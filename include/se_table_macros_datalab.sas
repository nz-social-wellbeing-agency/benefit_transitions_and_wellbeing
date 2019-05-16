
**				NOT FOR RELEASE ;

**********************************************************************************;
*                                                                              	*;
*  Program Name:  	SE_table_macros              										  	*;
*                                                                               	*;
*  Author:         	Statistics NZ                                               *;
*                                                                               	*;
*  Created:         	February 2012                                               *;
*                                                                               	*;
*  Purpose:         	This program is used to produce sampling errors for         *;
*                   	estimates from the GSS and other household surveys. This	  	*;
*							code uses the ABS table macro. 								  	  	*;
*																											*;
*	Macros:																								*;
*																											*;
*       Version 1 (seforpropn1): 																*;
*							Standard SE macro for proportions									*;
*							Warning:	Do not use to produce estimates as the results are *;
*							multiplied by 100. 	  													*;
*																											*;
*       Version 2 (seforpropn1_gssflag): 														*;
*							Standard SE macro including GSS flags and suppression  		*;
*							Warning:	Do not use to produce estimates as the results are *;
*							multiplied by 100. 													  	*;
*							Note - these flags are based on General Social Survey rules *;
*							used by Statistics NZ staff. Rules may differ for other 		*;
*							surveys and for datalab users. The code should be updated  	*;
*							as required.																*;
*																											*;
*		  Version 3 (seforlevel): 																	*;
*							Standard SE macro for estimates (levels) including totals 	*;
*                                                                       			*;
*                  								                                		  	*;
**********************************************************************************;

;
**********************************************************************************;	
*    macro:          seforpropn1 and seforpropn1_gssflag                        	*;
*                                                                                *;
*    parameters:                                                                 *;
*    indata:         name of input dataset                                       *;
*    outdata:        name of output dataset   												*;
*    class:          category variable                                           *;
*                    none: calculate proportions on the total population         *;
*                    variable list: calculate proportions in each category       *;
*    var:            name of the variable you want to calculate SEs and RSEs for *;
*    wgt:            name of weight variable                                     *;
*    ExcludMissing:  remove/not records with missing values                      *;
*                    (include refuse and unknown) for the calculated variable    *;
*                    1: remove, this is default specification                    *;
*                    0(or other number): do not remove                           *;
*    ExcludeMore:    specify conditions here if want to remove any more records  *;
*                    none: no, this is default specification                     *;
*                    e.g., CORDV14 = '77', remove records with the variable      *;
*                    CORDV14's values are '77'                                   *;
* 	 input:                                                                       *;
*    &indata.                                                                    *;
*                                                                                *;
*    output:                                                                     *;
*    &outdata.                                                                   *;
*                                                                                *;
*    purpose:  		 To create estimates of proportions with SEs, RSE,    		*;
*              		 confidence intervals and weighted and unweighted sample 	*;
*                     sizes																		*;
*																											*;
**********************************************************************************;

;
**********************************************************************************;
*    macro:          seforlevel								                          	*;
*                                                                                *;
*    parameters:                                                                 *;
*    inset:         name of input dataset                                        *;
*    outset:        name of output dataset   										 		*;
*    vars:          name of variables you want to include in the table 				*;
*    wgt:           name of weight variable                                      *;
*    ExcludMissing:  remove/not records with missing values                      *;
*                    (include refuse and unknown) for the calculated variable    *;
*                    1: remove, this is default specification                    *;
*                    0(or other number): do not remove                           *;
*    ExcludeMore:    specify conditions here if want to remove any more records  *;
*                    none: no, this is default specification                     *;
*                    e.g., CORDV14 = '77', remove records with the variable      *;
*                    CORDV14's values are '77'                                   *;
* 	 input:                                                                       *;
*    &indata.                                                                    *;
*                                                                                *;
*    output:                                                                     *;
*    &outdata.                                                                   *;
*                                                                                *;
*    purpose:  		 To create estimates (including totals), with SEs and RSE	*;
*																											*;
**********************************************************************************;

