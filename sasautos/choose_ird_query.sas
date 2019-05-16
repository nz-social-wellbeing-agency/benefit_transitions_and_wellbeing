/*********************************************************************************************************
DESCRIPTION: 
	Selects between different business rules of creating IRD spells based on input parameter.
	activate_emp_low_flg = True takes into account the minimum wage per month while calculating 
	the employment spells and marks it as EMP_LO in event_type2. Ordinary employment spells are 
	marked with	EMP.

INPUT:
	&idi_version..ir_clean.ird_ems
	[IDI_Sandpit].[&si_proj_schema.].[yearly_minimum_wage]
	[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out.

OUTPUT:
	"queryvar": SQL Query string for creating the IRD spells

AUTHOR: 
	V Benny, W Lee

DEPENDENCIES:
	NA

NOTES:   

HISTORY: 
	05 Mar 2018	VB

***********************************************************************************************************/

%macro choose_ird_query(activate_emp_low_flg =, queryvar = ird_query_str);
	
	/* IRD W&S spells dataset with separate indicators for employment and underemployment (i.e, below threshold for minimum wage in a month)*/
	%if (&activate_emp_low_flg. = True) %then %do;
		%let &queryvar. = %str(
				/*8.  Create IRD W&S spells dataset.*/
				select
					snz_uid
					,'EMP' as datamart					
					,ir_ems_income_source_code as event_type
					,final_emp_status as event_type2
					,cast(NULL as varchar(1)) as event_type3
					,cast(NULL as varchar(1)) as event_type4
					,cast(min(start_date) as datetime) as start_date
					,cast(max(end_date) as datetime) as end_date
				from (
					/*7. Create a grouping variable to combine records that form part of the same spell.*/
					select *
						,sum(newspell) over (partition by snz_uid, ir_ems_income_source_code 
											order by start_date rows between unbounded preceding and current row) as grouper
					from (
						select snz_uid
							,ir_ems_income_source_code
							,start_date
							,end_date
							/*6. Rederive the new spells indicator, based on whether there is a break of more than one month between successive spells,
								or if the employment status changes.*/
							,case when datediff(mm, lag(start_date) over (partition by snz_uid, ir_ems_income_source_code order by start_date), start_date) > 1
								or lag(final_emp_status) over (partition by snz_uid, ir_ems_income_source_code order by start_date) <> final_emp_status
								then 1 else 0 end as [newspell]
							,ir_ems_gross_earnings_amt
							,final_emp_status
						from ( 
							select 
								snz_uid
								,ir_ems_income_source_code
								,start_date
								,end_date
								,newspell as newspell							
								,ir_ems_gross_earnings_amt
								/*5. If the current record is start of a new spell, and current record indicates underemployment, check the next record if it is EMP and inherit that 
									employment status provided the next record is part of the current spell.
									If the current record is end of a spell and current record indicates underemployment, check the previous record if it is EMP and inherit that 
									employment status provided the previous record is part of the current spell */
								,case when (prev_newspell is NULL and newspell = 0) or newspell = 1 then 									
									case when (next_emp_status = 'EMP' and next_newspell <> 1) then next_emp_status else emp_status end 								
									when (newspell = 0 and next_newspell = 1) and prev_emp_status = 'EMP' then prev_emp_status 
									else emp_status
								end as final_emp_status 
							from (
								/* 4. Derive previous and subsequent record's employment status, and whether or not the previous or next record is a new spell*/
								select *
									,lag(emp_status) over (partition by snz_uid, ir_ems_income_source_code order by start_date) as prev_emp_status
									,lead(emp_status) over (partition by snz_uid, ir_ems_income_source_code order by start_date) as next_emp_status
									,lag(newspell) over (partition by snz_uid, ir_ems_income_source_code order by start_date) as prev_newspell
									,lead(newspell) over (partition by snz_uid, ir_ems_income_source_code order by start_date) as next_newspell
								from (
									/* 3. W&S Spells data with employment indicator*/
									select *
										,case when threshold_amt > ir_ems_gross_earnings_amt then 'EMP_LO' else 'EMP' end as emp_status
									from (
										select 
											ems.snz_uid
											,ir_ems_income_source_code
											,datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1) as start_date
											,ir_ems_return_period_date as end_date
											/* If there is a break in 2 successive records of more than 1 month, create an indicator to signify the next record as start of a new employment spell*/
											,case when datediff(mm, lag(ir_ems_return_period_date) over (partition by ems.snz_uid, ir_ems_income_source_code order by ir_ems_return_period_date), ir_ems_return_period_date) > 1
												then 1 else 0 end as [newspell]
											,ir_ems_gross_earnings_amt
											/* 2. Calculate the monthly threshold amount from minimum wage to classify a person as being underemployed, with 20 hours per week*/
											,minwage.[minwage] * 20 * datediff(dd, datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1),ir_ems_return_period_date) / 7.0 as threshold_amt
										from (
											/* 1. Aggregate the IRD W&S to a monthly level in case of multiple W&S during a given month
											This however loses granular info on employer and industry type. */
											select 
												snz_uid
												,ir_ems_income_source_code
												,ir_ems_return_period_date
												,sum(ir_ems_gross_earnings_amt) as ir_ems_gross_earnings_amt
											from &idi_version..ir_clean.ird_ems
											where  ir_ems_income_source_code = 'W&S'
											group by snz_uid
												,ir_ems_income_source_code
												,ir_ems_return_period_date
										) ems
										inner join (select distinct snz_uid from [IDI_Sandpit].[&si_proj_schema.].of_main_ben_spells_comp) gss on (ems.snz_uid = gss.snz_uid)
										left join [IDI_Sandpit].[&si_proj_schema.].[yearly_minimum_wage] minwage on (ems.ir_ems_return_period_date between minwage.start_date and minwage.end_date )					
									)inner_query1
								)inner_query2
							)inner_query3
						)inner_query4
					)inner_query5
				)inner_query6
				group by 
					snz_uid
					,ir_ems_income_source_code
					,grouper
					,final_emp_status
				order by 
					snz_uid
					,ir_ems_income_source_code
					,start_date
		);
	%end;
	%else %do;
		%let &queryvar. = %str(
							/* IRD W&S spells dataset at snz_uid, employer and industry type level */
							select
								snz_uid
								,'EMP' as datamart
								,ir_ems_income_source_code as event_type
								,cast(snz_employer_ird_uid as varchar(20))as event_type2
								,cast(ir_ems_pbn_anzsic06_code as varchar(20)) as event_type3
								,cast(ir_ems_ent_anzsic06_code as varchar(20)) as event_type4
								,cast(min(start_date) as datetime) as start_date
								,cast(max(end_date) as datetime) as end_date
								,sum(ir_ems_gross_earnings_amt) as total_earnings
							from (
								select *
									/*2. Create a grouping variable to combine records that form part of the same spell (a spell is defined here as continuous monthly records of
										employment for one employer in the same industry type).*/
									,sum(newspell) over (partition by snz_uid
																	,ir_ems_income_source_code
																	,snz_employer_ird_uid
																	,ir_ems_pbn_anzsic06_code
																	,ir_ems_ent_anzsic06_code 
										order by start_date rows between unbounded preceding and current row) as grouper
								from (						
									select 
										ems.snz_uid
										,ir_ems_income_source_code
										,snz_employer_ird_uid
										,ir_ems_pbn_anzsic06_code
										,ir_ems_ent_anzsic06_code
										,datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1) as start_date
										,ir_ems_return_period_date as end_date
										/* If there is a break in 2 successive records of more than 1 month, create an indicator to signify the next record as start of a new employment spell
										for that employer for that industry type*/
										,case when datediff(mm, 
											lag(ir_ems_return_period_date) over (partition by ems.snz_uid, ir_ems_income_source_code, snz_employer_ird_uid
												,ir_ems_pbn_anzsic06_code
												,ir_ems_ent_anzsic06_code
												order by ir_ems_return_period_date), ir_ems_return_period_date) > 1
											then 1 else 0 end as [newspell]
										,ir_ems_gross_earnings_amt
									from (
										/* 1. Aggregate the IRD W&S to a monthly level for an individual for each employer and industry type. */
										select 
											snz_uid
											,ir_ems_income_source_code
											,ir_ems_return_period_date
											,snz_employer_ird_uid
											,ir_ems_pbn_anzsic06_code
											,ir_ems_ent_anzsic06_code
											,sum(ir_ems_gross_earnings_amt) as ir_ems_gross_earnings_amt
										from &idi_version..ir_clean.ird_ems
										where  
										ir_ems_income_source_code = 'W&S'
										group by 
											snz_uid
											,ir_ems_income_source_code
											,ir_ems_return_period_date
											,snz_employer_ird_uid
											,ir_ems_pbn_anzsic06_code
											,ir_ems_ent_anzsic06_code
									) ems					
									inner join (select distinct snz_uid from [IDI_Sandpit].[&si_proj_schema.].of_main_ben_spells_comp) gss on (ems.snz_uid = gss.snz_uid)		
								)inner_query1
							)inner_query2
							group by 
								snz_uid
								,ir_ems_income_source_code
								,snz_employer_ird_uid
								,ir_ems_pbn_anzsic06_code
								,ir_ems_ent_anzsic06_code
								,grouper		   
							order by snz_uid, start_date		   
					);
	%end;

	%put &queryvar.;
%mend;

/*%choose_ird_query(activate_emp_low_flg = True);*/