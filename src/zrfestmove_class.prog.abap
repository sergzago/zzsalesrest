*----------------------------------------------------------------------*
***INCLUDE ZRESTSALES_CLASS.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class lcl_app
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      tr_werks TYPE RANGE OF werks_d,
      tr_sel type abap_bool,
      tr_ei type abap_bool,
      tr_only type abap_bool.
    METHODS:
      run
        IMPORTING
          ir_werks TYPE tr_werks
          ir_sel   type abap_bool
          ir_ei    type abap_bool
          ir_only  type abap_bool,
      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function.

  PRIVATE SECTION.
    types: begin of ty_rests,
            werks type werks_d,
            lgort type lgort_d,
            matnr type matnr,
            labst type labst,
            meins type meins,
            amount type p length 16 decimals 5,
            lntcode type c length 1,
           end of ty_rests.
    DATA:
*      mr_werks  type tr_werks,
      lv_sel type abap_bool,
      lv_ei type abap_bool,
      lv_only type abap_bool,
      ls_rests type ty_rests,
      lt_rests type table of ty_rests,
      lo_alv TYPE REF TO cl_salv_table,
      lo_columns TYPE REF TO cl_salv_columns_table,
      lo_column TYPE REF TO cl_salv_column_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_sorts type ref to cl_salv_sorts,
      lo_sort type ref to cl_salv_sort,
      mo_container    TYPE REF TO cl_gui_docking_container.


    METHODS:
      _get_main_data,
      _init_alv,
      _setup_alv
        importing
          io_alv TYPE REF TO cl_salv_table,
      _refresh_alv.
ENDCLASS.
*&---------------------------------------------------------------------*
*& Class (Implementation) lcl_app
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_app IMPLEMENTATION.
  METHOD run.
    lv_sel = ir_sel.
    lv_ei = ir_ei.
    lv_only = ir_only.
    _get_main_data( ).
    _init_alv( ).
    CALL SCREEN 0100.
  ENDMETHOD.
  METHOD _get_main_data.
*    data: lv_cur_date type dats.

*    lv_cur_date = sy-datum.
  data: lv_lntcode type matnr,
        lv_lntwerks type werks_d,
        ls_zmaplnt type zmaplnt,
        ls_zmapwerkslnt type zmapwerkslnt,
        ls_zmaplgortlnt type zmaplgortlnt.

    select mard~werks,
      mard~lgort,
      mard~matnr,
      mard~labst,
      mara~meins,
      mbew~lbkum,
      mbew~salk3
    into table @data(lt_rest)
    from mard
      join mara on mara~matnr eq mard~matnr
      join mbew on mbew~matnr eq mard~matnr and mbew~bwkey eq mard~werks
    where mard~werks in @s_werks
        and mard~labst NE 0
        "and mard~matnr EQ '000000000041162610'
    order by mard~werks,mard~matnr,mard~lgort.
    loop at lt_rest into data(ls_rest).
      clear ls_rests.
      ls_rests-lgort = ls_rest-lgort.
      ls_rests-werks = ls_rest-werks.
      ls_rests-matnr = ls_rest-matnr.
      if lv_sel EQ 'X'.
        select single * from zmaplnt
          into ls_zmaplnt
          where matnr = ls_rest-matnr.
        if sy-subrc = 0.
          ls_rests-matnr = ls_zmaplnt-matnr_lenta.
          ls_rests-lntcode = 'X'.
        endif.
        select single * from zmapwerkslnt
          into ls_zmapwerkslnt
          where werks = ls_rest-werks.
        if sy-subrc = 0.
          ls_rests-werks = ls_zmapwerkslnt-werks_lnt.
        endif.
        select single * from zmaplgortlnt
          into ls_zmaplgortlnt
          where lgort = ls_rest-lgort.
        if sy-subrc = 0.
          ls_rests-lgort = ls_zmaplgortlnt-lgort_lnt.
        else.
          ls_rests-lgort = '9999'.
        endif.
      else.
        select single * from zmaplnt
          into ls_zmaplnt
          where matnr = ls_rest-matnr.
        if sy-subrc = 0.
          ls_rests-lntcode = 'X'.
        endif.
      endif.
      ls_rests-amount = ls_rest-salk3 / ls_rest-lbkum  * ls_rest-labst.
      ls_rests-labst = ls_rest-labst.
      ls_rests-meins = ls_rest-meins.
* Пересчет ЕИ

