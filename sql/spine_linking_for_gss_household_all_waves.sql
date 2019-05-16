/*********************************************************************************************************
DESCRIPTION: 
Creates a mapping between the GSS version of unlinked snz_uids to the IDI Spine UIDs on the basis
of address data, date & month of birth and sex. Only one-to-one links are retained, others are discarded.

This involves the following steps:

1. We first pick all people from GSS person interviews (across all waves), and only retain the ones 
	linked to IDI Spine.
2. Then we obtain the address of these interviewees as on the household interview date, and find all 
	individuals is resident at the address on the same date.
3. Once we have the list of all residents at the address, we use sex, month and year of birth listed in 
	GSS Household to match these individuals of the same household with the residents at the same address.
4. In case of one-to-many matches between GSS snz_uids and spine_sz_uids (and vice-versa), we remove such links 
	and retain only one to one matches.

INPUT: 
 @schema-the name of your schema e.g. [DL-MAA2016-15]
 
OUTPUT: 

DEPENDENCIES: 
NA

AUTHOR: 
V Benny

 CREATED: 
 02 Nov 2017

 HISTORY:
 24 Aug 2017	VB	Created v1

***********************************************************************************************************/


/* Delete tables if these exist*/
IF OBJECT_ID('IDI_Sandpit.[{schemaname}].gss_hh_snzuid_mapping','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[{schemaname}].[gss_hh_snzuid_mapping];
IF OBJECT_ID('IDI_Sandpit.[{schemaname}].of_hh_addr_linking','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[{schemaname}].of_hh_addr_linking;



/*	Steps 1 to 3 -
	First, we define the individuals from combined GSS personal questionnaire.*/
with of_gss_ind as (
	select 
		p.*
		,h.[gss_hq_interview_start_date] 
	from
	(
		select distinct snz_uid, snz_gss_hhld_uid from [gss_clean].[gss_person]
		union all 
		select distinct snz_uid, snz_gss_hhld_uid from [gss_clean].[gss_person_2012]
		union all 
		select distinct snz_uid, snz_gss_hhld_uid from [gss_clean].[gss_person_2010]		
		union all 
		select distinct snz_uid, snz_gss_hhld_uid from [gss_clean].[gss_person_2008]
	) p
	inner join [IDI_Sandpit].[{schemaname}].of_gss_hh_variables h on (p.snz_uid = h.snz_uid)		
)
select distinct 
	other_resident
	,hh.snz_uid
into IDI_Sandpit.[{schemaname}].gss_hh_snzuid_mapping
from (
	select 
		mainper.snz_gss_hhld_uid
		, a.snz_uid as other_resident
		, per.snz_birth_year_nbr
		, per.snz_birth_month_nbr
		, per.snz_sex_code
	from 
	(
		select 
			linked_gss.snz_uid as main_person
			,linked_gss.snz_gss_hhld_uid
			,linked_gss.gss_hq_interview_start_date
			,addr.snz_idi_address_register_uid
		from 
		(
			select 
				gss.snz_uid
				,gss.gss_hq_interview_start_date
				,gss.snz_gss_hhld_uid
			from of_gss_ind gss
			/* Retain only those from the GSS personal data that link to IDI Spine*/
			inner join data.personal_detail p on (gss.snz_uid = p.snz_uid and p.snz_spine_ind = 1)
			)linked_gss
		/* Get their addresses from Admin data as on the date of household interview*/
		inner join data.address_notification addr 
			on (linked_gss.snz_uid = addr.snz_uid 
				and linked_gss.gss_hq_interview_start_date between addr.ant_notification_date and addr.ant_replacement_date)
	) mainper
	/* Based on the addresses of the GSS personal questionnaire individuals, obtain everyone else resident at the address on the 
		household interview date as on the household interview date (such that those individuals are also linked to spine).*/
	inner join data.address_notification a 
		on (mainper.snz_idi_address_register_uid = a.snz_idi_address_register_uid 
			and mainper.gss_hq_interview_start_date between a.ant_notification_date and a.ant_replacement_date)
	inner join data.personal_detail per on (a.snz_uid = per.snz_uid and per.snz_spine_ind = 1)
)all_ind
/* Join those individuals resident at the addresses of the GSS PQ individuals to the GSS Household individuals, and match on date & month of birth and sex*/
inner join [IDI_Sandpit].[{schemaname}].of_gss_hh_variables hh on ( 
	all_ind.snz_gss_hhld_uid = hh.snz_gss_hhld_uid and all_ind.snz_sex_code = hh.gss_hq_sex_dev and all_ind.snz_birth_year_nbr = hh.gss_hq_birth_year_nbr 
	and all_ind.snz_birth_month_nbr = hh.gss_hq_birth_month_nbr);


/* Create an index on the table*/
create clustered index idx_hh_snzuid_mapping on IDI_Sandpit.[{schemaname}].gss_hh_snzuid_mapping(other_resident, snz_uid);

/* Step 4 - Eliminate one-to-many matches between admin and GSS Household data*/
select linking.snz_uid_spine as snz_uid, hh.snz_uid as snz_uid_gss, hh.snz_gss_hhld_uid, cast(hh.gss_hq_interview_start_date as datetime) gss_hq_interview_date
into [IDI_Sandpit].[{schemaname}].of_hh_addr_linking
from [IDI_Sandpit].[{schemaname}].of_gss_hh_variables hh
inner join (
	select  
		other_resident as snz_uid_spine
		,snz_uid as snz_uid_gss 
	from IDI_Sandpit.[{schemaname}].gss_hh_snzuid_mapping
	where other_resident not in (select other_resident from IDI_Sandpit.[{schemaname}].gss_hh_snzuid_mapping group by other_resident having count(distinct snz_uid) > 1)
		and snz_uid not in (select snz_uid from IDI_Sandpit.[{schemaname}].gss_hh_snzuid_mapping group by snz_uid having count(distinct other_resident) > 1)
	) linking on (hh.snz_uid = linking.snz_uid_gss);