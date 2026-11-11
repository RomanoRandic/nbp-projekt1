-- Task 2: rr55208 configuration with the rr55208syn synonym dictionary.
-- The configuration and the dictionary are already in the database (restored from the
-- dump), and the synonym file is mounted from baza/rr55208syn.syn. They were created with:
--
--   CREATE TEXT SEARCH CONFIGURATION rr55208 (COPY = english);
--   CREATE TEXT SEARCH DICTIONARY rr55208syn (TEMPLATE = synonym, SYNONYMS = rr55208syn);
--   ALTER TEXT SEARCH CONFIGURATION rr55208
--       ALTER MAPPING FOR word, asciiword WITH rr55208syn, english_stem;
--
-- Synonym file location in the container: /usr/share/postgresql/18/tsearch_data/rr55208syn.syn

-- The dictionary alone: {desk} and NULL.
SELECT ts_lexize('rr55208syn', 'table') AS poznata, ts_lexize('rr55208syn', 'sailors') AS nepoznata;

-- Demonstration on a constant text: synonym (moist, table), normalization (sailors),
-- stop words (the, in) and a word that stays the same (zagreb).
SELECT alias, token, dictionaries, dictionary, lexemes
FROM ts_debug('rr55208', 'The sailors put the moist table in Zagreb')
WHERE alias IN ('asciiword', 'word');

SELECT to_tsvector('rr55208', 'The sailors put the moist table in Zagreb');
