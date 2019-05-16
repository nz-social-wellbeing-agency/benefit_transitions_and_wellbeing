# ================================================================================================ #
# Description: Creating descriptive statistics with new GSS weights.
#
# Input: 
# [DL-MAA2016-15].of_gss_calibrated_weights
# [DL-MAA2016-15].of_gss_ind_variables
#
# Output: 
#
# Author: C MacCormick and V Benny
#
# Dependencies:
#
# Notes:
#
# History (reverse order): 
# 4 October 2017 CM v1
# 16 October 2018 WJ Added in variables of interest regarding family type and tax credit measures
# 31 Oct 2018 BV specific version for couples income with linked partners only !
# ================================================================================================ #

# rm(list = ls())

connstr <- set_conn_string(db = "IDI_Sandpit")
library(DescTools)

# Left join personal vars table with new weights
gss_person <- read_sql_table("select * from [DL-MAA2016-15].of_gss_desc_stats_tab_mh18p_1mth where gss_wave in ('GSS2014', 'GSS2016')"
                             ,connection_string = connstr
                             ,string = TRUE
)

gss_person[is.na(gss_person$snz_spine_ind_partner), "snz_spine_ind_partner"] <- -1

gss_person <- gss_person %>% filter(snz_spine_ind_partner==1) %>% mutate(rounded_wgt_cnt=RoundTo(link_FinalWgt, multiple=1000))


# List of variables on which stats are required
var_list <- quos(
  admin_benefit_flag
  ,family_agg_type
)
measure_list <- quos(hhld_transfer_income_weekly
                     ,hhld_other_income_weekly
                     ,hhld_main_benefit_weekly
                     ,hhld_tax_cred_weekly
                     ,hhld_supp_benefit_weekly
                     ,hhld_total_income_weekly
                     ,hhld_transfer_income_weekly_af
                     ,hhld_other_income_weekly_af
                     ,hhld_main_benefit_weekly_af
                     ,hhld_tax_cred_weekly_af
                     ,hhld_supp_benefit_weekly_af
                     ,hhld_total_income_weekly_af)


##,econ_material_well_being_idx2
##,family_size

