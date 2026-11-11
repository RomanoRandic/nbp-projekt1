# Upute za Claudea: postavljanje NBP projekta 1 na novom računalu

Ove upute čitaš ti, Claude, na računalu na kojem korisnik želi pokazati projekt iz kolegija Napredne baze podataka (FER). Cilj je da na ovom računalu radi ista baza kao na korisnikovom: PostgreSQL 18 s pgvectorom, 40 124 filma s TMDB-a s vektorima od 384 i 768 dimenzija, te sve tablice i indeksi iz zadataka 2 do 7.

**Ništa se ne skida s TMDB-a i ne računaju se vektori.** Gotova baza je u jednoj datoteci (dump) na GitHubu, a ti je samo vraćaš u Docker.

Korisniku odgovaraj na hrvatskom, neformalno („ti”). Prije svake instalacije programa pitaj korisnika, jer instalacija traži administratorsku dozvolu.

## Što se gdje nalazi

| Putanja | Što je |
|---|---|
| `docker-compose.yml` | Jedan servis, `postgres`, sa slikom `pgvector/pgvector:0.8.6-pg18` |
| `baza/rr55208syn.syn` | Datoteka sinonima za zadatak 2. Compose je sam montira u kontejner |
| `baza/postavi_ostalo.sql` | Gradi tablice i indekse za zadatke 5, 6 i 7 |
| `baza/provjera.sql` | Provjera, s očekivanim rezultatom iznad svakog upita |
| `baza/moja_baza.dump` | Dump baze. **Nije u gitu**, skida se u koraku 3 |
| `zadaci/zadatakN/` | SQL i Python kod pojedinih zadataka, za pokazivanje |

Podaci za spajanje na bazu:

| | |
|---|---|
| Host | `localhost` |
| Port | `55432`, ili ono što je postavljeno u `.env` kao `PG_PORT` |
| Baza | `moja_baza` |
| Korisnik | `postgres` |
| Lozinka | `myPwd` |

Lozinka je ista kao u kodu projekta. Baza je dostupna samo s ovog računala, jer je port vezan na `127.0.0.1`.

## Koraci

Naredbe su za PowerShell na Windowsima. Na macOS-u i Linuxu su iste, osim gdje piše drugačije.

**Ako ih na Windowsima pokrećeš kroz Git Bash** (to je tvoj alat Bash), prvo pokreni `export MSYS_NO_PATHCONV=1`. Bez toga Git Bash putanje unutar kontejnera, npr. `/baza/moja_baza.dump`, pretvori u `C:/Program Files/Git/baza/...`, pa naredbe javljaju da datoteka ne postoji. U PowerShellu toga nema.

### 1. Provjeri programe

```powershell
docker --version
git --version
```

Ako nešto nedostaje, pitaj korisnika smiješ li ga instalirati:

| Program | Instalacija na Windowsima | Napomena |
|---|---|---|
| Docker Desktop | `winget install -e --id Docker.DockerDesktop` | Traži WSL 2 i često ponovno pokretanje računala |
| Git | `winget install -e --id Git.Git` | Nakon instalacije otvori novi terminal |
| pgAdmin, po želji | `winget install -e --id PostgreSQL.pgAdmin` | Za pokazivanje upita u grafičkom sučelju |
| Python, po želji | `winget install -e --id Python.Python.3.13` | Samo za korak 9 |

Docker Desktop mora biti **pokrenut**. Provjera:

```powershell
docker info
```

Ako javi grešku o `dockerDesktopLinuxEngine`, pokreni Docker Desktop i pričekaj dok `docker info` ne prođe:

```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

### 2. Skini repozitorij

```powershell
git clone https://github.com/RomanoRandic/nbp-projekt1.git
Set-Location nbp-projekt1
```

Sve sljedeće naredbe pokreći iz te mape.

### 3. Skini dump baze

Datoteka ima oko 226 MB.

```powershell
curl.exe -L -o baza\moja_baza.dump https://github.com/RomanoRandic/nbp-projekt1/releases/download/v1/moja_baza.dump
```

Na macOS-u i Linuxu je ista naredba, samo `curl` umjesto `curl.exe` i `/` umjesto `\`.

Provjeri da je stigla cijela:

```powershell
(Get-FileHash baza\moja_baza.dump -Algorithm SHA256).Hash
```

Mora biti `9F6121219382E43B2191725D7286934EFD2CE4206611154BF0975C4E9AFAEB91`. Na macOS-u i Linuxu provjeri sa `shasum -a 256 baza/moja_baza.dump`, a tamo je ispis malim slovima. Ako se ne poklapa, skini ponovno.

### 4. Provjeri je li port slobodan (samo Windows)

Windows ponekad rezervira raspone portova, osobito nakon ponovnog pokretanja, a tada se Docker ne može vezati na 55432:

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

Ako je 55432 unutar nekog raspona, ili korak 5 javi `ports are not available` ili `forbidden by its access permissions`, napravi datoteku `.env` s drugim portom koji nije ni u jednom rasponu, npr.:

```powershell
Set-Content -Path .env -Value "PG_PORT=15432" -Encoding ascii
```

Tada taj port koristi i u pgAdminu i u koraku 9.

### 5. Pokreni bazu

```powershell
docker compose up -d
```

Prvi put skida sliku PostgreSQL-a s pgvectorom, oko 150 MB. Pričekaj da baza bude spremna:

```powershell
docker compose exec postgres pg_isready -U postgres
```

Mora pisati `accepting connections`. Ako ne piše, pričekaj nekoliko sekundi i pokušaj ponovno.

Provjeri da je datoteka sinonima u kontejneru:

```powershell
docker compose exec postgres cat /usr/share/postgresql/18/tsearch_data/rr55208syn.syn
```

Moraju se vidjeti četiri retka, od `moist wet` do `counter desk`.

### 6. Vrati dump

```powershell
docker compose exec -T postgres pg_restore -U postgres -d moja_baza --no-owner --no-privileges /baza/moja_baza.dump
```

Traje desetak sekundi. Ne smije ispisati nijednu grešku. Ako javi `could not open synonym file`, korak 5 nije prošao kako treba.

### 7. Izgradi tablice i indekse za zadatke 5, 6 i 7

```powershell
docker compose exec -T postgres psql -U postgres -d moja_baza -v ON_ERROR_STOP=1 -f /baza/postavi_ostalo.sql
```

Traje nekoliko minuta, jer se gradi 16 indeksa, od toga 7 HNSW. Na računalu s kojeg je projekt trajalo je oko 4 minute. Pokreni **samo jednom**. Drugi put bi javio da tablice već postoje.

### 8. Provjeri

```powershell
docker compose exec -T postgres psql -U postgres -d moja_baza -f /baza/provjera.sql
```

Usporedi s očekivanim:

| Provjera | Očekivano |
|---|---|
| Podaci | `40124 \| 40124 \| 40124` |
| Zadatak 2 | `'desk':3 'wet':2` |
| Zadatak 5 | `2` |
| Indeksi | `2 \| 12 \| 2` |
| Zadatak 7, scenarij B | `1` |

Ako se sve poklapa, baza je ista kao na korisnikovom računalu. Javi to korisniku.

### 9. Python, samo ako korisnik želi pokrenuti skripte

Za pokus iz zadatka 6 treba samo `psycopg2`:

```powershell
python -m pip install psycopg2-binary
python zadaci\zadatak6\pokus.py
```

Traje oko minutu. **Prepisat će `zadaci\zadatak6\rezultati.md`** novim brojevima s ovog računala. Originalni rezultati vraćaju se sa `git restore zadaci\zadatak6\rezultati.md`. Ako je port promijenjen u koraku 4, prije pokretanja promijeni `"port": "55432"` u `pokus.py`.

Vrijeme na drugom računalu bit će drugačije nego u predaji. Recall bi trebao biti blizu predanog, ali se zbog novih HNSW i IVFFlat indeksa može malo razlikovati.

Za vektor novog upita u zadatku 7 treba `sentence-transformers`, a pri prvom pokretanju skida se i model `all-MiniLM-L6-v2`, oko 90 MB:

```powershell
python -m pip install sentence-transformers
python zadaci\zadatak7\vektoriziraj_upit.py "neki tekst"
```

To nije potrebno za predane upite, jer su vektori već upisani u `zadaci\zadatak7\upiti_film_11619.sql`.

**Ne pokreći** `zadaci\zadatak4\download_and_import.py` ni `zadaci\zadatak4\dodaj_768.py`. Podaci su već u bazi, a te skripte traže TMDB ključ i rade satima.

### 10. pgAdmin, po želji

U pgAdminu: **Register > Server**, pa na kartici **General** ime `NBP`, a na kartici **Connection** podaci iz tablice na vrhu. Zatim otvori **Query Tool** na bazi `moja_baza` i učitaj datoteku iz `zadaci`.

U Query Toolu označi jednu naredbu i pritisni F5. Bez označavanja pgAdmin pokrene sve, a prikaže samo zadnji rezultat.

## Što pokazati po zadacima

| Zadatak | Datoteka | Što se vidi |
|---|---|---|
| 2 | `zadaci/zadatak2/zadatak2.sql` | Konfiguracija `rr55208`: sinonimi, normalizacija i zaustavne riječi kroz `ts_debug` |
| 3 | `zadaci/zadatak3/zadatak3.sql` | Utjecaj težina i duljine dokumenta na `ts_rank`. Ne treba nijednu tablicu |
| 4 | `zadaci/zadatak4/` | Shema i kod kojim su podaci skinuti, samo za čitanje |
| 5 | `zadaci/zadatak5/zadatak5.sql` | Trigramska pretraga `'incepton'`: Seq Scan, GIN i GiST |
| 6 | `zadaci/zadatak6/zadatak6.sql`, `pokus.py`, `rezultati.md` | `EXPLAIN ANALYZE` s HNSW indeksom, pokus ENN prema ANN i predani rezultati |
| 7 | `zadaci/zadatak7/upiti_film_11619.sql` | Rang filma Flushed Away (11619): FTS i vektorska pretraga, scenariji A i B |

Za zadatak 7 predani rangovi su: scenarij A, FTS 887 i vektori 4; scenarij B, FTS 1 i vektori 1. FTS rangovi moraju biti isti. Vektorski se mogu malo razlikovati, jer je HNSW indeks ovdje nanovo izgrađen. U toj datoteci prvo pokreni `SET hnsw.ef_search = 200;`, jer bez njega HNSW u scenariju B ne nađe film.

## Gašenje i brisanje

Gašenje, podaci ostaju:

```powershell
docker compose stop
```

Ponovno pokretanje kasnije je samo `docker compose up -d`, bez koraka 6 i 7.

**`docker compose down -v` briše cijelu bazu** ovog projekta. Koristi ga samo ako korisnik želi sve ispočetka, i tada ponovi korake 5 do 8.

## Ako nešto ne radi

| Poruka | Uzrok | Rješenje |
|---|---|---|
| `failed to connect to the docker API` | Docker Desktop nije pokrenut | Pokreni ga i pričekaj, korak 1 |
| `ports are not available`, `forbidden by its access permissions` | Windows je rezervirao port | Korak 4 |
| `port is already allocated` | Port zauzima drugi program | Korak 4, s drugim portom |
| `could not open synonym file` | Datoteka sinonima nije u kontejneru | Provjeri da `baza\rr55208syn.syn` postoji kao datoteka, ne kao mapa, pa `docker compose up -d --force-recreate` |
| Baza se ne pokreće, u `docker compose logs postgres` piše o memoriji | Premalo RAM-a za `shared_buffers=1GB` | U `.env` dodaj `PG_SHARED_BUFFERS=256MB`, pa `docker compose up -d` |
| `could not resize shared memory segment` | Premalo memorije za paralelnu gradnju indeksa | Provjeri da je u compose datoteci `shm_size: 2g` |
| `relation ... already exists` u koraku 7 | Korak 7 je već pokrenut | Ništa, tablice već postoje. Provjeri korakom 8 |

Ne mijenjaj datoteke u repozitoriju i ne radi `git push`. Repozitorij je korisnikov.

Podaci o filmovima dolaze s The Movie Database (TMDB). Projekt koristi TMDB API, ali ga TMDB nije odobrio ni certificirao.
