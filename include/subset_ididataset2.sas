
 /*
     TITLE: Subset an IDI dataset on the SQL server to a SAS dataset

     PURPOSE: Using SQL Pass through procedure subset an IDI dataset to
     a specific subset of ids.

     AUTHOUR: Marc de Boer, MSD.

     DATE: March 2015

     MODIFICATIONS
     WHO            WHEN        WHAT
     Marc de Boer   March 2016  Included the ability to extract from the IDI sandpit area
     Bryan Ku       May 2017    Added the option to specify the number of observations to process
                                for each batch
     Bryan Ku       May 2018  
     Marc de Boer   June 2018   Changed logic by copying subsetting vars (ie snz_uid) to a temporary SQL dataset

   NOTES
   The macro variable IDI_RwNLib needs to be defined - not done yet

*/

 %MACRO subset_ididataset2(SIDId_infile =
                         ,SIDId_Id_var =
                         ,SIDId_IDIextDt = 
                         ,SIDId_database = 
                         ,SIDId_IDIschema = 
                         ,SIDId_IDIdataset =
                         ,SIDId_Temp_database = idi_sandpit
                         ,SIDId_Temp_dsn = idi_sandpit_srvprd
                         ,SIDId_Temp_schema = DL-MAA2016-15
                         ,SIDId_outfile =
                         );

 *
 SIDId_infile: dataset containing the IDI subsetting variable [SIDId_Id_var] if left
               null then the macro will extract the whole dataset
 SIDId_Id_var: IDI subsetting variable in the IDI source table [SIDId_IDIdataset]
               eg SIDId_Id_var = SNZ_uid
 SIDId_IDIextDt: IDI dataset version (eg 20151012) is extracting from (if null then assumes the call is to IDI_clean)
 SIDId_database: database the dataset is in (If left null then IDI_clean is assumed)
 SIDId_IDIschema: dataset schema eg ir_clean or msd_clean
 SIDId_IDIdataset: IDI dataset on the SQL server to be extracted by the macro.
 SIDI_outfile: output dataset written to the SAS work directory.

 If subsetting then need to have a accessible location to store the temporary dataset on the SQL server
 SIDId_Temp_database: write to location such as idi_sandpit 
 SIDId_Temp_dsn: for libname this is the sandpit dsn idi_sandpit_srvprd
 SIDId_Temp_schema: your local area eg DL-MAA2014-11
 *;

 /*  For testing 
  %LET SIDId_infile = &IMMIO_infile. ;
  %LET SIDId_Id_var = snz_uid ;
  %LET SIDId_IDIextDt = ;
  %LET SIDId_database = ;
  %LET SIDId_IDIschema = ir_clean ;
  %LET SIDId_IDIdataset = ird_rtns_keypoints_ir3;
  %LET SIDId_outfile = ir_keypoints_ir3_1 ;
  %LET SIDId_Temp_database = idi_sandpit ;
  %LET SIDId_Temp_dsn = idi_sandpit_srvprd ;
  %LET SIDId_Temp_schema = DL-MAA2014-11 ;
 */

 %PUT Start of macro: Subset_IDIdataset Located: Z:\MAA2014-11 MSD Investing in Better Outcomes  \01_SAS_macros\Utility_Macros\sasautos ;

********************************************************************************;
    ** identify whether the dataset needs to come from 
        current IDI dataset (IDI_clean)
        past refresh of IDI_clean
        another database
    **;

  DATA SIDI_temp3 ;
    IF LENGTHN(STRIP("&SIDId_IDIextDt")) = 0 THEN CALL SYMPUTX("DatabaseCall", "IDI_clean");
    ELSE CALL SYMPUTX("DatabaseCall", "IDI_clean_&SIDId_IDIextDt.")  ;
    IF LENGTHN("&SIDId_database.") gt 0 THEN CALL SYMPUTX("DatabaseCall", COMPRESS("&SIDId_database.","[]")) ;
    CALL SYMPUTX("SIDId_IDIdataset",COMPRESS("&SIDId_IDIdataset.","[]") ) ;
    CALL SYMPUTX("SIDId_IDIschema",COMPRESS("&SIDId_IDIschema.","[]") )  ;
  run ;

  %PUT Database called: [&DatabaseCall.].[&SIDId_IDIschema.].[&SIDId_IDIdataset.] ;

