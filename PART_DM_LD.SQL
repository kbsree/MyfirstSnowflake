use database dev_webinar_pl_db;
use schema main;
use warehouse dev_webinar_wh;


CREATE TABLE part_dm (
    dw_part_shk binary(20),  -- Replace with the appropriate data type
    p_partkey NUMBER,    -- Replace with the appropriate data type
    part_name VARCHAR2(255),  -- Replace with the appropriate data type and length
    mfgr VARCHAR2(255),       -- Replace with the appropriate data type and length
    brand VARCHAR2(255),      -- Replace with the appropriate data type and length
    type VARCHAR2(255),       -- Replace with the appropriate data type and length
    size NUMBER,              -- Replace with the appropriate data type
    container VARCHAR2(255),  -- Replace with the appropriate data type and length
    retail_price NUMBER,      -- Replace with the appropriate data type
    comment VARCHAR2(4000),   -- Replace with the appropriate data type and length
    first_orderdate DATE,     -- Replace with the appropriate data type
    last_modified_dt DATE,    -- Replace with the appropriate data type
    dw_load_ts TIMESTAMP,     -- Replace with the appropriate data type
    dw_update_ts TIMESTAMP    -- Replace with the appropriate data type
);

execute immediate '

begin
    
   insert overwrite into part_dm
   select
       p.dw_part_shk
      ,p.p_partkey
      ,p.p_name as part_name
      ,p.p_mfgr as mfgr
      ,p.p_brand as brand
      ,p.p_type as type
      ,p.p_size as size
      ,p.p_container as container
      ,p.p_retailprice as retail_price
      ,p.p_comment as comment
      ,d.first_orderdate
      ,p.last_modified_dt
      ,p.dw_load_ts
      ,p.dw_update_ts
   from
       dev_webinar_orders_rl_db.tpch.part_ld p
       left join dev_webinar_il_db.main.part_first_order_dt d
         on d.dw_part_shk = p.dw_part_shk;
  
  return ''SUCCESS'';

end;'
;


select *
from dev_webinar_pl_db.main.part_dm p
where p_partkey in ( 105237594, 128236374);
