/*********************************************************************************************************
DESCRIPTION: 
Create IRD spells in long table form for GSS population.

INPUT:
	ir_clean.ird_ems

OUTPUT:
	"si_sandpit_libname".of_ird_spells

AUTHOR: 
	V Benny, W Lee

DEPENDENCIES:
	NA

NOTES:  
	NA

HISTORY: 
	26 Mar 2018	VB	First version

***********************************************************************************************************/

/* Create a yearly minimum hourly wage dataset from 2007 to 2017. 
Source: MBIE:www.employment.govt.nz/hours-and-wages/pay/minimum-wage/previous-rates */
data _temp_minwage;

	attrib start_date format=date9.;
	attrib end_date format=date9.;
	attrib minwage length=8;	
	input start_date : date9. end_date : date9. minwage $;

	infile datalines dlm="," dsd missover;
	datalines;
	"27Mar2006"d,"31Mar2007"d, 10.25
 	"01Apr2007"d,"31Mar2008"d, 11.25
	"01Apr2008"d,"31Mar2009"d, 12.00
	"01Apr2009"d,"31Mar2010"d, 12.50
	"01Apr2010"d,"31Mar2011"d, 12.75
	"01Apr2011"d,"31Mar2012"d, 13.00
	"01Apr2012"d,"31Mar2013"d, 13.50
	"01Apr2013"d,"31Mar2014"d, 13.75
	"01Apr2014"d,"31Mar2015"d, 14.25
	"01Apr2015"d,"31Mar2016"d, 14.75
	"01Apr2016"d,"31Mar2017"d, 15.25
	"01Apr2017"d,"31Mar2018"d, 15.75
	"01Apr2018"d,"31Mar2019"d, 16.50
run;

/* Push the dataset into the database*/
%si_write_to_db(si_write_table_in=work._temp_minwage,
	si_write_table_out=&si_sandpit_libname..yearly_minimum_wage
	,si_cluster_index_flag=False
	);

/* We have defined two ways of defining IRD spells. Here, we choose between the method of calculation for IRD spells.
	activate_emp_low_flg = True gives us the IRD spells taking into account minimum wage calculation*/
%let ird_query_str = ;
%choose_ird_query(activate_emp_low_flg = True, queryvar = ird_query_str);

/* Taking EMS data for creation of spells*/
proc sql;

connect to odbc (dsn=&si_idi_dsnname.);

	create table _temp_ird_gss as
		select 
			*
		from connection to odbc(
			&ird_query_str.		   
		) spells;

	disconnect from odbc;

quit;

/* Push the dataset into the database*/
%si_write_to_db(si_write_table_in=work._temp_ird_gss,
	si_write_table_out=&si_sandpit_libname..of_ird_spells
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);
