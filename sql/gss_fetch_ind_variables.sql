
SELECT [snz_uid]
      ,[snz_gss_hhld_uid]
      ,[snz_spine_ind]
      ,[gss_id_collection_code] as gss_wave
      ,[gss_pq_interview_date] as pq_interview_date
      ,cast([gss_hq_interview_start_date] as datetime) as hq_interview_date	  
      ,[gss_pq_dvage_code] as age	  
      ,[sex]
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
	  ,[work_hrs_clean] as emp_total_hrs_worked
      ,[work_jobs_no] as emp_nbr_of_jobs
      ,[work_satisfaction] as emp_work_satisfaction
      ,[work_ft_pt] as emp_fulltime_parttime
      ,[gss_pq_highest_qual_dev] as know_highest_qual	  
      ,[gss_oecd_quals] as know_highest_qual_4lev	  
      ,[P_TER_DUR] as know_tertiary_dur_1year
	  ,life_satisfaction_ind as subj_life_satisfaction  
      ,[purpose_sense_clean] as subj_sense_of_purpose
      ,[gss_pq_voting] as civic_voting
      ,[generalised_trust_clean] as civic_generalised_trust	  
      ,[volunteer_clean] as civic_volunteering
      ,[trust_police_clean] as civic_trust_police
      ,[trust_education_clean] as civic_trust_education
      ,[trust_media_clean] as civic_trust_media
      ,[trust_courts_clean] as civic_trust_courts
      ,[trust_parliment_clean] as civic_trust_parliament
      ,[trust_health_clean] as civic_trust_health
      ,[gss_pq_time_lonely_code] as social_time_lonely	  
      ,[time_lonely_ind] as social_time_lonely_3lev
      ,hh_gss_income as income_household
	  ,[inc_intvwmnth] as income_pq_intvw_mnth	  
	  ,accom_sup_1mnth_b4_intvw
	  ,accom_sup_1mnth_af_intvw      
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
	  ,gss_pq_person_FinalWgt_nbr,    gss_pq_person_FinalWgt1_nbr,   gss_pq_person_FinalWgt2_nbr,   gss_pq_person_FinalWgt3_nbr,   gss_pq_person_FinalWgt4_nbr,   gss_pq_person_FinalWgt5_nbr,   gss_pq_person_FinalWgt6_nbr,   gss_pq_person_FinalWgt7_nbr,   gss_pq_person_FinalWgt8_nbr,   gss_pq_person_FinalWgt9_nbr,  
gss_pq_person_FinalWgt10_nbr,  gss_pq_person_FinalWgt11_nbr,  gss_pq_person_FinalWgt12_nbr,  gss_pq_person_FinalWgt13_nbr,  gss_pq_person_FinalWgt14_nbr,  gss_pq_person_FinalWgt15_nbr,  gss_pq_person_FinalWgt16_nbr,  gss_pq_person_FinalWgt17_nbr,  gss_pq_person_FinalWgt18_nbr,  gss_pq_person_FinalWgt19_nbr, 
gss_pq_person_FinalWgt20_nbr,  gss_pq_person_FinalWgt21_nbr,  gss_pq_person_FinalWgt22_nbr,  gss_pq_person_FinalWgt23_nbr,  gss_pq_person_FinalWgt24_nbr,  gss_pq_person_FinalWgt25_nbr,  gss_pq_person_FinalWgt26_nbr,  gss_pq_person_FinalWgt27_nbr,  gss_pq_person_FinalWgt28_nbr,  gss_pq_person_FinalWgt29_nbr, 
gss_pq_person_FinalWgt30_nbr,  gss_pq_person_FinalWgt31_nbr,  gss_pq_person_FinalWgt32_nbr,  gss_pq_person_FinalWgt33_nbr,  gss_pq_person_FinalWgt34_nbr,  gss_pq_person_FinalWgt35_nbr,  gss_pq_person_FinalWgt36_nbr,  gss_pq_person_FinalWgt37_nbr,  gss_pq_person_FinalWgt38_nbr,  gss_pq_person_FinalWgt39_nbr, 
gss_pq_person_FinalWgt40_nbr,  gss_pq_person_FinalWgt41_nbr,  gss_pq_person_FinalWgt42_nbr,  gss_pq_person_FinalWgt43_nbr,  gss_pq_person_FinalWgt44_nbr,  gss_pq_person_FinalWgt45_nbr,  gss_pq_person_FinalWgt46_nbr,  gss_pq_person_FinalWgt47_nbr,  gss_pq_person_FinalWgt48_nbr,  gss_pq_person_FinalWgt49_nbr, 
gss_pq_person_FinalWgt50_nbr,  gss_pq_person_FinalWgt51_nbr,  gss_pq_person_FinalWgt52_nbr,  gss_pq_person_FinalWgt53_nbr,  gss_pq_person_FinalWgt54_nbr,  gss_pq_person_FinalWgt55_nbr,  gss_pq_person_FinalWgt56_nbr,  gss_pq_person_FinalWgt57_nbr,  gss_pq_person_FinalWgt58_nbr,  gss_pq_person_FinalWgt59_nbr, 
gss_pq_person_FinalWgt60_nbr,  gss_pq_person_FinalWgt61_nbr,  gss_pq_person_FinalWgt62_nbr,  gss_pq_person_FinalWgt63_nbr,  gss_pq_person_FinalWgt64_nbr,  gss_pq_person_FinalWgt65_nbr,  gss_pq_person_FinalWgt66_nbr,  gss_pq_person_FinalWgt67_nbr,  gss_pq_person_FinalWgt68_nbr,  gss_pq_person_FinalWgt69_nbr, 
gss_pq_person_FinalWgt70_nbr,  gss_pq_person_FinalWgt71_nbr,  gss_pq_person_FinalWgt72_nbr,  gss_pq_person_FinalWgt73_nbr,  gss_pq_person_FinalWgt74_nbr,  gss_pq_person_FinalWgt75_nbr,  gss_pq_person_FinalWgt76_nbr,  gss_pq_person_FinalWgt77_nbr,  gss_pq_person_FinalWgt78_nbr,  gss_pq_person_FinalWgt79_nbr, 
gss_pq_person_FinalWgt80_nbr,  gss_pq_person_FinalWgt81_nbr,  gss_pq_person_FinalWgt82_nbr,  gss_pq_person_FinalWgt83_nbr,  gss_pq_person_FinalWgt84_nbr,  gss_pq_person_FinalWgt85_nbr,  gss_pq_person_FinalWgt86_nbr,  gss_pq_person_FinalWgt87_nbr,  gss_pq_person_FinalWgt88_nbr,  gss_pq_person_FinalWgt89_nbr, 
gss_pq_person_FinalWgt90_nbr,  gss_pq_person_FinalWgt91_nbr,  gss_pq_person_FinalWgt92_nbr,  gss_pq_person_FinalWgt93_nbr,  gss_pq_person_FinalWgt94_nbr,  gss_pq_person_FinalWgt95_nbr,  gss_pq_person_FinalWgt96_nbr,  gss_pq_person_FinalWgt97_nbr,  gss_pq_person_FinalWgt98_nbr,  gss_pq_person_FinalWgt99_nbr, 
gss_pq_person_FinalWgt100_nbr
FROM [IDI_Sandpit].[DL-MAA2016-15].of_gss_ind_variables;

