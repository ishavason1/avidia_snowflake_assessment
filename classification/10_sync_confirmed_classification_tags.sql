-- classification/10_sync_confirmed_classification_tags.sql
-- Apply GOVERNANCE.CATALOG.CLASSIFICATION only from APPROVED steward decisions.
-- Detection alone never drives the protection tag.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

CREATE OR REPLACE PROCEDURE SYNC_CONFIRMED_CLASSIFICATION_TAGS()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS
$$

function quoteIdentifier(value) {
    return '"' + String(value).replace(/"/g, '""') + '"';
}

function quoteLiteral(value) {
    return "'" + String(value).replace(/'/g, "''") + "'";
}

var approvedSql = `
    SELECT
        REVIEW_ID,
        DATABASE_NAME,
        SCHEMA_NAME,
        TABLE_NAME,
        COLUMN_NAME,
        CONFIRMED_CLASSIFICATION,
        REVIEWED_BY
    FROM GOVERNANCE.CATALOG.CLASSIFICATION_REVIEW_QUEUE
    WHERE REVIEW_STATUS = 'APPROVED'
      AND CONFIRMED_CLASSIFICATION IS NOT NULL
    ORDER BY DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, COLUMN_NAME
`;

var approvedStmt = snowflake.createStatement({
    sqlText: approvedSql
});

var approvedRows = approvedStmt.execute();

var appliedCount = 0;

while (approvedRows.next()) {

    var reviewId =
        approvedRows.getColumnValue("REVIEW_ID");

    var databaseName =
        approvedRows.getColumnValue("DATABASE_NAME");

    var schemaName =
        approvedRows.getColumnValue("SCHEMA_NAME");

    var tableName =
        approvedRows.getColumnValue("TABLE_NAME");

    var columnName =
        approvedRows.getColumnValue("COLUMN_NAME");

    var classification =
        approvedRows.getColumnValue("CONFIRMED_CLASSIFICATION");

    var reviewedBy =
        approvedRows.getColumnValue("REVIEWED_BY");


    // Determine whether the object is a TABLE or VIEW
    // from the already-harvested governance metadata.
    var typeStmt = snowflake.createStatement({
        sqlText: `
            SELECT OBJECT_TYPE
            FROM GOVERNANCE.CATALOG.TABLE_METADATA
            WHERE DATABASE_NAME = ?
              AND SCHEMA_NAME = ?
              AND TABLE_NAME = ?
            LIMIT 1
        `,
        binds: [
            databaseName,
            schemaName,
            tableName
        ]
    });

    var typeRows = typeStmt.execute();

    if (!typeRows.next()) {
        throw "Object type not found in TABLE_METADATA for "
            + databaseName + "."
            + schemaName + "."
            + tableName;
    }

    var objectType =
        String(typeRows.getColumnValue("OBJECT_TYPE")).toUpperCase();

    var alterKeyword =
        objectType.includes("VIEW")
            ? "ALTER VIEW "
            : "ALTER TABLE ";


    var fullObjectName =
        quoteIdentifier(databaseName) + "." +
        quoteIdentifier(schemaName) + "." +
        quoteIdentifier(tableName);


    var alterSql =
        alterKeyword +
        fullObjectName +
        " MODIFY COLUMN " +
        quoteIdentifier(columnName) +
        " SET TAG GOVERNANCE.CATALOG.CLASSIFICATION = " +
        quoteLiteral(classification);


    snowflake.createStatement({
        sqlText: alterSql
    }).execute();


    // Audit trail
    snowflake.createStatement({
        sqlText: `
            INSERT INTO GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY (
                TAG_NAME,
                OBJECT_TYPE,
                OBJECT_IDENTIFIER,
                TAG_VALUE,
                ASSIGNED_BY,
                ASSIGNED_AT,
                HARVEST_ID
            )
            VALUES (
                'CLASSIFICATION',
                'COLUMN',
                ?,
                ?,
                ?,
                CURRENT_TIMESTAMP(),
                ?
            )
        `,
        binds: [
            databaseName + "." +
                schemaName + "." +
                tableName + "." +
                columnName,

            classification,

            reviewedBy,

            "STEWARD_APPROVAL:" + reviewId
        ]
    }).execute();

    appliedCount++;
}

return "Confirmed classification tags synchronized: "
       + appliedCount;
$$;


CALL SYNC_CONFIRMED_CLASSIFICATION_TAGS();