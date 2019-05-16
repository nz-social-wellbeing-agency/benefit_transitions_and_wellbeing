
# ================================================================================================ #
# Description: Code for recalibration of point-estimate and replicate weights of GSS Person data 
#   using the survey package to compensate for loss of sample size due to IDI Spine linking issues.
#   The final weights given to individuals in the GSS person data is re-adjusted back to
#   the benchmark population totals used by StatsNZ, after individuals drop out of the sample due to
#   problems with IDI linking.
#
# Input: 
# gss_clean.[gss_person] = dataset with all the person-level variables & weights
# gss_clean.[gss_household] = dataset with all the household-level variables & weights
#
# Output: 
# linked_rep_weights = Dataset with the recalibrated weights for IDI spine-linked individuals.
# [DL-MAA2016-15].of_gss_calibrated_weights = SQL table with these new weights
#
# Author: C MacCormick, V Benny
#
# Dependencies:
# SIAtoolbox = to read in the table from the database
# IDI_Sandpit.[DL-MAA2016-15].[of_gss_ind_variables] table with all the source variables and weights
#
# Notes:
# NA
#
# History (reverse order): 
# 22 Sep 2017 SIA v1
# 02 Oct 2018 WJ - Modified code to add in constraints for GSS 2016
# ================================================================================================ #



############################# Create person dataset ##########################################

# Read in GSS person dataset and the spine linkage indicator
dataset <- SIAtoolbox::read_sql_table("select *
                                      from IDI_Sandpit.[DL-MAA2016-15].[of_gss_ind_variables_mh]",
                                      connstr, string = TRUE)



# Create population benchmark variables
person <- dataset %>% 
  # Derive benchmark categories
  mutate(
    age_groups = cut(gss_pq_dvage_code, breaks = c(seq(15,75,5), Inf), right = FALSE)
    ,age_groups_maori = cut(gss_pq_dvage_code, breaks = c(15, 30, Inf), right = FALSE)
    ,sex_factor = factor(gss_hq_sex_dev)
    ,age_sex_ind = interaction(age_groups, sex_factor)
    # ,age_sex_ind = factor(gsub("\\[|\\)|\\.|,", "", age_sex_ind))
    ,maori_ind = factor(ifelse(get("P_MAORI") == 0 | is.na(get("P_MAORI")), 0, 1))
    ,pasifika_ind = factor(ifelse(get("P_PACIFIC") == 0 | is.na(get("P_PACIFIC")),0,1)) 
    ,asian_ind = factor(ifelse(get("P_ASIAN") == 0 | is.na(get("P_ASIAN")),0,1)) 
    #,maori_age_ind = interaction(age_groups_maori, maori_ind)
    #,maori_age_ind = factor(gsub("\\[|\\)|\\.|,", "", maori_age_ind))
    ,region_group = factor(ifelse(gss_hq_regcouncil_dev %in% c(16, 17, 18), 16, gss_hq_regcouncil_dev))
    ,region_auck = factor(ifelse(gss_hq_regcouncil_dev == 2, 1, 0))
    #,two_adult = factor(ifelse(adult_count == 2, 1, 0))
    #,one_adult = factor(ifelse(adult_count == 1, 1, 0))
    ,maori_15to29 = factor(ifelse(maori_ind == "1" & between(gss_pq_dvage_code, 15, 29), 1, 0))
    ,maori_30plus = factor(ifelse(maori_ind == "1" & between(gss_pq_dvage_code, 30, Inf), 1, 0))
    #,age_groups_coarse = cut(gss_pq_dvage_code, breaks = c(15, 19, 26, 40, 56, 65, Inf), right = FALSE)
    ,age_groups_coarse = cut(gss_pq_dvage_code, breaks = c(15,20,35,65,Inf), right = FALSE)
    
    # House ownership
    ,home_rent_ind = factor(ifelse(is.na(get("gss_hq_house_pay_rent_code")) | !(get("gss_hq_house_pay_rent_code") == 1), 0, 1))
    ,home_trust_ind = factor(ifelse(is.na(get("gss_hq_house_trust")) | !(get("gss_hq_house_trust")) == 1, 0, 1))
    ,home_own_ind = factor(ifelse(is.na(get("gss_hq_house_own")) | !(get("gss_hq_house_own") == 1), 0, 1))
    ,home_hnz_ind = factor(ifelse(is.na(get("gss_hq_house_who_owns_code")) | !(get("gss_hq_house_who_owns_code") ==13), 0, 1))
    ,home_other_sh_ind = factor(ifelse(is.na(get("gss_hq_house_who_owns_code")) | 
                                         !(get("gss_hq_house_who_owns_code") %in% c(12, 14)), 0, 1))
    
    # # Housing quality
    ,home_overcrowding_ind = factor(house_crowding_ind)
    ,home_cold_ind = factor(gss_pq_house_cold_code)
    ,home_mould_ind = factor(gss_pq_house_mold_code)
    
    # Income
    # ,hh_income_eq_bands = cut(hh_income_eq, 
    #                           breaks = c(0, 30000, 70000, 100000, Inf),
    #                           labels = c("<$30k", "$30k-$70k", "$70k-$100k", ">$100k"))
    ,hh_income_ind = factor(ifelse(hh_gss_income %in% c("0", "-Loss"), 0, 1))
    
    # gss benefit indicator
   ,benefit_gss_ind = factor(ifelse(gss_unemp_jobseek+gss_sickness+gss_invalid_support+gss_soleprnt_domestic+gss_oth_ben>0, 1, 0))
   ,life_satisfaction_bin = factor(ifelse(get("life_satisfaction_bin") == 0 | is.na(get("life_satisfaction_bin")), 0, 1))
   
  #, life_satisfaction_bin = factor(life_satisfaction_bin)
  
  ,mental_health_ind = factor(ifelse(health_nzsf12_mental <= 28 | is.na(get("health_nzsf12_mental")), 1 , 0))
   # , mental_health_ind = factor(mental_health_ind)
   # ,mental_health_ind=factor(ifelse(ment_health_sf12_score <= 28,"Severe",ifelse(ment_health_sf12_score <= 39, "Common","No Disorder")))
    , time_lonely_ind = factor(time_lonely_ind)
    , safety_ind =factor(safety_ind)
  
    )

