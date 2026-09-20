-- protection/06_apply_row_access_policy.sql
-- Applies the single policy only where the inspected physical schema has
-- BRANCH_CODE. A different existing row policy is an error, not overwritten.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

CREATE OR REPLACE PROCEDURE APPLY_BRANCH_ROW_ACCESS_POLICY()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS
$$
var targets = [
  { database: 'RAW', schema: 'PUBLIC', table: 'ACCOUNT' },
  { database: 'ANALYTICS', schema: 'MARTS', table: 'MART_DEPOSITS' }
];
var policy = 'GOVERNANCE.CATALOG.BRANCH_ENTITLEMENT_POLICY';
var applied = 0;

function quoted(identifier) {
  return '"' + identifier.replace(/"/g, '""') + '"';
}

for (var i = 0; i < targets.length; i++) {
  var target = targets[i];
  var qualified = target.database + '.' + target.schema + '.' + target.table;
  var columns = snowflake.createStatement({
    sqlText: 'SELECT COUNT(*) FROM ' + quoted(target.database) +
      '.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?',
    binds: [target.schema, target.table, 'BRANCH_CODE']
  }).execute();
  columns.next();
  if (columns.getColumnValue(1) !== 1) {
    throw 'Required BRANCH_CODE column is absent from ' + qualified;
  }

  var references = snowflake.createStatement({
    sqlText: "SELECT POLICY_DB, POLICY_SCHEMA, POLICY_NAME FROM TABLE(" +
      "GOVERNANCE.INFORMATION_SCHEMA.POLICY_REFERENCES(" +
      "REF_ENTITY_NAME => '" + qualified + "', REF_ENTITY_DOMAIN => 'TABLE')) " +
      "WHERE POLICY_KIND = 'ROW_ACCESS_POLICY'"
  }).execute();

  if (references.next()) {
    var existing = references.getColumnValue(1) + '.' +
      references.getColumnValue(2) + '.' + references.getColumnValue(3);
    if (existing.toUpperCase() !== policy) {
      throw 'A different row access policy is already attached to ' + qualified + ': ' + existing;
    }
    continue;
  }

  snowflake.createStatement({
    sqlText: 'ALTER TABLE ' + quoted(target.database) + '.' + quoted(target.schema) + '.' +
      quoted(target.table) + ' ADD ROW ACCESS POLICY ' + policy + ' ON (' + quoted('BRANCH_CODE') + ')'
  }).execute();
  applied++;
}

return 'Branch row access policy applied to ' + applied + ' table(s).';
$$;

CALL APPLY_BRANCH_ROW_ACCESS_POLICY();
