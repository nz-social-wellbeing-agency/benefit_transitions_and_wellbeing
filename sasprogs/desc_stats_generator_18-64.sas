/*********************************************************************************************************
DESCRIPTION: 

desc_stats_generator

Create descritive stats for GSS (linked population, reweighted, age<65)

INPUT:
sand.of_gss_ind_variables
sand.of_gss_calibrated_weights
sand.of_main_ben_spells_comp
sand.of_gss_partners_adminvars_mh

OUTPUT:


DEPENDENCIES:
Stats macros (SE_table_macros_DATALAB.sas)

NOTES:   



HISTORY: 
15 May 2018 VB&WJL v1
24 Jul 2018 BV Adding Housing status simplified, inc_self
11 Oct 2018 BV SAS formats moved to SQL 
16 Oct 2018 WJ Adding in components required by David for Tax Credits stuff
29 Oct 2018 BV Adding partner income and weekly income components modified

***********************************************************************************************************/

/* Parameterise location where the folders are stored */
options spool;
%global si_source_path;
%let si_source_path = /nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/outcomes_framework/benefit_transitions;

/*%include "&si_source_path.\include\desc_formats.sas";*/
%include "&si_source_path./include/se_table_macros_datalab.sas";

%macro descstats_generator(indata = , varlist = , class = , outdata =);

   proc sql; drop table &outdata.; quit;

	%let gss_waves= %str(GSS2016	GSS2014		GSS2012		GSS2010		GSS2008);
		
	%let out_counter = 1;
	%do %while ( %scan(&gss_waves., &out_counter.) ^= %str() );

		%let gss_wave = %scan(&gss_waves., &out_counter.) ;
		%local counter;
		%let counter = 1;
		%do %while ( %scan(&varlist., &counter.) ^= %str() );

			/* Get the current table name */
			%let varname = %scan(&varlist., &counter.) ;
			%put &varname.;
			
			proc sql;

			create table gssdata as select * from &indata.
				where gss_wave = "&gss_wave.";

			quit;

			/* Check if the variable has more than one distinct value for the current GSS wave*/
			proc sql;
				select count(distinct &varname.) into :distvalues separated by '	' from gssdata;
			quit;

			%if &distvalues. > 1 %then %do;
				%put &distvalues.;

				%seforpropn1_gssflag(indata=gssdata,outdata=temp,class=%str(&class.),var=&varname.,wgt=link_FinalWgt,ExcludMissing=1,ExcludeMore=none);
				
				
				data temp(drop=&varname.); 
					length gssname $10 varname $50 varvalue $100;
					 
					set temp; 
					gssname = "&gss_wave.";
					varname = "&varname."; 
					varvalue= &varname.; 
				run;


				%si_perform_unionall(si_table_in=&outdata., append_table=temp);

			%end;

			%put counter = &counter.;
			%let counter = %eval(&counter. + 1);
		%end;

		%let out_counter = %eval(&out_counter. + 1);
	%end;




%mend;

proc delete data=work.descstats_for_benflag ; run;
proc delete data=work.descstats_by_benflag ; run;
proc delete data=work.descstats_by_bentype ; run;
proc delete data=work.descstats_by_famtype ; run;
proc delete data=work.descstats_by_depchild ; run;
proc delete data=work.descstats_by_depchildind ; run;
proc delete data=work.descstats_by_benfamtype ; run;
proc delete data=work.descstats_by_bendepchild ; run;
proc delete data=work.descstats_by_bendepchildind ; run;
proc delete data=work.full_gss ; run;
proc delete data=work.data_gss; run;


