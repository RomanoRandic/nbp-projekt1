"""Task 7: turn the query text into a vector, the same way the documents were embedded.

Same model (all-MiniLM-L6-v2) and same normalization as in zadatak4/dohvat_tmdb.py.
A vector from another model, or one that is not normalized, would not be comparable.

Usage: python zadatak7/vektoriziraj_upit.py "text of the query"
"""
import sys

from sentence_transformers import SentenceTransformer

MODEL_NAME = "all-MiniLM-L6-v2"


def embed_query(text):
    model = SentenceTransformer(MODEL_NAME)
    vector = model.encode(text, normalize_embeddings=True)
    return "[" + ",".join(f"{value:.7f}" for value in vector) + "]"


if __name__ == "__main__":
    print(embed_query(sys.argv[1]))
