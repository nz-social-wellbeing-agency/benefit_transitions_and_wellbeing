/*******************************************************************************************************************
Description: National level annual off-benefit transition summary

Input: Outcomes framework benefit and IRD spells: [of_main_ben_spells] and [of_ird_spells].
As well as IRD and MSD tables accessed directly.


Output: Tables copied to Excel for output from the lab.

Author: Simon Anastasiadis

Dependencies: 

Notes: Results should be comparable to published results by SNZ from LEED on nzdotstats.stats.govt.nz which only
uses IRD data.

Time period: FROM 1 January TO 31 December FOR EACH YEAR 2014, 2015, 2016

We want to compute:

number of benefit days in this interval
number of benefit months in this interval
number of people with some benefit receipt in this interval
number of people with at least 1, 3, and 6 months benefit receipt in this interval
number of people who enter benefit in this interval
number of people who exit benefit in this interval
number of people who exit benefit for at least 30 days
number of people who exit benefit for at least 30 days and spend this time in employment


Issues: 

History (reverse order):
2018-05-07 BV v0.1 Add benefit type
2018-05-01 SA v0
*******************************************************************************************************************/


 /*****************************************By BENEFIT TYPE*********************************************/

 /* First creates benefit spells from 2007 to treat the 4 waves */

 /* Delete temporary tables & views if they exists */
USE [IDI_Sandpit]
GO
IF OBJECT_ID('[DL-MAA2016-15].[of_merge_benefit_spells]','U') IS NOT NULL
DROP TABLE [DL-MAA2016-15].[of_merge_benefit_spells];

/* Sandpit table for merged Benefit spells */
/* Merge all overlapping spells */
SELECT snz_uid
      ,cast(min([start_date]) AS DATETIME) AS [start_date]
      ,cast(max([end_date]) AS DATETIME) AS [end_date]
      ,event_type
