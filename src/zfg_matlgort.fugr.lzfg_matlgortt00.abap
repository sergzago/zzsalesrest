*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMATLGORTLNT....................................*
DATA:  BEGIN OF STATUS_ZMATLGORTLNT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZMATLGORTLNT                  .
CONTROLS: TCTRL_ZMATLGORTLNT
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZMATLGORTLNT                  .
TABLES: ZMATLGORTLNT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
