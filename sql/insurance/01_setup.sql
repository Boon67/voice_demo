-- =============================================================================
-- Rental Insurance FNOL Demo — Schema Setup
-- =============================================================================
-- Creates the RENTAL_INSURANCE database, schemas, internal stage, and all
-- hybrid tables required by the FNOL demo application.
--
-- Prerequisites:
--   • SYSADMIN role (or equivalent).
--   • A running warehouse (COMPUTE_WH or equivalent).
--
-- Usage:
--   snow sql -f sql/insurance/01_setup.sql
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- -----------------------------------------------------------------------------
-- 1. Database & Schemas
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS RENTAL_INSURANCE;

USE DATABASE RENTAL_INSURANCE;

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
CREATE OR REPLACE HYBRID TABLE PUBLIC.POLICYHOLDERS (
    POLICYHOLDER_ID  NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    NAME             VARCHAR(200) NOT NULL,
    EMAIL            VARCHAR(200),
    PHONE            VARCHAR(20),
    POLICY_TIER      VARCHAR(20),
    POLICY_NUMBER    VARCHAR(50),
    ADDRESS          VARCHAR(500),
    DRIVERS_LICENSE  VARCHAR(50),
    PRIMARY KEY (POLICYHOLDER_ID),
    INDEX IDX_PH_NAME   (NAME),
    INDEX IDX_PH_EMAIL  (EMAIL),
    INDEX IDX_PH_PHONE  (PHONE),
    INDEX IDX_PH_POLICY (POLICY_NUMBER)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.VEHICLES (
    VEHICLE_ID    NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    CLASS_NAME    VARCHAR(200) NOT NULL,
    CATEGORY      VARCHAR(100),
    DAILY_RATE    NUMBER(10,2),
    VEHICLE_CODE  VARCHAR(50),
    PRIMARY KEY (VEHICLE_ID)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.RENTAL_AGREEMENTS (
    AGREEMENT_ID      NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    POLICYHOLDER_ID   NUMBER(38,0) NOT NULL,
    AGREEMENT_NUMBER  VARCHAR(50)  NOT NULL,
    PICKUP_DATE       DATE,
    RETURN_DATE       DATE,
    STATUS            VARCHAR(20),
    TOTAL             NUMBER(10,2),
    LOCATION          VARCHAR(200),
    PRIMARY KEY (AGREEMENT_ID),
    FOREIGN KEY (POLICYHOLDER_ID) REFERENCES RENTAL_INSURANCE.PUBLIC.POLICYHOLDERS(POLICYHOLDER_ID),
    INDEX IDX_AGR_PH     (POLICYHOLDER_ID),
    INDEX IDX_AGR_NUMBER (AGREEMENT_NUMBER)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.RENTAL_ITEMS (
    ITEM_ID      NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    AGREEMENT_ID NUMBER(38,0) NOT NULL,
    VEHICLE_ID   NUMBER(38,0) NOT NULL,
    QUANTITY     NUMBER(38,0),
    DAILY_RATE   NUMBER(10,2),
    PRIMARY KEY (ITEM_ID),
    FOREIGN KEY (AGREEMENT_ID) REFERENCES RENTAL_INSURANCE.PUBLIC.RENTAL_AGREEMENTS(AGREEMENT_ID),
    FOREIGN KEY (VEHICLE_ID)   REFERENCES RENTAL_INSURANCE.PUBLIC.VEHICLES(VEHICLE_ID),
    INDEX IDX_RI_AGR (AGREEMENT_ID)
);

CREATE OR REPLACE HYBRID TABLE PUBLIC.CLAIMS (
    CLAIM_ID          NUMBER(38,0) NOT NULL AUTOINCREMENT START 1 INCREMENT 1 NOORDER,
    CLAIM_NUMBER      VARCHAR(50)   NOT NULL,
    POLICYHOLDER_ID   NUMBER(38,0),
    POLICYHOLDER_NAME VARCHAR(200),
    VEHICLE_ID        NUMBER(38,0),
    VEHICLE_NAME      VARCHAR(200),
    CLAIM_TYPE        VARCHAR(50),
    STATUS            VARCHAR(20),
    PRIORITY          VARCHAR(20),
    LOSS_DESCRIPTION  VARCHAR(2000),
    CLAIM_RESOLUTION  VARCHAR(2000),
    INCIDENT_DATE     DATE,
    PRIMARY KEY (CLAIM_ID),
    INDEX IDX_CLM_NUMBER (CLAIM_NUMBER),
    INDEX IDX_CLM_STATUS (STATUS)
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
SELECT 'Setup complete — 7 hybrid tables + 1 stage created in RENTAL_INSURANCE.' AS STATUS;
