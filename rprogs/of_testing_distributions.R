# ================================================================================================ #
# Description: Testing if the recalibrated weights produced after linking to the spine have 
#   a distribution of outcomes/descriptive variabes that are consistent with the original 
#   distribution.
#
# Input: 
# of_rewt_gss_preson_replicates.R (or similar script) to produce datasets for consistency checking.
#
# Output: 
# results.csv providing p-values that the corresponding distributions are the same.
#
# Author: S Anastasiadis
#
# Dependencies:
# NA
#
# Notes:
# Output csv file is titled "comparison_pvals.csv". This has been inspected, with additional 
# comments and description in "validity of reweighting checks.xls".
#
# History (reverse order): 
# 22 Sep 2017 SA v1
# ================================================================================================ #

############### prepare data ###################

dataset <- SIAtoolbox::read_sql_table("SELECT [snz_uid]
                                      ,[snz_gss_hhld_uid]
                                      ,[snz_spine_ind]
                                      ,[gss_id_collection_code] as gss_wave
                                      ,[gss_pq_interview_date] as pq_interview_date
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
                                      ,[health_nzsf12_physical] as health_sf12_physcial
                                      ,[health_nzsf12_mental] as health_sf12_mental
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
                                      ,life_satisfaction_ind as subj_life_satisfaction  
                                      ,[purpose_sense_clean] as subj_sense_of_purpose
                                      ,[gss_pq_voting] as civic_voting
                                      ,[generalised_trust_clean] as civic_generalised_trust	  
                                      ,[volunteer_clean] as civic_volunteering
                                      ,[trust_police_clean] as civic_trust_police
                                      ,[trust_education_clean] as civic_trust_education
                                      ,[trust_media_clean] as civic_trust_media
                                      ,[trust_courts_clean] as civic_trust_courts
                                      ,[trust_parliament_clean] as civic_trust_parliament
                                      ,[trust_health_clean] as civic_trust_health
                                      ,[gss_pq_time_lonely_code] as social_time_lonely	  
                                      ,[time_lonely_ind] as social_time_lonely_3lev
                                      ,hh_gss_income as income_household
                                      ,[gss_pq_material_wellbeing_code] as econ_material_well_being_idx
                                      ,[gss_pq_ELSIDV1] as econ_elsi_idx
                                      ,[leisure_time]  
                                      ,[P_EURO] as ethnicity_european_6lev
                                      ,[P_MAORI] as ethnicity_maori_6lev	  
                                      ,[P_PACIFIC] as ethnicity_pacific_6lev
                                      ,[P_ASIAN] as ethnicity_asian_6lev
                                      ,[P_MELAA] as ethnicity_melaa_6lev	  
                                      ,[P_OTHER] as ethnicity_other_6lev 
                                      ,[married] as social_marital_status	  
                                      ,[fam_typem] as family_type	  
                                      ,[gss_pq_person_SeInWgt]
                                      ,[gss_pq_person_FinalWgt]
                                      ,[gss_pq_person_FinalWgt1]
                                      ,[gss_pq_person_FinalWgt2]
                                      ,[gss_pq_person_FinalWgt3]
                                      ,[gss_pq_person_FinalWgt4]
                                      ,[gss_pq_person_FinalWgt5]
                                      ,[gss_pq_person_FinalWgt6]
                                      ,[gss_pq_person_FinalWgt7]
                                      ,[gss_pq_person_FinalWgt8]
                                      ,[gss_pq_person_FinalWgt9]
                                      ,[gss_pq_person_FinalWgt10]
                                      ,[gss_pq_person_FinalWgt11]
                                      ,[gss_pq_person_FinalWgt12]
                                      ,[gss_pq_person_FinalWgt13]
                                      ,[gss_pq_person_FinalWgt14]
                                      ,[gss_pq_person_FinalWgt15]
                                      ,[gss_pq_person_FinalWgt16]
                                      ,[gss_pq_person_FinalWgt17]
                                      ,[gss_pq_person_FinalWgt18]
                                      ,[gss_pq_person_FinalWgt19]
                                      ,[gss_pq_person_FinalWgt20]
                                      ,[gss_pq_person_FinalWgt21]
                                      ,[gss_pq_person_FinalWgt22]
                                      ,[gss_pq_person_FinalWgt23]
                                      ,[gss_pq_person_FinalWgt24]
                                      ,[gss_pq_person_FinalWgt25]
                                      ,[gss_pq_person_FinalWgt26]
                                      ,[gss_pq_person_FinalWgt27]
                                      ,[gss_pq_person_FinalWgt28]
                                      ,[gss_pq_person_FinalWgt29]
                                      ,[gss_pq_person_FinalWgt30]
                                      ,[gss_pq_person_FinalWgt31]
                                      ,[gss_pq_person_FinalWgt32]
                                      ,[gss_pq_person_FinalWgt33]
                                      ,[gss_pq_person_FinalWgt34]
                                      ,[gss_pq_person_FinalWgt35]
                                      ,[gss_pq_person_FinalWgt36]
                                      ,[gss_pq_person_FinalWgt37]
                                      ,[gss_pq_person_FinalWgt38]
                                      ,[gss_pq_person_FinalWgt39]
                                      ,[gss_pq_person_FinalWgt40]
                                      ,[gss_pq_person_FinalWgt41]
                                      ,[gss_pq_person_FinalWgt42]
                                      ,[gss_pq_person_FinalWgt43]
                                      ,[gss_pq_person_FinalWgt44]
                                      ,[gss_pq_person_FinalWgt45]
                                      ,[gss_pq_person_FinalWgt46]
                                      ,[gss_pq_person_FinalWgt47]
                                      ,[gss_pq_person_FinalWgt48]
                                      ,[gss_pq_person_FinalWgt49]
                                      ,[gss_pq_person_FinalWgt50]
                                      ,[gss_pq_person_FinalWgt51]
                                      ,[gss_pq_person_FinalWgt52]
                                      ,[gss_pq_person_FinalWgt53]
                                      ,[gss_pq_person_FinalWgt54]
                                      ,[gss_pq_person_FinalWgt55]
                                      ,[gss_pq_person_FinalWgt56]
                                      ,[gss_pq_person_FinalWgt57]
                                      ,[gss_pq_person_FinalWgt58]
                                      ,[gss_pq_person_FinalWgt59]
                                      ,[gss_pq_person_FinalWgt60]
                                      ,[gss_pq_person_FinalWgt61]
                                      ,[gss_pq_person_FinalWgt62]
                                      ,[gss_pq_person_FinalWgt63]
                                      ,[gss_pq_person_FinalWgt64]
                                      ,[gss_pq_person_FinalWgt65]
                                      ,[gss_pq_person_FinalWgt66]
                                      ,[gss_pq_person_FinalWgt67]
                                      ,[gss_pq_person_FinalWgt68]
                                      ,[gss_pq_person_FinalWgt69]
                                      ,[gss_pq_person_FinalWgt70]
                                      ,[gss_pq_person_FinalWgt71]
                                      ,[gss_pq_person_FinalWgt72]
                                      ,[gss_pq_person_FinalWgt73]
                                      ,[gss_pq_person_FinalWgt74]
                                      ,[gss_pq_person_FinalWgt75]
                                      ,[gss_pq_person_FinalWgt76]
                                      ,[gss_pq_person_FinalWgt77]
                                      ,[gss_pq_person_FinalWgt78]
                                      ,[gss_pq_person_FinalWgt79]
                                      ,[gss_pq_person_FinalWgt80]
                                      ,[gss_pq_person_FinalWgt81]
                                      ,[gss_pq_person_FinalWgt82]
                                      ,[gss_pq_person_FinalWgt83]
                                      ,[gss_pq_person_FinalWgt84]
                                      ,[gss_pq_person_FinalWgt85]
                                      ,[gss_pq_person_FinalWgt86]
                                      ,[gss_pq_person_FinalWgt87]
                                      ,[gss_pq_person_FinalWgt88]
                                      ,[gss_pq_person_FinalWgt89]
                                      ,[gss_pq_person_FinalWgt90]
                                      ,[gss_pq_person_FinalWgt91]
                                      ,[gss_pq_person_FinalWgt92]
                                      ,[gss_pq_person_FinalWgt93]
                                      ,[gss_pq_person_FinalWgt94]
                                      ,[gss_pq_person_FinalWgt95]
                                      ,[gss_pq_person_FinalWgt96]
                                      ,[gss_pq_person_FinalWgt97]
                                      ,[gss_pq_person_FinalWgt98]
                                      ,[gss_pq_person_FinalWgt99]
                                      ,[gss_pq_person_FinalWgt100]
                                      ,[crime_exp_ind]
                                      ,[ct_house_pblms]
                                      ,[work_hrs]
                                      ,[volunteer_clean] as volunteer
                                      FROM [IDI_Sandpit].[DL-MAA2016-15].[of_gss_ind_variables_mh]",  connstr, string = TRUE)

#dataset[, grepl("FinalWgt", names(dataset) )] <- apply(person[, grepl("FinalWgt", names(dataset) )],2,FUN = function(x) replace(x,x<0,0))

# build combined dataset
compare_data <- left_join(dataset,all_weights_df,by = 'snz_uid', suffix=c(".ds",".new")) %>%
  # select("snz_uid",
  #        contains('.new'),
  #        contains('HH_'),
  #        contains('qual_'),
  #        contains('health_'),
  #        contains('birth_year'),
  #        contains('born_nz'),
  #        contains('descent_'),
  #        contains('paid_work'),
  #        contains('dvage_'),
  #        contains('Region_'),
  #        contains('Eth_'),
  #        contains('AOD_'),
  #        contains('feel_life'),
  #        contains('house_'),
  #        contains('Wgt')) %>%
  dplyr::mutate(
    house_condition = ifelse( is.na(get("house_condition")), -1, house_condition )
   ,house_satisfaction =  ifelse(is.na(get("house_satisfaction")), -1, house_satisfaction)
   ,house_satisfaction_2lev = ifelse(is.na(get("house_satisfaction_2lev")), -1, house_satisfaction_2lev)
   ,culture_belonging_nz = ifelse(is.na(get("culture_belonging_nz")), -1, culture_belonging_nz)
   ,culture_belonging_nz_2016 = ifelse(is.na(get("culture_belonging_nz_2016")), -1, culture_belonging_nz_2016)
   ,safety_neighbourhood_day =  ifelse(is.na(get("safety_neighbourhood_day")), -1, safety_neighbourhood_day)
   ,emp_labour_status = factor(ifelse(is.na(as.character(get("emp_labour_status"))), "UNK", as.character(emp_labour_status)))
   ,civic_voting = ifelse(is.na(get("civic_voting")), -1, civic_voting)
   ,econ_elsi_idx = ifelse(is.na(get("econ_elsi_idx")), -1, econ_elsi_idx)
   ,leisure_time = ifelse(is.na(get("leisure_time")), -1, leisure_time)
   ,subj_sense_of_purpose = ifelse(is.na(get("subj_sense_of_purpose")), -1, subj_sense_of_purpose)
   ,civic_generalised_trust = ifelse(is.na(get("civic_generalised_trust")), -1, civic_generalised_trust)
   ,civic_trust_police = ifelse(is.na(get("civic_trust_police")), -1, civic_trust_police)
   ,civic_trust_education = ifelse(is.na(get("civic_trust_education")), -1, civic_trust_education)
   ,civic_trust_media = ifelse(is.na(get("civic_trust_media")), -1, civic_trust_media)
   ,civic_trust_courts = ifelse(is.na(get("civic_trust_courts")), -1, civic_trust_courts)
   ,civic_trust_parliament = ifelse(is.na(get("civic_trust_parliament")), -1, civic_trust_parliament)
   ,civic_trust_health = ifelse(is.na(get("civic_trust_health")), -1, civic_trust_health)
   ,econ_material_well_being_idx = ifelse(is.na(get("civic_trust_health")), -1, civic_trust_health)
   ,econ_elsi_idx = ifelse(is.na(get("econ_elsi_idx")), -1, econ_elsi_idx)
   ,crime_exp_ind = ifelse(is.na(get("crime_exp_ind")), -1, crime_exp_ind)
  )

dummy_model <- dummyVars(data = compare_data, formula = "~house_status + emp_labour_status + know_highest_qual_4lev + income_household + family_type", sep ="_")
cat_dummies <- data.frame(predict(dummy_model, newdata = compare_data))
compare_data <- cbind(compare_data, cat_dummies)





# list of columns containing weights
wgt_prefix <- c("link_","gss_pq_person_")
wgt_list   <- c('FinalWgt', paste('FinalWgt',1:100,sep=''))




# list of columns containing parameters whose distribution we care about
num_param_list <- c(
                # "snz_spine_ind"
                "age"
                ,"sex"
                # ,"house_status"
                ,"house_tenure"
                ,"house_crowding"
                ,"house_mold"
                ,"house_cold"
                ,"house_condition"
                ,"house_satisfaction"
                ,"house_satisfaction_2lev"
                ,"safety_pub_transport"
                ,"safety_pub_transport_2lev"
                ,"safety_neighbourhood_night"
                ,"safety_neighbourhood_night_2lev"
                ,"safety_neighbourhood_day"
                ,"safety_neighbourhood_day_2lev"
                ,"safety_crime_victim"
                ,"culture_identity"
                ,"culture_identity_2lev"
                ,"culture_belonging_nz"
                ,"culture_belonging_nz_2016"
                ,"health_sf12_physcial"
                ,"health_sf12_mental"
                ,"health_status"
                ,"health_limit_activ"
                ,"health_limit_stair"
                ,"health_accomplish_phys"
                ,"health_work_phys"
                ,"health_accomplish_emo"
                ,"health_work_emo"
                ,"health_pain"
                ,"health_calm"
                ,"health_energy"
                ,"health_depressed"
                ,"health_social"
                # ,"health_pharm_cst_1year"
                # ,"health_hosp_cst_1year"
                # ,"emp_labour_status"
                ,"emp_job_last_7_days"
                ,"emp_job_start_4_weeks"
                ,"emp_job_look_last_4_weeks"
                ,"emp_job_could_start_last_week"
                ,"emp_total_hrs_worked"
                ,"emp_nbr_of_jobs"
                ,"emp_work_satisfaction"
                ,"emp_fulltime_parttime"
                ,"know_highest_qual"
                # ,"know_highest_qual_4lev"
                # ,"know_tertiary_dur_1year"
                ,"subj_life_satisfaction"
                ,"subj_sense_of_purpose"
                ,"civic_voting"
                ,"civic_generalised_trust"
                ,"civic_volunteering"
                ,"civic_trust_police"
                ,"civic_trust_education"
                ,"civic_trust_media"
                ,"civic_trust_courts"
                ,"civic_trust_parliament"
                ,"civic_trust_health"
                ,"social_time_lonely"
                ,"social_time_lonely_3lev"
                # ,"income_household"
                # ,"income_pq_intvw_mnth"
                # ,"accom_sup_1mnth_b4_intvw"
                # ,"accom_sup_1mnth_af_intvw"
                ,"econ_material_well_being_idx"
                ,"econ_elsi_idx"
                ,"leisure_time"
                ,"ethnicity_european_6lev"
                ,"ethnicity_maori_6lev"
                ,"ethnicity_pacific_6lev"
                ,"ethnicity_asian_6lev"
                ,"ethnicity_melaa_6lev"
                ,"ethnicity_other_6lev"
                ,"social_marital_status"
                # ,"family_type"
                ,"crime_exp_ind"
                ,"ct_house_pblms"
                ,"work_hrs"
                ,"volunteer"
                ,names(cat_dummies)
                )






############### run checks ###################

for(i in c("GSS2016","GSS2014", "GSS2012", "GSS2010", "GSS2008") ){
  
  print(i)
  # Filter the required GSS wave for analysis
  test.ds <- compare_data %>% filter(gss_wave == i)
  
  # storage for Mann-Whitney test results
  sink(paste0('../output/vb_comparison_pvals_ref',i,'.csv'))
  
  # Mann-Whitney U Tests
  cat('Mann-Whitney U Tests\n')
  # column headers
  cat('SIA wgt,GSS wgt,',paste(num_param_list,collapse=','),'\n')
  # iterate through weights
  for(this_wgt in wgt_list){
    
    # current weight
    cat(this_wgt)
    # weight codes
    this_sia_wgt <- paste0(wgt_prefix[1],this_wgt)
    this_snz_wgt <- paste0(wgt_prefix[2],this_wgt)
    # test distribution of weights
    test <- distribution_compare(pop1 = test.ds[[this_sia_wgt]], pop2 = test.ds[[this_snz_wgt]], standardize = TRUE)
    cat(',',test$MW_test)
    # test distribution of outcomes
    for(param in num_param_list){
      # weighted sampling of parameter
      tmp_samples <- make_samples(test.ds[[param]], wgt1=test.ds[[this_sia_wgt]], wgt2=test.ds[[this_snz_wgt]]              )
      # compare
      test <- distribution_compare(pop1 = tmp_samples$pop1, pop2 = tmp_samples$pop2)
      cat(',',test$MW_test)
    }
    # end line
    cat('\n')
  }
  
  # Kolmogorov-Smirnov Tests
  cat('Kolmogorov-Smirnov Tests\n')
  # column headers
  cat('SIA wgt,GSS wgt,',paste(num_param_list,collapse=','),'\n')
  # iterate through weights
  for(this_wgt in wgt_list){
    # current weight
    cat(this_wgt)
    # weight codes
    this_sia_wgt <- paste0(wgt_prefix[1],this_wgt)
    this_snz_wgt <- paste0(wgt_prefix[2],this_wgt)
    # test distribution of weights
    test <- distribution_compare(pop1 = test.ds[[this_sia_wgt]], pop2 = test.ds[[this_snz_wgt]], standardize = TRUE)
    cat(',',test$KS_test)
    # test distribution of outcomes
    for(param in num_param_list){
      # weighted sampling of parameter
      tmp_samples <- make_samples( test.ds[[param]] , wgt1=test.ds[[this_sia_wgt]], wgt2=test.ds[[this_snz_wgt]])
      # compare
      test <- distribution_compare(pop1 = tmp_samples$pop1, pop2 = tmp_samples$pop2)
      cat(',',test$KS_test)
    }
    # end line
    cat('\n')
  }
  
  sink()
 
  # plot standardized distribution of weights
  
  #tmp <- test.ds %>%
   # select(gss_pq_person_FinalWgt,link_FinalWgt) %>%
    #mutate(SNZ_wgt = (gss_pq_person_FinalWgt - mean(gss_pq_person_FinalWgt))/sd(gss_pq_person_FinalWgt)) %>%
    #mutate(SIA_wgt = (link_FinalWgt-mean(link_FinalWgt,na.rm=TRUE))/sd(link_FinalWgt,na.rm=TRUE))
  #ggplot() +                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
   # geom_density(data=tmp,aes(x=SNZ_wgt),col='red') +
    #geom_density(data=tmp %>% filter(!is.na(SIA_wgt)),aes(x=SIA_wgt))
  
  
  
}


## Checking why there is a difference in GSs waves


tmp<- compare_data %>% filter(gss_wave == "GSS2014") %>% select(gss_pq_person_FinalWgt,link_FinalWgt) 
test <- distribution_compare(pop1 = tmp[,"gss_pq_person_FinalWgt"], pop2 = tmp[,"link_FinalWgt"], standardize = TRUE)
pop1 <- tmp[,"gss_pq_person_FinalWgt"][is.finite(tmp[,"gss_pq_person_FinalWgt"])]
pop2 <- tmp[,"link_FinalWgt"][is.finite(tmp[,"link_FinalWgt"])]
pop1 <- sample(pop1, 4000, replace=TRUE)
pop2 <- sample(pop2, 4000, replace=TRUE)
pop1 <- pop1 - mean(pop1)
pop2 <- pop2 - mean(pop2)


pop1 <- pop1 / sd(pop1)
pop2 <- pop2 / sd(pop2)
standardise<-data.frame(cbind(pop1,pop2))

KS_test <- ks.test(tmp[,"gss_pq_person_FinalWgt"],tmp[,"link_FinalWgt"], exact=FALSE)
chart_title <-paste("GSS2014 - KS Test:",round(test$KS_test,2),"UnWeighted",round(KS_test$p.value,2),sep=" ")
plot1<- ggplot() +                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  geom_density(data=standardise,aes(x=pop1),col='red') +
  geom_density(data=standardise %>% filter(!is.na(pop2)),aes(x=pop2)) +
  ggtitle(chart_title)


tmp<- compare_data %>% filter(gss_wave == "GSS2012") %>% select(gss_pq_person_FinalWgt,link_FinalWgt) 
test <- distribution_compare(pop1 = tmp[,"gss_pq_person_FinalWgt"], pop2 = tmp[,"link_FinalWgt"], standardize = TRUE)
pop1 <- tmp[,"gss_pq_person_FinalWgt"][is.finite(tmp[,"gss_pq_person_FinalWgt"])]
pop2 <- tmp[,"link_FinalWgt"][is.finite(tmp[,"link_FinalWgt"])]
pop1 <- sample(pop1, 4000, replace=TRUE)
pop2 <- sample(pop2, 4000, replace=TRUE)
pop1 <- pop1 - mean(pop1)
pop2 <- pop2 - mean(pop2)


pop1 <- pop1 / sd(pop1)
pop2 <- pop2 / sd(pop2)
standardise<-data.frame(cbind(pop1,pop2))

KS_test <- ks.test(tmp[,"gss_pq_person_FinalWgt"],tmp[,"link_FinalWgt"], exact=FALSE)
chart_title <-paste("GSS2012 - KS Test:",round(test$KS_test,2),"UnWeighted",round(KS_test$p.value,2),sep=" ")
plot2 <-  ggplot() +                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  geom_density(data=standardise,aes(x=pop1),col='red') +
  geom_density(data=standardise %>% filter(!is.na(pop2)),aes(x=pop2)) +
  ggtitle(chart_title)


tmp<- compare_data %>% filter(gss_wave == "GSS2016") %>% select(gss_pq_person_FinalWgt,link_FinalWgt) 
test <- distribution_compare(pop1 = tmp[,"gss_pq_person_FinalWgt"], pop2 = tmp[,"link_FinalWgt"], standardize = TRUE)
pop1 <- tmp[,"gss_pq_person_FinalWgt"][is.finite(tmp[,"gss_pq_person_FinalWgt"])]
pop2 <- tmp[,"link_FinalWgt"][is.finite(tmp[,"link_FinalWgt"])]
pop1 <- sample(pop1, 4000, replace=TRUE)
pop2 <- sample(pop2, 4000, replace=TRUE)
pop1 <- pop1 - mean(pop1)
pop2 <- pop2 - mean(pop2)
pop1 <- pop1 / sd(pop1)
pop2 <- pop2 / sd(pop2)
standardise<-data.frame(cbind(pop1,pop2))
KS_test <- ks.test(tmp[,"gss_pq_person_FinalWgt"],tmp[,"link_FinalWgt"], exact=FALSE)
chart_title <-paste("GSS2016 - KS Test:",round(test$KS_test,2),"UnWeighted",round(KS_test$p.value,2),sep=" ")
plot3 <-  ggplot() +                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  geom_density(data=standardise,aes(x=pop1),col='red') +
  geom_density(data=standardise %>% filter(!is.na(pop2)),aes(x=pop2)) +
  ggtitle(chart_title)

grid.arrange(plot1,plot2,plot3,ncol=3)


person_wave_GSS2016 <- person %>% filter(gss_id_collection_code == "GSS2016") %>% select (   age_groups_coarse
                                                                                             ,region_auck
                                                                                             ,home_trust_ind
                                                                                             ,home_own_ind
                                                                                             ,home_hnz_ind
                                                                                             ,home_other_sh_ind
                                                                                             ,home_rent_ind
                                                                                             ,home_overcrowding_ind
                                                                                             ,home_cold_ind
                                                                                             ,home_mould_ind)
person_wave_GSS2014 <- person %>% filter(gss_id_collection_code == "GSS2014") %>% select (   age_groups_coarse
                                                                                             ,region_auck
                                                                                             ,home_trust_ind
                                                                                             ,home_own_ind
                                                                                             ,home_hnz_ind
                                                                                             ,home_other_sh_ind
                                                                                             ,home_rent_ind
                                                                                             ,home_overcrowding_ind
                                                                                             ,home_cold_ind
                                                                                             ,home_mould_ind)
 person_wave_GSS2012 <-  person %>% filter(gss_id_collection_code == "GSS2012") %>% select (   age_groups_coarse
                                                                                               ,region_auck
                                                                                               ,home_trust_ind
                                                                                               ,home_own_ind
                                                                                               ,home_hnz_ind
                                                                                               ,home_other_sh_ind
                                                                                               ,home_rent_ind
                                                                                               ,home_overcrowding_ind
                                                                                               ,home_cold_ind
                                                                                               ,home_mould_ind)
 person_wave_GSS2010 <-  person %>% filter(gss_id_collection_code == "GSS2010") %>% select (   age_groups_coarse
                                                                                               ,region_auck
                                                                                               ,home_trust_ind
                                                                                               ,home_own_ind
                                                                                               ,home_hnz_ind
                                                                                               ,home_other_sh_ind
                                                                                               ,home_rent_ind
                                                                                               ,home_overcrowding_ind
                                                                                               ,home_cold_ind
                                                                                               ,home_mould_ind)
 
 
 
 

summary(person_wave_GSS2014[,"age_groups_coarse"])
summary(person_wave_GSS2012[,"age_groups_coarse"])
summary(person_wave_GSS2010[,"age_groups_coarse"])

summary(person_wave_GSS2014[,"region_auck"])
summary(person_wave_GSS2012[,"region_auck"])
summary(person_wave_GSS2010[,"region_auck"])

summary(person_wave_GSS2014[,"home_trust_ind"])
summary(person_wave_GSS2012[,"home_trust_ind"])
summary(person_wave_GSS2010[,"home_trust_ind"])

summary(person_wave_GSS2014[,"home_own_ind"])
summary(person_wave_GSS2012[,"home_own_ind"])
summary(person_wave_GSS2010[,"home_own_ind"])





