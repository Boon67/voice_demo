import os
import json
import snowflake.connector
from typing import Optional, List, Dict, Any
import logging
import config

logger = logging.getLogger(__name__)

DB = "CALL_CENTER"
SCHEMA = "PUBLIC"
STAGE = "@CALL_CENTER.STG.TRANSCRIPTS"


def get_connection():
    return snowflake.connector.connect(
        connection_name=os.getenv("SNOWFLAKE_CONNECTION_NAME") or "default"
    )


def test_connection() -> bool:
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        return True
    except Exception as e:
        logger.error(f"Snowflake connection test failed: {e}")
        return False


def search_customers(query: str) -> List[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        search = f"%{query}%"
        cur.execute("""
            SELECT customer_id, name, email, phone, loyalty_tier, address
            FROM CUSTOMERS
            WHERE LOWER(name) LIKE LOWER(%s)
               OR phone LIKE %s
               OR LOWER(email) LIKE LOWER(%s)
            LIMIT 5
        """, (search, search, search))
        cols = [d[0].lower() for d in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]
    finally:
        cur.close()
        conn.close()


def diarize_chunk(text: str) -> List[Dict[str, str]]:
    if not text or len(text.strip()) < 5:
        return [{"speaker": "caller", "text": text}]
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        safe_text = text.replace("'", "''").replace("\\", "\\\\")
        sql = f"""
            SELECT TO_VARCHAR(AI_COMPLETE(
                model => '{config.DIARIZATION_MODEL}',
                prompt => 'You are analyzing a call center audio transcript chunk. This chunk may contain speech from both the AGENT and the CALLER. Split the text into segments by speaker. The agent asks questions, verifies info, offers help, and uses professional language. The caller provides personal info (name, email, phone, address), describes problems, and asks about orders/products. Return JSON with a segments array. Each segment has speaker (agent or caller) and text fields. Preserve the exact original text - do not paraphrase or summarize. If the entire chunk is one speaker, return a single segment.\n\nTranscript chunk: {safe_text}',
                response_format => {{
                    'type': 'json',
                    'schema': {{
                        'type': 'object',
                        'properties': {{
                            'segments': {{
                                'type': 'array',
                                'items': {{
                                    'type': 'object',
                                    'properties': {{
                                        'speaker': {{'type': 'string'}},
                                        'text': {{'type': 'string'}}
                                    }},
                                    'required': ['speaker', 'text']
                                }}
                            }}
                        }},
                        'required': ['segments']
                    }}
                }}
            ))
        """
        cur.execute(sql)
        row = cur.fetchone()
        if row and row[0]:
            result = json.loads(row[0]) if isinstance(row[0], str) else row[0]
            segments = result.get("segments", [])
            if segments:
                for seg in segments:
                    seg["speaker"] = seg.get("speaker", "caller").lower()
                    if seg["speaker"] not in ("agent", "caller"):
                        seg["speaker"] = "caller"
                return segments
        return [{"speaker": "caller", "text": text}]
    except Exception as e:
        logger.error(f"Speaker diarization failed: {e}")
        return [{"speaker": "caller", "text": text}]
    finally:
        cur.close()
        conn.close()


def get_customer_orders(customer_id: int) -> List[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute("""
            SELECT o.order_id, o.order_number, o.order_date, o.status, o.total, o.tracking_number
            FROM ORDERS o
            WHERE o.customer_id = %s
            ORDER BY o.order_date DESC
        """, (customer_id,))
        cols = [d[0].lower() for d in cur.description]
        orders = []
        for row in cur.fetchall():
            order = dict(zip(cols, row))
            order["order_date"] = str(order["order_date"]) if order["order_date"] else None
            cur2 = conn.cursor()
            cur2.execute("""
                SELECT p.name, oi.quantity, oi.price
                FROM ORDER_ITEMS oi
                JOIN PRODUCTS p ON oi.product_id = p.product_id
                WHERE oi.order_id = %s
            """, (order["order_id"],))
            items = []
            for item_row in cur2.fetchall():
                items.append({
                    "product_name": item_row[0],
                    "quantity": item_row[1],
                    "price": float(item_row[2]) if item_row[2] else 0
                })
            cur2.close()
            order["items"] = items
            order["total"] = float(order["total"]) if order["total"] else 0
            orders.append(order)
        return orders
    finally:
        cur.close()
        conn.close()


def upload_audio_to_stage(local_path: str, stage_filename: str) -> bool:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute(f"PUT file://{local_path} {STAGE} AUTO_COMPRESS=FALSE OVERWRITE=TRUE")
        return True
    except Exception as e:
        logger.error(f"Stage upload failed: {e}")
        return False
    finally:
        cur.close()
        conn.close()


def transcribe_audio(stage_filename: str) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute(f"""
            SELECT TO_VARCHAR(AI_TRANSCRIBE(TO_FILE('{STAGE}', '{stage_filename}')))
        """)
        row = cur.fetchone()
        if row and row[0]:
            return json.loads(row[0])
        return None
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        return None
    finally:
        cur.close()
        conn.close()


def insert_transcript(case_id: int, call_id: str, chunk: int, stream_type: str, text: str, duration: float):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute("""
            INSERT INTO CALL_TRANSCRIPTS (case_id, call_id, chunk_number, stream_type, transcript_text, audio_duration)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (case_id, call_id, chunk, stream_type, text, duration))
    finally:
        cur.close()
        conn.close()


def get_full_transcript(call_id: str) -> str:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute("""
            SELECT transcript_text
            FROM CALL_TRANSCRIPTS
            WHERE call_id = %s
            ORDER BY chunk_number, created_at
        """, (call_id,))
        texts = [row[0] for row in cur.fetchall() if row[0]]
        return " ".join(texts)
    finally:
        cur.close()
        conn.close()


def extract_call_info(transcript: str) -> Dict[str, Any]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        safe_text = transcript.replace("'", "''")
        sql = f"""
            SELECT TO_VARCHAR(AI_EXTRACT(
                text => '{safe_text}',
                responseFormat => {{
                    'customer_name': 'What is the caller or customer name?',
                    'customer_phone': 'What is the caller phone number?',
                    'customer_email': 'What is the caller email address?',
                    'order_number': 'What order number did the caller mention?',
                    'product_name': 'What product is the caller calling about?',
                    'issue_description': 'What is the issue or problem the caller is describing?',
                    'resolution_requested': 'What resolution is the caller requesting?',
                    'shipping_address': 'What shipping address did the caller mention?',
                    'return_reason': 'What is the reason for return if mentioned?'
                }}
            ))
        """
        cur.execute(sql)
        row = cur.fetchone()
        if row and row[0]:
            result = json.loads(row[0])
            return result.get("response", result)
        return {}
    except Exception as e:
        logger.error(f"AI extraction failed: {e}")
        return {}
    finally:
        cur.close()
        conn.close()


def save_candidate_values(case_id: int, call_id: str, extracted: Dict[str, Any]):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        for field_name, field_value in extracted.items():
            if field_value and str(field_value).strip() and str(field_value).lower() not in ("none", "null", "n/a", ""):
                cur.execute("""
                    SELECT COUNT(*) FROM CALL_CANDIDATE_VALUES
                    WHERE call_id = %s AND field_name = %s AND field_value = %s
                """, (call_id, field_name, str(field_value)))
                if cur.fetchone()[0] == 0:
                    cur.execute("""
                        INSERT INTO CALL_CANDIDATE_VALUES (case_id, call_id, field_name, field_value)
                        VALUES (%s, %s, %s, %s)
                    """, (case_id, call_id, field_name, str(field_value)))
    finally:
        cur.close()
        conn.close()


def get_candidate_values(call_id: str) -> List[Dict[str, str]]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute("""
            SELECT field_name, field_value
            FROM CALL_CANDIDATE_VALUES
            WHERE call_id = %s
            ORDER BY created_at DESC
        """, (call_id,))
        return [{"field_name": r[0], "field_value": r[1]} for r in cur.fetchall()]
    finally:
        cur.close()
        conn.close()


def match_products(customer_id: int, product_mention: str) -> List[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        safe_product = product_mention.replace("'", "''")
        cur.execute(f"""
            SELECT p.name, p.category, p.price, p.sku,
                   oi.quantity, o.order_number, o.status, o.order_date, o.tracking_number,
                   AI_SIMILARITY('{safe_product}', p.name) AS match_score
            FROM ORDER_ITEMS oi
            JOIN PRODUCTS p ON oi.product_id = p.product_id
            JOIN ORDERS o ON oi.order_id = o.order_id
            WHERE o.customer_id = {customer_id}
              AND AI_SIMILARITY('{safe_product}', p.name) > {config.SIMILARITY_THRESHOLD_PRODUCT}
            ORDER BY match_score DESC
        """)
        cols = ["product_name", "category", "price", "sku", "quantity",
                "order_number", "order_status", "order_date", "tracking_number", "match_score"]
        results = []
        for row in cur.fetchall():
            d = dict(zip(cols, row))
            d["price"] = float(d["price"]) if d["price"] else 0
            d["match_score"] = float(d["match_score"]) if d["match_score"] else 0
            d["order_date"] = str(d["order_date"]) if d["order_date"] else None
            results.append(d)
        return results
    except Exception as e:
        logger.error(f"Product matching failed: {e}")
        return []
    finally:
        cur.close()
        conn.close()


def reset_runtime_data():
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        cur.execute("REMOVE @CALL_CENTER.STG.TRANSCRIPTS")
        cur.execute("TRUNCATE TABLE CALL_TRANSCRIPTS")
        cur.execute("TRUNCATE TABLE CALL_CANDIDATE_VALUES")
        return True
    except Exception as e:
        logger.error(f"Reset failed: {e}")
        return False
    finally:
        cur.close()
        conn.close()


def find_similar_cases(issue_description: str) -> List[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(f"USE DATABASE {DB}")
        safe_issue = issue_description.replace("'", "''")
        cur.execute(f"""
            SELECT case_number, customer_name, product_name, case_type,
                   status, priority, issue_description, resolution, opened_date,
                   AI_SIMILARITY('{safe_issue}', issue_description) AS match_score
            FROM CASES
            WHERE AI_SIMILARITY('{safe_issue}', issue_description) > {config.SIMILARITY_THRESHOLD_CASE}
            ORDER BY match_score DESC
            LIMIT 10
        """)
        cols = ["case_number", "customer_name", "product_name", "case_type",
                "status", "priority", "issue_description", "resolution", "opened_date", "match_score"]
        results = []
        for row in cur.fetchall():
            d = dict(zip(cols, row))
            d["match_score"] = float(d["match_score"]) if d["match_score"] else 0
            d["opened_date"] = str(d["opened_date"]) if d["opened_date"] else None
            results.append(d)
        return results
    except Exception as e:
        logger.error(f"Similar case detection failed: {e}")
        return []
    finally:
        cur.close()
        conn.close()
