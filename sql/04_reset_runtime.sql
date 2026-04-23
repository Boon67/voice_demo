-- =============================================================================
-- Call Center AI Demo — Reset Runtime Tables
-- =============================================================================
-- Clears data generated during demo runs (transcripts + candidate values)
-- while preserving all reference data (customers, products, orders, cases).
--
-- Run this between demo sessions to start with a clean slate.
--
-- Usage:
--   snow sql -f sql/04_reset_runtime.sql
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE CALL_CENTER;
USE SCHEMA PUBLIC;

TRUNCATE TABLE IF EXISTS CALL_CANDIDATE_VALUES;
TRUNCATE TABLE IF EXISTS CALL_TRANSCRIPTS;

-- Also clean up any files uploaded to the transcripts stage
REMOVE @CALL_CENTER.STG.TRANSCRIPTS;

SELECT 'Runtime reset complete — transcripts and candidates cleared.' AS STATUS;
