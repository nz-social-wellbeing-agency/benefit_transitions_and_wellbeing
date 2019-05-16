/*********************************************************************************************************
DESCRIPTION: 

si_create_of_gss_ind_variables

Combines all the GSS person information across different waves into one single 
table. Only a limited set of variables which are useful for the outcomes framework project have 
been retained.

INPUT:
[&idi_version.].[gss_clean].[gss_person] = 2014 GSS person table
[&idi_version.].[gss_clean].[gss_person_2012] = 2012 GSS person table
[&idi_version.].[gss_clean].[gss_person_2010] = 2010 GSS person table
[&idi_version.].[gss_clean].[gss_person_2008] = 2008 GSS person table

OUTPUT:dep
sand.of_gss_ind_variables = dataset with person variables for GSS

AUTHOR: 
V Benny

DEPENDENCIES:
NA

NOTES:   
1. All GSS waves are available only from IDI_Clean_20171027 onwards.


HISTORY: 
22 Nov 2017 VB Converted the SQL version into SAS.
20 Dec 2017 WJ Added SQL part of income derived for OECD for benefits and OECD ISCED attempt and mental_health_type
10 Mar 2018 WJ Added Other GSS variables that were matched based on the waves and availability - Note that variables added have not yet been formatted
10 Apr 2018 WJ Added variables used for benefit to employment work

10 Jul 2018 WJ Added new housing variables requested by David Rea
20 Jul 2018 BV Added voting, free time and access to green space indicator
06 Aug 2018 WJ Changed the dsn variable and added variables requested about size of family for the pq
19 Oct 2018 WJ - Modified for 2018 refresh
***********************************************************************************************************/

