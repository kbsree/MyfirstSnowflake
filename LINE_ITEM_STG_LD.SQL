use database dev_webinar_orders_rl_db;
use schema   tpch;
use warehouse dev_webinar_wh;

-- Create a table

CREATE or replace table  line_item_stg (
    l_orderkey int,
    o_orderdate DATE,
    l_partkey int,
    l_suppkey int,
    l_linenumber int,
    l_quantity decimal(10,2),
    l_extendedprice decimal(10,2),
    l_discount decimal(10,2) ,
    l_tax decimal(10,2),
    l_returnflag VARCHAR(255),
    l_linestatus VARCHAR(255),
    l_shipdate DATE,
    l_commitdate DATE,
    l_receiptdate DATE,
    l_shipinstruct VARCHAR(255),
    l_shipmode VARCHAR(255),
    l_comment VARCHAR(255),
    last_modified_dt TIMESTAMP,
    dw_file_name VARCHAR(255),
    dw_file_row_no int,
    dw_load_ts TIMESTAMP
);


-- Truncate/Load Pattern
-- truncate stage prior to bulk load, to clean out the rows from the prior load
truncate table line_item_stg;

-- perform bulk load
copy into
    line_item_stg
from
    (
    select
         s.$1                                            -- l_orderkey
        ,s.$2                                            -- o_orderdate
        ,s.$3                                            -- l_partkey
        ,s.$4                                            -- l_suppkey
        ,s.$5                                            -- l_linenumber
        ,s.$6                                            -- l_quantity
        ,s.$7                                            -- l_extendedprice
        ,s.$8                                            -- l_discount
        ,s.$9                                            -- l_tax
        ,s.$10                                           -- l_returnflag
        ,s.$11                                           -- l_linestatus
        ,s.$12                                           -- l_shipdate
        ,s.$13                                           -- l_commitdate
        ,s.$14                                           -- l_receiptdate
        ,s.$15                                           -- l_shipinstruct
        ,s.$16                                           -- l_shipmode
        ,s.$17                                           -- l_comment
        ,s.$18                                           -- last_modified_dt
        ,metadata$filename                               -- dw_file_name
        ,metadata$file_row_number                        -- dw_file_row_no
        ,current_timestamp()                             -- dw_load_ts
    from
        @~ s
    )
purge         = true
pattern       = '.*line_item/data.*\.csv\.gz'
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
    table(information_schema.copy_history(table_name=>'LINE_ITEM_STG', start_time=> dateadd(hours, -1, current_timestamp())))
where
    status = 'Loaded'
order by
    last_load_time desc
;


select * 
from dev_webinar_orders_rl_db.tpch.line_item_stg 
where l_orderkey = 5722076550
and l_partkey in ( 105237594, 128236374); -- 2 lines
