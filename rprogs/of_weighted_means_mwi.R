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
#16 October 2018 WJ Added in variables of interest regarding family type and tax credit measures
# ================================================================================================ #

# rm(list = ls())

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
  ,family_agg_type
)
measure_list <- quos(econ_material_well_being_idx2,family_size)


##,econ_material_well_being_idx2

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

  gssvars <- var_list
  measurevars <- measure_list
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



bivar_agg <-rbind(bivariate_list$GSS2016%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2016"),
                   bivariate_list$GSS2014%>%dplyr::select(var, var_name, var2, var_name2,measure_name, wtmean, wtmean_se, wtmean_low, wtmean_upp, unwttotal, wttotal)
                   %>%mutate(wave="GSS2014")
)




write.xlsx(as.data.frame(univar_agg) %>% mutate(wttotal = rrn(as.integer(univar_agg$wttotal), 1000)
                                                ,unwttotal = rrn(univar_agg$unwttotal, 3))
           , file = "../output/desc_stats_rr_mwi_fam18p.xlsx", sheetName = "univariate_means", row.names = FALSE,
           append = TRUE)

write.xlsx(as.data.frame(bivar_agg) %>% mutate(wttotal = rrn(as.integer(bivar_agg$wttotal), 1000)
                                                ,unwttotal = rrn(bivar_agg$unwttotal, 3))
           , file = "../output/desc_stats_rr_mwi_fam18p.xlsx", sheetName = "bivariate_means", row.names = FALSE,
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


