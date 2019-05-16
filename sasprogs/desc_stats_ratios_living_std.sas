/*********************************************************************************************************
DESCRIPTION: 
GSS 2014 & 2016 Descriptive Stats
Risk Ratios and Relative Risk Ratios for Economic and social outcomes
bivariate: var*benefit_flag, Risk = % of beneficiaries within var=1
trivariate: dep_child_ind*benefit_flag*var, Risk = % of var=1 for the 4 groups(dep_child*ben_flag)

INPUT:
[IDI_Sandpit].[DL-MAA2016-15].[of_gss_desc_stats_tab_mh]


OUTPUT:


DEPENDENCIES:

NOTES:

HISTORY: 
11 Jul 2018 BV V1
16 Oct 2018 BV GSS2016 integration, reverse bivariate risk ratio

*********************************************************************************************************/


/*Create binary indicators for the economic and social outcomes GSS2014*/
proc sql;

connect to odbc (dsn=&si_idi_dsnname.);

	create table work._temp_gss20146_stats as
	select *
	from connection to odbc(

	select *,
		case when admin_benefit_flag = 1 then 0 else 1 end as admin_benefit_flag_rev, /* reversing the benefit flag */
		case when econ_cost_down_vege = 13 then 1 else 0 end as econ_vege_bin,
		case when econ_cost_down_dr = 13 then 1 else 0 end as econ_dr_bin,
		case when econ_cost_down_shop = 13 then 1 else 0 end as econ_shop_bin,
		case when econ_cost_down_hobby = 13 then 1 else 0 end as econ_hobby_bin,
		case when econ_cost_down_cold = 13 then 1 else 0 end as econ_cold_bin,
		case when econ_cost_down_appliance = 13 then 1 else 0 end as econ_appliance_bin,
		case when econ_buy_shoes_limit = 14 then 1 else 0 end as econ_shoes_bin,
		case when econ_item_300_limit = 15 then 1 else 0 end as econ_item300_bin,
		case when econ_not_pay_bills_time = 13 then 1 else 0 end as econ_bills_bin,
		case when econ_enough_inc_code = 11 then 1 else 0 end as econ_enoughinc_bin,
		case when econ_material_well_being_idx = '1. Less than 6' then 1 else 0 end as econ_welb_less6_bin,
		case when house_crowding < 3 then 1 else 0 end as house_crowding_bin,
		case when culture_discrimination = '1. Experienced Discrimination' then 1 else 0 end as culture_discrimination_bin,
		case when safety_neighbourhood_night > 12 then 1 else 0 end as safety_neighbourhood_night_bin,
		case when health_depressed < 14 then 1 else 0 end as health_depressed_bin,
		case when health_pain between 14 and 15 then 1 else 0 end as health_pain_bin,
		case when civic_generalised_trust < 2 then 1 else 0 end as civic_generalised_trust_bin,
		case when culture_identity > 12 then 1 else 0 end as culture_identity_bin,
		case when social_time_lonely between 11 and 12 then 1 else 0 end as social_time_lonely_bin, /* flipped scale for 2014 */
		case when subj_life_satisfaction between 1 and 2 then 1 else 0 end as subj_life_satisfaction_low, /*  1 and 2 are 0 to 4 for GSS2014 */
		case when subj_sense_of_purpose < 6 then 1 else 0 end as subj_sense_of_purpose_low

	from [IDI_Sandpit].[DL-MAA2016-15].[of_gss_desc_stats_tab_mh] where gss_wave in ('GSS2014','GSS2016');


	);

	disconnect from odbc;

quit;

/*Multiple hardship indicator : at least 5 of the 13 hardships above*/

proc sql;
	create table _temp_gss20146_stats2 as
	select *,
	case when econ_vege_bin +econ_dr_bin +econ_shop_bin +econ_hobby_bin +econ_cold_bin +econ_appliance_bin +econ_shoes_bin
                 +econ_item300_bin +econ_bills_bin +econ_enoughinc_bin +house_crowding_bin +house_mold +house_cold >= 5 
		then 1 else 0 end as multiple_hardship
	from _temp_gss20146_stats;
quit;


proc sort data=_temp_gss20146_stats2;
	by dependent_children;
	run;

%let varlist = %str(econ_vege_bin econ_dr_bin econ_shop_bin econ_hobby_bin econ_cold_bin econ_appliance_bin econ_shoes_bin
                 econ_item300_bin econ_bills_bin econ_enoughinc_bin econ_welb_less6_bin
                 house_crowding_bin house_mold house_cold multiple_hardship culture_discrimination_bin  safety_crime_victim safety_neighbourhood_night_bin
                 health_depressed_bin health_pain_bin civic_generalised_trust_bin culture_identity_bin social_time_lonely_bin
                 subj_life_satisfaction_low subj_sense_of_purpose_low);







%macro risk_ratios(ds=);

/*Calculates the risks and relative risks by dependent children and admin benefit flags*/
proc surveyfreq data=&ds.;
	by dependent_children;
	repweights link_FinalWgt_1-link_FinalWgt_99;
	tables admin_benefit_flag_rev*(&varlist.) / risk risk1 risk2 cl or clwt alpha= 0.01 lrchisq;
	ods output CrossTabs=output_cross OddsRatio=output_or Risk2=output_risk;
