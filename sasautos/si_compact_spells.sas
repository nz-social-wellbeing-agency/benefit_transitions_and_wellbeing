/*********************************************************************************************************
DESCRIPTION: Macro that compacts any spells that overlap, and creates one single consistent spell
	that covers the time period under all the constituent spells. To be combined, the individual
	spells must have the same values for all the aggregationg columns.

INPUT:
	si_sial_table = SIAL or SIAL like table in the following format
					[IDI_Sandpit].["si_proj_schema"].tablename
	si_agg_cols =  Columns that need to be considered while deciding on aggregation of spells.
					Only those rows with the same value for all of these columns will be considered
					for aggregation.
					Example: %str(snz_uid datamart event_type ...)
	unify_spells_threshold_days =  Numeric, signifying number of days. Any spells separated by "unify_spells_threshold_days" 
					days will be compacted as well, even if the time periods do not overlap. For example, consider the 
					following:
						Spell_1:	Jan 1 to Jan 5
						Spell_2:	Jan 7 to Jan 10
						unify_spells_threshold_days: 2
					In this scenario, even though the original spells are non-overlapping, the value of this input
					makes the two spells combine into one spell from Jan 1 to Jan 10.

OUTPUT:	
	"si_sandpit_libname"."si_out_table"

AUTHOR: V Benny

DEPENDENCIES:
	1. SI Data Foundation macros must be loaded into memory.

NOTES:
	NA

HISTORY:
	25 Mar 2018	VB	First version

*********************************************************************************************************/

%macro si_compact_spells(si_sial_table=, si_agg_cols =, unify_spells_threshold_days = 1,
	si_out_table=);

	/* Create SQL syntax for self joins for the input table*/
	%if not( &si_agg_cols.=%str() ) %then %do;
		%let i = 1;
		%let alias1 = tab1; /* Aliases for the self-join references*/
		%let alias2 = tab2;
		%let alias3 = tab3;
		%let commasep_aggcols = ;
		%let joinconditions1 = ;
		%let joinconditions2 = ;

		%do %while ( %scan(&si_agg_cols., &i.) ^= %str() );
			%let word = %scan(&si_agg_cols., &i.) ;
			%if &i. eq 1 %then %do;
				%let commasep_aggcols = %str(&alias1..&word.);
				%let joinconditions1 = %str( coalesce(&alias1..&word.,'1')=coalesce(&alias2..&word.,'1') );
				%let joinconditions2 = %str( coalesce(&alias1..&word.,'1')=coalesce(&alias3..&word.,'1') );
			%end;
			%else %do;
				%let commasep_aggcols = %str(&commasep_aggcols , &alias1..&word. );
				%let joinconditions1 = %str(&joinconditions1. and  coalesce(&alias1..&word.,'1')=coalesce(&alias2..&word.,'1') );
				%let joinconditions2 = %str(&joinconditions2. and  coalesce(&alias1..&word.,'1')=coalesce(&alias3..&word.,'1') );
			%end;
			%let i = %eval(&i. + 1);
		%end;
		
	%end;	


	/* Construct SQL query for performing compaction */
	proc sql;

		connect to odbc(dsn=&si_idi_dsnname.);

		create table _temp_combspells as
			select * from connection to odbc(

				with closedint as (
						select &commasep_aggcols., start_date, dateadd(dd, &unify_spells_threshold_days., end_date) as end_date 
						from &si_sial_table. tab1
					)
					/* For overlaps, fetch records with the earliest start dates*/
					,earliest as (
					select 
						row_number() over (partition by &commasep_aggcols. order by start_date) as rownum
						,*
					from closedint &alias1.
					where not exists (
						select 1 from closedint &alias2.
						where &joinconditions1.
							and &alias1..start_date > &alias2..start_date 
							and &alias1..start_date <= &alias2..end_date
						)
				)
				select 
					&commasep_aggcols.
					/*,row_number() over (partition by &commasep_aggcols. order by &alias1..start_date) */
					,&alias1..start_date
					,dateadd(dd, -&unify_spells_threshold_days.,max(&alias3..end_date)) as end_date
				from earliest &alias1.
				left join earliest &alias2. on (&joinconditions1. and &alias1..rownum + 1 = &alias2..rownum)
				left join closedint &alias3. 
					on (&joinconditions2. 
						and &alias1..start_date <= &alias3..start_date 
						and (&alias3..start_date < &alias2..start_date or &alias2..start_date is null)
						)
				group by 
					&commasep_aggcols.
					,&alias1..start_date
				order by snz_uid
					,&alias1..start_date

			);

		disconnect from odbc;

	quit;

	%si_write_to_db(si_write_table_in=work._temp_combspells,
		si_write_table_out=&si_sandpit_libname..&si_out_table.
		,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

	proc datasets lib=work;
		delete _temp_: ;
	run;

%mend;

/* Test Code*/
/*%si_compact_spells(si_sial_table=[IDI_Sandpit].[DL-MAA2016-15]._spellcomb_tester , si_agg_cols =%str(snz_uid event_type),*/
/*	si_out_table= _spellcomb_tester);*/