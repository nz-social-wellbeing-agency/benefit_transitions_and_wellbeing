/*********************************************************************************************************
DESCRIPTION: Script that creates variables based on transition dates for the individuals

INPUT:	
	[IDI_Sandpit].[&si_proj_schema.].[of_mhaet_population]

OUTPUT:	
	&si_sandpit_libname..of_mhaet_pop_ben2emp
	&si_sandpit_libname..of_mhaet_pop_emp2ben

DEPENDENCIES:
	SI Data Foundation macros must be loaded into memory.

NOTES: 

HISTORY: 
	10 Apr 2018		VB,BV	First version.
	11 Oct 2018		VB		Created a macro (assuming symmetricity between BEN2EMp and EMP2BEN 
							transitions)
*********************************************************************************************************/

/* This macro selectively creates the analysis population as required (ben2emp or emp2ben transitions)*/

%macro create_analysis_pop(analysis_pop = ben2emp, interval_flag = );


	%if &analysis_pop. = ben2emp %then %do;
		
		%put &analysis_pop.;

		/* Define the BEFORE and AFTER groups for BEN to EMP transitions*/
		proc sql;
			connect to odbc (dsn=&si_idi_dsnname.);

			create table work.mhaet_population_&analysis_pop. as
				select 
					*
				from connection to odbc(
					/* BEN to EMP tansitions*/
					select 
						mhaet.* 
						,c.days_to_backben as days_to_backben_12month /* days from the transition to the next ben spell within 12 month */
/*						,gss.**/

					from 
					(	select *
							,datediff(dd, state1_to_state2_trans_date, gss_pq_interview_date) as days_to_intvw_date /* Days from transition from BEN to EMP*/
							,case when gss_pq_interview_date between state1_start_date and state1_to_state2_trans_date then 'CONTROL'
								else 'TREAT' end as treat_control_ind
						from [IDI_Sandpit].[&si_proj_schema.].[of_mhaet_population]
						where &interval_flag. = 1 and transitions_ind = 1				
					) mhaet
					/* back in benefit 12-month after the transition ? */
					left join 
					(	select 
							r.snz_uid
							,min(r.start_date) as min_start_date
							,m.state1_to_state2_trans_date 
							,min(datediff(dd, m.state1_to_state2_trans_date, r.start_date)) as days_to_backben
						from [IDI_Sandpit].[&si_proj_schema.].[of_comb_spells_rule2] r
						inner join [IDI_Sandpit].[&si_proj_schema.].[of_mhaet_population] m
							on m.snz_uid=r.snz_uid and m.transitions_ind = 1
						where r.state='BEN' 
							and datediff(dd, m.state1_to_state2_trans_date, r.start_date) between 0 and 365
						group by r.snz_uid, m.state1_to_state2_trans_date
					) c on (mhaet.snz_uid = c.snz_uid and mhaet.state1_to_state2_trans_date=c.state1_to_state2_trans_date)
				);

			disconnect from odbc;
		quit;
	%end;
	%else %do;
		%put &analysis_pop.;

		/* Define the BEFORE and AFTER groups for EMP to BEN transitions*/
		proc sql;
			connect to odbc (dsn=&si_idi_dsnname.);

			create table work.mhaet_population_&analysis_pop. as
				select 
					*
				from connection to odbc(
					/* EMP to BEN tansitions*/
					select 
						mhaet.* 
					from 
					(	select *
							,datediff(dd, state1_to_state2_trans_date, gss_pq_interview_date) as days_to_intvw_date /* Days from transition from BEN to EMP*/
							,case when gss_pq_interview_date between state1_start_date and state1_to_state2_trans_date then 'CONTROL'
								else 'TREAT' end as treat_control_ind
						from [IDI_Sandpit].[&si_proj_schema.].[of_mhaet_population]
						where &interval_flag. = 1 and transitions_ind = 2				
					) mhaet
				);

			disconnect from odbc;
		quit;

	%end;

		%si_write_to_db(si_write_table_in=work.mhaet_population_&analysis_pop.,
			si_write_table_out=&si_sandpit_libname..of_mhaet_pop_&analysis_pop.
			,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
			);


		/************************************** Transistion date-based variables ************************************************/

		
		/* Get 6-month total income for the transitions group before and after their transition*/
		%si_align_sialevents_to_periods(
					si_table_in=[IDI_Sandpit].[&si_proj_schema.].of_mhaet_pop_&analysis_pop.,
					si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_IRD_income_events , 						
					si_id_col = &si_id_col. , 
					si_as_at_date = state1_to_state2_trans_date ,
					si_amount_type = &si_amount_type. , 
					si_amount_col = &si_sial_amount_col. ,  
					noofperiodsbefore = -1 , 
					noofperiodsafter = 1 , 
					period_duration = Halfyear , 
					si_out_table = IRD_income_events_aln,
					period_aligned_to_calendar = False, 
					si_pi_type = &si_price_index_type. , 
					si_pi_qtr = &si_price_index_qtr. );
		%si_create_rollup_vars(
			si_table_in = sand.of_mhaet_pop_&analysis_pop., 
			si_sial_table = IRD_income_events_aln,	
			si_out_table = IRD_income_events_rlp,	
			si_agg_cols= %str(department datamart subject_area),	
			si_id_col = &si_id_col. ,
			si_as_at_date = state1_to_state2_trans_date ,
			si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
			cost = True, 
			duration = True, 
			count = False, 
			count_startdate = False, 
			dayssince = False,
			si_rollup_ouput_type = Long
		);

		/* Get 6-month total T2 benefits for the transitions group before and after their transition*/
		%si_align_sialevents_to_periods(
					si_table_in=[IDI_Sandpit].[&si_proj_schema.].of_mhaet_pop_&analysis_pop.,
					si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MSD_t2_events , 						
					si_id_col = &si_id_col. , 
					si_as_at_date = state1_to_state2_trans_date ,
					si_amount_type = &si_amount_type. , 
					si_amount_col = &si_sial_amount_col. ,  
					noofperiodsbefore = -1 , 
					noofperiodsafter = 1 , 
					period_duration = Halfyear , 
					si_out_table = MSD_t2_events_aln,
					period_aligned_to_calendar = False, 
					si_pi_type = &si_price_index_type. , 
					si_pi_qtr = &si_price_index_qtr. );
		%si_create_rollup_vars(
			si_table_in = sand.of_mhaet_pop_&analysis_pop., 
			si_sial_table = MSD_t2_events_aln,	
			si_out_table = MSD_t2_events_rlp,	
			si_agg_cols= %str(department datamart subject_area event_type),	
			si_id_col = &si_id_col. ,
			si_as_at_date = state1_to_state2_trans_date ,
			si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
			cost = True, 
			duration = False, 
			count = False, 
			count_startdate = False, 
			dayssince = False,
			si_rollup_ouput_type = Long
		);

		/* Get 6-month income for the transitions group from tax credits before and after transition*/
		%si_align_sialevents_to_periods(
					si_table_in=[IDI_Sandpit].[&si_proj_schema.].of_mhaet_pop_&analysis_pop.,
					si_sial_table=[IDI_Sandpit].[&si_proj_schema.].of_gss_admin_taxcreds , 						
					si_id_col = &si_id_col. , 
					si_as_at_date = state1_to_state2_trans_date ,
					si_amount_type = &si_amount_type. , 
					si_amount_col = &si_sial_amount_col. ,  
					noofperiodsbefore = -1 , 
					noofperiodsafter = 1 , 
					period_duration = Halfyear , 
					si_out_table = ALT_taxcred_events_aln,
					period_aligned_to_calendar = False, 
					si_pi_type = &si_price_index_type. , 
					si_pi_qtr = &si_price_index_qtr. );
		%si_create_rollup_vars(
			si_table_in = sand.of_mhaet_pop_&analysis_pop., 
			si_sial_table = ALT_taxcred_events_aln,	
			si_out_table = ALT_taxcred_events_rlp,	
			si_agg_cols= %str(department datamart subject_area),	
			si_id_col = &si_id_col. ,
			si_as_at_date = state1_to_state2_trans_date ,
			si_amount_col = &si_sial_amount_col._&si_price_index_type._&si_price_index_qtr. ,
			cost = True, 
			duration = False, 
			count = False, 
			count_startdate = False, 
			dayssince = False,
			si_rollup_ouput_type = Long
		);

		/* Get 6-month total duration spent on T1 benefits for the transitions group before and after transition*/
		%si_align_sialevents_to_periods(
					si_table_in=[IDI_Sandpit].[&si_proj_schema.].of_mhaet_pop_&analysis_pop.,
					si_sial_table=[IDI_Sandpit].[&si_proj_schema.].SIAL_MSD_t1_events , 						
					si_id_col = &si_id_col. , 
					si_as_at_date = state1_to_state2_trans_date ,
					si_amount_type = &si_amount_type. , 
					si_amount_col = &si_sial_amount_col. ,  
					noofperiodsbefore = -1 , 
					noofperiodsafter = 1 , 
					period_duration = Halfyear , 
					si_out_table = MSD_t1_events_aln,
					period_aligned_to_calendar = False, 
					si_pi_type = &si_price_index_type. , 
					si_pi_qtr = &si_price_index_qtr. );
		%si_create_rollup_vars(
			si_table_in = sand.of_mhaet_pop_&analysis_pop., 
			si_sial_table = MSD_t1_events_aln,	
			si_out_table = MSD_t1_events_rlp,	
			si_agg_cols= %str(department datamart subject_area event_type_4),	
			si_id_col = &si_id_col. ,
			si_as_at_date = state1_to_state2_trans_date ,
			si_amount_col = NA ,
			cost = False, 
			duration = True, 
			count = False, 
			count_startdate = False, 
			dayssince = False,
			si_rollup_ouput_type = Long
		);



		/* Total 6-month gross income for transitions group before and after transition.
			The components that go into the income calculation are:
			P_IRD_EMP_C00_CST
			P_IRD_EMP_C01_CST
			P_IRD_EMP_P00_CST
			P_IRD_EMP_PPL_CST
			P_IRD_EMP_S00_CST
			P_IRD_EMP_S02_CST
			P_IRD_EMP_WAS_CST
			P_IRD_INS_BEN_CST
			P_IRD_INS_CLM_CST
			P_IRD_INS_FTCb_CST
			P_IRD_INS_FTCn_CST
			P_IRD_INS_PEN_CST
			P_IRD_STS_STU_CST
			P_MSD_BEN_T2_065_CST
			P_MSD_BEN_T2_344_CST
			P_MSD_BEN_T2_425_CST
			P_MSD_BEN_T2_450_CST
			P_MSD_BEN_T2_460_CST
			P_MSD_BEN_T2_471_CST
			P_MSD_BEN_T2_500_CST
			P_MSD_BEN_T2_833_CST
			P_MSD_BEN_T2_835_CST
		*/
		proc sql;
			create table _temp_IRD_income_events_rlp as 
				select coalesce(incb4.snz_uid,incaf.snz_uid, t1b4.snz_uid, t1af.snz_uid, pyeb4.snz_uid, pyeaf.snz_uid
								, accomb4.snz_uid, accomaf.snz_uid) as snz_uid, 
					   coalesce(incb4.tot_inc_6mnth_b4,0) as tot_inc_6mnth_b4,	
					   coalesce(incaf.tot_inc_6mnth_af,0) as tot_inc_6mnth_af,
					   coalesce(pyeb4.tot_ird_pye_was_dur_b4,0) as tot_ird_pye_was_dur_b4,	
					   coalesce(pyeaf.tot_ird_pye_was_dur_af,0) as tot_ird_pye_was_dur_af,
					   coalesce(accomb4.value, 0.00) as accomsup_6mnth_b4trans,
					   coalesce(accomaf.value, 0.00) as accomsup_6mnth_aftrans,
					   coalesce(t1b4.dur_benIB_6mnth_b4,0) as dur_benIB_6mnth_b4,
					   coalesce(t1b4.dur_benOther_6mnth_b4,0) as dur_benOther_6mnth_b4,
					   coalesce(t1b4.dur_benSB_6mnth_b4,0) as dur_benSB_6mnth_b4,
					   coalesce(t1b4.dur_benUB_6mnth_b4,0) as dur_benUB_6mnth_b4,
					   coalesce(t1b4.dur_benDPB_6mnth_b4,0) as dur_benDPB_6mnth_b4,
					   coalesce(t1b4.dur_benIB_6mnth_b4,0) + coalesce(t1b4.dur_benOther_6mnth_b4,0) + coalesce(t1b4.dur_benSB_6mnth_b4,0) +
					   coalesce(t1b4.dur_benUB_6mnth_b4,0) + coalesce(t1b4.dur_benDPB_6mnth_b4,0) as dur_benany_6mnth_b4,
					   coalesce(t1af.dur_benIB_6mnth_af,0) as dur_benIB_6mnth_af,
					   coalesce(t1af.dur_benOther_6mnth_af,0) as dur_benOther_6mnth_af,
					   coalesce(t1af.dur_benSB_6mnth_af,0) as dur_benSB_6mnth_af,
					   coalesce(t1af.dur_benUB_6mnth_af,0) as dur_benUB_6mnth_af,
					   coalesce(t1af.dur_benDPB_6mnth_af,0) as dur_benDPB_6mnth_af,
					   coalesce(t1af.dur_benIB_6mnth_af,0) + coalesce(t1af.dur_benOther_6mnth_af,0) + coalesce(t1af.dur_benSB_6mnth_af,0) +
					   coalesce(t1af.dur_benUB_6mnth_af,0) + coalesce(t1af.dur_benDPB_6mnth_af,0) as dur_benany_6mnth_af			 
				from
					/* Total Income in the 6 months before the transition */
					(select snz_uid, sum(value) as tot_inc_6mnth_b4 from 
						(	select * from IRD_income_events_rlpl 
							where 
								(vartype like 'P_IRD_EMP%CST' 
									or vartype like 'P_IRD_INS%CST'
									or vartype like 'P_IRD_STS%CST'
									or vartype like 'P_IRD_RNT%CST')
								and vartype not in ('P_IRD_INS_FTCb_CST','P_IRD_INS_FTCn_CST') /*Exclude Family Tax credits as it is accounted from external source*/
							union all 
							select * from MSD_t2_events_rlpl 
							where vartype like 'P_MSD_%' 
								and vartype not like 'P_MSD_BEN_T2_064_CST' /*Exclude Family Tax credits as it is accounted  from external source*/
							union all 
							select * from ALT_taxcred_events_rlpl where vartype like 'P_INC_%' /*Tax credits, from IR3, PTS, FRD and FDR combined*/
						)
					group by snz_uid) incb4

				full join  
					/* Total Income in the 6 months after the transition */
					(select snz_uid, sum(value) as tot_inc_6mnth_af from 
						(	select * from IRD_income_events_rlpl 
							where 
								(vartype like 'F_IRD_EMP%CST' 
									or vartype like 'F_IRD_INS%CST'
									or vartype like 'F_IRD_STS%CST'
									or vartype like 'F_IRD_RNT%CST')
								and vartype not in ('F_IRD_INS_FTCb_CST','F_IRD_INS_FTCn_CST') /*Exclude Family Tax credits as it is accounted from external source*/
							union all 
							select * from MSD_t2_events_rlpl 
							where vartype like 'F_MSD_%' 
								and vartype not like 'F_MSD_BEN_T2_064_CST' /*Exclude Family Tax credits as it is accounted  from external source*/
							union all 
							select * from ALT_taxcred_events_rlpl where vartype like 'F_INC_%' /*Tax credits, from IR3, PTS, FRD and FDR combined*/
						)
					group by snz_uid) incaf
				on incb4.snz_uid=incaf.snz_uid

				/* Total Accomodation supplement 6 months before transition*/
				full join (select * from MSD_t2_events_rlpl where vartype = 'P_MSD_BEN_T2_471_CST') accomb4
					on (incb4.snz_uid = accomb4.snz_uid)
				/* Total Accomodation supplement 6 months after transition*/
				full join (select * from MSD_t2_events_rlpl where vartype = 'F_MSD_BEN_T2_471_CST') accomaf
					on (incb4.snz_uid = accomaf.snz_uid)

				full join  
				/* Main Benefit Benefit durations in the 6 months before transition*/
					(select snz_uid 
							,sum(valueDPB) as dur_benDPB_6mnth_b4
							,sum(valueIB) as dur_benIB_6mnth_b4
							,sum(valueOther) as dur_benOther_6mnth_b4
							,sum(valueSB) as dur_benSB_6mnth_b4
							,sum(valueUB) as dur_benUB_6mnth_b4	
					from 
						/* The high-level classifications for benefit types below are derived from discussions with
							David Rea(MSD)*/
						(	select *, 
								case when vartype in ("P_MSD_BEN_T1_SupportedLivingPaymentsCarers_DUR",
													  "P_MSD_BEN_T1_Invalid'sBenefit_DUR",
													  'P_MSD_BEN_T1_SupportedLivingPaymentsHealthCondition&Disability_DUR',
													  "P_MSD_BEN_T1_SupportedLivingPaymentOverseas_DUR")
										then value else 0 end as valueIB,
								case when vartype in ("P_MSD_BEN_T1_EmergencyUnemploymentBenefit_DUR",
													"P_MSD_BEN_T1_JobSeekerWorkReady_DUR",
													"P_MSD_BEN_T1_JobSeekerWorkReadyHardship_DUR",
													"P_MSD_BEN_T1_JobSeekerWorkReadyTraining_DUR",
													"P_MSD_BEN_T1_UnemploymentBenefit(Training)_DUR",
													"P_MSD_BEN_T1_CommunityWageEmergencyJobSeeker_DUR",
													"P_MSD_BEN_T1_CommunityWageJobSeekers_DUR",
													"P_MSD_BEN_T1_CommunityWageTrainingBenefit_DUR",
													"P_MSD_BEN_T1_JobSearchAllowance_DUR",
													"P_MSD_BEN_T1_JobSeekerWorkReadyTrainingHardship_DUR",
													"P_MSD_BEN_T1_TrainingBenefit_DUR",
													"P_MSD_BEN_T1_UnemploymentBenefit_DUR",
													"P_MSD_BEN_T1_UnemploymentBenefitHardship_DUR",
													"P_MSD_BEN_T1_EmergencyUnemploymentStudent_DUR",
													"P_MSD_BEN_T1_JobSeekerStudentHardship_DUR",
													"P_MSD_BEN_T1_CommunityWageEmergencyStudent_DUR",
													"P_MSD_BEN_T1_UnemploymentBenefitStudentHardship_DUR")
										then value else 0 end as valueUB,
								case when vartype in ("P_MSD_BEN_T1_DPBCaringforSickorInfirm_DUR",
													"P_MSD_BEN_T1_EmergencyMaintenanceAllowance_DUR",
													"P_MSD_BEN_T1_SoleParentSupportOverseas_DUR",
													"P_MSD_BEN_T1_DPBSoleParent_DUR",
													"P_MSD_BEN_T1_SoleParentSupport_DUR",)
										then value else 0 end as valueDPB,
								case when vartype in ("P_MSD_BEN_T1_CommunityWageSicknessBenefit_DUR",
													'P_MSD_BEN_T1_JobSeekerHealthCondition&Disability_DUR',
													'P_MSD_BEN_T1_JobSeekerHealthCondition&DisabilityHardship_DUR',
													"P_MSD_BEN_T1_SicknessBenefit_DUR")
										then value else 0 end as valueSB,
								case when vartype in ("P_MSD_BEN_T1_EmergencyBenefit_DUR",
													"P_MSD_BEN_T1_TransitionalRetirementBenefit_DUR",
													"P_MSD_BEN_T1_Widow'sBenefit_DUR",
													"P_MSD_BEN_T1_DPBWomanAlone_DUR",
													"P_MSD_BEN_T1_YoungParentPayment_DUR",
													"P_MSD_BEN_T1_IndependentYouthBenefit_DUR",
													"P_MSD_BEN_T1_YouthPayment_DUR")
										then value else 0 end as valueOther
							from MSD_t1_events_rlpl 
						)
					group by snz_uid) t1b4
				on incb4.snz_uid=t1b4.snz_uid


				full join  

				/* Main Benefit Benefit durations in the 6 months before transition*/
				(select snz_uid 
						,sum(valueDPB) as dur_benDPB_6mnth_af
						,sum(valueIB) as dur_benIB_6mnth_af
						,sum(valueOther) as dur_benOther_6mnth_af
						,sum(valueSB) as dur_benSB_6mnth_af
						,sum(valueUB) as dur_benUB_6mnth_af	
				from 
				(	select *, 
						case when vartype in ("F_MSD_BEN_T1_SupportedLivingPaymentsCarers_DUR",
											  "F_MSD_BEN_T1_Invalid'sBenefit_DUR",
											  'F_MSD_BEN_T1_SupportedLivingPaymentsHealthCondition&Disability_DUR',
											  "F_MSD_BEN_T1_SupportedLivingPaymentOverseas_DUR")
								then value else 0 end as valueIB,
						case when vartype in ("F_MSD_BEN_T1_EmergencyUnemploymentBenefit_DUR",
											"F_MSD_BEN_T1_JobSeekerWorkReady_DUR",
											"F_MSD_BEN_T1_JobSeekerWorkReadyHardship_DUR",
											"F_MSD_BEN_T1_JobSeekerWorkReadyTraining_DUR",
											"F_MSD_BEN_T1_UnemploymentBenefit(Training)_DUR",
											"F_MSD_BEN_T1_CommunityWageEmergencyJobSeeker_DUR",
											"F_MSD_BEN_T1_CommunityWageJobSeekers_DUR",
											"F_MSD_BEN_T1_CommunityWageTrainingBenefit_DUR",
											"F_MSD_BEN_T1_JobSearchAllowance_DUR",
											"F_MSD_BEN_T1_JobSeekerWorkReadyTrainingHardship_DUR",
											"F_MSD_BEN_T1_TrainingBenefit_DUR",
											"F_MSD_BEN_T1_UnemploymentBenefit_DUR",
											"F_MSD_BEN_T1_UnemploymentBenefitHardship_DUR",
											"F_MSD_BEN_T1_EmergencyUnemploymentStudent_DUR",
											"F_MSD_BEN_T1_JobSeekerStudentHardship_DUR",
											"F_MSD_BEN_T1_CommunityWageEmergencyStudent_DUR",
											"F_MSD_BEN_T1_UnemploymentBenefitStudentHardship_DUR")
								then value else 0 end as valueUB,
						case when vartype in ("F_MSD_BEN_T1_DPBCaringforSickorInfirm_DUR",
											"F_MSD_BEN_T1_EmergencyMaintenanceAllowance_DUR",
											"F_MSD_BEN_T1_SoleParentSupportOverseas_DUR",
											"F_MSD_BEN_T1_DPBSoleParent_DUR",
											"F_MSD_BEN_T1_SoleParentSupport_DUR",)
								then value else 0 end as valueDPB,
						case when vartype in ("F_MSD_BEN_T1_CommunityWageSicknessBenefit_DUR",
											'F_MSD_BEN_T1_JobSeekerHealthCondition&Disability_DUR',
											'F_MSD_BEN_T1_JobSeekerHealthCondition&DisabilityHardship_DUR',
											"F_MSD_BEN_T1_SicknessBenefit_DUR")
								then value else 0 end as valueSB,
						case when vartype in ("F_MSD_BEN_T1_EmergencyBenefit_DUR",
											"F_MSD_BEN_T1_TransitionalRetirementBenefit_DUR",
											"F_MSD_BEN_T1_Widow'sBenefit_DUR",
											"F_MSD_BEN_T1_DPBWomanAlone_DUR",
											"F_MSD_BEN_T1_YoungParentPayment_DUR",
											"F_MSD_BEN_T1_IndependentYouthBenefit_DUR",
											"F_MSD_BEN_T1_YouthPayment_DUR")
								then value else 0 end as valueOther
					from MSD_t1_events_rlpl 
				)
				group by snz_uid) t1af
				on incb4.snz_uid=t1af.snz_uid

				/* PAYE durations (from W&S) before transition */
				full join (
					select snz_uid
						,value as tot_ird_pye_was_dur_b4
					from IRD_income_events_rlpl 
					where vartype = "P_IRD_PYE_WAS_DUR"
				) pyeb4 on (incb4.snz_uid = pyeb4.snz_uid)

				/* PAYE durations (from W&S) after transition */
				full join (
					select snz_uid
						,value as tot_ird_pye_was_dur_af
					from IRD_income_events_rlpl 
					where vartype = "F_IRD_PYE_WAS_DUR"
				) pyeaf on (incb4.snz_uid = pyeaf.snz_uid);

		quit;

		/* Create a temp table with all variables before writing it to the DB*/
		proc sql;

			create table _temp_&interval_flag._&analysis_pop. as 
				select 
					&analysis_pop..*
					,inc.*
					,"&interval_flag." as interval_flag
				from sand.of_mhaet_pop_&analysis_pop. &analysis_pop.
				left join _temp_IRD_income_events_rlp inc on (&analysis_pop..snz_uid = inc.snz_uid);

		quit;

		


