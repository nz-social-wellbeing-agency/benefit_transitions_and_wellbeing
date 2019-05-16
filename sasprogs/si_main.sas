/*********************************************************************************************************
DESCRIPTION: Mental Health and Employment Transitions
Main script that determines the sequence of execution for all SAS data preparation tasks.


INPUT:
	si_control.sas = Specify the parameters which decide how the data foundation works and what variables 
		to create.
	si_source_path = Specify the path where you saved the SI data foundation code.

OUTPUT:
	

DEPENDENCIES:
1. Social Investment Data Foundation macros need to be available as a library.
2. si_control.sas file should be set up with the configuration parameters required to run the data 
	foundation.

NOTES: 

HISTORY: 
V2: PNH: Changes to Run on SAS-GRID linux environment
& additional income fields for David Rea
*********************************************************************************************************/


/* Switch this statement off when testing is complete */
/*options mlogic mprint;*/

/* Parameterise location where the folders are stored */
/* %let si_source_path = //wprdfs09/Datalab-MA/MAA2016-15 Supporting the Social Investment Unit/outcomes_framework/benefit_transitions; */
%let si_source_path  =/nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/outcomes_framework/benefit_transitions;
%let SIAL_source_path=/nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/SIAL;
/* Load user name and password */
/* march 2019 - no longer required*/
/*%include "&si_source_path./sasprogs/credentials.sas";*/

/**********************************RUN CONFIGURATION AND SETUP***********************************************************************/

/* Set up a variable to store the runtime of the script; this helps to plan for future re-runs of code if necessary */
%global si_main_start_time;
%let si_main_start_time = %sysfunc(time());


/*%symexist(%si_compact_spells)*/

/* Load all the macros for the project and from the associated dependencies */
options obs=MAX mvarsize=max pagesize=132 
        append=sasautos=("&si_source_path./lib/social_investment_data_foundation/sasautos"
						"&SIAL_source_path/SIAL_dependencies/sasautos"
						"&si_source_path./sasautos");


/* Load the user's parameters and global variables that define how the data foundation works from the 
	control file */
%include "&si_source_path./sasprogs/si_control.sas";

/* libname &si_sandpit_libname. ODBC dsn= idi_sandpit_srvprd schema="&si_proj_schema." bulkload=yes; */
libname &si_sandpit_libname. ODBC dsn= idi_sandpit_srvprd  schema="&si_proj_schema.";

/************************************CREATE SPELLS OF INTEREST***********************************************************************/
/*Create the benefit spells dataset for the GSS population*/
%include "&si_source_path./sasprogs/si_create_benefit_spells.sas";
/*Compacting spells to the required level of datamart/event_type */
%si_compact_spells(si_sial_table=[IDI_Sandpit].[DL-MAA2016-15].[of_main_ben_spells] , si_agg_cols =%str(snz_uid datamart),
	si_out_table= of_main_ben_spells_comp, unify_spells_threshold_days = 14);

/*Create the employment spells dataset for the GSS population*/
%include "&si_source_path./sasprogs/si_create_ird_spells.sas";
/*Compacting spells to the required level of datamart/event_type */
%si_compact_spells(si_sial_table=[IDI_Sandpit].[DL-MAA2016-15].[of_ird_spells] , si_agg_cols =%str(snz_uid datamart),
	si_out_table= of_ird_spells_comp, unify_spells_threshold_days = 1);

/*Create the education spells dataset for the GSS population*/
/*%include "&si_source_path./sasprogs/si_create_edu_spells.sas";*/
/*Compacting spells to the required level of datamart/event_type */
/*%si_compact_spells(si_sial_table=[IDI_Sandpit].[DL-MAA2016-15].[of_edu_spells] , si_agg_cols =%str(snz_uid datamart),*/
/*	si_out_table= of_edu_spells_comp, unify_spells_threshold_days = 1);*/

/*Create ..... spells dataset for the GSS population*/


/* Create non-overlapping combination spells for all individuals of interest for MHaET*/
%si_combine_spells(si_tables=%str(of_main_ben_spells_comp of_ird_spells_comp ), si_out_table=of_comb_spells);


/************************************GSS HOUSEHOLD DATASET CREATION******************************************************************/

/* Create a GSS Household dataset with all the required GSS household-level variables */
%include "&si_source_path./sasprogs/si_create_of_gss_hh_variables.sas";

/* Perform linking of individuals in the household dataset with the IDI spine */
/*%include "&si_source_path./sasprogs/si_link_gss_addr_households.sas";*/

/* Create a GSS partners dataset with all the required admin person-level variables (2014 and 2016 only)*/
%include "&si_source_path./sasprogs/si_create_of_gss_partners_admin_variables.sas";



/************************************GSS PERSONAL DATASET CREATION*******************************************************************/
/* Create a GSS Individuals dataset with all the required GSS person-level variables */
%include "&si_source_path./sasprogs/si_create_of_gss_ind_variables.sas";

/* Create a GSS Individuals dataset with all the required GSS person-level variables */
%include "&si_source_path./sasprogs/si_create_of_gss_ind_wrapper.sas";

/*Create the SF12 scores*/
%include "&si_source_path./sasprogs/si_gss_sf12v2_nz_norms.sas";

/* Create a GSS Individuals dataset with all the required admin person-level variables */
%include "&si_source_path./sasprogs/si_create_of_gss_ind_admin_variables_mth.sas";



/*Apply custom rules for filtering and prioritisation for Benefit to employment transitions*/
%include "&si_source_path./sasprogs/si_ben_to_work_rules.sas";



/* At this point, we run R scripts that create the BEN-EMP sequences for the individuals, and defines
filters that can be used to identify the population of interest in this analysis. The R script can be found in
"&si_source_path./rprogs/convert_spells_to_sequence.R" */


/* This script creates the BEN to EMP transitions population and EMP to BEN transitions population*/
%include "&si_source_path./sasprogs/si_mhaet_population_definition.sas";
