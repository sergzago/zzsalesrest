*&---------------------------------------------------------------------*
*& Include          ZRESTSALES_EVENTS
*&---------------------------------------------------------------------*
start-of-selection.
data(go_app) = new lcl_app( ).
go_app->run(
  ir_rc = s_rc
  ir_werks = s_werks[]
  ir_lgort = s_lgort[]
  ir_mtart = s_mtart[]
  ir_mapgr = s_mapgr[]
  ir_prcnt = p_prcnt
  "ir_sel = s_sel
  ir_ei = s_ei
  ir_only = s_only
  ir_long = s_long
  ir_sales = s_sales
  ir_mrktyp = s_mrktyp
  ir_jour = s_jour ).
