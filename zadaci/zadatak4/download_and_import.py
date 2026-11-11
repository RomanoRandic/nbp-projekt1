import os
import requests
import time
import json
import psycopg2
from sentence_transformers import SentenceTransformer
from datetime import datetime, timedelta


# --- 1. CONFIGURATION ---
API_KEY = os.environ.get("TMDB_API_KEY")
if not API_KEY: 
    raise RuntimeError("Postavite TMDB_API_KEY kao varijablu okoline.")
# ili API_KEY = os.environ.get("TMDB_API_KEY", "upišite API_KEY")

BASE_URL = "https://api.themoviedb.org/3"
JSON_FILE = "tmdb_movies_vectors.json"

DB_CONFIG = {
    "dbname": "moja_baza",
    "user": "postgres",
    "password": "myPwd",
    "host": "localhost",
    "port": "55432"
}

TMDB_MAX_PAGES = 500

# --- 2. HELPER FUNCTIONS ---
def month_range(start_date, end_date):
    current = start_date.replace(day=1)

    while current <= end_date:
        next_month = (current.replace(day=28) + timedelta(days=4)).replace(day=1)
        to_dt = min(next_month - timedelta(days=1), end_date)
        yield current, to_dt
        current = next_month


def load_genres():
    """Dohvaća mapu ID-a žanra u njegov naziv."""
    response = requests.get(
        f"{BASE_URL}/genre/movie/list",
        params={"api_key": API_KEY, "language": "en-US"}
    )
    response.raise_for_status()
    return {genre["id"]: genre["name"] for genre in response.json()["genres"]}


# --- 3. MAIN FUNCTION ---
def fetch_process_and_insert(
    max_movies, start_date, end_date, min_votes, model, conn, cur
):
    movies_processed = []

    try:
        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        end_dt = datetime.strptime(end_date, "%Y-%m-%d")
    except ValueError:
        print("ERROR: Neispravan format datuma. Koristite YYYY-MM-DD.")
        return

    genres = load_genres()
    print(f"--- Starting ETL process (max {max_movies} movies) ---")

    for from_dt, to_dt in month_range(start_dt, end_dt):
        page = 1
        month_str = from_dt.strftime("%Y-%m")

        if len(movies_processed) >= max_movies:
            break

        while len(movies_processed) < max_movies:
            params = {
                "api_key": API_KEY,
                "language": "en-US",
                "page": page,
                "sort_by": "popularity.desc",
                "primary_release_date.gte": from_dt.strftime("%Y-%m-%d"),
                "primary_release_date.lte": to_dt.strftime("%Y-%m-%d"),
                "vote_count.gte": min_votes,
                "include_adult": "false"
            }

            try:
                response = requests.get(
                    f"{BASE_URL}/discover/movie",
                    params=params
                )
                response.raise_for_status()
                data = response.json()
            except requests.exceptions.RequestException as error:
                print(
                    f"ERROR: API zahtjev nije uspio za {month_str}, "
                    f"stranica {page}: {error}"
                )
                time.sleep(5)
                break

            results = data.get("results", [])
            total_pages = min(data.get("total_pages", 1), TMDB_MAX_PAGES)

            if not results:
                print(f"Nema više rezultata za {month_str}.")
                break

            for item in results:
                if len(movies_processed) >= max_movies:
                    break

                movie_id = item.get("id")
                title = item.get("title")
                overview = item.get("overview")

                if not overview:
                    continue

                genre_names = ", ".join(
                    genres.get(genre_id, "")
                    for genre_id in item.get("genre_ids", [])
                )
                text_to_embed = f"{title or ''}\n{genre_names}\n{overview}"

                try:
                    embedding = model.encode(
                        text_to_embed,
                        convert_to_tensor=False,
                        normalize_embeddings=True
                    ).tolist()
                except Exception as error:
                    print(
                        f"WARNING: Vektorizacija nije uspjela za film "
                        f"{movie_id}. Preskačem. Detalji: {error}"
                    )
                    continue

                try:
                    cur.execute(
                        """
                        INSERT INTO movies (
                            movie_id,
                            title,
                            overview,
                            genres,
                            release_date,
                            vote_average,
                            popularity,
                            text_to_embed,
                            embedding384
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (movie_id) DO NOTHING
                        """,
                        (
                            movie_id,
                            title,
                            overview,
                            genre_names,
                            item.get("release_date") or None,
                            item.get("vote_average"),
                            item.get("popularity"),
                            text_to_embed,
                            embedding
                        )
                    )
                    conn.commit()

                    movies_processed.append({
                        "movie_id": movie_id,
                        "title": title,
                        "overview": overview,
                        "genres": genre_names,
                        "release_date": item.get("release_date"),
                        "vote_average": item.get("vote_average"),
                        "popularity": item.get("popularity"),
                        "text_to_embed": text_to_embed,
                        "url": f"https://www.themoviedb.org/movie/{movie_id}"
                    })

                    if len(movies_processed) % 10 == 0:
                        print(
                            f"Processed movie {len(movies_processed)}/"
                            f"{max_movies}: {title[:70]}..."
                        )

                except psycopg2.Error as error:
                    print(
                        f"ERROR: Upis filma {movie_id} u bazu nije uspio. "
                        f"Detalji: {error}"
                    )
                    conn.rollback()

            if len(movies_processed) >= max_movies or page >= total_pages:
                break

            page += 1
            time.sleep(0.1)

    try:
        with open(JSON_FILE, "w", encoding="utf-8") as file:
            json.dump(movies_processed, file, ensure_ascii=False, indent=2)

        print(f"\nGotovo! Spremljeno je {len(movies_processed)} filmova u {JSON_FILE}")
    except Exception as error:
        print(f"ERROR: Spremanje JSON datoteke nije uspjelo. Detalji: {error}")

    print("\n--- Preuzimanje i obrada su završeni. ---")


# --- 4. MAIN ---
if __name__ == "__main__":
    NUM_MOVIES = 42500
    START_DATE = "1969-11-11"
    END_DATE = "1970-11-11"
    MIN_VOTES = 20

    EMBEDDING_MODEL = "all-MiniLM-L6-v2"  # 384-dimenzionalni model

    conn, cur = None, None

    try:
        print(f"\n--- Loading embedding model: {EMBEDDING_MODEL} ---")
        model = SentenceTransformer(EMBEDDING_MODEL)

        print("--- Connecting to PostgreSQL ---")
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        fetch_process_and_insert(
            max_movies=NUM_MOVIES,
            start_date=START_DATE,
            end_date=END_DATE,
            min_votes=MIN_VOTES,
            model=model,
            conn=conn,
            cur=cur
        )

    except psycopg2.Error as error:
        print(f"FATAL ERROR: Spajanje na PostgreSQL nije uspjelo. Detalji: {error}")
    except Exception as error:
        print(f"FATAL ERROR: Neočekivana greška. Detalji: {error}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()
            print("PostgreSQL veza je zatvorena.")

    print("\n--- Program je završio. ---")
