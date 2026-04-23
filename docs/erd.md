# Call Center AI Demo — Entity Relationship Diagram

## ERD

![Entity Relationship Diagram](./diagrams/erd.svg)

## Table Definitions

### CUSTOMERS (Reference Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `CUSTOMER_ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique customer identifier |
| `NAME` | `VARCHAR(200)` | NOT NULL, INDEXED | Customer full name |
| `EMAIL` | `VARCHAR(200)` | INDEXED | Email address |
| `PHONE` | `VARCHAR(20)` | INDEXED | Phone number |
| `LOYALTY_TIER` | `VARCHAR(20)` | | PLATINUM, GOLD, SILVER |
| `ADDRESS` | `VARCHAR(500)` | | Mailing address |

**Seed data:** 8 customers. Diana Prince (PLATINUM) is the primary demo persona.

### PRODUCTS (Reference Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `PRODUCT_ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique product identifier |
| `NAME` | `VARCHAR(200)` | NOT NULL | Product name (used for AI_SIMILARITY matching) |
| `CATEGORY` | `VARCHAR(100)` | | Product category (Electronics, Footwear, etc.) |
| `PRICE` | `NUMBER(10,2)` | | Unit price |
| `SKU` | `VARCHAR(50)` | | Stock keeping unit code |

**Seed data:** 10 products. WH-NC100 (Wireless Noise-Canceling Headphones) is the key demo product.

### ORDERS (Reference Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `ORDER_ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique order identifier |
| `CUSTOMER_ID` | `NUMBER(38,0)` | FK → CUSTOMERS, INDEXED | Owning customer |
| `ORDER_NUMBER` | `VARCHAR(50)` | NOT NULL, INDEXED | Human-readable order number (e.g., ORD-2026-901) |
| `ORDER_DATE` | `DATE` | | Order placement date |
| `STATUS` | `VARCHAR(20)` | | PENDING, PROCESSING, SHIPPED, DELIVERED |
| `TOTAL` | `NUMBER(10,2)` | | Order total amount |
| `TRACKING_NUMBER` | `VARCHAR(50)` | | Shipping tracking number |

**Seed data:** 11 orders. 4 belong to Diana Prince.

### ORDER_ITEMS (Reference Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `ITEM_ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique line item identifier |
| `ORDER_ID` | `NUMBER(38,0)` | FK → ORDERS, INDEXED | Parent order |
| `PRODUCT_ID` | `NUMBER(38,0)` | FK → PRODUCTS | Product in this line item |
| `QUANTITY` | `NUMBER(38,0)` | | Quantity ordered |
| `PRICE` | `NUMBER(10,2)` | | Line item price |

**Seed data:** 14 order items across all orders.

### CASES (Reference Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `CASE_ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique case identifier |
| `CASE_NUMBER` | `VARCHAR(50)` | NOT NULL, INDEXED | Human-readable case number (e.g., CASE-2026-002) |
| `CUSTOMER_ID` | `NUMBER(38,0)` | | Customer who filed the case |
| `CUSTOMER_NAME` | `VARCHAR(200)` | | Denormalized customer name |
| `PRODUCT_ID` | `NUMBER(38,0)` | | Related product |
| `PRODUCT_NAME` | `VARCHAR(200)` | | Denormalized product name |
| `CASE_TYPE` | `VARCHAR(50)` | | DEFECT, RETURN, INQUIRY |
| `STATUS` | `VARCHAR(20)` | INDEXED | OPEN, CLOSED |
| `PRIORITY` | `VARCHAR(20)` | | CRITICAL, HIGH, MEDIUM, LOW |
| `ISSUE_DESCRIPTION` | `VARCHAR(2000)` | | Free-text issue description (used for AI_SIMILARITY) |
| `RESOLUTION` | `VARCHAR(2000)` | | Resolution taken (if closed) |
| `OPENED_DATE` | `DATE` | | Case open date |

**Seed data:** 7 cases. 5 are headphone defect cases (WH-NC100 left-ear audio issue pattern).

### CALL_TRANSCRIPTS (Runtime Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `TRANSCRIPT_ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique transcript record |
| `CASE_ID` | `NUMBER(38,0)` | | Associated case |
| `CALL_ID` | `VARCHAR(50)` | INDEXED | Call session identifier |
| `CHUNK_NUMBER` | `NUMBER(38,0)` | | Audio chunk sequence number |
| `STREAM_TYPE` | `VARCHAR(20)` | | Audio stream type |
| `TRANSCRIPT_TEXT` | `VARCHAR(16777216)` | | Transcribed text from AI_TRANSCRIBE |
| `AUDIO_DURATION` | `FLOAT` | | Duration of the audio chunk in seconds |
| `CREATED_AT` | `TIMESTAMP_NTZ(9)` | DEFAULT CURRENT_TIMESTAMP() | Record creation time |

**Runtime:** Populated during demo execution. Truncated on reset.

### CALL_CANDIDATE_VALUES (Runtime Data)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `ID` | `NUMBER(38,0)` | PK, AUTOINCREMENT | Unique record identifier |
| `CASE_ID` | `NUMBER(38,0)` | | Associated case |
| `CALL_ID` | `VARCHAR(50)` | INDEXED | Call session identifier |
| `FIELD_NAME` | `VARCHAR(100)` | | Extracted field name (e.g., customer_name, product_name) |
| `FIELD_VALUE` | `VARCHAR(2000)` | | Extracted field value |
| `CREATED_AT` | `TIMESTAMP_NTZ(9)` | DEFAULT CURRENT_TIMESTAMP() | Record creation time |

**Runtime:** Populated by AI_EXTRACT results. Truncated on reset.

## Relationships

| From | To | Cardinality | FK Column |
|------|----|-------------|-----------|
| CUSTOMERS | ORDERS | 1:N | `ORDERS.CUSTOMER_ID` |
| ORDERS | ORDER_ITEMS | 1:N | `ORDER_ITEMS.ORDER_ID` |
| PRODUCTS | ORDER_ITEMS | 1:N | `ORDER_ITEMS.PRODUCT_ID` |
| CUSTOMERS | CASES | 1:N | `CASES.CUSTOMER_ID` (logical) |
| CASES | CALL_TRANSCRIPTS | 1:N | `CALL_TRANSCRIPTS.CASE_ID` (logical) |
| CASES | CALL_CANDIDATE_VALUES | 1:N | `CALL_CANDIDATE_VALUES.CASE_ID` (logical) |

## Storage Details

- **Table type:** Snowflake Hybrid Tables (low-latency OLTP)
- **Stage:** `@CALL_CENTER.STG.TRANSCRIPTS` with `SNOWFLAKE_SSE` encryption (required for AI functions)
- **Database:** `CALL_CENTER`
- **Schemas:** `PUBLIC` (tables), `STG` (stages)
