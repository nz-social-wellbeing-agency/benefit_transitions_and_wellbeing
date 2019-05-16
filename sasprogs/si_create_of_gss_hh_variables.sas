/*********************************************************************************************************
DESCRIPTION: 
Combines all the GSS household information across different waves into one single 
table. Only a limited set of variables which are useful for the outcomes framework project have 
been retained in the output.

INPUT:
[&idi_version.].[gss_clean].[gss_household] = 2014 GSS household table
[&idi_version.].[gss_clean].[gss_household_2012] = 2012 GSS household table
[&idi_version.].[gss_clean].[gss_household_2010] = 2010 GSS household table
[&idi_version.].[gss_clean].[gss_household_2008] = 2008 GSS household table

OUTPUT:
sand.of_gss_hh_variables = dataset with household variables for GSS

AUTHOR: 
V Benny

DEPENDENCIES:
NA

NOTES:   
1. Individuals in the GSS households are not linked to the spine at the time of writing this code, except
	for those individuals who also answer the personal questionnaire. 
2. All GSS waves are available only from &idi_version._20171027 onwards.


HISTORY: 
22 Nov 2017 VB	Converted the SQL version into SAS.
11 Jun 2018	VB	Added new variable for number of dependent children at the household level for all waves
				Added a count variable for number of family/non-family nuclei in a GSS household.
01 Aug 2018 WJ	For each person - asnwering the questionaire - what is the family structure in terms of number of children and adults
				variable created is adult_pq_ct and child_pq_ct
10 Aug 2018 VB	Changed the adult_ind variable definition from above 15 years to >= 18 years.
19 Oct 2018 VB	Added a join to the previous IDI refresh (IDI_Clean_20180720) to estimate interview dates
				for GSS2016 as these are absent in the IDI_Clean_20181020 refresh. Check Issues below.

ISSUES:

1. In the IDI_Clean_20181020 refresh version, the GSS HQ interview dates are null for GSS2016. We have used
	the previous refresh to estimate the interview dates to take care of this issue. This code needs to be
	removed once the issue is fixed by STATSNZ.

***********************************************************************************************************/