*      if ( lv_ei EQ 'X' ) and ( ls_rest-meins eq 'KG' ).
*        "if ls_rest-meins eq 'KG'.
*          ls_rests-labst = ls_rest-labst * 1000.
*          ls_rests-meins = 'G'.
*        "endif.
*      endif.

      if ( lv_only eq '') or ( ls_rests-lntcode eq 'X').
        append ls_rests to lt_rests.
      endif.
    endloop.
  ENDMETHOD.
  METHOD _init_alv.

    mo_container = NEW #(
      repid = sy-repid
      dynnr = '0100'
      extension = 10000
    ).
    TRY.
      cl_salv_table=>factory(
        EXPORTING
          r_container = mo_container
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_rests ).
    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      " Обработка ошибок
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
    ENDTRY.
    _setup_alv( EXPORTING io_alv = lo_alv  ).
    lo_alv->display( ).
  ENDMETHOD.
  METHOD _setup_alv.
    data: lv_icon type string,
          lt_fcat type lvc_t_fcat,
          ls_fcat type lvc_s_fcat.

    data: lo_functions type ref to cl_salv_functions_list.
*   Включаем все функции alv-представления
       lo_functions = io_alv->get_functions( ).
       lo_functions->set_all( ).

       data(lo_columns) = io_alv->get_columns( ).
       lo_columns->get_column( 'WERKS' )->set_short_text( 'ТК' ).
       lo_columns->get_column( 'WERKS' )->set_medium_text( 'ТК' ).
       lo_columns->get_column( 'WERKS' )->set_long_text( 'ТК' ).
       lo_columns->get_column( 'LGORT' )->set_short_text( 'Склад' ).
       lo_columns->get_column( 'LGORT' )->set_medium_text( 'Склад' ).
       lo_columns->get_column( 'LGORT' )->set_long_text( 'Склад' ).
       lo_columns->get_column( 'MATNR' )->set_short_text( |Товар| ).
       lo_columns->get_column( 'MATNR' )->set_medium_text( |Товар| ).
       lo_columns->get_column( 'MATNR' )->set_long_text( |Товар| ).
       lo_columns->get_column( 'LABST' )->set_short_text( 'СвобЗап' ).
       lo_columns->get_column( 'LABST' )->set_medium_text( 'Свободный запас' ).
       lo_columns->get_column( 'LABST' )->set_long_text( 'Свободный запас' ).
       lo_columns->get_column( 'MEINS' )->set_short_text( 'БЕИ' ).
       lo_columns->get_column( 'MEINS' )->set_medium_text( 'БЕИ' ).
       lo_columns->get_column( 'MEINS' )->set_long_text( 'БЕИ' ).
       lo_columns->get_column( 'AMOUNT' )->set_short_text( 'Ст-ть' ).
       lo_columns->get_column( 'AMOUNT' )->set_medium_text( 'Стоимость' ).
       lo_columns->get_column( 'AMOUNT' )->set_long_text( 'Стоимость' ).
       lo_columns->get_column( 'LNTCODE' )->set_short_text( 'КодЛнт' ).
       lo_columns->get_column( 'LNTCODE' )->set_medium_text( 'КодЛенты' ).
       lo_columns->get_column( 'LNTCODE' )->set_long_text( 'Код Ленты' ).
       if lv_sel ne 'X'.
         lo_columns->get_column( 'LNTCODE' )->set_visible( if_salv_c_bool_sap=>false ).
       endif.
       if lv_only eq 'X'.
         lo_columns->get_column( 'LNTCODE' )->set_visible( if_salv_c_bool_sap=>false ).
       endif.
*   Сортируем по коду материала
       lo_sorts = io_alv->get_sorts( ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'WERKS'
          position = 1
          sequence = if_salv_c_sort=>sort_up ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'MATNR'
          position = 2
          sequence = if_salv_c_sort=>sort_up ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'LGORT'
          position = 3
          sequence = if_salv_c_sort=>sort_up ).

       data(lo_events) = io_alv->get_event( ).
       set handler on_user_command for lo_events.
  ENDMETHOD.
  METHOD _refresh_alv.
    data: ls_stable type lvc_s_stbl.

    ls_stable-row = abap_true.
    ls_stable-col = abap_true.

    _get_main_data( ).
    call method lo_alv->refresh
      exporting
        s_stable = ls_stable.
  ENDMETHOD.
  method on_user_command.
  ENDMETHOD.
 ENDCLASS.
