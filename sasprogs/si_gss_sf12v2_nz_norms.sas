/*****************************************************************
* SF12V2-1.SAS
* SAS CODE FOR SCORING 12-ITEM HEALTH SURVEY VERSION 2.0
* WRITTEN BY K. SPRITZER, 6/23/2003
* MODIFIED: 6/28/2004
* MODIFIED: 22/03/2018 CS Wright SIA 
			07/06/2018	V Benny	SIA
*****************************************************************/


/* V Benny, added 07/06/2018  : Create the SF-12 questionnaire response dataset for all individuals from 
the GSS*/
proc sql;
	connect to odbc (dsn=&si_idi_dsnname.);
	create table temp1 as 
		select * from connection to odbc(
			select 
				snz_uid
				,gss_pq_collection_code
				,pers.gss_pq_HEAQ01 - 10 AS I1
				,pers.gss_pq_HEAQ02a - 10 AS I2A
				,pers.gss_pq_HEAQ02b - 10 AS I2B
				,pers.gss_pq_HEAQ03 - 10 AS I3A
				,pers.gss_pq_HEAQ04 - 10 AS I3B
				,pers.gss_pq_HEAQ05 - 10 AS I4A
				,pers.gss_pq_HEAQ06 - 10 AS I4B
				,pers.gss_pq_HEAQ07 - 10 AS I5
				,pers.gss_pq_HEAQ08a - 10 AS I6A
				,pers.gss_pq_HEAQ08b - 10 AS I6B
				,pers.gss_pq_HEAQ08c - 10 AS I6C
				,pers.gss_pq_HEAQ09 - 10 AS I7
				,cast(pers.gss_pq_HEADV2 as integer) AS mental_status
				,cast(pers.gss_pq_HEADV3 as integer) AS physical_status 
			from &idi_version..gss_clean.gss_person_2008 pers
			union all
			select 
				snz_uid
				,gss_pq_collection_code
				,pers.gss_pq_HEAQ01 - 10 AS I1
				,pers.gss_pq_HEAQ02a - 10 AS I2A
				,pers.gss_pq_HEAQ02b - 10 AS I2B
				,pers.gss_pq_HEAQ03 - 10 AS I3A
				,pers.gss_pq_HEAQ04 - 10 AS I3B
				,pers.gss_pq_HEAQ05 - 10 AS I4A
				,pers.gss_pq_HEAQ06 - 10 AS I4B
				,pers.gss_pq_HEAQ07 - 10 AS I5
				,pers.gss_pq_HEAQ08a - 10 AS I6A
				,pers.gss_pq_HEAQ08b - 10 AS I6B
				,pers.gss_pq_HEAQ08c - 10 AS I6C
				,pers.gss_pq_HEAQ09 - 10 AS I7
				,cast(pers.gss_pq_HEADV2 as integer) AS mental_status
				,cast(pers.gss_pq_HEADV3 as integer) AS physical_status 
			from &idi_version..gss_clean.gss_person_2010 pers
			union all
			select 
				snz_uid
				,gss_pq_collection_code
				,pers.gss_pq_HEAQ01 - 10 AS I1
				,pers.gss_pq_HEAQ02a - 10 AS I2A
				,pers.gss_pq_HEAQ02b - 10 AS I2B
				,pers.gss_pq_HEAQ03 - 10 AS I3A
				,pers.gss_pq_HEAQ04 - 10 AS I3B
				,pers.gss_pq_HEAQ05 - 10 AS I4A
				,pers.gss_pq_HEAQ06 - 10 AS I4B
				,pers.gss_pq_HEAQ07 - 10 AS I5
				,pers.gss_pq_HEAQ08a - 10 AS I6A
				,pers.gss_pq_HEAQ08b - 10 AS I6B
				,pers.gss_pq_HEAQ08c - 10 AS I6C
				,pers.gss_pq_HEAQ09 - 10 AS I7
				,cast(pers.gss_pq_HEADV2 as integer) AS mental_status
				,cast(pers.gss_pq_HEADV3 as integer) AS physical_status 
			from &idi_version..gss_clean.gss_person_2012 pers
			union all
			select 
				snz_uid
				,gss_pq_collection_code
				,[gss_pq_health_excel_poor_code] - 10 as I1
				,[gss_pq_health_limits_activ_code] - 10 as I2A
				,[gss_pq_health_limits_stairs_code] - 10 as I2B
				,[gss_pq_accomplish_less_phys_code] - 10 as I3A
				,[gss_pq_limited_work_phys_code] - 10 as I3B
				,[gss_pq_accomplish_less_emo_code] - 10 as I4A
				,[gss_pq_less_careful_emo_code] - 10 as I4B
				,[gss_pq_pain_interfere_code] - 10 as I5
				,[gss_pq_felt_calm_code] - 10 as I6A
				,[gss_pq_felt_energetic_code] - 10 as I6B
				,[gss_pq_felt_depressed_code] - 10 as I6C
				,[gss_pq_health_interfere_soc_code] - 10 as I7
				,cast([gss_pq_ment_health_code] as smallint) as mental_status
				,cast([gss_pq_phys_health_code] as smallint) as physical_status
			 from &idi_version..gss_clean.gss_person

			);

	disconnect from odbc;
