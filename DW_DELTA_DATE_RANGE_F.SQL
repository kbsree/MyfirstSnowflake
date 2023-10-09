use database dev_webinar_common_db;
use schema   util;

CREATE OR REPLACE FUNCTION dw_delta_date_range_f(
    p_period_type_cd VARCHAR
)
RETURNS TABLE(start_dt DATE, end_dt DATE)
AS
' SELECT 
    CASE LOWER(p_period_type_cd)
        WHEN ''all''     THEN current_date()
        WHEN ''day''     THEN date_trunc(''day'', event_dt)::DATE
        WHEN ''week''    THEN date_trunc(''week'', event_dt)::DATE
        WHEN ''month''   THEN date_trunc(''month'', event_dt)::DATE
        WHEN ''quarter'' THEN date_trunc(''quarter'', event_dt)::DATE
        WHEN ''year''    THEN date_trunc(''year'', event_dt)::DATE
        ELSE current_date()
    END AS start_dt,
    MAX(event_dt::DATE) + INTERVAL ''1 DAY'' AS end_dt 
FROM
    dw_delta_date
GROUP BY
   1
ORDER BY
   1
';






