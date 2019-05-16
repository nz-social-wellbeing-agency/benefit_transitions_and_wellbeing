/*********************************************************************************************************
DESCRIPTION: 
Apply specific priority rules for the MHaET project.
Prioritize Benefit spells over employment, no employment spells <= 14 days, no education spells.
Then does a spells compaction in case of fragmenting by the prio rules.
Output only a time window around the interview (fixed at 210 days after tests for 12 and 3 months)

INPUT:
[IDI_Sandpit].[&si_proj_schema.].[of_comb_spells]

OUTPUT:
[IDI_Sandpit].[&si_proj_schema.].[of_comb_spells_rules_xxx]

AUTHOR: 
Vinay Benny & Ben Vandenbroucke

DEPENDENCIES:



NOTES:


HISTORY: 
01 April 2018 VB/BV V1

*********************************************************************************************************/

%let interval_days = 180;


/*First, replace all spell numbering from the spells dataset.*/
proc sql;
		connect to odbc(dsn=&si_idi_dsnname.);
		create table _temp_comb_spells_rule1 as
		select * from connection to odbc(
		select snz_uid,
			start_date,
			end_date,
			replace(
				replace(
					replace(
						replace(
							replace(
								replace(
									replace(
										replace(
											replace(
												replace(final_event_type,'0','')
												,'1','') 
											,'2','') 
										,'3','') 
									,'4','') 
								,'5','') 
							,'6','') 
						,'7','') 
					,'8','') 
				,'9','') 
		as final_event_type
		from [IDI_Sandpit].[&si_proj_schema.].[of_comb_spells]
		);
		disconnect from odbc;
quit;

/*Rule 2: Apply Benefit over employment priority and remove employment spells <= 14 days*/
proc sql;
		connect to odbc(dsn=&si_idi_dsnname.);
		create table _temp_comb_spells_rule2 as
			select * from connection to odbc(
				select snz_uid,
					start_date,
					end_date, 
					case when final_event_type like '%BEN%' then 'BEN' 
					when final_event_type like '%EMP%' then 'EMP' 
					else 'EDU' end as state
				from [IDI_Sandpit].[&si_proj_schema.].[of_comb_spells]
				)
				where state eq "BEN" 
				or (state eq "EMP" and end_date - start_date >= 14) ; 
				/* >= 14 days because both dates should be inclusive while calculating the interval*/
		disconnect from odbc;
quit;

