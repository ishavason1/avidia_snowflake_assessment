{{ config(tags=['foundation'], store_failures=false) }}

-- Structural prerequisite, not one of the six DQ dimensions.
select count(*) as mart_row_count
from {{ ref('mart_deposits') }}
having count(*) = 0