quit;


/*****************************************************************
** CODE OUT-OF-RANGE VALUES TO MISSING;
*****************************************************************/
DATA TEMP1;
	SET TEMP1;
	ARRAY PT5 I1 I3A I3B I4A I4B I5 I6A I6B I6C I7;

	DO OVER PT5;
		IF PT5 NOT IN (1,2,3,4,5) THEN
			PT5=.;
	END;

	ARRAY PT3 I2A I2B;

	DO OVER PT3;
		IF PT3 NOT IN (1,2,3) THEN
			PT3=.;
	END;
RUN;
/***************************************************************************/


/***************************************************************************/
DATA TEMP1;
	SET TEMP1;

	/***************************************************************************;
	** WHEN NECESSARY, REVERSE CODE ITEMS SO A HIGHER SCORE MEANS BETTER HEALTH;
	***************************************************************************/
	IF I1=1 THEN
		I1=5.0;
	ELSE IF I1=2 THEN
		I1=4.4;
	ELSE IF I1=3 THEN
		I1=3.4;
	ELSE IF I1=4 THEN
		I1=2.0;
	ELSE IF I1=5 THEN
		I1=1.0;
	I5=6-I5;
	I6A=6-I6A;
	I6B=6-I6B;

	/* CREATE SCALES */
	PF=I2A+I2B;
	RP=I3A+I3B;
	BP=I5;
	GH=I1;
	VT=I6B;
	SF=I7;
	RE=I4A+I4B;
	MH=I6A+I6C;

	
	PF=100*(PF-2)/4;
	RP=100*(RP-2)/8;
	BP=100*(BP-1)/4;
	GH=100*(GH-1)/4;
	VT=100*(VT-1)/4;
	SF=100*(SF-1)/4;
	RE=100*(RE-2)/8;
	MH=100*(MH-2)/8;
RUN;
            

DATA TEMP1; 
SET TEMP1;
 
/* 1) TRANSFORM SCORES TO Z-SCORES
NZ GENERAL POPULATION MEANS AND SD'S ARE USED HERE 
(NOT AGE/GENDER BASED) */

/* V Benny, added 07/06/2018 : Added NZ populations' SF12v2 population means and std.deviations in addition
to US values.
Reference: Frieling MA, Davis WR, Chiang G.: The SF36v2 and SF12v2 health surveys in New Zealand, norms, 
scoring coefficients and cross-country comparisons
*/
              
   PF_Z = (PF - 88.6) /  25.0;
   RP_Z = (RP - 84.9) /  24.4;
   BP_Z = (BP - 81.7) /  28.3;
   GH_Z = (GH - 74.0) /  25.1;
   VT_Z = (VT - 64.0) /  23.5;
   SF_Z = (SF - 88.5) /  22.7;
   RE_Z = (RE - 89.3) /  18.6;
   MH_Z = (MH - 76.1) /  18.1;

