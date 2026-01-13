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
      tr_rc type werks_d,
      tr_werks TYPE RANGE OF werks_d,
      tr_lgort type range of lgort_d,
      tr_mtart type range of mtart,
      tr_mapgr type range of zmaplnt-mapgr,
      "tr_sel type abap_bool,
      tr_ei type abap_bool,
      tr_only type abap_bool,
      tr_long type abap_bool,
      tr_sales type abap_bool,
      tr_mrktyp type abap_bool.
    METHODS:
      run
        IMPORTING
          ir_rc type tr_rc
          ir_werks TYPE tr_werks
          ir_lgort type tr_lgort
          ir_mtart type tr_mtart
          ir_prcnt type i
          ir_mapgr type tr_mapgr
          ir_jour type abap_bool
          "ir_sel type tr_sel
          ir_ei type tr_ei
          ir_only type tr_only
          ir_long type tr_long
          ir_sales type tr_sales
          ir_mrktyp type tr_mrktyp,
      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function.

  PRIVATE SECTION.
    types: begin of ty_rests,
            postav type c length 40,
            ekgrp type ekgrp,
            werks type werks_d,
            lgort type lgort_d,
            matnr_c type c length 18,
            salesdate type dats,
            labst type labst,
            meins type meins,
            amount type p length 16 decimals 2,
            price type p length 13 decimals 2,
            eprice type i,
            emeins type meins,
            mwskz type mwskz,
            matnr type matnr,
            lntcode type c length 1,
            marktype type c length 30,
            mapgr type zmaplnt-mapgr,
           end of ty_rests.
    DATA:
*      mr_werks  type tr_werks,
      "lv_sel type tr_sel,
      lv_rc type tr_rc,
      lv_ei type tr_ei,
      lv_only type tr_only,
      lv_long type tr_long,
      lv_sales type tr_sales,
      lv_mrktyp type tr_mrktyp,
      lv_jour type abap_bool,
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
    "lv_sel = ir_sel.
    lv_rc = ir_rc.
    lv_ei = ir_ei.
    lv_only = ir_only.
    lv_long = ir_long.
    lv_sales = ir_sales.
    lv_mrktyp = ir_mrktyp.
    lv_mapgr = ir_mapgr.
    lv_jour = ir_jour.
    _get_main_data( ).
    _init_alv( ).
    CALL SCREEN 0100.
  ENDMETHOD.
  METHOD _get_main_data.
*    data: lv_cur_date type dats.

