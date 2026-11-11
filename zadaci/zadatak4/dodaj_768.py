import psycopg2
from sentence_transformers import SentenceTransformer

DB_CONFIG = {
    "dbname": "moja_baza",
    "user": "postgres",
    "password": "myPwd",
    "host": "localhost",
    "port": "55432"
}

BATCH_SIZE = 64

model = SentenceTransformer("all-mpnet-base-v2")
conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

cur.execute("SELECT movie_id, text_to_embed FROM movies WHERE embedding768 IS NULL")
rows = cur.fetchall()
print(f"Filmova za obradu: {len(rows)}", flush=True)

for start in range(0, len(rows), BATCH_SIZE):
    batch = rows[start:start + BATCH_SIZE]
    embeddings = model.encode(
        [text_to_embed for _, text_to_embed in batch],
        batch_size=BATCH_SIZE,
        convert_to_tensor=False,
        normalize_embeddings=True
    ).tolist()
    for (movie_id, _), embedding in zip(batch, embeddings):
        cur.execute(
            "UPDATE movies SET embedding768 = %s WHERE movie_id = %s",
            (embedding, movie_id)
        )
    conn.commit()
    print(f"{start + len(batch)}/{len(rows)}", flush=True)

cur.close()
conn.close()
print("Gotovo.")