proc sql;

	connect to odbc (dsn=&si_idi_dsnname.);

	create table work._temp_of_gss_hh_variables as
	select
		*
	from connection to odbc(		
			select 
				hh.snz_uid
				,hh.snz_gss_hhld_uid
				,gss_hq_collection_code as gss_id_collection_code
				/* 19 Oct 2018, Vinay:  Remove the coalesce function below, since this is a stopgap fix for the issue of missing interview dates
				for the IDI Refresh IDI_Clean_20181020*/
				,coalesce(p.gss_pq_HQinterview_date, p2.gss_hq_interview_start_date) as [gss_hq_interview_start_date]
				,hh.gss_hq_sex_dev
				,hh.[gss_hq_birth_month_nbr]
				,hh.[gss_hq_birth_year_nbr]
				,hh.[gss_hq_regcouncil_dev]
				,hh.[gss_hq_under_15_dev]
				,hh.gss_hq_age_dev
				,case when hh.[gss_hq_age_dev] >= 18 then 1 else 0 end as [adult_ind]
				,hhnucleus.family_nuclei_ct
				,hhnucleus.nonfamily_nuclei_ct
				,adult_pq_ct  as family_size_adult
				,child_pq_ct  as family_size_child
				,cast(hh.gss_hq_house_trust as smallint) as gss_hq_house_trust 
				,cast(hh.gss_hq_house_own as smallint) as gss_hq_house_own
				,cast(hh.gss_hq_house_pay_mort_code as smallint) as gss_hq_house_pay_mort_code
				,cast(hh.gss_hq_house_pay_rent_code as smallint) as gss_hq_house_pay_rent_code
				,hh.gss_hq_house_who_owns_code
				,hh.gss_hq_household_inc1_dev
			from [&idi_version.].[gss_clean].[gss_household] hh
			inner join (select snz_gss_hhld_uid, coalesce([Y], 0) as family_nuclei_ct, coalesce([N], 0) as nonfamily_nuclei_ct 
						from 
							(
							select snz_gss_hhld_uid, gss_hq_fam_nuc_yn_ind, count(distinct gss_hq_nucleus_nbr) as count_nuclei
							from [&idi_version.].[gss_clean].[gss_household]
							group by 
								snz_gss_hhld_uid, gss_hq_fam_nuc_yn_ind
							) as inner_query
						pivot (
							sum(count_nuclei)
							for
							gss_hq_fam_nuc_yn_ind in ([Y], [N])
							) as pivot_query
						) hhnucleus
						on (hh.snz_gss_hhld_uid = hhnucleus.snz_gss_hhld_uid)
			inner join [&idi_version.].[gss_clean].[gss_person] p on (hh.snz_gss_hhld_uid = p.snz_gss_hhld_uid)
			/* 19 Oct 2018, Vinay:  Remove the 2 joins below, since this is a stopgap fix for the issue of missing interview dates
			for the IDI Refresh IDI_Clean_20181020*/
			inner join IDI_Clean_20180720.security.concordance concord on (hh.snz_gss_uid = concord.snz_gss_uid)
			inner join IDI_Sandpit.[&si_proj_schema.].[of_gss_hh_interviewdates] p2 
				on (concord.snz_uid = p2.snz_uid and hh.gss_hq_collection_code = p2.gss_id_collection_code)

			left join(
			  		select bb.snz_gss_hhld_uid, bb.gss_hq_nucleus_nbr, sum(adult) as adult_pq_ct, sum(child) as child_pq_ct  
					from
							( 
							select	
								snz_gss_hhld_uid
								,gss_hq_nucleus_nbr
								,case when gss_hq_age_dev >= 18 then 1 else 0 end as adult
								,case when gss_hq_age_dev < 18 then 1 else 0 end as child
							from [&idi_version.].[gss_clean].[gss_household] ) bb
							group by  bb.snz_gss_hhld_uid ,bb.gss_hq_nucleus_nbr ) j   
					on (hh.snz_gss_hhld_uid = j.snz_gss_hhld_uid and hh.gss_hq_nucleus_nbr = j.gss_hq_nucleus_nbr)
			where gss_hq_collection_code = 'GSS2016'
			union all
			select 
				hh.snz_uid
				,hh.snz_gss_hhld_uid
				,gss_hq_collection_code as gss_id_collection_code
				,p.gss_pq_HQinterview_date as [gss_hq_interview_start_date]
				,hh.gss_hq_sex_dev
				,hh.[gss_hq_birth_month_nbr]
				,hh.[gss_hq_birth_year_nbr]
				,[gss_hq_regcouncil_dev]
				,[gss_hq_under_15_dev]
				,gss_hq_age_dev
				,case when [gss_hq_age_dev] >= 18 then 1 else 0 end as [adult_ind]
				,hhnucleus.family_nuclei_ct
				,hhnucleus.nonfamily_nuclei_ct
				,adult_pq_ct  as family_size_adult
				,child_pq_ct  as family_size_child
				,cast(hh.gss_hq_house_trust as smallint) as gss_hq_house_trust 
				,cast(hh.gss_hq_house_own as smallint) as gss_hq_house_own
				,cast(hh.gss_hq_house_pay_mort_code as smallint) as gss_hq_house_pay_mort_code
				,cast(hh.gss_hq_house_pay_rent_code as smallint) as gss_hq_house_pay_rent_code
				,hh.gss_hq_house_who_owns_code
				,hh.gss_hq_household_inc1_dev
			from [&idi_version.].[gss_clean].[gss_household] hh
			inner join (select snz_gss_hhld_uid, coalesce([Y], 0) as family_nuclei_ct, coalesce([N], 0) as nonfamily_nuclei_ct 
						from 
							(
							select snz_gss_hhld_uid, gss_hq_fam_nuc_yn_ind, count(distinct gss_hq_nucleus_nbr) as count_nuclei
							from [&idi_version.].[gss_clean].[gss_household]
							group by 
								snz_gss_hhld_uid, gss_hq_fam_nuc_yn_ind
							) as inner_query
						pivot (
							sum(count_nuclei)
							for
							gss_hq_fam_nuc_yn_ind in ([Y], [N])
							) as pivot_query
						) hhnucleus
						on (hh.snz_gss_hhld_uid = hhnucleus.snz_gss_hhld_uid)
			inner join [&idi_version.].[gss_clean].[gss_person] p on (hh.snz_gss_hhld_uid = p.snz_gss_hhld_uid)
			left join(
			  		select bb.snz_gss_hhld_uid, bb.gss_hq_nucleus_nbr, sum(adult) as adult_pq_ct, sum(child) as child_pq_ct  
					from
							( 
							select	
								snz_gss_hhld_uid
								,gss_hq_nucleus_nbr
								,case when gss_hq_age_dev >= 18 then 1 else 0 end as adult
								,case when gss_hq_age_dev < 18 then 1 else 0 end as child
							from [&idi_version.].[gss_clean].[gss_household] ) bb
							group by  bb.snz_gss_hhld_uid ,bb.gss_hq_nucleus_nbr ) j   
					on (hh.snz_gss_hhld_uid = j.snz_gss_hhld_uid and hh.gss_hq_nucleus_nbr = j.gss_hq_nucleus_nbr)
			where gss_hq_collection_code = 'GSS2014'
			union all
			select 
				hh.snz_uid
				,hh.snz_gss_hhld_uid
				,hh.gss_hq_collection_code as gss_id_collection_code
				,cast([gss_hq_interview_start_date] as date) as [gss_hq_interview_start_date]
				,case [gss_hq_CORDV10] when '11' then 1 when '12' then 2 else NULL end as [gss_hq_CORDV10] 
				,[gss_hq_birth_month_nbr]
				,[gss_hq_birth_year_nbr]
				,null as [gss_hq_regcouncil_dev]
				,[gss_hq_Under15_DV]
				,[gss_hq_CORDV9] as gss_hq_age_dev
				,case when hh.[gss_hq_CORDV9] >= 18 then 1 else 0 end as [adult_ind]
				,NULL as family_nuclei_ct
				,NULL as nonfamily_nuclei_ct
				,NULL  as family_size_adult
				,NULL  as family_size_child
				,house.gss_hq_CORHQ05 as gss_hq_house_trust 
				,house.gss_hq_CORHQ07  as gss_hq_house_own
				,house.gss_hq_CORHQ08 as gss_hq_house_pay_mort_code
				,house.gss_hq_CORHQ10 as  gss_hq_house_pay_rent_code
				,house.gss_hq_CORHQ09 as gss_hq_house_who_owns_code
				,hh.gss_hq_CORDV13 as gss_hq_household_inc1_dev
			from [&idi_version.].[gss_clean].[gss_household_2012] hh
			left join (select snz_gss_hhld_uid
						,max(gss_hq_CORHQ05) as gss_hq_CORHQ05
						,max(gss_hq_CORHQ07) as gss_hq_CORHQ07
						,max(gss_hq_CORHQ08) as gss_hq_CORHQ08
						,max(gss_hq_CORHQ10) as gss_hq_CORHQ10
						,max(gss_hq_CORHQ09) as gss_hq_CORHQ09
					from [&idi_version.].[gss_clean].[gss_household_2012]
					group by snz_gss_hhld_uid) house on ( hh.snz_gss_hhld_uid = house.snz_gss_hhld_uid)
			/* Funfact: GSS refresh dated 20181020 has duplicates in the GSS household table for 2008. It isn't clear why this occurs
					or how to get unique records, so for now, as an interim fix, we have used the gss_hq_PersonCoreNonRespInd
					column as a determiner of unique records. This may need to change with future refreshes. The following join
					takes care of the de-duplication. You can remove this join once the duplicate issue is fixed on STATSNZ end.
					*/
			inner join (select snz_uid, gss_hq_collection_code, coalesce(max(gss_hq_PersonCoreNonRespInd), '') as gss_hq_PersonCoreNonRespInd 
						from [&idi_version.].gss_clean.gss_household_2012 
						group by snz_uid, gss_hq_collection_code) dupremove
				on (hh.snz_uid = dupremove.snz_uid 
				and coalesce(hh.gss_hq_PersonCoreNonRespInd, '') = dupremove.gss_hq_PersonCoreNonRespInd )

			union all

			select 
				hh.snz_uid
				,hh.snz_gss_hhld_uid
				,gss_hq_collection_code as gss_id_collection_code
				,cast([gss_hq_interview_start_date] as date) as [gss_hq_interview_start_date]
				,case [gss_hq_CORDV10] when '11' then 1 when '12' then 2 else NULL end as [gss_hq_CORDV10]
				,[gss_hq_birth_month_nbr]
				,[gss_hq_birth_year_nbr]
				,null as [gss_hq_regcouncil_dev]
				,[gss_hq_Under15_DV]
				,[gss_hq_CORDV9] as gss_hq_age_dev
				,case when hh.[gss_hq_CORDV9] >= 18 then 1 else 0 end as [adult_ind]
				,NULL as family_nuclei_ct
				,NULL as nonfamily_nuclei_ct
				,NULL  as family_size_adult
				,NULL  as family_size_child
				,house.gss_hq_CORHQ05 as gss_hq_house_trust 
				,house.gss_hq_CORHQ07 as gss_hq_house_own
				,house.gss_hq_CORHQ08 as gss_hq_house_pay_mort_code
				,house.gss_hq_CORHQ10 as  gss_hq_house_pay_rent_code
				,house.gss_hq_CORHQ09 as gss_hq_house_who_owns_code
				,hh.gss_hq_CORDV13 as gss_hq_household_inc1_dev
			from [&idi_version.].[gss_clean].[gss_household_2010] hh
			left join (select snz_gss_hhld_uid
						,max(gss_hq_CORHQ05) as gss_hq_CORHQ05
						,max(gss_hq_CORHQ07) as gss_hq_CORHQ07
						,max(gss_hq_CORHQ08) as gss_hq_CORHQ08
						,max(gss_hq_CORHQ10) as gss_hq_CORHQ10
						,max(gss_hq_CORHQ09) as gss_hq_CORHQ09
					from [&idi_version.].[gss_clean].[gss_household_2010]
					group by snz_gss_hhld_uid) house on ( hh.snz_gss_hhld_uid = house.snz_gss_hhld_uid)

			union all

			select 
				hh.snz_uid
				,hh.snz_gss_hhld_uid
				,hh.gss_hq_collection_code as gss_id_collection_code
				,cast([gss_hq_interview_start_date] as date) as [gss_hq_interview_start_date]
				,case [gss_hq_CORDV10] when '11' then 1 when '12' then 2 else NULL end as [gss_hq_CORDV10]
				,[gss_hq_birth_month_nbr]
				,[gss_hq_birth_year_nbr]
				,null as [gss_hq_regcouncil_dev]
				,[gss_hq_Under15_DV]
				,[gss_hq_CORDV9] as gss_hq_age_dev
				,case when hh.[gss_hq_CORDV9] >= 18 then 1 else 0 end as [adult_ind]
				,NULL as family_nuclei_ct
				,NULL as nonfamily_nuclei_ct
				,NULL  as family_size_adult
				,NULL  as family_size_child
				,house.gss_hq_CORHQ05 as gss_hq_house_trust 
				,house.gss_hq_CORHQ07 as gss_hq_house_own
				,house.gss_hq_CORHQ08 as gss_hq_house_pay_mort_code
				,house.gss_hq_CORHQ10 as  gss_hq_house_pay_rent_code
				,house.gss_hq_CORHQ09 as gss_hq_house_who_owns_code
				,hh.gss_hq_CORDV13 as gss_hq_household_inc1_dev
			from [&idi_version.].[gss_clean].[gss_household_2008] hh
			left join (select snz_gss_hhld_uid
						,max(gss_hq_CORHQ05) as gss_hq_CORHQ05
						,max(gss_hq_CORHQ07) as gss_hq_CORHQ07
						,max(gss_hq_CORHQ08) as gss_hq_CORHQ08
						,max(gss_hq_CORHQ10) as gss_hq_CORHQ10
						,max(gss_hq_CORHQ09) as gss_hq_CORHQ09
					from [&idi_version.].[gss_clean].[gss_household_2008]
					group by snz_gss_hhld_uid) house on ( hh.snz_gss_hhld_uid = house.snz_gss_hhld_uid)
			/* Funfact: GSS refresh dated 20181020 has duplicates in the GSS household table for 2008. It isn't clear why this occurs
					or how to get unique records, so for now, as an interim fix, we have used the gss_hq_PersonCoreNonRespInd
					column as a determiner of unique records. This may need to change with future refreshes. The following join
					takes care of the de-duplication. You can remove this join once the duplicate issue is fixed on STATSNZ end.
					*/
			inner join (select snz_uid, gss_hq_collection_code, coalesce(max(gss_hq_PersonCoreNonRespInd), '') as gss_hq_PersonCoreNonRespInd 
						from [&idi_version.].gss_clean.gss_household_2008 
						group by snz_uid, gss_hq_collection_code) dupremove
				on (hh.snz_uid = dupremove.snz_uid 
				and coalesce(hh.gss_hq_PersonCoreNonRespInd, '') = dupremove.gss_hq_PersonCoreNonRespInd )

	
	);

	disconnect from odbc;

quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_gss_hh_variables,
	si_write_table_out=&si_sandpit_libname..of_gss_hh_variables_mh
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);


/* Add on some derived variables on top of the of_gss_hh_variables table. */
proc sql;

	connect to odbc (dsn=&si_idi_dsnname.);

	create table _temp_of_gss_hh_variables
	as select * from connection to odbc (

		select
			snz_uid
			,snz_gss_hhld_uid
			,gss_id_collection_code
			,gss_hq_interview_start_date
			,gss_hq_sex_dev
			,gss_hq_birth_month_nbr
			,gss_hq_birth_year_nbr
			,gss_hq_regcouncil_dev
			,gss_hq_under_15_dev
			,gss_hq_age_dev
			,adult_ind
			,family_nuclei_ct
			,nonfamily_nuclei_ct
			,family_size_adult
			,family_size_child
			,gss_hq_house_trust
			,gss_hq_house_own
			,gss_hq_house_pay_mort_code
			,gss_hq_house_pay_rent_code
			,gss_hq_house_who_owns_code
			,gss_hq_household_inc1_dev

			/* Derived Variables*/
			,case when gss_hq_household_inc1_dev = '01' then '-Loss'
				when gss_hq_household_inc1_dev = '02' then '0'
				when gss_hq_household_inc1_dev = '03' then '1-5000'
				when gss_hq_household_inc1_dev = '04' then '5001-10000'
				when gss_hq_household_inc1_dev = '05' then '10001-15000'
				when gss_hq_household_inc1_dev = '06' then '15001-20000'
				when gss_hq_household_inc1_dev = '07' then '20001-25000'
				when gss_hq_household_inc1_dev = '08' then '25001-30000'
				when gss_hq_household_inc1_dev = '09' then '30001-35000'
				when gss_hq_household_inc1_dev = '10' then '35001-40000'
				when gss_hq_household_inc1_dev in ('11', '12', '13') then '40001-70000'
				when gss_hq_household_inc1_dev = '14' then '70001-100000'
				when gss_hq_household_inc1_dev = '15' then '100001-150000'
				when gss_hq_household_inc1_dev = '16' then '150001-Inf'
			end as hh_gss_income
			,case when gss_hq_household_inc1_dev = '01' then 0
				when gss_hq_household_inc1_dev = '02' then 0
				when gss_hq_household_inc1_dev = '03' then 2500
				when gss_hq_household_inc1_dev = '04' then 7500
				when gss_hq_household_inc1_dev = '05' then 12500
				when gss_hq_household_inc1_dev = '06' then 17500
				when gss_hq_household_inc1_dev = '07' then 22500
				when gss_hq_household_inc1_dev = '08' then 27500
				when gss_hq_household_inc1_dev = '09' then 32500
				when gss_hq_household_inc1_dev = '10' then 37500
				when gss_hq_household_inc1_dev in ('11', '12', '13') then 55000
				when gss_hq_household_inc1_dev = '14' then 85000
				when gss_hq_household_inc1_dev = '15' then 125000
				when gss_hq_household_inc1_dev = '16' then 175000
			end as hh_gss_income_median

			,case when gss_hq_household_inc1_dev = '01' then 0
				when gss_hq_household_inc1_dev = '02' then 0
				when gss_hq_household_inc1_dev = '03' then 1
				when gss_hq_household_inc1_dev = '04' then 5001
				when gss_hq_household_inc1_dev = '05' then 10001
				when gss_hq_household_inc1_dev = '06' then 15001
				when gss_hq_household_inc1_dev = '07' then 20001
				when gss_hq_household_inc1_dev = '08' then 25001
				when gss_hq_household_inc1_dev = '09' then 30001
				when gss_hq_household_inc1_dev = '10' then 35001
				when gss_hq_household_inc1_dev in ('11', '12', '13') then 40001
				when gss_hq_household_inc1_dev = '14' then 70001
				when gss_hq_household_inc1_dev = '15' then 100001
				when gss_hq_household_inc1_dev = '16' then 150001
			end as hh_gss_income_lower

			,case when gss_hq_household_inc1_dev = '01' then 0
				when gss_hq_household_inc1_dev = '02' then 0
				when gss_hq_household_inc1_dev = '03' then 5000
				when gss_hq_household_inc1_dev = '04' then 10000
				when gss_hq_household_inc1_dev = '05' then 15000
				when gss_hq_household_inc1_dev = '06' then 20000
				when gss_hq_household_inc1_dev = '07' then 25000
				when gss_hq_household_inc1_dev = '08' then 30000
				when gss_hq_household_inc1_dev = '09' then 35000
				when gss_hq_household_inc1_dev = '10' then 40000
				when gss_hq_household_inc1_dev in ('11', '12', '13') then 70000
				when gss_hq_household_inc1_dev = '14' then 100000
				when gss_hq_household_inc1_dev = '15' then 150000
				when gss_hq_household_inc1_dev = '16' then 200000
			end as hh_gss_income_upper

			,case when gss_hq_house_trust='99' then 'UNKNOWN'
				when gss_hq_house_trust in ('88', '02') then 
					case when gss_hq_house_own = '01' then 'OWN'
						when gss_hq_house_own = '99' then 'UNKNOWN'
						when gss_hq_house_own in ('02','88') then 
							case when gss_hq_house_who_owns_code = '11' 
									and gss_hq_house_pay_rent_code = '01' then 'PRIVATE, TRUST OR BUSINESS-PAY RENT'
								when gss_hq_house_who_owns_code = '11' 
									and gss_hq_house_pay_rent_code = '02' then 'PRIVATE, TRUST OR BUSINESS-NO RENT'
								when gss_hq_house_who_owns_code = '11' 
									and gss_hq_house_pay_rent_code in ('88', '99') then 'PRIVATE, TRUST OR BUSINESS-UNKNOWN'
								when gss_hq_house_who_owns_code in ('12', '14') then 'OTHER SOCIAL HOUSING'
								when gss_hq_house_who_owns_code ='13' then 'HOUSING NZ'
								when gss_hq_house_who_owns_code in ('88', '99') 
									and gss_hq_house_pay_rent_code = '01' then 'UNKNOWN-PAY RENT'
								when gss_hq_house_who_owns_code in ('88', '99') 
									and gss_hq_house_pay_rent_code = '02' then 'UNKNOWN-NO RENT'
								when gss_hq_house_who_owns_code in ('88', '99') 
									and gss_hq_house_pay_rent_code in ('88', '99') then 'UNKNOWN'
							end
					end
				when gss_hq_house_trust = '01' then 'TRUST'
			end as housing_status
		from 
		[IDI_Sandpit].[&si_proj_schema.].of_gss_hh_variables_mh
	);

	disconnect from odbc;

quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_of_gss_hh_variables,
	si_write_table_out=&si_sandpit_libname..of_gss_hh_variables_mh
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);



/* Remove temporary datasets */
proc datasets lib=work;
	delete _temp_:;
run;