%si_write_to_db(si_write_table_in=work._temp_comb_spells_rule2
	,si_write_table_out=&si_sandpit_libname..of_comb_spells_rule2
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/* Since after application of priority rules, some of the BEN_EMP combination spells become just benefit spells, 
	we need to apply compaction again to merge together successive benefit spells.*/
%si_compact_spells(si_sial_table=[IDI_Sandpit].[&si_proj_schema.].[of_comb_spells_rule2] , si_agg_cols =%str(snz_uid state),
	si_out_table= of_comb_spells_rule2);

/* Rule 3: Identify all transitions that occured in the period of interest such that the benefit spells is 
	at least 30 days long followed by and employment spell that is atleast 30 days long, and the benefit and employment
	spells are not separated by more than 14 days.*/
proc sql;
	connect to odbc(dsn=&si_idi_dsnname.);
	create table _temp_comb_spells_rule3 as
		select * from connection to odbc(
			
			with transitions as ( 
			select
				snz_uid
				,state
				,start_date
				,end_date
				,lead(state) over (partition by snz_uid order by start_date) as state2
				,lead(start_date) over (partition by snz_uid order by start_date) as state2_start_date
				,lead(end_date) over (partition by snz_uid order by start_date) as state2_end_date
			from IDI_Sandpit.[&si_proj_schema.].of_comb_spells_rule2 
			)
			select *
				,datediff(dd, start_date, end_date) + 1 as state1_duration
				,datediff(dd, end_date, state2_start_date) - 1 as state1_state2_gap_duration
				,datediff(dd, state2_start_date, state2_end_date) + 1 as state2_duration
			from (
				select
					*
					/* Ensure benefits and employments are at least 30 days in duration, and the separation between these
					is no more than 14 days.*/
					,case when state = 'BEN' 
								and datediff(dd, start_date, end_date) + 1 >= 180 
								and state2 = 'EMP'
								and datediff(dd, state2_start_date, state2_end_date) + 1 >= 180 
								and datediff(dd, end_date, state2_start_date) - 1 <= 14
							then 1
						when state = 'EMP' 
							and datediff(dd, start_date, end_date) + 1 >= 180 
							and state2 = 'BEN'
							and datediff(dd, state2_start_date, state2_end_date) + 1 >= 180 
							and datediff(dd, end_date, state2_start_date) - 1 <= 14
						then 2
						else 0 
					end as transitions_ind
				from transitions
				)x
			where transitions_ind <> 0
		);
	disconnect from odbc;
quit;

%si_write_to_db(si_write_table_in=work._temp_comb_spells_rule3,
	si_write_table_out=&si_sandpit_libname..of_comb_spells_rule3
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/* 	Rule 4: Get all transitions such that the GSS interview happens 180 days on either side of the transition date */
proc sql;
	connect to odbc(dsn=&si_idi_dsnname.);
	create table _temp_comb_spells_rule4 as
		select * from connection to odbc(
			select 
				x.*
				,datediff(dd, x.end_date, gss.gss_pq_interview_date) as days_to_gss_intvw
				,gss.gss_pq_interview_date
				,abs(checksum(newid()) % 10000)/10000.0 as _random_ /* Random number to enable uniform sampling in case of multiple spells per individual*/
			from IDI_Sandpit.[&si_proj_schema.].of_comb_spells_rule3 x
			inner join IDI_Sandpit.[&si_proj_schema.].&si_pop_table_out. gss 
				on (x.snz_uid = gss.snz_uid 
					and gss.gss_pq_interview_date between dateadd(dd, -&interval_days., x.end_date) and dateadd(dd, &interval_days., x.end_date))
		);
	disconnect from odbc;
quit;

%si_write_to_db(si_write_table_in=work._temp_comb_spells_rule4,
	si_write_table_out=&si_sandpit_libname..of_comb_spells_rule4
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);

/* Rule 5 & 6: Create flags for population where all individuals where the interview date fall within "x" days of the 
	transition point (defined as end of benefit spell). In case of multiple transitions, we randomly pick one of the spells 
	for the individual. Note: there is no repeatability in which spell gets chosen.	*/
proc sql;
	connect to odbc(dsn=&si_idi_dsnname.);

	create table _temp_comb_spells_rule5 as
		select * from connection to odbc(
			select 
				a.snz_uid
				,a.state as state
				,a.start_date as state1_start_date
				,a.end_date as state1_to_state2_trans_date
				,a.state2 as state2
				,a.state2_start_date as state2_start_date
				,a.state2_end_date as state2_end_date
				,a.state1_duration
				,a.state2_duration
				,a.days_to_gss_intvw
				,a.gss_pq_interview_date
				,a.transitions_ind
				,case when (gss_pq_interview_date between start_date and state2_end_date)
					and (gss_pq_interview_date not between dateadd(dd, 1,end_date) and dateadd(dd, -1,state2_start_date)) 
					then 1 else 0 end as intvw_xsect
				,case when a.state1_duration > 180 and a.state2_duration > 180 and abs(a.days_to_gss_intvw) <= 180
					then 1 else 0 end as intvw_180_xsect
				,case when a.state1_duration > 150 and a.state2_duration > 150 and abs(a.days_to_gss_intvw) <= 150
					then 1 else 0 end as intvw_150_xsect
				,case when a.state1_duration > 120 and a.state2_duration > 120 and abs(a.days_to_gss_intvw) <= 120
					then 1 else 0 end as intvw_120_xsect
				,case when a.state1_duration > 90 and a.state2_duration > 90 and abs(a.days_to_gss_intvw) <= 90
					then 1 else 0 end as intvw_90_xsect
				,case when a.state1_duration > 60 and a.state2_duration > 60 and abs(a.days_to_gss_intvw) <= 60
					then 1 else 0 end as intvw_60_xsect					
			from IDI_Sandpit.[&si_proj_schema.].of_comb_spells_rule4 a
			left join (select snz_uid, transitions_ind,max(_random_) as _random_ 
						from IDI_Sandpit.[&si_proj_schema.].of_comb_spells_rule4
						group by snz_uid, transitions_ind) b
				on (a.snz_uid = b.snz_uid and a.transitions_ind = b.transitions_ind and a._random_ = b._random_)
		);	

	disconnect from odbc;
quit;


%si_write_to_db(si_write_table_in=work._temp_comb_spells_rule3,
	si_write_table_out=&si_sandpit_libname..of_mhaet_population
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);


/*Delete temp*/
proc datasets lib=work;
	delete _temp_: ;
run;


