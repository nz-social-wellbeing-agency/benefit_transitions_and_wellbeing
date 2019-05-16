/*********************************************************************************************************
DESCRIPTION: Creates the main benefit spells dataset for the considered population.
First applies Marc DeBoer's code and logic for the full population, then take a subset.
Includes main benefits as single, primary and partner.
By benefit type and name, reconciliating pre and post welfare reform (2013) benefits.

INPUT:


OUTPUT:
sand.of_main_ben_spells = dataset with full list of main benefits spells (all time) for all individuals
of the considered population.

AUTHOR: 
Ben Vandenbroucke

DEPENDENCIES:
Macros in the sial folder


NOTES:
Only includes main benefit at the moment but T2 and T3 might be included in this program later

HISTORY: 
05 Mar 2018	BV
proc options;
run;
*********************************************************************************************************/
%include "/nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/SIAL/SIAL_dependencies/sasautos/adltsmainbenspl.sas";

/*Load benefit formats*/
%include "&si_source_path./include/ben_formats.sas";

/*Set the big date to the date of msd_spell update*/
proc sql;
	connect to odbc (dsn=&si_idi_dsnname.);
	select modify_date into :bigdate from connection to odbc (
		select cast(cast(year(modify_date) as varchar(4)) + 
			right( '0' + cast(month(modify_date) as varchar(2)), 2) + 
			right( '0' + cast(day(modify_date) as varchar(2)), 2) as integer) as modify_date
		from &idi_version..sys.tables 
		where name = 'msd_spell'
	);
	disconnect from odbc;
quit;

/*Run MarcDeBoer's code for the full population of main benefiaries*/
%adltsmainbenspl(AMBSinfile =
                 ,AMBS_IDIxt = &idi_version.
                 ,AMBS_BenSpl = work._temp_full_benspells
				 ,bigdate = &bigdate.);

/*Subset to the considered population*/
proc sql;
	create table work._temp_benspells as
	select a.snz_uid,
		"BEN" as datamart,
		a.EntitlementSD as start_date,
		a.EntitlementED as end_date,
		a.BenefitType as event_type,
		a.BenefitRole as event_type2,
		a.BenefitName as event_type3
	from work._temp_full_benspells a
/*	inner join &si_sandpit_libname..&si_pop_table_out. b on a.snz_uid=b.snz_uid*/
	where a.EntitlementSD < '01Jan2018'd and a.EntitlementED >= '01Jan2007'd;
quit;


/* Push the dataset into the database*/
%si_write_to_db(si_write_table_in=work._temp_benspells,
	si_write_table_out=&si_sandpit_libname..of_main_ben_spells
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/*%si_compact_spells(si_sial_table=[IDI_Sandpit].[DL-MAA2016-15].of_main_ben_spells, si_agg_cols =%str(snz_uid datamart ),*/
/*	si_out_table= of_main_ben_spells_con);*/

/* Delete temporary datasets*/
proc datasets lib=work;
	delete _temp_: ;
run;