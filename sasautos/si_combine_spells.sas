/*********************************************************************************************************
DESCRIPTION: 
	This macro accepts a list of SIAL tables or a SIAL-like table (i.e., same column format as the SIAL 
	tables), and creates a new dataset that combines the events from all the input tables. Events that 
	overlap in time from the same SIAL table or different SIAL tables for an individual will be converted 
	into combination events for the overlapping duration. The final result will be a table with non-overlapping
	events and the start and end dates for these events.	
	
	For instance: 
		1. A person is on EVENT_A1 from Jan 1 to Jan 10 (from SIAL table A)
		2. EVENT_A2 from Jan 3 to Jan 9 (from SIAL table A)
		3. EVENT_B from Jan 5 to Jan 7 (from SIAL table B)
		4. EVENT_C on Jan 5 (from SIAL table C)

	The output table in this scenario will be: 
		1. EVENT_A1 from Jan 1 to Jan 2.
		2. EVENT_A1 + EVENT_A2 from Jan 3 to Jan 4.
		3. EVENT_A1 + EVENT_A2 + EVENT_B + EVENT_C from Jan 5 to Jan 5.
		4. EVENT_A1 + EVENT_A2 + EVENT_B from Jan 6 to Jan 7.
		5. EVENT_A1 + EVENT_A2  from Jan 8 to Jan 9.
		6. EVENT_A1 from Jan 10 to Jan 10.

	If there are multiple event types in the input tables for each of the SIAL tables, the combination events
	are created by taking into account all the event types from all tables. Hence, care must be taken to 
	subset the input tables to only the required event types that require combination.
	

INPUT:
	si_tables = The SIAL tables to be combined together to create the combination events, enclosed in
				brackets as shown below. These tables should be available in the "si_project_schema"
				global variable.
				%str(SIAL_table_A SIAL_table_B ...)
	si_out_table = The name of the output table .
				(valid SQL table names)
	fixed_cols = If there are any extra columns that need to be part of the combination event creation,
				include those here. By default, the "datamart" column is always included in the combination
				event. 

OUTPUT:
	"si_project_schema"."si_out_table"

AUTHOR: V Benny, B Vandenbroucke

DEPENDENCIES:
	1. "si_project_schema" variable should be declared before macro invocation.
	2. "si_sandpit_libname" variable should be declared before macro invocation.
	3. SI Data Foundation macros must be available and loaded in memory.


KNOWN ISSUES:


HISTORY: 
	25 Mar 2018 VB	First version.	

*********************************************************************************************************/

%macro si_combine_spells(si_tables=, si_out_table=, fixed_cols=datamart);

	/* Create a loop to look through each table that is supplied. We will keep track of the event types 
	provided in each table*/
	%let i = 1;
	%do %while ( %scan(&si_tables., &i.) ^= %str() );
		
		/* Get the current table name */
		%let table = %scan(&si_tables., &i.) ;		
		%let eventcols_&i. = ;

		/* Determine the event types in the current table under consideration and store into a variable*/
		proc sql;
			select name into :eventcols_&i. separated by ' ' from sashelp.vcolumn 
			where libname = 'SAND' 
				and memname = "&table."
				and name like 'event_type%';
		quit;
		
		/* PNH: QA Nov 2018 - the below code does not work. SAS coalesce returns a numeic, and countw with 
		/* If event columns were not found*/
