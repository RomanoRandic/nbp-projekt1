-- Task 7: preparation, as submitted. Already done by baza/postavi_ostalo.sql, so do not
-- run it again. The rank queries for film 11619 are in upiti_film_11619.sql.
--
--   ALTER TABLE movies ADD COLUMN fts tsvector;
--
--   UPDATE movies
--   SET fts = setweight(to_tsvector('english', title),    'A') ||
--             setweight(to_tsvector('english', genres),   'B') ||
--             setweight(to_tsvector('english', overview), 'C');
--
--   CREATE INDEX movies_fts_gin ON movies USING gin (fts);
--
--   CREATE INDEX movies_embedding384_hnsw
--       ON movies USING hnsw (embedding384 vector_cosine_ops);

-- Film used in the experiment:
SELECT movie_id, title, genres, overview FROM movies WHERE movie_id = 11619;
