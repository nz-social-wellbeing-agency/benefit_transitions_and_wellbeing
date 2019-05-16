	

/*******************************************************************************************************************
Description:  A Clean Up of the final analysis dataset for the benefit to employment dataset

Input: [IDI_Sandpit].[DL-MAA2016-15].of_mhaet_pop_ben2emp

Output: Table of gss variables of interests only

Author: Wen jhe Lee

Issues: 

History (reverse order):
2018-03-06 WJ v1

*******************************************************************************************************************/

	

/* Delete temporary table if it exists */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[of_final_ben2emp]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[of_final_ben2emp];

						
						select *,
Case when region_6lev='11' THEN 'Auckland'
when region_6lev='12' THEN 'Wellington'
when region_6lev='13' THEN 'Northland Group (Northland, Bay of Plenty, Gisborne)'
when region_6lev='14' THEN 'Rest of North Island'
when region_6lev='15' THEN 'Canterbury '
when region_6lev='16' THEN 'Rest of South Island'
else 'Unknown' end as region_name
,case when sex=1 then 'Male' else 'Female' end as sex_name
,Case when emp_job_last_7_days='1' THEN 'Is Working'
when emp_job_last_7_days='2' THEN 'Not Working'
else 'DK,RF Other' end as emp_job_last_7_days
,Case when emp_job_start_4_weeks='1' THEN 'Start Work Soon'
when emp_job_start_4_weeks='2' THEN 'Not Working'
else 'DK,RF Other' end as emp_job_start_4_weeks
,Case when emp_job_look_last_4_weeks='1' THEN 'Looking For Work'
when emp_job_look_last_4_weeks='2' THEN 'Not Working'
else 'DK,RF Other' end as emp_job_look_last_4_weeks
,Case when emp_job_could_start_last_week='1' THEN 'Can Start Work'
when emp_job_could_start_last_week='2' THEN 'Cant Start Work'
else 'DK,RF Other' end as work_could_starts
,cast(age as smallint) as age_r
,Case when social_marital_status='1'or social_marital_status='01' THEN 'Partnered'
when social_marital_status='2' or social_marital_status='02' THEN 'Not Partnered'
else 'DK,RF Other' end as social_marital_status
,Case when health_status ='11' THEN 'Excellent'
when health_status ='12' THEN 'Very Good'
when health_status ='13' THEN 'Good'
when health_status ='14' THEN 'Fair'
when health_status ='15' THEN 'Poor'
else 'DK,RF Other' end as health_statusm
,Case when health_limit_activ in ('11','12') THEN 'Limited-various'
when health_limit_activ  in ('13') THEN 'No'
else 'DK,RF Other' end as health_limit_activm
,Case when health_limit_stair in ('11','12') THEN 'Limited-various'
when health_limit_stair  in ('13') THEN 'No'
else 'DK,RF Other' end as health_limit_stairm
,Case when health_accomplish_phys in ('11','12') THEN 'All - Most'
when health_accomplish_phys  in ('13','14') THEN 'Some - A Little'
when health_accomplish_phys  in ('15') THEN 'None'
else 'DK,RF Other' end as health_accomplish_physm
,Case when health_accomplish_emo in ('11','12') THEN 'All - Most'
when health_accomplish_emo  in ('13','14') THEN 'Some - A Little'
when health_accomplish_emo in ('15') THEN 'None'
else 'DK,RF Other' end as health_accomplish_emom
,Case when health_pain in ('14','15') THEN 'All - Most'
when health_pain  in ('12','13') THEN 'Some - A Little'
when health_pain in ('11') THEN 'No'
else 'DK,RF Other' end as health_painm
,Case when health_calm in ('11','12') THEN 'All - Most'
when health_calm   in ('13','14') THEN 'Some - A Little'
when health_calm  in ('15') THEN 'None'
else 'DK,RF Other' end as health_calmm
,Case when health_energy in ('11','12') THEN 'All - Most'
when health_energy   in ('13','14') THEN 'Some - A Little'
when health_energy  in ('15') THEN 'None'
else 'DK,RF Other' end as health_energym
,Case when health_depressed in ('11','12') THEN 'All - Most'
when health_depressed   in ('13','14') THEN 'Some - A Little'
when health_depressed  in ('15') THEN 'None'
else 'DK,RF Other' end as health_depressedm
,Case when health_social in ('11','12') THEN 'All - Most'
when health_social   in ('13','14') THEN 'Some - A Little'
when health_social in ('15') THEN 'None'
else 'DK,RF Other' end as health_socialm
,Case when family_type like '1%' THEN 'Couple without Children'
when family_type like '2%' THEN 'Couple with dependent child(ren)'
when family_type like '3%' THEN 'Single Parent with children'
when family_type like '4%' THEN 'Not in A Family Nucleus'
else 'Family type unidentifiable' end as fam_typemz
,Case when econ_enough_income= '11' THEN 'not enough money'
when econ_enough_income= '12' THEN 'only just enough money'
when econ_enough_income = '13' THEN 'enough money'
when econ_enough_income  = '14' THEN 'more than enough money'
else 'Unknown' end as fin_wellm
,Case when culture_identity= '11' THEN 'very easy'
when culture_identity = '12' THEN 'easy'
when culture_identity = '13' THEN 'sometimes easy, sometimes hard'
when culture_identity  = '14' THEN 'hard'
when culture_identity  = '15' THEN 'very hard'
else 'Unknown' end as cult_idm
,Case when civic_voting= '1' THEN 'Voted'
when civic_voting = '0' THEN 'Did Not Vote'
else 'Unknown'END AS voting_indm
,Case when safety_crime_victim ='1' THEN 'Yes'
when safety_crime_victim ='0' THEN 'No'
else 'Other' end as crime_exp_indm
	into [IDI_Sandpit].[DL-MAA2016-15].of_final_ben2emp from (
						

SELECT [snz_uid]
      ,[snz_gss_hhld_uid]
      ,[snz_spine_ind]
      ,[gss_id_collection_code] as gss_wave
      ,[gss_pq_interview_date] as pq_interview_date
      ,cast([gss_hq_interview_start_date] as datetime) as hq_interview_date	  
      ,[gss_pq_dvage_code] as age	  
      ,[sex]
      --,[gss_hq_sex_dev]
      --,[gss_hq_birth_month_nbr]
      --,[gss_hq_birth_year_nbr]
      --,[gss_hq_house_trust]
      --,[gss_hq_house_own]
      --,[gss_hq_house_pay_mort_code]
      --,[gss_hq_house_pay_rent_code]
      --,[gss_hq_house_who_owns_code]	  
      ,[housing_status] as house_status
      ,[gss_pq_HH_tenure_code] as house_tenure
      ,[gss_pq_HH_crowd_code] as house_crowding
      ,[gss_pq_house_mold_code] as house_mold
      ,[gss_pq_house_cold_code] as house_cold
      ,[gss_pq_house_condition_code] as house_condition
      ,[housing_satisfaction] as house_satisfaction	  
      ,[housing_sat_ind] as house_satisfaction_2lev
      ,[house_brm] as house_nbr_bedrooms
      --,[gss_pq_prob_hood_noisy_ind]
      ,[gss_pq_safe_night_pub_trans_code] as safety_pub_transport
	  ,pub_trpt_safety_ind as safety_pub_transport_2lev
      ,[gss_pq_safe_night_hood_code] as safety_neighbourhood_night
	  ,[safety_ind] as safety_neighbourhood_night_2lev
      ,[gss_pq_safe_day_hood_code] as safety_neighbourhood_day	  
      ,[safety_day_ind] as safety_neighbourhood_day_2lev
      --,[gss_pq_discrim_rent_ind]
      ,[crime_exp_ind] as safety_crime_victim
      ,[gss_pq_cult_identity_code] as culture_identity     
	  ,[cult_identity_ind] as culture_identity_2lev
      ,[belong] as culture_belonging_nz      
	  ,[phys_health_sf12_score] as health_sf12_physcial
      ,[ment_health_sf12_score] as health_sf12_mental
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
      ,[generalised_trust] as civic_generalised_trust	  
      ,[volunteer] as civic_volunteering
      ,[trust_police] as civic_trust_police
      ,[trust_education] as civic_trust_education
      ,[trust_media] as civic_trust_media
      ,[trust_courts] as civic_trust_courts
      ,[trust_parliment] as civic_trust_parliament
      ,[trust_health] as civic_trust_health
      ,[gss_pq_time_lonely_code] as social_time_lonely	  
      ,[time_lonely_ind] as social_time_lonely_3lev
      ,hh_gss_income as income_household
	  ,[inc_intvwmnth] as income_pq_intvw_mnth	  
	  ,[tot_inc_6mnth_b4] as income_6mnth_b4_trans
      ,[tot_inc_6mnth_af] as income_6mnth_af_trans
      ,[tot_ird_pye_was_dur_b4] as income_6mnth_paye_dur_b4_trans
      ,[dur_benIB_6mnth_b4] as income_6mnth_benIB_dur_b4_trans
      ,[dur_benSB_6mnth_b4] as income_6mnth_benSB_dur_b4_trans
      ,[dur_benUB_6mnth_b4] as income_6mnth_benUB_dur_b4_trans
      ,[dur_benDPB_6mnth_b4] as income_6mnth_benDPB_dur_b4_trans	  
      ,[dur_benOther_6mnth_b4] as income_6mnth_benOT_dur_b4_trans
      ,[dur_benIB_6mnth_af] as income_6mnth_benIB_dur_af_trans
      ,[dur_benSB_6mnth_af] as income_6mnth_benSB_dur_af_trans
      ,[dur_benUB_6mnth_af] as income_6mnth_benUB_dur_af_trans
      ,[dur_benDPB_6mnth_af] as income_6mnth_benDPB_dur_af_trans
      ,[dur_benOther_6mnth_af] as income_6mnth_benOT_dur_af_trans
      ,[gss_pq_material_wellbeing_code] as econ_material_well_being_idx
      ,[gss_pq_ELSIDV1] as econ_elsi_idx
      ,[FIN_WELL] as econ_enough_income
	  ,[leisure_time]
      ,[gss_pq_eth_european_code] as ethnicity_european_9lev
      ,[gss_pq_eth_maori_code] as ethnicity_maori_9lev
      ,[gss_pq_eth_samoan_code] as ethnicity_samoan_9lev
      ,[gss_pq_eth_cookisland_code] as ethnicity_cook_9lev
      ,[gss_pq_eth_tongan_code] as ethnicity_tongan_9lev
      ,[gss_pq_eth_nieuan_code] as ethnicity_nieuan_9lev
      ,[gss_pq_eth_chinese_code] as ethnicity_chinese_9lev
      ,[gss_pq_eth_indian_code] as ethnicity_indian_9lev
	  ,[eth_oth] as ethnicity_other_9lev
      ,[eth_dk] as ethnicity_dk_9lev
      ,[eth_ref] as ethnicity_refuse_9lev	  
      ,[P_EURO] as ethnicity_european_6lev
      ,[P_MAORI] as ethnicity_maori_6lev	  
      ,[P_PACIFIC] as ethnicity_pacific_6lev
	  ,[P_ASIAN] as ethnicity_asian_6lev
      ,[P_MELAA] as ethnicity_melaa_6lev	  
      ,[P_OTHER] as ethnicity_other_6lev
      ,[P_NS] as ethnicity_ns_6lev	  
      ,[P_OTHER_NS] as ethnicity_otherns_6lev	
      ,[reg_six] as region_6lev	  
      ,[married] as social_marital_status	  
      ,[fam_typem] as family_type	  
      ,[P_COR_ind] as corr_ind_1year
	  ,[sequence_full] as sequence_events
      ,[sequence_b4] as sequence_events_b4
      ,[sequence_af] as sequence_events_af
      ,[state_3b4] as third_state_b4_intvw
      ,[days_3b4] as third_state_b4_intvw_dur
      ,[state_2b4] as second_state_b4_intvw
      ,[days_2b4] as second_state_b4_intvw_dur
      ,[state_1b4] as state_b4_intvw
      ,[days_1b4] as state_b4_intvw_dur
      ,[state_1af] as state_af_intvw
      ,[days_1af] as state_af_intvw_dur
      ,[state_2af] as second_state_af_intvw
      ,[days_2af] as second_state_af_intvw_dur
      ,[state_3af] as third_state_af_intvw
      ,[days_3af] as third_state_af_intvw_dur
      ,[crossover_spell_days] as transition_spell_days
      ,[BEN_to_EMP_b4]
      ,[BEN_to_EMP_af]
	  ,[EMP_to_BEN_b4]
      ,[EMP_to_BEN_af]
	   ,[ben_to_emp_trans_days] as days_to_transition_ben_to_emp
      ,[treat_control_ind]
  FROM [IDI_Sandpit].[DL-MAA2016-15].of_mhaet_pop_ben2emp

						
)zz


