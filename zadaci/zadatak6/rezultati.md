Redaka: 40124. k = 100. Seed: 42.
Zapisi za upite: [17627, 4547, 53487, 45888, 41201, 23303, 16061, 373450, 14028, 451955, 149218, 6963, 5994, 14809, 40205, 42769, 302946, 476517, 4960, 400001]
hnsw.ef_search = 101, ivfflat.probes = 10, enable_seqscan = off za ANN.

ENN

| Type | Dimensions | Measure | AVG(execution time ms) |
|---|---|---|---|
| noIndex | 384 | L2 | 14.11 |
| noIndex | 384 | cosine | 15.14 |
| noIndex | 384 | inner_product | 14.20 |
| noIndex | 768 | L2 | 60.19 |
| noIndex | 768 | cosine | 55.66 |
| noIndex | 768 | inner_product | 54.52 |

ANN

| Type | Dimensions | Measure | Index creation time | AVG(recall) | AVG(execution time) |
|---|---|---|---|---|---|
| HNSW | 384 | L2 |  | 0.9105 | 2.79 |
| HNSW | 384 | cosine |  | 0.9155 | 2.73 |
| HNSW | 384 | inner_product |  | 0.9160 | 2.94 |
| HNSW | 768 | L2 |  | 0.9390 | 3.03 |
| HNSW | 768 | cosine |  | 0.9365 | 3.17 |
| HNSW | 768 | inner_product |  | 0.9370 | 3.39 |
| IVFFlat | 384 | L2 |  | 0.8730 | 6.32 |
| IVFFlat | 384 | cosine |  | 0.8895 | 4.96 |
| IVFFlat | 384 | inner_product |  | 0.8965 | 5.32 |
| IVFFlat | 768 | L2 |  | 0.9170 | 8.52 |
| IVFFlat | 768 | cosine |  | 0.9140 | 8.34 |
| IVFFlat | 768 | inner_product |  | 0.9245 | 8.32 |
