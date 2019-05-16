# ================================================================================================ #
# Description: Creating descriptive statistics with new GSS weights.
#
# Input: 
# [DL-MAA2016-15].of_gss_desc_stats_tab_mh
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
#16 October 2018 WJ Added in variables of interest regarding family type and tax credit measures
#
#
# ================================================================================================ #

# rm(list = ls())

library(SIAtoolbox)
library(RODBC)
library(dplyr)
library(survey)
library(srvyr)
library(ggplot2)
library(readr)
library(xlsx)
library(rlang)

connstr <- set_conn_string(db = "IDI_Sandpit")

# Left join personal vars table with new weights
gss_person <- read_sql_table("select * from [DL-MAA2016-15].of_gss_desc_stats_tab_mh18p"
                             ,connection_string = connstr
                             ,string = TRUE
)


# List of variables on which stats are required
var_list <- quos(
  admin_benefit_flag
  ,dependent_children
  ,family_type
  ,family_agg_type
)
measure_list <- quos(income_monthly_net
                     ,health_nzsf12_physical
                     ,health_nzsf12_mental
                     ,multiple_disadvantage_index
                     ,hhld_transfer_income_weekly
                     ,hhld_other_income_weekly
                     ,hhld_main_benefit_weekly
                     ,hhld_tax_cred_weekly
                     ,hhld_supp_benefit_weekly
                     ,hhld_total_income_weekly)


##,econ_material_well_being_idx2
##,family_size

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