/*		%if %sysfunc(countw(coalesce(&&eventcols_&i.),"")) eq 0 %then*/
/*		%put 'WARNING: No event columns found for table ' &table. 'or table does not exist.';*/
		%if %trim(&&eventcols_&i.) eq %str() %then
		%put WARNING: No event columns found for table &table. or table does not exist.;
		%put Event table will be build just using &fixed_cols;
		
		/* Inner Loop: Loop through each event type in the current table and create query constructs for use later
			This basically creates SQL syntax to append the event types together (with pipe separation between 
			event_types). Any fixed_cols are pre-fixed before the event types.*/
		%let j = 1;
		%let querycol_&i= &fixed_cols. ; 
		%do %while ( %scan(&&eventcols_&i., &j.) ^= %str() );
			%let eventcol = %scan(&&eventcols_&i., &j.) ;
			%let querycol_&i = &&querycol_&i. + '|' + coalesce(&eventcol. , '') ;		
			%let j = %eval(&j. + 1);
		%end;	/* Inner loop ends. */
		

		%let i = %eval(&i. + 1);
	%end; /* Loop ends. */

	/*Construct a dataset with all the dates from start and end dates of all spells/tables.
		Mark the dates as either start or end date using the 'end_flag' variable*/

	proc sql;
		connect to odbc(dsn=&si_idi_dsnname.);
		create table _temp_comb_spells as
		select * from connection to odbc(
		
			select *
				,lag(end_flag) over (partition by snz_uid order by date, end_flag) as prev_flag
				,lag(date) over (partition by snz_uid order by date, end_flag) as prev_date
				,lag(event_type) over (partition by snz_uid order by date, end_flag) as prev_event
				,lead(end_flag) over (partition by snz_uid order by date, end_flag) as next_flag
				,lead(date) over (partition by snz_uid order by date, end_flag) as next_date
				,lead(event_type) over (partition by snz_uid order by date, end_flag) as next_event 
			from (
				/* These union all queries must be for all the input tables, so use a loop to iterate through table list.
				All events under the same SIAL input table are appended together to form one string, which will be called 
				'event_type'. */
				%if not( &si_tables.=%str() ) %then %do;
					%let i = 1;
					%do %while ( %scan(&si_tables., &i.) ^= %str() );
						%let table = %scan(&si_tables., &i.) ;

						%if &i. ne 1 %then %do; union all %end;
						select distinct snz_uid, start_date as date, 'F' as end_flag
							, '{' + cast(row_number() over (partition by snz_uid order by start_date) as varchar(1000)) + &&querycol_&i + '}' as event_type
							  from [IDI_Sandpit].[&si_proj_schema.].[&table.]
							  union all 
						select distinct snz_uid, end_date as date, 'T' as end_flag
							,  '{' + cast(row_number() over (partition by snz_uid order by start_date) as varchar(1000)) + &&querycol_&i + '}' as event_type
							  from [IDI_Sandpit].[&si_proj_schema.].[&table.]

						%let i = %eval(&i. + 1);
					%end;
				%end;
				) x		 
			order by snz_uid, date, next_date

			);
		disconnect from odbc;
	quit;

	/* Create a table that breaks overlapping spells into non-overlapping spells. For the overlapping periods
	with muliple events, this will create combo events, but ensure that all spells are non-overlapping.*/
	data work._temp_spells_2( drop=prev_final_event_type prev_flag prev_date prev_event next_flag);
		
		set _temp_comb_spells;
		format start_date end_date date next_date datetime20.;
		length final_event_type prev_final_event_type $2000.;
		
		/*The logic for non-overlapping spells work per snz_uid*/
		by snz_uid;
		retain final_event_type;

		/* If this is the first record for an individual, initialise the previous record's final_event_spell with blank.*/
		if first.snz_uid then final_event_type ="";
		prev_final_event_type = strip(final_event_type);		
		
		/* If the current record is the start of a spell, then start date is the same date and the end date of this spell
		is either the next record's date - 1day (if the next record is also a start-of-spell) or the next record's date (if
		the next record is an end-of-spell).
		Also, if the current record is start-of-spell, append the current event to the previous event set. If it is end-of-spell,
		remove the current event from the previous event set.
		*/
		if end_flag eq 'F' then do;
			start_date = date;
			final_event_type = strip(catx("",coalescec(prev_final_event_type, ""), strip(event_type)));
			if next_flag eq 'F' then end_date = intnx('DTDAY',next_date,-1,'begin');
			else if next_flag eq 'T' then end_date = next_date;
		end;
		if end_flag eq 'T' then do;
			start_date = intnx('DTDAY',date,1,'begin');
			final_event_type = strip(tranwrd(prev_final_event_type, trim(event_type), ""));
			if next_flag eq 'F' then end_date = intnx('DTDAY',next_date,-1,'begin');
			else if next_flag eq 'T' then end_date = next_date;
		end;


	run;

	/*Create the final dataset with no blank spells and only the required wset of columns*/
	proc sql;
		create table _temp_spells_3 as
		select snz_uid, start_date, end_date, final_event_type
		from _temp_spells_2
		where final_event_type is not missing
			and start_date <= end_date;
	quit;

/*Push to the database*/
%si_write_to_db(si_write_table_in=work._temp_spells_3,
	si_write_table_out=&si_sandpit_libname..&si_out_table.
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
); 

/*Delete temp datasets*/
/*proc datasets lib=work;*/
/*	delete _temp_: ;*/
/*run;*/;


%mend;

/*Test*/
/*%si_combine_spells(si_tables=%str(of_main_ben_spells_comp), si_out_table=of_comb_spells);*/



	