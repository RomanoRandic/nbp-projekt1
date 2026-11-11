# NBP projekt 1: baza za pokazivanje

Projekt iz kolegija Napredne baze podataka (FER): PostgreSQL 18 s pgvectorom, 40 124 filma s TMDB-a s vektorima od 384 i 768 dimenzija, pretraga teksta (FTS, trigrami) i vektorska pretraga (HNSW, IVFFlat).

Baza se ne gradi ispočetka. Gotov dump je u [izdanju v1](https://github.com/RomanoRandic/nbp-projekt1/releases/tag/v1), a vraća se u Docker.

## Kako postaviti

Najlakše je preko Claude Codea na novom računalu. Napiši mu:

> Kloniraj https://github.com/RomanoRandic/nbp-projekt1 i postavi sve prema datoteci UPUTE_ZA_CLAUDEA.md iz tog repozitorija.

Ručno: koraci su isti i opisani su u [UPUTE_ZA_CLAUDEA.md](UPUTE_ZA_CLAUDEA.md). Treba Docker Desktop i Git.

## Sadržaj

| Mapa | Što je |
|---|---|
| `baza/` | Datoteka sinonima, skripta za tablice i indekse, provjera |
| `zadaci/` | SQL i Python kod zadataka 2 do 7 |

Podaci o filmovima dolaze s [The Movie Database (TMDB)](https://www.themoviedb.org/). Projekt koristi TMDB API, ali ga TMDB nije odobrio ni certificirao.
