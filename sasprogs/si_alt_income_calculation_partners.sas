
/* Here we invoke Marc DeBoer's macros to construct a measure of income and tax credits, to function as an
	alternative to the existing measures of income we have.*/
/* Updated the macro names to lower case - AK - 20190402 */

%include "&si_source_path./include/frmtdatatight.sas";
%include "&si_source_path./include/hashtblfulljoin.sas";
%include "&si_source_path./include/subset_ididataset2.sas";
%include "&si_source_path./include/use_fmt.sas";
%include "&si_source_path./include/indv_money_inout_macro.sas";

  proc sql;
 	connect to odbc (dsn=&si_idi_dsnname.);
	create table work.tmp_records_toupdate2 as select * from connection to odbc(
 		select snz_uid from IDI_Sandpit.[&si_proj_schema.].of_gss_partners_adminvars_mh);
	disconnect from odbc;
 quit;
options mprint;
 %indv_money_inout_macro( IMMIO_infile =tmp_records_toupdate2
                           ,IMMIO_IDIexDt = %substr(&idi_version, %length(&idi_version) - 7, 8) /*Extracts the date string from the database name*/
                           ,IMMIO_RptSD =01Jan2006
                           ,IMMIO_RptED =31Dec2017
                           ,IMMIO_Outfile =tmp_income
                           ,IMMIO_IncomeDetail = 2
                           ,IMMIO_LoanDetail = 2
                           ,IMMIO_TaxDetail = 2
                           ,IMMIO_TransferDetail = 2
                           ,IMMIO_annual = IncomeOutgoingsAnnual
                           ,IMMIO_InCDudCode = IncomeOutgoingsCodeLookup
                           ,IMMIO_SandPitSchema = &si_proj_schema.
                           ) ;

/* We only retain the tax credit component of the income so generated.*/
proc sql; 

	create table tmp_income as 
	select 
		a.snz_uid
		,'INC' as department
		,'INC' as datamart
		,'INC' as subject_area
		,startdate as start_date
		,enddate as end_date
		,amount as cost
		,a.incdudcode as event_type
		,b.Level1 as event_type2
		,b.Level2 as event_type3
		,b.Level3 as event_type4
		,b.LevelN as event_type5
	from tmp_income a
	inner join incomeoutgoingscodelookup b on (a.incdudcode = b.incdudcode and a.Level3=b.Level3);

	create table tmp_income2 as
	select * from tmp_income 
	where event_type in ('fdrtpi', 'frdtir', 'emstpm', 'frdtwi');


quit;

%si_write_to_db(si_write_table_in=work.tmp_income,
	si_write_table_out=&si_sandpit_libname..of_gss_partners_admin_income
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid, event_type, start_date)
	);

 %si_write_to_db(si_write_table_in=work.tmp_income2,
	si_write_table_out=&si_sandpit_libname..of_gss_partners_admin_taxcreds
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid, event_type, start_date)
	);