run;


/*renaming the crosstab output var value*/
proc sql;
	create table output_cross2 as
	select dependent_children, Table, admin_benefit_flag_rev, WgtFreq, 
	coalesce(econ_vege_bin, econ_dr_bin, econ_shop_bin, econ_hobby_bin, econ_cold_bin, econ_appliance_bin, econ_shoes_bin,
                 econ_item300_bin, econ_bills_bin, econ_enoughinc_bin, econ_welb_less6_bin,
                 house_crowding_bin, house_mold, house_cold, multiple_hardship,  culture_discrimination_bin,  safety_crime_victim, safety_neighbourhood_night_bin,
                 health_depressed_bin, health_pain_bin, civic_generalised_trust_bin, culture_identity_bin, social_time_lonely_bin,
                 subj_life_satisfaction_low, subj_sense_of_purpose_low) as var_value
	from output_cross;
quit;

proc sql;
	create table output_risk2 as
	select *, case when Row="Row 1" then 0 else 1 end as admin_benefit_flag_rev
	from output_risk where Row in ("Row 1","Row 2");
quit;


/*Joining the outputs and keep the weighted counts for confidentiality rules*/
proc sql;
	create table risks_output as
	select a.dependent_children, a.Table, a.admin_benefit_flag_rev, a.var_value, a.WgtFreq, round(a.WgtFreq,1000) as WgtFreq_Rnd
	,b.*
	,c.estimate as RelRisk, c.LowerCL as RelRiskLowCL, c.UpperCL as RelRiskUpCL
	from output_cross2 a
	left join output_risk2 b on a.dependent_children=b.dependent_children and a.Table=b.Table and a.admin_benefit_flag_rev=b.admin_benefit_flag_rev
	left join output_or c on a.dependent_children=c.dependent_children and a.Table=c.Table
	where a.var_value=1 and a.admin_benefit_flag_rev ne .
	and c.Statistic="Column 2 Relative Risk"
	;
quit;



/************************************************************************/
/* Bivariate benefit*var only for share of group that are beneficiaries */

/*Calculate the risks by admin benefit flags*/
proc surveyfreq data=&ds.;
	repweights link_FinalWgt_1-link_FinalWgt_99;
	tables (&varlist.)*admin_benefit_flag_rev / risk risk1 risk2 cl or clwt;
	ods output CrossTabs=output_cross_bi Risk1=output_risk_bi; /* Risk2=output_risk_bi; */
run;


/*renaming the crosstab output var value*/
proc sql;
	create table output_cross_bi2 as
	select Table, admin_benefit_flag_rev, WgtFreq, 
	coalesce(econ_vege_bin, econ_dr_bin, econ_shop_bin, econ_hobby_bin, econ_cold_bin, econ_appliance_bin, econ_shoes_bin,
                 econ_item300_bin, econ_bills_bin, econ_enoughinc_bin, econ_welb_less6_bin,
                 house_crowding_bin, house_mold, house_cold, multiple_hardship,  culture_discrimination_bin,  safety_crime_victim, safety_neighbourhood_night_bin,
                 health_depressed_bin, health_pain_bin, civic_generalised_trust_bin, culture_identity_bin, social_time_lonely_bin,
                 subj_life_satisfaction_low, subj_sense_of_purpose_low) as var_value
	from output_cross_bi;
quit;

proc sql;
	create table output_risk_bi2 as
	select *, case when Row="Row 2" then 0 else 1 end as admin_benefit_flag_rev
	from output_risk_bi where Row in ("Row 2");
quit;


/*Joining the outputs and keep the weighted counts for confidentiality rules*/
proc sql;
	create table risks_output_bi as
	select a.Table, a.admin_benefit_flag_rev, a.var_value, a.WgtFreq, round(a.WgtFreq,1000) as WgtFreq_Rnd
	,b.*
	from output_cross_bi2 a
	left join output_risk_bi2 b on a.Table=b.Table and a.admin_benefit_flag_rev=b.admin_benefit_flag_rev
	where a.var_value=1 and a.admin_benefit_flag_rev = 0
	;
quit;

%mend;




/*2014 only */
%risk_ratios(ds=_temp_gss20146_stats2(where=(gss_wave='GSS2014')));
proc export data=risks_output_bi outfile="&si_source_path.\output\living_std_risk_ratios.xlsx" dbms=xlsx replace; 	sheet="2014_bivar"; run;
proc export data=risks_output outfile="&si_source_path.\output\living_std_risk_ratios.xlsx" dbms=xlsx replace; 	sheet="2014_trivar"; run;

/*2016 only */
%risk_ratios(ds=_temp_gss20146_stats2(where=(gss_wave='GSS2016')));
proc export data=risks_output_bi outfile="&si_source_path.\output\living_std_risk_ratios.xlsx" dbms=xlsx replace; 	sheet="2016_bivar"; run;
proc export data=risks_output outfile="&si_source_path.\output\living_std_risk_ratios.xlsx" dbms=xlsx replace; 	sheet="2016_trivar"; run;

