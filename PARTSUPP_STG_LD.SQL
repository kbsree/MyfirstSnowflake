use database dev_webinar_orders_rl_db;
use schema   tpch;
use warehouse dev_webinar_wh;

-- Create a table

CREATE TABLE partsupp_stg (
    ps_partkey INT,
    ps_suppkey INT,
    ps_availqty INT,
    ps_supplycost DECIMAL(10, 2), -- Assuming supply cost is a decimal with 10 total digits and 2 decimal places
    ps_comment VARCHAR(255), -- Assuming ps_comment is a VARCHAR with a maximum length of 255 characters
    last_modified_dt TIMESTAMP,
    dw_file_name VARCHAR(255), -- Assuming dw_file_name is a VARCHAR with a maximum length of 255 characters
    dw_file_row_no INT,
    dw_load_ts TIMESTAMP
);

-- Truncate/Load Pattern
-- truncate stage prior to bulk load
truncate table partsupp_stg;

-- perform bulk load
copy into
    partsupp_stg
from
    (
    select
         s.$1                                            -- ps_partkey
        ,s.$2                                            -- ps_suppkey
        ,s.$3                                            -- ps_availqty
        ,s.$4                                            -- ps_supplycost
        ,s.$5                                            -- ps_comment
        ,s.$6                                            -- last_modified_dt
        ,metadata$filename                               -- dw_file_name
        ,metadata$file_row_number                        -- dw_file_row_no
        ,current_timestamp()                             -- dw_load_ts
    from
        @~ s
    )
purge         = true
pattern       = '.*partsupp/data.*\.csv\.gz'
file_format   = ( type=csv field_optionally_enclosed_by = '"' )
on_error      = skip_file
--validation_mode = return_all_errors
;

select * from partsupp_stg;