#NB negative weights in GSS 2016
person[, grepl("FinalWgt", names(person) )] <- apply(person[, grepl("FinalWgt", names(person) )],2,FUN = function(x) replace(x,x<0,0))

#quantile check for mental health ind

# gss2008 <- person %>%filter(gss_id_collection_code =="GSS2008") 
# prob<- c(0,0.05,0.15,0.75,1)
#quantiles08 <- quantile(gss2008$health_nzsf12_mental,na.rm=TRUE, prob=prob)
#quantiles08

#gss2010 <- person %>%filter(gss_id_collection_code =="GSS2010") 
#quantiles10 <- quantile(gss2010$health_nzsf12_mental,na.rm=TRUE, prob=prob)
#quantiles10

#gss2012 <- person %>%filter(gss_id_collection_code =="GSS2012") 
#quantiles12 <- quantile(gss2012$health_nzsf12_mental,na.rm=TRUE, prob=prob)
#quantiles12

#gss2014 <- person %>%filter(gss_id_collection_code =="GSS2014") 
#quantiles14 <- quantile(gss2014$health_nzsf12_mental,na.rm=TRUE, prob=prob)
#quantiles14

#gss2016 <- person %>%filter(gss_id_collection_code =="GSS2016") 
#quantiles16 <- quantile(gss2016$health_nzsf12_mental,na.rm=TRUE, prob=prob)
#quantiles16



# Create a separate dataset with IDI-spine linked individuals
person_linked <- person %>% filter(snz_spine_ind == 1) %>% dplyr::select(-snz_spine_ind)


############################# Weight Recalibration ##########################################

# Get list of weights that need to be recalibrated to the "pre- spine linking" benchmark totals
repweight_names <- names(dataset[grepl("FinalWgt", names(dataset))])


# Empty data frame to hold all weights
all_weights_df <- data.frame()

