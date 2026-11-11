-- Checks that the database is complete. The expected result is above each query.

-- 1. Data. Expected: 40124 | 40124 | 40124
SELECT count(*) AS filmova, count(embedding384) AS v384, count(embedding768) AS v768 FROM movies;

-- 2. Task 2, synonyms. Expected: 'desk':3 'wet':2
SELECT to_tsvector('rr55208', 'The moist table') AS zadatak2;

-- 3. Task 5, trigrams. Expected: 2
SELECT count(*) AS zadatak5 FROM movies_gin WHERE title % 'incepton';

-- 4. Indexes. Expected: 2 | 12 | 2
SELECT count(*) FILTER (WHERE tablename IN ('movies_gin', 'movies_gist')) AS zadatak5,
       count(*) FILTER (WHERE tablename IN ('tablica_hnsw', 'tablica_ivfflat')) AS zadatak6,
       count(*) FILTER (WHERE indexname IN ('movies_fts_gin', 'movies_embedding384_hnsw')) AS zadatak7
FROM pg_indexes
WHERE schemaname = 'public';

-- 5. Task 7, FTS rank of film 11619 in scenario B. Expected: 1
WITH upit AS (
    SELECT to_tsquery('english', 'Roddy | flushed | away') AS q
), rangirano AS (
    SELECT movie_id, rank() OVER (ORDER BY ts_rank(fts, q) DESC) AS pozicija
    FROM movies, upit
    WHERE fts @@ q
)
SELECT pozicija AS zadatak7_b FROM rangirano WHERE movie_id = 11619;
