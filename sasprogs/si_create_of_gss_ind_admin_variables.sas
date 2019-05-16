/*******************************************************************************************************
TITLE: si_create_of_gss_ind_admin_variables.sas

DESCRIPTION: This script creates all the covariates required for the MHAET project from the admin datasets
	in the IDI.

INPUT: 
	SAS variable "si_pop_table_out" 
	SIAL tables


OUTPUT:
	SQL Table named by "si_pop_table_out" 

KNOWN ISSUES:
	NA

DEPENDENCIES: 
	1. SIAL tables should be available in the project schema.
	2. The SI Data Foundation macros should be available for use.

NOTES: 
	NA


AUTHOR: V Benny

DATE: 03 Apr 2018

HISTORY: 
	03 Apr 2018	VB	First version
	07 Sep 2018	VB	Temporary addition that calculates income from admin datasets using an alternative 
					method developed by Marc DeBoer, to compare against our existing income measure
					and ensure that the differences are minimal.

*******************************************************************************************************/



/*********************************MOH Admin variables**************************************************/
/* 1. Pharms cost over 1 year */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MOH_pharm_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. , 
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = MOH_pharm_events_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );

/* Create the roll-up variables */
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = MOH_pharm_events_aln,	
	si_out_table = MOH_pharm_events_rlp,	
	si_agg_cols= %str(department datamart subject_area),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = &si_rollup_output_type.
);



/* 2. Public hospitalisation counts and duration */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MOH_pfhd_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. , 
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = MOH_pfhd_events_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );

/* Create the roll-up variables */
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = MOH_pfhd_events_aln,	
	si_out_table = MOH_pfhd_events_rlp,	
	si_agg_cols= %str(department datamart subject_area),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = False, 
	duration = True, 
	count = True, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = &si_rollup_output_type.
);


/*********************************MSD Admin variables**************************************************/
/* Time spent on main benefits */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MSD_t1_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = NA , 
			si_amount_col = NA , 
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = MSD_t1_events_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = NA , 
			si_pi_qtr = NA );

%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = MSD_t1_events_aln,	
	si_out_table = MSD_t1_events_rlp,	
	si_agg_cols= %str(datamart),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = NA ,
	cost = False, 
	duration = True, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = &si_rollup_output_type.
);


/*********************************MOE Admin variables**************************************************/
/* Time spent in tertiary education */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MOE_tertiary_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = NA , 
			si_amount_col = NA , 
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = MOE_tertiary_events_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = NA , 
			si_pi_qtr = NA );

%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = MOE_tertiary_events_aln,	
	si_out_table = MOE_tertiary_events_rlp,	
	si_agg_cols= %str(datamart),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = NA ,
	cost = False, 
	duration = True, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = &si_rollup_output_type.
);

	/*********************************COR Admin variables**************************************************/
	/* Time spent incarcerated or in contact with the corrections system. This is defined by the following 
		Corrections codes:
			PRISON	Prison sentenced
			REMAND	Remanded in custody
			HD_SENT	Home detention sentenced
			HD_REL	Released to HD
			ESO	Extended supervision order
			PAROLE	Paroled
			ROC	Released with conditions
			PDC	Post detention conditions
			PERIODIC	Periodic detention
			COM_DET	Community detention
			CW	Community work
			COM_PROG	Community programme
			COM_SERV	Community service
			OTH_COM	Other community
			INT_SUPER	Intensive supervision
			SUPER	Supervision
	*/
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_COR_sentence_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = NA , 
			si_amount_col = NA , 
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = COR_sentence_events_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = NA , 
			si_pi_qtr = NA );

%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = COR_sentence_events_aln,	
	si_out_table = COR_sentence_events_rlp,	
	si_agg_cols= %str(department datamart subject_area),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = NA ,
	cost = False, 
	duration = True, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = &si_rollup_output_type.
);

/*********************************IRD Admin variables**************************************************/

/* Here we invoke Marc DeBoer's macros to construct a measure of income and tax credits, to function as an
	alternative to the existing measures of income we have. Please note the logic used for this measure of 
income is still pending review */
%include "&si_source_path.\sasprogs\si_alt_income_calculation.sas";