%mend;


/* Create the Benefit to Employment transitions analysis population*/
proc sql;drop table work.transition_ben2emp; quit;
%create_analysis_pop(analysis_pop=ben2emp, interval_flag = intvw_180_xsect);
%si_perform_unionall(si_table_in=transition_ben2emp, append_table=_temp_intvw_180_xsect_ben2emp);
%create_analysis_pop(analysis_pop=ben2emp, interval_flag = intvw_150_xsect);
%si_perform_unionall(si_table_in=transition_ben2emp, append_table=_temp_intvw_150_xsect_ben2emp);
%create_analysis_pop(analysis_pop=ben2emp, interval_flag = intvw_120_xsect);
%si_perform_unionall(si_table_in=transition_ben2emp, append_table=_temp_intvw_120_xsect_ben2emp);
%create_analysis_pop(analysis_pop=ben2emp, interval_flag = intvw_90_xsect);
%si_perform_unionall(si_table_in=transition_ben2emp, append_table=_temp_intvw_90_xsect_ben2emp);
%create_analysis_pop(analysis_pop=ben2emp, interval_flag = intvw_60_xsect);
%si_perform_unionall(si_table_in=transition_ben2emp, append_table=_temp_intvw_60_xsect_ben2emp);

/* Write final BEN to EMP table to database*/
%si_write_to_db(si_write_table_in=work.transition_ben2emp,
	si_write_table_out=&si_sandpit_libname..of_mhaet_pop_ben2emp
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/* Create the Employment to Benefit transitions analysis population*/
proc sql;drop table work.transition_emp2ben; quit;
%create_analysis_pop(analysis_pop=emp2ben, interval_flag = intvw_180_xsect);
%si_perform_unionall(si_table_in=transition_emp2ben, append_table=_temp_intvw_180_xsect_emp2ben);
%create_analysis_pop(analysis_pop=emp2ben, interval_flag = intvw_150_xsect);
%si_perform_unionall(si_table_in=transition_emp2ben, append_table=_temp_intvw_150_xsect_emp2ben);
%create_analysis_pop(analysis_pop=emp2ben, interval_flag = intvw_120_xsect);
%si_perform_unionall(si_table_in=transition_emp2ben, append_table=_temp_intvw_120_xsect_emp2ben);
%create_analysis_pop(analysis_pop=emp2ben, interval_flag = intvw_90_xsect);
%si_perform_unionall(si_table_in=transition_emp2ben, append_table=_temp_intvw_90_xsect_emp2ben);
%create_analysis_pop(analysis_pop=emp2ben, interval_flag = intvw_60_xsect);
%si_perform_unionall(si_table_in=transition_emp2ben, append_table=_temp_intvw_60_xsect_emp2ben);

/* Write final EMP to BEN table to database*/
%si_write_to_db(si_write_table_in=work.transition_emp2ben,
	si_write_table_out=&si_sandpit_libname..of_mhaet_pop_emp2ben
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/*Delete temp*/
proc datasets lib=work;
	delete _temp_: ;
run;

