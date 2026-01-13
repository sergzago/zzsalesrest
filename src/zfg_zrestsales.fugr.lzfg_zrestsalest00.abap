*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZRESTSALES......................................*
DATA:  BEGIN OF STATUS_ZRESTSALES                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZRESTSALES                    .
CONTROLS: TCTRL_ZRESTSALES
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZRESTSALES                    .
TABLES: ZRESTSALES                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