/* Gross Income in the month of interview. */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_IRD_income_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = 30 , 
			si_out_table = IRD_income_events_30d_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = IRD_income_events_30d_aln,	
	si_out_table = IRD_income_events_30d_rlp,	
	si_agg_cols= %str(department datamart subject_area),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Long
);

/* Get total T2 benefits in the month of interview */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MSD_t2_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 1 , /* Since we would like to look at accomodation supplement 1 month after the interview as well.*/
			period_duration = 30 , 
			si_out_table = MSD_t2_events_30d_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = MSD_t2_events_30d_aln,	
	si_out_table = MSD_t2_events_30d_rlp,	
	si_agg_cols= %str(department datamart subject_area event_type),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Long
);

/* Interview month's income from tax credits*/
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].of_gss_admin_taxcreds , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = 30 , 
			si_out_table = ALT_taxcred_events_30d_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = ALT_taxcred_events_30d_aln,	
	si_out_table = ALT_taxcred_events_30d_rlp,	
	si_agg_cols= %str(department datamart subject_area),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Long
);


/*********************************IRD Admin variables / 1year for net monthly income *********************/
/* IRD income - 1 year before interview, monthly */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_IRD_income_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = IRD_income_events_1yr_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );

%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = IRD_income_events_1yr_aln,	
	si_out_table = IRD_income_events_1yr_rlp,	
	si_agg_cols= %str(department datamart subject_area),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Both
);

/*MSD T2 income - 1 year before interview, monthly */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MSD_t2_events , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 1 ,  
			period_duration = Year , 
			si_out_table = MSD_t2_events_1yr_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = MSD_t2_events_1yr_aln,	
	si_out_table = MSD_t2_events_1yr_rlp,	
	si_agg_cols= %str(department datamart subject_area event_type),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Both
);

/* Tax credits - 1 year before interview, monthly */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].of_gss_admin_taxcreds , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = ALT_taxcred_events_1yr_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );
%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = ALT_taxcred_events_1yr_aln,	
	si_out_table = ALT_taxcred_events_1yr_rlp,	
	si_agg_cols= %str(department datamart subject_area event_type),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Both
);

/******** Temporary addition based on David's request dated 07 August 2018 ****************/

/*IRD income (from alternate source) - 1 year, monthly */
%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.,
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].of_gss_admin_income , 						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. ,  
			noofperiodsbefore = -1 , 
			noofperiodsafter = 0 , 
			period_duration = Year , 
			si_out_table = ALT_income_events_1yr_aln,
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );

%si_create_rollup_vars(
	si_table_in = sand.&si_pop_table_out., 
	si_sial_table = ALT_income_events_1yr_aln,	
	si_out_table = ALT_income_events_1yr_rlp,	
	si_agg_cols= %str(department datamart subject_area event_type),	
	si_id_col = &si_id_col. ,
	si_as_at_date = &si_asat_date. ,
	si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
	cost = True, 
	duration = False, 
	count = False, 
	count_startdate = False, 
	dayssince = False,
	si_rollup_ouput_type = Both
);



/******** End Temporary addition****************/



/*******************************************************************************************************/
/* Consolidate all admin variables and create custom variables as required 

Yearly Net Income is defined as follows: 
 Income 
	P_IRD_EMP_C00_CST
	P_IRD_EMP_C01_CST
	P_IRD_EMP_C02_CST
	P_IRD_EMP_P00_CST
	P_IRD_EMP_P01_CST
	P_IRD_EMP_PPL_CST
	P_IRD_EMP_S00_CST
	P_IRD_EMP_S01_CST
	P_IRD_EMP_S02_CST
	P_IRD_EMP_WAS_CST
	P_IRD_INS_BEN_CST
	P_IRD_INS_CLM_CST
	P_IRD_INS_PEN_CST
	P_IRD_RNT_S03_CST
	P_IRD_STS_STU_CST
	P_MSD_BEN_T2_065_CST
	P_MSD_BEN_T2_340_CST
	P_MSD_BEN_T2_344_CST
	P_MSD_BEN_T2_425_CST
	P_MSD_BEN_T2_450_CST
	P_MSD_BEN_T2_460_CST
	P_MSD_BEN_T2_471_CST
	P_MSD_BEN_T2_500_CST
	P_MSD_BEN_T2_833_CST
	P_MSD_BEN_T2_835_CST
	P_MSD_BEN_T2_838_CST
	P_INC_INC_INC_emstpm_CST
	P_INC_INC_INC_fdrtpi_CST
	P_INC_INC_INC_frdtir_CST
	P_INC_INC_INC_frdtwi_CST
 Tax 
	P_IRD_PYE_BEN_CST
	P_IRD_PYE_CLM_CST
	P_IRD_PYE_PEN_CST
	P_IRD_PYE_PPL_CST
	P_IRD_PYE_STU_CST
	P_IRD_PYE_WAS_CST
	P_IRD_WHT_WHP_CST
*/



