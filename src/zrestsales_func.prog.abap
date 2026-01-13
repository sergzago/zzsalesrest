*&---------------------------------------------------------------------*
*& Include          ZRESTSALES_FUNC
*&---------------------------------------------------------------------*
form wms_connect
  using iv_werks type werks_d
  changing cv_conn type dbcon-con_name
           cv_scheme type dbcon-con_name.
  if iv_werks is initial.
    return.
  endif.

  case iv_werks.
    when '1999'.
      cv_conn = 'INFOR11'.
      cv_scheme = 'wmwhse1'.
    when '1998'.
      cv_conn = 'INFOR11'.
      cv_scheme = 'wmwhse2'.
    when '1997'.
      cv_conn = 'INFOR11'.
      cv_scheme = 'wmwhse3'.
  endcase.

  select single con_name
       from  dbcon
       where con_name = @cv_conn
         and dbms     = 'MSS'
       into @cv_conn.
endform.

form add_test_value
    changing ct_wms_result type standard table.
  data: lt_data type table of ts_wms_result.
  lt_data = value #(
    ( werks = '1014' matnr = '41097059' labst = 3 loc = 'MAG1014' )
    ( werks = '1014' matnr = '41146746' labst = 1 loc = 'MAG1014' )
    ( werks = '1014' matnr = '41146748' labst = 2 loc = 'MAG1014' )
    ( werks = '1014' matnr = '41146749' labst = 1 loc = 'MAG1014' )
    ( werks = '1014' matnr = '41146750' labst = 1 loc = 'MAG1014' )
    ( werks = '1014' matnr = '41146751' labst = 2 loc = 'MAG1014' )
    ( werks = '1014' matnr = '41185514' labst = 4 loc = 'MAG1014' )
    ( werks = '1033' matnr = '41095232' labst = 3 loc = 'MAG1033' )
    ( werks = '1033' matnr = '41095233' labst = 7 loc = 'MAG1033' )
    ( werks = '1033' matnr = '41095234' labst = 1 loc = 'MAG1033' )
    ( werks = '1033' matnr = '41095737' labst = 2 loc = 'MAG1033' )
    ( werks = '1033' matnr = '41096390' labst = 10 loc = 'MAG1033' )
    ( werks = '1033' matnr = '41097760' labst = 9 loc = 'MAG1033' )
  ).
 ct_wms_result[] = lt_data[].
endform.
