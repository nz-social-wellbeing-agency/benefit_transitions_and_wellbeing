/* Creates the Benefit to Employment transitions dataset with renamed columns*/

/*Define the interval : 60 90 120 150 180*/
%let interval_flag='intvw_150_xsect';


proc sql;
connect to odbc (dsn=&si_idi_dsnname.);
create table work.mhaet_population_ben2emp as
select * from connection to odbc (

SELECT pop.[snz_uid]
		,[snz_gss_hhld_uid]
		,[snz_spine_ind]
		,[gss_id_collection_code] as gss_wave
		,pop.[gss_pq_interview_date] as pq_interview_date
		,cast([gss_hq_interview_date] as datetime) as hq_interview_date	  
		,[gss_pq_dvage_code] as age	  
		,[gss_hq_sex_dev] as sex
		,[housing_status] as house_status
		,[gss_pq_HH_tenure_code] as house_tenure
		,[gss_pq_HH_crowd_code] as house_crowding
		,[gss_pq_house_mold_code] as house_mold
		,[gss_pq_house_cold_code] as house_cold
		,[gss_pq_house_condition_code] as house_condition
		,[housing_satisfaction] as house_satisfaction	  
		,[housing_sat_ind] as house_satisfaction_2lev
		,[house_brm] as house_nbr_bedrooms
		,[gss_pq_safe_night_pub_trans_code] as safety_pub_transport
		,pub_trpt_safety_ind as safety_pub_transport_2lev
		,[gss_pq_safe_night_hood_code] as safety_neighbourhood_night
		,[safety_ind] as safety_neighbourhood_night_2lev
		,[gss_pq_safe_day_hood_code] as safety_neighbourhood_day	  
		,[safety_day_ind] as safety_neighbourhood_day_2lev
		,[crime_exp_ind] as safety_crime_victim
		,[gss_pq_cult_identity_code] as culture_identity     
		,[cult_identity_ind] as culture_identity_2lev
		,[belong] as culture_belonging_nz     
		,[belong_2016] as culture_belonging_nz_2016 
		,[discrim_status] as culture_discrimination 
/*		,[phys_health_sf12_score] as health_sf12_physcial*/
/*		,[ment_health_sf12_score] as health_sf12_mental*/
		,[health_nzsf12_physical]
		,[health_nzsf12_mental]
		,[health_status]
		,[health_limit_activ]
		,[health_limit_stair]
		,[health_accomplish_phys]
		,[health_work_phys]
		,[health_accomplish_emo]
		,[health_work_emo]
		,[health_pain]
		,[health_calm]
		,[health_energy]
		,[health_depressed]
		,[health_social]	  
		,[P_MOH_PHA_PHA_CST] as health_pharm_cst_1year
		,[P_MOH_PFH_PFH_DUR] as health_hosp_cst_1year
		,[lbr_force_status] as emp_labour_status
		,[work_now_ind] as emp_job_last_7_days
		,[work_start_ind] as emp_job_start_4_weeks
		,[work_look_ind] as emp_job_look_last_4_weeks
		,[work_could_start] as emp_job_could_start_last_week
		,[work_hrs] as emp_total_hrs_worked
		,[work_jobs_no] as emp_nbr_of_jobs
		,[work_satisfaction] as emp_work_satisfaction
		,[work_ft_pt] as emp_fulltime_parttime
		,[gss_pq_highest_qual_dev] as know_highest_qual	  
		,[gss_oecd_quals] as know_highest_qual_4lev	  
		,[P_TER_DUR] as know_tertiary_dur_1year
		,life_satisfaction_ind as subj_life_satisfaction  
		,[purpose_sense] as subj_sense_of_purpose
		,[gss_pq_voting] as civic_voting
		,voting_ind
		,[generalised_trust] as civic_generalised_trust	  
		,[volunteer] as civic_volunteering
		,[trust_police] as civic_trust_police
		,[trust_education] as civic_trust_education
		,[trust_media] as civic_trust_media
		,[trust_courts] as civic_trust_courts
		,[trust_parliament] as civic_trust_parliament
		,[trust_health] as civic_trust_health
		,[gss_pq_time_lonely_code] as social_time_lonely	  
		,[time_lonely_ind] as social_time_lonely_3lev
		,hh_gss_income as income_household
		,[inc_intvwmnth_gross] as income_pq_intvw_mnth	  
		,[tot_inc_6mnth_b4] as income_6mnth_b4_trans
		,[tot_inc_6mnth_af] as income_6mnth_af_trans	  
		,accom_sup_1mnth_b4_intvw
		,accom_sup_1mnth_af_intvw
		,[tot_ird_pye_was_dur_b4] as income_6mnth_paye_dur_b4_trans
		,[tot_ird_pye_was_dur_af] as income_6mnth_paye_dur_af_trans
		,[dur_benIB_6mnth_b4] as income_6mnth_benIB_dur_b4_trans
		,[dur_benSB_6mnth_b4] as income_6mnth_benSB_dur_b4_trans
		,[dur_benUB_6mnth_b4] as income_6mnth_benUB_dur_b4_trans
		,[dur_benDPB_6mnth_b4] as income_6mnth_benDPB_dur_b4_trans	  
		,[dur_benOther_6mnth_b4] as income_6mnth_benOT_dur_b4_trans
		,dur_benany_6mnth_b4 as income_6mnth_benany_dur_b4_trans
		,[dur_benIB_6mnth_af] as income_6mnth_benIB_dur_af_trans
		,[dur_benSB_6mnth_af] as income_6mnth_benSB_dur_af_trans
		,[dur_benUB_6mnth_af] as income_6mnth_benUB_dur_af_trans
		,[dur_benDPB_6mnth_af] as income_6mnth_benDPB_dur_af_trans
		,[dur_benOther_6mnth_af] as income_6mnth_benOT_dur_af_trans  
		,dur_benany_6mnth_af as income_6mnth_benany_dur_af_trans  
		,accomsup_6mnth_b4trans
		,accomsup_6mnth_aftrans
		,[gss_pq_material_wellbeing_code] as econ_material_well_being_idx
		,[gss_pq_ELSIDV1] as econ_elsi_idx
		,gss_pq_cost_down_vege_code as econ_cost_down_vege
		,gss_pq_cost_down_dr_code as econ_cost_down_dr
		,gss_pq_cost_down_shop_code as econ_cost_down_shop
		,gss_pq_cost_down_hobby_code as econ_cost_down_hobby
		,gss_pq_cost_down_cold_code as econ_cost_down_cold
		,gss_pq_cost_down_appliance_code as econ_cost_down_appliance
		,gss_pq_buy_shoes_limit_code as econ_buy_shoes_limit
		,gss_pq_item_300_limit_code as econ_item_300_limit
		,gss_pq_not_pay_bills_time_code as econ_not_pay_bills_time
		,gss_pq_enough_inc_code as  econ_enough_income
		/*      ,[FIN_WELL] as econ_enough_income*/
		,[leisure_time]
		,enough_free_time
		,access_green_spaces
/*		,[gss_pq_eth_european_code] as ethnicity_european_9lev*/
/*		,[gss_pq_eth_maori_code] as ethnicity_maori_9lev*/
/*		,[gss_pq_eth_samoan_code] as ethnicity_samoan_9lev*/
/*		,[gss_pq_eth_cookisland_code] as ethnicity_cook_9lev*/
/*		,[gss_pq_eth_tongan_code] as ethnicity_tongan_9lev*/
/*		,[gss_pq_eth_nieuan_code] as ethnicity_nieuan_9lev*/
/*		,[gss_pq_eth_chinese_code] as ethnicity_chinese_9lev*/
/*		,[gss_pq_eth_indian_code] as ethnicity_indian_9lev*/
/*		,[eth_oth] as ethnicity_other_9lev*/
/*		,[eth_dk] as ethnicity_dk_9lev*/
/*		,[eth_ref] as ethnicity_refuse_9lev	  */
		,[P_EURO] as ethnicity_european_6lev
		,[P_MAORI] as ethnicity_maori_6lev	  
		,[P_PACIFIC] as ethnicity_pacific_6lev
		,[P_ASIAN] as ethnicity_asian_6lev
		,[P_MELAA] as ethnicity_melaa_6lev	  
		,[P_OTHER] as ethnicity_other_6lev
		,[gss_hq_regcouncil_dev] as region_18lev	  
		,[married] as social_marital_status	  
		,[fam_typem] as family_type	
		,[gss_hq_dep_child_dev] as family_dep_child
		,[family_nuclei_ct] as family_nuclei_count 
		,[nonfamily_nuclei_ct] as family_non_nuclei_count 
		,[P_COR_ind] as corr_ind_1year
		,[state1_start_date] as ben_start_date
		,[state1_to_state2_trans_date] as ben_to_emp_trans_date
		,[state2_start_date] as emp_start_date
		,[state2_end_date] as emp_end_date
		,[state1_duration] as ben_duration
/*		,ben_duration_trunc*/
		,[state2_duration] as emp_duration
/*		,emp_duration_trunc*/
		,intvw_xsect
		,days_to_intvw_date
/*	  ,[sequence_full] as sequence_events*/
/*      ,[sequence_b4] as sequence_events_b4*/
/*      ,[sequence_af] as sequence_events_af*/
/*      ,[state_3b4] as third_state_b4_intvw*/
/*      ,[days_3b4] as third_state_b4_intvw_dur*/
/*      ,[state_2b4] as second_state_b4_intvw*/
/*      ,[days_2b4] as second_state_b4_intvw_dur*/
/*      ,[state_1b4] as state_b4_intvw*/
/*      ,[days_1b4] as state_b4_intvw_dur*/
/*      ,[state_1af] as state_af_intvw*/
/*      ,[days_1af] as state_af_intvw_dur*/
/*      ,[state_2af] as second_state_af_intvw*/
/*      ,[days_2af] as second_state_af_intvw_dur*/
/*      ,[state_3af] as third_state_af_intvw*/
/*      ,[days_3af] as third_state_af_intvw_dur*/
/*      ,[crossover_spell_days] as transition_spell_days*/
/*      ,[BEN_to_EMP_b4]*/
/*      ,[BEN_to_EMP_af]*/
/*	  ,[EMP_to_BEN_b4]*/
/*      ,[EMP_to_BEN_af]*/
/*	  ,[ben_to_emp_trans_days] as days_to_transition_ben_to_emp*/
      ,[treat_control_ind]
/*	  ,case when [treat_control_ind] = 'CONTROL' then [crossover_spell_days] else */
/*			case when [state_2b4] = '(N)' then [days_2b4] + days_3b4*/
/*			else [days_2b4] end*/
/*		end as ben_duration*/
/*	  ,case when [treat_control_ind] = 'TREAT' then [crossover_spell_days] */
/*	   else */
/*			case when [state_2af] = '(N)' then [days_2af] + days_3af */
/*			else [days_2af] end*/
/*		end as emp_duration*/
  FROM [IDI_Sandpit].[DL-MAA2016-15].of_mhaet_pop_ben2emp pop
	left join [IDI_Sandpit].[DL-MAA2016-15].of_gss_ind_variables_mh ind on pop.snz_uid=ind.snz_uid
	where pop.interval_flag=&interval_flag.) 

;
disconnect from odbc;
quit;

