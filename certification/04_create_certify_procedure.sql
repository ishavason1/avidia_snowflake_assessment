-- certification/04_create_certify_procedure.sql

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

CREATE OR REPLACE PROCEDURE GOVERNANCE.CATALOG.CERTIFY_MART_DEPOSITS()
RETURNS OBJECT
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$

DECLARE
    V_RUN_ID VARCHAR;
    V_STARTED_AT TIMESTAMP_LTZ;
    V_COMPLETED_AT TIMESTAMP_LTZ;

    V_OWNER_COUNT NUMBER DEFAULT 0;
    V_STEWARD_COUNT NUMBER DEFAULT 0;

    V_TOTAL_COLUMNS NUMBER DEFAULT 0;
    V_DOCUMENTED_COLUMNS NUMBER DEFAULT 0;

    V_LINEAGE_COUNT NUMBER DEFAULT 0;

    V_LATEST_DQ_INVOCATION VARCHAR;
    V_DQ_COUNT NUMBER DEFAULT 0;
    V_DQ_DIMENSION_COUNT NUMBER DEFAULT 0;
    V_DQ_FAILURE_COUNT NUMBER DEFAULT 0;

    V_SECURITY_GAP_COUNT NUMBER DEFAULT 0;

    V_ADOPTION_QUERY_COUNT NUMBER DEFAULT 0;

    V_ACCURACY_PASS_COUNT NUMBER DEFAULT 0;

    V_OWNED_STATUS VARCHAR;
    V_DEFINED_STATUS VARCHAR;
    V_TRACEABLE_STATUS VARCHAR;
    V_TRUSTED_STATUS VARCHAR;
    V_SECURE_STATUS VARCHAR;
    V_ADOPTED_STATUS VARCHAR;
    V_RECONCILED_STATUS VARCHAR;

    V_PASSED_CONTROLS NUMBER DEFAULT 0;
    V_FINAL_STATUS VARCHAR;

    V_LAST_CERTIFIED VARCHAR;
    V_SQL VARCHAR;

