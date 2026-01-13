*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMAPPRICELNT....................................*
DATA:  BEGIN OF STATUS_ZMAPPRICELNT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZMAPPRICELNT                  .
CONTROLS: TCTRL_ZMAPPRICELNT
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZMAPPRICELNT                  .
TABLES: ZMAPPRICELNT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
