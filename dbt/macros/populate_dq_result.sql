{# SQL literals contain metadata/status only, never raw tax IDs or error payloads. #}
{% macro dq_sql_literal(value) -%}
  '{{ value | string | replace("\\", "\\\\") | replace("'", "''") }}'
{%- endmacro %}

{% macro populate_dq_result_from_tests(results=none) %}
  {% if execute and var('persist_dq_results', false) %}
    {% if flags.WHICH != 'test' %}
      {{ exceptions.raise_compiler_error("persist_dq_results is supported only for dbt test.") }}
    {% endif %}

    {% set dimensions = ['COMPLETENESS', 'UNIQUENESS', 'VALIDITY', 'CONSISTENCY', 'TIMELINESS', 'ACCURACY'] %}
    {% set tests = [] %}
    {% set found_dimensions = [] %}
    {% for node in graph.nodes.values() %}
      {% if node.resource_type == 'test' and node.config.meta.get('assessment') == 'deposits' %}
        {% do tests.append(node) %}
        {% do found_dimensions.append(node.config.meta.get('check_dimension')) %}
      {% endif %}
    {% endfor %}
    {% if tests | length != 6 or found_dimensions | sort != dimensions | sort %}
      {{ exceptions.raise_compiler_error("Deposits assessment requires exactly one test definition for each of the six dimensions.") }}
    {% endif %}

    {% set measured = {} %}
    {% set prerequisite = namespace(status='not_executed', failures=none) %}
    {% for result in results or [] %}
      {% do measured.update({result.node.unique_id: result}) %}
      {% if result.node.name == 'test_mart_deposits_not_empty' %}
        {% set prerequisite.status = result.status | string %}
        {% set prerequisite.failures = result.failures %}
      {% endif %}
    {% endfor %}
    {% set prerequisite_ok = prerequisite.status == 'pass' and prerequisite.failures == 0 %}

    {# Only query the GL snapshot if accuracy actually completed in this invocation.
       An errored/missing accuracy test must not prevent other outcomes being recorded. #}
    {% set accuracy = namespace(completed=false) %}
    {% for node in tests %}
      {% set result = measured.get(node.unique_id) %}
      {% if node.config.meta.check_dimension == 'ACCURACY' and result is not none %}
        {% if result.status | string in ['pass', 'fail'] and result.failures is number %}
          {% set accuracy.completed = true %}
        {% endif %}
      {% endif %}
    {% endfor %}

    {% set persist_sql %}
      merge into GOVERNANCE.CATALOG.DQ_RESULT target
      using (
        with snapshot as (
          {% if accuracy.completed %}
          select case
            when count(*) > 0 and count(as_of_date) = count(*)
                 and min(as_of_date) = max(as_of_date)
            then min(as_of_date)
            else null
          end as snapshot_date
          from {{ source('raw', 'gl_control') }}
          {% else %}
          select cast(null as date) as snapshot_date
          {% endif %}
        ), measured as (
          {% for node in tests %}
            {% set result = measured.get(node.unique_id) %}
            {% set status = result.status | string if result is not none else 'not_executed' %}
            {% set failures = result.failures if result is not none else none %}
            select
              {{ dq_sql_literal(invocation_id) }} as invocation_id,
              {{ dq_sql_literal(node.unique_id) }} as test_unique_id,
              {{ dq_sql_literal(node.name) }} as check_type,
              {{ dq_sql_literal(node.config.meta.check_dimension) }} as check_dimension,
              {{ dq_sql_literal(node.config.meta.target_column) }} as target_column,
              {{ dq_sql_literal(node.config.meta.failure_unit) }} as failure_unit,
              {{ dq_sql_literal(status) }} as dbt_status,
              {% if status in ['pass', 'fail'] and failures is number %}
                {{ failures | int }}
              {% else %}
                cast(null as integer)
              {% endif %} as failed_rows,
              {% if status in ['pass', 'fail'] and node.relation_name %}
                {{ dq_sql_literal(node.relation_name) }}
              {% else %}
                cast(null as varchar)
              {% endif %} as failure_relation
            {% if not loop.last %} union all {% endif %}
          {% endfor %}
        )
        select
          md5(m.invocation_id || ':' || m.test_unique_id) as dq_result_id,
          m.*,
          'MART_DEPOSITS' as mart_name,
          'MART_DEPOSITS' as target_table,
          case
            when m.dbt_status in ('not_executed', 'skipped') then 'NOT_EXECUTED'
            when m.dbt_status not in ('pass', 'fail')
                 or m.failed_rows is null or m.failed_rows < 0 then 'ERROR'
            when m.failed_rows > 0 then 'FAIL'
            when m.dbt_status <> 'pass' then 'ERROR'
            when not {{ 'true' if prerequisite_ok else 'false' }} then 'BLOCKED'
            else 'PASS'
          end as check_result,
          case when m.check_dimension = 'ACCURACY'
                    and m.dbt_status in ('pass', 'fail')
               then s.snapshot_date else null end as snapshot_date,
          {{ dq_sql_literal('Empty-mart prerequisite: ' ~ prerequisite.status ~ '; failures=' ~ prerequisite.failures ~ '. Failure relation is latest-run drill-down only; see matching dbt run_results for execution errors.') }} as details,
          current_timestamp() as executed_at,
          current_user() as executed_by
        from measured m cross join snapshot s
      ) incoming
      on target.INVOCATION_ID = incoming.invocation_id
         and target.TEST_UNIQUE_ID = incoming.test_unique_id
      when not matched then insert (
        DQ_RESULT_ID, INVOCATION_ID, TEST_UNIQUE_ID,
        MART_NAME, CHECK_DIMENSION, CHECK_TYPE, TARGET_TABLE, TARGET_COLUMN,
        CHECK_RESULT, DBT_STATUS, FAILED_ROWS, FAILURE_UNIT,
        SNAPSHOT_DATE, FAILURE_RELATION, DETAILS, EXECUTED_AT, EXECUTED_BY
      ) values (
        incoming.dq_result_id, incoming.invocation_id, incoming.test_unique_id,
        incoming.mart_name, incoming.check_dimension, incoming.check_type,
        incoming.target_table, incoming.target_column,
        incoming.check_result, incoming.dbt_status, incoming.failed_rows,
        incoming.failure_unit, incoming.snapshot_date, incoming.failure_relation,
        incoming.details, incoming.executed_at, incoming.executed_by
      )
    {% endset %}
    {% do run_query(persist_sql) %}
    {% do log("Recorded six measured deposits DQ results for invocation " ~ invocation_id, info=true) %}
  {% endif %}
{% endmacro %}