for(wave in c("GSS2016", "GSS2014", "GSS2012", "GSS2010", "GSS2008") ) {
  
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


names(univariate_list) <- c("GSS2016","GSS2014", "GSS2012", "GSS2010", "GSS2008")
names(bivariate_list) <- c("GSS2016","GSS2014", "GSS2012", "GSS2010", "GSS2008")

univar_agg <-c()
bivar_agg <-c()

univar_agg <-rbind(univariate_list$GSS2016%>%dplyr::select(var, var_name,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2016"),
       univariate_list$GSS2014%>%dplyr::select(var, var_name, wtmean,measure_name, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                  %>%mutate(wave="GSS2014"),
       univariate_list$GSS2012%>%dplyr::select(var, var_name, wtmean,measure_name, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
       %>%mutate(wave="GSS2012"),
       univariate_list$GSS2010%>%dplyr::select(var, var_name, wtmean,measure_name, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
       %>%mutate(wave="GSS2010"),
       univariate_list$GSS2008%>%dplyr::select(var, var_name, wtmean,measure_name,wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
       %>%mutate(wave="GSS2008")
       )



bivar_agg <-rbind(bivariate_list$GSS2016%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2016"),
                   bivariate_list$GSS2014%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2014"),
                   bivariate_list$GSS2012%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2012"),
                   bivariate_list$GSS2010%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2010"),
                   bivariate_list$GSS2008%>%dplyr::select(var, var_name, var2, var_name2, measure_name,wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2008")
)




write.xlsx(as.data.frame(univar_agg) %>% mutate(wttotal = random_round(as.integer(univar_agg$wttotal), 1000)
                                                ,unwttotal = random_round(univar_agg$unwttotal, 3))
           , file = "../output/desc_stats_rr_complete18p.xlsx", sheetName = "univariate_means", row.names = FALSE,
           append = TRUE)

write.xlsx(as.data.frame(bivar_agg) %>% mutate(wttotal = random_round(as.integer(bivar_agg$wttotal), 1000)
                                                ,unwttotal = random_round(bivar_agg$unwttotal, 3))
           , file = "../output/desc_stats_rr_complete18p.xlsx", sheetName = "bivariate_means", row.names = FALSE,
           append = TRUE)











############################# Making sure the difference between the values are significant ##########################################


varlist <- c("health_nzsf12_mental", 
         "health_nzsf12_physical",
         "multiple_disadvantage_index",
         "econ_material_well_being_idx2")

# Define number of replicates
repcount <- 500
confidence_levels <- c(0.025, 0.975)
confints <- data.frame(colname = character(), qlower = numeric(), qupper = numeric(), meanval = numeric(), stringsAsFactors = FALSE)



confints <-c()

for(i in c("GSS2016","GSS2014") ){
  print(i)

  gss_person_diff_ben_dep <- c()
  gss_person_diff_noben_dep<-c()
  gss_person_diff_ben_nodep<-c()
  gss_person_diff_noben_nodep<-c()
  
  gss_person_diff_ben_dep <- gss_person %>% 
    select(health_nzsf12_mental, 
           health_nzsf12_physical,
           multiple_disadvantage_index,
           econ_material_well_being_idx2,
           admin_benefit_flag ,
           dependent_children,gss_wave)%>% 
    filter(admin_benefit_flag==1, dependent_children=="1. Has Dependent Child(ren)", gss_wave ==i)
  
  gss_person_diff_noben_dep <- gss_person %>% 
    select(health_nzsf12_mental,
           health_nzsf12_physical,
           multiple_disadvantage_index,
           econ_material_well_being_idx2,
           admin_benefit_flag ,
           dependent_children, gss_wave)%>%
    filter(admin_benefit_flag==0, dependent_children=="1. Has Dependent Child(ren)", gss_wave ==i)
  
  gss_person_diff_ben_nodep <- gss_person %>% 
    select(health_nzsf12_mental, 
           health_nzsf12_physical,
           multiple_disadvantage_index,
           econ_material_well_being_idx2,
           admin_benefit_flag ,
           dependent_children, gss_wave)%>% 
    filter(admin_benefit_flag==1, dependent_children=="2. Doesnt Have Dependent Child(ren)", gss_wave ==i)
  
  gss_person_diff_noben_nodep <- gss_person %>% 
    select(health_nzsf12_mental,
           health_nzsf12_physical,
           multiple_disadvantage_index,
           econ_material_well_being_idx2,
           admin_benefit_flag ,
           dependent_children, gss_wave)%>% 
    filter(admin_benefit_flag==0, dependent_children=="2. Doesnt Have Dependent Child(ren)", gss_wave ==i)
  
  
for(this_var in varlist){
  print(this_var)
  bootstrap_sample <- simplify2array(replicate(repcount, sample_from_data(gss_person_diff_ben_dep, gss_person_diff_noben_dep, this_var), simplify = "matrix" ))
  bounds <- quantile(bootstrap_sample  , prob = confidence_levels )
  wave <- i
  info <- "Dependent_Children"
  this_row <- cbind(data.frame(colname = this_var, 
                         qlower = unname(bounds)[1],
                         qupper = unname(bounds)[2],
                         meanval = mean(na.omit(gss_person_diff_ben_dep[,this_var]) - mean(na.omit(gss_person_diff_noben_dep[,this_var]))),wave, info)
                       
  )
  confints <- rbind(confints,this_row)
}
for(this_var in varlist){
  print(this_var)
  bootstrap_sample <- simplify2array(replicate(repcount, sample_from_data(gss_person_diff_ben_nodep, gss_person_diff_noben_nodep, this_var), simplify = "matrix" ))
  bounds <- quantile(bootstrap_sample  , prob = confidence_levels )
  wave <- i
  info <- "No Dependent_Children"
  this_row <- cbind(data.frame(colname = this_var, 
                               qlower = unname(bounds)[1],
                               qupper = unname(bounds)[2],
                               meanval = mean(na.omit(gss_person_diff_ben_nodep[,this_var]) - mean(na.omit(gss_person_diff_noben_nodep[,this_var]))),wave, info)
                    
  )
  confints <- rbind(confints,this_row)
  }
}

write.xlsx(as.data.frame(confints)
           , file = "../output/desc_stats_rr_complete1.xlsx", sheetName = "diff_ben-noben_sign", row.names = FALSE,
           append = TRUE)