proc sql;

	create table _temp_adminvars as 
	select 
		ind.snz_uid
		,pharm.P_MOH_PHA_PHA_cst
		,pfhd.P_MOH_PFH_PFH_dur
		,t1.P_BEN_DUR/365.24 as P_BEN_DUR_prop
		,coalesce(ird.inc_intvwmnth, 0.00) as inc_intvwmnth_gross /* Gross Income in the specific month before interview*/
		,coalesce(paye.incpaye_intvwmnth, 0.00) as incpaye_intvwmnth_gross /* PAYE Income in the specific month before interview*/
		,coalesce(yearlynet.income_monthly_net, 0.00) as income_monthly_net /* Average monthly net income for 1 year before interview*/
		,coalesce(yearlynetalt.income_monthly_net_comp, 0.00) as income_monthly_net_comp /* Average monthly net income for 1 year before interview from an alternate source*/
		,coalesce(irddetail.P_IRD_EMP_C00_CST , 0.00) as P_IRD_EMP_C00_CST /*Specific components of net income for the year*/
		,coalesce(irddetail.P_IRD_EMP_C01_CST, 0.00) as P_IRD_EMP_C01_CST
		,coalesce(irddetail.P_IRD_EMP_C02_CST, 0.00) as P_IRD_EMP_C02_CST
		,coalesce(irddetail.P_IRD_EMP_P00_CST, 0.00) as P_IRD_EMP_P00_CST
		,coalesce(irddetail.P_IRD_EMP_P01_CST, 0.00) as P_IRD_EMP_P01_CST
		,coalesce(irddetail.P_IRD_EMP_PPL_CST, 0.00) as P_IRD_EMP_PPL_CST
		,coalesce(irddetail.P_IRD_EMP_S00_CST, 0.00) as P_IRD_EMP_S00_CST
		,coalesce(irddetail.P_IRD_EMP_S01_CST, 0.00) as P_IRD_EMP_S01_CST
		,coalesce(irddetail.P_IRD_EMP_S02_CST, 0.00) as P_IRD_EMP_S02_CST
		,coalesce(irddetail.P_IRD_EMP_WAS_CST, 0.00) as P_IRD_EMP_WAS_CST
		,coalesce(irddetail.P_IRD_INS_BEN_CST, 0.00) as P_IRD_INS_BEN_CST
		,coalesce(irddetail.P_IRD_INS_CLM_CST, 0.00) as P_IRD_INS_CLM_CST
		,coalesce(irddetail.P_IRD_INS_PEN_CST, 0.00) as P_IRD_INS_PEN_CST
		,coalesce(irddetail.P_IRD_RNT_S03_CST, 0.00) as P_IRD_RNT_S03_CST
		,coalesce(irddetail.P_IRD_STS_STU_CST, 0.00) as P_IRD_STS_STU_CST
		,coalesce(msddetail.P_MSD_BEN_T2_065_CST, 0.00) as P_MSD_BEN_T2_065_CST
		,coalesce(msddetail.P_MSD_BEN_T2_340_CST, 0.00) as P_MSD_BEN_T2_340_CST
		,coalesce(msddetail.P_MSD_BEN_T2_344_CST, 0.00) as P_MSD_BEN_T2_344_CST
		,coalesce(msddetail.P_MSD_BEN_T2_425_CST, 0.00) as P_MSD_BEN_T2_425_CST
		,coalesce(msddetail.P_MSD_BEN_T2_450_CST, 0.00) as P_MSD_BEN_T2_450_CST
		,coalesce(msddetail.P_MSD_BEN_T2_460_CST, 0.00) as P_MSD_BEN_T2_460_CST
		,coalesce(msddetail.P_MSD_BEN_T2_471_CST, 0.00) as P_MSD_BEN_T2_471_CST
		,coalesce(msddetail.P_MSD_BEN_T2_500_CST, 0.00) as P_MSD_BEN_T2_500_CST
		,coalesce(msddetail.P_MSD_BEN_T2_833_CST, 0.00) as P_MSD_BEN_T2_833_CST
		,coalesce(msddetail.P_MSD_BEN_T2_835_CST, 0.00) as P_MSD_BEN_T2_835_CST
		,coalesce(msddetail.P_MSD_BEN_T2_838_CST, 0.00) as P_MSD_BEN_T2_838_CST
		,coalesce(creddetail.P_INC_INC_INC_emstpm_CST, 0.00) as P_INC_INC_INC_emstpm_CST
		,coalesce(creddetail.P_INC_INC_INC_fdrtpi_CST, 0.00) as P_INC_INC_INC_fdrtpi_CST
		,coalesce(creddetail.P_INC_INC_INC_frdtir_CST, 0.00) as P_INC_INC_INC_frdtir_CST
		,coalesce(creddetail.P_INC_INC_INC_frdtwi_CST, 0.00) as P_INC_INC_INC_frdtwi_CST
		,coalesce(irddetail.P_IRD_PYE_BEN_CST, 0.00) as P_IRD_PYE_BEN_CST  /*Specific components of tax for the year*/
		,coalesce(irddetail.P_IRD_PYE_CLM_CST, 0.00) as P_IRD_PYE_CLM_CST
		,coalesce(irddetail.P_IRD_PYE_PEN_CST, 0.00) as P_IRD_PYE_PEN_CST
		,coalesce(irddetail.P_IRD_PYE_PPL_CST, 0.00) as P_IRD_PYE_PPL_CST
		,coalesce(irddetail.P_IRD_PYE_STU_CST, 0.00) as P_IRD_PYE_STU_CST
		,coalesce(irddetail.P_IRD_PYE_WAS_CST, 0.00) as P_IRD_PYE_WAS_CST
		,coalesce(irddetail.P_IRD_WHT_WHP_CST, 0.00) as P_IRD_WHT_WHP_CST
		,ter.P_TER_DUR
		,case when ter.snz_uid is null then 0 else 1 end as P_TER_ind
		,case when cor.snz_uid is null then 0 else 1 end as P_COR_ind
		,accom_b4.value as accom_sup_1mnth_b4_intvw
		,accom_af.value as accom_sup_1mnth_af_intvw
	from 
	sand.&si_pop_table_out. ind
	left join MOH_pharm_events_rlpw pharm on (ind.snz_uid = pharm.snz_uid)
	left join MOH_pfhd_events_rlpw pfhd on (ind.snz_uid = pfhd.snz_uid)
	left join MSD_t1_events_rlpw t1 on (ind.snz_uid = t1.snz_uid)
	left join MOE_tertiary_events_rlpw ter on (ind.snz_uid = ter.snz_uid)
	left join COR_sentence_events_rlpw cor on (ind.snz_uid = cor.snz_uid)

	/* Gross Income in the month of interview*/
	left join (select snz_uid, sum(value) as inc_intvwmnth from 
				(	select * from IRD_income_events_30d_rlpl 
					where 
						(vartype like 'P_IRD_EMP%CST' 
							or vartype like 'P_IRD_INS%CST'
							or vartype like 'P_IRD_STS%CST'
							or vartype like 'P_IRD_RNT%CST')
						and vartype not in ('P_IRD_INS_FTCb_CST','P_IRD_INS_FTCn_CST') /*Exclude Family Tax credits as it is accounted from external source*/
					union all 
					select * from MSD_t2_events_30d_rlpl 
					where vartype like 'P_MSD_%' 
						and vartype not like 'P_MSD_BEN_T2_064_CST' /*Exclude Family Tax credits as it is accounted  from external source*/
					union all 
					select * from ALT_taxcred_events_30d_rlpl where vartype like 'P_INC_%' /*Tax credits, from IR3, PTS, FRD and FDR combined*/
				)
				group by snz_uid) ird on (ind.snz_uid = ird.snz_uid)

	/* Gross PAYE income for individual from month of interview*/
	left join (select snz_uid, sum(value) as incpaye_intvwmnth from 
				(	select * from IRD_income_events_30d_rlpl 
					where vartype = 'P_IRD_EMP_WAS_CST' )
				group by snz_uid) paye on (ind.snz_uid = paye.snz_uid)

	/* Yearly Net Income : For David's request dated 28 May 2018, tax credits edited 07 August 2018*/
	left join (select 
					snz_uid, sum(value)/12.0 as income_monthly_net
				from 
					(/*Exclude Student Loans & tax credit components, add in the tax components and withheld payments*/
					select * from IRD_income_events_1yr_rlpl where vartype not like 'P_IRD_STL%' and vartype like 'P_IRD_%' 
						and vartype not in ('P_IRD_INS_FTCb_CST','P_IRD_INS_FTCn_CST')
					union all 
					/*Exclude Family Tax credits as it is accounted from IRD table*/
					select * from MSD_t2_events_1yr_rlpl where vartype like 'P_MSD_%' and vartype not like 'P_MSD_BEN_T2_064_CST'
					union all 
					/*Add in Family Tax credits*/
					select * from ALT_taxcred_events_1yr_rlpl where vartype like 'P_INC_%' )x
				group by snz_uid) yearlynet on (ind.snz_uid = yearlynet.snz_uid)

	/* Comparison measure for yearly net income: Based on David's request dated 07 August 2018*/
	left join (select 
					snz_uid
					,sum(value)/12.0 as income_monthly_net_comp
				from ALT_income_events_1yr_rlpl 
				where vartype like 'P_INC_%'
				group by snz_uid
				) yearlynetalt on (ind.snz_uid = yearlynetalt.snz_uid)
	/* Income broken down into components*/
	left join (select * from IRD_income_events_1yr_rlpw) irddetail 
		on (ind.snz_uid = irddetail.snz_uid)
	left join (select * from MSD_t2_events_1yr_rlpw) msddetail 
		on (ind.snz_uid = msddetail.snz_uid)
	left join (select * from ALT_taxcred_events_1yr_rlpw ) creddetail 
		on (ind.snz_uid = creddetail.snz_uid)


	left join (select * from MSD_t2_events_30d_rlpl where vartype = 'P_MSD_BEN_T2_471_CST') accom_b4 
		on (ind.snz_uid = accom_b4.snz_uid)
	left join (select * from MSD_t2_events_30d_rlpl where vartype = 'F_MSD_BEN_T2_471_CST') accom_af 
		on (ind.snz_uid = accom_af.snz_uid);

quit;

/*proc sql;*/
/*create table temp45 as */
/*select  income_monthly_net, income_monthly_net_comp, abs(income_monthly_net - income_monthly_net_comp)  as diff from _temp_adminvars;*/
/*quit;*/
/*proc univariate data=temp45; var income_monthly_net income_monthly_net_comp;*/
/*run;*/
/**/
/**/
/*proc corr data=temp45 ;*/
/*var income_monthly_net income_monthly_net_comp;*/
/*run;*/
/**/
/*proc reg data=temp45 ;*/
/*model income_monthly_net_comp = income_monthly_net;*/
/*run;*/


/* Replace NULLs in admin variables with 0 */
proc stdize data=_temp_adminvars out=_temp_adminvars reponly missing=0;run;

/* Add in the admin variables into the "si_pop_table_out" table and write to database*/
proc sql;

	create table _temp_adminvars as 
	select 
		ind.*
		,temp.*
	from 
	sand.&si_pop_table_out. ind
	left join _temp_adminvars temp on (ind.snz_uid = temp.snz_uid);

quit;

%si_write_to_db(si_write_table_in=work._temp_adminvars,
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out.
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/*Delete temp*/
proc datasets lib=work;
	delete _temp_: ;
run;

