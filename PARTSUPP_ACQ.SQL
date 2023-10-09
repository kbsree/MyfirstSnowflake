use database DEV_WEBINAR_ORDERS_RL_DB;
use schema   TPCH;
use warehouse DEV_WEBINAR_WH;

-- Create a table 
CREATE OR REPLACE TABLE partsupp (
    seq_no            NUMBER,
    ps_partkey        NUMBER,
    ps_suppkey        NUMBER,
    ps_availqty       NUMBER,
    ps_supplycost     NUMBER,
    ps_comment        STRING,
    last_modified_dt  TIMESTAMP
);

--COPY INTO TABLE 
-- run this 2 or 3 times to produce overlapping files with new and modified records.
copy into
    @~/partsupp
from
(
    with l_partsupp as
    (
        select
              row_number() over(order by uniform( 1, 60, random() ) ) as seq_no
             ,p.ps_partkey
             ,p.ps_suppkey
             ,p.ps_availqty
             ,p.ps_supplycost
             ,p.ps_comment
        from
            snowflake_sample_data.tpch_sf1000.partsupp p
    )
    select
         p.ps_partkey
        ,p.ps_suppkey
        ,p.ps_availqty
        ,p.ps_supplycost
        ,p.ps_comment
        ,current_timestamp()            as last_modified_dt -- generating a last modified timestamp as partsupp of data acquisition.
    from
        l_partsupp p
    order by
        p.ps_partkey
)
file_format      = ( type=csv field_optionally_enclosed_by = '"' )
overwrite        = false
single           = false
include_query_id = true
max_file_size    = 16000000
;
list @~/partsupp;
