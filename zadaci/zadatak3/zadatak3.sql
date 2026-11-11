-- Task 3: influence of document structure and length on the rank.

-- PART 1: structure. Four documents with four attributes. Each contains the query
-- word exactly once and each has 12 lexemes, so only the attribute (and with it
-- the weight) differs.
WITH dokumenti(id, naslov, kljucne_rijeci, sazetak, tijelo) AS (VALUES
    (1, 'lighthouse restoration', 'coast harbor',      'volunteers repaired beacon',     'crew returned safely winter storms'),
    (2, 'coastal restoration',    'lighthouse harbor', 'volunteers repaired beacon',     'crew returned safely winter storms'),
    (3, 'coastal restoration',    'coast harbor',      'volunteers repaired lighthouse', 'crew returned safely winter storms'),
    (4, 'coastal restoration',    'coast harbor',      'volunteers repaired beacon',     'crew returned lighthouse winter storms')
), vektori AS (
    SELECT id,
           setweight(to_tsvector('english', naslov),         'A') ||
           setweight(to_tsvector('english', kljucne_rijeci), 'B') ||
           setweight(to_tsvector('english', sazetak),        'C') ||
           setweight(to_tsvector('english', tijelo),         'D') AS tsv
    FROM dokumenti
)
SELECT id,
       CASE id WHEN 1 THEN 'naslov (A)' WHEN 2 THEN 'kljucne rijeci (B)'
               WHEN 3 THEN 'sazetak (C)' ELSE 'tijelo (D)' END AS gdje_je_rijec,
       length(tsv) AS broj_leksema,
       tsv,
       ts_rank(tsv, to_tsquery('english', 'lighthouse')) AS rang
FROM vektori
ORDER BY rang DESC;

-- PART 1b: the same documents with the weight array reversed. The order flips,
-- which shows that the weights alone produced the ranking above.
WITH dokumenti(id, naslov, kljucne_rijeci, sazetak, tijelo) AS (VALUES
    (1, 'lighthouse restoration', 'coast harbor',      'volunteers repaired beacon',     'crew returned safely winter storms'),
    (2, 'coastal restoration',    'lighthouse harbor', 'volunteers repaired beacon',     'crew returned safely winter storms'),
    (3, 'coastal restoration',    'coast harbor',      'volunteers repaired lighthouse', 'crew returned safely winter storms'),
    (4, 'coastal restoration',    'coast harbor',      'volunteers repaired beacon',     'crew returned lighthouse winter storms')
), vektori AS (
    SELECT id,
           setweight(to_tsvector('english', naslov),         'A') ||
           setweight(to_tsvector('english', kljucne_rijeci), 'B') ||
           setweight(to_tsvector('english', sazetak),        'C') ||
           setweight(to_tsvector('english', tijelo),         'D') AS tsv
    FROM dokumenti
)
SELECT id,
       ts_rank('{0.1, 0.2, 0.4, 1.0}', tsv, to_tsquery('english', 'lighthouse')) AS zadane_tezine,
       ts_rank('{1.0, 0.4, 0.2, 0.1}', tsv, to_tsquery('english', 'lighthouse')) AS obrnute_tezine
FROM vektori
ORDER BY id;

-- PART 2: length. Every document starts with the same two query words at the same
-- positions. Only the number of unrelated words after them differs.
WITH duljine(ukupno) AS (VALUES (10), (50), (200), (1000)),
dokumenti AS (
    SELECT ukupno,
           'lighthouse keeper ' ||
           (SELECT string_agg('zapis' || g, ' ') FROM generate_series(1, ukupno - 2) g) AS tekst
    FROM duljine
), vektori AS (
    SELECT ukupno, to_tsvector('english', tekst) AS tsv FROM dokumenti
)
SELECT ukupno                                                           AS broj_rijeci,
       length(tsv)                                                      AS broj_leksema,
       ts_rank(tsv, to_tsquery('english', 'lighthouse & keeper'), 0)    AS norm_0_bez_utjecaja,
       ts_rank(tsv, to_tsquery('english', 'lighthouse & keeper'), 1)    AS norm_1_log_duljine,
       ts_rank(tsv, to_tsquery('english', 'lighthouse & keeper'), 2)    AS norm_2_duljina
FROM vektori
ORDER BY ukupno;
