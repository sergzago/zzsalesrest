*&---------------------------------------------------------------------*
*& Include          ZRESTSALES_DATA
*&---------------------------------------------------------------------*
types: begin of ts_wms_result,
         werks type werks_d,
         matnr type matnr,
         labst type labst,
         loc type c length 10,
       end of ts_wms_result.
data:
  lv_werks type werks_d,
  lv_lgort type lgort_d,
  lv_mtart type mtart,
  lv_mapgr type range of zmaplnt-mapgr,
  gv_ucomm TYPE sy-ucomm.

DATA: lv_partner type c length 10.

SELECT SINGLE low
from TVARVC
into @lv_partner
where type EQ 'P' and name EQ 'ZLENTAPARTNER'.