/*US MOS values               */
   US_PF_Z = (PF - 81.18122) / 29.10588 ; 
   US_RP_Z = (RP - 80.52856) / 27.13526 ; 
   US_BP_Z = (BP - 81.74015) / 24.53019 ; 
   US_GH_Z = (GH - 72.19795) / 23.19041 ; 
   US_VT_Z = (VT - 55.59090) / 24.84380 ; 
   US_SF_Z = (SF - 83.73973) / 24.75775 ; 
   US_RE_Z = (RE - 86.41051) / 22.35543 ; 
   US_MH_Z = (MH - 70.18217) / 20.50597 ; 


/*** 2) CREATE PHYSICAL AND MENTAL HEALTH COMPOSITE SCORES: **********;
***    MULTIPLY Z-SCORES BY VARIMAX-ROTATED FACTOR SCORING **********;
***    COEFFICIENTS AND SUM THE PRODUCTS ****************************/

/* V Benny, added 07/06/2018 : Added NZ populations' SF12v2 PCS & MCS scores in addition
to US values.
Reference: Frieling MA, Davis WR, Chiang G.: The SF36v2 and SF12v2 health surveys in New Zealand, norms, 
scoring coefficients and cross-country comparisons
*/

AGG_PHYS	=	(PF_Z	*	0.3970	)	+
(RP_Z	*	0.3670	)	+		
(BP_Z	*	0.3400	)	+		
(GH_Z	*	0.1500	)	+		
(VT_Z	*	0.0280	)	+		
(SF_Z	*	0.0500	)	+		
(RE_Z	*	-0.1310	)	+		
(MH_Z	*	-0.2250	)	;		

AGG_MENT	=	(PF_Z	*	-0.160	)	+
(RP_Z	*	-0.097	)	+		
(BP_Z	*	-0.123	)	+		
(GH_Z	*	0.110	)	+		
(VT_Z	*	0.257	)	+		
(SF_Z	*	0.212	)	+		
(RE_Z	*	0.390	)	+		
(MH_Z	*	0.491	)	;		


/*US MOS*/
   US_AGG_PHYS = (US_PF_Z * 0.42402) + 
              (US_RP_Z * 0.35119) + 
              (US_BP_Z * 0.31754) +
              (US_GH_Z * 0.24954) + 
              (US_VT_Z * 0.02877) + 
              (US_SF_Z * -.00753) + 
              (US_RE_Z * -.19206) + 
              (US_MH_Z * -.22069) ;
              

              
   US_AGG_MENT = (US_PF_Z * -.22999) + 
              (US_RP_Z * -.12329) + 
              (US_BP_Z * -.09731) +
              (US_GH_Z * -.01571) + 
              (US_VT_Z * 0.23534) + 
              (US_SF_Z * 0.26876) +
              (US_RE_Z * 0.43407) + 
              (US_MH_Z * 0.48581) ;


/*** 3) TRANSFORM COMPOSITE AND SCALE SCORES TO T-SCORES: ******/ 

   AGG_PHYS = 50 + (AGG_PHYS * 10);
   AGG_MENT = 50 + (AGG_MENT * 10);
   US_AGG_PHYS = 50 + (US_AGG_PHYS * 10);
   US_AGG_MENT = 50 + (US_AGG_MENT * 10);

   LABEL AGG_PHYS="NEMC PHYSICAL HEALTH T-SCORE - SF12";
   LABEL AGG_MENT="NEMC MENTAL HEALTH T-SCORE - SF12";

   PF_T = 50 + (PF_Z * 10) ;
   RP_T = 50 + (RP_Z * 10) ;
   BP_T = 50 + (BP_Z * 10) ;
   GH_T = 50 + (GH_Z * 10) ;
   VT_T = 50 + (VT_Z * 10) ;
   RE_T = 50 + (RE_Z * 10) ;
   SF_T = 50 + (SF_Z * 10) ;
   MH_T = 50 + (MH_Z * 10) ;

   LABEL PF_T="NEMC PHYSICAL FUNCTIONING T-SCORE";
   LABEL RP_T="NEMC ROLE LIMITATION PHYSICAL T-SCORE";
   LABEL BP_T="NEMC PAIN T-SCORE";
   LABEL GH_T="NEMC GENERAL HEALTH T-SCORE";
   LABEL VT_T="NEMC VITALITY T-SCORE";
   LABEL RE_T="NEMC ROLE LIMITATION EMOTIONAL T-SCORE";
   LABEL SF_T="NEMC SOCIAL FUNCTIONING T-SCORE";
   LABEL MH_T="NEMC MENTAL HEALTH T-SCORE";