********************************************************************************;
    ** identify whether the dataset needs to be subsetted **;

 %LET SIDISubset = 0 ;

 DATA SIDI_temp1 ;
  IF LENGTHN(STRIP("&SIDId_infile.")) gt 0 THEN CALL SYMPUTX("SIDISubset",1) ;
  ELSE  CALL SYMPUTX("SIDISubset",0) ;
 run ;
  
 %PUT Subset IDI dataset (yes:1): &SIDISubset. ;

********************************************************************************; 
 ** Run extract with subsetting **;

  %IF &SIDISubset. = 1 %THEN %DO ;

   * define SQL location to write temporary file *;
   LIBNAME IDIsubst ODBC dsn=&SIDId_Temp_dsn. schema="&SIDId_Temp_schema.";

   * create temporary dataset name *;
   DATA SIDI_temp1 ;
    CALL SYMPUTX('IDIsubset_SAS',CATT('IDIsubset_',&sysjobid) ) ;
    CALL SYMPUTX('IDIsubset_sql',CATT("["
                                     ,LOWCASE(COMPRESS("&SIDId_Temp_database.","[]"))
                                      ,"].["
                                     ,LOWCASE(COMPRESS("&SIDId_Temp_schema.","[]"))
                                     ,'].[IDIsubset_'
                                     ,&sysjobid,"]"
                                      ) 
                  ) ;
   run ;
   
    ** Identify unqiue ids **;
   PROC SORT DATA = &SIDId_infile. (WHERE = (&SIDId_Id_var. ne .) ) 
    OUT = SIDI_temp2 (KEEP = &SIDId_Id_var.
                      )
    NODUPKEY ;
    BY &SIDId_Id_var. ;
   run ;

   * delete subset file from SQL server just in case *;
   PROC DATASETS LIB = IDIsubst NOLIST ;
    DELETE &IDIsubset_SAS. ;
   run ;
	/* PNH- April 2019 - New SAS GRID Linux does not allow Bulk Load*/
   DATA IDIsubst.&IDIsubset_SAS. /*(BULKLOAD = yes)*/ ;
    SET SIDI_temp2 ;
   run ;

   ** delete SIDId_outfile in case it already existed *;
   PROC DATASETS LIB = work NOLIST ;
    DELETE &SIDId_outfile.  ;
   run ;   

   ** extract ids from IDI tables using pass through *;
   PROC SQL ;
    connect to odbc( dsn=idi_clean_20181020_srvprd);
	CREATE TABLE &SIDId_outfile. AS SELECT * FROM CONNECTION TO odbc
    (
    SELECT a.*
        FROM &IDIsubset_sql.  AS b
         LEFT JOIN
         [&DatabaseCall.].[&SIDId_IDIschema.].[&SIDId_IDIdataset.] AS a 
    ON a.&SIDId_Id_var. = b.&SIDId_Id_var. 
   ) ;

   /*CREATE TABLE &SIDId_outfile. AS SELECT * FROM CONNECTION TO odbc (
	   SELECT * FROM #SIDI_temp3) ;*/

    DISCONNECT FROM odbc ;
   quit ;

   * delete subset file from SQL server *;
   PROC DATASETS LIB = IDIsubst NOLIST ;
    DELETE &IDIsubset_SAS. ;
   run ;

   %END ;

 ** extract the whole dataset *;
 %IF &SIDISubset. = 0 %THEN %DO ; ** loop 3 *;
   PROC SQL ;
    connect to odbc(dsn=&idi_version._srvprd);
    CREATE TABLE &SIDId_outfile. AS
    SELECT a.*
    FROM CONNECTION TO odbc (SELECT * FROM [&DatabaseCall.].[&SIDId_IDIschema.].[&SIDId_IDIdataset.]
                                 ) AS a ;
    DISCONNECT FROM odbc ;
   quit ;
 %END ; * end loop 3 *;

 PROC DATASETS LIB = work NOLIST ;
  DELETE SIDI_temp: ;
 run ;

  %PUT End of macro: Subset_IDIdataset ;
 %MEND ;


