-- =============================================================================
-- Call Center AI Demo — Schema Setup
-- =============================================================================
-- Creates the CALL_CENTER database, schemas, internal stage, and all hybrid
-- tables required by the demo application.
--
-- Prerequisites:
--   • SYSADMIN role (or a role with CREATE DATABASE / CREATE SCHEMA / CREATE
--     STAGE / CREATE HYBRID TABLE privileges).
--   • A running warehouse (COMPUTE_WH or equivalent).
--
-- Usage:
--   snow sql -f sql/01_setup.sql
--   — or —
--   Execute in Snowsight / VS Code Snowflake extension.
--
-- After running this script, execute 02_seed_data.sql to populate demo data.
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- -----------------------------------------------------------------------------
-- 1. Database & Schemas
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS CALL_CENTER;

USE DATABASE CALL_CENTER;

CREATE SCHEMA IF NOT EXISTS PUBLIC;
CREATE SCHEMA IF NOT EXISTS STG;

-- -----------------------------------------------------------------------------
-- 2. Internal Stage (SSE encryption required for AI functions)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE STAGE STG.TRANSCRIPTS
  DIRECTORY  = (ENABLE = TRUE)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- -----------------------------------------------------------------------------
-- 3. Hybrid Tables — Reference Data
-- -----------------------------------------------------------------------------
CREATE OR REPLACE HYBRID TABLE PUBLIC.CUSTOMERS (
    CUSTOMER_ID   NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    NAME          VARCHAR(200) NOT NULL,
    EMAIL         VARCHAR(200),
    PHONE         VARCHAR(20),
    LOYALTY_TIER  VARCHAR(20),
    ADDRESS       VARCHAR(500),
    PRIMARY KEY (CUSTOMER_ID),
    INDEX IDX_CUSTOMERS_NAME  (NAME),
    INDEX IDX_CUSTOMERS_EMAIL (EMAIL),
    INDEX IDX_CUSTOMERS_PHONE (PHONE)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.PRODUCTS (
    PRODUCT_ID  NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    NAME        VARCHAR(200) NOT NULL,
    CATEGORY    VARCHAR(100),
    PRICE       NUMBER(10,2),
    SKU         VARCHAR(50),
    PRIMARY KEY (PRODUCT_ID)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.ORDERS (
    ORDER_ID        NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    CUSTOMER_ID     NUMBER(38,0) NOT NULL,
    ORDER_NUMBER    VARCHAR(50)  NOT NULL,
    ORDER_DATE      DATE,
    STATUS          VARCHAR(20),
    TOTAL           NUMBER(10,2),
    TRACKING_NUMBER VARCHAR(50),
    PRIMARY KEY (ORDER_ID),
    FOREIGN KEY (CUSTOMER_ID) REFERENCES CALL_CENTER.PUBLIC.CUSTOMERS(CUSTOMER_ID),
    INDEX IDX_ORDERS_CUSTOMER (CUSTOMER_ID),
    INDEX IDX_ORDERS_NUMBER   (ORDER_NUMBER)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.ORDER_ITEMS (
    ITEM_ID    NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    ORDER_ID   NUMBER(38,0) NOT NULL,
    PRODUCT_ID NUMBER(38,0) NOT NULL,
    QUANTITY   NUMBER(38,0),
    PRICE      NUMBER(10,2),
    PRIMARY KEY (ITEM_ID),
    FOREIGN KEY (ORDER_ID)   REFERENCES CALL_CENTER.PUBLIC.ORDERS(ORDER_ID),
    FOREIGN KEY (PRODUCT_ID) REFERENCES CALL_CENTER.PUBLIC.PRODUCTS(PRODUCT_ID),
    INDEX IDX_ITEMS_ORDER (ORDER_ID)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.CASES (
    CASE_ID           NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    CASE_NUMBER       VARCHAR(50)   NOT NULL,
    CUSTOMER_ID       NUMBER(38,0),
    CUSTOMER_NAME     VARCHAR(200),
    PRODUCT_ID        NUMBER(38,0),
    PRODUCT_NAME      VARCHAR(200),
    CASE_TYPE         VARCHAR(50),
    STATUS            VARCHAR(20),
    PRIORITY          VARCHAR(20),
    ISSUE_DESCRIPTION VARCHAR(2000),
    RESOLUTION        VARCHAR(2000),
    OPENED_DATE       DATE,
    PRIMARY KEY (CASE_ID),
    INDEX IDX_CASES_NUMBER (CASE_NUMBER),
    INDEX IDX_CASES_STATUS (STATUS)
);

-- -----------------------------------------------------------------------------
-- 4. Hybrid Tables — Runtime (populated during demo execution)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE HYBRID TABLE PUBLIC.CALL_TRANSCRIPTS (
    TRANSCRIPT_ID  NUMBER(38,0)    NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    CASE_ID        NUMBER(38,0),
    CALL_ID        VARCHAR(50),
    CHUNK_NUMBER   NUMBER(38,0),
    STREAM_TYPE    VARCHAR(20),
    TRANSCRIPT_TEXT VARCHAR(16777216),
    AUDIO_DURATION FLOAT,
    CREATED_AT     TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (TRANSCRIPT_ID),
    INDEX IDX_TRANSCRIPTS_CALL (CALL_ID)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.CALL_CANDIDATE_VALUES (
    ID          NUMBER(38,0)    NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    CASE_ID     NUMBER(38,0),
    CALL_ID     VARCHAR(50),
    FIELD_NAME  VARCHAR(100),
    FIELD_VALUE VARCHAR(2000),
    CREATED_AT  TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ID),
    INDEX IDX_CANDIDATES_CALL (CALL_ID)
);

-- -----------------------------------------------------------------------------
-- Done. Run 02_seed_data.sql next.
-- -----------------------------------------------------------------------------
SELECT 'Setup complete — 7 hybrid tables + 1 stage created in CALL_CENTER.' AS STATUS;