for(i in levels(dataset$gss_id_collection_code)){
  
  print(i)
  
  #added another filter to remove out negative weights specifically for GSS 2016 for the 2018/08 refresh
  
  person_linked_wave <- filter(person_linked, gss_id_collection_code == i)
  person_wave <- filter(person, gss_id_collection_code == i)
  
  # Create a new dataset to hold the new weights post recalibration, including the point estimate weights
  linked_rep_weights <- person_linked_wave$snz_uid
  
  # Loop through each weight variable in spine linked dataset, and recalibrate to the benchmark totals in the 
  # corresponding weights in pe-linkage dataset
  for( repweight in repweight_names){
    print(repweight)
    
    # Create a benchmark population vector
    pop.totals <- c(
      `(Intercept)` = person_wave %>%
        summarise(tot = sum(!!sym(repweight))) %>% 
        as.numeric()
      ,create_bmark_vector(person_wave, c(
        "age_groups_coarse"
        #  "age_sex_ind", 
        # "one_adult", 
        # "two_adult", 
        # "region_group",
        ,"region_auck"
        # "maori_15to29",
        # "maori_30plus"
        ,"home_trust_ind"
        ,"home_own_ind"
        ,"home_hnz_ind"
        ,"home_other_sh_ind"
        ,"home_rent_ind"
        ,"home_overcrowding_ind"
        ,"home_cold_ind"
        ,"home_mould_ind"
       ,"hh_income_ind"
        ,"time_lonely_ind"
        ,"safety_ind"
        ,"mental_health_ind"
       ,"life_satisfaction_bin"
        
      ), 
      repweight)
    )
    
    
    
    # Create survey object for the linked data to prepare for recalibration and perform recalibration
    person_linked_svy <- svydesign(id = ~1, weights = as.formula(paste0("~", repweight)), data = person_linked_wave)
    person_calibrate_link <- calibrate(
      person_linked_svy,
      ~ age_groups_coarse
      # age_sex_ind
      # + two_adult
      # + region_group
      + region_auck
      # + one_adult
      # + maori_15to29
      # + maori_30plus
      + home_trust_ind
      + home_own_ind
      + home_hnz_ind
      + home_other_sh_ind
      + home_rent_ind
      + home_overcrowding_ind
      + home_cold_ind
      + home_mould_ind
      + time_lonely_ind
      + safety_ind
      + mental_health_ind
      + life_satisfaction_bin
     + hh_income_ind
      , pop.totals
      , bounds = c(0, 15*mean(person_wave[, repweight]) ) #The new weight shouldn't be larger than 15 times the original.
      , bounds.const = TRUE
    )
    

    
    # Get the recalibrated weight and set other attributes in the object to null.
    postlinkweights <- weights(person_calibrate_link)
    attributes(postlinkweights) <- c()
    linked_rep_weights <- cbind(linked_rep_weights, postlinkweights)
  }
  
  # Finalise the dataframe with all the newly recalibrated weights and assign column names.
  linked_rep_weights <- data.frame(linked_rep_weights)
  linked_rep_weights <- cbind(linked_rep_weights, rep(i, nrow(linked_rep_weights)) )
  names(linked_rep_weights) <- c("snz_uid", gsub("gss_pq_person", "link", repweight_names), "gss_id_collection_code")
  
  #Row bind of weight data frames
  
  ifelse(length(names(all_weights_df)) == 0, 
         all_weights_df <- linked_rep_weights, 
         all_weights_df <- rbind(all_weights_df, linked_rep_weights))
  
}



############################# Post reweighting checks ##########################################

# Are there any weights that are lower than 1?
check_zeros <- sapply(all_weights_df[, grepl("link_FinalWgt", names(all_weights_df) )],
                      FUN = function(x) length(x[x < 1]) > 0 )
check_nas <- sapply(all_weights_df[, grepl("link_FinalWgt", names(all_weights_df) )],
                    FUN = function(x) length(x[is.na(x)]) > 0 )


# Write the recalibrated weights dataset to the database
connstr <- "DRIVER=ODBC Driver 11 for SQL Server; "
connstr <- paste0(connstr, "Trusted_Connection=Yes; ")
connstr <- paste0(connstr, paste0("DATABASE=", "IDI_Sandpit", " ; "))
connstr <- paste0(connstr, "SERVER=WPRDSQL36.stats.govt.nz, 49530")
conn <- odbcDriverConnect(connstr)
sqlSave(conn, all_weights_df, tablename = "[DL-MAA2016-15].of_gss_calibrated_weights_mh_extravar", verbose = TRUE,
        rownames = FALSE, fast=FALSE)

# Read the dataset if recalibration not run
# all_weights_df <- SIAtoolbox::read_sql_table("select *
#                                      from IDI_Sandpit.[DL-MAA2016-15].[of_gss_calibrated_weights]",
#                                      connstr, string = TRUE)




# Remove unwanted datasets to free up memory
rm(person_wave, person_linked_wave)