**
**	VERSION 1: Standard sampling errors;
**;
*Warning - do not use this for estimates as this version multiplies results by 100;
/*SEforPropn1 --> seforpropn1 20190403 AK*/
%macro seforpropn1(indata=,outdata=,class=none,var=,wgt=,ExcludMissing=1,ExcludeMore=none);

   %** create a temporary table for table macro;
   data _fortable_;
      set &indata.;
      %if &ExcludMissing.=1 %then %do;
         %if %scan(&class.,1) ne none %then %do;
            %do i = 1 %to %SYSFUNC(countw(&class.));
               if %scan(&class.,&i) in (" ","77","88","89","99","999") then delete;
            %end;
         %end;
         if &var. in (" ","77","88","89","99","999") then delete;
      %end;
      %if %scan(&ExcludeMore.,1) ne none %then %do; if &ExcludeMore. then delete;%end;
   run;

   %** call %table macro to calculate the sampling errors;
   %table(data=_fortable_,                 /* input dataset */
         weight=&wgt.,                     /* main survey weight */
         repwts=&wgt._1-&wgt._100,         /* replicate weights */
         out=_fromtab_,                    /* output dataset  */
         %if &class. ne none %then %do;
            class=&class.,                   /* domain of estimates   */
         %end;
         subclass=&var.,
         maxspace=5000); 

   %*** converting to SNZ sampling errors ;
   data _SNZse_(drop=_est_ _var_ _se_ _rse_);
      set _fromtab_;
      Estimate=_est_*100;
      Sampling_error=_se_*1.96*100;
      Relative_sampling_error = (_se_*1.96/_est_)*100; 
      Lower_CI=Estimate -sampling_error;
      Upper_CI=Estimate +sampling_error;
      Confidence_level=95;
   run;

   %*** create the output table and attach population and sample size for each cell of the table;
   %if &class. ne none %then %do; 
      proc summary data=_fortable_ nway;
         class &class. &var. ;
         var &wgt.;
         output out=_Nnsize_ (drop=_type_ _freq_) sum=N_popn_count n=n_samp_count;
      run;
      data &outdata.;
          merge _SNZse_ _Nnsize_;
          by &class. &var. ;
      run;
   %end;
   %else %do;
      proc summary data=_fortable_ nway;
         class &var.;
         var &wgt.;
         output out=_Nnsize_ (drop=_type_ _freq_) sum=N_popn_count n=n_samp_count;
      run;
      data &outdata.;
          merge _SNZse_ _Nnsize_;
          by &var. ;
      run;
   %end;

   %*** drop temporary tables;
   proc sql; drop table _fortable_,_fromtab_,_SNZse_, _Nnsize_; quit;
;
%mend seforpropn1;


**
**	VERSION 2: General Social Survey suppression and quality flags
**;
*Warning - do not use this for estimates as this version multiplies results by 100;

*Note - these flags are based on General Social Survey rules used by Statistics NZ staff. 
Rules may differ for other surveys and for datalab users. The code should be updated as 
required;
/*seforpropn1_GSSflag --> seforpropn1_gssflag 20190403 AK*/
%macro seforpropn1_gssflag(indata=,outdata=,class=none,var=,wgt=,ExcludMissing=1,ExcludeMore=none);

   %** create a temporary table for table macro;
   data _fortable_;
      set &indata.;
      %if &ExcludMissing.=1 %then %do;
         %if %scan(&class.,1) ne none %then %do;
            %do i = 1 %to %SYSFUNC(countw(&class.));
               if %scan(&class.,&i) in (" ","77","88","89","99","999") then delete;
            %end;
         %end;
         if &var. in (" ","77","88","89","99","999") then delete;
      %end;
      %if %scan(&ExcludeMore.,1) ne none %then %do; if &ExcludeMore. then delete;%end;
   run;

   %** call %table macro to calculate the sampling errors;
   %table(data=_fortable_,                 /* input dataset */
         weight=&wgt.,                     /* main survey weight */
         repwts=&wgt._1-&wgt._100,         /* replicate weights */
         out=_fromtab_,                    /* output dataset  */
         %if &class. ne none %then %do;
            class=&class.,                   /* domain of estimates   */
         %end;
         subclass=&var.,
         maxspace=5000); 

   %*** converting to SNZ sampling errors ;
   data _SNZse_(drop=_est_ _var_ _se_ _rse_);
      set _fromtab_;
      Estimate=_est_*100;
      Sampling_error=_se_*1.96*100;
      Relative_sampling_error = (_se_*1.96/_est_)*100; 
      Lower_CI=Estimate -sampling_error;
      Upper_CI=Estimate +sampling_error;
      Confidence_level=95;
   run;

   %*** create the output table and attach population and sample size for each cell of the table;
   %if &class. ne none %then %do; 
      proc summary data=_fortable_ nway;
         class &class. &var. ;
         var &wgt.;
         output out=_Nnsize_ (drop=_type_ _freq_) sum=N_popn_count n=n_samp_count;
      run;
      data &outdata.;
          merge _SNZse_ _Nnsize_;
          by &class. &var. ;
      run;
   %end;
   %else %do;
      proc summary data=_fortable_ nway;
         class &var.;
         var &wgt.;
         output out=_Nnsize_ (drop=_type_ _freq_) sum=N_popn_count n=n_samp_count;
      run;
      data &outdata.;
          merge _SNZse_ _Nnsize_;
          by &var. ;
      run;
   %end;