proc sql;

		connect to odbc (dsn=&si_idi_dsnname.);
		create table full_gss as 
			select * from connection to odbc(
				select 
					gss.[snz_uid]
					,gss.[snz_gss_hhld_uid]
					,gss.[snz_spine_ind]
					,gss.[gss_id_collection_code] as gss_wave
					,gss.[gss_pq_interview_date] as pq_interview_date
					,cast(gss.[gss_hq_interview_date] as datetime) as hq_interview_date	  
					,case when cast(gss.[gss_pq_dvage_code] as smallint) between 15 and 19 then '1. 15 to 25'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 26 and 35 then '2. 26 to 35'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 36 and 45 then '3. 36 to 45'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 46 and 55 then '4. 46 to 55'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 56 and 65 then '5. 56 to 65'
						when cast(gss.[gss_pq_dvage_code] as smallint) >65 then '6. 66 and older'
						else '7. Other'
						end as age	
					,case when cast(gss.[gss_pq_dvage_code] as smallint) between 18 and 19 then '1. 18 to 19'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 20 and 24 then '2. 20 to 24'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 25 and 29 then '3. 25 to 29'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 30 and 34 then '4. 30 to 34'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 35 and 39 then '5. 35 to 39'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 40 and 44 then '6. 40 to 44'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 45 and 49 then '7. 45 to 49'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 50 and 54 then '8. 50 to 54'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 55 and 59 then '9. 55 to 59'
						when cast(gss.[gss_pq_dvage_code] as smallint) between 60 and 64 then '10. 60 to 64'
						when cast(gss.[gss_pq_dvage_code] as smallint) >65 then '11. 65 and older'
						else '12. Other'
						end as age2 
					,gss.[gss_hq_sex_dev] as sex
					,gss.[housing_status] as house_status
					,case when gss.[housing_status] = 'HOUSING NZ' then '1. Public-Rent'
						when gss.[housing_status] = 'OTHER SOCIAL HOUSING' then '1. Public-Rent'
						when gss.[housing_status] = 'OWN' then '2. Own'
						when gss.[housing_status] = 'TRUST' then '2. Own'
						else '3. Private-Rent'
						end as house_status_rent
					,gss.[housing_status_simplified] as housing_status_simplified
					,gss.[gss_pq_HH_tenure_code] as house_tenure
					,gss.[gss_pq_HH_crowd_code] as house_crowding
					,gss.[gss_pq_house_mold_code] as house_mold
					,gss.[gss_pq_house_cold_code] as house_cold
					,gss.[gss_pq_house_condition_code20146] as house_condition_20146
					,gss.[gss_pq_house_condition_code] as house_condition
					,gss.[housing_satisfaction] as house_satisfaction	  
					,gss.[housing_sat_ind] as house_satisfaction_2lev
					,gss.[house_brm] as house_nbr_bedrooms
					,gss.[gss_pq_safe_night_pub_trans_code] as safety_pub_transport
					,gss.pub_trpt_safety_ind as safety_pub_transport_2lev
					,gss.[gss_pq_safe_night_hood_code] as safety_neighbourhood_night
					,gss.[safety_ind] as safety_neighbourhood_night_2lev
					,gss.[gss_pq_safe_day_hood_code] as safety_neighbourhood_day	  
					,gss.[safety_day_ind] as safety_neighbourhood_day_2lev
					,gss.[crime_exp_ind] as safety_crime_victim
					,gss.[gss_pq_cult_identity_code] as culture_identity     
					,gss.[cult_identity_ind] as culture_identity_2lev
					,gss.[belong] as culture_belonging_nz  
					,gss.[belong_2016] as culture_belonging_nz_2016   
					,case when gss.[discrim_status] = '01' then '1. Experienced Discrimination'
						when gss.[discrim_status] = '02' then '2. Did not experience Discrimination'
						else '3. Unknown' 
						end as culture_discrimination  
					,case when gss.health_nzsf12_physical between 0 and 25 then '1. 0 to 25'
						when gss.health_nzsf12_physical between 26 and 50 then '2. 26 to 50'
						when gss.health_nzsf12_physical between 51 and 75 then '3. 51 to 75'
						when gss.health_nzsf12_physical between 76 and 100 then '4. 76 to 100'
						else '5. Other'
						end as health_nzsf12_physical_gp
					,case when gss.health_nzsf12_mental between 0 and 25 then '1. 0 to 25'
						when gss.health_nzsf12_mental between 26 and 50 then '2. 26 to 50'
						when gss.health_nzsf12_mental between 51 and 75 then '3. 51 to 75'
						when gss.health_nzsf12_mental between 76 and 100 then '4. 76 to 100'
						else '5. Other'
						end as health_nzsf12_mental_gp
					,gss.health_nzsf12_physical
					,gss.health_nzsf12_mental
					,gss.[health_status]
					,gss.[health_limit_activ]
					,gss.[health_limit_stair]
					,gss.[health_accomplish_phys]
					,gss.[health_work_phys]
					,gss.[health_accomplish_emo]
					,gss.[health_work_emo]
					,gss.[health_pain]
					,gss.[health_calm]
					,gss.[health_energy]
					,gss.[health_depressed]
					,gss.[health_social]	  
					,case when gss.[P_MOH_PHA_PHA_CST] <0 then '1. Less than 0 '
						when gss.[P_MOH_PHA_PHA_CST] =0 then '2. 0 '
						when gss.[P_MOH_PHA_PHA_CST] >0 and gss.[P_MOH_PHA_PHA_CST] <30 then '3. More than 0 Less Than 30'
						when gss.[P_MOH_PHA_PHA_CST] >=30 and gss.[P_MOH_PHA_PHA_CST] <100 then '4. More than 30 Less Than 100'
						when gss.[P_MOH_PHA_PHA_CST] >=100 then '5. 100 and More'
						else '6. Other'
						end as health_pharm_cst_1year
					,case when gss.[P_MOH_PFH_PFH_DUR] <0 then '1. Less than 0 '
						when gss.[P_MOH_PFH_PFH_DUR] =0 then '2. 0 '
						when gss.[P_MOH_PFH_PFH_DUR] >0 and gss.[P_MOH_PFH_PFH_DUR] <4 then '3. More than 0 Less Than 4'
						when gss.[P_MOH_PFH_PFH_DUR] >=4 and gss.[P_MOH_PFH_PFH_DUR] <8 then '4. More than 4 Less Than 8'
						when gss.[P_MOH_PFH_PFH_DUR] >=8 then '5. 8 and More'
						else '6. Other'
						end as health_hosp_dur_1year
					,gss.[lbr_force_status] as emp_labour_status
					,gss.[work_now_ind] as emp_job_last_7_days
					,gss.[work_start_ind] as emp_job_start_4_weeks
					,gss.[work_look_ind] as emp_job_look_last_4_weeks
					,gss.[work_could_start] as emp_job_could_start_last_week
					,case when gss.[work_hrs_clean] =0 then '1. 0  '
						when gss.[work_hrs_clean] >0 and gss.[work_hrs_clean] <=20 then '2. 1 to 20 '
						when gss.[work_hrs_clean] >=21 and gss.[work_hrs_clean] <40 then '3. 21 to 39 '
						when gss.[work_hrs_clean] >=40 and gss.[work_hrs_clean] <45 then '4. 40 to 44 '
						when gss.[work_hrs_clean] >=45 and gss.[work_hrs_clean] <55 then '5. 45 to 54'
						when gss.[work_hrs_clean] >=55 and gss.[work_hrs_clean] <100 then '6. 55 to 99'
						else '7. Other or NULLS'
						end as emp_total_hrs_worked
					,gss.[work_jobs_no] as emp_nbr_of_jobs
					,gss.[work_satisfaction] as emp_work_satisfaction
					,gss.[work_ft_pt] as emp_fulltime_parttime
					,gss.[gss_pq_highest_qual_dev] as know_highest_qual	  
					,gss.[gss_oecd_quals] as know_highest_qual_4lev	  
					,case when gss.[P_TER_DUR] <0 then '1. Less than 0 '
						when gss.[P_TER_DUR] =0 then '2. 0 '
						when gss.[P_TER_DUR] >0 and gss.[P_TER_DUR]<40 then '3. More than 0 Less Than 40'
						when gss.[P_TER_DUR] >=40 then '4. 40 and More'
						else '5. Other'
						end as know_tertiary_dur_1year
					,gss.life_satisfaction_ind as subj_life_satisfaction  
					,gss.[purpose_sense_clean] as subj_sense_of_purpose
					,gss.[gss_pq_voting] as civic_voting
					,gss.[generalised_trust_clean] as civic_generalised_trust	  
					,gss.[volunteer_clean] as civic_volunteering
					,gss.[trust_police_clean] as civic_trust_police
					,gss.[trust_education_clean] as civic_trust_education
					,gss.[trust_media_clean] as civic_trust_media
					,gss.[trust_courts_clean] as civic_trust_courts
					,gss.[trust_parliament_clean] as civic_trust_parliament
					,gss.[trust_health_clean] as civic_trust_health
					,gss.[gss_pq_time_lonely_code] as social_time_lonely	  
					,gss.[time_lonely_ind] as social_time_lonely_3lev
					,gss.hh_gss_income as income_household
					,case when gss.[inc_intvwmnth_gross] < 0 then '1. Less than 0'
						when gss.[inc_intvwmnth_gross] = 0 then '2. 0'
						when gss.[inc_intvwmnth_gross] >0 and gss.[inc_intvwmnth_gross] <4000 then '3. More than 0 Less Than 4000'						
						when gss.[inc_intvwmnth_gross] >=4000 and gss.[inc_intvwmnth_gross] <8000 then '4. More than 4000 Less Than 8000'						
						when gss.[inc_intvwmnth_gross] >=8000 and gss.[inc_intvwmnth_gross] <12000 then '5. More than 8000 Less Than 12000'						
						when gss.[inc_intvwmnth_gross] >=12000 then '6. 12000 and More'
						else '6. Other'	
						end as income_pq_intvw_mnth
					/* As per David's request dated 28 May 2018, adding proportion benefit */
					,gss.P_BEN_DUR_PROP as income_ben_dur_prop
					,case when gss.P_BEN_DUR_PROP <0.5 then '1. Less Than 183 days on Benefit in Last Year'
						when gss.P_BEN_DUR_PROP >=0.5 then '2. More Than 183 days on Benefit in Last Year'
						else '3. other'
						end as benefit_prop_duration
					,gss.[income_monthly_net]
		/* As per David's request dated 1 August 2018 May 2018, adding tax credits and breaking income into separate components */
					,gss.[income_monthly_net_comp] as income_monthly_net_alternate
					,gss.[P_IRD_EMP_C00_CST] as income_comp_dir_shareholder_ir3
					,gss.[P_IRD_EMP_C01_CST] as income_comp_dir_shareholder_paye
					,gss.[P_IRD_EMP_C02_CST] as income_comp_dir_shareholder_wht
					,gss.[P_IRD_EMP_P00_CST] as income_partnership_ir20
					,gss.[P_IRD_EMP_P01_CST] as income_partnership_paye
					,gss.[P_IRD_EMP_PPL_CST] as income_paid_parental_leave
					,gss.[P_IRD_EMP_S00_CST] as income_soletrader_ir3
					,gss.[P_IRD_EMP_S01_CST] as income_soletrader_paye
					,gss.[P_IRD_EMP_S02_CST] as income_soletrader_wht
					,gss.[P_IRD_EMP_WAS_CST] as income_wages_salaries
					,gss.[P_IRD_INS_BEN_CST] as income_main_benefit
					,gss.[P_IRD_INS_CLM_CST] as income_acc_claims
					,gss.[P_IRD_INS_PEN_CST] as income_pensions
					,gss.[P_IRD_RNT_S03_CST] as income_rents
					,gss.[P_IRD_STS_STU_CST] as income_stu_allowance
					,gss.[P_MSD_BEN_T2_065_CST] as income_supp_cda
					,gss.[P_MSD_BEN_T2_340_CST] as income_supp_orphan
					,gss.[P_MSD_BEN_T2_344_CST] as income_supp_ucb
					,gss.[P_MSD_BEN_T2_425_CST] as income_supp_disability
					,gss.[P_MSD_BEN_T2_450_CST] as income_supp_tas
					,gss.[P_MSD_BEN_T2_460_CST] as income_supp_special
					,gss.[P_MSD_BEN_T2_471_CST] as income_supp_accomsup
					,gss.[P_MSD_BEN_T2_500_CST] as income_supp_wb
					,gss.[P_MSD_BEN_T2_833_CST] as income_supp_trainallow
					,gss.[P_MSD_BEN_T2_835_CST] as income_supp_miscsubsidy
					,gss.[P_MSD_BEN_T2_838_CST] as income_supp_sda
					,gss.[P_INC_INC_INC_emstpm_CST] as income_taxcred_msd1
					,gss.[P_INC_INC_INC_fdrtpi_CST] as income_taxcred_ir1
					,gss.[P_INC_INC_INC_frdtir_CST] as income_taxcred_ir2
					,gss.[P_INC_INC_INC_frdtwi_CST] as income_taxcred_msd2
					,gss.[P_IRD_PYE_BEN_CST] as inctax_main_benefit
					,gss.[P_IRD_PYE_CLM_CST] as inctax_acc_claims
					,gss.[P_IRD_PYE_PEN_CST] as inctax_pensions
					,gss.[P_IRD_PYE_PPL_CST] as inctax_paid_parental_leave
					,gss.[P_IRD_PYE_STU_CST] as inctax_stu_allowance
					,gss.[P_IRD_PYE_WAS_CST] as inctax_wages_salaries
					,gss.[P_IRD_WHT_WHP_CST] as inctax_wht_payments

/* Creating summary values which is used in the final output */
/* added these variables in WJ for David's Request 16 Oct 2018 */
					,(gss.[P_MSD_BEN_T2_065_CST] 
						+gss.[P_MSD_BEN_T2_340_CST] 
						+gss.[P_MSD_BEN_T2_344_CST] 
						+gss.[P_MSD_BEN_T2_425_CST] 
						+gss.[P_MSD_BEN_T2_450_CST] 
						+gss.[P_MSD_BEN_T2_460_CST] 
						+gss.[P_MSD_BEN_T2_471_CST] 
						+gss.[P_MSD_BEN_T2_500_CST] 
						+gss.[P_MSD_BEN_T2_833_CST] 
						+gss.[P_MSD_BEN_T2_835_CST]
						+gss.[P_MSD_BEN_T2_838_CST]
						+gss.[P_IRD_INS_BEN_CST]
						+gss.[P_IRD_PYE_BEN_CST]
						+gss.[P_INC_INC_INC_emstpm_CST]
						+gss.[P_INC_INC_INC_fdrtpi_CST] 
						+gss.[P_INC_INC_INC_frdtir_CST]
						+gss.[P_INC_INC_INC_frdtwi_CST] )/52 as transfer_income_weekly

					,(gss.[P_IRD_EMP_C00_CST]
						+gss.[P_IRD_EMP_C01_CST]
						+gss.[P_IRD_EMP_C02_CST]
						+gss.[P_IRD_EMP_P00_CST]
						+gss.[P_IRD_EMP_P01_CST]
						+gss.[P_IRD_EMP_PPL_CST]
						+gss.[P_IRD_EMP_S00_CST]
						+gss.[P_IRD_EMP_S01_CST]
						+gss.[P_IRD_EMP_S02_CST]
						+gss.[P_IRD_EMP_WAS_CST]
						+gss.[P_IRD_INS_CLM_CST]
						+gss.[P_IRD_INS_PEN_CST] 
						+gss.[P_IRD_RNT_S03_CST]
						+gss.[P_IRD_STS_STU_CST]
						+gss.[P_IRD_PYE_CLM_CST] 
						+gss.[P_IRD_PYE_PEN_CST] 
						+gss.[P_IRD_PYE_PPL_CST] 
						+gss.[P_IRD_PYE_STU_CST] 
						+gss.[P_IRD_PYE_WAS_CST]
						+gss.[P_IRD_WHT_WHP_CST]
								) /52 as other_income_weekly

					,(gss.[P_IRD_INS_BEN_CST]
						+gss.[P_IRD_PYE_BEN_CST] )/52 as main_benefit_weekly

					,(gss.[P_INC_INC_INC_emstpm_CST]
						+gss.[P_INC_INC_INC_fdrtpi_CST] 
						+gss.[P_INC_INC_INC_frdtir_CST]
						+gss.[P_INC_INC_INC_frdtwi_CST] )/52 as tax_cred_weekly

					,(gss.[P_MSD_BEN_T2_065_CST] 
						+gss.[P_MSD_BEN_T2_340_CST] 
						+gss.[P_MSD_BEN_T2_344_CST] 
						+gss.[P_MSD_BEN_T2_425_CST] 
						+gss.[P_MSD_BEN_T2_450_CST] 
						+gss.[P_MSD_BEN_T2_460_CST] 
						+gss.[P_MSD_BEN_T2_471_CST] 
						+gss.[P_MSD_BEN_T2_500_CST] 
						+gss.[P_MSD_BEN_T2_833_CST] 
						+gss.[P_MSD_BEN_T2_835_CST]
						+gss.[P_MSD_BEN_T2_838_CST])/52 as supp_benefit_weekly

					,(	gss.[P_MSD_BEN_T2_065_CST] 
						+gss.[P_MSD_BEN_T2_340_CST] 
						+gss.[P_MSD_BEN_T2_344_CST] 
						+gss.[P_MSD_BEN_T2_425_CST] 
						+gss.[P_MSD_BEN_T2_450_CST] 
						+gss.[P_MSD_BEN_T2_460_CST] 
						+gss.[P_MSD_BEN_T2_471_CST] 
						+gss.[P_MSD_BEN_T2_500_CST] 
						+gss.[P_MSD_BEN_T2_833_CST] 
						+gss.[P_MSD_BEN_T2_835_CST]
						+gss.[P_MSD_BEN_T2_838_CST]
						+gss.[P_IRD_INS_BEN_CST]
						+gss.[P_IRD_PYE_BEN_CST]
						+gss.[P_INC_INC_INC_emstpm_CST]
						+gss.[P_INC_INC_INC_fdrtpi_CST] 
						+gss.[P_INC_INC_INC_frdtir_CST]
						+gss.[P_INC_INC_INC_frdtwi_CST]
						+gss.[P_IRD_EMP_C00_CST]
						+gss.[P_IRD_EMP_C01_CST]
						+gss.[P_IRD_EMP_C02_CST]
						+gss.[P_IRD_EMP_P00_CST]
						+gss.[P_IRD_EMP_P01_CST]
						+gss.[P_IRD_EMP_PPL_CST]
						+gss.[P_IRD_EMP_S00_CST]
						+gss.[P_IRD_EMP_S01_CST]
						+gss.[P_IRD_EMP_S02_CST]
						+gss.[P_IRD_EMP_WAS_CST]
						+gss.[P_IRD_INS_CLM_CST]
						+gss.[P_IRD_INS_PEN_CST] 
						+gss.[P_IRD_RNT_S03_CST]
						+gss.[P_IRD_STS_STU_CST]
						+gss.[P_IRD_PYE_CLM_CST] 
						+gss.[P_IRD_PYE_PEN_CST] 
						+gss.[P_IRD_PYE_PPL_CST] 
						+gss.[P_IRD_PYE_STU_CST] 
						+gss.[P_IRD_PYE_WAS_CST]
						+gss.[P_IRD_WHT_WHP_CST]
											)/52 as total_income_weekly  /* =transfer + other */



					,case when part.snz_uid is NULL then 0 else 1 end as couple_ind

/* household income = pq + partner */
					,(	gss.[P_MSD_BEN_T2_065_CST] 
						+gss.[P_MSD_BEN_T2_340_CST] 
						+gss.[P_MSD_BEN_T2_344_CST] 
						+gss.[P_MSD_BEN_T2_425_CST] 
						+gss.[P_MSD_BEN_T2_450_CST] 
						+gss.[P_MSD_BEN_T2_460_CST] 
						+gss.[P_MSD_BEN_T2_471_CST] 
						+gss.[P_MSD_BEN_T2_500_CST] 
						+gss.[P_MSD_BEN_T2_833_CST] 
						+gss.[P_MSD_BEN_T2_835_CST]
						+gss.[P_MSD_BEN_T2_838_CST]
						+gss.[P_IRD_INS_BEN_CST]
						+gss.[P_IRD_PYE_BEN_CST]
						+gss.[P_INC_INC_INC_emstpm_CST]
						+gss.[P_INC_INC_INC_fdrtpi_CST] 
						+gss.[P_INC_INC_INC_frdtir_CST]
						+gss.[P_INC_INC_INC_frdtwi_CST]
						+coalesce(part.[P_MSD_BEN_T2_065_CST],0)
/*						+coalesce(part.[P_MSD_BEN_T2_340_CST],0) */
						+coalesce(part.[P_MSD_BEN_T2_344_CST],0)
						+coalesce(part.[P_MSD_BEN_T2_425_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_450_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_460_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_471_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_500_CST],0) 
/*						+coalesce(part.[P_MSD_BEN_T2_833_CST],0) */
						+coalesce(part.[P_MSD_BEN_T2_835_CST],0)
/*						+coalesce(part.[P_MSD_BEN_T2_838_CST],0)*/
						+coalesce(part.[P_IRD_INS_BEN_CST],0) 
						+coalesce(part.[P_IRD_PYE_BEN_CST],0)
						+coalesce(part.[P_INC_INC_INC_emstpm_CST],0)
						+coalesce(part.[P_INC_INC_INC_fdrtpi_CST],0) 
						+coalesce(part.[P_INC_INC_INC_frdtir_CST],0)
/*						+coalesce(part.[P_INC_INC_INC_frdtwi_CST],0)*/
										)/52 as hhld_transfer_income_weekly

						,(gss.[P_IRD_EMP_C00_CST]
						+gss.[P_IRD_EMP_C01_CST]
						+gss.[P_IRD_EMP_C02_CST]
						+gss.[P_IRD_EMP_P00_CST]
						+gss.[P_IRD_EMP_P01_CST]
						+gss.[P_IRD_EMP_PPL_CST]
						+gss.[P_IRD_EMP_S00_CST]
						+gss.[P_IRD_EMP_S01_CST]
						+gss.[P_IRD_EMP_S02_CST]
						+gss.[P_IRD_EMP_WAS_CST]
						+gss.[P_IRD_INS_CLM_CST]
						+gss.[P_IRD_INS_PEN_CST] 
						+gss.[P_IRD_RNT_S03_CST]
						+gss.[P_IRD_STS_STU_CST]
						+gss.[P_IRD_PYE_CLM_CST] 
						+gss.[P_IRD_PYE_PEN_CST] 
						+gss.[P_IRD_PYE_PPL_CST] 
						+gss.[P_IRD_PYE_STU_CST] 
						+gss.[P_IRD_PYE_WAS_CST]
						+gss.[P_IRD_WHT_WHP_CST]
						+coalesce(part.[P_IRD_EMP_C00_CST],0)
						+coalesce(part.[P_IRD_EMP_C01_CST],0)
						+coalesce(part.[P_IRD_EMP_C02_CST],0)
						+coalesce(part.[P_IRD_EMP_P00_CST],0)
						+coalesce(part.[P_IRD_EMP_P01_CST],0)
						+coalesce(part.[P_IRD_EMP_PPL_CST],0)
						+coalesce(part.[P_IRD_EMP_S00_CST],0)
						+coalesce(part.[P_IRD_EMP_S01_CST],0)
						+coalesce(part.[P_IRD_EMP_S02_CST],0)
						+coalesce(part.[P_IRD_EMP_WAS_CST],0)
						+coalesce(part.[P_IRD_INS_CLM_CST],0)
						+coalesce(part.[P_IRD_INS_PEN_CST],0) 
						+coalesce(part.[P_IRD_RNT_S03_CST],0)
						+coalesce(part.[P_IRD_STS_STU_CST],0)
						+coalesce(part.[P_IRD_PYE_CLM_CST],0) 
						+coalesce(part.[P_IRD_PYE_PEN_CST],0) 
						+coalesce(part.[P_IRD_PYE_PPL_CST],0) 
						+coalesce(part.[P_IRD_PYE_STU_CST],0) 
						+coalesce(part.[P_IRD_PYE_WAS_CST],0)
						+coalesce(part.[P_IRD_WHT_WHP_CST],0)
										)/52 as hhld_other_income_weekly

						,(gss.[P_IRD_INS_BEN_CST] 
						+gss.[P_IRD_PYE_BEN_CST]
						+coalesce(part.[P_IRD_INS_BEN_CST],0)
						+coalesce(part.[P_IRD_PYE_BEN_CST],0) 
									)/52 as hhld_main_benefit_weekly

						,(gss.[P_INC_INC_INC_emstpm_CST]
							+gss.[P_INC_INC_INC_fdrtpi_CST]
							+gss.[P_INC_INC_INC_frdtir_CST]
							+gss.[P_INC_INC_INC_frdtwi_CST]
							+coalesce(part.[P_INC_INC_INC_emstpm_CST],0)
							+coalesce(part.[P_INC_INC_INC_fdrtpi_CST],0)
							+coalesce(part.[P_INC_INC_INC_frdtir_CST],0)
	/*						+coalesce(part.[P_INC_INC_INC_frdtwi_CST],0) */
													)/52 as hhld_tax_cred_weekly

					,(gss.[P_MSD_BEN_T2_065_CST] 
						+gss.[P_MSD_BEN_T2_340_CST] 
						+gss.[P_MSD_BEN_T2_344_CST] 
						+gss.[P_MSD_BEN_T2_425_CST] 
						+gss.[P_MSD_BEN_T2_450_CST] 
						+gss.[P_MSD_BEN_T2_460_CST] 
						+gss.[P_MSD_BEN_T2_471_CST] 
						+gss.[P_MSD_BEN_T2_500_CST] 
						+gss.[P_MSD_BEN_T2_833_CST] 
						+gss.[P_MSD_BEN_T2_835_CST]
						+gss.[P_MSD_BEN_T2_838_CST]
						+coalesce(part.[P_MSD_BEN_T2_065_CST],0)
/*						+coalesce(part.[P_MSD_BEN_T2_340_CST],0) */
						+coalesce(part.[P_MSD_BEN_T2_344_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_425_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_450_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_460_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_471_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_500_CST],0) 
/*						+coalesce(part.[P_MSD_BEN_T2_833_CST],0) */
						+coalesce(part.[P_MSD_BEN_T2_835_CST],0)
/*						+coalesce(part.[P_MSD_BEN_T2_838_CST],0)*/
														)/52 as hhld_supp_benefit_weekly

					,(gss.[P_MSD_BEN_T2_065_CST] 
						+gss.[P_MSD_BEN_T2_340_CST] 
						+gss.[P_MSD_BEN_T2_344_CST] 
						+gss.[P_MSD_BEN_T2_425_CST] 
						+gss.[P_MSD_BEN_T2_450_CST] 
						+gss.[P_MSD_BEN_T2_460_CST] 
						+gss.[P_MSD_BEN_T2_471_CST] 
						+gss.[P_MSD_BEN_T2_500_CST] 
						+gss.[P_MSD_BEN_T2_833_CST] 
						+gss.[P_MSD_BEN_T2_835_CST]
						+gss.[P_MSD_BEN_T2_838_CST]
						+gss.[P_IRD_INS_BEN_CST]
						+gss.[P_IRD_PYE_BEN_CST]
						+gss.[P_INC_INC_INC_emstpm_CST]
						+gss.[P_INC_INC_INC_fdrtpi_CST] 
						+gss.[P_INC_INC_INC_frdtir_CST]
						+gss.[P_INC_INC_INC_frdtwi_CST]
						+gss.[P_IRD_EMP_C00_CST]
						+gss.[P_IRD_EMP_C01_CST]
						+gss.[P_IRD_EMP_C02_CST]
						+gss.[P_IRD_EMP_P00_CST]
						+gss.[P_IRD_EMP_P01_CST]
						+gss.[P_IRD_EMP_PPL_CST]
						+gss.[P_IRD_EMP_S00_CST]
						+gss.[P_IRD_EMP_S01_CST]
						+gss.[P_IRD_EMP_S02_CST]
						+gss.[P_IRD_EMP_WAS_CST]
						+gss.[P_IRD_INS_CLM_CST]
						+gss.[P_IRD_INS_PEN_CST] 
						+gss.[P_IRD_RNT_S03_CST]
						+gss.[P_IRD_STS_STU_CST]
						+gss.[P_IRD_PYE_CLM_CST] 
						+gss.[P_IRD_PYE_PEN_CST] 
						+gss.[P_IRD_PYE_PPL_CST] 
						+gss.[P_IRD_PYE_STU_CST] 
						+gss.[P_IRD_PYE_WAS_CST]
						+gss.[P_IRD_WHT_WHP_CST]
						+coalesce(part.[P_MSD_BEN_T2_065_CST],0) 
/*						+coalesce(part.[P_MSD_BEN_T2_340_CST],0) */
						+coalesce(part.[P_MSD_BEN_T2_344_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_425_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_450_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_460_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_471_CST],0) 
						+coalesce(part.[P_MSD_BEN_T2_500_CST],0) 
/*						+coalesce(part.[P_MSD_BEN_T2_833_CST],0) */
						+coalesce(part.[P_MSD_BEN_T2_835_CST],0)
/*						+coalesce(part.[P_MSD_BEN_T2_838_CST],0)*/
						+coalesce(part.[P_IRD_INS_BEN_CST],0)
						+coalesce(part.[P_IRD_PYE_BEN_CST],0)
						+coalesce(part.[P_INC_INC_INC_emstpm_CST],0)
						+coalesce(part.[P_INC_INC_INC_fdrtpi_CST],0) 
						+coalesce(part.[P_INC_INC_INC_frdtir_CST],0)
/*						+coalesce(part.[P_INC_INC_INC_frdtwi_CST],0)*/
						+coalesce(part.[P_IRD_EMP_C00_CST],0)
						+coalesce(part.[P_IRD_EMP_C01_CST],0)
						+coalesce(part.[P_IRD_EMP_C02_CST],0)
						+coalesce(part.[P_IRD_EMP_P00_CST],0)
						+coalesce(part.[P_IRD_EMP_P01_CST],0)
						+coalesce(part.[P_IRD_EMP_PPL_CST],0)
						+coalesce(part.[P_IRD_EMP_S00_CST],0)
						+coalesce(part.[P_IRD_EMP_S01_CST],0)
						+coalesce(part.[P_IRD_EMP_S02_CST],0)
						+coalesce(part.[P_IRD_EMP_WAS_CST],0)
						+coalesce(part.[P_IRD_INS_CLM_CST],0)
						+coalesce(part.[P_IRD_INS_PEN_CST],0) 
						+coalesce(part.[P_IRD_RNT_S03_CST],0)
						+coalesce(part.[P_IRD_STS_STU_CST],0)
						+coalesce(part.[P_IRD_PYE_CLM_CST],0) 
						+coalesce(part.[P_IRD_PYE_PEN_CST],0) 
						+coalesce(part.[P_IRD_PYE_PPL_CST],0) 
						+coalesce(part.[P_IRD_PYE_STU_CST],0) 
						+coalesce(part.[P_IRD_PYE_WAS_CST],0)
						+coalesce(part.[P_IRD_WHT_WHP_CST],0)
											)/52 as hhld_total_income_weekly
					  ,part.[snz_uid] as snz_uid_partner
					  ,pers.[snz_spine_ind] as snz_spine_ind_partner

					,case when gss.inc_self is NULL then 0 else gss.inc_self end as inc_self
					,case when gss.accom_sup_1mnth_b4_intvw <=0 then 'No Accom. Supplement ' 
						when gss.accom_sup_1mnth_b4_intvw >0 then 'On Accom. Supplement '
						end as accom_sup_1mnth_b4_intvw
					,case when gss.accom_sup_1mnth_af_intvw <=0 then 'No Accom. Supplement ' 
						when gss.accom_sup_1mnth_af_intvw >0 then 'On Accom. Supplement '
						end as accom_sup_1mnth_af_intvw
/*					,case when [gss_pq_material_wellbeing_code] <6 then '1. Less than 6 '*/
/*						when [gss_pq_material_wellbeing_code] >=6 and [gss_pq_material_wellbeing_code] <14 then '2. More than 6 Less Than 14'										*/
/*						when [gss_pq_material_wellbeing_code] >=14 then '4. 14 and More'						*/
/*						else '5. Other'	*/
/*						end as econ_material_well_being_idx*/
/*					,gss.[gss_pq_material_wellbeing_code] as econ_material_well_being_idx2*/

					
/*					Updated MWI-( statistic to reflect request from Dr. David on 20190401*/

					,case 
						when [gss_pq_material_wellbeing_code] >=0 and [gss_pq_material_wellbeing_code] <=7 then '1. Hardship'										
						when [gss_pq_material_wellbeing_code] >=8 then '2. Not in Hardship'						
						else '3. Other'	
					 end as econ_material_well_being_idx
					,case
						when [gss_pq_material_wellbeing_code] then [gss_pq_material_wellbeing_code]
					 end as econ_material_well_being_idx2
					,case when [gss_pq_ELSIDV1] <14 then '1. Less than 14 '
						when [gss_pq_ELSIDV1] >=14 and [gss_pq_ELSIDV1] <21 then '2. More than 14 Less Than 21'						
						when [gss_pq_ELSIDV1] >=21 and [gss_pq_ELSIDV1] <26 then '3. More than 21 Less Than 26'						
						when [gss_pq_ELSIDV1] >=26 then '4. 26 and More'						
						else '5. Other'	
						end as econ_elsi_idx
					,gss.[gss_pq_enough_inc_code] as econ_enough_income
					,gss.[leisure_time]
					,gss.[P_EURO] as ethnicity_european_6lev
					,gss.[P_MAORI] as ethnicity_maori_6lev	  
					,gss.[P_PACIFIC] as ethnicity_pacific_6lev
					,gss.[P_ASIAN] as ethnicity_asian_6lev
					,gss.[P_MELAA] as ethnicity_melaa_6lev	  
					,gss.[P_OTHER] as ethnicity_other_6lev
					,case when gss.[gss_hq_regcouncil_dev] ='01' then 'Northland Region'
						when gss.[gss_hq_regcouncil_dev] ='02'	then 'Auckland Region'
						when gss.[gss_hq_regcouncil_dev] ='03'	then 'Waikato Region'
						when gss.[gss_hq_regcouncil_dev] ='04'	then 'Bay of Plenty Region'
						when gss.[gss_hq_regcouncil_dev] ='05'	then 'Gisborne Region'
						when gss.[gss_hq_regcouncil_dev] ='06'	then 'Hawkes Bay Region'
						when gss.[gss_hq_regcouncil_dev] ='07'	then 'Taranaki Region'
						when gss.[gss_hq_regcouncil_dev] ='08'	then 'Manawatu - Wanganui Region'
						when gss.[gss_hq_regcouncil_dev] ='09'	then 'Wellington Region'
						when gss.[gss_hq_regcouncil_dev] ='12'	then 'West Coast Region'
						when gss.[gss_hq_regcouncil_dev] ='13'	then 'Canterbury Region'
						when gss.[gss_hq_regcouncil_dev] ='14'	then 'Otago Region'
						when gss.[gss_hq_regcouncil_dev] ='15'	then 'Southland Region'
						when gss.[gss_hq_regcouncil_dev] ='16'	then 'Tasman Region'
						when gss.[gss_hq_regcouncil_dev] ='17'	then 'Nelson Region'
						when gss.[gss_hq_regcouncil_dev] ='18'	then 'Malborough Region'
						else 'Other Region'
						end as region_council 
					,gss.[married] as social_marital_status	  
					,gss.[fam_typem] as family_type
					,case when gss.[fam_typem] ='Couple with dependent child(ren) under 18 only' then '1. Has Dependent Child(ren)'
						when gss.[fam_typem] ='Couple with adult child(ren) and dependent child(ren) under 18' then '1. Has Dependent Child(ren)'
						when gss.[fam_typem] ='One parent with adult child(ren) and dependent child(ren) under 18' then '1. Has Dependent Child(ren)'
						when gss.[fam_typem] ='One parent with dependent child(ren) under 18 only' then '1. Has Dependent Child(ren)'
						else '2. Doesnt Have Dependent Child(ren)'
						end as dependent_children
						/* added these variables in WJ for David's Request 16 Oct 2018 */
					,case when gss.[fam_typem] in ('Couple with dependent child(ren) under 18 only','Couple with adult child(ren) and dependent child(ren) under 18')
						then 'Couple with dependent children'
						when gss.[fam_typem] in ('One parent with adult child(ren) and dependent child(ren) under 18','One parent with dependent child(ren) under 18 only')
						then 'Single with dependent children'
						when gss.[fam_typem] in ('Couple without Children','Couple with adult child(ren) only') 
						then 'Couple no dependent children'
						when gss.[fam_typem] in ('One parent with adult child(ren) only','Not in a family nucleus') 
						then 'Single no dependent children'
					end as family_agg_type

					,gss.[P_COR_ind] as corr_ind_1year
					,gss.gss_pq_cost_down_vege_code as econ_cost_down_vege
					,gss.gss_pq_cost_down_dr_code as econ_cost_down_dr
					,gss.gss_pq_cost_down_shop_code as econ_cost_down_shop
					,gss.gss_pq_cost_down_hobby_code as econ_cost_down_hobby
					,gss.gss_pq_cost_down_cold_code as econ_cost_down_cold
					,gss.gss_pq_cost_down_appliance_code as econ_cost_down_appliance
					,gss.gss_pq_buy_shoes_limit_code as econ_buy_shoes_limit
					,gss.gss_pq_item_300_limit_code as econ_item_300_limit
					,gss.gss_pq_not_pay_bills_time_code as econ_not_pay_bills_time
					,gss.gss_pq_enough_inc_code as econ_enough_inc_code
					,case when [gss_hq_dep_child_dev] = 1 then '1. One Dependent child'
						when [gss_hq_dep_child_dev] = 2 then '2. Two Dependent children'
						when [gss_hq_dep_child_dev] = 3 then '3. Three Dependent children'
						when [gss_hq_dep_child_dev] = 4 then '4. Four or more Dependent children'
						when [gss_hq_dep_child_dev] = 5 then '5. No Dependent children'
						else '6. Unknown number of Dependent children'
						end as family_dep_child
					,case when [gss_hq_dep_child_dev] between 1 and 4 then '1. Dependent children'
						when [gss_hq_dep_child_dev] = 5 then '2. No Dependent children'
						else '3. Unknown'
						end as family_dep_child_ind
					,[family_nuclei_ct] as family_nuclei_count 
					,[nonfamily_nuclei_ct] as family_non_nuclei_count
					,case when [family_nuclei_ct] + [nonfamily_nuclei_ct] = 1 then '1. One Nucleus'
						when [family_nuclei_ct] + [nonfamily_nuclei_ct] = 2 then '2. Two Nuclei'
						when [family_nuclei_ct] + [nonfamily_nuclei_ct] = 3 then '3. Three or more nuclei'
						else '4. Unknown nuclei'
						end as household_nuclei
					,gss.family_size_adult 
					,gss.family_size_child
					/* added these variables in WJ for David's Request 16 Oct 2018 */
					,( case when gss.[fam_typem] in ('Couple with dependent child(ren) under 18 only',
								'Couple with adult child(ren) and dependent child(ren) under 18','Couple without Children','Couple with adult child(ren) only') then 2 
							when gss.[fam_typem] in ('One parent with adult child(ren) and dependent child(ren) under 18',
								'One parent with dependent child(ren) under 18 only','One parent with adult child(ren) only','Not in a family nucleus') then 1 end + 
						coalesce(gss.family_size_child,0)) as family_size

					,link_FinalWgt as link_FinalWgt					
					,link_FinalWgt1 as link_FinalWgt_1
					,link_FinalWgt2 as link_FinalWgt_2
					,link_FinalWgt3 as link_FinalWgt_3
					,link_FinalWgt4 as link_FinalWgt_4
					,link_FinalWgt5 as link_FinalWgt_5
					,link_FinalWgt6 as link_FinalWgt_6
					,link_FinalWgt7 as link_FinalWgt_7
					,link_FinalWgt8 as link_FinalWgt_8
					,link_FinalWgt9 as link_FinalWgt_9  
					,link_FinalWgt10 as link_FinalWgt_10
					,link_FinalWgt11 as link_FinalWgt_11
					,link_FinalWgt12 as link_FinalWgt_12
					,link_FinalWgt13 as link_FinalWgt_13
					,link_FinalWgt14 as link_FinalWgt_14
					,link_FinalWgt15 as link_FinalWgt_15
					,link_FinalWgt16 as link_FinalWgt_16
					,link_FinalWgt17 as link_FinalWgt_17
					,link_FinalWgt18 as link_FinalWgt_18
					,link_FinalWgt19  as link_FinalWgt_19 
					,link_FinalWgt20 as link_FinalWgt_20
					,link_FinalWgt21 as link_FinalWgt_21
					,link_FinalWgt22 as link_FinalWgt_22
					,link_FinalWgt23 as link_FinalWgt_23
					,link_FinalWgt24 as link_FinalWgt_24
					,link_FinalWgt25 as link_FinalWgt_25
					,link_FinalWgt26 as link_FinalWgt_26
					,link_FinalWgt27 as link_FinalWgt_27
					,link_FinalWgt28 as link_FinalWgt_28
					,link_FinalWgt29  as link_FinalWgt_29 
					,link_FinalWgt30 as link_FinalWgt_30
					,link_FinalWgt31 as link_FinalWgt_31
					,link_FinalWgt32 as link_FinalWgt_32
					,link_FinalWgt33 as link_FinalWgt_33
					,link_FinalWgt34 as link_FinalWgt_34
					,link_FinalWgt35 as link_FinalWgt_35
					,link_FinalWgt36 as link_FinalWgt_36
					,link_FinalWgt37 as link_FinalWgt_37
					,link_FinalWgt38 as link_FinalWgt_38
					,link_FinalWgt39  as link_FinalWgt_39 
					,link_FinalWgt40 as link_FinalWgt_40
					,link_FinalWgt41 as link_FinalWgt_41
					,link_FinalWgt42 as link_FinalWgt_42
					,link_FinalWgt43 as link_FinalWgt_43
					,link_FinalWgt44 as link_FinalWgt_44
					,link_FinalWgt45 as link_FinalWgt_45
					,link_FinalWgt46 as link_FinalWgt_46
					,link_FinalWgt47 as link_FinalWgt_47
					,link_FinalWgt48 as link_FinalWgt_48
					,link_FinalWgt49  as link_FinalWgt_49 
					,link_FinalWgt50 as link_FinalWgt_50
					,link_FinalWgt51 as link_FinalWgt_51
					,link_FinalWgt52 as link_FinalWgt_52
					,link_FinalWgt53 as link_FinalWgt_53
					,link_FinalWgt54 as link_FinalWgt_54
					,link_FinalWgt55 as link_FinalWgt_55
					,link_FinalWgt56 as link_FinalWgt_56
					,link_FinalWgt57 as link_FinalWgt_57
					,link_FinalWgt58 as link_FinalWgt_58
					,link_FinalWgt59  as link_FinalWgt_59 
					,link_FinalWgt60 as link_FinalWgt_60
					,link_FinalWgt61 as link_FinalWgt_61
					,link_FinalWgt62 as link_FinalWgt_62
					,link_FinalWgt63 as link_FinalWgt_63
					,link_FinalWgt64 as link_FinalWgt_64
					,link_FinalWgt65 as link_FinalWgt_65
					,link_FinalWgt66 as link_FinalWgt_66
					,link_FinalWgt67 as link_FinalWgt_67
					,link_FinalWgt68 as link_FinalWgt_68
					,link_FinalWgt69  as link_FinalWgt_69 
					,link_FinalWgt70 as link_FinalWgt_70
					,link_FinalWgt71 as link_FinalWgt_71
					,link_FinalWgt72 as link_FinalWgt_72
					,link_FinalWgt73 as link_FinalWgt_73
					,link_FinalWgt74 as link_FinalWgt_74
					,link_FinalWgt75 as link_FinalWgt_75
					,link_FinalWgt76 as link_FinalWgt_76
					,link_FinalWgt77 as link_FinalWgt_77
					,link_FinalWgt78 as link_FinalWgt_78
					,link_FinalWgt79  as link_FinalWgt_79 
					,link_FinalWgt80 as link_FinalWgt_80
					,link_FinalWgt81 as link_FinalWgt_81
					,link_FinalWgt82 as link_FinalWgt_82
					,link_FinalWgt83 as link_FinalWgt_83
					,link_FinalWgt84 as link_FinalWgt_84
					,link_FinalWgt85 as link_FinalWgt_85
					,link_FinalWgt86 as link_FinalWgt_86
					,link_FinalWgt87 as link_FinalWgt_87
					,link_FinalWgt88 as link_FinalWgt_88
					,link_FinalWgt89  as link_FinalWgt_89 
					,link_FinalWgt90 as link_FinalWgt_90
					,link_FinalWgt91 as link_FinalWgt_91
					,link_FinalWgt92 as link_FinalWgt_92
					,link_FinalWgt93 as link_FinalWgt_93
					,link_FinalWgt94 as link_FinalWgt_94
					,link_FinalWgt95 as link_FinalWgt_95
					,link_FinalWgt96 as link_FinalWgt_96
					,link_FinalWgt97 as link_FinalWgt_97
					,link_FinalWgt98 as link_FinalWgt_98
					,link_FinalWgt99  as link_FinalWgt_99 
					,link_FinalWgt100 as link_FinalWgt_100
					,case when ben.snz_uid is null then 0 else 1 end as admin_benefit_flag
					,case when (gss.gss_unemp_jobseek + gss.gss_sickness + gss.gss_invalid_support + gss.gss_soleprnt_domestic + gss.gss_oth_ben) > 0 
						then 1 else 0 end as gss_benefit_flag
					,case when t1.event_type_4 is null then 'Not on Benefit' else t1.event_type_4 end as benefit_type
					,case when zz.snz_uid is not null then 1 else 0 end as ben_1yr_before	

				from [IDI_Sandpit].[&si_proj_schema.].of_gss_ind_variables_mh gss
				inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_calibrated_weights_mh weights 
					on (gss.snz_uid = weights.snz_uid and gss.gss_id_collection_code = weights.gss_id_collection_code)
				left join [IDI_Sandpit].[&si_proj_schema.].[of_comb_spells_rule2] ben
					on (gss.snz_uid = ben.snz_uid and ben.state='BEN' and gss.gss_pq_interview_date between ben.start_date and ben.end_date) 
				left join  (select gss.snz_uid, max(event_type_4) as event_type_4
							from [IDI_Sandpit].[&si_proj_schema.].of_gss_ind_variables_mh gss
							inner join [IDI_Sandpit].[&si_proj_schema.].[of_comb_spells_rule2] ben
								on (gss.snz_uid = ben.snz_uid and ben.state='BEN' 
									and gss.gss_pq_interview_date between ben.start_date and ben.end_date) 
							inner join  [IDI_Sandpit].[&si_proj_schema.].SIAL_MSD_T1_events t1 
								/* Since we have to go back to SIAL_t1_events to get the benefit types, we have to account for any compaction and 
								combination of spells done by the buisiness rules applied to the data while creation of the of_comb_spells_rule2 table.
								Here we find that we capture all individuals who are shown to be on benefit from of_comb_spells_rule2 table only if we 
								look at 2 days before interview to 3 days after in the SIAL_t1_events table. We hard code it here...*/
								on (gss.snz_uid = t1.snz_uid and dateadd(dd, 3, cast(gss.[gss_pq_interview_date] as date)) >= cast(t1.start_date as date) and 
									dateadd(dd, -1, cast(gss.[gss_pq_interview_date] as date)) <= cast(t1.end_date as date))
							group by gss.snz_uid) t1 
					on (gss.snz_uid = t1.snz_uid)
				/* on benefit one year before the interview ? */
				left join (
					select distinct b.snz_uid 
					from [IDI_Sandpit].[&si_proj_schema.].[of_main_ben_spells_comp] b
					inner join [IDI_Sandpit].[&si_proj_schema.].of_gss_ind_variables_mh g on (b.snz_uid = g.snz_uid)
					where g.snz_uid = b.snz_uid and dateadd(dd, -365, g.gss_pq_interview_date) between b.start_date and b.end_date
				) zz on ( gss.snz_uid=zz.snz_uid )
				left join [IDI_Sandpit].[&si_proj_schema.].[of_gss_partners_adminvars_mh] part on (gss.snz_uid=part.snz_uid_pq)
	   			left join [&idi_version.].[data].[personal_detail] pers on (pers.snz_uid=part.snz_uid)
				/* As per David's request dated 28 May 2018, adding filters for age < 65 */
				where gss.[gss_pq_dvage_code] < 65 and gss.[gss_pq_dvage_code] > 17




)		;

		disconnect from odbc;

