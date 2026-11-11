-- Task 5: trigram search for 'incepton' without an index, with GIN and with GiST.
-- The tables and indexes are built by baza/postavi_ostalo.sql.

SELECT pg_size_pretty(pg_relation_size('movies_gin_title_trgm'));
SELECT pg_size_pretty(pg_relation_size('movies_gist_title_trgm'));

EXPLAIN ANALYZE
SELECT movie_id, title, similarity(title, 'incepton') AS slicnost
FROM movies_no_index
WHERE title % 'incepton'
ORDER BY slicnost DESC;

EXPLAIN ANALYZE
SELECT movie_id, title, similarity(title, 'incepton') AS slicnost
FROM movies_gin
WHERE title % 'incepton'
ORDER BY slicnost DESC;

EXPLAIN ANALYZE
SELECT movie_id, title, similarity(title, 'incepton') AS slicnost
FROM movies_gist
WHERE title % 'incepton'
ORDER BY slicnost DESC;
