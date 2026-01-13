*&---------------------------------------------------------------------*
*& Include          ZRESTMOVE_SSCR
*&---------------------------------------------------------------------*
selection-screen begin of block b1 with frame title text-001.
select-options: s_werks for lv_werks.
selection-screen skip.
parameters: s_sel type abap_bool as checkbox default 'X'. " изменять на коды Ленты
selection-screen skip.
parameters: s_ei type abap_bool as checkbox default 'X'.  " Изменять ЕИ "КГ" на "Г"
selection-screen skip.
parameters: s_only type abap_bool as checkbox default 'X'. "Выгружать только мэппинг
selection-screen end of block b1.
