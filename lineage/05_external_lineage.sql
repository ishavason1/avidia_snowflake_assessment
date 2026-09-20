-- lineage/05_external_lineage.sql
-- These edges are assessment-required external/manual context. They are not
-- part of the implemented Snowflake/dbt RAW -> STAGING -> MART pipeline.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

MERGE INTO GOVERNANCE.CATALOG.LINEAGE_EDGE_EXTERNAL AS T
USING (
  SELECT * FROM VALUES
    ('TALEND_LEGACY', 'talend://avidia/legacy_transaction_load', NULL,
     'SNOWFLAKE', 'RAW.PUBLIC.TRANSACTION', NULL,
     'LEGACY_EXTERNAL_UPSTREAM', 'EXTERNAL_MANUAL',
     'Assessment context only; Talend is not used by the implemented pipeline.'),
    ('SNOWFLAKE', 'ANALYTICS.MARTS.MART_DEPOSITS', NULL,
     'POWER_BI', 'powerbi://avidia/deposits-semantic-model', NULL,
     'EXTERNAL_DOWNSTREAM_CONSUMER', 'EXTERNAL_MANUAL',
     'Assessment context only; Power BI is outside Snowflake native lineage.')
  AS V(SOURCE_SYSTEM, SOURCE_OBJECT, SOURCE_COLUMN, TARGET_SYSTEM, TARGET_OBJECT,
         TARGET_COLUMN, RELATIONSHIP_TYPE, REGISTRATION_TYPE, NOTES)
) AS S
ON T.SOURCE_SYSTEM = S.SOURCE_SYSTEM
AND T.SOURCE_OBJECT = S.SOURCE_OBJECT
AND T.TARGET_SYSTEM = S.TARGET_SYSTEM
AND T.TARGET_OBJECT = S.TARGET_OBJECT
WHEN MATCHED THEN UPDATE SET
  T.RELATIONSHIP_TYPE = S.RELATIONSHIP_TYPE,
  T.REGISTRATION_TYPE = S.REGISTRATION_TYPE,
  T.NOTES = S.NOTES
WHEN NOT MATCHED THEN INSERT (
  SOURCE_SYSTEM, SOURCE_OBJECT, SOURCE_COLUMN, TARGET_SYSTEM, TARGET_OBJECT,
  TARGET_COLUMN, RELATIONSHIP_TYPE, REGISTRATION_TYPE, NOTES
) VALUES (
  S.SOURCE_SYSTEM, S.SOURCE_OBJECT, S.SOURCE_COLUMN, S.TARGET_SYSTEM, S.TARGET_OBJECT,
  S.TARGET_COLUMN, S.RELATIONSHIP_TYPE, S.REGISTRATION_TYPE, S.NOTES
);

-- Optional production registration guidance (not executed by this assessment):
-- POST https://<account>.snowflakecomputing.com/api/v2/lineage/external-lineage
-- with an OpenLineage COMPLETE event, for example:
-- {
--   "eventType": "COMPLETE", "eventTime": "<timestamp>",
--   "job": {"namespace": "talend://avidia", "name": "legacy_transaction_load"},
--   "inputs": [{"namespace": "talend://avidia", "name": "legacy_transaction_load"}],
--   "outputs": [{"namespace": "snowflake", "name": "RAW.PUBLIC.TRANSACTION",
--                "datasetType": "TABLE"}]
-- }
-- A second COMPLETE event would use ANALYTICS.MARTS.MART_DEPOSITS as an input
-- and powerbi://avidia/deposits-semantic-model as an output.
-- The sending role requires INGEST LINEAGE ON ACCOUNT. No REST/API call is
-- required for this assessment fallback table.