INTO [IDI_Sandpit].[DL-MAA2016-15].[of_merge_benefit_spells]
FROM (
    SELECT snz_uid
	   	  ,[start_date]
	      ,[end_date]
    	  ,event_type
	   	  ,do_not_merge_w_next
          ,sum(do_not_merge_w_next) OVER(ORDER BY snz_uid, [start_date], [end_date], do_not_merge_w_next ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS cumulative
    FROM (
        /* add indicators for whether a row should be merged with the next row */
        SELECT snz_uid
	          ,[start_date]
		      ,[end_date]
    		  ,event_type
	   		  /* indicator for spell is independent of following spell */
	          ,CASE WHEN snz_uid = next_snz_uid
	                 AND [start_date] <= dateadd(day, 14, next_end)
		             AND next_start <= dateadd(day, 14, [end_date]) THEN 0 ELSE 1 END AS do_not_merge_w_next
    		  /* TO MERGE SPELLS WITH A GAP OF LESS THAN X DAYS BETWEEN THEM, ADD X TO next_end AND end_date IN THE CASE STATEMENT IMMEDIATELY ABOVE */
        FROM (
            /* Select core columns and lead columns from original table */
            SELECT [snz_uid]
                  ,[start_date]
                  ,[end_date]
			      ,'ben' AS event_type
    	          ,LEAD(snz_uid, 1, -1) OVER( ORDER BY snz_uid, [start_date], [end_date]) AS next_snz_uid
	              ,LEAD([start_date], 1, NULL) OVER( ORDER BY snz_uid, [start_date], [end_date]) AS next_start
	              ,LEAD([end_date], 1, '9999-01-01') OVER( ORDER BY snz_uid, [start_date], [end_date]) AS next_end
		    /* NAME OF TABLE YOU WANT TO REMOVE OVERLAPPING SPELLS FROM GOES HERE */
            FROM (
	    	    SELECT [snz_uid], [start_date], CASE WHEN [end_date] > '9999-01-01' THEN '9999-01-01' ELSE [end_date] END AS [end_date]
		    	FROM [IDI_Sandpit].[DL-MAA2016-15].[SIAL_MSD_T1_events]
				WHERE [end_date] >= '2007-01-01'
            ) k
        ) k
    ) k
) k
GROUP BY event_type, snz_uid, cumulative
GO






/*
Time period: FROM 1 January TO 31 December FOR EACH YEAR 2008, 2010, 2012, 2014

We want to compute:

number of benefit days in this interval
number of benefit months in this interval
number of people with some benefit receipt in this interval
number of people with at least 1, 3, and 6 months benefit receipt in this interval
number of people who enter benefit in this interval
number of people who exit benefit in this interval
number of people who exit benefit for at least 30 days
number of people who exit benefit for at least 30 days and spend this time in employment
[equiv to has W&S in IRD-EMS in the month of benefit exit and the following month]
*/

/* Breakdown by benefit type for the count of transitions ben to emp. The first one in case of several transitions */


SELECT count(distinct snz_uid)
	, event_type_3
FROM (
	SELECT DISTINCT a.*
		, MIN(clipped_end_date) over (partition by a.snz_uid) as min_clipped_end_date 
		, b.event_type_3
	FROM (
		SELECT DISTINCT snz_uid
			, start_date
			, end_date
			, clipped_start_date
			, clipped_end_date
			, next_start
			, num_EMS
			,datediff(day,clipped_start_date,clipped_end_date) AS num_days_on_benefit
			,datediff(month,clipped_start_date,clipped_end_date) AS num_months_on_benefit
			,CASE WHEN datediff(day,clipped_start_date,clipped_end_date) >=  30 THEN 1 ELSE 0 END AS _30plus_days_on_benefit
			,CASE WHEN datediff(day,clipped_start_date,clipped_end_date) >=  90 THEN 1 ELSE 0 END AS _90plus_days_on_benefit
			,CASE WHEN datediff(day,clipped_start_date,clipped_end_date) >= 180 THEN 1 ELSE 0 END AS _180plus_days_on_benefit
			,CASE WHEN clipped_start_date = [start_date] THEN 1 ELSE 0 END AS begin_benefit
			,CASE WHEN clipped_end_date = [end_date] THEN 1 ELSE 0 END AS exit_benefit

			,CASE WHEN clipped_end_date = [end_date] 
									AND datediff(day,clipped_end_date,next_start) >= 30
									THEN 1 ELSE 0 END AS exit_benefit_30plus_days
	
			,CASE WHEN clipped_end_date = [end_date] 
									AND datediff(day,clipped_end_date,next_start) >= 30
									AND num_EMS >= 1
									THEN 1 ELSE 0 END AS exit_to_employ_30plus_days
		FROM (
			SELECT ben.snz_uid
				,ben.[start_date]
				,ben.[end_date]
				,clipped_start_date
				,clipped_end_date
				,coalesce(next_start, '9999-01-01') AS next_start
				,count([ir_ems_income_source_code]) AS num_EMS
			FROM (
				SELECT *
				FROM (
					SELECT snz_uid
						  ,CASE WHEN [start_date] <= '2012-01-01' THEN '2012-01-01' ELSE [start_date] END AS clipped_start_date
						  ,CASE WHEN [end_date] >= '2012-12-31' THEN '2012-12-31' ELSE [end_date] END AS clipped_end_date
						  ,[start_date]
						  ,[end_date]
						  ,LEAD([start_date], 1, NULL) OVER(PARTITION BY snz_uid ORDER BY [start_date], [end_date]) AS next_start
					FROM [IDI_Sandpit].[DL-MAA2016-15].[of_merge_benefit_spells]
				) k
				WHERE [end_date] >= '2012-01-01'
				AND [start_date] <= '2012-12-31'
			) ben
			LEFT JOIN (
				SELECT [snz_uid]
					,[ir_ems_return_period_date]
					,[ir_ems_income_source_code]
				FROM [IDI_Clean].[ir_clean].[ird_ems]
				WHERE [ir_ems_income_source_code] = 'W&S'
				AND [ir_ems_return_period_date] >= '2012-01-01'
			) emp
			ON ben.snz_uid = emp.snz_uid
			AND [ir_ems_return_period_date] BETWEEN ben.[end_date] AND dateadd(month,2,ben.[end_date])
			GROUP BY ben.snz_uid
				,ben.[start_date]
				,ben.[end_date]
				,clipped_start_date
				,clipped_end_date
				,next_start
		) z
	) a
	left join [IDI_Sandpit].[DL-MAA2016-15].[SIAL_MSD_T1_events] b 
		on a.snz_uid=b.snz_uid and a.start_date=b.start_date
		where exit_to_employ_30plus_days=1
) aa
WHERE clipped_end_date=min_clipped_end_date
GROUP BY event_type_3




