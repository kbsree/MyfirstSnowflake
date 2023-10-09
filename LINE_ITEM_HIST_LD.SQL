use database dev_webinar_orders_rl_db;
create schema tpch;
use schema tpch;
use warehouse dev_webinar_wh;

CREATE  or replace TABLE line_item_hist (
    dw_line_item_shk binary (40), -- Assuming SHA1 hash is stored as a string
    dw_hash_diff binary (40), -- Assuming SHA1 hash is stored as a string
    dw_version_ts TIMESTAMP, -- Timestamp
    l_orderkey NUMBER, -- Assuming numeric data type
    o_orderdate DATE, -- Date
    l_partkey NUMBER, -- Assuming numeric data type
    l_suppkey NUMBER, -- Assuming numeric data type
    l_linenumber NUMBER, -- Assuming numeric data type
    l_quantity NUMBER, -- Assuming numeric data type
    l_extendedprice NUMBER, -- Assuming numeric data type
    l_discount NUMBER, -- Assuming numeric data type
    l_tax NUMBER, -- Assuming numeric data type
    l_returnflag VARCHAR2(1), -- Assuming single-character flag
    l_linestatus VARCHAR2(1), -- Assuming single-character status
    l_shipdate DATE, -- Date
    l_commitdate DATE, -- Date
    l_receiptdate DATE, -- Date
    l_shipinstruct VARCHAR2(50), -- Assuming a reasonable length
    l_shipmode VARCHAR2(20), -- Assuming a reasonable length
    l_comment VARCHAR2(2000), -- Assuming a reasonable length
    last_modified_dt TIMESTAMP, -- Timestamp
    dw_file_name VARCHAR2(255), -- Assuming a reasonable length
    dw_file_row_no NUMBER, -- Assuming numeric data type
    dw_load_ts TIMESTAMP -- Timestamp
);

EXECUTE immediate '

declare
  l_start_dt DATE;
  l_end_dt   DATE;
  -- Grab the dates for the logical partitions to process
  c1 cursor for select start_dt, end_dt FROM table(dev_webinar_common_db.util.dw_delta_date_range_f(''week'')) order by 1;

begin

  --
  -- Loop through the dates to incrementally process based on the logical partition definition.
  -- In this example, the logical partitions are by week.
  --
  for record in c1 do
    l_start_dt := record.start_dt;
    l_end_dt   := record.end_dt;

    --
    -- insert new and modified records into history table with version date
    -- dedupe source records as part of insert
    --
    -- run a second time to see that no rows will be inserted
    --
    insert into line_item_hist
    with l_stg as
    (
        --
        -- Driving CTE to identify all records in the logical partition to be processed.
        select
            -- generate hash key and hash diff to streamline processing
             sha1_binary( concat( s.l_orderkey, ''|'', s.l_linenumber ) )  as dw_line_item_shk
            --
            -- note that last_modified_dt is not included in the hash diff since it only represents recency of the record versus an 
            -- actual meaningful change in the data
            ,sha1_binary( concat( s.l_orderkey
                                         ,''|'', coalesce( to_char( s.o_orderdate, ''yyyymmdd'' ), ''~'' )
                                         ,''|'', s.l_linenumber
                                         ,''|'', coalesce( to_char( s.l_partkey ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_suppkey ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_quantity ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_extendedprice ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_discount ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_tax ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_returnflag ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_linestatus ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_shipdate, ''yyyymmdd'' ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_commitdate, ''yyyymmdd'' ), ''~'' )
                                         ,''|'', coalesce( to_char( s.l_receiptdate, ''yyyymmdd'' ), ''~'' )
                                         ,''|'', coalesce( s.l_shipinstruct, ''~'' )
                                         ,''|'', coalesce( s.l_shipmode, ''~'' )
                                         ,''|'', coalesce( s.l_comment, ''~'' )
                                )
        
                        )               as dw_hash_diff
            ,s.*
        from
            line_item_stg s
        where
                s.o_orderdate >= :l_start_dt
            and s.o_orderdate  < :l_end_dt
    )
    ,l_deduped as
    (
        --
        -- Dedupe the records from the staging table.
        -- This assumes that there may be late arriving or duplicate data that were loaded
        -- Need to identify the most recent record and use that to update the Current state table.
        -- as there is no reason to process each individual change in the record, the last one would have the most recent updates
        select
            *
        from
            l_stg
        qualify
            row_number() over( partition by dw_hash_diff order by last_modified_dt desc, dw_file_row_no )  = 1
    )
    select
         s.dw_line_item_shk
        ,s.dw_hash_diff
        ,s.dw_load_ts             as dw_version_ts
        ,s.l_orderkey
        ,s.o_orderdate
        ,s.l_partkey
        ,s.l_suppkey
        ,s.l_linenumber
        ,s.l_quantity
        ,s.l_extendedprice
        ,s.l_discount
        ,s.l_tax
        ,s.l_returnflag
        ,s.l_linestatus
        ,s.l_shipdate
        ,s.l_commitdate
        ,s.l_receiptdate
        ,s.l_shipinstruct
        ,s.l_shipmode
        ,s.l_comment
        ,s.last_modified_dt
        ,s.dw_file_name
        ,s.dw_file_row_no
        ,current_timestamp()    as dw_load_ts
    
    from
        l_deduped s
    where
        s.dw_hash_diff not in
        (
            select dw_hash_diff from line_item_hist 
            where
                    o_orderdate >= :l_start_dt
                and o_orderdate  < :l_end_dt
        )
    order by
        o_orderdate  -- physically sort rows by a logical partitioning date
    ;

  end for;

  return ''SUCCESS'';

end;'
;
