/*********************************************************************************************************
TITLE: si_write_to_db.sas

DESCRIPTION: Macro to save a table that is in the work space into the sandpit

INPUT:
si_write_table_in = table in the sas work space to write into the db
si_cluster_index_flag = whether or not you want to create a cluster index {True|False}
si_index_cols =  columns that you wish to create an index on


OUTPUT:
si_write_table_out = name of output table prefixed with the libname that points to the database

AUTHOR: E Walsh

DATE: 28 Apr 2017

DEPENDENCIES: 

NOTES: 
If you are creating an index on multiple columns you will need to mask the comma.
	See the sasprogs/si_unit_test.sas for correct and incorrect methods of doing this.

For the input dataset si_write_table_in do not specify the work libname

HISTORY: 
28 Apr 2017 EW v1
*********************************************************************************************************/
%macro si_write_to_db (si_write_table_in = , si_write_table_out = , si_cluster_index_flag = False, si_index_cols = snz_uid);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_write_to_db: Inputs-----------------------------;
	%put .....si_write_table_in: &si_write_table_in;
	%put ....si_write_table_out: &si_write_table_out;
	%put .si_cluster_index_flag: &si_cluster_index_flag;
	%put .........si_index_cols: &si_index_cols;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	/* these macros are only required within this macro */
	%local db_lib db_engine db_schema db_ds;

	/* writing to the database needs an implicit passthrough */
	%if %scan(&si_write_table_out.,2,.)=  %then
		%do;
			%put ERROR: In si_write_to_db.sas - writing to the database uses an implicit passthrough "\n"
				si_write_table_out must have a libname specified to write to the database;
		%end;
	%else
		%do;
			%let db_lib = %scan(%upcase(&si_write_table_out.,1,.));
			%let db_ds = %scan(%upcase(&si_write_table_out.,2,.));

			/* confirm whether the data is being written to the database */
			/* note the macro varaible db_schema is left in here in case we want to check that the person is writing */
			/* to a particular schema at a later date but for now we are just concerned about whether the library */
			/* points to the database */
			proc sql noprint;
				select engine, sysvalue
					into: db_engine separated by ''
					, :db_schema separated by ''
				from dictionary.libnames
					where libname = "&db_lib";
			quit;

			%if "&db_engine" ~= "ODBC" %then
				%do;
					%put ERROR: In  si_write_to_db.sas - non ODBC engine specified. Are you sure you are writing to the database?;
				%end;
			%else
				%do;
					/* to avoid warnings about dropping tables that do not exist conditionally check the table */
					/* exists before deleting */
					%si_conditional_drop_table(si_cond_table_in = &si_write_table_out.);

					/* write to database via implicit passthrough */
					data &si_write_table_out.;
						set &si_write_table_in.;
					run;

					/* reorder the way records are physically stored so that tables can be joined more efficienctly */
					%if &si_cluster_index_flag. = True %then
						%do;
							%put INFO: In  si_write_to_db.sas - creating cluster index on &si_write_table_out - &si_index_cols;

							proc sql;
								connect to odbc(dsn=&si_idi_dsnname.);
								execute(create clustered index cluster_index on 
									[IDI_Sandpit].[&si_proj_schema].[&db_ds] (&si_index_cols)) by odbc;
								disconnect from odbc;
							quit;

						%end;
				%end;
		%end;
%mend si_write_to_db;