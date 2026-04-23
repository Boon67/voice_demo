SEGMENT_SECONDS = 15
DIARIZATION_MODEL = "llama3.1-8b"
SIMILARITY_THRESHOLD_PRODUCT = 0.3
SIMILARITY_THRESHOLD_CASE = 0.4
ENRICHMENT_MIN_CHARS = 100

def get_config():
    return {
        "segment_seconds": SEGMENT_SECONDS,
        "diarization_model": DIARIZATION_MODEL,
        "similarity_threshold_product": SIMILARITY_THRESHOLD_PRODUCT,
        "similarity_threshold_case": SIMILARITY_THRESHOLD_CASE,
        "enrichment_min_chars": ENRICHMENT_MIN_CHARS,
    }

def update_config(updates: dict):
    global SEGMENT_SECONDS, DIARIZATION_MODEL, SIMILARITY_THRESHOLD_PRODUCT, SIMILARITY_THRESHOLD_CASE, ENRICHMENT_MIN_CHARS
    if "segment_seconds" in updates:
        SEGMENT_SECONDS = int(updates["segment_seconds"])
    if "diarization_model" in updates:
        DIARIZATION_MODEL = str(updates["diarization_model"])
    if "similarity_threshold_product" in updates:
        SIMILARITY_THRESHOLD_PRODUCT = float(updates["similarity_threshold_product"])
    if "similarity_threshold_case" in updates:
        SIMILARITY_THRESHOLD_CASE = float(updates["similarity_threshold_case"])
    if "enrichment_min_chars" in updates:
        ENRICHMENT_MIN_CHARS = int(updates["enrichment_min_chars"])
    return get_config()
