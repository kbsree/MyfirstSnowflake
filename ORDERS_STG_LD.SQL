use database dev_webinar_orders_rl_db;
use schema tpch;
use warehouse dev_webinar_wh;

-- Create a table
CREATE TABLE orders_stg (
    o_orderkey INT,
    o_custkey INT,
    o_orderstatus VARCHAR(1),
    o_totalprice DECIMAL(10, 2),
    o_orderdate DATE,
    o_orderpriority VARCHAR(15),
    o_clerk VARCHAR(15),
    o_shippriority INT,
    o_comment VARCHAR(255),
    last_modified_dt TIMESTAMP,
    dw_file_name VARCHAR(255),
    dw_file_row_no INT,
    dw_load_ts TIMESTAMP
);

-- Truncate/Load Pattern
-- truncate stage prior to bulk load
truncate table orders_stg;

-- perform bulk load
copy into
    orders_stg
from
    (
    select
         s.$1                                            -- o_orderkey
        ,s.$2                                            -- o_custkey
        ,s.$3                                            -- o_orderstatus
        ,s.$4                                            -- o_totalprice
        ,s.$5                                            -- o_orderdate
        ,s.$6                                            -- o_orderpriority
        ,s.$7                                            -- o_clerk
        ,s.$8                                            -- o_shippriority
        ,s.$9                                            -- o_comment
        ,s.$10                                           -- last_modified_dt
        ,metadata$filename                               -- dw_file_name
        ,metadata$file_row_number                        -- dw_file_row_no
        ,current_timestamp()                             -- dw_load_ts
    from
        @~ s
    )
purge         = true
pattern       = '.*orders/data.*\.csv\.gz'
file_format   = ( type=csv field_optionally_enclosed_by = '"' )
on_error      = skip_file
--validation_mode = return_all_errors
;

--
-- review history of load errors
--
select 
    *
from 
    table(information_schema.copy_history(table_name=>'ORDERS_STG', start_time=> dateadd(hours, -1, current_timestamp())))
where
    status = 'Loaded'
order by
    last_load_time desc
;
