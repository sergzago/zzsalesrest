*&---------------------------------------------------------------------*
*& Include          ZRESTSALES_SSCR
*&---------------------------------------------------------------------*
tables: zmaplnt.
data: lr_mapgr type range of zmaplnt-mapgr.
selection-screen begin of block b1 with frame title text-001.
parameters: s_rc type werks_d.
select-options: s_werks for lv_werks.
select-options: s_lgort for lv_lgort.
select-options: s_mtart for lv_mtart.
select-options: s_mapgr for zmaplnt-mapgr.
parameters: p_prcnt type i default 4 visible length 4 .
selection-screen skip.
*parameters: s_sel type abap_bool as checkbox default 'X'. " изменять на коды Ленты
parameters: s_long type abap_bool as checkbox default ''. " Длинные коды
selection-screen skip.
parameters: s_ei type abap_bool as checkbox default 'X'.  " Изменять ЕИ "КГ" на "Г"
selection-screen skip.
parameters: s_only type abap_bool as checkbox default 'X'. "Выгружать только мэппинг
selection-screen skip.
parameters: s_sales type abap_bool as checkbox default 'X'. "Продажа/передача товара
selection-screen skip.
parameters: s_mrktyp type abap_bool as checkbox default ''. "Выводить тип маркировки и наименование
parameters: s_jour type abap_bool as checkbox default 'X'.  "Сохранять данные по выгрузке
selection-screen end of block b1.