proc sql;

	connect to odbc (dsn=&si_idi_dsnname.);

	create table work._temp_of_gss_ind_variables as
	select *
	from connection to odbc(	
		select 
			pers.snz_uid  
			,pers.snz_gss_hhld_uid  
			,pers_det.snz_spine_ind  
			,pers.gss_pq_collection_code as gss_id_collection_code  
			/* 19 Oct 2018, Vinay:  Remove the coalesce function below, since this is a stopgap fix for the issue of missing interview dates
			for the IDI Refresh IDI_Clean_20181020*/
/*			,coalesce(pers.gss_pq_PQinterview_date, p2.gss_pq_interview_date) as gss_pq_interview_date*/
			,cast(pers.gss_pq_PQinterview_date as datetime) as gss_pq_interview_date  

/*			,coalesce(hhld.gss_hq_interview_start_date, p2.gss_hq_interview_date) as gss_hq_interview_date*/
			,hhld.gss_hq_interview_start_date  as gss_hq_interview_date

			,hhld.gss_hq_sex_dev  
			,hhld.gss_hq_birth_month_nbr  
			,hhld.gss_hq_birth_year_nbr  
			,pers.gss_pq_dvage_code  
				/*			Modified for 2018 refresh*/
			,coalesce(pers.gss_pq_ethnic_grp4_snz_ind,0)  AS P_ASIAN  
			,coalesce(pers.gss_pq_ethnic_grp1_snz_ind,0) AS P_EURO   
			,coalesce(pers.gss_pq_ethnic_grp2_snz_ind,0) AS P_MAORI   
			,coalesce(pers.gss_pq_ethnic_grp5_snz_ind,0) AS P_MELAA   
			,coalesce(pers.gss_pq_ethnic_grp6_snz_ind,0) AS P_OTHER   
			,coalesce(pers.gss_pq_ethnic_grp3_snz_ind,0) AS P_PACIFIC    /* Ethnicity lower level raw detail*/   

			,case when cast(pers.gss_pq_maori_descent_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_maori_descent_code as smallint) end  AS maori_desc
			,cast(pers.gss_pq_born_NZ_ind as smallint) AS nz_born
			,pers.gss_pq_arrive_NZ_yr  AS nz_arrive_year
			,pers.gss_pq_arrive_nz_mnth_code  AS nz_arrive_month
			,hhld.[gss_hq_regcouncil_dev]  
			,pers.gss_pq_mar_stat_code  AS married
			,pers.gss_pq_HH_comp_code  
			,case when devfam.gss_hq_fam_num_depchild_nbr=0 then 5 when devfam.gss_hq_fam_num_depchild_nbr >=4 then 4 when devfam.gss_hq_fam_num_depchild_nbr = 77 then NULL else devfam.gss_hq_fam_num_depchild_nbr end as gss_hq_dep_child_dev
			,case pers.gss_pq_fam_type_code when '10' then '11' when '40' then '41' else  pers.gss_pq_fam_type_code end as fam_type /* diff mapping between 2014 and 2016: 10->11 and 40->41 */
			,hhld.family_nuclei_ct   
			,hhld.nonfamily_nuclei_ct
			,hhld.family_size_adult    
			,hhld.family_size_child
			,devfam.gss_hq_fam_num_depchild_nbr as family_size_depchild
			,devfam.[gss_hq_fam_num_indepchild_nbr] as family_size_indepchild
			,case when hhld.gss_hq_house_trust  in (88, 99) then NULL else hhld.gss_hq_house_trust end as gss_hq_house_trust
			,case when hhld.gss_hq_house_own   in (88, 99) then NULL else hhld.gss_hq_house_own end as gss_hq_house_own
			,case when hhld.gss_hq_house_pay_mort_code in (88, 99) then NULL else hhld.gss_hq_house_pay_mort_code end as gss_hq_house_pay_mort_code  
			,case when hhld.gss_hq_house_pay_rent_code  in (88, 99) then NULL else hhld.gss_hq_house_pay_rent_code end as gss_hq_house_pay_rent_code
			,case when hhld.gss_hq_house_who_owns_code  in (88, 99) then NULL else hhld.gss_hq_house_who_owns_code end as gss_hq_house_who_owns_code 
			,pers.gss_pq_HH_tenure_code 
			,cast(pers.gss_pq_HH_crowd_code as smallint) as gss_pq_HH_crowd_code  
			,case when pers.gss_pq_house_mold_code in ('13') then 1 else 0 end as gss_pq_house_mold_code /* 1- Yes, 0 - No/Unknown */  
			,case when pers.gss_pq_house_cold_code in ('11', '12') then 1 else 0 end as gss_pq_house_cold_code /* 1- Yes, 0 - No/Unknown */  
			,pers.gss_pq_house_condition_code as gss_pq_house_condition_code20146
			,NULL as gss_pq_house_condition_code
			,NULL as housing_satisfaction
			,coalesce(pers.gss_pq_prob_hood_noisy_ind, 0) as gss_pq_prob_hood_noisy_ind  
			,pers.gss_pq_safe_night_pub_trans_code
			,pers.gss_pq_safe_night_hood_code
			,NULL as gss_pq_safe_day_hood_code
			,cast(pers.gss_pq_crimes_against_ind as smallint) as gss_pq_crimes_against_ind/* Slightly different wording (re traffic incidents) */  
			,cast(hhld.gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
			,hhld.hh_gss_income
			,hhld.hh_gss_income_median
			,hhld.hh_gss_income_lower
			,hhld.hh_gss_income_upper
			,hhld.housing_status
			,cast(pers.gss_pq_lfs_dev as smallint) as gss_pq_lfs_dev  
			,coalesce(pers.gss_pq_inc_jobseek_dev,0) as gss_unemp_jobseek  /* only jobseek ben post reform, no unemp anymore */
			,NULL as gss_sickness /* set to NULL for post reform benefits */
			,coalesce(pers.gss_pq_inc_supplive_dev,0) as gss_invalid_support   /* only suppliving ben post reform, no invalid anymore */
			,coalesce(pers.gss_pq_inc_soleprnt_dev,0) as gss_soleprnt_domestic    /* only soleprnt ben post reform, no domestic anymore */
			, coalesce(gss_pq_inc_othben_dev,0) as gss_oth_ben   
			,coalesce(gss_pq_inc_none_dev,0) as gss_no_income     /*Adding variables of interest which matches up across all waves - raw variables here as no transformations done*/   /* year of birth */   
			,case when cast(gss_pq_material_wellbeing_code as smallint) between 0 and 20 then cast(gss_pq_material_wellbeing_code as smallint) else NULL end as gss_pq_material_wellbeing_code  
			,NULL as gss_pq_ELSIDV1         
			,gss_pq_cost_down_vege_code   
			,gss_pq_cost_down_dr_code   
			,gss_pq_cost_down_shop_code   
			,gss_pq_cost_down_hobby_code   
			,gss_pq_cost_down_cold_code   
			,gss_pq_cost_down_appliance_code   
			,gss_pq_buy_shoes_limit_code   
			,gss_pq_item_300_limit_code   
			,gss_pq_not_pay_bills_time_code   
			,gss_pq_enough_inc_code
			,pers.gss_pq_usual_hrs_work_nbr AS work_hrs
			,pers.gss_pq_jobs_nbr  AS work_jobs_no   
			,pers.gss_pq_feel_job_code  AS work_satisfaction   
			,cast(pers.gss_pq_FT_PT_Status_code as smallint)  AS work_ft_pt   
			,cast(case when pers.gss_pq_paid_work_profit_code = '1' then 1 else 2 end as smallint) as work_now_ind
			,case when cast(pers.gss_pq_has_job_start_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_has_job_start_code as smallint) end AS work_start_ind   
			,case when cast(pers.gss_pq_looked_work_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_looked_work_code as smallint) end AS work_look_ind
			,case when cast(pers.gss_pq_start_last_wk_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_start_last_wk_code as smallint) end AS work_could_start
			,pers.gss_pq_sch_qual_code  AS school_highest
			,cast(pers.gss_pq_highest_qual_dev as smallint) as gss_pq_highest_qual_dev  
			,pers.gss_pq_high_qual_yr  AS qual_yr
			,case when pers.gss_pq_health_excel_poor_code in (88, 99) then NULL else pers.gss_pq_health_excel_poor_code end  AS health_status   
			,case when pers.gss_pq_health_limits_activ_code in (88, 99) then NULL else pers.gss_pq_health_limits_activ_code end AS health_limit_activ   
			,case when pers.gss_pq_health_limits_stairs_code in (88, 99) then NULL else pers.gss_pq_health_limits_stairs_code end AS health_limit_stair     
			,pers.gss_pq_accomplish_less_phys_code  AS health_accomplish_phys   
			,pers.gss_pq_limited_work_phys_code  AS health_work_phys   
			,pers.gss_pq_accomplish_less_emo_code  AS health_accomplish_emo   
			,pers.gss_pq_less_careful_emo_code  AS health_work_emo   
			,pers.gss_pq_pain_interfere_code  AS health_pain   
			,pers.gss_pq_felt_calm_code  AS health_calm   
			,pers.gss_pq_felt_energetic_code  AS health_energy   
			,pers.gss_pq_felt_depressed_code  AS health_depressed   
			,pers.gss_pq_health_interfere_soc_code  AS health_social   
			,cast(pers.gss_pq_ment_health_code as smallint) as gss_pq_ment_health_code  
			,cast(pers.gss_pq_phys_health_code as smallint) as gss_pq_phys_health_code  
			,pers.gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different) */  
			,NULL AS belong    
			,sup.gss_supp16_SOI_qSOBNZ AS belong_2016
			,pers.gss_pq_discriminated_code AS discrim_status   
			,coalesce(pers.gss_pq_discrim_ShopRest_ind, 0) AS discrim_shop      
			,coalesce(pers.gss_pq_discrim_work_ind, 0)  AS discrim_work   
			,coalesce(pers.gss_pq_discrim_public_ind, 0)  AS discrim_public   
			,coalesce(pers.gss_pq_discrim_school_ind, 0)  AS discrim_school   
			,coalesce(pers.gss_pq_discrim_job_ind, 0)  AS discrim_job   
			,coalesce(pers.gss_pq_discrim_police_ind, 0)  AS discrim_police   
			,coalesce(pers.gss_pq_discrim_medic_ind, 0)  AS discrim_medic   
			,coalesce(pers.gss_pq_discrim_other_ind, 0)  AS discrim_other   
			,coalesce(pers.gss_pq_discrim_dontknow_ind, 0)  AS discrim_dk   
			,coalesce(pers.gss_pq_discrim_refused_ind, 0)  AS discrim_nr   
			,case when pers.gss_pq_discrim_rent_ind = '1' then 1 else 0 end as gss_pq_discrim_rent_ind  
			,NULL AS leisure_time   
			,sup.gss_supp16_VOT_qVoteLE as gss_pq_voting
			,case when sup.gss_supp16_VOL_qVolOrg_NoVolWrk='1' then 0 else 1 end as volunteer
			,pers.gss_pq_trust_police_code AS trust_police   
			,pers.gss_pq_trust_education_code AS trust_education   
			,pers.gss_pq_trust_media_code AS trust_media    
			,pers.gss_pq_trust_courts_code AS trust_courts   
			,pers.gss_pq_trust_parliament_code AS trust_parliament   
			,pers.gss_pq_trust_health_code AS trust_health
			,cast(pers.gss_pq_trust_most_code as smallint) AS generalised_trust   
			,case pers.gss_pq_time_lonely_code 
			/* Scales flipped between 2014 & 2016  and other waves */    
			when 11 then 15    when 12 then 14     when 14 then 12     when 15 then 11    else pers.gss_pq_time_lonely_code end as gss_pq_time_lonely_code  
			,NULL AS env_water_bodies /*environment*/   
			,NULL AS env_access_bush /*environment*/   
			,NULL AS env_state_bush /*environment*/     
			,cast(pers.gss_pq_life_worthwhile_code as smallint) AS purpose_sense
			,pers.gss_pq_feel_life_code  
			,pers.gss_pq_bedroom_nbr as house_brm
			,pers.gss_pq_inc_selfemp_dev  AS inc_self   
			,[gss_pq_person_SeInWgt_nbr]   as gss_pq_person_SeInWgt
			,[gss_pq_person_FinalWgt_nbr]   as gss_pq_person_FinalWgt
			,[gss_pq_person_FinalWgt1_nbr]   as  gss_pq_person_FinalWgt1
			,[gss_pq_person_FinalWgt2_nbr]   as  gss_pq_person_FinalWgt2
			,[gss_pq_person_FinalWgt3_nbr]   as  gss_pq_person_FinalWgt3
			,[gss_pq_person_FinalWgt4_nbr]   as  gss_pq_person_FinalWgt4
			,[gss_pq_person_FinalWgt5_nbr]   as  gss_pq_person_FinalWgt5
			,[gss_pq_person_FinalWgt6_nbr]   as  gss_pq_person_FinalWgt6
			,[gss_pq_person_FinalWgt7_nbr]   as  gss_pq_person_FinalWgt7
			,[gss_pq_person_FinalWgt8_nbr]   as  gss_pq_person_FinalWgt8
			,[gss_pq_person_FinalWgt9_nbr]   as  gss_pq_person_FinalWgt9
			,[gss_pq_person_FinalWgt10_nbr]   as  gss_pq_person_FinalWgt10
			,[gss_pq_person_FinalWgt11_nbr]   as  gss_pq_person_FinalWgt11
			,[gss_pq_person_FinalWgt12_nbr]   as  gss_pq_person_FinalWgt12
			,[gss_pq_person_FinalWgt13_nbr]   as  gss_pq_person_FinalWgt13
			,[gss_pq_person_FinalWgt14_nbr]   as  gss_pq_person_FinalWgt14
			,[gss_pq_person_FinalWgt15_nbr]   as  gss_pq_person_FinalWgt15
			,[gss_pq_person_FinalWgt16_nbr]   as  gss_pq_person_FinalWgt16
			,[gss_pq_person_FinalWgt17_nbr]   as  gss_pq_person_FinalWgt17
			,[gss_pq_person_FinalWgt18_nbr]   as  gss_pq_person_FinalWgt18
			,[gss_pq_person_FinalWgt19_nbr]   as  gss_pq_person_FinalWgt19
			,[gss_pq_person_FinalWgt20_nbr]   as  gss_pq_person_FinalWgt20
			,[gss_pq_person_FinalWgt21_nbr]   as  gss_pq_person_FinalWgt21
			,[gss_pq_person_FinalWgt22_nbr]   as  gss_pq_person_FinalWgt22
			,[gss_pq_person_FinalWgt23_nbr]   as  gss_pq_person_FinalWgt23
			,[gss_pq_person_FinalWgt24_nbr]   as  gss_pq_person_FinalWgt24
			,[gss_pq_person_FinalWgt25_nbr]   as  gss_pq_person_FinalWgt25
			,[gss_pq_person_FinalWgt26_nbr]   as  gss_pq_person_FinalWgt26
			,[gss_pq_person_FinalWgt27_nbr]   as  gss_pq_person_FinalWgt27
			,[gss_pq_person_FinalWgt28_nbr]   as  gss_pq_person_FinalWgt28
			,[gss_pq_person_FinalWgt29_nbr]   as  gss_pq_person_FinalWgt29
			,[gss_pq_person_FinalWgt30_nbr]   as  gss_pq_person_FinalWgt30
			,[gss_pq_person_FinalWgt31_nbr]   as  gss_pq_person_FinalWgt31
			,[gss_pq_person_FinalWgt32_nbr]   as  gss_pq_person_FinalWgt32
			,[gss_pq_person_FinalWgt33_nbr]   as  gss_pq_person_FinalWgt33
			,[gss_pq_person_FinalWgt34_nbr]   as  gss_pq_person_FinalWgt34
			,[gss_pq_person_FinalWgt35_nbr]   as  gss_pq_person_FinalWgt35
			,[gss_pq_person_FinalWgt36_nbr]   as  gss_pq_person_FinalWgt36
			,[gss_pq_person_FinalWgt37_nbr]   as  gss_pq_person_FinalWgt37
			,[gss_pq_person_FinalWgt38_nbr]   as  gss_pq_person_FinalWgt38
			,[gss_pq_person_FinalWgt39_nbr]   as  gss_pq_person_FinalWgt39
			,[gss_pq_person_FinalWgt40_nbr]   as  gss_pq_person_FinalWgt40
			,[gss_pq_person_FinalWgt41_nbr]   as  gss_pq_person_FinalWgt41
			,[gss_pq_person_FinalWgt42_nbr]   as  gss_pq_person_FinalWgt42
			,[gss_pq_person_FinalWgt43_nbr]   as  gss_pq_person_FinalWgt43
			,[gss_pq_person_FinalWgt44_nbr]   as  gss_pq_person_FinalWgt44
			,[gss_pq_person_FinalWgt45_nbr]   as  gss_pq_person_FinalWgt45
			,[gss_pq_person_FinalWgt46_nbr]   as  gss_pq_person_FinalWgt46
			,[gss_pq_person_FinalWgt47_nbr]   as  gss_pq_person_FinalWgt47
			,[gss_pq_person_FinalWgt48_nbr]   as  gss_pq_person_FinalWgt48
			,[gss_pq_person_FinalWgt49_nbr]   as  gss_pq_person_FinalWgt49
			,[gss_pq_person_FinalWgt50_nbr]   as  gss_pq_person_FinalWgt50
			,[gss_pq_person_FinalWgt51_nbr]   as  gss_pq_person_FinalWgt51
			,[gss_pq_person_FinalWgt52_nbr]   as  gss_pq_person_FinalWgt52
			,[gss_pq_person_FinalWgt53_nbr]   as  gss_pq_person_FinalWgt53
			,[gss_pq_person_FinalWgt54_nbr]   as  gss_pq_person_FinalWgt54
			,[gss_pq_person_FinalWgt55_nbr]   as  gss_pq_person_FinalWgt55
			,[gss_pq_person_FinalWgt56_nbr]   as  gss_pq_person_FinalWgt56
			,[gss_pq_person_FinalWgt57_nbr]   as  gss_pq_person_FinalWgt57
			,[gss_pq_person_FinalWgt58_nbr]   as  gss_pq_person_FinalWgt58
			,[gss_pq_person_FinalWgt59_nbr]   as  gss_pq_person_FinalWgt59
			,[gss_pq_person_FinalWgt60_nbr]   as  gss_pq_person_FinalWgt60
			,[gss_pq_person_FinalWgt61_nbr]   as  gss_pq_person_FinalWgt61
			,[gss_pq_person_FinalWgt62_nbr]   as  gss_pq_person_FinalWgt62
			,[gss_pq_person_FinalWgt63_nbr]   as  gss_pq_person_FinalWgt63
			,[gss_pq_person_FinalWgt64_nbr]   as  gss_pq_person_FinalWgt64
			,[gss_pq_person_FinalWgt65_nbr]   as  gss_pq_person_FinalWgt65
			,[gss_pq_person_FinalWgt66_nbr]   as  gss_pq_person_FinalWgt66
			,[gss_pq_person_FinalWgt67_nbr]   as  gss_pq_person_FinalWgt67
			,[gss_pq_person_FinalWgt68_nbr]   as  gss_pq_person_FinalWgt68
			,[gss_pq_person_FinalWgt69_nbr]   as  gss_pq_person_FinalWgt69
			,[gss_pq_person_FinalWgt70_nbr]   as  gss_pq_person_FinalWgt70
			,[gss_pq_person_FinalWgt71_nbr]   as  gss_pq_person_FinalWgt71
			,[gss_pq_person_FinalWgt72_nbr]   as  gss_pq_person_FinalWgt72
			,[gss_pq_person_FinalWgt73_nbr]   as  gss_pq_person_FinalWgt73
			,[gss_pq_person_FinalWgt74_nbr]   as  gss_pq_person_FinalWgt74
			,[gss_pq_person_FinalWgt75_nbr]   as  gss_pq_person_FinalWgt75
			,[gss_pq_person_FinalWgt76_nbr]   as  gss_pq_person_FinalWgt76
			,[gss_pq_person_FinalWgt77_nbr]   as  gss_pq_person_FinalWgt77
			,[gss_pq_person_FinalWgt78_nbr]   as  gss_pq_person_FinalWgt78
			,[gss_pq_person_FinalWgt79_nbr]   as  gss_pq_person_FinalWgt79
			,[gss_pq_person_FinalWgt80_nbr]   as  gss_pq_person_FinalWgt80
			,[gss_pq_person_FinalWgt81_nbr]   as  gss_pq_person_FinalWgt81
			,[gss_pq_person_FinalWgt82_nbr]   as  gss_pq_person_FinalWgt82
			,[gss_pq_person_FinalWgt83_nbr]   as  gss_pq_person_FinalWgt83
			,[gss_pq_person_FinalWgt84_nbr]   as  gss_pq_person_FinalWgt84
			,[gss_pq_person_FinalWgt85_nbr]   as  gss_pq_person_FinalWgt85
			,[gss_pq_person_FinalWgt86_nbr]   as  gss_pq_person_FinalWgt86
			,[gss_pq_person_FinalWgt87_nbr]   as  gss_pq_person_FinalWgt87
			,[gss_pq_person_FinalWgt88_nbr]   as  gss_pq_person_FinalWgt88
			,[gss_pq_person_FinalWgt89_nbr]   as  gss_pq_person_FinalWgt89
			,[gss_pq_person_FinalWgt90_nbr]   as  gss_pq_person_FinalWgt90
			,[gss_pq_person_FinalWgt91_nbr]   as  gss_pq_person_FinalWgt91
			,[gss_pq_person_FinalWgt92_nbr]   as  gss_pq_person_FinalWgt92
			,[gss_pq_person_FinalWgt93_nbr]   as  gss_pq_person_FinalWgt93
			,[gss_pq_person_FinalWgt94_nbr]   as  gss_pq_person_FinalWgt94
			,[gss_pq_person_FinalWgt95_nbr]   as  gss_pq_person_FinalWgt95
			,[gss_pq_person_FinalWgt96_nbr]   as  gss_pq_person_FinalWgt96
			,[gss_pq_person_FinalWgt97_nbr]   as  gss_pq_person_FinalWgt97
			,[gss_pq_person_FinalWgt98_nbr]   as  gss_pq_person_FinalWgt98
			,[gss_pq_person_FinalWgt99_nbr]   as  gss_pq_person_FinalWgt99
			,[gss_pq_person_FinalWgt100_nbr] as  gss_pq_person_FinalWgt100
		from &idi_version..gss_clean.gss_person pers 
		inner join &idi_version..data.personal_detail pers_det on (pers.snz_uid = pers_det.snz_uid)
		inner join IDI_Sandpit.[&si_proj_schema.].of_gss_hh_variables_mh hhld 
			on (pers.snz_uid = hhld.snz_uid and pers.gss_pq_collection_code = hhld.gss_id_collection_code)
				/*			Modified for 2018 refresh*/
		inner join &idi_version..gss_clean.gss_household devfam
			on (pers.snz_uid = devfam.snz_uid and pers.gss_pq_collection_code = devfam.gss_hq_collection_code)
		inner join &idi_version..gss_clean.gss_supp_2016 sup on (pers.snz_uid = sup.snz_uid)
		/* 19 Oct 2018, Vinay:  Remove the join below, since this is a stopgap fix for the issue of missing interview dates
			for the IDI Refresh IDI_Clean_20181020*/
/*		inner join (select snz_gss_hhld_uid, gss_pq_interview_date, gss_hq_interview_date from */
/*					IDI_Sandpit.[&si_proj_schema.].[of_gss_ind_interviewdates]) p2 on (pers.snz_gss_hhld_uid = p2.snz_gss_hhld_uid)*/
		where pers.gss_pq_collection_code = 'GSS2016'

		union all

		select 
			pers.snz_uid  
			,pers.snz_gss_hhld_uid  
			,pers_det.snz_spine_ind  
			,pers.gss_pq_collection_code as gss_id_collection_code  
			,cast(gss_pq_PQinterview_date as datetime) as gss_pq_interview_date  
			,hhld.gss_hq_interview_start_date  as gss_hq_interview_date
			,hhld.gss_hq_sex_dev  
			,hhld.gss_hq_birth_month_nbr  
			,hhld.gss_hq_birth_year_nbr  
			,pers.gss_pq_dvage_code  
				/*			Modified for 2018 refresh*/
			,coalesce(pers.gss_pq_ethnic_grp4_snz_ind,0)  AS P_ASIAN   
			,coalesce(pers.gss_pq_ethnic_grp1_snz_ind,0) AS P_EURO   
			,coalesce(pers.gss_pq_ethnic_grp2_snz_ind,0) AS P_MAORI   
			,coalesce(pers.gss_pq_ethnic_grp5_snz_ind,0) AS P_MELAA   
			,coalesce(pers.gss_pq_ethnic_grp6_snz_ind,0) AS P_OTHER   
			,coalesce(pers.gss_pq_ethnic_grp3_snz_ind,0) AS P_PACIFIC    /* Ethnicity lower level raw detail*/   
			,case when cast(pers.gss_pq_maori_descent_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_maori_descent_code as smallint) end  AS maori_desc
			,cast(pers.gss_pq_born_NZ_ind as smallint) AS nz_born
			,pers.gss_pq_arrive_NZ_yr  AS nz_arrive_year
			,pers.gss_pq_arrive_nz_mnth_code  AS nz_arrive_month
			,hhld.[gss_hq_regcouncil_dev]  
			,pers.gss_pq_mar_stat_code  AS married
			,pers.gss_pq_HH_comp_code  
			,case when devfam.gss_hq_fam_num_depchild_nbr=0 then 5 when devfam.gss_hq_fam_num_depchild_nbr >=4 then 4 when devfam.gss_hq_fam_num_depchild_nbr = 77 then NULL else devfam.gss_hq_fam_num_depchild_nbr end as gss_hq_dep_child_dev
			,pers.gss_pq_fam_type_code  AS fam_type
			,hhld.family_nuclei_ct   
			,hhld.nonfamily_nuclei_ct
			,hhld.family_size_adult    
			,hhld.family_size_child
			,devfam.gss_hq_fam_num_depchild_nbr as family_size_depchild
			,devfam.[gss_hq_fam_num_indepchild_nbr] as family_size_indepchild
			,case when hhld.gss_hq_house_trust  in (88, 99) then NULL else hhld.gss_hq_house_trust end as gss_hq_house_trust
			,case when hhld.gss_hq_house_own   in (88, 99) then NULL else hhld.gss_hq_house_own end as gss_hq_house_own
			,case when hhld.gss_hq_house_pay_mort_code in (88, 99) then NULL else hhld.gss_hq_house_pay_mort_code end as gss_hq_house_pay_mort_code  
			,case when hhld.gss_hq_house_pay_rent_code  in (88, 99) then NULL else hhld.gss_hq_house_pay_rent_code end as gss_hq_house_pay_rent_code
			,case when hhld.gss_hq_house_who_owns_code  in (88, 99) then NULL else hhld.gss_hq_house_who_owns_code end as gss_hq_house_who_owns_code  
			,pers.gss_pq_HH_tenure_code 
			,cast(pers.gss_pq_HH_crowd_code as smallint) as gss_pq_HH_crowd_code  
			,case when pers.gss_pq_house_mold_code in ('13') then 1 else 0 end as gss_pq_house_mold_code /* 1- Yes, 0 - No/Unknown */  
			,case when pers.gss_pq_house_cold_code in ('11', '12') then 1 else 0 end as gss_pq_house_cold_code /* 1- Yes, 0 - No/Unknown */  
			,pers.gss_pq_house_condition_code as gss_pq_house_condition_code20146
			,NULL as gss_pq_house_condition_code
			,NULL as housing_satisfaction
			,coalesce(pers.gss_pq_prob_hood_noisy_ind, 0) as gss_pq_prob_hood_noisy_ind  
			,pers.gss_pq_safe_night_pub_trans_code
			,pers.gss_pq_safe_night_hood_code
			,NULL as gss_pq_safe_day_hood_code
			,cast(pers.gss_pq_crimes_against_ind as smallint) as gss_pq_crimes_against_ind/* Slightly different wording (re traffic incidents) */  
			,cast(hhld.gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
			,hhld.hh_gss_income
			,hhld.hh_gss_income_median
			,hhld.hh_gss_income_lower
			,hhld.hh_gss_income_upper
			,hhld.housing_status
			,cast(pers.gss_pq_lfs_dev as smallint) as gss_pq_lfs_dev  
			,case when coalesce(gss_pq_inc_unemp_dev,0) =1 or  coalesce(gss_pq_inc_jobseek_dev,0) = 1 then 1 else 0 end as gss_unemp_jobseek       
			, case when coalesce(gss_pq_inc_sick_dev,0)  = 1 then 1 else 0 end as gss_sickness   
			, case when coalesce(gss_pq_inc_invalid_dev,0) =1 or   coalesce(gss_pq_inc_supplive_dev,0) = 1 then 1 else 0 end as gss_invalid_support  
			, case when coalesce(gss_pq_inc_soleprnt_dev,0) =1 or   coalesce(gss_pq_inc_domestic_dev,0) = 1 then 1 else 0 end as gss_soleprnt_domestic  
			, case when coalesce(gss_pq_inc_othben_dev,0)  = 1 then 1 else 0 end as gss_oth_ben   
			,case when coalesce(gss_pq_inc_none_dev,0)  = 1 then 1 else 0 end as gss_no_income     /*Adding variables of interest which matches up across all waves - raw variables here as no transformations done*/   /* year of birth */   
			,case when cast(gss_pq_material_wellbeing_code as smallint) between 0 and 20    then cast(gss_pq_material_wellbeing_code as smallint)   else NULL end as gss_pq_material_wellbeing_code  
			,NULL as gss_pq_ELSIDV1         
			,gss_pq_cost_down_vege_code   
			,gss_pq_cost_down_dr_code   
			,gss_pq_cost_down_shop_code   
			,gss_pq_cost_down_hobby_code   
			,gss_pq_cost_down_cold_code   
			,gss_pq_cost_down_appliance_code   
			,gss_pq_buy_shoes_limit_code   
			,gss_pq_item_300_limit_code   
			,gss_pq_not_pay_bills_time_code   
			,gss_pq_enough_inc_code
			,pers.gss_pq_usual_hrs_work_nbr AS work_hrs
			,pers.gss_pq_jobs_nbr  AS work_jobs_no   
			,pers.gss_pq_feel_job_code  AS work_satisfaction   
			,cast(pers.gss_pq_FT_PT_Status_code as smallint)  AS work_ft_pt   
			,cast(pers.gss_pq_paid_work_code as smallint)  AS work_now_ind   
			,case when cast(pers.gss_pq_has_job_start_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_has_job_start_code as smallint) end AS work_start_ind   
			,case when cast(pers.gss_pq_looked_work_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_looked_work_code as smallint) end AS work_look_ind
			,case when cast(pers.gss_pq_start_last_wk_code as smallint) in (88, 99) then NULL else cast(pers.gss_pq_start_last_wk_code as smallint) end AS work_could_start
			,pers.gss_pq_sch_qual_code  AS school_highest
			,cast(pers.gss_pq_highest_qual_dev as smallint) as gss_pq_highest_qual_dev  
			,pers.gss_pq_high_qual_yr  AS qual_yr
			,case when pers.gss_pq_health_excel_poor_code in (88, 99) then NULL else pers.gss_pq_health_excel_poor_code end  AS health_status   
			,case when pers.gss_pq_health_limits_activ_code in (88, 99) then NULL else pers.gss_pq_health_limits_activ_code end AS health_limit_activ   
			,case when pers.gss_pq_health_limits_stairs_code in (88, 99) then NULL else pers.gss_pq_health_limits_stairs_code end AS health_limit_stair   
			,pers.gss_pq_accomplish_less_phys_code  AS health_accomplish_phys   
			,pers.gss_pq_limited_work_phys_code  AS health_work_phys   
			,pers.gss_pq_accomplish_less_emo_code  AS health_accomplish_emo   
			,pers.gss_pq_less_careful_emo_code  AS health_work_emo   
			,pers.gss_pq_pain_interfere_code  AS health_pain   
			,pers.gss_pq_felt_calm_code  AS health_calm   
			,pers.gss_pq_felt_energetic_code  AS health_energy   
			,pers.gss_pq_felt_depressed_code  AS health_depressed   
			,pers.gss_pq_health_interfere_soc_code  AS health_social   
			,cast(pers.gss_pq_ment_health_code as smallint) as gss_pq_ment_health_code  
			,cast(pers.gss_pq_phys_health_code as smallint) as gss_pq_phys_health_code  
			,pers.gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different) */  
			,NULL AS belong    
			,NULL AS belong_2016
			,pers.gss_pq_discriminated_code AS discrim_status   
			,coalesce(pers.gss_pq_discrim_ShopRest_ind, 0) AS discrim_shop      
			,coalesce(pers.gss_pq_discrim_work_ind, 0)  AS discrim_work   
			,coalesce(pers.gss_pq_discrim_public_ind, 0)  AS discrim_public   
			,coalesce(pers.gss_pq_discrim_school_ind, 0)  AS discrim_school   
			,coalesce(pers.gss_pq_discrim_job_ind, 0)  AS discrim_job   
			,coalesce(pers.gss_pq_discrim_police_ind, 0)  AS discrim_police   
			,coalesce(pers.gss_pq_discrim_medic_ind, 0)  AS discrim_medic   
			,coalesce(pers.gss_pq_discrim_other_ind, 0)  AS discrim_other   
			,coalesce(pers.gss_pq_discrim_dontknow_ind, 0)  AS discrim_dk   
			,coalesce(pers.gss_pq_discrim_refused_ind, 0)  AS discrim_nr 
			,case when pers.gss_pq_discrim_rent_ind = '1' then 1 else 0 end as gss_pq_discrim_rent_ind  
			,NULL AS leisure_time   
			,NULL as gss_pq_voting /* Available only for 2012, 2010, 2008 waves */  
			,coalesce(sup.gss_supp14_club_volunteer_ind,0) AS volunteer    
			,pers.gss_pq_trust_police_code AS trust_police   
			,pers.gss_pq_trust_education_code AS trust_education   
			,pers.gss_pq_trust_media_code AS trust_media    
			,pers.gss_pq_trust_courts_code AS trust_courts   
			,pers.gss_pq_trust_parliament_code AS trust_parliament   
			,pers.gss_pq_trust_health_code AS trust_health
			,cast(pers.gss_pq_trust_most_code as smallint) AS generalised_trust   
			,case pers.gss_pq_time_lonely_code 
			/* Scales flipped between 2014 & 2016  and other waves and now in gss_supp_2014 table */    
			when 11 then 15    when 12 then 14     when 14 then 12     when 15 then 11    else pers.gss_pq_time_lonely_code  end as gss_pq_time_lonely_code  
			,NULL AS env_water_bodies /*environment*/   
			,NULL AS env_access_bush /*environment*/   
			,NULL AS env_state_bush /*environment*/   
			,cast(pers.gss_pq_life_worthwhile_code as smallint) AS purpose_sense
			,pers.gss_pq_feel_life_code  
			,pers.gss_pq_bedroom_nbr as house_brm
			,pers.gss_pq_inc_selfemp_dev  AS inc_self  
			,[gss_pq_person_SeInWgt_nbr]   as gss_pq_person_SeInWgt
			,[gss_pq_person_FinalWgt_nbr]   as gss_pq_person_FinalWgt
			,[gss_pq_person_FinalWgt1_nbr]   as  gss_pq_person_FinalWgt1
			,[gss_pq_person_FinalWgt2_nbr]   as  gss_pq_person_FinalWgt2
			,[gss_pq_person_FinalWgt3_nbr]   as  gss_pq_person_FinalWgt3
			,[gss_pq_person_FinalWgt4_nbr]   as  gss_pq_person_FinalWgt4
			,[gss_pq_person_FinalWgt5_nbr]   as  gss_pq_person_FinalWgt5
			,[gss_pq_person_FinalWgt6_nbr]   as  gss_pq_person_FinalWgt6
			,[gss_pq_person_FinalWgt7_nbr]   as  gss_pq_person_FinalWgt7
			,[gss_pq_person_FinalWgt8_nbr]   as  gss_pq_person_FinalWgt8
			,[gss_pq_person_FinalWgt9_nbr]   as  gss_pq_person_FinalWgt9
			,[gss_pq_person_FinalWgt10_nbr]   as  gss_pq_person_FinalWgt10
			,[gss_pq_person_FinalWgt11_nbr]   as  gss_pq_person_FinalWgt11
			,[gss_pq_person_FinalWgt12_nbr]   as  gss_pq_person_FinalWgt12
			,[gss_pq_person_FinalWgt13_nbr]   as  gss_pq_person_FinalWgt13
			,[gss_pq_person_FinalWgt14_nbr]   as  gss_pq_person_FinalWgt14
			,[gss_pq_person_FinalWgt15_nbr]   as  gss_pq_person_FinalWgt15
			,[gss_pq_person_FinalWgt16_nbr]   as  gss_pq_person_FinalWgt16
			,[gss_pq_person_FinalWgt17_nbr]   as  gss_pq_person_FinalWgt17
			,[gss_pq_person_FinalWgt18_nbr]   as  gss_pq_person_FinalWgt18
			,[gss_pq_person_FinalWgt19_nbr]   as  gss_pq_person_FinalWgt19
			,[gss_pq_person_FinalWgt20_nbr]   as  gss_pq_person_FinalWgt20
			,[gss_pq_person_FinalWgt21_nbr]   as  gss_pq_person_FinalWgt21
			,[gss_pq_person_FinalWgt22_nbr]   as  gss_pq_person_FinalWgt22
			,[gss_pq_person_FinalWgt23_nbr]   as  gss_pq_person_FinalWgt23
			,[gss_pq_person_FinalWgt24_nbr]   as  gss_pq_person_FinalWgt24
			,[gss_pq_person_FinalWgt25_nbr]   as  gss_pq_person_FinalWgt25
			,[gss_pq_person_FinalWgt26_nbr]   as  gss_pq_person_FinalWgt26
			,[gss_pq_person_FinalWgt27_nbr]   as  gss_pq_person_FinalWgt27
			,[gss_pq_person_FinalWgt28_nbr]   as  gss_pq_person_FinalWgt28
			,[gss_pq_person_FinalWgt29_nbr]   as  gss_pq_person_FinalWgt29
			,[gss_pq_person_FinalWgt30_nbr]   as  gss_pq_person_FinalWgt30
			,[gss_pq_person_FinalWgt31_nbr]   as  gss_pq_person_FinalWgt31
			,[gss_pq_person_FinalWgt32_nbr]   as  gss_pq_person_FinalWgt32
			,[gss_pq_person_FinalWgt33_nbr]   as  gss_pq_person_FinalWgt33
			,[gss_pq_person_FinalWgt34_nbr]   as  gss_pq_person_FinalWgt34
			,[gss_pq_person_FinalWgt35_nbr]   as  gss_pq_person_FinalWgt35
			,[gss_pq_person_FinalWgt36_nbr]   as  gss_pq_person_FinalWgt36
			,[gss_pq_person_FinalWgt37_nbr]   as  gss_pq_person_FinalWgt37
			,[gss_pq_person_FinalWgt38_nbr]   as  gss_pq_person_FinalWgt38
			,[gss_pq_person_FinalWgt39_nbr]   as  gss_pq_person_FinalWgt39
			,[gss_pq_person_FinalWgt40_nbr]   as  gss_pq_person_FinalWgt40
			,[gss_pq_person_FinalWgt41_nbr]   as  gss_pq_person_FinalWgt41
			,[gss_pq_person_FinalWgt42_nbr]   as  gss_pq_person_FinalWgt42
			,[gss_pq_person_FinalWgt43_nbr]   as  gss_pq_person_FinalWgt43
			,[gss_pq_person_FinalWgt44_nbr]   as  gss_pq_person_FinalWgt44
			,[gss_pq_person_FinalWgt45_nbr]   as  gss_pq_person_FinalWgt45
			,[gss_pq_person_FinalWgt46_nbr]   as  gss_pq_person_FinalWgt46
			,[gss_pq_person_FinalWgt47_nbr]   as  gss_pq_person_FinalWgt47
			,[gss_pq_person_FinalWgt48_nbr]   as  gss_pq_person_FinalWgt48
			,[gss_pq_person_FinalWgt49_nbr]   as  gss_pq_person_FinalWgt49
			,[gss_pq_person_FinalWgt50_nbr]   as  gss_pq_person_FinalWgt50
			,[gss_pq_person_FinalWgt51_nbr]   as  gss_pq_person_FinalWgt51
			,[gss_pq_person_FinalWgt52_nbr]   as  gss_pq_person_FinalWgt52
			,[gss_pq_person_FinalWgt53_nbr]   as  gss_pq_person_FinalWgt53
			,[gss_pq_person_FinalWgt54_nbr]   as  gss_pq_person_FinalWgt54
			,[gss_pq_person_FinalWgt55_nbr]   as  gss_pq_person_FinalWgt55
			,[gss_pq_person_FinalWgt56_nbr]   as  gss_pq_person_FinalWgt56
			,[gss_pq_person_FinalWgt57_nbr]   as  gss_pq_person_FinalWgt57
			,[gss_pq_person_FinalWgt58_nbr]   as  gss_pq_person_FinalWgt58
			,[gss_pq_person_FinalWgt59_nbr]   as  gss_pq_person_FinalWgt59
			,[gss_pq_person_FinalWgt60_nbr]   as  gss_pq_person_FinalWgt60
			,[gss_pq_person_FinalWgt61_nbr]   as  gss_pq_person_FinalWgt61
			,[gss_pq_person_FinalWgt62_nbr]   as  gss_pq_person_FinalWgt62
			,[gss_pq_person_FinalWgt63_nbr]   as  gss_pq_person_FinalWgt63
			,[gss_pq_person_FinalWgt64_nbr]   as  gss_pq_person_FinalWgt64
			,[gss_pq_person_FinalWgt65_nbr]   as  gss_pq_person_FinalWgt65
			,[gss_pq_person_FinalWgt66_nbr]   as  gss_pq_person_FinalWgt66
			,[gss_pq_person_FinalWgt67_nbr]   as  gss_pq_person_FinalWgt67
			,[gss_pq_person_FinalWgt68_nbr]   as  gss_pq_person_FinalWgt68
			,[gss_pq_person_FinalWgt69_nbr]   as  gss_pq_person_FinalWgt69
			,[gss_pq_person_FinalWgt70_nbr]   as  gss_pq_person_FinalWgt70
			,[gss_pq_person_FinalWgt71_nbr]   as  gss_pq_person_FinalWgt71
			,[gss_pq_person_FinalWgt72_nbr]   as  gss_pq_person_FinalWgt72
			,[gss_pq_person_FinalWgt73_nbr]   as  gss_pq_person_FinalWgt73
			,[gss_pq_person_FinalWgt74_nbr]   as  gss_pq_person_FinalWgt74
			,[gss_pq_person_FinalWgt75_nbr]   as  gss_pq_person_FinalWgt75
			,[gss_pq_person_FinalWgt76_nbr]   as  gss_pq_person_FinalWgt76
			,[gss_pq_person_FinalWgt77_nbr]   as  gss_pq_person_FinalWgt77
			,[gss_pq_person_FinalWgt78_nbr]   as  gss_pq_person_FinalWgt78
			,[gss_pq_person_FinalWgt79_nbr]   as  gss_pq_person_FinalWgt79
			,[gss_pq_person_FinalWgt80_nbr]   as  gss_pq_person_FinalWgt80
			,[gss_pq_person_FinalWgt81_nbr]   as  gss_pq_person_FinalWgt81
			,[gss_pq_person_FinalWgt82_nbr]   as  gss_pq_person_FinalWgt82
			,[gss_pq_person_FinalWgt83_nbr]   as  gss_pq_person_FinalWgt83
			,[gss_pq_person_FinalWgt84_nbr]   as  gss_pq_person_FinalWgt84
			,[gss_pq_person_FinalWgt85_nbr]   as  gss_pq_person_FinalWgt85
			,[gss_pq_person_FinalWgt86_nbr]   as  gss_pq_person_FinalWgt86
			,[gss_pq_person_FinalWgt87_nbr]   as  gss_pq_person_FinalWgt87
			,[gss_pq_person_FinalWgt88_nbr]   as  gss_pq_person_FinalWgt88
			,[gss_pq_person_FinalWgt89_nbr]   as  gss_pq_person_FinalWgt89
			,[gss_pq_person_FinalWgt90_nbr]   as  gss_pq_person_FinalWgt90
			,[gss_pq_person_FinalWgt91_nbr]   as  gss_pq_person_FinalWgt91
			,[gss_pq_person_FinalWgt92_nbr]   as  gss_pq_person_FinalWgt92
			,[gss_pq_person_FinalWgt93_nbr]   as  gss_pq_person_FinalWgt93
			,[gss_pq_person_FinalWgt94_nbr]   as  gss_pq_person_FinalWgt94
			,[gss_pq_person_FinalWgt95_nbr]   as  gss_pq_person_FinalWgt95
			,[gss_pq_person_FinalWgt96_nbr]   as  gss_pq_person_FinalWgt96
			,[gss_pq_person_FinalWgt97_nbr]   as  gss_pq_person_FinalWgt97
			,[gss_pq_person_FinalWgt98_nbr]   as  gss_pq_person_FinalWgt98
			,[gss_pq_person_FinalWgt99_nbr]   as  gss_pq_person_FinalWgt99
			,[gss_pq_person_FinalWgt100_nbr] as  gss_pq_person_FinalWgt100
		from &idi_version..gss_clean.gss_person pers 
		inner join &idi_version..data.personal_detail pers_det on (pers.snz_uid = pers_det.snz_uid)
		inner join IDI_Sandpit.[&si_proj_schema.].of_gss_hh_variables_mh hhld 
			on (pers.snz_uid = hhld.snz_uid and pers.gss_pq_collection_code = hhld.gss_id_collection_code)
		/*			Modified for 2018 refresh*/
		inner join &idi_version..gss_clean.gss_household devfam
			on (pers.snz_uid = devfam.snz_uid and pers.gss_pq_collection_code = devfam.gss_hq_collection_code)
		inner join &idi_version..gss_clean.gss_supp_2014 sup on (pers.snz_uid = sup.snz_uid)
		where pers.gss_pq_collection_code = 'GSS2014'

		union all

		select 
			pers.snz_uid 
			,pers.snz_gss_hhld_uid 
			,pers_det.snz_spine_ind 
			,pers.gss_pq_collection_code as gss_id_collection_code 
			,cast([gss_pq_interview_start_date] as datetime) as gss_pq_interview_date 
			,hhld.gss_hq_interview_start_date as gss_hq_interview_date
			,hhld.gss_hq_sex_dev 
			,hhld.gss_hq_birth_month_nbr 
			,hhld.gss_hq_birth_year_nbr 
			,pers.gss_pq_CORDV9 as gss_pq_dvage_code  
			,pers.gss_pq_CORDV3_ASIAN AS P_ASIAN 
			,pers.gss_pq_CORDV3_EURO AS P_EURO 
			,pers.gss_pq_CORDV3_MAORI AS P_MAORI 
			,pers.gss_pq_CORDV3_MELAA AS P_MELAA 
			,pers.gss_pq_CORDV3_OTHER AS P_OTHER 
			,pers.gss_pq_CORDV3_PP AS P_PACIFIC 
			,case when cast(pers.gss_pq_CORPQ15 as smallint) in (88, 99) then NULL else cast(pers.gss_pq_CORPQ15 as smallint) end AS maori_desc 
			,pers.gss_pq_CORPQ11 AS nz_born 
			,pers.gss_pq_CORPQ13 AS nz_arrive_year 
			,pers.gss_pq_CORPQ14 AS nz_arrive_month 
			,gss_pq_reg_council_08_code as gss_hq_regcouncil_dev
			,pers.gss_pq_CORDV1 AS married 
			,pers.[gss_pq_CORDV4] as gss_pq_HH_comp_code  
			,case when cast(gss_pq_CORDV5 as smallint) = 77 then NULL else cast(gss_pq_CORDV5 as smallint) end as gss_hq_dep_child_dev
			,pers.gss_pq_CORDV2 AS fam_type 
			,hhld.family_nuclei_ct 
			,hhld.nonfamily_nuclei_ct        
			,hhld.family_size_adult  
			,hhld.family_size_child   
			,NULL as family_size_depchild
			,NULL as family_size_indepchild
			,case when hhld.gss_hq_house_trust  in (88, 99) then NULL else hhld.gss_hq_house_trust end as gss_hq_house_trust
			,case when hhld.gss_hq_house_own   in (88, 99) then NULL else hhld.gss_hq_house_own end as gss_hq_house_own
			,case when hhld.gss_hq_house_pay_mort_code in (88, 99) then NULL else hhld.gss_hq_house_pay_mort_code end as gss_hq_house_pay_mort_code  
			,case when hhld.gss_hq_house_pay_rent_code  in (88, 99) then NULL else hhld.gss_hq_house_pay_rent_code end as gss_hq_house_pay_rent_code
			,case when hhld.gss_hq_house_who_owns_code  in (88, 99) then NULL else hhld.gss_hq_house_who_owns_code end as gss_hq_house_who_owns_code
			,pers.gss_pq_CORDV16 AS gss_pq_HH_tenure_code  
			,cast(pers.gss_pq_HOUDV2 as smallint) as gss_pq_HH_crowd_code 
			,coalesce(cast(pers.gss_pq_HOUQ03_14 as smallint), 0) as gss_pq_house_mold_code 
			,coalesce(cast(pers.gss_pq_HOUQ03_15 as smallint), 0) as gss_pq_house_cold_code 
			,NULL as gss_pq_house_condition_code20146
			,cast(pers.gss_pq_HOUQ03_13 as smallint) as gss_pq_house_condition_code 
			,cast(pers.gss_pq_HOUQ01 as smallint) as housing_satisfaction 
			,pers.gss_pq_HOUQ04_14 as gss_pq_prob_hood_noisy_ind 
			,pers.gss_pq_SAFQ01C as gss_pq_safe_night_pub_trans_code
			,pers.gss_pq_SAFQ01E as gss_pq_safe_night_hood_code 
			,pers.gss_pq_SAFQ01D as gss_pq_safe_day_hood_code 
			,cast(pers.gss_pq_SAFQ02 as smallint) as gss_pq_crimes_against_ind /* Slightly different wording (re traffic incidents) */ 
			,cast(hhld.gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev
			,hhld.hh_gss_income
			,hhld.hh_gss_income_median
			,hhld.hh_gss_income_lower
			,hhld.hh_gss_income_upper
			,hhld.housing_status
			,cast(pers.gss_pq_CORDV14 as smallint) as gss_pq_lfs_dev 
			,case when coalesce(gss_pq_CORDV8_17,0) =1  then 1 else 0 end as gss_unemp_jobseek  
			,case when coalesce(gss_pq_CORDV8_18,0)  = 1 then 1 else 0 end as gss_sickness 
			,case when coalesce(gss_pq_CORDV8_20,0) =1  then 1 else 0 end as gss_invalid_support 
			,case when coalesce(gss_pq_CORDV8_19,0) = 1 then 1 else 0 end as gss_soleprnt_domestic 
			,case when coalesce(gss_pq_CORDV8_22,0)  = 1 then 1 else 0 end as gss_oth_ben 
			,case when coalesce(gss_pq_CORDV8_24,0)  = 1 then 1 else 0 end as gss_no_income 
			,NULL as gss_pq_material_wellbeing_code 
			,case when cast(gss_pq_ELSIDV1 as smallint) between 0 and 31  then cast(gss_pq_ELSIDV1 as smallint) else NULL end as gss_pq_ELSIDV1 
			,[gss_pq_ELSQ05A] AS gss_pq_cost_down_vege_code 
			,[gss_pq_ELSQ05E] AS gss_pq_cost_down_dr_code 
			,[gss_pq_ELSQ05H] AS gss_pq_cost_down_shop_code 
			,NULL AS gss_pq_cost_down_hobby_code 
			,NULL AS gss_pq_cost_down_cold_code 
			,NULL AS gss_pq_cost_down_appliance_code 
			,NULL AS gss_pq_buy_shoes_limit_code 
			,NULL AS gss_pq_item_300_limit_code 
			,NULL AS gss_pq_not_pay_bills_time_code 
			,[gss_pq_ELSQ08] AS gss_pq_enough_inc_code 
			,pers.gss_pq_WORDV2 AS work_hrs 
			,pers.gss_pq_WORQ01 AS work_jobs_no 
			,pers.gss_pq_WORQ07 AS work_satisfaction 
			,pers.gss_pq_WORDV3 AS work_ft_pt 
			,pers.gss_pq_CORPQ22 AS work_now_ind 
			,case when pers.gss_pq_CORPQ25 in (88,99) then NULL else pers.gss_pq_CORPQ25 end AS work_start_ind
			,case when pers.gss_pq_CORPQ26 in (88, 99) then NULL else pers.gss_pq_CORPQ26 end  AS work_look_ind 
			,case when pers.gss_pq_CORPQ28 in (88, 99) then NULL else pers.gss_pq_CORPQ28 end AS work_could_start 
			,pers.gss_pq_CORPQ16 AS school_highest 
			,cast(pers.gss_pq_CORDV15 as smallint) as gss_pq_highest_qual_dev 
			,pers.gss_pq_CORPQ21 AS qual_yr 
			,case when pers.gss_pq_HEAQ01 in (88, 99) then NULL else pers.gss_pq_HEAQ01 end AS health_status 
			,case when pers.gss_pq_HEAQ02a  in (88, 99) then NULL else pers.gss_pq_HEAQ02a end  AS health_limit_activ 
			,case when pers.gss_pq_HEAQ02b  in (88, 99) then NULL else pers.gss_pq_HEAQ02b end AS health_limit_stair 
			,pers.gss_pq_HEAQ03 AS health_accomplish_phys 
			,pers.gss_pq_HEAQ04 AS health_work_phys 
			,pers.gss_pq_HEAQ05 AS health_accomplish_emo 
			,pers.gss_pq_HEAQ06 AS health_work_emo 
			,pers.gss_pq_HEAQ07 AS health_pain 
			,pers.gss_pq_HEAQ08a AS health_calm 
			,pers.gss_pq_HEAQ08b AS health_energy 
			,pers.gss_pq_HEAQ08c AS health_depressed 
			,pers.gss_pq_HEAQ09 AS health_social 
			,cast(pers.gss_pq_HEADV2 as smallint) as gss_pq_ment_health_code 
			,cast(pers.gss_pq_HEADV3 as smallint) as gss_pq_phys_health_code 
			,pers.gss_pq_CULQ04 as gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different)*/ 
			,[gss_pq_CULQ01] AS belong 
			,NULL AS belong_2016
			,NULL AS discrim_status 
			,NULL AS discrim_shop    
			,NULL AS discrim_work 
			,NULL AS discrim_public 
			,NULL AS discrim_school 
			,NULL AS discrim_job 
			,NULL AS discrim_police 
			,NULL AS discrim_medic 
			,NULL AS discrim_other 
			,NULL AS discrim_dk 
			,NULL AS discrim_nr 
			,coalesce(pers.gss_pq_HUMQ07_19,0) as gss_pq_discrim_rent_ind /* 2012 question is about "applying for or keeping a house/flat". Probably too small to worry about */ 
			,[gss_pq_LEIQ01] AS leisure_time 
			,pers.gss_pq_HUMQ01 as gss_pq_voting /* not in 2014 (just made up a var name) */ 
			,[gss_pq_SOCQ15] AS volunteer 
			,NULL AS trust_police 
			,NULL AS trust_education 
			,NULL AS trust_media  
			,NULL AS trust_courts 
			,NULL AS trust_parliament 
			,NULL AS trust_health
			,NULL AS generalised_trust 
			,pers.gss_pq_SOCQ11 as gss_pq_time_lonely_code /* Scales flipped between 2014 and rest. Prioritise over 'help who'*/ 
			,[gss_pq_PHYQ12] AS env_water_bodies /*environment*/   
			,[gss_pq_PHYQ13]  AS env_access_bush /*environment*/   
			,[gss_pq_PHYQ14] AS env_state_bush /*environment*/   
			,NULL AS purpose_sense 
			,pers.gss_pq_OLSQ01 as gss_pq_feel_life_code 
			,pers.gss_pq_HOUQ02 AS house_brm
			,pers.gss_pq_CORDV8_12 AS inc_self 
			,[gss_pq_PersonGSSSelectionWeight] as gss_pq_person_SeInWgt
			,[gss_pq_PersonGSSFinalweight] as gss_pq_person_FinalWgt
			,[gss_pq_PersonGSSFinalWeight_1] as gss_pq_person_FinalWgt1
			,[gss_pq_PersonGSSFinalWeight_2] as gss_pq_person_FinalWgt2
			,[gss_pq_PersonGSSFinalWeight_3] as gss_pq_person_FinalWgt3
			,[gss_pq_PersonGSSFinalWeight_4] as gss_pq_person_FinalWgt4
			,[gss_pq_PersonGSSFinalWeight_5] as gss_pq_person_FinalWgt5
			,[gss_pq_PersonGSSFinalWeight_6] as gss_pq_person_FinalWgt6
			,[gss_pq_PersonGSSFinalWeight_7] as gss_pq_person_FinalWgt7
			,[gss_pq_PersonGSSFinalWeight_8] as gss_pq_person_FinalWgt8
			,[gss_pq_PersonGSSFinalWeight_9] as gss_pq_person_FinalWgt9
			,[gss_pq_PersonGSSFinalWeight_10] as gss_pq_person_FinalWgt10
			,[gss_pq_PersonGSSFinalWeight_11] as gss_pq_person_FinalWgt11
			,[gss_pq_PersonGSSFinalWeight_12] as gss_pq_person_FinalWgt12
			,[gss_pq_PersonGSSFinalWeight_13] as gss_pq_person_FinalWgt13
			,[gss_pq_PersonGSSFinalWeight_14] as gss_pq_person_FinalWgt14
			,[gss_pq_PersonGSSFinalWeight_15] as gss_pq_person_FinalWgt15
			,[gss_pq_PersonGSSFinalWeight_16] as gss_pq_person_FinalWgt16
			,[gss_pq_PersonGSSFinalWeight_17] as gss_pq_person_FinalWgt17
			,[gss_pq_PersonGSSFinalWeight_18] as gss_pq_person_FinalWgt18
			,[gss_pq_PersonGSSFinalWeight_19] as gss_pq_person_FinalWgt19
			,[gss_pq_PersonGSSFinalWeight_20] as gss_pq_person_FinalWgt20
			,[gss_pq_PersonGSSFinalWeight_21] as gss_pq_person_FinalWgt21
			,[gss_pq_PersonGSSFinalWeight_22] as gss_pq_person_FinalWgt22
			,[gss_pq_PersonGSSFinalWeight_23] as gss_pq_person_FinalWgt23
			,[gss_pq_PersonGSSFinalWeight_24] as gss_pq_person_FinalWgt24
			,[gss_pq_PersonGSSFinalWeight_25] as gss_pq_person_FinalWgt25
			,[gss_pq_PersonGSSFinalWeight_26] as gss_pq_person_FinalWgt26
			,[gss_pq_PersonGSSFinalWeight_27] as gss_pq_person_FinalWgt27
			,[gss_pq_PersonGSSFinalWeight_28] as gss_pq_person_FinalWgt28
			,[gss_pq_PersonGSSFinalWeight_29] as gss_pq_person_FinalWgt29
			,[gss_pq_PersonGSSFinalWeight_30] as gss_pq_person_FinalWgt30
			,[gss_pq_PersonGSSFinalWeight_31] as gss_pq_person_FinalWgt31
			,[gss_pq_PersonGSSFinalWeight_32] as gss_pq_person_FinalWgt32
			,[gss_pq_PersonGSSFinalWeight_33] as gss_pq_person_FinalWgt33
			,[gss_pq_PersonGSSFinalWeight_34] as gss_pq_person_FinalWgt34
			,[gss_pq_PersonGSSFinalWeight_35] as gss_pq_person_FinalWgt35
			,[gss_pq_PersonGSSFinalWeight_36] as gss_pq_person_FinalWgt36
			,[gss_pq_PersonGSSFinalWeight_37] as gss_pq_person_FinalWgt37
			,[gss_pq_PersonGSSFinalWeight_38] as gss_pq_person_FinalWgt38
			,[gss_pq_PersonGSSFinalWeight_39] as gss_pq_person_FinalWgt39
			,[gss_pq_PersonGSSFinalWeight_40] as gss_pq_person_FinalWgt40
			,[gss_pq_PersonGSSFinalWeight_41] as gss_pq_person_FinalWgt41
			,[gss_pq_PersonGSSFinalWeight_42] as gss_pq_person_FinalWgt42
			,[gss_pq_PersonGSSFinalWeight_43] as gss_pq_person_FinalWgt43
			,[gss_pq_PersonGSSFinalWeight_44] as gss_pq_person_FinalWgt44
			,[gss_pq_PersonGSSFinalWeight_45] as gss_pq_person_FinalWgt45
			,[gss_pq_PersonGSSFinalWeight_46] as gss_pq_person_FinalWgt46
			,[gss_pq_PersonGSSFinalWeight_47] as gss_pq_person_FinalWgt47
			,[gss_pq_PersonGSSFinalWeight_48] as gss_pq_person_FinalWgt48
			,[gss_pq_PersonGSSFinalWeight_49] as gss_pq_person_FinalWgt49
			,[gss_pq_PersonGSSFinalWeight_50] as gss_pq_person_FinalWgt50
			,[gss_pq_PersonGSSFinalWeight_51] as gss_pq_person_FinalWgt51
			,[gss_pq_PersonGSSFinalWeight_52] as gss_pq_person_FinalWgt52
			,[gss_pq_PersonGSSFinalWeight_53] as gss_pq_person_FinalWgt53
			,[gss_pq_PersonGSSFinalWeight_54] as gss_pq_person_FinalWgt54
			,[gss_pq_PersonGSSFinalWeight_55] as gss_pq_person_FinalWgt55
			,[gss_pq_PersonGSSFinalWeight_56] as gss_pq_person_FinalWgt56
			,[gss_pq_PersonGSSFinalWeight_57] as gss_pq_person_FinalWgt57
			,[gss_pq_PersonGSSFinalWeight_58] as gss_pq_person_FinalWgt58
			,[gss_pq_PersonGSSFinalWeight_59] as gss_pq_person_FinalWgt59
			,[gss_pq_PersonGSSFinalWeight_60] as gss_pq_person_FinalWgt60
			,[gss_pq_PersonGSSFinalWeight_61] as gss_pq_person_FinalWgt61
			,[gss_pq_PersonGSSFinalWeight_62] as gss_pq_person_FinalWgt62
			,[gss_pq_PersonGSSFinalWeight_63] as gss_pq_person_FinalWgt63
			,[gss_pq_PersonGSSFinalWeight_64] as gss_pq_person_FinalWgt64
			,[gss_pq_PersonGSSFinalWeight_65] as gss_pq_person_FinalWgt65
			,[gss_pq_PersonGSSFinalWeight_66] as gss_pq_person_FinalWgt66
			,[gss_pq_PersonGSSFinalWeight_67] as gss_pq_person_FinalWgt67
			,[gss_pq_PersonGSSFinalWeight_68] as gss_pq_person_FinalWgt68
			,[gss_pq_PersonGSSFinalWeight_69] as gss_pq_person_FinalWgt69
			,[gss_pq_PersonGSSFinalWeight_70] as gss_pq_person_FinalWgt70
			,[gss_pq_PersonGSSFinalWeight_71] as gss_pq_person_FinalWgt71
			,[gss_pq_PersonGSSFinalWeight_72] as gss_pq_person_FinalWgt72
			,[gss_pq_PersonGSSFinalWeight_73] as gss_pq_person_FinalWgt73
			,[gss_pq_PersonGSSFinalWeight_74] as gss_pq_person_FinalWgt74
			,[gss_pq_PersonGSSFinalWeight_75] as gss_pq_person_FinalWgt75
			,[gss_pq_PersonGSSFinalWeight_76] as gss_pq_person_FinalWgt76
			,[gss_pq_PersonGSSFinalWeight_77] as gss_pq_person_FinalWgt77
			,[gss_pq_PersonGSSFinalWeight_78] as gss_pq_person_FinalWgt78
			,[gss_pq_PersonGSSFinalWeight_79] as gss_pq_person_FinalWgt79
			,[gss_pq_PersonGSSFinalWeight_80] as gss_pq_person_FinalWgt80
			,[gss_pq_PersonGSSFinalWeight_81] as gss_pq_person_FinalWgt81
			,[gss_pq_PersonGSSFinalWeight_82] as gss_pq_person_FinalWgt82
			,[gss_pq_PersonGSSFinalWeight_83] as gss_pq_person_FinalWgt83
			,[gss_pq_PersonGSSFinalWeight_84] as gss_pq_person_FinalWgt84
			,[gss_pq_PersonGSSFinalWeight_85] as gss_pq_person_FinalWgt85
			,[gss_pq_PersonGSSFinalWeight_86] as gss_pq_person_FinalWgt86
			,[gss_pq_PersonGSSFinalWeight_87] as gss_pq_person_FinalWgt87
			,[gss_pq_PersonGSSFinalWeight_88] as gss_pq_person_FinalWgt88
			,[gss_pq_PersonGSSFinalWeight_89] as gss_pq_person_FinalWgt89
			,[gss_pq_PersonGSSFinalWeight_90] as gss_pq_person_FinalWgt90
			,[gss_pq_PersonGSSFinalWeight_91] as gss_pq_person_FinalWgt91
			,[gss_pq_PersonGSSFinalWeight_92] as gss_pq_person_FinalWgt92
			,[gss_pq_PersonGSSFinalWeight_93] as gss_pq_person_FinalWgt93
			,[gss_pq_PersonGSSFinalWeight_94] as gss_pq_person_FinalWgt94
			,[gss_pq_PersonGSSFinalWeight_95] as gss_pq_person_FinalWgt95
			,[gss_pq_PersonGSSFinalWeight_96] as gss_pq_person_FinalWgt96
			,[gss_pq_PersonGSSFinalWeight_97] as gss_pq_person_FinalWgt97
			,[gss_pq_PersonGSSFinalWeight_98] as gss_pq_person_FinalWgt98
			,[gss_pq_PersonGSSFinalWeight_99] as gss_pq_person_FinalWgt99
			,[gss_pq_PersonGSSFinalWeight_100] as gss_pq_person_FinalWgt100
		from &idi_version..gss_clean.gss_person_2012 pers 
		inner join &idi_version..data.personal_detail pers_det on (pers.snz_uid = pers_det.snz_uid)
		inner join IDI_Sandpit.[&si_proj_schema.].of_gss_hh_variables_mh hhld 
			on (pers.snz_uid = hhld.snz_uid and pers.gss_pq_collection_code = hhld.gss_id_collection_code)


		union all

		select 
			pers.snz_uid 
			,pers.snz_gss_hhld_uid 
			,pers_det.snz_spine_ind 
			,pers.gss_pq_collection_code as gss_id_collection_code 
			,cast([gss_pq_interview_start_date] as datetime) as gss_pq_interview_date 
			,hhld.gss_hq_interview_start_date as gss_hq_interview_date
			,hhld.gss_hq_sex_dev 
			,hhld.gss_hq_birth_month_nbr 
			,hhld.gss_hq_birth_year_nbr 
			,pers.gss_pq_CORDV9 as gss_pq_dvage_code  
			,pers.gss_pq_CORDV3_ASIAN AS P_ASIAN 
			,pers.gss_pq_CORDV3_EURO AS P_EURO 
			,pers.gss_pq_CORDV3_MAORI AS P_MAORI 
			,pers.gss_pq_CORDV3_MELAA AS P_MELAA 
			,pers.gss_pq_CORDV3_OTHER AS P_OTHER 
			,pers.gss_pq_CORDV3_PP AS P_PACIFIC 
			,case when cast(pers.gss_pq_CORPQ15 as smallint) in (88, 99) then NULL else cast(pers.gss_pq_CORPQ15 as smallint) end AS maori_desc 
			,pers.gss_pq_CORPQ11 AS nz_born 
			,pers.gss_pq_CORPQ13 AS nz_arrive_year 
			,pers.gss_pq_CORPQ14 AS nz_arrive_month 
			,gss_pq_reg_council_08_code as gss_hq_regcouncil_dev
			,pers.gss_pq_CORDV1 AS married 
			,pers.[gss_pq_CORDV4] as gss_pq_HH_comp_code  
			,case when cast(gss_pq_CORDV5 as smallint) = 77 then NULL else cast(gss_pq_CORDV5 as smallint) end as gss_hq_dep_child_dev
			,pers.gss_pq_CORDV2 AS fam_type 
			,hhld.family_nuclei_ct 
			,hhld.nonfamily_nuclei_ct        
			,hhld.family_size_adult  
			,hhld.family_size_child   
			,NULL as family_size_depchild
			,NULL as family_size_indepchild
			,case when hhld.gss_hq_house_trust  in (88, 99) then NULL else hhld.gss_hq_house_trust end as gss_hq_house_trust
			,case when hhld.gss_hq_house_own   in (88, 99) then NULL else hhld.gss_hq_house_own end as gss_hq_house_own
			,case when hhld.gss_hq_house_pay_mort_code in (88, 99) then NULL else hhld.gss_hq_house_pay_mort_code end as gss_hq_house_pay_mort_code  
			,case when hhld.gss_hq_house_pay_rent_code  in (88, 99) then NULL else hhld.gss_hq_house_pay_rent_code end as gss_hq_house_pay_rent_code
			,case when hhld.gss_hq_house_who_owns_code  in (88, 99) then NULL else hhld.gss_hq_house_who_owns_code end as gss_hq_house_who_owns_code
			,case when pers.gss_pq_CORDV16 in ('88','99') then '77' else pers.gss_pq_CORDV16 end as  gss_pq_HH_tenure_code  
			,cast(pers.gss_pq_HOUDV2 as smallint) as gss_pq_HH_crowd_code 
			,coalesce(cast(pers.gss_pq_HOUQ03_14 as smallint), 0) as gss_pq_house_mold_code 
			,coalesce(cast(pers.gss_pq_HOUQ03_15 as smallint), 0) as gss_pq_house_cold_code 
			,NULL as gss_pq_house_condition_code20146
			,cast(pers.gss_pq_HOUQ03_13 as smallint) as gss_pq_house_condition_code 
			,cast(pers.gss_pq_HOUQ01 as smallint) as housing_satisfaction 
			,pers.gss_pq_HOUQ04_14 as gss_pq_prob_hood_noisy_ind 
			,pers.gss_pq_SAFQ01C as gss_pq_safe_night_pub_trans_code
			,pers.gss_pq_SAFQ01E as gss_pq_safe_night_hood_code
			,pers.gss_pq_SAFQ01D as gss_pq_safe_day_hood_code
			,cast(pers.gss_pq_SAFQ02 as smallint) as gss_pq_crimes_against_ind /* Slightly different wording (re traffic incidents)*/ 
			,cast(hhld.gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev 
			,hhld.hh_gss_income
			,hhld.hh_gss_income_median
			,hhld.hh_gss_income_lower
			,hhld.hh_gss_income_upper
			,hhld.housing_status
			,cast(pers.gss_pq_CORDV14 as smallint) as gss_pq_lfs_dev 
			,case when coalesce(gss_pq_CORDV8_17,0) =1  then 1 else 0 end as gss_unemp_jobseek  
			,case when coalesce(gss_pq_CORDV8_18,0)  = 1 then 1 else 0 end as gss_sickness 
			,case when coalesce(gss_pq_CORDV8_20,0) =1  then 1 else 0 end as gss_invalid_support 
			,case when coalesce(gss_pq_CORDV8_19,0) = 1 then 1 else 0 end as gss_soleprnt_domestic 
			,case when coalesce(gss_pq_CORDV8_22,0)  = 1 then 1 else 0 end as gss_oth_ben 
			,case when coalesce(gss_pq_CORDV8_24,0)  = 1 then 1 else 0 end as gss_no_income 
			,NULL as gss_pq_material_wellbeing_code 
			,case when cast(gss_pq_ELSIDV1 as smallint) between 0 and 31 then cast(gss_pq_ELSIDV1 as smallint) else NULL end as gss_pq_ELSIDV1 
			,[gss_pq_ELSQ05A] AS gss_pq_cost_down_vege_code 
			,[gss_pq_ELSQ05E] AS gss_pq_cost_down_dr_code 
			,[gss_pq_ELSQ05H] AS gss_pq_cost_down_shop_code 
			,NULL AS gss_pq_cost_down_hobby_code 
			,NULL AS gss_pq_cost_down_cold_code 
			,NULL AS gss_pq_cost_down_appliance_code 
			,NULL AS gss_pq_buy_shoes_limit_code 
			,NULL AS gss_pq_item_300_limit_code 
			,NULL AS gss_pq_not_pay_bills_time_code 
			,[gss_pq_ELSQ08] AS gss_pq_enough_inc_code
			,pers.gss_pq_WORDV2 AS work_hrs 
			,pers.gss_pq_WORQ01 AS work_jobs_no 
			,pers.gss_pq_WORQ07 AS work_satisfaction 
			,pers.gss_pq_WORDV3 AS work_ft_pt 
			,pers.gss_pq_CORPQ22 AS work_now_ind 
			,case when pers.gss_pq_CORPQ25 in (88,99) then NULL else pers.gss_pq_CORPQ25 end AS work_start_ind
			,case when pers.gss_pq_CORPQ26 in (88, 99) then NULL else pers.gss_pq_CORPQ26 end  AS work_look_ind 
			,case when pers.gss_pq_CORPQ28 in (88, 99) then NULL else pers.gss_pq_CORPQ28 end AS work_could_start 
			,pers.gss_pq_CORPQ16 AS school_highest 
			,cast(pers.gss_pq_CORDV15 as smallint) as gss_pq_highest_qual_dev 
			,pers.gss_pq_CORPQ21 AS qual_yr 
			,case when pers.gss_pq_HEAQ01 in (88, 99) then NULL else pers.gss_pq_HEAQ01 end AS health_status 
			,case when pers.gss_pq_HEAQ02a  in (88, 99) then NULL else pers.gss_pq_HEAQ02a end  AS health_limit_activ 
			,case when pers.gss_pq_HEAQ02b  in (88, 99) then NULL else pers.gss_pq_HEAQ02b end AS health_limit_stair 
			,pers.gss_pq_HEAQ03 AS health_accomplish_phys 
			,pers.gss_pq_HEAQ04 AS health_work_phys 
			,pers.gss_pq_HEAQ05 AS health_accomplish_emo 
			,pers.gss_pq_HEAQ06 AS health_work_emo 
			,pers.gss_pq_HEAQ07 AS health_pain 
			,pers.gss_pq_HEAQ08a AS health_calm 
			,pers.gss_pq_HEAQ08b AS health_energy 
			,pers.gss_pq_HEAQ08c AS health_depressed 
			,pers.gss_pq_HEAQ09 AS health_social 
			,cast(pers.gss_pq_HEADV2 as smallint) as gss_pq_ment_health_code 
			,cast(pers.gss_pq_HEADV3 as smallint) as gss_pq_phys_health_code 
			,pers.gss_pq_CULQ04 as gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different)*/ 
			,[gss_pq_CULQ01] AS belong 
			,NULL AS belong_2016
			,NULL AS discrim_status 
			,NULL AS discrim_shop    
			,NULL AS discrim_work 
			,NULL AS discrim_public 
			,NULL AS discrim_school 
			,NULL AS discrim_job 
			,NULL AS discrim_police 
			,NULL AS discrim_medic 
			,NULL AS discrim_other 
			,NULL AS discrim_dk 
			,NULL AS discrim_nr 
			,coalesce(pers.gss_pq_HUMQ07_19,0) as gss_pq_discrim_rent_ind /* Questions in earlier waves is about "applying for or keeping a house/flat". Probably too small to worry about*/ 
			,[gss_pq_LEIQ01] AS leisure_time 
			,pers.gss_pq_HUMQ01 as gss_pq_voting /* not in 2014 (just made up a var name) */ 
			,[gss_pq_SOCQ15] AS volunteer 
			,NULL AS trust_police 
			,NULL AS trust_education 
			,NULL AS trust_media  
			,NULL AS trust_courts 
			,NULL AS trust_parliament 
			,NULL AS trust_health
			,NULL AS generalised_trust 
			,pers.gss_pq_SOCQ11 as gss_pq_time_lonely_code /* Scales flipped between 2014 and rest. Prioritise over 'help who' */ 
			,[gss_pq_PHYQ12] AS env_water_bodies /*environment*/   
			,[gss_pq_PHYQ13]  AS env_access_bush /*environment*/   
			,[gss_pq_PHYQ14] AS env_state_bush /*environment*/     
			,NULL AS purpose_sense 
			,pers.gss_pq_OLSQ01 as gss_pq_feel_life_code 
			,pers.gss_pq_HOUQ02 AS house_brm
			,pers.gss_pq_CORDV8_12 AS inc_self 
			,[gss_pq_PersonGSSSelectionWeight] as gss_pq_person_SeInWgt
			,[gss_pq_PersonGSSFinalweight] as gss_pq_person_FinalWgt
			,[gss_pq_PersonGSSFinalWeight_1] as gss_pq_person_FinalWgt1
			,[gss_pq_PersonGSSFinalWeight_2] as gss_pq_person_FinalWgt2
			,[gss_pq_PersonGSSFinalWeight_3] as gss_pq_person_FinalWgt3
			,[gss_pq_PersonGSSFinalWeight_4] as gss_pq_person_FinalWgt4
			,[gss_pq_PersonGSSFinalWeight_5] as gss_pq_person_FinalWgt5
			,[gss_pq_PersonGSSFinalWeight_6] as gss_pq_person_FinalWgt6
			,[gss_pq_PersonGSSFinalWeight_7] as gss_pq_person_FinalWgt7
			,[gss_pq_PersonGSSFinalWeight_8] as gss_pq_person_FinalWgt8
			,[gss_pq_PersonGSSFinalWeight_9] as gss_pq_person_FinalWgt9
			,[gss_pq_PersonGSSFinalWeight_10] as gss_pq_person_FinalWgt10
			,[gss_pq_PersonGSSFinalWeight_11] as gss_pq_person_FinalWgt11
			,[gss_pq_PersonGSSFinalWeight_12] as gss_pq_person_FinalWgt12
			,[gss_pq_PersonGSSFinalWeight_13] as gss_pq_person_FinalWgt13
			,[gss_pq_PersonGSSFinalWeight_14] as gss_pq_person_FinalWgt14
			,[gss_pq_PersonGSSFinalWeight_15] as gss_pq_person_FinalWgt15
			,[gss_pq_PersonGSSFinalWeight_16] as gss_pq_person_FinalWgt16
			,[gss_pq_PersonGSSFinalWeight_17] as gss_pq_person_FinalWgt17
			,[gss_pq_PersonGSSFinalWeight_18] as gss_pq_person_FinalWgt18
			,[gss_pq_PersonGSSFinalWeight_19] as gss_pq_person_FinalWgt19
			,[gss_pq_PersonGSSFinalWeight_20] as gss_pq_person_FinalWgt20
			,[gss_pq_PersonGSSFinalWeight_21] as gss_pq_person_FinalWgt21
			,[gss_pq_PersonGSSFinalWeight_22] as gss_pq_person_FinalWgt22
			,[gss_pq_PersonGSSFinalWeight_23] as gss_pq_person_FinalWgt23
			,[gss_pq_PersonGSSFinalWeight_24] as gss_pq_person_FinalWgt24
			,[gss_pq_PersonGSSFinalWeight_25] as gss_pq_person_FinalWgt25
			,[gss_pq_PersonGSSFinalWeight_26] as gss_pq_person_FinalWgt26
			,[gss_pq_PersonGSSFinalWeight_27] as gss_pq_person_FinalWgt27
			,[gss_pq_PersonGSSFinalWeight_28] as gss_pq_person_FinalWgt28
			,[gss_pq_PersonGSSFinalWeight_29] as gss_pq_person_FinalWgt29
			,[gss_pq_PersonGSSFinalWeight_30] as gss_pq_person_FinalWgt30
			,[gss_pq_PersonGSSFinalWeight_31] as gss_pq_person_FinalWgt31
			,[gss_pq_PersonGSSFinalWeight_32] as gss_pq_person_FinalWgt32
			,[gss_pq_PersonGSSFinalWeight_33] as gss_pq_person_FinalWgt33
			,[gss_pq_PersonGSSFinalWeight_34] as gss_pq_person_FinalWgt34
			,[gss_pq_PersonGSSFinalWeight_35] as gss_pq_person_FinalWgt35
			,[gss_pq_PersonGSSFinalWeight_36] as gss_pq_person_FinalWgt36
			,[gss_pq_PersonGSSFinalWeight_37] as gss_pq_person_FinalWgt37
			,[gss_pq_PersonGSSFinalWeight_38] as gss_pq_person_FinalWgt38
			,[gss_pq_PersonGSSFinalWeight_39] as gss_pq_person_FinalWgt39
			,[gss_pq_PersonGSSFinalWeight_40] as gss_pq_person_FinalWgt40
			,[gss_pq_PersonGSSFinalWeight_41] as gss_pq_person_FinalWgt41
			,[gss_pq_PersonGSSFinalWeight_42] as gss_pq_person_FinalWgt42
			,[gss_pq_PersonGSSFinalWeight_43] as gss_pq_person_FinalWgt43
			,[gss_pq_PersonGSSFinalWeight_44] as gss_pq_person_FinalWgt44
			,[gss_pq_PersonGSSFinalWeight_45] as gss_pq_person_FinalWgt45
			,[gss_pq_PersonGSSFinalWeight_46] as gss_pq_person_FinalWgt46
			,[gss_pq_PersonGSSFinalWeight_47] as gss_pq_person_FinalWgt47
			,[gss_pq_PersonGSSFinalWeight_48] as gss_pq_person_FinalWgt48
			,[gss_pq_PersonGSSFinalWeight_49] as gss_pq_person_FinalWgt49
			,[gss_pq_PersonGSSFinalWeight_50] as gss_pq_person_FinalWgt50
			,[gss_pq_PersonGSSFinalWeight_51] as gss_pq_person_FinalWgt51
			,[gss_pq_PersonGSSFinalWeight_52] as gss_pq_person_FinalWgt52
			,[gss_pq_PersonGSSFinalWeight_53] as gss_pq_person_FinalWgt53
			,[gss_pq_PersonGSSFinalWeight_54] as gss_pq_person_FinalWgt54
			,[gss_pq_PersonGSSFinalWeight_55] as gss_pq_person_FinalWgt55
			,[gss_pq_PersonGSSFinalWeight_56] as gss_pq_person_FinalWgt56
			,[gss_pq_PersonGSSFinalWeight_57] as gss_pq_person_FinalWgt57
			,[gss_pq_PersonGSSFinalWeight_58] as gss_pq_person_FinalWgt58
			,[gss_pq_PersonGSSFinalWeight_59] as gss_pq_person_FinalWgt59
			,[gss_pq_PersonGSSFinalWeight_60] as gss_pq_person_FinalWgt60
			,[gss_pq_PersonGSSFinalWeight_61] as gss_pq_person_FinalWgt61
			,[gss_pq_PersonGSSFinalWeight_62] as gss_pq_person_FinalWgt62
			,[gss_pq_PersonGSSFinalWeight_63] as gss_pq_person_FinalWgt63
			,[gss_pq_PersonGSSFinalWeight_64] as gss_pq_person_FinalWgt64
			,[gss_pq_PersonGSSFinalWeight_65] as gss_pq_person_FinalWgt65
			,[gss_pq_PersonGSSFinalWeight_66] as gss_pq_person_FinalWgt66
			,[gss_pq_PersonGSSFinalWeight_67] as gss_pq_person_FinalWgt67
			,[gss_pq_PersonGSSFinalWeight_68] as gss_pq_person_FinalWgt68
			,[gss_pq_PersonGSSFinalWeight_69] as gss_pq_person_FinalWgt69
			,[gss_pq_PersonGSSFinalWeight_70] as gss_pq_person_FinalWgt70
			,[gss_pq_PersonGSSFinalWeight_71] as gss_pq_person_FinalWgt71
			,[gss_pq_PersonGSSFinalWeight_72] as gss_pq_person_FinalWgt72
			,[gss_pq_PersonGSSFinalWeight_73] as gss_pq_person_FinalWgt73
			,[gss_pq_PersonGSSFinalWeight_74] as gss_pq_person_FinalWgt74
			,[gss_pq_PersonGSSFinalWeight_75] as gss_pq_person_FinalWgt75
			,[gss_pq_PersonGSSFinalWeight_76] as gss_pq_person_FinalWgt76
			,[gss_pq_PersonGSSFinalWeight_77] as gss_pq_person_FinalWgt77
			,[gss_pq_PersonGSSFinalWeight_78] as gss_pq_person_FinalWgt78
			,[gss_pq_PersonGSSFinalWeight_79] as gss_pq_person_FinalWgt79
			,[gss_pq_PersonGSSFinalWeight_80] as gss_pq_person_FinalWgt80
			,[gss_pq_PersonGSSFinalWeight_81] as gss_pq_person_FinalWgt81
			,[gss_pq_PersonGSSFinalWeight_82] as gss_pq_person_FinalWgt82
			,[gss_pq_PersonGSSFinalWeight_83] as gss_pq_person_FinalWgt83
			,[gss_pq_PersonGSSFinalWeight_84] as gss_pq_person_FinalWgt84
			,[gss_pq_PersonGSSFinalWeight_85] as gss_pq_person_FinalWgt85
			,[gss_pq_PersonGSSFinalWeight_86] as gss_pq_person_FinalWgt86
			,[gss_pq_PersonGSSFinalWeight_87] as gss_pq_person_FinalWgt87
			,[gss_pq_PersonGSSFinalWeight_88] as gss_pq_person_FinalWgt88
			,[gss_pq_PersonGSSFinalWeight_89] as gss_pq_person_FinalWgt89
			,[gss_pq_PersonGSSFinalWeight_90] as gss_pq_person_FinalWgt90
			,[gss_pq_PersonGSSFinalWeight_91] as gss_pq_person_FinalWgt91
			,[gss_pq_PersonGSSFinalWeight_92] as gss_pq_person_FinalWgt92
			,[gss_pq_PersonGSSFinalWeight_93] as gss_pq_person_FinalWgt93
			,[gss_pq_PersonGSSFinalWeight_94] as gss_pq_person_FinalWgt94
			,[gss_pq_PersonGSSFinalWeight_95] as gss_pq_person_FinalWgt95
			,[gss_pq_PersonGSSFinalWeight_96] as gss_pq_person_FinalWgt96
			,[gss_pq_PersonGSSFinalWeight_97] as gss_pq_person_FinalWgt97
			,[gss_pq_PersonGSSFinalWeight_98] as gss_pq_person_FinalWgt98
			,[gss_pq_PersonGSSFinalWeight_99] as gss_pq_person_FinalWgt99
			,[gss_pq_PersonGSSFinalWeight_100] as gss_pq_person_FinalWgt100
		from &idi_version..gss_clean.gss_person_2010 pers 
		inner join &idi_version..data.personal_detail pers_det on (pers.snz_uid = pers_det.snz_uid)
		inner join IDI_Sandpit.[&si_proj_schema.].of_gss_hh_variables_mh hhld 
				on (pers.snz_uid = hhld.snz_uid and pers.gss_pq_collection_code = hhld.gss_id_collection_code)

		union all


		select 
			pers.snz_uid  
			,pers.snz_gss_hhld_uid  
			,pers_det.snz_spine_ind  
			,pers.gss_pq_collection_code as gss_id_collection_code  
			,cast([gss_pq_interview_start_date] as datetime) as gss_pq_interview_date  
			,hhld.gss_hq_interview_start_date  as gss_hq_interview_date
			,hhld.gss_hq_sex_dev  
			,hhld.gss_hq_birth_month_nbr  
			,hhld.gss_hq_birth_year_nbr  
			,pers.gss_pq_CORDV9 as gss_pq_dvage_code  
			,pers.gss_pq_CORDV3_ASIAN AS P_ASIAN  
			,pers.gss_pq_CORDV3_EURO AS P_EURO  
			,pers.gss_pq_CORDV3_MAORI AS P_MAORI  
			,pers.gss_pq_CORDV3_MELAA AS P_MELAA  
			,pers.gss_pq_CORDV3_OTHER AS P_OTHER  
			,pers.gss_pq_CORDV3_PP AS P_PACIFIC  
			,case when cast(pers.gss_pq_CORPQ15 as smallint) in (88, 99) then NULL else cast(pers.gss_pq_CORPQ15 as smallint) end AS maori_desc 
			,pers.gss_pq_CORPQ11 AS nz_born  
			,pers.gss_pq_CORPQ13 AS nz_arrive_year  
			,pers.gss_pq_CORPQ14 AS nz_arrive_month  
			,gss_pq_reg_council_08_code as gss_hq_regcouncil_dev
			,pers.gss_pq_CORDV1 AS married  
			,pers.[gss_pq_CORDV4]  as gss_pq_HH_comp_code  
			,case when cast(gss_pq_CORDV5 as smallint) = 77 then NULL else cast(gss_pq_CORDV5 as smallint) end as gss_hq_dep_child_dev
			,case when cast(pers.gss_pq_CORDV2 as smallint) = '10' then '11'   when cast(pers.gss_pq_CORDV2 as smallint) = '21' then '21'   when cast(pers.gss_pq_CORDV2 as smallint) = '22' then '23'   when cast(pers.gss_pq_CORDV2 as smallint) = '23' then '22' when cast(left(pers.gss_pq_CORDV2, 2) as smallint) = '24' then '24'   when cast(pers.gss_pq_CORDV2 as smallint) = '31' then '31'   when cast(pers.gss_pq_CORDV2 as smallint) = '32' then '33'   when cast(pers.gss_pq_CORDV2 as smallint) = '33' then '32' when cast(left(pers.gss_pq_CORDV2,2) as smallint) = '34' then '34'   when cast(pers.gss_pq_CORDV2 as smallint) = '40' then '41'   when cast(pers.gss_pq_CORDV2 as smallint) ='99' then '99'    else NULL end as fam_type  
			,hhld.family_nuclei_ct  
			,hhld.nonfamily_nuclei_ct   
			,hhld.family_size_adult   
			,hhld.family_size_child    
			,NULL as family_size_depchild
			,NULL as family_size_indepchild
			,case when hhld.gss_hq_house_trust  in (88, 99) then NULL else hhld.gss_hq_house_trust end as gss_hq_house_trust
			,case when hhld.gss_hq_house_own   in (88, 99) then NULL else hhld.gss_hq_house_own end as gss_hq_house_own
			,case when hhld.gss_hq_house_pay_mort_code in (88, 99) then NULL else hhld.gss_hq_house_pay_mort_code end as gss_hq_house_pay_mort_code  
			,case when hhld.gss_hq_house_pay_rent_code  in (88, 99) then NULL else hhld.gss_hq_house_pay_rent_code end as gss_hq_house_pay_rent_code
			,case when hhld.gss_hq_house_who_owns_code  in (88, 99) then NULL else hhld.gss_hq_house_who_owns_code end as gss_hq_house_who_owns_code 
			,case when pers.gss_pq_CORDV16 in ('88','99') then '77' else pers.gss_pq_CORDV16 end as  gss_pq_HH_tenure_code  
			,cast(pers.gss_pq_HOUDV2 as smallint) as gss_pq_HH_crowd_code  
			,coalesce(cast(pers.gss_pq_HOUQ03_14 as smallint), 0) as gss_pq_house_mold_code  
			,coalesce(cast(pers.gss_pq_HOUQ03_15 as smallint), 0) as gss_pq_house_cold_code  
			,NULL as gss_pq_house_condition_code20146
			,cast(pers.gss_pq_HOUQ03_13 as smallint) as gss_pq_house_condition_code  
			,cast(pers.gss_pq_HOUQ01 as smallint) as housing_satisfaction  
			,pers.gss_pq_HOUQ04_14 as gss_pq_prob_hood_noisy_ind  
			,pers.gss_pq_SAFQ01C as gss_pq_safe_night_pub_trans_code
			,pers.gss_pq_SAFQ01E as gss_pq_safe_night_hood_code
			,pers.gss_pq_SAFQ01D as gss_pq_safe_day_hood_code
			,cast(pers.gss_pq_SAFQ02 as smallint) as gss_pq_crimes_against_ind /* Slightly different wording (re traffic incidents) */  
			,cast(hhld.gss_hq_household_inc1_dev as smallint) as gss_hq_household_inc1_dev  
			,hhld.hh_gss_income
			,hhld.hh_gss_income_median
			,hhld.hh_gss_income_lower
			,hhld.hh_gss_income_upper
			,hhld.housing_status
			,cast(pers.gss_pq_CORDV14 as smallint) as gss_pq_lfs_dev  
			,case when coalesce(gss_pq_CORDV8_17,0) =1  then 1 else 0 end as gss_unemp_jobseek   
			,case when coalesce(gss_pq_CORDV8_18,0)  = 1 then 1 else 0 end as gss_sickness  
			,case when coalesce(gss_pq_CORDV8_20,0) =1  then 1 else 0 end as gss_invalid_support  
			,case when coalesce(gss_pq_CORDV8_19,0) = 1 then 1 else 0 end as gss_soleprnt_domestic  
			,case when coalesce(gss_pq_CORDV8_22,0)  = 1 then 1 else 0 end as gss_oth_ben  
			,case when coalesce(gss_pq_CORDV8_24,0)  = 1 then 1 else 0 end as gss_no_income         
			,NULL as gss_pq_material_wellbeing_code  
			,case when cast(gss_pq_ELSIDV1 as smallint) between 0 and 31    then cast(gss_pq_ELSIDV1 as smallint)  else NULL end as gss_pq_ELSIDV1  
			,[gss_pq_ELSQ05A] AS gss_pq_cost_down_vege_code  
			,[gss_pq_ELSQ05E] AS gss_pq_cost_down_dr_code  
			,[gss_pq_ELSQ05H] AS gss_pq_cost_down_shop_code  
			,NULL AS gss_pq_cost_down_hobby_code  
			,NULL AS gss_pq_cost_down_cold_code  
			,NULL AS gss_pq_cost_down_appliance_code  
			,NULL AS gss_pq_buy_shoes_limit_code  
			,NULL AS gss_pq_item_300_limit_code  
			,NULL AS gss_pq_not_pay_bills_time_code  
			,[gss_pq_ELSQ08] AS gss_pq_enough_inc_code 
			,pers.gss_pq_WORDV2 AS work_hrs  
			,pers.gss_pq_WORQ01 AS work_jobs_no  
			,pers.gss_pq_WORQ07 AS work_satisfaction  
			,pers.gss_pq_WORDV3 AS work_ft_pt  
			,pers.gss_pq_CORPQ22 AS work_now_ind  
			,case when pers.gss_pq_CORPQ25 in (88,99) then NULL else pers.gss_pq_CORPQ25 end AS work_start_ind
			,case when pers.gss_pq_CORPQ26 in (88, 99) then NULL else pers.gss_pq_CORPQ26 end  AS work_look_ind 
			,case when pers.gss_pq_CORPQ28 in (88, 99) then NULL else pers.gss_pq_CORPQ28 end AS work_could_start  
			,pers.gss_pq_CORPQ16 AS school_highest  
			,cast(pers.gss_pq_CORDV15 as smallint) as gss_pq_highest_qual_dev  
			,pers.gss_pq_CORPQ21 AS qual_yr  
			,case when pers.gss_pq_HEAQ01 in (88, 99) then NULL else pers.gss_pq_HEAQ01 end AS health_status 
			,case when pers.gss_pq_HEAQ02a  in (88, 99) then NULL else pers.gss_pq_HEAQ02a end  AS health_limit_activ 
			,case when pers.gss_pq_HEAQ02b  in (88, 99) then NULL else pers.gss_pq_HEAQ02b end AS health_limit_stair 
			,pers.gss_pq_HEAQ03 AS health_accomplish_phys  
			,pers.gss_pq_HEAQ04 AS health_work_phys  
			,pers.gss_pq_HEAQ05 AS health_accomplish_emo  
			,pers.gss_pq_HEAQ06 AS health_work_emo  
			,pers.gss_pq_HEAQ07 AS health_pain  
			,pers.gss_pq_HEAQ08a AS health_calm  
			,pers.gss_pq_HEAQ08b AS health_energy  
			,pers.gss_pq_HEAQ08c AS health_depressed  
			,pers.gss_pq_HEAQ09 AS health_social  
			,cast(pers.gss_pq_HEADV2 as smallint) as gss_pq_ment_health_code  
			,cast(pers.gss_pq_HEADV3 as smallint) as gss_pq_phys_health_code  
			,pers.gss_pq_CULQ04 as gss_pq_cult_identity_code /* Culture question asked differently across waves (and responses different)*/  
			,[gss_pq_CULQ01] AS belong  
			,NULL AS belong_2016
			,NULL AS discrim_status  
			,NULL AS discrim_shop     
			,NULL AS discrim_work  
			,NULL AS discrim_public  
			,NULL AS discrim_school  
			,NULL AS discrim_job  
			,NULL AS discrim_police  
			,NULL AS discrim_medic  
			,NULL AS discrim_other  
			,NULL AS discrim_dk  
			,NULL AS discrim_nr  
			,coalesce(pers.gss_pq_HUMQ07_19,0) as gss_pq_discrim_rent_ind /* 2012 question is about "applying for or keeping a house/flat". Probably too small to worry about */  
			,[gss_pq_LEIQ01] AS leisure_time  
			,pers.gss_pq_HUMQ01 as gss_pq_voting /* not in 2014 (just made up a var name) */  /*pers.gss_pq_SOCQ13 as help_who_code -- Scales flipped between 2014 and rest. Question has different scope too.*/  
			,[gss_pq_SOCQ15] AS volunteer  
			,NULL AS trust_police  
			,NULL AS trust_education  
			,NULL AS trust_media   
			,NULL AS trust_courts  
			,NULL AS trust_parliament  
			,NULL AS trust_health
			,NULL AS generalised_trust  
			,pers.gss_pq_SOCQ11 as gss_pq_time_lonely_code /* Scales flipped between 2014 and rest. Prioritise over 'help who'*/  
			,[gss_pq_PHYQ12] AS env_water_bodies /*environment*/   
			,[gss_pq_PHYQ13]  AS env_access_bush /*environment*/   
			,[gss_pq_PHYQ14] AS env_state_bush /*environment*/    
			,NULL AS purpose_sense  
			,pers.gss_pq_OLSQ01 as gss_pq_feel_life_code 
			,pers.gss_pq_HOUQ02 AS house_brm 
			,pers.gss_pq_CORDV8_12 AS inc_self 
			,[gss_pq_PersonGSSSelectionWeight]
			,[gss_pq_person_FinalWgt_nbr]
			,[gss_pq_person_FinalWgt1_nbr]
			,[gss_pq_person_FinalWgt2_nbr]
			,[gss_pq_person_FinalWgt3_nbr]
			,[gss_pq_person_FinalWgt4_nbr]
			,[gss_pq_person_FinalWgt5_nbr]
			,[gss_pq_person_FinalWgt6_nbr]
			,[gss_pq_person_FinalWgt7_nbr]
			,[gss_pq_person_FinalWgt8_nbr]
			,[gss_pq_person_FinalWgt9_nbr]
			,[gss_pq_person_FinalWgt10_nbr]
			,[gss_pq_person_FinalWgt11_nbr]
			,[gss_pq_person_FinalWgt12_nbr]
			,[gss_pq_person_FinalWgt13_nbr]
			,[gss_pq_person_FinalWgt14_nbr]
			,[gss_pq_person_FinalWgt15_nbr]
			,[gss_pq_person_FinalWgt16_nbr]
			,[gss_pq_person_FinalWgt17_nbr]
			,[gss_pq_person_FinalWgt18_nbr]
			,[gss_pq_person_FinalWgt19_nbr]
			,[gss_pq_person_FinalWgt20_nbr]
			,[gss_pq_person_FinalWgt21_nbr]
			,[gss_pq_person_FinalWgt22_nbr]
			,[gss_pq_person_FinalWgt23_nbr]
			,[gss_pq_person_FinalWgt24_nbr]
			,[gss_pq_person_FinalWgt25_nbr]
			,[gss_pq_person_FinalWgt26_nbr]
			,[gss_pq_person_FinalWgt27_nbr]
			,[gss_pq_person_FinalWgt28_nbr]
			,[gss_pq_person_FinalWgt29_nbr]
			,[gss_pq_person_FinalWgt30_nbr]
			,[gss_pq_person_FinalWgt31_nbr]
			,[gss_pq_person_FinalWgt32_nbr]
			,[gss_pq_person_FinalWgt33_nbr]
			,[gss_pq_person_FinalWgt34_nbr]
			,[gss_pq_person_FinalWgt35_nbr]
			,[gss_pq_person_FinalWgt36_nbr]
			,[gss_pq_person_FinalWgt37_nbr]
			,[gss_pq_person_FinalWgt38_nbr]
			,[gss_pq_person_FinalWgt39_nbr]
			,[gss_pq_person_FinalWgt40_nbr]
			,[gss_pq_person_FinalWgt41_nbr]
			,[gss_pq_person_FinalWgt42_nbr]
			,[gss_pq_person_FinalWgt43_nbr]
			,[gss_pq_person_FinalWgt44_nbr]
			,[gss_pq_person_FinalWgt45_nbr]
			,[gss_pq_person_FinalWgt46_nbr]
			,[gss_pq_person_FinalWgt47_nbr]
			,[gss_pq_person_FinalWgt48_nbr]
			,[gss_pq_person_FinalWgt49_nbr]
			,[gss_pq_person_FinalWgt50_nbr]
			,[gss_pq_person_FinalWgt51_nbr]
			,[gss_pq_person_FinalWgt52_nbr]
			,[gss_pq_person_FinalWgt53_nbr]
			,[gss_pq_person_FinalWgt54_nbr]
			,[gss_pq_person_FinalWgt55_nbr]
			,[gss_pq_person_FinalWgt56_nbr]
			,[gss_pq_person_FinalWgt57_nbr]
			,[gss_pq_person_FinalWgt58_nbr]
			,[gss_pq_person_FinalWgt59_nbr]
			,[gss_pq_person_FinalWgt60_nbr]
			,[gss_pq_person_FinalWgt61_nbr]
			,[gss_pq_person_FinalWgt62_nbr]
			,[gss_pq_person_FinalWgt63_nbr]
			,[gss_pq_person_FinalWgt64_nbr]
			,[gss_pq_person_FinalWgt65_nbr]
			,[gss_pq_person_FinalWgt66_nbr]
			,[gss_pq_person_FinalWgt67_nbr]
			,[gss_pq_person_FinalWgt68_nbr]
			,[gss_pq_person_FinalWgt69_nbr]
			,[gss_pq_person_FinalWgt70_nbr]
			,[gss_pq_person_FinalWgt71_nbr]
			,[gss_pq_person_FinalWgt72_nbr]
			,[gss_pq_person_FinalWgt73_nbr]
			,[gss_pq_person_FinalWgt74_nbr]
			,[gss_pq_person_FinalWgt75_nbr]
			,[gss_pq_person_FinalWgt76_nbr]
			,[gss_pq_person_FinalWgt77_nbr]
			,[gss_pq_person_FinalWgt78_nbr]
			,[gss_pq_person_FinalWgt79_nbr]
			,[gss_pq_person_FinalWgt80_nbr]
			,[gss_pq_person_FinalWgt81_nbr]
			,[gss_pq_person_FinalWgt82_nbr]
			,[gss_pq_person_FinalWgt83_nbr]
			,[gss_pq_person_FinalWgt84_nbr]
			,[gss_pq_person_FinalWgt85_nbr]
			,[gss_pq_person_FinalWgt86_nbr]
			,[gss_pq_person_FinalWgt87_nbr]
			,[gss_pq_person_FinalWgt88_nbr]
			,[gss_pq_person_FinalWgt89_nbr]
			,[gss_pq_person_FinalWgt90_nbr]
			,[gss_pq_person_FinalWgt91_nbr]
			,[gss_pq_person_FinalWgt92_nbr]
			,[gss_pq_person_FinalWgt93_nbr]
			,[gss_pq_person_FinalWgt94_nbr]
			,[gss_pq_person_FinalWgt95_nbr]
			,[gss_pq_person_FinalWgt96_nbr]
			,[gss_pq_person_FinalWgt97_nbr]
			,[gss_pq_person_FinalWgt98_nbr]
			,[gss_pq_person_FinalWgt99_nbr]
			,[gss_pq_person_FinalWgt100_nbr]
		from &idi_version..gss_clean.gss_person_2008 pers 
		inner join &idi_version..data.personal_detail pers_det on (pers.snz_uid = pers_det.snz_uid)
		inner join IDI_Sandpit.[&si_proj_schema.].of_gss_hh_variables_mh hhld 
			on (pers.snz_uid = hhld.snz_uid and pers.gss_pq_collection_code = hhld.gss_id_collection_code)
	);

	
	disconnect from odbc;

quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_gss_ind_variables,
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out.
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);