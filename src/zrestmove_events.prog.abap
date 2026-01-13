*&---------------------------------------------------------------------*
*& Include          ZRESTMOVE_EVENTS
*&---------------------------------------------------------------------*
start-of-selection.
data(go_app) = new lcl_app( ).
go_app->run(
  ir_werks = s_werks[]
  ir_sel = s_sel
  ir_ei = s_ei
  ir_only = s_only ).