quit;


data data_gss;
	set full_gss;

	/* Addition for a derived variable -David's request, dated 30 Aug 2018*/
	vege=0; if econ_cost_down_vege = '13' then vege=1; if econ_cost_down_vege = '88' then vege=.; if econ_cost_down_vege = ' ' then vege=.;
	doctor=0; if econ_cost_down_dr = '13' then doctor=1; if econ_cost_down_dr = '88' then doctor=.; if econ_cost_down_dr = ' ' then doctor=.;
	tripshops=0; if econ_cost_down_shop = '13' then tripshops=1; if econ_cost_down_shop = '88' then tripshops=.; if econ_cost_down_shop = ' ' then tripshops=.;
	hobbies=0; if econ_cost_down_hobby = '13' then hobbies=1; if econ_cost_down_hobby = '88' then hobbies=.; if econ_cost_down_hobby = ' ' then hobbies=.;
	cold=0; if econ_cost_down_cold = '13' then cold=1; if econ_cost_down_cold = '88' then cold=.; if econ_cost_down_cold = ' ' then cold=.;
	appliance=0; if econ_cost_down_appliance = '13' then appliance=1; if econ_cost_down_appliance = '88' then appliance=.; if econ_cost_down_appliance = ' ' then appliance=.;
	shoes=0; if econ_buy_shoes_limit = '14' then shoes=1; if econ_buy_shoes_limit = '88' then shoes=.; if econ_buy_shoes_limit = ' ' then shoes =.;
	threehundred = 0; if econ_item_300_limit = '15' then threehundred =1; if econ_item_300_limit = '88' then threehundred =.; if econ_item_300_limit = ' ' then threehundred =.;
	utilities = 0; if econ_not_pay_bills_time = '13' then utilities =1; if econ_not_pay_bills_time = '88' then utilities =.; if econ_not_pay_bills_time = ' ' then utilities =.;
	adequate = 0; if econ_enough_inc_code = '11' then adequate =1; if econ_enough_inc_code = '88' then adequate =.; if econ_enough_inc_code = ' ' then adequate =.;
	crowd = 0; if house_crowding le 2 then crowd =1; if house_crowding = 77 then crowd =.; 

	multiple_disadvantage_index = 12*mean(vege, doctor, tripshops, hobbies, cold, appliance, shoes, threehundred, utilities, adequate, crowd, house_mold);	

	/* Drop temporary columns */
	drop vege doctor tripshops hobbies cold appliance shoes threehundred utilities adequate crowd
	;

