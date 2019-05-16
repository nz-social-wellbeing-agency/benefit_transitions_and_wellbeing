/*  
    TITLE:  Hash Table Macros

   PURPOSE:
      Hash Table Macros for look up table functions

    AUTHOR: Marc de Boer, Insights MSD

    DATE: June 2016

     MODIFCATIONS
     BY             WHEN          WHY

*/

****************************************************************************************;
  ** Static hash table full join function **;
/*
  %hashtblfulljoin( RCVtble [Name of SAS dataset to be the hash table]
                   ,RCVtblCd [Unique Char code to identify hash table]
                   ,RCVcode [Index variable to link hash table to dataset]
                   ,RCVvars [Variables from hash table to add to dataset]
                   ) ;

*/


****************************************************************************************;
  ** Static hash table full join function **;

  %MACRO hashtblfulljoin( RCVtble
                        ,RCVtblCd
                        ,RCVcode 
                        ,RCVvars
                        ) ;

  ** create a dummy for whether hash object has been defined *;
  LENGTH HashObjDef_&RCVtblCd. 8. ;
  IF HashObjDef_&RCVtblCd. = . THEN HashObjDef_&RCVtblCd. = 0 ;
  RETAIN HashObjDef_&RCVtblCd. ;

  ** set up variables to add **;
  ** remove multiple blanks from RCVvar list *;
  %LET RCVvarSlim = %SYSFUNC(COMPBL(&RCVvars.)) ;
  %LET RCVcodeSlim = %SYSFUNC(COMPBL(&RCVcode.)) ;
  ** work out number of variables to add **;
  %LET Nvars = %EVAL(%SYSFUNC(LENGTH(&RCVvarSlim.) ) - %SYSFUNC(LENGTH(%SYSFUNC(COMPRESS(&RCVvarSlim.)) )) + 1 );
  ** create individual macro variable names for each pf the hash table variables *;
  %DO i = 1 %TO &Nvars ;
     %LET RCVvar&i = %SCAN(&RCVvarSlim., &i., " ") ;
  %END ;

  ** create temporary variables for the hash table to write to *;
  %DO i = 1 %TO &Nvars ;
     %LET RCVvar&i = %SCAN(&RCVvarSlim., &i., " ") ;
  %END ;

  %MACRO ReNameVars ;
    %DO x = 1 %TO &Nvars ;
      &&RCVvar&x. = &RCVtblCd.temp&x 
    %END ;
  %MEND ;

  ** Define the formats and lengths of the Hash table variable parameters *;
  IF 1 = 2 THEN SET &RCVtble. (KEEP = &RCVcode. &RCVvarSlim. RENAME = (%ReNameVars))  ;

  ** define hash table objects **;
  IF HashObjDef_&RCVtblCd. = 0 THEN DO ;
   HashObjDef_&RCVtblCd. = 1 ;
   DECLARE HASH &RCVtblCd.(DATASET: "&RCVtble. (KEEP = &RCVcode. &RCVvarSlim. RENAME = (%ReNameVars))", MULTIDATA:"Y"); 
   &RCVtblCd..DEFINEKEY(%SYSFUNC(TRANWRD("&RCVcodeSlim.",%STR( ) ,%STR(" ,")) ));
   &RCVtblCd..DEFINEDATA(all:'yes') ; 
   &RCVtblCd..DEFINEDONE () ;

   ** Set the format and length of temporary variables to match the hash table variables *;
   ** Note becuase the hash table has not returned any values the temp varibale are null 
      which is what we want *;
   ** Note each hashtablemacro creats unqiue temp variables with RCVtblCd as the prefix 
      so you can have multiple hashtablemacro calls in the same data step. *;
   %DO i = 1 %TO &Nvars. ;
      &&RCVvar&i. =  &RCVtblCd.temp&i ;
   %END ;
  END ;

  ** search for records with matching look up codes *;
  rc = &RCVtblCd..FIND() ;
  *** if matched then write matched results to variable name *;
  IF rc = 0  THEN DO  ;
    %DO i = 1 %TO &Nvars ;
      &&RCVvar&i. =  &RCVtblCd.temp&i ;
    %END ;
  END ;

  DROP rc
       %DO i = 1 %TO &Nvars ;
          &RCVtblCd.temp&i 
       %END ;   
       ; 

  DROP HashObjDef_&RCVtblCd. ; * drop another temp var - B Ku 31 Jul 2017 *;

 %MEND ;

