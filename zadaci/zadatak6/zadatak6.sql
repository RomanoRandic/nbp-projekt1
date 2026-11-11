-- Task 6: proof that an ANN query uses its index. Record 17627 is the first of the 20
-- records chosen with seed 42 (see rezultati.md). The tables and the 12 indexes are
-- built by baza/postavi_ostalo.sql. The experiment itself is pokus.py.

SET hnsw.ef_search = 101;

EXPLAIN ANALYZE
SELECT movie_id
FROM tablica_hnsw
WHERE movie_id <> 17627
ORDER BY embedding384 <=> (SELECT embedding384 FROM movies WHERE movie_id = 17627)
LIMIT 100;

-- Expected: Index Scan using hnsw_384_cosine on tablica_hnsw.
-- If it says Seq Scan on tablica_hnsw instead, run this and repeat the query:
-- SET enable_seqscan = off;