*    lv_cur_date = sy-datum.
  types: begin of ty_rest,
          werks type werks_d,
          lgort type lgort_d,
          matnr type matnr,
          labst type labst,
          meins type meins,
          lbkum type lbkum,
          salk3 type salk3,
        end of ty_rest.
  data: lt_rest type table of ty_rest.

  data: gt_wms_result  type standard table of ts_wms_result with empty key,
        lv_lntcode type matnr,
        lv_lntwerks type werks_d,
        ls_zmaplnt type zmaplnt,
        ls_zmapwerkslnt type zmapwerkslnt,
        ls_zmaplgortlnt type zmaplgortlnt,
        lv_shortmatnr type c length 6,
        lv_matnr_i type c length 18,
        ls_specialprice type zmappricelnt,
        gv_conn        type dbcon-con_name,
        gv_scheme      type dbcon-con_name,
        crdat          type sy-datlo,
        crtim          type sy-timlo,
        ls_restsales   type zrestsales.


    crdat = sy-datlo.
    crtim = sy-timlo.
    if lv_rc is initial or lv_sales eq abap_false.
      select mard~werks,
        mard~lgort,
        mard~matnr,
        mard~labst,
        mara~meins,
        mbew~lbkum,
        mbew~salk3
      into table @lt_rest "@data(lt_rest)
      from mard
        join mara on mara~matnr eq mard~matnr
        join mbew on mbew~matnr eq mard~matnr and mbew~bwkey eq mard~werks
      where mard~werks in @s_werks
        and mard~lgort in @s_lgort
        and mara~mtart in @s_mtart
        and mard~labst NE 0
      order by mard~werks,mard~matnr,mard~lgort.
    else.
      "Выгрузка с РЦ (по ячейкам)
      perform wms_connect using lv_rc changing gv_conn gv_scheme.
      if gv_conn is initial.
        message |Не настроено подключение к базе данных WMS для РЦ { lv_rc }| type 'A'.
      endif.
      if gv_scheme is initial.
        message |Не сопоставлена схема БД с РЦ { lv_rc }| type 'A'.
      endif.
      data(lo_con) = cl_sql_connection=>get_connection( gv_conn ).
      data(lv_sql) =
        |select right(loc,4) as werks, | &&
        |sku as matnr | &&
        |,qty | &&
        |,LOC | &&
        |from { gv_scheme }.skuxloc | &&
        |where LOC like 'MAG%' and qty>0 |.
      data(lo_stmt) = lo_con->create_statement(  ).
      data(lo_result) = lo_stmt->execute_query( lv_sql ).
      lo_result->set_param_table( ref #( gt_wms_result ) ).
      try.
        data(lv_row_count) = lo_result->next_package( ).
      catch cx_sql_exception into data(lo_exception).
        message |{ lo_exception->get_text(  ) }| type 'E' display like 'I'.
        lo_con->close( ).
      endtry.
      "perform add_test_value changing gt_wms_result.  "для S4D. В продуктиве убрать!
      loop at gt_wms_result assigning field-symbol(<ls_wms_result>).
        lv_matnr_i = |{ <ls_wms_result>-matnr ALPHA = IN }|.
        <ls_wms_result>-matnr = lv_matnr_i.
      endloop.
      select gwr~werks,
        '0001' as lgort,
        gwr~matnr,
        gwr~labst,
        mara~meins,
        mbew~lbkum,
        mbew~salk3
      from @gt_wms_result as gwr
        join mara on mara~matnr eq gwr~matnr
        "join mbew on mbew~bwkey eq gwr~werks and mbew~matnr eq gwr~matnr
        join mbew on mbew~bwkey eq @lv_rc and mbew~matnr eq gwr~matnr
      where gwr~werks in @s_werks
        and mara~mtart in @s_mtart
        and gwr~labst NE 0
      order by gwr~werks,gwr~matnr
      into table @lt_rest. "@data(lt_rest).
    endif.

    loop at lt_rest into data(ls_rest).
      clear ls_rests.
      clear ls_restsales.
      if lv_partner is initial.
        ls_rests-postav = 'MOLL'.
      else.
        ls_rests-postav = lv_partner.
      endif.
      ls_rests-werks = ls_rest-werks.
      ls_rests-lgort = ls_rest-lgort.
      ls_rests-matnr = ls_rest-matnr.
      "ls_rests-matnr_c = substring( val = ls_rest-matnr off = 10 len = 8 ).
      ls_rests-labst = ls_rest-labst.
      ls_rests-meins = ls_rest-meins.
      ls_rests-emeins = ls_rest-meins.
      if lv_rc is initial.
        clear ls_specialprice.
        select single *
          from zmappricelnt
          into @ls_specialprice
          where matnr eq @ls_rest-matnr.
      endif.
      if ls_specialprice is initial.
         ls_rests-price = ls_rest-salk3 / ls_rest-lbkum * ( 1 + p_prcnt / 100 ).
      else.
         ls_rests-price = ls_specialprice-price.
      endif.
*      if lv_sel EQ 'X'.
        select single * from zmaplnt
          into ls_zmaplnt
          where matnr eq ls_rest-matnr.
        if sy-subrc = 0.
          ls_rests-ekgrp = ls_zmaplnt-ekgrp.
          ls_rests-mwskz = ls_zmaplnt-mwskz.
          ls_rests-mapgr = ls_zmaplnt-mapgr.
          if lv_long eq 'X'.
            "ls_rests-matnr = ls_zmaplnt-matnr_long.
            ls_rests-matnr_c = substring( val = ls_zmaplnt-matnr_long off = 6 len = 12 ).
          else.
            "ls_rests-matnr = ls_zmaplnt-matnr_lenta.
            ls_rests-matnr_c = substring( val = ls_zmaplnt-matnr_lenta off = 12 len = 6 ).
          endif.
          ls_rests-lntcode = 'X'.
          if lv_ei eq 'X' and ls_zmaplnt-meins ne ls_zmaplnt-meins_lenta.
            if ls_zmaplnt-meins eq 'KG' and ls_zmaplnt-meins_lenta eq 'G'.
              ls_rests-labst = ls_rest-labst * 1000.
              ls_rests-meins = 'G'.
              ls_rests-emeins = 'G'.
              "ls_rests-price = ls_rest-salk3 / ( ls_rest-lbkum * 1000 ) * ( 1 + p_prcnt / 100 ).
               ls_rests-price = ls_rests-price / 1000.
            else.
              if ls_zmaplnt-meins eq 'G' and ls_zmaplnt-meins_lenta eq 'KG'.
                 ls_rests-labst = ls_rest-labst / 1000.
                 ls_rests-meins = 'G'.
                 ls_rests-emeins = 'G'.
                 "ls_rests-price = ls_rest-salk3 / ( ls_rest-lbkum / 1000 ) * ( 1 + p_prcnt / 100 ).
                 ls_rests-price = ls_rests-price * 1000.
              endif.
            endif.
        endif.
        select single * from zmapwerkslnt
          into ls_zmapwerkslnt
          where werks eq ls_rest-werks.
        if sy-subrc = 0.
          ls_rests-werks = ls_zmapwerkslnt-werks_lnt.
        endif.
        " Смотрим склад Ленты по материалу
        select single lgort from zmatlgortlnt
          into @data(lv_matlgort)
          where matnr eq @ls_rest-matnr.
        if sy-subrc = 0.
          ls_rests-lgort = lv_matlgort.
        else.
          " Если специально склад для материала не указан, то выбираем общий склад из мэппинга
          select single * from zmaplgortlnt
            into ls_zmaplgortlnt
            where lgort eq ls_rest-lgort.
          if sy-subrc = 0.
            ls_rests-lgort = ls_zmaplgortlnt-lgort_lnt.
          else.
            ls_rests-lgort = '9999'.
            endif.
         endif.
       endif.
*      else.
*        select single * from zmaplnt
*          into ls_zmaplnt
*          where matnr = ls_rest-matnr.
*        if sy-subrc = 0.
*          ls_rests-lntcode = 'X'.
*        endif.
*      endif.
      ls_rests-salesdate = sy-datum.
*      if lv_ei eq 'X' and ls_rest-meins eq 'KG'.
*        ls_rests-labst = ls_rest-labst * 1000.
*        ls_rests-meins = 'G'.
*        ls_rests-emeins = 'G'.
*        ls_rests-price = ls_rest-salk3 / ( ls_rest-lbkum * 1000 ) * ( 1 + p_prcnt / 100 ).
*    else.
*        ls_rests-labst = ls_rest-labst.
*        ls_rests-meins = ls_rest-meins.
*        ls_rests-emeins = ls_rest-meins.
*        ls_rests-price = ls_rest-salk3 / ls_rest-lbkum * ( 1 + p_prcnt / 100 ).
*      endif.
      ls_rests-amount = ls_rest-salk3 / ls_rest-lbkum  * ls_rest-labst.
      if ls_zmaplnt-min_price is not initial and ls_zmaplnt-min_price gt 0.
        if ls_rests-price < ls_zmaplnt-min_price.
          ls_rests-price = ls_zmaplnt-min_price.
        endif.
      endif.
      ls_rests-price = round( val = ls_rests-price dec = 2 ).
      ls_rests-eprice = 1.
      SELECT SINGLE ausp~atwrt into @data(ls_marktype)
        FROM inob
        JOIN ausp ON ausp~objek eq inob~cuobj
        JOIN cabn ON cabn~atinn eq ausp~atinn AND cabn~atnam eq 'ZMARK_TYPE'
        WHERE inob~objek eq @ls_rest-matnr
          AND inob~OBTAB eq 'MARAT' AND inob~klart eq '026'.
      if sy-subrc = 0.
        ls_rests-marktype = ls_marktype.
      endif.
      if ( lv_only eq '' ) or ( ls_rests-lntcode eq 'X' ).
        if ls_rests-mapgr in lv_mapgr.
          append ls_rests to lt_rests.
          if lv_jour eq 'X'.
            ls_restsales-werks = ls_rest-werks.
            ls_restsales-lgort = ls_rest-lgort.
            ls_restsales-matnr = ls_rest-matnr.
            ls_restsales-meins = ls_rest-meins.
            ls_restsales-matnr_lenta = ls_rests-matnr_c.
            CALL FUNCTION 'CONVERSION_EXIT_MATNL_INPUT'
              EXPORTING
                input  = ls_restsales-matnr_lenta
              IMPORTING
                output = ls_restsales-matnr_lenta
              EXCEPTIONS
              OTHERS = 1.
            ls_restsales-meins_lenta = ls_rests-meins.
            ls_restsales-rest = ls_rest-labst.
            ls_restsales-rest_lenta = ls_rests-labst.
            ls_restsales-mapgr = ls_zmaplnt-mapgr.
            ls_restsales-crdat = crdat.
            ls_restsales-crtim = crtim.
            MODIFY zrestsales FROM ls_restsales.
            if sy-subrc = 0.
              commit work.
            else.
              rollback work.
            endif.
          endif.
        endif.
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

       lo_columns->get_column( 'POSTAV' )->set_short_text( 'LIFNR' ). "'Постав.' ).
       lo_columns->get_column( 'POSTAV' )->set_medium_text( 'LIFNR' ). "'Поставщик' ).
       lo_columns->get_column( 'POSTAV' )->set_long_text( 'LIFNR' ). "'Поставщик' ).
       lo_columns->get_column( 'EKGRP' )->set_short_text( 'EKGRP' ).
       lo_columns->get_column( 'EKGRP' )->set_medium_text( 'EKGRP' ).
       lo_columns->get_column( 'EKGRP' )->set_long_text( 'EKGRP' ).
*       lo_columns->get_column( 'SALESDATE' )->set_short_text( 'ДатаПост' ).
*       lo_columns->get_column( 'SALESDATE' )->set_medium_text( 'Дата поставки' ).
*       lo_columns->get_column( 'SALESDATE' )->set_long_text( 'Дата поставки' ).
       lo_columns->get_column( 'LABST' )->set_short_text( 'MENGE' ). "'КолВо' ).
       lo_columns->get_column( 'LABST' )->set_medium_text( 'MENGE' ). "'Количество' ).
       lo_columns->get_column( 'LABST' )->set_long_text( 'MENGE' ). "'Количество' ).
       lo_columns->get_column( 'PRICE' )->set_short_text( 'NETWR' ). "'Цена' ).
       lo_columns->get_column( 'PRICE' )->set_medium_text( 'NETWR' ). "'Цена' ).
       lo_columns->get_column( 'PRICE' )->set_long_text( 'NETWR' ). "'Цена' ).
       lo_columns->get_column( 'EPRICE' )->set_short_text( 'PEINH' ). "'За' ).
       lo_columns->get_column( 'EPRICE' )->set_medium_text( 'PEINH' ). "'За' ).
       lo_columns->get_column( 'EPRICE' )->set_long_text( 'PEINH' ). "'За' ).
       lo_columns->get_column( 'EMEINS' )->set_short_text( 'BPRME' ). "'ЕИЗак' ).
       lo_columns->get_column( 'EMEINS' )->set_medium_text( 'BPRME' ). "'ЕИ заказа' ).
       lo_columns->get_column( 'EMEINS' )->set_long_text( 'BPRME' ). "'ЕИ цены заказа' ).
       lo_columns->get_column( 'LNTCODE' )->set_short_text( 'КодЛнт' ).
       lo_columns->get_column( 'LNTCODE' )->set_medium_text( 'КодЛенты' ).
       lo_columns->get_column( 'LNTCODE' )->set_long_text( 'Код Ленты' ).
       lo_columns->get_column( 'WERKS' )->set_short_text( 'WERKS' ).
       lo_columns->get_column( 'WERKS' )->set_medium_text( 'WERKS' ).
       lo_columns->get_column( 'WERKS' )->set_long_text( 'WERKS' ).
       lo_columns->get_column( 'LGORT' )->set_short_text( 'LGORT' ).
       lo_columns->get_column( 'LGORT' )->set_medium_text( 'LGORT' ).
       lo_columns->get_column( 'LGORT' )->set_long_text( 'LGORT' ).
       lo_columns->get_column( 'MATNR' )->set_short_text( 'CODSAPMOL' ).
       lo_columns->get_column( 'MATNR' )->set_medium_text( 'COD SAP MOLL' ).
       lo_columns->get_column( 'MATNR' )->set_long_text( 'COD SAP MOLL' ).
       lo_columns->get_column( 'MEINS' )->set_short_text( 'MEINS' ).
       lo_columns->get_column( 'MEINS' )->set_medium_text( 'MEINS' ).
       lo_columns->get_column( 'MEINS' )->set_long_text( 'MEINS' ).
       lo_columns->get_column( 'MWSKZ' )->set_short_text( 'MWSKZ' ).
       lo_columns->get_column( 'MWSKZ' )->set_medium_text( 'MWSKZ' ).
       lo_columns->get_column( 'MWSKZ' )->set_long_text( 'MWSKZ' ).
       lo_columns->get_column( 'AMOUNT' )->set_short_text( 'AMOUNT' ).
       lo_columns->get_column( 'AMOUNT' )->set_medium_text( 'AMOUNT' ).
       lo_columns->get_column( 'AMOUNT' )->set_long_text( 'AMOUNT' ).
       lo_columns->get_column( 'MATNR_C' )->set_short_text( 'MATNR' ).
       lo_columns->get_column( 'MATNR_C' )->set_medium_text( 'MATNR' ).
       lo_columns->get_column( 'MATNR_C' )->set_long_text( 'MATNR' ).
       lo_columns->get_column( 'MARKTYPE' )->set_short_text( 'MARKTYPE' ).
       lo_columns->get_column( 'MARKTYPE' )->set_medium_text( 'MARKTYPE' ).
       lo_columns->get_column( 'MARKTYPE' )->set_long_text( 'MARKTYPE' ).
* Скрываем столбцы
       lo_columns->get_column( 'SALESDATE' )->set_visible( if_salv_c_bool_sap=>false ).
       lo_columns->get_column( 'MARKTYPE' )->set_visible( if_salv_c_bool_sap=>false ).
       lo_columns->get_column( 'MAPGR' )->set_visible( if_salv_c_bool_sap=>false ).
       if lv_sales ne 'X'.
         lo_columns->get_column( 'POSTAV' )->set_visible( if_salv_c_bool_sap=>false ).
         lo_columns->get_column( 'EKGRP' )->set_visible( if_salv_c_bool_sap=>false ).
         lo_columns->get_column( 'PRICE' )->set_visible( if_salv_c_bool_sap=>false ).
         lo_columns->get_column( 'EMEINS' )->set_visible( if_salv_c_bool_sap=>false ).
         lo_columns->get_column( 'MWSKZ' )->set_visible( if_salv_c_bool_sap=>false ).
         lo_columns->get_column( 'EPRICE' )->set_visible( if_salv_c_bool_sap=>false ).
         lo_columns->get_column( 'LABST' )->set_short_text( 'LABST' ). "'КолВо' ).
         lo_columns->get_column( 'LABST' )->set_medium_text( 'LABST' ). "'Количество' ).
         lo_columns->get_column( 'LABST' )->set_long_text( 'LABST' ). "'Количество' ).
       else.
         lo_columns->get_column( 'AMOUNT' )->set_visible( if_salv_c_bool_sap=>false ).
       endif.
"       if lv_sel ne 'X'.
         lo_columns->get_column( 'LNTCODE' )->set_visible( if_salv_c_bool_sap=>false ).
"       endif.
*       if lv_only eq 'X'.
*         lo_columns->get_column( 'LNTCODE' )->set_visible( if_salv_c_bool_sap=>false ).
*       endif.
       if lv_mrktyp eq 'X'.
         lo_columns->get_column( 'MARKTYPE' )->set_visible( if_salv_c_bool_sap=>true ).
       endif.
*   Сортируем по коду материала
       lo_sorts = io_alv->get_sorts( ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'WERKS'
          position = 1
          sequence = if_salv_c_sort=>sort_up ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'EKGRP'
          position = 2
          sequence = if_salv_c_sort=>sort_up ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'MATNR'
          position = 3
          sequence = if_salv_c_sort=>sort_up ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'LGORT'
          position = 4
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