run;

/* Push the cohort into the database*/
/*%si_write_to_db(si_write_table_in=data_gss,*/
/*	si_write_table_out=&si_sandpit_libname..of_gss_desc_stats_tab_mh18p*/
/*	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)*/
/*	);*/

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=WORK.DATA_GSS,
	si_write_table_out=&si_sandpit_libname..of_gss_desc_stats_tab_mh18p
	,si_cluster_index_flag=True,si_index_cols=%bquote(snz_uid)
	);

/*	data sand.DF_MSD_T2_rlpw_2015;*/
/*set MSD_T2_events_rlpw;*/
/*run;*/

%let varlist = %str(
	age2
	health_nzsf12_physical_gp
	health_nzsf12_mental_gp
	income_pq_intvw_mnth
	health_pharm_cst_1year
	health_hosp_dur_1year
	econ_material_well_being_idx	
	econ_elsi_idx
	accom_sup_1mnth_b4_intvw
	accom_sup_1mnth_af_intvw
	know_tertiary_dur_1year
	emp_total_hrs_worked
	sex	
	house_status	house_tenure	house_crowding	house_mold	house_cold house_condition_20146 house_condition	house_satisfaction	house_satisfaction_2lev	house_nbr_bedrooms	
	safety_pub_transport	safety_pub_transport_2lev	safety_neighbourhood_night	safety_neighbourhood_night_2lev	safety_neighbourhood_day	
	safety_neighbourhood_day_2lev	safety_crime_victim	
	culture_identity	culture_identity_2lev	culture_belonging_nz culture_belonging_nz_2016 	
	health_status	health_limit_activ	health_limit_stair	health_accomplish_phys	health_work_phys	health_accomplish_emo	
	health_work_emo	health_pain	health_calm	health_energy	health_depressed	health_social		
	emp_labour_status	emp_job_last_7_days	emp_job_start_4_weeks	emp_job_look_last_4_weeks	emp_job_could_start_last_week	
	emp_nbr_of_jobs	emp_work_satisfaction	emp_fulltime_parttime	
	know_highest_qual	know_highest_qual_4lev	
	subj_life_satisfaction	subj_sense_of_purpose	
	civic_voting	civic_generalised_trust	civic_volunteering	civic_trust_police	civic_trust_education	civic_trust_media	
	civic_trust_courts	civic_trust_parliament	civic_trust_health	
	social_time_lonely	social_time_lonely_3lev	
	income_household
	econ_cost_down_vege
	econ_cost_down_dr
	econ_cost_down_shop
	econ_cost_down_hobby
	econ_cost_down_cold
	econ_cost_down_appliance
	econ_buy_shoes_limit
	econ_item_300_limit
	econ_not_pay_bills_time
	econ_enough_inc_code
	econ_enough_income	leisure_time	
	ethnicity_european_6lev	
	ethnicity_maori_6lev	ethnicity_pacific_6lev	ethnicity_asian_6lev	ethnicity_melaa_6lev	ethnicity_other_6lev		
	social_marital_status	family_type	corr_ind_1year
	house_status_rent
	dependent_children
	benefit_prop_duration
	culture_discrimination
	household_nuclei
	region_council

);


