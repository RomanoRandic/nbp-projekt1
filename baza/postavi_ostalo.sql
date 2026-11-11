-- Runs once, after the dump is restored. The dump holds the movies table with both
-- vectors and the rr55208 configuration (task 2). This file builds everything else
-- the way it was built for tasks 5, 6 and 7. Building the indexes takes a few minutes.

\timing on

-- Task 5: three tables with titles, a trigram GIN and a trigram GiST index.
CREATE TABLE movies_no_index AS SELECT movie_id, title FROM movies;
CREATE TABLE movies_gin AS SELECT movie_id, title FROM movies;
CREATE TABLE movies_gist AS SELECT movie_id, title FROM movies;

CREATE INDEX movies_gin_title_trgm ON movies_gin USING gin (title gin_trgm_ops);
CREATE INDEX movies_gist_title_trgm ON movies_gist USING gist (title gist_trgm_ops);

-- Task 6: three tables with both vectors and 12 vector indexes.
CREATE TABLE tablica_noindexes AS SELECT movie_id, embedding384, embedding768 FROM movies;
CREATE TABLE tablica_hnsw AS SELECT movie_id, embedding384, embedding768 FROM movies;
CREATE TABLE tablica_ivfflat AS SELECT movie_id, embedding384, embedding768 FROM movies;

CREATE INDEX hnsw_384_l2 ON tablica_hnsw USING hnsw (embedding384 vector_l2_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX hnsw_384_cosine ON tablica_hnsw USING hnsw (embedding384 vector_cosine_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX hnsw_384_ip ON tablica_hnsw USING hnsw (embedding384 vector_ip_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX hnsw_768_l2 ON tablica_hnsw USING hnsw (embedding768 vector_l2_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX hnsw_768_cosine ON tablica_hnsw USING hnsw (embedding768 vector_cosine_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX hnsw_768_ip ON tablica_hnsw USING hnsw (embedding768 vector_ip_ops) WITH (m = 16, ef_construction = 64);

CREATE INDEX ivfflat_384_l2 ON tablica_ivfflat USING ivfflat (embedding384 vector_l2_ops) WITH (lists = 40);
CREATE INDEX ivfflat_384_cosine ON tablica_ivfflat USING ivfflat (embedding384 vector_cosine_ops) WITH (lists = 40);
CREATE INDEX ivfflat_384_ip ON tablica_ivfflat USING ivfflat (embedding384 vector_ip_ops) WITH (lists = 40);
CREATE INDEX ivfflat_768_l2 ON tablica_ivfflat USING ivfflat (embedding768 vector_l2_ops) WITH (lists = 40);
CREATE INDEX ivfflat_768_cosine ON tablica_ivfflat USING ivfflat (embedding768 vector_cosine_ops) WITH (lists = 40);
CREATE INDEX ivfflat_768_ip ON tablica_ivfflat USING ivfflat (embedding768 vector_ip_ops) WITH (lists = 40);

-- Task 7: weighted tsvector column on movies, a GIN index on it and an HNSW cosine index.
ALTER TABLE movies ADD COLUMN fts tsvector;

UPDATE movies
SET fts = setweight(to_tsvector('english', title),    'A') ||
          setweight(to_tsvector('english', genres),   'B') ||
          setweight(to_tsvector('english', overview), 'C');

CREATE INDEX movies_fts_gin ON movies USING gin (fts);
CREATE INDEX movies_embedding384_hnsw ON movies USING hnsw (embedding384 vector_cosine_ops);

-- Not part of any task: fresh statistics, so the planner picks the indexes right away.
ANALYZE;
