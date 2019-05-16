
/*
     TITLE: Create a yes no format from an input dataset

     PURPOSE: Fast wasy to subset large datasets to a specific 
      subset.

     AUTHOUR: Mike ORourke, MSD.

     DATE: June 2013
*/



%macro use_fmt(input, id, fmtname, zeroobs = silentfail);
****************** %USE_FMT - Create format of input variable (id) *****************;
*********************** INSTRUCTIONS FOR THE USE OF THIS MACRO *********************;
*** The data set from which a format is to be generated must be available prior  ***;
*** to running this macro.                                                       ***;
*** If a format is required to be created when there are no observations in the  ***;
*** input data set then ZEROOBS should be set to CREATE.                         ***;
************************************************************************************;
* Updated: 6 Aug 2004 - Include the option NOPRINT in the proc contents procedure. *;
*                       Provide a length of 8 for fmtname.                         *;
* Updated: 25 Jun 2008 - Basically a rewrite of this macro with the following      *;
*                       changes:                                                   *;
*                      - Provide the ability via the ZEROOBS parameter to generate *;
*                        a format when the input data set contains 0 observations. *;
*                      - Check to see if a format with the name of the one about   *;
*                        to be created exists and if so delete this format.        *;
*                      - Remove all intermediate data sets at the end of the code  *;
* Updated: 12 Jun 2009 - Add the 'NOLIST' option to the 'PROC DATASETS' procedure. *;
 /* 
      %put TNote:  Macro use_fmt starting with:;
      %put %str(        )input%str(  ) = &input;
      %put %str(        )id%str(     ) = &id;
      %put %str(        )fmtname = &fmtname;
      %put %str(        )zeroobs = &zeroobs;
 */
      /* CHECK TO SEE IF A FORMAT WITH THE NAME OF THE ONE ABOUT TO BE  */;
      /* CREATED EXISTS IF SO DELETED THIS FORMAT.                      */;
      %macro delete_format;
            %let exists = N;

            data _null_;
                  if cexist("work.formats.&fmtname..format") 
                        then call symput('exists','Y');
            run;

            %put &exists;

            %if &exists = Y 
                  %then %do;
                        proc catalog cat = work.formats;
                              delete &fmtname..format;
                        run;
                  %end;
      %mend delete_format;

      %delete_format;

      /* SORT INPUT DATA SET KEEPING UNIQUE VALUES OF &ID */
      proc sort data = &input 
            out = work.use_fmt (keep = &id) nodupkey;
            by &id;
      run;

      /* CREATE FORMAT TO SELECT RECORDS BASED ON THE REQUIRED VARIABLE */
      data work.use_fmt2(keep =
                        start 
                        hlo 
                        label 
                        fmtname
                        );
            retain fmtname;

      /* DETERMINE 'TYPE' OF FORMAT BASED ON TYPE OF INPUT VARIABLE. ie CHARACTER */
      /* OR NUMERIC AND NAME THE FORMAT ACCORDINGLY.                              */
      if vtypex("&id") eq 'C' then  /* Use vtypex to get at run time (post use_fmt 
                                       being in PDV) */
            fmtname = "$&fmtname";
      else
            fmtname = "&fmtname";

      %if %upcase(&zeroobs) eq SILENTFAIL 
            %then %do;
                  if nobs eq 0 then stop;  /* Don't write the 'Other' value */
            %end;

      if _n_ eq 1 
            then do;
                  hlo   = 'O';
                  label = 'N';
                  output;
            end;

      set use_fmt nobs = nobs;
            rename &id = start;
            hlo   = ' ';
            label = 'Y';
            output;
      run;

      proc format cntlin = work.use_fmt2;
      run;

      /* REMOVE ALL INTERMEDIATE DATA SETS SO THAT THEY DONT GET PICKED UP */;
      /* IN A LATER EXECUTION OF THIS MACRO.                               */;
      proc datasets nolist;
            delete
                  use_fmt
                  use_fmt2;
      run;

      %put TNote:  Macro use_fmt finishing.;
%mend;
