create database  dev_webinar_pl_db;
use database  dev_webinar_pl_db;
create schema main;
use schema main;
use warehouse dev_webinar_wh;

CREATE TABLE order_line_fact (
    dw_line_item_shk binary(20), -- Replace with the appropriate data type for your database
    o_orderdate DATE,
    dw_order_shk binary(20), -- Replace with the appropriate data type for your database
    dw_part_shk binary(20), -- Replace with the appropriate data type for your database
    dw_supplier_shk binary(20), -- Replace with the appropriate data type for your database
    quantity NUMBER, -- Replace with the appropriate data type for your database
    extendedprice NUMBER, -- Replace with the appropriate data type for your database
    discount NUMBER, -- Replace with the appropriate data type for your database
    tax NUMBER, -- Replace with the appropriate data type for your database
    returnflag VARCHAR2(255), -- Replace with the appropriate data type for your database
    linestatus VARCHAR2(255), -- Replace with the appropriate data type for your database
    l_shipdate DATE,
    l_commitdate DATE,
    l_receiptdate DATE,
    margin_amt NUMBER, -- Replace with the appropriate data type for your database
    dw_load_ts TIMESTAMP
);

execute immediate '

declare
  l_start_dt       date;
  l_end_dt         date;
  -- Grab the dates for the logical partitions to process
  c1 cursor for select start_dt, end_dt FROM table(dev_webinar_common_db.util.dw_delta_date_range_f(''week'')) order by 1;
  
begin
    
  --
  -- Loop through the dates to incrementally process based on the logical partition definition.
  -- In this example, the logical partitions are by week.
  --
  for record in c1 do
    l_start_dt       := record.start_dt;
    l_end_dt         := record.end_dt;

    --
    -- delete from the current table the logical partition to be processed.
    -- then insert the updated records.
    -- very similar to the Oracle method of inserting records into a table, and swapping that table into the Oracle partitioned table once proceessed
    --
    -- Start a transaction such that delete and insert are all committed at once.
    -- Decouple the for loop and begin transaction, fork processes to run concurrently - PUT PRESENTATION
       
     -- Delete the records using the logical partition 
     -- Very efficient when all the rows are in the same micropartitions.  Mirrors a truncate table in other database platforms.
     delete from order_line_fact
     where o_orderdate >= :l_start_dt
       and o_orderdate <  :l_end_dt;
 
     -- Insert the logical partitioned records into the table
     -- Inserts data from same order date into the same micropartitions
     -- Enables efficient querying of the data for consumption
     insert into order_line_fact
     select
         li.dw_line_item_shk
        ,o.o_orderdate
        ,o.dw_order_shk
        ,p.dw_part_shk
        ,s.dw_partsupp_shk
        ,li.l_quantity      as quantity
        ,li.l_extendedprice as extendedprice
        ,li.l_discount      as discount
        ,li.l_tax           as tax
        ,li.l_returnflag    as returnflag
        ,li.l_linestatus    as linestatus
        ,li.l_shipdate
        ,li.l_commitdate
        ,li.l_receiptdate
        ,lim.margin_amt
        ,current_timestamp() as dw_load_ts
     from
         dev_webinar_orders_rl_db.tpch.line_item_ld li
         --
         join dev_webinar_orders_rl_db.tpch.orders_ld o
           on o.o_orderkey = li.l_orderkey
         --
         join dev_webinar_il_db.main.line_item_margin lim
           on lim.dw_line_item_shk = li.dw_line_item_shk
         --
         -- Left outer join in case the part record is late arriving
         --
         left outer join dev_webinar_orders_rl_db.tpch.part_ld p
           on p.p_partkey = li.l_partkey
         --
         -- left outer join in case the supplier record is late arriving
         --
         left outer join dev_webinar_orders_rl_db.tpch.partsupp_ld s
           on s.ps_suppkey = li.l_suppkey
     where 
             li.o_orderdate >= :l_start_dt
         and li.o_orderdate <  :l_end_dt
     order by o.o_orderdate;

  end for;
  
  return ''SUCCESS'';

end;'
;


select olf.*
from dev_webinar_pl_db.main.order_line_fact olf
  join dev_webinar_orders_rl_db.tpch.line_item l
    on l.dw_line_item_shk = olf.dw_line_item_shk
where l.l_orderkey = 5722076550 
and l.l_partkey in ( 105237594, 128236374);