/*Flagging cases with high relative sampling errors*/
data &outdata.;
	set &outdata.;

	Length Flag $4;
	if 30 <= Relative_sampling_error < 50 then Flag='*';
	else if 50 <= Relative_sampling_error < 100 then Flag='**';
	else if Relative_sampling_error >= 100 then Flag='***';

/*Suppression of values where the weighted population count is less than 1000*/
	if N_popn_count < 1000 then do;
		estimate=.;
		sampling_error=.;
		relative_sampling_error=.;
		Lower_CI=.;
		Upper_CI=.;
		N_popn_count=.;
		N_samp_count=.;
		Flag='S';
	end;

/*Round population count and show all other figures to 1 decimal place*/
if Flag ne 'S' then do;
		estimate=round(estimate, 0.1); 
		sampling_error=round(sampling_error, 0.1);
		relative_sampling_error=round(relative_sampling_error, 0.1);
		Lower_CI=round(Lower_CI, 0.1); 
		Upper_CI=round(Upper_CI, 0.1);
		N_popn_count=round(N_popn_count, 1000);

	end;

	drop N_samp_count;

run;

   %*** drop temporary tables;
   proc sql; drop table _fortable_,_fromtab_,_SNZse_, _Nnsize_; quit;
;
%mend seforpropn1_gssflag;

**
**	VERSION 3: Sampling error for levels (including totals)
**;
/*SEforLevel --> seforlevel 20190403 AK*/
%macro seforlevel(inset=, outset=, vars=, wgt=, ExcludeMissing=0, ExcludeMore=none);

   %local n var i;
   %let n = 1;
   %let var=%scan(&vars., &n.);
   %local x&n.;
   %let x&n. = &var.;

   %do %while(&var. ne);
      %let n=%eval(&n. + 1);
      %let var=%scan(&vars., &n.);
      %local x&n.;
      %if (&var. ne) %then %do;
         %let x&n. = &var.;
      %end;
   %end;

   %let n = %eval(&n. - 1);

   data _tmp_;
      set &inset.(keep=&vars. &wgt. %do i=1 %to 100; &wgt._&i. %end;);
      %if &ExcludeMissing. = 1 %then %do;
         %do i=1 %to &n.;
            if &&x&i.. in (' ', '88', '99') then delete;
         %end;
      %end;
      %if &ExcludeMore. ne none %then %do;
         if &ExcludeMore. then delete;
      %end;
   run;

   proc summary data=_tmp_;
      class &vars.;
      var &wgt. %do i=1 %to 100; &wgt._&i. %end;;
      output out=&outset.(drop=_type_ rename=(_freq_=n)) sum=;
   run;

   data &outset.;
      set &outset.;
      %do i=1 %to &n.;
         if missing(&&x&i..) then &&x&i..='TT';
      %end;
      array w{0:100} &wgt. &wgt._1-&wgt._100;
      array s{1:100} s1-s100;
      do i=1 to 100;
         s{i} = (w{i}-w{0})**2;
      end;
      Estimate = w{0};
      Sampling_error = 1.96 * sqrt(99/100*sum(of s1-s100));
      Relative_sampling_error = Sampling_error / Estimate * 100;
      Lower_CI = Estimate - Sampling_error;
      Upper_CI = Estimate + Sampling_error;
      Confidence_level = 95;
      drop i &wgt. &wgt._1-&wgt._100 s1-s100;
   run;

   proc sort data=&outset.;
      by &vars.;
   run;

   proc sql; drop table _tmp_; run; quit;

%mend seforlevel;