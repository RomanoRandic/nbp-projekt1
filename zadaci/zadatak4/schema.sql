-- Task 4: schema planned ahead for tasks 5, 6 and 7.
-- Compared to the suggested schema it adds embedding768, because task 6 needs two
-- vectors of the same text. The tsvector column for task 7 is added in that task.
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS movies (
    movie_id      INTEGER PRIMARY KEY,
    title         TEXT,
    overview      TEXT,
    genres        TEXT,
    release_date  DATE,
    vote_average  REAL,
    popularity    REAL,
    text_to_embed TEXT,
    embedding384  vector(384),
    embedding768  vector(768)
);