# weighted means
bivar <- gss_person %>% group_by(gss_wave, admin_benefit_flag, family_agg_type) %>% 
                        summarise(wtcnt= random_round(sum(as.integer(link_FinalWgt)),  n=1000),
                                  uwtcnt=random_round(n(), 3),
                                  hhld_transfer_income_weekly = sum(hhld_transfer_income_weekly*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)), 1000),
                                  hhld_other_income_weekly = sum(hhld_other_income_weekly*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)), 1000),
                                  hhld_main_benefit_weekly = sum(hhld_main_benefit_weekly*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_tax_cred_weekly = sum(hhld_tax_cred_weekly*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_supp_benefit_weekly = sum(hhld_supp_benefit_weekly*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_total_income_weekly = sum(hhld_total_income_weekly*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_transfer_income_weekly_af = sum(hhld_transfer_income_weekly_af*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_other_income_weekly_af = sum(hhld_other_income_weekly_af*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_main_benefit_weekly_af = sum(hhld_main_benefit_weekly_af*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_tax_cred_weekly_af = sum(hhld_tax_cred_weekly_af*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt),  1000)),
                                  hhld_supp_benefit_weekly_af = sum(hhld_supp_benefit_weekly_af*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000),
                                  hhld_total_income_weekly_af = sum(hhld_total_income_weekly_af*link_FinalWgt)/random_round(sum(as.integer(link_FinalWgt)),  1000)
                        ) 


bivar
write.xlsx(as.data.frame(bivar) 
           , file = "../output/desc_stats_rr_couples_on_ben_1mth_2.xlsx", sheetName = "bivariate_means", row.names = FALSE,
           append = TRUE)

####################################################################################################
# Functions to generate the statistics


# Bivariate stats generation
bivariate_means <- function(inputVar, inputVar2, measure){
  
  # enquo_input <- enquo(inputVar)
  enquo_input <- inputVar
  enquo_input2 <- inputVar2
  print(enquo_input2)
  
  
  tmp1 <- gss_person_final_svy %>%
    mutate(var = factor(!!enquo_input)
           ,var2 = factor(!!enquo_input2)
           ,meas = as.numeric(!!measure)) %>%
    filter(!is.na(var) & !is.na(var2)) %>%
    group_by(var, var2) %>%
    summarise(
      wtmean = survey_mean(meas, na.rm = TRUE, vartype = c("ci", "se"))
      # wtmean2 = sum(meas*rounded_wgt_cnt)/sum(rounded_wgt_cnt)
      # ,wttotal = survey_total(na.rm = TRUE, vartype = c("ci", "se"))
      # ,unwttotal = unweighted(n())
    ) %>%
    mutate(var_name = rlang::quo_text(enquo_input)
           ,var_name2 = rlang::quo_text(enquo_input2)
           ,measure_name = rlang::quo_text(measure)
    )
  
  tmp2 <- gss_person_final_svy %>%
    mutate(var = factor(!!enquo_input)
           ,var2 = factor(!!enquo_input2)) %>%
    filter(!is.na(var) & !is.na(var2)) %>%
    group_by(var, var2) %>%
    summarise(
      unwttotal = unweighted(n())
    ) %>%
    mutate(var_name = rlang::quo_text(enquo_input)
           ,var_name2 = rlang::quo_text(enquo_input2)
           ,measure_name = rlang::quo_text(measure)
    )
  
  tmp3 <- gss_person_final_svy %>%
    mutate(var = factor(!!enquo_input)
           ,var2 = factor(!!enquo_input2)
           ,meas = as.numeric(!!measure)) %>%
    filter(!is.na(var) & !is.na(var2)) %>%
    group_by(var, var2) %>%
    summarise(
      # wtmean = survey_mean(meas, na.rm = TRUE, vartype = c("ci", "se"))
      wttotal = survey_total(na.rm = TRUE, vartype = c("ci", "se"))
      # wttotal2 = sum(rounded_wgt_cnt)
      # ,unwttotal = unweighted(n())
    ) %>%
    mutate(var_name = rlang::quo_text(enquo_input)
           ,var_name2 = rlang::quo_text(enquo_input2)
           ,measure_name = rlang::quo_text(measure)
    )
  
  tmp <- left_join(tmp1, tmp2, by = c("var", "var_name", "var2", "var_name2", "measure_name")) %>%
    left_join(tmp3, by = c("var", "var_name", "var2", "var_name2", "measure_name"))
  return(tmp)
  
}


# Univariate stats generation
univariate_means <- function(inputVar, measure, weighted = TRUE){
  
  # enquo_input <- enquo(inputVar)
  enquo_input <- inputVar
  print(enquo_input)
  print(measure)
  
  # if weighted is TRUE, then run the below aggregation
  if(weighted){
    tmp <- gss_person_final_svy %>%
      mutate(var = factor(!!enquo_input)
             ,meas = as.numeric(!!measure)) %>%
      filter(!is.na(var)) %>% # Filter NAs
      group_by(var) %>%
      summarise(wtmean = survey_mean(meas, na.rm = TRUE, vartype = c("ci", "se"))
                ,wttotal = survey_total(na.rm = TRUE, vartype = c("ci", "se"))
                ,unwttotal = unweighted(n())
      ) %>%
      mutate(var_name = rlang::quo_text(enquo_input)
             ,measure_name = rlang::quo_text(measure))
  } else{
    tmp <- gss_person_final_svy %>%
      mutate(var = factor(!!enquo_input)) %>%
      filter(!is.na(var)) %>% # Filter NAs
      group_by(var) %>%
      summarise(unwttotal = unweighted(n)) %>%
      mutate(var_name = rlang::quo_text(enquo_input)
             ,measure_name = rlang::quo_text(measure))
  }
  return(tmp)
}




####################################################################################################

# Declare lists and an iterator for storing intermediate datasets from each wave
univariate_list <- list()
bivariate_list <- c()
listcounter <- 1

for(wave in c("GSS2016", "GSS2014") ) {
  
  # Create the survey object for generating stats
  gss_person_final_svy <- svrepdesign(id = ~1
                                      , weights = ~link_FinalWgt
                                      , repweights = "link_FinalWgt_[0-9]"
                                      , data = gss_person %>% filter(gss_wave == wave)
                                      , type = "JK1"
                                      , scale = 0.99
  ) %>%
    as_survey_rep()
  
  # Create an exclusion variable list for each wave.
  if(wave == "GSS2014" ) {
    gssvars <- var_list[unlist(lapply(var_list, function(x) 
      x != c(quos(gss_pq_house_condition_code)) &
        x != c(quos(housing_satisfaction)) &
        x != c(quos(housing_sat_ind)) &
        x != c(quos(safety_day_ind)) &
        x != c(quos(gss_pq_safe_day_hood_code)) &
        x != c(quos(gss_pq_voting)) &
        x != c(quos(voting_ind)) &
        x != c(quos(no_access_natural_space)) &
        x != c(quos(no_free_time))
    ))]
    measurevars <- measure_list
  }  
  else if(wave == "GSS2016") {
    gssvars <- var_list[unlist(lapply(var_list, function(x) 
      x != c(quos(gss_pq_house_condition_code)) &
        x != c(quos(housing_satisfaction)) &
        x != c(quos(housing_sat_ind)) &
        x != c(quos(safety_day_ind)) &
        x != c(quos(gss_pq_safe_day_hood_code)) &
        x != c(quos(no_access_natural_space)) &
        x != c(quos(no_free_time))
    ))]
    measurevars <- measure_list
  }
  
##GSS wave 2010 most of the values are 77 or Unknown - some stuff which is done by Stats NZ
  else if(wave == "GSS2010") {
    gssvars <- var_list[unlist(lapply(var_list, function(x) 
      x != c(quos(family_agg_type)) 
    ))]
    measurevars <- measure_list[unlist(lapply(measure_list, function(x) 
      x != c(quos(econ_material_well_being_idx2)) &
        x != c(quos(family_size)) 
    ))]
  }
  
  else{
    gssvars <- var_list
    measurevars <- measure_list[unlist(lapply(measure_list, function(x) 
      x != c(quos(econ_material_well_being_idx2)) &
      x != c(quos(family_size)) 
    ))]
  }
  
  ######## Univariate Statistics - Weighted ########
  univariate_tbl <- data.frame()
  for(i in 1:length(gssvars)){
    print(i)
    for(j in 1:length(measurevars)){
      print(j)
      univariate_tbl <- rbind(univariate_tbl, univariate_means(gssvars[[i]], measurevars[[j]]))
    }
      
  }
  
  # univariate_tbl$wttotal <- rrn(as.integer(univariate_tbl$wttotal), 1000)
  # univariate_tbl$unwttotal <- rrn(univariate_tbl$unwttotal, 3)
 # write.xlsx(as.data.frame(univariate_tbl) %>% mutate(wttotal = rrn(as.integer(univariate_tbl$wttotal), 1000)
  #                                                    ,unwttotal = rrn(univariate_tbl$unwttotal, 3))
  #             , file = "../output/univariate_desc_stats_rr_out.xlsx", sheetName = wave, row.names = FALSE,
#              append = TRUE)
 # write.xlsx(as.data.frame(univariate_tbl), file = "../output/univariate_desc_stats_out.xlsx", sheetName = wave, row.names = FALSE,
 #            append = TRUE)
  
  # Save the summary table for later use
  univariate_list[[listcounter]] <- univariate_tbl
  
  ######## Bivariate Statistics at housing groups level- Weighted ########
  bivariate_tbl <- data.frame()
  for(i in 1:length(gssvars)){
    for(j in 1:length(gssvars)){
      for(k in 1:length(measurevars)){
        if(! (rlang::quo_text(gssvars[[i]]) == rlang::quo_text(gssvars[[j]])) )
          bivariate_tbl <- rbind(bivariate_tbl, bivariate_means(gssvars[[i]], gssvars[[j]], measurevars[[k]] ))
      }
    }
      
  }
  
 # write.xlsx(as.data.frame(bivariate_tbl) %>% mutate(wttotal = rrn(as.integer(bivariate_tbl$wttotal), 1000)
  #                                                   ,unwttotal = rrn(bivariate_tbl$unwttotal, 3))
 #            , file = "../output/bivariate_desc_stats_weighted_rr_out.xlsx", sheetName = wave, row.names = FALSE,
 #             append = TRUE)
 # write.xlsx(as.data.frame(bivariate_tbl), file = "../output/bivariate_desc_stats_weighted_out.xlsx", sheetName = wave, row.names = FALSE,
#             append = TRUE)
  
  # Save the summary table for later use
  bivariate_list[[listcounter]] <- bivariate_tbl
  
  # Increment counter for list
  listcounter <- listcounter + 1
  
}


names(univariate_list) <- c("GSS2016","GSS2014")
names(bivariate_list) <- c("GSS2016","GSS2014")

univar_agg <-c()
bivar_agg <-c()

univar_agg <-rbind(univariate_list$GSS2016%>%dplyr::select(var, var_name,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2016"),
       univariate_list$GSS2014%>%dplyr::select(var, var_name, wtmean,measure_name, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                  %>%mutate(wave="GSS2014")
       )



bivar_agg <-rbind(bivariate_list$GSS2016%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean2, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal, wttotal2)
                   %>%mutate(wave="GSS2016"),
                   bivariate_list$GSS2014%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean2, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal, wttotal2)
                   %>%mutate(wave="GSS2014")
)




write.xlsx(as.data.frame(univar_agg) %>% mutate(wttotal = random_round(as.integer(univar_agg$wttotal), 1000)
                                                ,unwttotal = random_round(univar_agg$unwttotal, 3))
           , file = "../output/desc_stats_rr_couples_on_ben.xlsx", sheetName = "univariate_means", row.names = FALSE,
           append = TRUE)

write.xlsx(as.data.frame(bivar_agg) %>% mutate(wttotal = random_round(as.integer(bivar_agg$wttotal), 1000)
                                                ,unwttotal = random_round(bivar_agg$unwttotal, 3))
           , file = "../output/desc_stats_rr_couples_on_ben.xlsx", sheetName = "bivariate_means", row.names = FALSE,
           append = TRUE)





# Calculate aggregate statistics for univariate case
#univar_agg <- univariate_list$GSS2016 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) %>%
#  full_join(univariate_list$GSS2014 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("16", "14")) %>%
#  full_join(univariate_list$GSS2012 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("14", "12")) %>%
#  full_join(univariate_list$GSS2010 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("12", "10")) %>%
#  left_join(univariate_list$GSS2008 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("10", "08")) %>%
#  dplyr::mutate(overallse = sqrt( ( ifelse(is.na(wtmean_se14), 0, wtmean_se16^2) + 
#                                ifelse(is.na(wtmean_se14), 0, wtmean_se14^2) + 
#                               ifelse(is.na(wtmean_se12), 0, wtmean_se12^2) + 
#                               ifelse(is.na(wtmean_se10), 0, wtmean_se10^2)  + 
#                               ifelse(is.na(wtmean_se08), 0, wtmean_se08^2) ) /
#                             (ifelse(is.na(wtmean_se16), 0, 1) + 
#                               ifelse(is.na(wtmean_se14), 0, 1) + 
#                                ifelse(is.na(wtmean_se12), 0, 1) + 
#                                ifelse(is.na(wtmean_se10), 0, 1) + 
#                                ifelse(is.na(wtmean_se08), 0, 1))^2 
#  )
#  )


#  full_join(univariate_list$GSS2014 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("16", "14")) %>%
#  full_join(univariate_list$GSS2012 %>% dplyr::select(var, var_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , by = c("var", "var_name"), suffix = c("14", "12"))

#univar_agg$overallmean <- rowMeans(univar_agg[,grepl("mean[0-9]", names(univar_agg))], na.rm = TRUE)
#univar_agg$overall_low <- univar_agg$overallmean - 1.96*univar_agg$overallse
#univar_agg$overall_upp <- univar_agg$overallmean + 1.96*univar_agg$overallse

# univar_agg$overallse <- rowMeans(univar_agg[,grepl("mean_var[0-9]", names(univar_agg))], na.rm = TRUE)

# Calculate aggregate statistics for bivariate case
#bivar_agg <- bivariate_housing_list$GSS2014 %>% select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) %>%
 # full_join(bivariate_housing_list$GSS2012 %>% select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , 
  #          by = c("var", "var_name", "var2", "var_name2"), suffix = c("14", "12")) %>%
  #full_join(bivariate_housing_list$GSS2010 %>% select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , 
   #         by = c("var", "var_name", "var2", "var_name2"), suffix = c("12", "10")) %>%
  #full_join(bivariate_housing_list$GSS2008 %>% select(var, var_name, var2, var_name2, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal) , 
   #         by = c("var", "var_name", "var2", "var_name2"), suffix = c("10", "08"))%>%
#  mutate(overallse = sqrt( ( ifelse(is.na(wtmean_se14), 0, wtmean_se14^2) + 
 #                              ifelse(is.na(wtmean_se12), 0, wtmean_se12^2) + 
     #                          ifelse(is.na(wtmean_se10), 0, wtmean_se10^2)  + 
  #                             ifelse(is.na(wtmean_se08), 0, wtmean_se08^2) ) /
   #                          (ifelse(is.na(wtmean_se14), 0, 1) + 
    #                            ifelse(is.na(wtmean_se12), 0, 1) + 
      #                          ifelse(is.na(wtmean_se10), 0, 1) + 
       #                         ifelse(is.na(wtmean_se08), 0, 1))^2 
 # )
 # )
#bivar_agg$overallmean <-  rowMeans(bivar_agg[,grepl("mean[0-9]", names(bivar_agg))], na.rm = TRUE)
#bivar_agg$overall_low <- bivar_agg$overallmean - 1.96*bivar_agg$overallse
#bivar_agg$overall_upp <- bivar_agg$overallmean + 1.96*bivar_agg$overallse
#write.xlsx(as.data.frame(bivar_agg), file = "./output/bivariate_agg.xlsx", sheetName = "Data", row.names = FALSE)

# Create overall stats by wave for link rates and total counts (weighted and unweighted)
#overall_tbl <- gss_person %>% 
 # group_by(gss_id_collection_code, snz_spine_ind) %>%
  #summarise(unwttot = n()
   #         ,wttot = sum(gss_pq_person_FinalWgt_nbr))

#write.xlsx(as.data.frame(overall_tbl), file = "./output/overall_desc_stats_unweighted_out.xlsx", sheetName = "All_waves", row.names = FALSE, 
#           append = TRUE)




############################# Declare Functions ##########################################

# This function reads in a treatment & control group and a list of variables. 
# It then draws a random sample of rows from each group (with replacement) and calculates the 
# difference in means for each of these variables between treatment and control datasets.
sample_from_data <- function(treat, control, varlist){
  tsample <- sample_n(tbl = treat %>% select(one_of(varlist)), 
                      size = 0.5*nrow(treat), replace = TRUE )
  csample <- sample_n(tbl = control %>% select(one_of(varlist)), 
                      size = 0.5*nrow(control), replace = TRUE )
  return( (na.omit(tsample) %>% summarise_all(mean)) - (na.omit(csample) %>% summarise_all(mean)) )
  
}


varlist <- c("health_nzsf12_mental", 
         "health_nzsf12_physical",
         "multiple_disadvantage_index",
         "econ_material_well_being_idx2")

# Define number of replicates
repcount <- 500
confidence_levels <- c(0.025, 0.975)
confints <- data.frame(colname = character(), qlower = numeric(), qupper = numeric(), meanval = numeric(), stringsAsFactors = FALSE)

gss_person_diff_ben_dep <- gss_person %>% 
  select(health_nzsf12_mental, 
         health_nzsf12_physical,
         multiple_disadvantage_index,
         econ_material_well_being_idx2,
         admin_benefit_flag ,
         dependent_children,gss_wave)%>% 
  filter(admin_benefit_flag==1, dependent_children=="1. Has Dependent Child(ren)", gss_wave =="GSS2014")

gss_person_diff_noben_dep <- gss_person %>% 
  select(health_nzsf12_mental,
         health_nzsf12_physical,
         multiple_disadvantage_index,
         econ_material_well_being_idx2,
         admin_benefit_flag ,
         dependent_children, gss_wave)%>%
  filter(admin_benefit_flag==0, dependent_children=="1. Has Dependent Child(ren)", gss_wave =="GSS2014")

gss_person_diff_ben_nodep <- gss_person %>% 
  select(health_nzsf12_mental, 
         health_nzsf12_physical,
         multiple_disadvantage_index,
         econ_material_well_being_idx2,
         admin_benefit_flag ,
         dependent_children, gss_wave)%>% 
  filter(admin_benefit_flag==1, dependent_children=="2. Doesnt Have Dependent Child(ren)", gss_wave =="GSS2014")

gss_person_diff_noben_nodep <- gss_person %>% 
  select(health_nzsf12_mental,
         health_nzsf12_physical,
         multiple_disadvantage_index,
         econ_material_well_being_idx2,
         admin_benefit_flag ,
         dependent_children, gss_wave)%>% 
  filter(admin_benefit_flag==0, dependent_children=="2. Doesnt Have Dependent Child(ren)", gss_wave =="GSS2014")

confints <-c()


for(this_var in varlist){
  print(this_var)
  bootstrap_sample <- simplify2array(replicate(repcount, sample_from_data(gss_person_diff_ben_dep, gss_person_diff_noben_dep, this_var), simplify = "matrix" ))
  bounds <- quantile(bootstrap_sample  , prob = confidence_levels )
  this_row <- data.frame(colname = this_var, 
                         qlower = unname(bounds)[1],
                         qupper = unname(bounds)[2],
                         meanval = mean(na.omit(gss_person_diff_ben_dep[,this_var]) - mean(na.omit(gss_person_diff_noben_dep[,this_var])),
                         wave = "GSS2014"               )
  )
  confints <- rbind(confints,this_row)
}