RUN;

proc sql;

create table _temp_sf12 as 
	select 
		snz_uid
		,gss_pq_collection_code		
		,physical_status as original_physical_status
		,mental_status as original_mental_status 
		,case when physical_status <= 100 then physical_status else . end as physical_status
		,case when mental_status <= 100 then mental_status else . end as mental_status
		,round(agg_phys) as agg_phys
		,round(agg_ment) as agg_ment
		,round(us_agg_phys) as us_agg_phys
		,round(us_agg_ment) as us_agg_ment
		,case when physical_status <= 100 then physical_status else . end - 
			case when gss_pq_collection_code = 'GSS2008' then round(us_agg_phys) else round(agg_phys) end as phys_orig_calc_diff
		,case when mental_status <= 100 then mental_status else . end - 
			case when gss_pq_collection_code = 'GSS2008' then round(us_agg_ment) else round(agg_ment) end as ment_orig_calc_diff
	from temp1;

quit;

proc sql;
	
	create table _temp_sf12vars as 
	select 
		ind.*
		,temp.agg_phys,temp.agg_ment
		,case when -100 < temp.agg_phys < 0 then 0 else temp.agg_phys end as health_nzsf12_physical
		,case when -100 < temp.agg_ment < 0 then 0 else temp.agg_ment end as health_nzsf12_mental
	from 
	sand.&si_pop_table_out. ind
	left join _temp_sf12 temp on (ind.snz_uid = temp.snz_uid)
;

quit;

/* Push the cohort into the database*/
%si_write_to_db(si_write_table_in=work._temp_sf12vars,
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out.
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col.)
	);


/* Testing the scores for match with original*/
/*TITLE1 "SF12 V2 - OVERALL DESCRIPTIVE STATISTICS ON SCALE SCORES"; RUN;*/
/*PROC MEANS DATA=TEMP1; */
/*VAR PF PF_T  */
/*    RP RP_T  */
/*    BP BP_T */
/*    GH GH_T */
/*    VT VT_T */
/*    SF SF_T */
/*    RE RE_T */
/*    MH MH_T */
/*    AGG_PHYS AGG_MENT*/
/*	US_AGG_PHYS US_AGG_MENT;*/
/*RUN;*/
/**/
/*proc sql;*/
/*create table temp3 as */
/*	select * from _temp_sf12 */
/*	where gss_pq_collection_code ne 'GSS2008' and ((agg_phys ne physical_status) or (agg_ment ne mental_status))*/
/*	union all */
/*	select * from _temp_sf12 */
/*	where gss_pq_collection_code = 'GSS2008' and ((us_agg_phys ne physical_status) or (us_agg_ment ne mental_status));*/
/*quit;*/
/**/
/*proc sort data=_temp_sf12; by gss_pq_collection_code;*/
/*proc means data=_temp_sf12(where=(physical_status between 0 and 100) keep=gss_pq_collection_code AGG_PHYS US_AGG_PHYS physical_status);*/
/*by gss_pq_collection_code;run;*/
/**/
/*proc means data=_temp_sf12(where=(mental_status between 0 and 100) keep=gss_pq_collection_code AGG_MENT US_AGG_MENT mental_status);*/
/*by gss_pq_collection_code;run;*/
/**/
/*proc sql;*/
/*select * from temp3 where abs(ment_orig_calc_diff ) > 1;*/
/*quit;*/