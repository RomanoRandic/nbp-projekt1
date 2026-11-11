import random
import statistics
import time
from pathlib import Path

import psycopg2

DB_CONFIG = {
    "dbname": "moja_baza",
    "user": "postgres",
    "password": "myPwd",
    "host": "localhost",
    "port": "55432"
}

SEED = 42
REPETITIONS = 20
K = 100
EF_SEARCH = 101
PROBES = 10
DIMENSIONS = [384, 768]
MEASURES = {"L2": "<->", "cosine": "<=>", "inner_product": "<#>"}


def search(cur, table, column, operator, query_id, vector):
    started = time.perf_counter()
    cur.execute(
        f"SELECT movie_id FROM {table} WHERE movie_id <> %s "
        f"ORDER BY {column} {operator} %s::vector LIMIT {K}",
        (query_id, vector)
    )
    rows = cur.fetchall()
    elapsed = (time.perf_counter() - started) * 1000
    return [row[0] for row in rows], elapsed


def run_series(cur, table, column, operator, queries):
    for query_id, vector in queries:
        search(cur, table, column, operator, query_id, vector)
    results, times = {}, []
    for query_id, vector in queries:
        ids, elapsed = search(cur, table, column, operator, query_id, vector)
        results[query_id] = ids
        times.append(elapsed)
    return results, statistics.mean(times)


conn = psycopg2.connect(**DB_CONFIG)
conn.autocommit = True
cur = conn.cursor()

cur.execute("SELECT movie_id FROM tablica_noindexes ORDER BY movie_id")
all_ids = [row[0] for row in cur.fetchall()]
query_ids = random.Random(SEED).sample(all_ids, REPETITIONS)

queries = {}
for dimension in DIMENSIONS:
    queries[dimension] = []
    for query_id in query_ids:
        cur.execute(f"SELECT embedding{dimension} FROM tablica_noindexes WHERE movie_id = %s", (query_id,))
        queries[dimension].append((query_id, cur.fetchone()[0]))

lines = [
    f"Redaka: {len(all_ids)}. k = {K}. Seed: {SEED}.",
    f"Zapisi za upite: {query_ids}",
    f"hnsw.ef_search = {EF_SEARCH}, ivfflat.probes = {PROBES}, enable_seqscan = off za ANN.",
    "",
    "ENN",
    "",
    "| Type | Dimensions | Measure | AVG(execution time ms) |",
    "|---|---|---|---|",
]
exact = {}
for dimension in DIMENSIONS:
    for measure, operator in MEASURES.items():
        results, average = run_series(cur, "tablica_noindexes", f"embedding{dimension}", operator, queries[dimension])
        exact[(dimension, measure)] = results
        lines.append(f"| noIndex | {dimension} | {measure} | {average:.2f} |")
        print(lines[-1], flush=True)

cur.execute(f"SET hnsw.ef_search = {EF_SEARCH}")
cur.execute(f"SET ivfflat.probes = {PROBES}")
cur.execute("SET enable_seqscan = off")

lines += [
    "",
    "ANN",
    "",
    "| Type | Dimensions | Measure | Index creation time | AVG(recall) | AVG(execution time) |",
    "|---|---|---|---|---|---|",
]
for label, table in (("HNSW", "tablica_hnsw"), ("IVFFlat", "tablica_ivfflat")):
    for dimension in DIMENSIONS:
        for measure, operator in MEASURES.items():
            results, average = run_series(cur, table, f"embedding{dimension}", operator, queries[dimension])
            truth = exact[(dimension, measure)]
            recall = statistics.mean(len(set(truth[q]) & set(results[q])) / K for q in results)
            lines.append(f"| {label} | {dimension} | {measure} |  | {recall:.4f} | {average:.2f} |")
            print(lines[-1], flush=True)

(Path(__file__).parent / "rezultati.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
cur.close()
conn.close()
print("Gotovo. Rezultati su u zadatak6\\rezultati.md")