%macro xlsx(name);
proc export data=&name. outfile="&si_source_path./output/desc_stats_refresh_18-64.xlsx" dbms=xlsx replace; 
sheet="&name."; run;
%mend;


%descstats_generator(indata = WORK.data_gss, varlist = &varlist., class =  admin_benefit_flag, outdata = descstats_by_benflag);
%xlsx(descstats_by_benflag);
%descstats_generator(indata = data_gss, varlist = &varlist., class =  benefit_type, outdata = descstats_by_bentype);
%xlsx(descstats_by_bentype);
%descstats_generator(indata = data_gss, varlist = &varlist., class =  family_type, outdata = descstats_by_famtype);
%xlsx(descstats_by_famtype);
%descstats_generator(indata = data_gss, varlist = &varlist., class =  family_dep_child, outdata = descstats_by_depchild);
%xlsx(descstats_by_depchild);
%descstats_generator(indata = data_gss, varlist = &varlist., class =  family_dep_child_ind, outdata = descstats_by_depchildind);
%xlsx(descstats_by_depchildind);
/**/
%descstats_generator(indata = data_gss, varlist = &varlist., class =  %str(family_type admin_benefit_flag), outdata = descstats_by_benfamtype);
%xlsx(descstats_by_benfamtype);
%descstats_generator(indata = data_gss, varlist = &varlist., class =  %str(admin_benefit_flag family_dep_child_ind), outdata = descstats_by_bendepchildind);
%xlsx(descstats_by_bendepchildind);





%let varlist = %str(
admin_benefit_flag

);

%descstats_generator(indata = data_gss, varlist = &varlist., class =  %str(age2 sex), outdata = age_sex_benefit );
proc export data=age_sex_benefit outfile="&si_source_path./output/desc_stats_refresh_agesex_1864.xlsx" dbms=xlsx replace; 
sheet="age_sex_benefit"; run;