BEGIN

    ------------------------------------------------------------------
    -- Start certification run
    ------------------------------------------------------------------

    V_RUN_ID := UUID_STRING();
    V_STARTED_AT := CURRENT_TIMESTAMP();


    ------------------------------------------------------------------
    -- 1. OWNED
    --
    -- Ownership evidence is refreshed outside the stored procedure
    -- using live Information Schema tag metadata.
    ------------------------------------------------------------------

    SELECT
        COUNT_IF(
            UPPER(EVIDENCE_KEY) = 'DATA_OWNER'
            AND EVIDENCE_VALUE IS NOT NULL
            AND TRIM(EVIDENCE_VALUE) <> ''
        ),

        COUNT_IF(
            UPPER(EVIDENCE_KEY) = 'DATA_STEWARD'
            AND EVIDENCE_VALUE IS NOT NULL
            AND TRIM(EVIDENCE_VALUE) <> ''
        )

    INTO
        :V_OWNER_COUNT,
        :V_STEWARD_COUNT

    FROM GOVERNANCE.CATALOG.CERTIFICATION_EVIDENCE

    WHERE DATABASE_NAME = 'ANALYTICS'
      AND SCHEMA_NAME = 'MARTS'
      AND OBJECT_NAME = 'MART_DEPOSITS'
      AND EVIDENCE_TYPE = 'OWNERSHIP_TAG';


    V_OWNED_STATUS :=
        IFF(
            V_OWNER_COUNT > 0
            AND V_STEWARD_COUNT > 0,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- 2. DEFINED
    --
    -- Every current MART_DEPOSITS column must have a non-empty
    -- description in the catalog.
    ------------------------------------------------------------------

    SELECT
        COUNT(*),

        COUNT_IF(
            DESCRIPTION IS NOT NULL
            AND TRIM(DESCRIPTION) <> ''
        )

    INTO
        :V_TOTAL_COLUMNS,
        :V_DOCUMENTED_COLUMNS

    FROM GOVERNANCE.CATALOG.CATALOG_MASTER_VIEW

    WHERE DATABASE_NAME = 'ANALYTICS'
      AND SCHEMA_NAME = 'MARTS'
      AND TABLE_NAME = 'MART_DEPOSITS';


    V_DEFINED_STATUS :=
        IFF(
            V_TOTAL_COLUMNS > 0
            AND V_DOCUMENTED_COLUMNS = V_TOTAL_COLUMNS,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- 3. TRACEABLE
    --
    -- Require actual native Snowflake GET_LINEAGE evidence flowing
    -- into MART_DEPOSITS.
    ------------------------------------------------------------------

    SELECT COUNT(*)
    INTO :V_LINEAGE_COUNT

    FROM GOVERNANCE.CATALOG.LINEAGE_EDGE

    WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'
      AND DIRECTION = 'UPSTREAM'
      AND TARGET_DATABASE = 'ANALYTICS'
      AND TARGET_SCHEMA = 'MARTS'
      AND TARGET_OBJECT = 'MART_DEPOSITS';


    V_TRACEABLE_STATUS :=
        IFF(
            V_LINEAGE_COUNT > 0,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- Resolve latest DQ invocation
    ------------------------------------------------------------------

    SELECT INVOCATION_ID
    INTO :V_LATEST_DQ_INVOCATION

    FROM GOVERNANCE.CATALOG.DQ_RESULT

    WHERE TARGET_TABLE = 'MART_DEPOSITS'
      AND INVOCATION_ID IS NOT NULL

    GROUP BY INVOCATION_ID

    ORDER BY MAX(EXECUTED_AT) DESC

    LIMIT 1;


    ------------------------------------------------------------------
    -- 4. TRUSTED
    --
    -- Latest invocation must contain exactly six distinct DQ
    -- dimensions and all six must PASS.
    ------------------------------------------------------------------

    SELECT
        COUNT(*),
        COUNT(DISTINCT CHECK_DIMENSION),
        COUNT_IF(UPPER(CHECK_RESULT) <> 'PASS')

    INTO
        :V_DQ_COUNT,
        :V_DQ_DIMENSION_COUNT,
        :V_DQ_FAILURE_COUNT

    FROM GOVERNANCE.CATALOG.DQ_RESULT

    WHERE TARGET_TABLE = 'MART_DEPOSITS'
      AND INVOCATION_ID = :V_LATEST_DQ_INVOCATION;


    V_TRUSTED_STATUS :=
        IFF(
            V_DQ_COUNT = 6
            AND V_DQ_DIMENSION_COUNT = 6
            AND V_DQ_FAILURE_COUNT = 0,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- 5. SECURE
    --
    -- There must be zero sensitive columns with missing/mismatched
    -- policy coverage.
    ------------------------------------------------------------------

    SELECT COUNT(*)
    INTO :V_SECURITY_GAP_COUNT

    FROM GOVERNANCE.CATALOG.SENSITIVE_POLICY_GAPS;


    V_SECURE_STATUS :=
        IFF(
            V_SECURITY_GAP_COUNT = 0,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- 6. ADOPTED
    --
    -- Recent consumer usage is captured outside this stored procedure
    -- into ADOPTION_EVIDENCE using live Information Schema query history.
    ------------------------------------------------------------------

    SELECT COUNT(*)
    INTO :V_ADOPTION_QUERY_COUNT

    FROM GOVERNANCE.CATALOG.ADOPTION_EVIDENCE

    WHERE DATABASE_NAME = 'ANALYTICS'
      AND SCHEMA_NAME = 'MARTS'
      AND OBJECT_NAME = 'MART_DEPOSITS'

      AND QUERY_START_TIME >= DATEADD(
          'HOUR',
          -167,
          CURRENT_TIMESTAMP()
      )

      AND ROLE_NAME IN (
          'DEPOSITS_ANALYST',
          'DATA_STEWARD',
          'BRANCH_HUDSON'
      );


    V_ADOPTED_STATUS :=
        IFF(
            V_ADOPTION_QUERY_COUNT > 0,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- 7. RECONCILED
    --
    -- Latest DQ invocation must contain exactly one passing ACCURACY
    -- reconciliation row.
    ------------------------------------------------------------------

    SELECT COUNT(*)
    INTO :V_ACCURACY_PASS_COUNT

    FROM GOVERNANCE.CATALOG.DQ_RESULT

    WHERE TARGET_TABLE = 'MART_DEPOSITS'
      AND INVOCATION_ID = :V_LATEST_DQ_INVOCATION
      AND UPPER(CHECK_DIMENSION) = 'ACCURACY'
      AND UPPER(CHECK_RESULT) = 'PASS';


    V_RECONCILED_STATUS :=
        IFF(
            V_ACCURACY_PASS_COUNT = 1,
            'PASS',
            'FAIL'
        );


    ------------------------------------------------------------------
    -- Persist seven-word scorecard
    ------------------------------------------------------------------

    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'OWNED',
        :V_OWNED_STATUS,
        :V_OWNER_COUNT || ' owner tag(s), '
            || :V_STEWARD_COUNT || ' steward tag(s)',
        'Requires refreshed DATA_OWNER and DATA_STEWARD evidence.',
        CURRENT_TIMESTAMP()
    );


    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'DEFINED',
        :V_DEFINED_STATUS,
        :V_DOCUMENTED_COLUMNS || '/' || :V_TOTAL_COLUMNS,
        'All current MART_DEPOSITS columns must have descriptions.',
        CURRENT_TIMESTAMP()
    );


    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'TRACEABLE',
        :V_TRACEABLE_STATUS,
        :V_LINEAGE_COUNT || ' native upstream edge(s)',
        'Requires native Snowflake GET_LINEAGE evidence into MART_DEPOSITS.',
        CURRENT_TIMESTAMP()
    );


    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'TRUSTED',
        :V_TRUSTED_STATUS,
        :V_DQ_DIMENSION_COUNT || '/6 DQ dimensions; '
            || :V_DQ_FAILURE_COUNT || ' failure(s)',
        'Latest DQ invocation must contain six passing dimensions.',
        CURRENT_TIMESTAMP()
    );


    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'SECURE',
        :V_SECURE_STATUS,
        :V_SECURITY_GAP_COUNT || ' protection gap(s)',
        'Sensitive-policy gap report must return zero rows.',
        CURRENT_TIMESTAMP()
    );


    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'ADOPTED',
        :V_ADOPTED_STATUS,
        :V_ADOPTION_QUERY_COUNT
            || ' consumer query/queries in recent evidence window',
        'Recent successful consumer usage must exist in ADOPTION_EVIDENCE.',
        CURRENT_TIMESTAMP()
    );


    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        'RECONCILED',
        :V_RECONCILED_STATUS,
        :V_ACCURACY_PASS_COUNT
            || ' passing accuracy reconciliation row(s)',
        'Latest DQ invocation must contain one passing ACCURACY check.',
        CURRENT_TIMESTAMP()
    );


    ------------------------------------------------------------------
    -- Compute final certification status dynamically
    ------------------------------------------------------------------

    SELECT COUNT_IF(CONTROL_STATUS = 'PASS')
    INTO :V_PASSED_CONTROLS

    FROM GOVERNANCE.CATALOG.CERTIFICATION_SCORECARD

    WHERE CERTIFICATION_RUN_ID = :V_RUN_ID;


    V_FINAL_STATUS :=
        IFF(
            V_PASSED_CONTROLS = 7,
            'CERTIFIED',
            'IN_PROGRESS'
        );


    V_COMPLETED_AT := CURRENT_TIMESTAMP();


    ------------------------------------------------------------------
    -- Persist certification run
    ------------------------------------------------------------------

    INSERT INTO GOVERNANCE.CATALOG.CERTIFICATION_RUN (
        CERTIFICATION_RUN_ID,
        DATABASE_NAME,
        SCHEMA_NAME,
        OBJECT_NAME,
        FINAL_STATUS,
        PASSED_CONTROLS,
        TOTAL_CONTROLS,
        CERTIFIED_BY,
        STARTED_AT,
        COMPLETED_AT
    )
    VALUES (
        :V_RUN_ID,
        'ANALYTICS',
        'MARTS',
        'MART_DEPOSITS',
        :V_FINAL_STATUS,
        :V_PASSED_CONTROLS,
        7,

        -- Avoid CURRENT_USER() inside owner-rights procedure.
        'DATA_OWNER',

        :V_STARTED_AT,
        :V_COMPLETED_AT
    );


    ------------------------------------------------------------------
    -- Apply certification tags only from computed outcome
    ------------------------------------------------------------------

    IF (V_FINAL_STATUS = 'CERTIFIED') THEN

        V_LAST_CERTIFIED :=
            TO_VARCHAR(
                V_COMPLETED_AT,
                'YYYY-MM-DD HH24:MI:SS TZH:TZM'
            );


        V_SQL :=
            'ALTER TABLE ANALYTICS.MARTS.MART_DEPOSITS '
            || 'SET TAG '
            || 'GOVERNANCE.CATALOG.CERTIFICATION = ''CERTIFIED'', '
            || 'GOVERNANCE.CATALOG.LAST_CERTIFIED = '''
            || REPLACE(
                V_LAST_CERTIFIED,
                '''',
                ''''''
            )
            || '''';


        EXECUTE IMMEDIATE :V_SQL;

    ELSE

        ALTER TABLE ANALYTICS.MARTS.MART_DEPOSITS
        SET TAG
            GOVERNANCE.CATALOG.CERTIFICATION = 'IN_PROGRESS';

    END IF;


    ------------------------------------------------------------------
    -- Return compact certification result
    ------------------------------------------------------------------

    RETURN OBJECT_CONSTRUCT(
        'certification_run_id', V_RUN_ID,
        'final_status', V_FINAL_STATUS,
        'passed_controls', V_PASSED_CONTROLS,
        'total_controls', 7,

        'owned', V_OWNED_STATUS,
        'defined', V_DEFINED_STATUS,
        'traceable', V_TRACEABLE_STATUS,
        'trusted', V_TRUSTED_STATUS,
        'secure', V_SECURE_STATUS,
        'adopted', V_ADOPTED_STATUS,
        'reconciled', V_RECONCILED_STATUS
    );

END;
$$;


----------------------------------------------------------------------
-- Execute certification
----------------------------------------------------------------------
USE ROLE DATA_OWNER;

CALL GOVERNANCE.CATALOG.CERTIFY_MART_DEPOSITS();
