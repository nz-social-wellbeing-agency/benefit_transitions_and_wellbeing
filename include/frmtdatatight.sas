 *****************************************************************************************;
/*
     TITLE: Create a format from an input dataset allow missing values

     PURPOSE: Takes input dataset and makes a format if value is missing 
              the format shows a format error.

     AUTHOUR: Marc de Boer, MSD.

     DATE: March 2015
*/

 %MACRO frmtdatatight(FCMinfile
                     ,FCMFmtNm
                     ,FCMStart
                     ,FCMLabel
                     ) ;

 %PUT frmtdatatight Macro starting ;

 /*
   %LET FCMinfile = MOE_Provider_Lookup_table  ;
   %LET FCMFmtNm = PrvdCode_Inst  ;
   %LET FCMStart = provider_code        ;
   %LET FCMLabel = subsector        ;
 */

 PROC SORT DATA = &FCMinfile 
  OUT = FCMtemp1 (KEEP = &FCMStart &FCMLabel) 
  NODUPKEY; 
  BY &FCMStart ;
 run ;

 PROC CONTENTS DATA= FCMtemp1 NOPRINT 
  OUT = FCMtemp2 ;
 run ;

 DATA FCMtemp3 ;
  SET FCMtemp2 (WHERE = (LOWCASE(Name) = LOWCASE("&FCMLabel")) ) ;
  IF type = 2 THEN CALL SYMPUTX("FCMnullV", "LABEL = '!FORMAT ERROR!'" ) ;
  ELSE CALL SYMPUTX("FCMnullV", "LABEL = ." ) ;
 run ;

 DATA FCMtemp3 ;
  SET FCMtemp2 (WHERE = (LOWCASE(Name) = LOWCASE("&FCMStart")) ) ;
  IF type = 2 THEN CALL SYMPUTX("FCMnullS", "Start = 'other'" ) ;
  ELSE CALL SYMPUTX("FCMnullS", "start = ." ) ;
 run ;

   DATA FCMtemp4 ;
    SET FCMtemp1 (RENAME = (&FCMStart. = start
                            &FCMLabel.  = label
                           ) 
                  ) end = eof ;
    fmtname = "&FCMFmtNm." ;
    OUTPUT ;
    &FCMnullS. ;
    &FCMnullV. ;
   run ;

 PROC FORMAT LIBRARY = work CNTLIN = FCMtemp4  ; run ;
 PROC DATASETS LIB = work NOLIST ;
  DELETE FCMtemp: ;
 run ;
 %MEND ;
