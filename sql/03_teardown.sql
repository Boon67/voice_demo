-- =============================================================================
-- Call Center AI Demo — Teardown
-- =============================================================================
-- Drops the entire CALL_CENTER database and all objects within it.
-- USE WITH CAUTION — this is irreversible.
--
-- Usage:
--   snowsql -f sql/03_teardown.sql
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Drop the entire database (cascades to all schemas, tables, stages)
DROP DATABASE IF EXISTS CALL_CENTER;

SELECT 'Teardown complete — CALL_CENTER database dropped.' AS STATUS;
