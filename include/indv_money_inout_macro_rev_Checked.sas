 /*
   Title: Extract earnings and deductions for selelected individual
          clients.
 
   Purpose: Generate monthly earnings and deductions from all available income
            sources in the IDI.
            Current coverage
            - IRD EMS
            - IRD IR3, PTS
            - MSD second tier benefits (non-taxable)
            - MSD third tier benefits (non-taxable)
            - MSD/IR Student Loans and Allowances
            - WFF tax credits
 
   Author: Marc de Boer, MSD
 
   Date: March 2016
 
   Change History
   WHEN        WHO                WHAT
   March 2018  Bryan Ku, MSD      Added date parameter if IDIdate was not specified
   March 2018  Bryan Ku, MSD      Added batch size limiter option to WFF dataset extracter
   June 2018   Marc de Boer, MSD  Updated code to reflect feedback from Treasury and IR.

 */
 

******************************************************************************
 Copy the following into your code to run 

 %indv_money_inout_macro( IMMIO_infile =
                         ,IMMIO_IDIexDt =
                         ,IMMIO_RptSD =
                         ,IMMIO_RptED =
                         ,IMMIO_Outfile =
                         ,IMMIO_IncomeDetail = 2
                         ,IMMIO_LoanDetail = 2
                         ,IMMIO_TaxDetail = 2
                         ,IMMIO_TransferDetail = 2
                         ,IMMIO_annual = IncomeOutgoingsAnnual
                         ,IMMIO_InCDudCode = IncomeOutgoingsCodeLookup
                         ,IMMIO_SandPitSchema = DL-MAA2014-11
                         ) ;

  *
  IMMIO_infile: infile containing the snz_uids to extract (if blank extracts the whole population WARNING this will crash the session)
  IMMIO_IDIexDt: <no longer used> IDI extract date (ie 20160224)
  IMMIO_RptSD / IMMIO_RptED: expressed as ddMMMyyyy (eg 01Jan2015) limits the monthly expenditure to within the specificed 
                             date range. If left null the macro will extract the full range of values. 
  IMMIO_Outfile: outfile name for the dataset containing all sources of income 
               and tax and student loan deductions.
  IMMIO_IncomeDetail: detailed information on income 0 returns no records 1 summary and 2 all income records
  IMMIO_LoanDetail: detailed information on loans 0 returns no records 1 summary and 2 all loans records
  IMMIO_TaxDetail: detailed information on tax 0 returns no records 1 summary and 2 all tax records 
  IMMIO_TransferDetail: detailed information on transfer payments 0 returns no records 1 summary and 2 all transfer payments records
  IMMIO_annual: summary table of requested income and outgoings by tax year to check amounts across data sources
  IMMIO_InCDudCode: reference table of InCDudCode metadata for requested income and outgoings records.
  IMMIO_SandPitSchema: for the Subset_IDIdataset2 macro need to give a write to location on the SQL server usually the project folder (eg DL-MAA2014-11) 
  *;
 

******************************************************************************
   * Reference tables *;

* metadata table for all income and outgoings records *;
DATA IncomeDeductionCodes  ;
  INFILE DATALINES DELIMITER = "~" ;
  LENGTH InCDudCode $6. LevelN 8. Level1 $10. Level2 $15. Level3 $60. Period $6. PersonView 8.  IDI_tble $32. IDI_var $32. Notes $100.;
  INPUT  InCDudCode     LevelN    Level1      Level2      Level3      Period     PersonView     IDI_tble      IDI_var      Notes;
  LABEL InCDudCode = "Reference code"
       LevelN = "InCDudCode detail level 1 summary 2 detailed"
       Level1 = "Income tax event group level 1" 
       Level2 = "Income tax event group level 2"  
       Level3  = "Income tax event group level 3" 
       PersonView  = "Convert sign from agency to person perspective"   
       IDI_tble = "name of IDI source table"
       IDI_var = "name of IDI variable"
       Notes = "Relevent information about the event"
       ;
  DATALINES ;
  ir3ntp ~2 ~Income   ~Gross income ~Self-employment income          ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_net_profit_amt            ~ 
  ir3eti ~2 ~Income   ~Gross income ~Estate trust income             ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_estate_trust_income_amt   ~
  ir3gdv ~2 ~Income   ~Gross income ~Gross dividend                  ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_gross_dividend_amt        ~
  emsppl ~2 ~Income   ~Gross Income ~Paid parental leave             ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emswas ~2 ~Income   ~Gross Income ~Wages and salaries              ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emswhp ~2 ~Income   ~Gross Income ~Contract payment                ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  ir3int ~2 ~Income   ~Gross income ~Interest payments               ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_gross_interest_amt        ~
  ptsint ~2 ~Income   ~Gross income ~Interest payments               ~Annual ~1  ~ird_pts                ~ir_pts_tot_interest_amt          ~
  ir3rnt ~2 ~Income   ~Gross income ~Net rental income               ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_net_rents_826_amt         ~
  ir3ovi ~2 ~Income   ~Gross income ~Overseas income                 ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_overseas_income_amt       ~
  ir3oti ~2 ~Income   ~Gross income ~Other income                    ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_other_income_amt          ~
  ir3tpi ~2 ~Income   ~Gross income ~Partnership income              ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_tot_pship_income_amt      ~
  ir3shr ~2 ~Income   ~Gross income ~Shareholder salary              ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_tot_sholder_salary_amt    ~
  ptsdiv ~2 ~Income   ~Gross income ~Dividend payments               ~Annual ~1  ~ird_pts                ~ir_pts_tot_dividend_amt          ~
  ir3tin ~1 ~Income   ~Gross income ~Taxable income                  ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_taxable_income_amt        ~
  ptstin ~1 ~Income   ~Gross income ~Taxable income                  ~Annual ~1  ~ird_pts                ~ir_pts_taxable_inc_amt           ~
  ir3407 ~1 ~Income   ~Gross income ~Income with PAYE                ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_gross_earnings_407_amt    ~
  ptsgre ~1 ~Income   ~Gross income ~Income with PAYE                ~Annual ~1  ~ird_pts                ~ir_pts_tot_gross_earnings_amt    ~
  emsgre ~1 ~Income   ~Gross income ~Income with PAYE                ~Month  ~1  ~ird_ems                ~ir_ems_gross_earnings_amt        ~Scaled to PTS/IR3 if possible
  ir3wpi ~1 ~Income   ~Gross income ~Income with WHT                 ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_tot_wholding_paymnts_amt  ~
  emswpi ~1 ~Income   ~Gross income ~Income with WHT                 ~Month  ~1  ~ird_ems                ~ir_ems_wht_earnings_amt          ~Scaled to PTS/IR3 if possible
  ir3tec ~1 ~Tax      ~Expenses     ~Total expenses                  ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_tot_expenses_claimed_amt  ~
  ptsexp ~1 ~Tax      ~Expenses     ~Total expenses                  ~Annual ~1  ~ird_pts                ~ir_pts_tot_exp_amt               ~
  ir3tti ~1 ~Tax      ~Tax to pay   ~Tax on taxable income           ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_tax_on_taxable_income_amt ~
  ptstti ~1 ~Tax      ~Tax to pay   ~Tax on taxable income           ~Annual ~-1 ~ird_pts                ~ir_pts_tot_tax_on_inc_amt        ~
  emsact ~2 ~Tax      ~Tax paid     ~PAYE ACC income compensation    ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emspet ~2 ~Tax      ~Tax paid     ~PAYE superannuation             ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible 
  emsppt ~2 ~Tax      ~Tax paid     ~PAYE paid parental leave        ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emsstt ~2 ~Tax      ~Tax paid     ~PAYE student allowance          ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emswat ~2 ~Tax      ~Tax paid     ~PAYE wages and salaries         ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emsbet ~2 ~Tax      ~Tax paid     ~PAYE main benefit               ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emswht ~2 ~Tax      ~Tax paid     ~WHT contract payment            ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  ptsrwt ~2 ~Tax      ~Tax paid     ~WHT interest                    ~Annual ~1  ~ird_pts                ~ir_pts_tot_rwt_amt               ~
  ptsdwt ~2 ~Tax      ~Tax paid     ~WHT dividends                    ~Annual ~1  ~ird_pts                ~ir_pts_tot_dwt_amt               ~
  emspay ~1 ~Tax      ~Tax paid     ~PAYE total                      ~Month  ~1  ~ird_ems                ~ir_ems_paye_deductions_amt       ~Scaled to PTS/IR3 if possible
  emswtx ~1 ~Tax      ~Tax paid     ~WHT total                       ~Month  ~1  ~ird_ems                ~ir_ems_withholding_tax_amt       ~Split from ir_ems_paye_deductions_amt where ir_ems_withholding_type_code = "W" Scaled to PTS/IR3 if possible
  ir3reb ~1 ~Tax      ~Tax rebates  ~Total rebate                    ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_tot_rebate_amt            ~
  ptsreb ~1 ~Tax      ~Tax rebates  ~Total rebate                    ~Annual ~-1 ~ird_pts                ~ir_pts_tot_rebates_amt           ~
  ptschr ~2 ~Tax      ~Tax rebates  ~Child rebate                    ~Annual ~1  ~ird_pts                ~ir_pts_child_rebate_amt          ~
  ptslwi ~2 ~Tax      ~Tax rebates  ~Low income rebate               ~Annual ~1  ~ird_pts                ~ir_pts_low_income_rebate_amt     ~
  ptsthr ~2 ~Tax      ~Tax rebates  ~Threshold rebate                ~Annual ~1  ~ird_pts                ~ir_pts_threshold_rebate_amt      ~
  ptslep ~2 ~Tax      ~ACC          ~Earner premium                  ~Annual ~1  ~ird_pts                ~ir_pts_tot_earner_premium_amt    ~
  ptsnep ~1 ~Tax      ~ACC          ~Non liable earner amount        ~Annual ~1  ~ird_pts                ~ir_pts_tot_nonliable_earning_amt ~
  emsnep ~1 ~Tax      ~ACC          ~Non liable earner amount        ~Month  ~1  ~ird_ems                ~ir_ems_earnings_not_liable_amt   ~
  emsacp ~1 ~Transfer ~ACC          ~ACC income compensation         ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emspen ~1 ~Transfer ~Pension      ~Superannuation                  ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  emsben ~1 ~Transfer ~Main benefit ~Main benefit                    ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  stetot ~1 ~Transfer ~Supplementary ~Supplementary total             ~Month  ~1  ~msd_second_tier_expenditure ~msd_ste_daily_gross_amt     ~
  ttetot ~1 ~Transfer ~Hardship     ~Hardship payments total         ~Month  ~1  ~msd_third_tier_expenditure ~msd_tte_pmt_amt              ~where msd_tte_recoverable_ind <> "Y"
  ir3ctc ~2 ~Transfer ~Tax credit   ~Entitlement child tax credit    ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_child_tax_crdt_entl_amt   ~
  ptsctc ~2 ~Transfer ~Tax credit   ~Entitlement child tax credit    ~Annual ~-1 ~ird_pts                ~ir_pts_child_tax_crdt_entl_amt   ~
  frdctc ~2 ~Transfer ~Tax credit   ~Entitlement child tax credit    ~Annual ~-1 ~fam_return_dtls        ~wff_frd_ctc_entitlement_amt      ~
  ir3fsc ~2 ~Transfer ~Tax credit   ~Entitlement family supplementary tax credit ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_fam_sup_tax_crdt_entl_amt ~
  ptsfsc ~2 ~Transfer ~Tax credit   ~Entitlement family supplementary tax credit ~Annual ~-1 ~ird_pts    ~ir_pts_fam_sup_tax_crdt_entl_amt ~
  frdfsc ~2 ~Transfer ~Tax credit   ~Entitlement family supplementary tax credit ~Annual ~-1~fam_return_dtls ~wff_frd_fstc_entitlement_amt ~
  ir3ftx ~2 ~Transfer ~Tax credit   ~Entitlement family tax credit    ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_family_tax_crdt_entl_amt ~
  ptsftx ~2 ~Transfer ~Tax credit   ~Entitlement family tax credit   ~Annual ~-1 ~ird_pts                ~ir_pts_family_tax_crdt_entl_amt  ~
  frdftx ~2 ~Transfer ~Tax credit   ~Entitlement family tax credit   ~Annual ~-1 ~fam_return_dtls        ~wff_frd_ftc_entitlement_amt      ~
  ir3iwp ~2 ~Transfer ~Tax credit   ~Entitlement in work payment     ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_in_work_payment_entl_amt  ~
  ptsiwp ~2 ~Transfer ~Tax credit   ~Entitlement in work payment     ~Annual ~-1 ~ird_pts                ~ir_pts_in_work_payment_entl_amt  ~
  frdiwp ~2 ~Transfer ~Tax credit   ~Entitlement in work payment     ~Annual ~-1 ~fam_return_dtls        ~wff_frd_iwp_entitlement_amt      ~
  ptsiet ~2 ~Transfer ~Tax credit   ~Entitlement independent earner  ~Annual ~-1 ~ird_pts                ~ir_pts_ind_ern_tax_crdt_entl_amt ~
  ir3ptx ~2 ~Transfer ~Tax credit   ~Entitlement parental tax credit ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_parent_tax_crdt_entl_amt  ~
  ptsptx ~2 ~Transfer ~Tax credit   ~Entitlement parental tax credit ~Annual ~-1 ~ird_pts                ~ir_pts_parent_tax_crdt_entl_amt  ~
  frdptx ~2 ~Transfer ~Tax credit   ~Entitlement parental tax credit ~Annual ~-1 ~fam_return_dtls        ~wff_frd_ptc_entitlement_amt      ~
  frdtce ~1 ~Transfer ~Tax credit   ~Entitlement tax credits total   ~Annual ~-1 ~fam_return_dtls        ~wff_frd_total_entilement_amt     ~Derived from all tax credit entitlements
  ir3tce ~1 ~Transfer ~Tax credit   ~Entitlement tax credits total   ~Annual ~-1 ~ird_rtns_keypoints_ir3 ~ir_ir3_tax_crdt_total_entl_amt   ~Derived from all tax credit entitlements
  ptstce ~1 ~Transfer ~Tax credit   ~Entitlement tax credits total   ~Annual ~-1 ~ird_pts                ~ir_pts_tax_crdt_total_entl_amt   ~Derived from all tax credit entitlements
  fdrfsc ~2 ~Transfer ~Tax credit   ~Regular pay family supplementary tax credit IR ~Month ~1 ~fam_daily_rate ~wff_fdr_daily_fstc_rate_amt ~
  fdrftx ~2 ~Transfer ~Tax credit   ~Regular pay family tax credit IR ~Month ~1  ~fam_daily_rate         ~wff_fdr_daily_ftc_rate_amt       ~
  fdriwp ~2 ~Transfer ~Tax credit   ~Regular pay in work payment regular IR ~Month ~1 ~fam_daily_rate    ~wff_fdr_daily_iwp_rate_amt       ~
  fdrctc ~2 ~Transfer ~Tax credit   ~Regular pay child tax credit IR ~Month ~1    ~fam_daily_rate        ~wff_fdr_daily_ctc_rate_amt       ~
  fdrptx ~2 ~Transfer ~Tax credit   ~Regular pay parental tax credit IR ~Month ~1 ~fam_daily_rate        ~wff_fdr_daily_ptc_rate_amt       ~
  frdtwi ~2 ~Transfer ~Tax credit   ~Regular pay all tax credits MSD ~Annual ~-1 ~fam_return_dtls        ~wff_frd_winz_paid_amt            ~
  emstpm ~2 ~Transfer ~Tax credit   ~Regular pay all tax credits MSD ~Month ~-1  ~ird_ems                ~ir_ems_fstc_amt                  ~Scaled to MSD pay annual amount (frdtwi)
  frdtir ~2 ~Transfer ~Tax credit   ~Regular pay all tax credits IR  ~Annual ~1  ~fam_return_dtls        ~wff_frd_fam_paid_amt             ~
  fdrtpi ~2 ~Transfer ~Tax credit   ~Regular pay all tax credits IR  ~Month ~1   ~fam_daily_rate         ~wff_frd_total_payment_amt        ~Scaled to IR pay annual amount (frdtir)
  frdtpd ~1 ~Transfer ~Tax credit   ~Regular pay all tax credits total ~Annual ~-1 ~fam_return_dtls      ~wff_frd_tl_payment_amt            ~wff_frd_fam_paid_amt + wff_frd_winz_paid_amt
  dertpr ~1 ~Transfer ~Tax credit   ~Regular pay all tax credits total ~Month ~1 ~derived                ~derived                          ~sum of IR and MSD regular pay (fdrtpi + emstpm) scaled to annual amount (frdtpd)
  frdfdr ~1 ~Transfer ~Tax credit   ~Final payment all tax credits   ~Annual ~-1 ~fam_return_dtls        ~wff_frd_final_dr_cr_amt          ~Negative value is an overpayment
  frdcsr ~1 ~Transfer ~Child support ~Child support received         ~Annual ~1  ~fam_return_dtls        ~wff_frd_child_support_rec_amt    ~
  frdcsp ~1 ~Transfer ~Child support ~Child support paid             ~Annual ~1  ~fam_return_dtls        ~wff_frd_child_support_paid_amt   ~
  emsstu ~2 ~Transfer ~Study        ~Student allowance payments      ~Month  ~1  ~ird_ems                ~ir_ems_income_source_code        ~Scaled to PTS/IR3 if possible
  sbasap ~2 ~Transfer ~Study        ~Student allowance payments      ~Annual ~1  ~msd_borrowing          ~msd_sla_ann_allowance_paid_amt    ~
  sbasar ~2 ~Transfer ~Study        ~Student allowance repayment     ~Annual ~1  ~msd_borrowing          ~msd_sla_ann_allowance_repaid_amt  ~
  sbaabp ~2 ~Transfer ~Study        ~A bursary payment               ~Annual ~1  ~msd_borrowing          ~msd_sla_a_bursary_amt             ~
  sbaabr ~2 ~Transfer ~Study        ~A bursary repaid                ~Annual ~1  ~msd_borrowing          ~msd_sla_a_bursary_repaid_amt      ~
  sbabbp ~2 ~Transfer ~Study        ~B bursary payment               ~Annual ~1  ~msd_borrowing          ~msd_sla_b_bursary_amt             ~
  sbabbr ~2 ~Transfer ~Study        ~B bursary repaid                ~Annual ~1  ~msd_borrowing          ~msd_sla_b_bursary_repaid_amt      ~
  sbatsp ~2 ~Transfer ~Study        ~Top scholar payment             ~Annual ~1  ~msd_borrowing          ~msd_sla_top_scholar_paid_amt      ~
  sbatsr ~2 ~Transfer ~Study        ~Top scholar repaid              ~Annual ~1  ~msd_borrowing          ~msd_sla_top_scholar_repaid_amt    ~
  sbapmp ~2 ~Transfer ~Study        ~Bonded merit payment            ~Annual ~1  ~msd_borrowing          ~msd_sla_bonded_merit_paid_amt     ~
  sbapmr ~2 ~Transfer ~Study        ~Bonded merit repaid             ~Annual ~1  ~msd_borrowing          ~msd_sla_bonded_merit_repaid_amt   ~
  sbasup ~2 ~Transfer ~Study        ~Step up payment                 ~Annual ~1  ~msd_borrowing          ~msd_sla_step_up_paid_amt          ~
  sbasur ~2 ~Transfer ~Study        ~Step up repaid                  ~Annual ~1  ~msd_borrowing          ~msd_sla_step_up_repaid_amt        ~
  sbatzp ~2 ~Transfer ~Study        ~TeachNZ payment                 ~Annual ~1  ~msd_borrowing          ~msd_sla_teachnz_paid_amt          ~
  sbatzr ~2 ~Transfer ~Study        ~TeachNZ repaid                  ~Annual ~1  ~msd_borrowing          ~msd_sla_teachnz_repaid_amt        ~
  dersat ~1 ~Transfer ~Study        ~Study assistance total          ~Mixed ~1   ~derived                ~derived                           ~Sum of all transfers for study assistance
  ttltot ~1 ~Loan     ~Hardship     ~Hardship loan total             ~Month  ~1  ~msd_third_tier_expenditure ~msd_tte_pmt_amt              ~where msd_tte_recoverable_ind = "Y"
  ir3sll ~1 ~Loan     ~Study        ~Student loan liable income      ~Annual ~1  ~ird_rtns_keypoints_ir3 ~ir_ir3_sl_liable_income_amt      ~
  ptssll ~1 ~Loan     ~Study        ~Student loan liable income      ~Annual ~1  ~ird_pts                ~ir_pts_sl_liable_amt             ~
  iltdfe ~2 ~Loan     ~Study        ~Loan drawdown course fee        ~Annual ~-1 ~ird_loan_transfer      ~ir_trn_fees_lending_amt          ~
  iltdfr ~2 ~Loan     ~Study        ~Loan drawdown course fee refund ~Annual ~-1 ~ird_loan_transfer      ~ir_trn_fees_lending_refunded_amt ~
  iltcrf ~2 ~Loan     ~Study        ~Loan drawdown course related costs ~Annual ~-1 ~ird_loan_transfer   ~ir_trn_course_related_costs_amt  ~
  iltcrf ~2 ~Loan     ~Study        ~Loan drawdown course related costs recovery ~Annual ~-1 ~ird_loan_transfer ~ir_trn_course_related_costs_reve ~
  iltllc ~2 ~Loan     ~Study        ~Loan drawdown living costs       ~Annual ~-1 ~ird_loan_transfer     ~ir_trn_living_cost_amt            ~
  iltlcr ~2 ~Loan     ~Study        ~Loan drawdown living costs reversal ~Annual ~-1 ~ird_loan_transfer  ~ir_trn_living_costs_reversal_amt ~
  iltlcp ~2 ~Loan     ~Study        ~Loan drawdown living costs recovered ~Annual ~-1 ~ird_loan_transfer ~ir_trn_living_costs_recovered_am ~
  iltmis ~2 ~Loan     ~Study        ~Loan drawdown miscellaneous      ~Annual ~-1 ~ird_loan_transfer     ~ir_trn_loans_lending_misc_amt     ~
  trnltr ~2 ~Loan     ~Study        ~Loan drawdown balance transferred to IR ~Month  ~-1 ~ird_amt_by_trn_type ~ir_att_trn_type_amt           ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  ilttld ~2 ~Loan     ~Study        ~Loan drawdown balance transferred to IR ~Annual ~-1 ~ird_loan_transfer ~ir_trn_ann_principal_amt        ~
  trnfee ~2 ~Loan     ~Study        ~Loan drawdown establishment fee  ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  iltles ~2 ~Loan     ~Study        ~Loan drawdown establishment fee  ~Annual ~-1 ~ird_loan_transfer      ~ir_trn_establishment_fee_amt     ~
  iltlaf ~2 ~Loan     ~Study        ~Loan drawdown administration fee ~Annual ~-1 ~ird_loan_transfer      ~ir_trn_admin_fee_amt             ~
  trnadf ~2 ~Loan     ~Study        ~Loan drawdown administration fee ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  dersld ~1 ~Loan     ~Study        ~Loan drawdown total              ~Mixed ~-1  ~derived                ~derived                           ~Sum of all loan drawdowns
  iltint ~2 ~Loan     ~Study        ~Loan interest transferred to IR   ~Annual ~-1 ~ird_loan_transfer      ~ir_trn_ann_interest_transferred_ ~
  trnint ~2 ~Loan     ~Study        ~Loan interest charged            ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  trnliw ~2 ~Loan     ~Study        ~Loan interest written-off        ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  trnlwo ~2 ~Loan     ~Study        ~Loan principal written-off       ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  trnpna ~2 ~Loan     ~Study        ~Loan penalties added             ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  trnpnr ~2 ~Loan     ~Study        ~Loan penalties reversed          ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type  
  dersli ~1 ~Loan     ~Study        ~Loan interest penalties and write offs total ~Mixed ~-1 ~derived     ~derived                          ~Sum of all loan interest penalities and write offs
  emsslp ~2 ~Loan     ~Study        ~Loan repayments to IR            ~Month  ~1  ~ird_ems                ~ir_ems_sl_amt                    ~no payments recorded after April 2001
  trnrpy ~2 ~Loan     ~Study        ~Loan repayments to IR            ~Month  ~-1 ~ird_amt_by_trn_type    ~ir_att_trn_type_amt              ~by ir_att_trn_type_code, most recent months are in clean_read_SLA.sla_ird_amt_by_trn_type
  sbalrm ~2 ~Loan     ~Study        ~Loan repayments to MSD           ~Annual ~-1 ~msd_borrowing          ~msd_sla_ann_repayment_amt        ~
  derslr ~1 ~Loan     ~Study        ~Loan repayments total            ~Mixed  ~-1 ~derived                ~derived                          ~Sum of all loan repayments
  ;
  run ;

* 2.0 Extract benefit serv codes from meta tables *;
 %Subset_IDIdataset2(SIDId_database = IDI_Metadata
                    ,SIDId_IDIschema = clean_read_CLASSIFICATIONS
                    ,SIDId_IDIdataset = msd_benefit_type_code
                    ,SIDId_outfile = msd_benefit_type_code
                   );

 DATA ISE_IncomeDeductionCodes ;
  SET msd_benefit_type_code (WHERE = (code ne .) ) ;
  LENGTH InCDudCode $6. LevelN 8. Level1 $10. Level2 $15. Level3 $60. Period $6. PersonView 8.  IDI_tble $32. IDI_var $32. Notes $100.;
  LENGTH CodeTxt $3. ;
  CodeTxt = code ;
  IF LENGTH(STRIP(CodeTxt) ) = 2 THEN CodeTxt = CATT('0',code) ;

  Period = 'Month' ;
  PersonView = 1 ;
  Level1 = 'Transfer' ;
  LevelN = 2 ;

  * Classify serv codes on main benefit, Supplimentary and hardship *;
  IF CodeTxt IN ('020'  ,'030' ,'050'  ,'115'  ,'125' ,'313'  ,'320','330' ,'350'  ,'365' ,'366'
                ,'367','370' ,'600' ,'601','602'  ,'603','607','608'  ,'610'  ,'611' ,'613'  ,'665'  ,'666'  ,'675','839' 
                ) THEN DO ; * Main benefits *;
    InCDudCode = CATT('fte',CodeTxt) ;
    Level2 = 'Main benefit';
    Level3 = STRIP(classification) ; 
    IDI_tble = 'msd_first_tier_expenditure';
    IDI_var = 'fte_daily_gross_amt';
    Notes = 'fte_daily_gross_amt by fte_serv_code' ;
    OUTPUT ;
  END ;
  IF CodeTxt IN ('180', '181' ,'209') THEN DO ; * Pensions *;
    InCDudCode = CATT('fte',CodeTxt) ;
    Level2 = 'Pension';
    Level3 = STRIP(classification) ; 
    IDI_tble = 'msd_first_tier_expenditure';
    IDI_var = 'fte_daily_gross_amt';
    Notes = 'fte_daily_gross_amt by fte_serv_code' ;
    OUTPUT ;
  END ;
  IF CodeTxt IN ('040' ,'044'  ,'064' ,'065','202' ,'209','271' ,'340' ,'344' ,'425','450'  ,'460' ,'461'
                ,'470','471' ,'472' ,'473' ,'474'  ,'475'  ,'500','596'  ,'620','655','710' ,'830' ,'831' 
                ,'832','833' ,'834' ,'835' ,'836','837'  ,'838'  ,'843'                   
                ) THEN DO ; * Supplementary benefits *;
    InCDudCode = CATT('ste',CodeTxt) ;
    Level2 = 'Supplementary';
    Level3 = STRIP(classification) ; 
    IDI_tble = 'msd_second_tier_expenditure';
    IDI_var = 'msd_ste_daily_gross_amt';
    Notes = 'msd_ste_daily_gross_amt by msd_ste_supp_serv_code' ;
    * handel tax credits  *;
    IF InCDudCode IN ('ste064') THEN DO ;
      Level2 = 'Tax credit';
      Level3 = 'Family tax credit regular pay MSD' ;
    END ;
    OUTPUT ;
  END ;
  IF CodeTxt IN ('190' ,'191','192'  ,'193'  ,'250'  ,'255'  ,'260'  ,'263'  ,'270' ,'271'  ,'272'  ,'440'  
                ,'460'  ,'610'  ,'620' ,'622'  ,'626'  ,'630' ,'652'  ,'653'  ,'654'  ,'655' ,'700','710'  
                ,'720'  ,'730'  ,'740'  ,'750' ,'760'  ,'820' ,'831'  ,'834'  ,'840','842','850'  ) THEN DO ; * Ad hoc *;
    InCDudCode = CATT('tte',CodeTxt) ;
    Level2 = 'Hardship' ;
    Level3 =STRIP(classification) ; 
    IDI_tble = 'msd_third_tier_expenditure';
    IDI_var = 'msd_tte_pmt_amt';
    Notes = 'msd_tte_pmt_amt by msd_tte_lump_sum_svc_code where msd_tte_recoverable_ind <> Y' ;
    OUTPUT ;
    InCDudCode = CATT('ttl',CodeTxt) ;
    Level1 = 'Loan' ;
    Level3 = STRIP(classification) ; 
    Notes = 'msd_tte_pmt_amt by msd_tte_lump_sum_svc_code where msd_tte_recoverable_ind = Y' ;
    OUTPUT ;
  END ;
  DROP CodeTxt Code classification;
 run ;

 ** add income support payment codes to main code table *;
 PROC APPEND BASE = IncomeDeductionCodes DATA = ISE_IncomeDeductionCodes ; run ;

 ** EMS table income source codes *;
 DATA EMS_provenance_codes ;
   INFILE DATALINES DELIMITER = "~" ;
   LENGTH ir_prv_cd $8. ir_ems_income_source_code $3.  ;
   INPUT  ir_prv_cd     ir_ems_income_source_code      ;
   LABEL ir_prv_cd = "Reference code"
         ir_ems_income_source_code = "EMS income source code"     
         ;
   DATALINES ;
  acp ~CLM
  pen ~PEN  
  ppl ~PPL 
  stu ~STU  
  was ~W&S
  whp ~WHP
  ben ~BEN 
;
run ;


******************************************************************************;
        ** Main Macro Code *;

%MACRO indv_money_inout_macro( IMMIO_infile =
                           ,IMMIO_IDIexDt =
                           ,IMMIO_RptSD =
                           ,IMMIO_RptED =
                           ,IMMIO_Outfile =
                           ,IMMIO_IncomeDetail = 2
                           ,IMMIO_LoanDetail = 2
                           ,IMMIO_TaxDetail = 2
                           ,IMMIO_TransferDetail = 2
                           ,IMMIO_annual = IncomeOutgoingsAnnual
                           ,IMMIO_InCDudCode = IncomeOutgoingsCodeLookup
                           ,IMMIO_SandPitSchema = DL-MAA2014-11
                           ) ;

 %PUT Macro start: indv_money_inout_macro ;
  *
  IMMIO_infile: infile containing the snz_uids to extract (if blank extracts the whole population WARNING this will crash the session)
  IMMIO_IDIexDt: <no longer used> IDI extract date (ie 20160224)
  IMMIO_RptSD / IMMIO_RptED: expressed as ddMMMyyyy (eg 01Jan2015) limits the monthly expenditure to within the specificed 
                             date range. If left null the macro will extract the full range of values. 
  IMMIO_Outfile: outfile name for the dataset containing all sources of income 
               and tax and student loan deductions.
  IMMIO_IncomeDetail: detailed information on income 0 returns no records 1 summary and 2 all income records
  IMMIO_LoanDetail: detailed information on loans 0 returns no records 1 summary and 2 all loans records
  IMMIO_TaxDetail: detailed information on tax 0 returns no records 1 summary and 2 all tax records 
  IMMIO_TransferDetail: detailed information on transfer payments 0 returns no records 1 summary and 2 all transfer payments records
  IMMIO_annual: summary table of requested income and outgoings by tax year to check amounts across data sources
  IMMIO_InCDudCode: reference table of InCDudCode metadata for requested income and outgoings records.
  IMMIO_SandPitSchema: for the Subset_IDIdataset2 macro need to give a write to location on the SQL server usually the project folder (eg DL-MAA2014-11) 
  *;
 
 /*  testing 
 %Subset_IDIdataset2(SIDId_IDIschema = ir_clean
                    ,SIDId_IDIdataset = ird_customers
                    ,SIDId_outfile = customers
                   );
  
 %LET ByVars = snz_uid ;
 PROC SORT DATA= customers (WHERE = (ir_cus_birth_year_nbr lt 2000) ) 
  OUT = test (KEEP = snz_uid) NODUPKEY ; BY &ByVars. ; run ; 

  DATA EES_ids ;
   SET test ;
   select = UNIFORM(0) ;
   IF select lt 0.03 THEN OUTPUT ;
  run ;
  PROC PRINT DATA = &syslast. (obs=20) ; run ;

 proc sql;
 	connect to odbc (dsn=idi_clean_archive_srvprd);
	create table work.tmp_records_toupdate2 as select * from connection to odbc(
 		select snz_uid from IDI_Sandpit.[DL-MAA2016-15].of_gss_ind_variables 
 		where gss_id_collection_code = 'GSS2014' and snz_spine_ind = 1);
	disconnect from odbc;
 quit;

  %LET IMMIO_infile = tmp_records_toupdate2 ;
  %LET IMMIO_IDIexDt =  20180420;
  %LET IMMIO_RptSD =  01Jan2006;
  %LET IMMIO_RptED =  31Dec2016;
  %LET IMMIO_Outfile = tmp_income;
  %LET IMMIO_IncomeDetail = 2 ;
  %LET IMMIO_LoanDetail = 2 ;
  %LET IMMIO_TaxDetail = 2 ;
  %LET IMMIO_TransferDetail = 2 ;
  %LET IMMIO_annual = IncomeOutgoingsAnnual ;
  %LET IMMIO_InCDudCode = IncomeOutgoingsCodeLookup ;
  %LET IMMIO_SandPitSchema = DL-MAA2016-15 ;

 */

 ******************************************************************************
   Issue log (if you can shed light on these let me know)

  ACC deductions (included in the net income ductions? Not clear from documentation)
  Familty Tax Credit: both the IRD and MSD data cover people on main benefit recieving
                      FTC (not clear if IRD supplys FTC data amounts not paid through MSD)
  Family Support payments: IR TFC dataset has family support payments but are these only for people also recieving FTC (likely case)
  Tax Credits paid by IR: monthly IR payment data starts from 2005. The EMS table shows tax credits paid by MSD since 1999.
                  Does this means that IR paid no text credits before 2005 OR IR payment rate data is avalaible from 2005 onwards only.
                  Assuming the latter is the case.
  EMS student loand deductions: these appear to stop after April 2001, but the EMS still records these does anyone know why this field is null
            after this date?

 ******************************************************************************
   Main code assumptions

  When scaling EMS to IR3/PTS we do not have annual tax paid data. Currently scaling EMS tax by the same factor as gross income

 ******************************************************************************
  Code outline

  Dependencies

  Utility macros
    Subset_IDIdataset2
    FrmtDataTight     
    HashTblFullJoin
 
  Need access to: 
      clean_read_classifications.msd_benefit_type_code
                 
      ir_clean.ird_rtns_keypoints_ir3
      ir_clean.ird_pts
      ir_clean.ird_ems
      ir_clean.ird_customers

      wff_clean.fam_return_dtls
      wff_clean.fam_daily_rate

      msd_clean.msd_second_tier_expenditure
      msd_clean.msd_third_tier_expenditure

      sla_clean.msd_borrowing
      sla_clean.ird_loan_transfer
      sla_clean.ird_amt_by_trn_type
      clean_read_sla.sla_amt_by_trn_type

  Code structure
  Stage 1: Extract IR IR3 PTS FTC annual 
  Stage 2: Extract EMS tables and scale values to match annual IR3/PTS   
  Stage 3: Tax Credit daily IR payment rate data, convert to monthly values and scale to annual FTC return total
  Stage 4: Extract non taxable income support assistance
  Stage 5: Extract Student scholarships, Student Loan drawdonw interest and penalties and repayments  
  Stage 6: Combine income and deductions datasets 

 ******************************************************************************;
   * Parameters *;

 * big tables compress to save disk space *;
  OPTIONS COMPRESS = yes ;

 ** Output variables and their formats *;
 %LET IMMIOvars = snz_uid
                  StartDate
                  EndDate
                  Level1
                  Level2
                  Level3
                  Amount 
                  InCDudCode
                  ;

 %LET IMMIOfmts = %STR(LENGTH snz_uid 8.
                              StartDate EndDate 8.
                              Level1 $10. Level2 $15. 
                              Level3 $60. 
                              Amount 8.
                              InCDudCode $6. 
                              ;
                        FORMAT StartDate EndDate ddmmyy10.
                              ;
                       ) ;

 ** Check whether a date range is specified *;
 DATA IMMIO_temp1 ;
  temp1 = LENGTHN(STRIP("&IMMIO_RptSD.")) ;
  IF temp1 = 0 THEN DO ;
    CALL SYMPUTX("IMMIO_RptSD", PUT("01Jan1990"d, date9.) );
    CALL SYMPUTX("IMMIO_RptED", PUT("01Jan2100"d, date9.) );
    CALL SYMPUTX("IMMIO_RptSYr", 1990 );
    CALL SYMPUTX("IMMIO_RptEYr", 2100 );
  END ;
  ELSE DO ;
    CALL SYMPUTX("IMMIO_RptSYr", YEAR("&IMMIO_RptSD."d) );
    CALL SYMPUTX("IMMIO_RptEYr", YEAR("&IMMIO_RptED."d) );
  END ;
 run ;

 %PUT Extract period from &IMMIO_RptSD. to &IMMIO_RptED. ;
 %PUT Extract period year from &IMMIO_RptSYr. to &IMMIO_RptEYr. ;

 ** identify which tax years are needed **;
 DATA TxYearRange ;

  FORMAT RepStart RepEnd  ddmmyy10. ;
  RepStart = "&IMMIO_RptSD."d ;
  RepEnd = "&IMMIO_RptED."d ;

  IF MDY(1,1,YEAR(RepStart)) le RepStart le MDY(3,31,YEAR(RepStart)) THEN FirstTaxYear = YEAR(RepStart) ;
  ELSE FirstTaxYear = YEAR(RepStart)+1 ;
  IF MDY(1,1,YEAR(RepEnd)) le RepEnd le MDY(3,31,YEAR(RepEnd)) THEN LastTaxYear = YEAR(RepEnd) ;
  ELSE LastTaxYear = YEAR(RepEnd)+1 ;
 
  n = 0 ;
  DO TaxYear_i = FirstTaxYear TO LastTaxYear ;
    n = n + 1 ;
    TaxYear = CATT(TaxYear_i,"-03-31") ;
    CALL SYMPUTX(CATT('TaxYear',n),TaxYear) ; 
    OUTPUT ;
  END ; DROP TaxYear_i ;
  CALL SYMPUTX('N_taxYears', n);
 run ;

 %PUT N tax years: &N_taxYears. ;
 %PUT first and last tax years: &TaxYear1. to &&TaxYear&N_taxYears. ;

 %MACRO TaxYearList ;
   %DO tyi = 1 %TO &N_taxYears. ;
      "&&TaxYear&tyi."
  %END ;
 %MEND ;

%MACRO CheckIDIdate ;
 * if IDI date parameter was not specified, set this to current date *;
%LET datespecified = %SYMEXIST(IDIdate);

%IF &datespecified. = 0 %THEN %DO;
DATA _NULL_;
CALL SYMPUTX("IDIdate",PUT(TODAY(),date9.));
RUN;
%END;
%MEND ; %CheckIDIdate ;

******************************************************************************;
   * Sub macros *;

  %MACRO IDICharDates( IDIinvar=
                       ,IDIoutvar=
                       ,IDIDateFrm=  
                      );

  LENGTH &IDIoutvar 8. ;
  FORMAT &IDIoutvar ddmmyy10. ;
  LENGTH IDIDFyear
         IDIDFmonth
         IDIDFday 8. ; 

  IF UPCASE("&IDIDateFrm") = "YYYY-MM-DD" THEN DO ;
    IDIDFyear = SUBSTR(&IDIinvar,1,4) ; 
    IDIDFmonth = SUBSTR(&IDIinvar,6,2) ; 
    IDIDFday = SUBSTR(&IDIinvar,9,2) ; 
    &IDIoutvar = MDY(IDIDFmonth,IDIDFday,IDIDFyear ) ;
  END ;
  IF LOWCASE("&IDIDateFrm") = "yyyymmdd" THEN DO ;
    IDIDFyear = SUBSTR(&IDIinvar,1,4) ; 
    IDIDFmonth = SUBSTR(&IDIinvar,5,2) ; 
    IDIDFday = SUBSTR(&IDIinvar,7,2) ; 
    &IDIoutvar = MDY(IDIDFmonth,IDIDFday,IDIDFyear ) ;
  END ;
  IF UPCASE("&IDIDateFrm") = "DD/MM/YYYY" THEN DO ;
    IDIDFyear = SUBSTR(&IDIinvar,7,4) ; 
    IDIDFmonth = SUBSTR(&IDIinvar,4,2) ; 
    IDIDFday = SUBSTR(&IDIinvar,1,2) ; 
    &IDIoutvar = MDY(IDIDFmonth,IDIDFday,IDIDFyear ) ;
  END ;

  DROP &IDIinvar IDIDFyear IDIDFmonth IDIDFday;
 %MEND ;

  ** read through dataset and output values of inetrest *;
  %MACRO ThinFileConvert ;
  %DO tfc_i = 1 %TO &irait_N. ;
  IF &&irait_var_&tfc_i. NOT IN (.,0) THEN DO ;
    amount = &&irait_var_&tfc_i. * &&irait_pv_&tfc_i. ;
    InCDudCode = "&&irait_cd_&tfc_i." ;
    Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
    Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
    Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
    OUTPUT ;
  END ;
  %END ;
 %MEND ;

******************************************************************************;
   * Formats *;

 %FrmtDataTight(FCMinfile = IncomeDeductionCodes
              ,FCMFmtNm = $Income_1_lvl
              ,FCMStart = InCDudCode
              ,FCMLabel = Level1
              ) ;

 %FrmtDataTight(FCMinfile = IncomeDeductionCodes
              ,FCMFmtNm = $Income_2_lvl
              ,FCMStart = InCDudCode
              ,FCMLabel = Level2
              ) ;

 %FrmtDataTight(FCMinfile = IncomeDeductionCodes
               ,FCMFmtNm = $Income_3_lvl
               ,FCMStart = InCDudCode
               ,FCMLabel = Level3
               ) ;

  %FrmtDataTight(FCMinfile = IncomeDeductionCodes
               ,FCMFmtNm = $Income_period
               ,FCMStart = InCDudCode
               ,FCMLabel = Period
               ) ;

 %FrmtDataTight(FCMinfile = IncomeDeductionCodes
              ,FCMFmtNm = $LevelN
              ,FCMStart = InCDudCode
              ,FCMLabel = LevelN
              ) ;

*****************************************************************;
  * Stage 1: annual IR tax and wff (tax credit) data *;

** 1.0 Subset SNZ income IR ird_rtns_keypoints_ir3 *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema = ir_clean
                    ,SIDId_IDIdataset = ird_rtns_keypoints_ir3
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = ir_keypoints_ir3_1
                   );

** 1.1 Convert to thin file for processing **;

*1.1.1 Identify variables of interest *;
DATA ir3_keypoint_vars1 ;
 SET IncomeDeductionCodes (WHERE = (IDI_tble = 'ird_rtns_keypoints_ir3') ) ;
 CALL SYMPUTX(CATT('irait_var_',_N_), IDI_var) ;
 CALL SYMPUTX(CATT('irait_cd_',_N_), InCDudCode ) ;
 CALL SYMPUTX(CATT('irait_pv_',_N_), PersonView) ;
 CALL SYMPUTX('irait_N', _N_) ;
run ;

* 1.1.2 extract only relevent values from ir_keypoints_ir3 *;
 %LET ByVars = snz_uid ir_ir3_return_period_date ir_ir3_ird_timestamp_date ir_ir3_snz_unique_nbr ;
 PROC SORT DATA= ir_keypoints_ir3_1 ; BY &ByVars. ; run ; 

DATA ir_keypoints_ir3_2 (KEEP = &IMMIOvars. TaxYear );
 &IMMIOfmts. ; 
 SET ir_keypoints_ir3_1 (WHERE = (snz_uid ne .) ) ;
  BY &ByVars.;

 * Format taxyear and StartDate *;
 LENGTH TaxYear $10. ;
 TaxYear = ir_ir3_return_period_date ;
 %IDICharDates( IDIinvar = ir_ir3_return_period_date
               ,IDIoutvar = EndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
 StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;

 * remove any records outside of date range *;
 IF TaxYear NOT IN (%TaxYearList) THEN DELETE ;

 * Tax credit total entitlement *;
 ir_ir3_tax_crdt_total_entl_amt = SUM(ir_ir3_child_tax_crdt_entl_amt  
                                     ,ir_ir3_fam_sup_tax_crdt_entl_amt
                                     ,ir_ir3_family_tax_crdt_entl_amt 
                                     ,ir_ir3_in_work_payment_entl_amt 
                                     ,ir_ir3_parent_tax_crdt_entl_amt ) ;
 IF last.ir_ir3_return_period_date THEN DO ;
   * read through variables and output non null and zero values only *;
   %ThinFileConvert ;
 END ;
run ;

** 1.2.0 IR Personal Tax Summary table *;

** 1.0 Subset SNZ income IR ird_rtns_keypoints_ir3 *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema = ir_clean
                    ,SIDId_IDIdataset = ird_pts
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = ir_pts1
                   );

** 1.2.1 Convert to thin file for processing **;

* 1.2.1 Identify variables of interest *;
DATA ir_pts_vars1 ;
 SET IncomeDeductionCodes (WHERE = (IDI_tble = 'ird_pts') ) ;
 CALL SYMPUTX(CATT('irait_var_',_N_), IDI_var) ;
 CALL SYMPUTX(CATT('irait_cd_',_N_), InCDudCode ) ;
 CALL SYMPUTX(CATT('irait_pv_',_N_), PersonView) ;
 CALL SYMPUTX('irait_N', _N_) ;
run ;

* 1.2.2 extract only relevent values from ir_pts *;
%LET ByVars = snz_uid ir_pts_return_period_date ir_pts_timestamp_date;
PROC SORT DATA= ir_pts1 ; BY &ByVars. ; run ; 

DATA ir_pts2 (KEEP = &IMMIOvars. TaxYear );
 &IMMIOfmts. ; 
 SET ir_pts1 (WHERE = (snz_uid ne .) ) ;
  BY &ByVars.;

 * Format taxyear and StartDate *;
 LENGTH TaxYear $10. ;
 TaxYear = ir_pts_return_period_date ;
 %IDICharDates( IDIinvar = ir_pts_return_period_date
               ,IDIoutvar = EndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
 StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;

 * remove any records outside of date range *;
 IF TaxYear NOT IN (%TaxYearList) THEN DELETE ;

 * Value should be negative I think *;
 ir_pts_ind_ern_tax_crdt_entl_amt = ir_pts_ind_ern_tax_crdt_entl_amt * -1 ;
 * in the instances examined these two values are the same is ind_ern_tax_crdt a rebate? 
  ir_pts_tot_rebates_amt = ir_pts_ind_ern_tax_crdt_entl_amt
 *;

 * Total tax credit entilement *;
 ir_pts_tax_crdt_total_entl_amt = SUM( ir_pts_parent_tax_crdt_entl_amt
                                      ,ir_pts_child_tax_crdt_entl_amt
                                      ,ir_pts_fam_sup_tax_crdt_entl_amt
                                      ,ir_pts_family_tax_crdt_entl_amt
                                      ,ir_pts_in_work_payment_entl_amt
                                      ,ir_pts_ind_ern_tax_crdt_entl_amt) ;

 * if more than one PTS select the latest timestamp record *;
 IF last.ir_pts_return_period_date THEN DO ;
   * read through variables and output non null and zero values only *;
   %ThinFileConvert ;
 END ;
run ;

* 1.3 Merge PTS and IR3 records *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_keypoints_ir3_2 ; BY &ByVars. ; run ; 
 PROC SORT DATA= ir_pts2 ; BY &ByVars. ; run ; 

 DATA ir_ir3_pts1 (SORTEDBY = &ByVars.
                   COMPRESS = yes);
  &IMMIOfmts. ; 
  MERGE ir_keypoints_ir3_2 (IN=A 
                RENAME = (Amount = IR3_Amount
                          InCDudCode = IR3_InCDudCode) 
                ) 
       ir_pts2 (IN=B 
                RENAME = (Amount = PTS_Amount
                          InCDudCode = PTS_InCDudCode) 
                ) ;
  BY &ByVars.;
  IF A OR B ;

  LABEL snz_uid = "SNZ unique person id"
        TaxYear = "Tax year end date"
        StartDate = "Period start date"
        EndDate = "Period end date"
        Level1 = "Income deduction type level 1"
        Level2 = "Income deduction type level 2"
        Level3 = "Income deduction type level 3"
        InCDudCode = "Income deducation code"
        Amount = "Income positive deduction negtaive"
        IR3_Amount = "Amount from ird_clean.ird_rtns_keypoints_ir3" 
        PTS_Amount = "Amount from ird_clean.ird_pts"
        ;

  ** If IR3 amount is missing then use PTS *;
  Amount = COALESCE(IR3_Amount, PTS_Amount) ;
  InCDudCode = COALESCEC(IR3_InCDudCode, PTS_InCDudCode) ;
  DROP IR3_InCDudCode PTS_InCDudCode ;
run ;

 *1.4 Tax credit child support (not sure if child support is comprehensive or just covers people with FTC) *;
  * Note these are for the primary care giver *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema = wff_clean
                    ,SIDId_IDIdataset = fam_return_dtls
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = wff_taxreturn1
                   );

* 1.4.1 Identify variables of interest *;
DATA ir_wff_vars1 ;
 SET IncomeDeductionCodes (WHERE = (IDI_tble = 'fam_return_dtls' ) ) ;

 CALL SYMPUTX(CATT('irait_var_',_N_), IDI_var) ;
 CALL SYMPUTX(CATT('irait_cd_',_N_), InCDudCode) ;
 CALL SYMPUTX(CATT('irait_pv_',_N_), PersonView) ;
 CALL SYMPUTX('irait_N', _N_) ;
run ;

* 1.4.2 Convert to thin file and keep tax year and partner uid *;
DATA wff_taxreturn2 (KEEP = &IMMIOvars. TaxYear partner_snz_uid );
  &IMMIOfmts. ;
 SET wff_taxreturn1 (WHERE = (snz_uid ne .) )   ;

 * Format taxyear and StartDate *;
 LENGTH TaxYear $10. ;
 TaxYear = wff_frd_return_period_date ;
 %IDICharDates( IDIinvar = wff_frd_return_period_date
               ,IDIoutvar = EndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
 StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;

 IF partner_snz_uid = .... THEN partner_snz_uid = . ; 
 * this id matches ..... people in 2006-03-31 similar for other tax years assume this indicates a sole parent *;
 * it looks like that the information is not recorded twice for the partner in the same tax year. But there are 
   duplicate tax year spells for an snz_uid with different partners or becoming single *;

 * total tax credit entitlement amount *;
 wff_frd_total_entilement_amt = SUM(wff_frd_ctc_entitlement_amt                                               
                                    ,wff_frd_fstc_entitlement_amt                                              
                                    ,wff_frd_ftc_entitlement_amt                                               
                                    ,wff_frd_iwp_entitlement_amt                                               
                                    ,wff_frd_ptc_entitlement_amt     
                                    );
 * total amount of payments *;
/* Vinay : potential error in the code as nulls will be missed out from the output. why is sum function not used?*/
/* wff_frd_tl_payment_amt = -1*wff_frd_fam_paid_amt + wff_frd_winz_paid_amt ;*/
wff_frd_tl_payment_amt = sum(-1*wff_frd_fam_paid_amt , wff_frd_winz_paid_amt) ;

 * read through variables and output non null and non zero values only *;
 %ThinFileConvert ;
run ;

 * 1.4.3 Sum values for each tax year **;
 * There are multi tax year records where individual circumstances changed *;
%LET ClassVars = snz_uid 
                 TaxYear 
                 StartDate 
                 EndDate 
                 Level1 
                 Level2 
                 Level3 
                 InCDudCode;
PROC MEANS DATA = wff_taxreturn2 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_taxreturn3 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = 
    ;
 run ;

 * 1.5 Combine Tax credit annual witn IR3/PTS *;
 %LET ByVars = snz_uid 
              TaxYear 
              Level1 
              Level2 
              Level3  ;
 PROC SORT DATA= ir_ir3_pts1 ; BY &ByVars. ; run ; 
 PROC SORT DATA= wff_taxreturn3 ; BY &ByVars. ; run ; 

 DATA ir_annual_return1 (SORTEDBY = &ByVars. );
  &IMMIOfmts. ; 
  MERGE ir_ir3_pts1 (IN=A) 
        wff_taxreturn3 (IN=B 
                        RENAME = (Amount = FTC_Amount
                                  InCDudCode = FTC_InCDudCode) 
                        ) ;
  BY &ByVars.;
  IF A OR B ;

  LABEL FTC_Amount = "Amount from fam_return_dtls" ;
  ** If IR3/PTS amount is missing then use FTC *;
  Amount = COALESCE(Amount, FTC_Amount) ;
  InCDudCode = COALESCEC(InCDudCode, FTC_InCDudCode) ;
  DROP FTC_InCDudCode ;
run ;

PROC PRINT DATA = &syslast. (obs=20) ; run ;

/* Variance checks *;


 DATA IR3PTSWFF_variance1 ;
  SET ir_annual_return1 ;
 
  IF ir3_amount ne . AND pts_amount ne . THEN ir3_pts_var = ir3_amount - pts_amount ;
  IF ftc_amount ne . AND pts_amount ne . THEN pts_ftc_var = pts_amount - ftc_amount ;
  IF ftc_amount ne . AND ir3_amount ne . THEN ir3_ftc_var = ir3_amount - ftc_amount ;

 run ;
 
%LET ClassVars = Level1 Level2 Level3 TaxYear ;
PROC MEANS DATA = IR3PTSWFF_variance1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = IR3PTSWFF_variance2 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    MEAN(ir3_amount pts_amount ftc_amount 
         ir3_pts_var pts_ftc_var ir3_ftc_var) = 
    ;
 run ;

 DATA IR3PTSWFF_variance2 ;
  SET IR3PTSWFF_variance2 ;
  N_amount = MIN(1,COALESCE(ir3_amount, 0)) 
           + MIN(1,COALESCE(pts_amount, 0)) 
           + MIN(1,COALESCE(ftc_amount, 0))  ;
 run ;

 PROC PRINT DATA = &syslast. (obs=200 WHERE = (N_amount gt 1) ) ; run ;
*/

 * housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
   DELETE ir_ir3_pts1
          wff_taxreturn: 
          ir_pts:
          ir_keypoints_ir3_: 
          ir_pts_vars1 
          ir3_keypoint_vars1  ;
 run ;

*****************************************************************;
  * Stage 2: Employer Monthly Schedual *;

 ** for some people this is the only annual source *;
 
* 2.0 Extract EMS records for population of interest *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema = ir_clean
                    ,SIDId_IDIdataset = ird_ems
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = ir_ems1
                   );

* 2.1 Add tax year and switch to thin file *;
%FrmtDataTight(FCMinfile = EMS_provenance_codes
              ,FCMFmtNm = $ems_type
              ,FCMStart = ir_ems_income_source_code
              ,FCMLabel = ir_prv_cd
              ) ;

*2.2.1 Identify variables of interest *;
DATA ir_ems_vars1 ;
 SET IncomeDeductionCodes (WHERE = (    IDI_tble = 'ird_ems' 
                                    AND STRIP(COMPRESS(IDI_var,' ', 's')) ne 'ir_ems_income_source_code') 
                          ) ;

 CALL SYMPUTX(CATT('irait_var_',_N_), IDI_var) ;
 CALL SYMPUTX(CATT('irait_cd_',_N_), InCDudCode) ;
 CALL SYMPUTX(CATT('irait_pv_',_N_), PersonView) ;
 CALL SYMPUTX('irait_N', _N_) ;
run ;

* 2.2.2 extract only relevent values from ir_ems *;
DATA ir_ems3 (KEEP =  &IMMIOvars. TaxYear);
  &IMMIOfmts. ;
 SET ir_ems1 (WHERE = (snz_uid ne .) )  ;

 %IDICharDates( IDIinvar = ir_ems_return_period_date
               ,IDIoutvar = EndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
 StartDate = INTNX('month',EndDate,0);

 * determine tax year *;
  LENGTH TaxYear $10. ;
  IF MDY(1,1,YEAR(StartDate)) le StartDate le MDY(3,31,YEAR(StartDate)) THEN TaxYear = CATT(YEAR(StartDate),"-03-31") ;
  ELSE TaxYear = CATT(YEAR(StartDate)+1,"-03-31") ;

 * remove any records outside of date range *;
 IF TaxYear NOT IN (%TaxYearList) THEN DELETE ;

  ** code ir_ems_income_source_code items to ir_prv_cd **;
  IF ir_ems_gross_earnings_amt NOT IN (0, .) THEN DO ;
    InCDudCode = CATT('ems',PUT(ir_ems_income_source_code, $ems_type.)) ;
    amount = ir_ems_gross_earnings_amt ;
    Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
    Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
    Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
    OUTPUT ;
    InCDudCode = CATT(SUBSTR(InCDudCode,1,5),"t") ;
    Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
    Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
    Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
    amount = ir_ems_paye_deductions_amt ;
    OUTPUT ;
  END ;

  * split PAYE and WHT *;
  LENGTH ir_ems_withholding_tax_amt 
         ir_ems_wht_earnings_amt 8. ;
  IF ir_ems_withholding_type_code = "W" THEN DO ;
    ir_ems_withholding_tax_amt = ir_ems_paye_deductions_amt ;
    ir_ems_wht_earnings_amt = ir_ems_gross_earnings_amt ;
    ir_ems_paye_deductions_amt = . ;
    ir_ems_gross_earnings_amt = . ;
  END ;

  * output remaining as is *;
  * read through variables and output non null and non zero values only *;
  %ThinFileConvert ;
run ;

* 2.3 Sum any multiple month values *;
%LET ClassVars = snz_uid Startdate Enddate TaxYear Level1 Level2 Level3 InCDudCode;
PROC MEANS DATA = ir_ems3 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = ir_ems3 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = 
    ;
 run ;

* 2.4 Sum values to return period (tax year) *;
%LET ClassVars = snz_uid TaxYear Level1 Level2 Level3 InCDudCode;
PROC MEANS DATA = ir_ems3 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = ir_ems4 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = 
    ;
 run ;

 *2.5 Identify where ems and annual results match *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return1 ; BY &ByVars. ; run ; 
 PROC SORT DATA= ir_ems4 ; BY &ByVars. ; run ; 

 DATA ems_scale1 ;
  &IMMIOfmts. ;
  MERGE ir_annual_return1 (IN=A)
        ir_ems4 (IN=B 
                 RENAME = (amount = ems_amount
                           InCDudCode = ems_InCDudCode
                            )
                 ) ;
  BY &ByVars.;
  IF A AND B ;

  IF amount = . THEN amount = 0 ;
  IF ems_amount = . THEN ems_amount = 0 ;
  ems_variance = amount - ems_amount ; * difference with IR3/PTS *;
  IF     InCDudCode ne ""
     AND ems_InCDudCode ne "" THEN OUTPUT ;
 run ;

 /* Check variance 
 
%LET ClassVars = Level3 TaxYear;
PROC MEANS DATA =ems_scale1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT =ems_var (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    MEAN(amount ems_amount ems_variance ) = 
    ;
 run ;
 ** EMS values are generally a bit higher than what is recorded in IR3/PTS/Tax Credit annual returns **;

 PROC PRINT DATA = &syslast. (obs=200) ; run ;

 */

 *2.3 Scale the EMS records based on the PTS/IR3 *; 

 * 2.3.1 Calculate scaling for EMS records *;
 DATA ems_scale2 (KEEP = snz_uid TaxYear level1 level2 Level3 ems_scale ems_variance);
  SET ems_scale1 ;
  ems_scale = amount / ems_amount ;
  OUTPUT ;
  IF Level3 IN ("Income with PAYE") THEN DO ;
    Level3 = "Paid parental leave" ; OUTPUT ;
    Level3 = "Wages and salaries" ; OUTPUT ;
    Level1 = "Transfers" ;
    Level2 = 'ACC' ;
    Level3 = "ACC income compensation" ; OUTPUT ;
    Level2 = 'Pension' ;
    Level3 = "Superannuation" ; OUTPUT ;
    Level2 = 'Main benefit' ;
    Level3 = "Main benefit" ; OUTPUT ;
    Level2 = 'Study' ;
    Level3 = "Student allowance payments" ; OUTPUT ;
    Level1 = "Tax" ;
    Level2 = 'Tax paid' ;
    Level3 = "PAYE ACC income compensation" ; OUTPUT ;
    Level3 = "PAYE superannuation" ; OUTPUT ;
    Level3 = "PAYE paid parental leave" ; OUTPUT ;
    Level3 = "PAYE student allowance" ; OUTPUT ;
    Level3 = "PAYE wages and salaries" ; OUTPUT ;
    Level3 = "PAYE main benefit" ; OUTPUT ;
    Level3 = "PAYE deductions" ; OUTPUT ;
 END ;

  IF Level3 IN ("Income with WHT") THEN DO ;
     Level3 = "Contract payment" ; OUTPUT ;
     Level1 = "Tax" ;
     Level2 = 'Tax paid' ;
     Level3 = "WHT total" ; OUTPUT ;
     Level3 = "WHT contract payment" ; OUTPUT ;
  END ; 
 run ;
 
  * For monthly EMS values scale to PTS/IRS values (this treats any PTS/IRS3 info as more accurate than EMS) *;
 %LET ByVars = snz_uid TaxYear level1 level2 Level3;
 PROC SORT DATA= ir_ems3 ; BY &ByVars. ; run ; 
 PROC SORT DATA= ems_scale2 ; BY &ByVars. ; run ; 

 DATA ir_ems5 (SORTEDBY = &ByVars.);
  FORMAT &ByVars. ; 
  MERGE ir_ems3 (IN=A)
        ems_scale2 (IN=B) ;
  BY &ByVars.;
  IF A ;

  ems_scale = COALESCE(ems_scale,1) ; 
  amount = amount * ems_scale ;
  DROP ems_scale ;
 run ;

 * 2.4 Create combined annual and monthly payment dataset *;
   * if there is a monthly and annual record then favour monthyl *;
 DATA ems_scale3 (KEEP =snz_uid TaxYear level1 level2 Level3 ems_in) ;
  SET ems_scale1  ;
  ems_in = "Y" ;
 run ;

 DATA IMMIO_IncomeOutgoing1 (KEEP =  &IMMIOvars. TaxYear) ;
  &IMMIOfmts. ;
  SET ir_ems5 (IN=A) 
      ir_annual_return1 (IN=B);

  * scale ems amount to match PTS/IR3 when avalaible *;
  %HashTblFullJoin( RCVtble = ems_scale3
                   ,RCVtblCd = es
                   ,RCVcode = snz_uid TaxYear level1 level2 Level3 
                   ,RCVvars = ems_in
                   ) ; 

  IF B THEN DO ;
   IF ems_in = "Y" THEN DELETE ;
  END ;
 run ;

 * 2.5 Updated annual tax return dataset for cross checking *;
%LET ClassVars = snz_uid TaxYear level1 level2 Level3 InCDudCode;
PROC MEANS DATA = ir_ems5 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = ir_ems6 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = ems_amount 
    ;
 run ;

 *2.2 Identify where ems and annual results match *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return1 ; BY &ByVars. ; run ; 
 PROC SORT DATA= ir_ems6 ; BY &ByVars. ; run ; 

 DATA ir_annual_return2 (SORTEDBY = &ByVars.
                        DROP = ScaledVariance ems_InCDudCode)
      ems_var1 ;
  &IMMIOfmts. ;
  MERGE ir_annual_return1 (IN=A)
        ir_ems6 (IN=B 
                 RENAME = (InCDudCode = ems_InCDudCode )
                 ) ;
  BY &ByVars.;
  IF A OR B ;

  %HashTblFullJoin( RCVtble = ems_scale2
                   ,RCVtblCd = es
                   ,RCVcode = snz_uid TaxYear level1 level2 Level3 
                   ,RCVvars = ems_scale
                   ) ; 
  LABEL ems_amount = "Scaled amount from ird_clean.ird_ems"
        ems_scale = "Amount of scaling from orginal ems value" ;

  IF amount = . THEN amount = 0 ;
  IF ems_amount = . THEN ems_amount = 0 ;
  ScaledVariance = amount - ems_amount ; * difference with IR3/PTS *;
  IF     InCDudCode ne ""
     AND ems_InCDudCode ne "" 
     AND ABS(ScaledVariance) gt 2 THEN OUTPUT ems_var1 ;

  ** if IR3/PTS missing then add in EMS information *;
  IF amount = 0 THEN amount = .;
  IF ems_amount = 0 THEN ems_amount = . ;
  IF ems_scale = 0 THEN  ems_scale = . ;
  Amount = COALESCE(Amount, ems_Amount) ;
  Period = "Annual" ;
  tempTaxYear = TaxYear ;
   %IDICharDates( IDIinvar = tempTaxYear
                 ,IDIoutvar = EndDate
                 ,IDIDateFrm = YYYY-MM-DD ) ;
   StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;
  InCDudCode = COALESCEC(InCDudCode, ems_InCDudCode) ;
  OUTPUT ir_annual_return2 ;
 run ;
 
 * housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
   DELETE ir_ems1-ir_ems6  
          ir_annual_return1 
          ems_scale:
          ;
 run ;

*****************************************************************;
  * Stage 3: FTC IR daily rate data from WFF dataset *;

 * Daily family tax rate spells paid by IR *;

 * 3.0 Identify family tax rate spells **;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema =  wff_clean
                    ,SIDId_IDIdataset = fam_daily_rate
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = wff_fam_daily_rate1
                   );

* 3.1 Format dates *;

DATA wff_fam_daily_rate2  ;
 SET wff_fam_daily_rate1 (WHERE = (snz_uid ne .) ) ;

  FORMAT TAxYearSD ddmmyy10. ;
  TaxYear = wff_fdr_return_period_date ;
  %IDICharDates( IDIinvar = wff_fdr_return_period_date
                 ,IDIoutvar = TaxYearED
                 ,IDIDateFrm = YYYY-MM-DD ) ;
  TaxYearSD = INTNX('year',TaxYearED,-1, 'same') + 1 ;

  %IDICharDates( IDIinvar = wff_fdr_applied_date
               ,IDIoutvar = ApplyDate
               ,IDIDateFrm = YYYY-MM-DD ) ;

  %IDICharDates( IDIinvar = wff_fdr_ceased_date
               ,IDIoutvar = CeasedDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
  IF CeasedDate = . THEN CeasedDate = TaxYearED ;

  %IDICharDates( IDIinvar = wff_fdr_eligible_period_end_date
               ,IDIoutvar = EligibleEndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;

/* Vinay: ptc is being added twice which looks like an error */
/* totalrate = SUM(wff_fdr_daily_ctc_rate_amt, wff_fdr_daily_fstc_rate_amt, */
/*                wff_fdr_daily_ftc_rate_amt, wff_fdr_daily_iwp_rate_amt, wff_fdr_daily_ptc_rate_amt, */
/*                wff_fdr_daily_ptc_rate_amt) ;*/
   totalrate = SUM(wff_fdr_daily_ctc_rate_amt, wff_fdr_daily_fstc_rate_amt, 
    				wff_fdr_daily_ftc_rate_amt, wff_fdr_daily_iwp_rate_amt, wff_fdr_daily_ptc_rate_amt) ;

run ;

 * 3.2 Calculate rate periods *;

 * The rate table appears to be complex to decipher with one set of rules
   as far as I can tell there is no single rule set that will reconcile with 
   all the values to the ftc annual returns form amount paid by IR *;

 * 3.2.1 Identify rate periods with different apply dates within a tax year *;
%LET ClassVars = snz_uid TaxYear ApplyDate ;
PROC MEANS DATA =wff_fam_daily_rate2 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_daily_same_applydate (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    N(snz_uid) = N_recs
    ;
 run ;

%LET ClassVars = snz_uid TaxYear  ;
PROC MEANS DATA =wff_daily_same_applydate NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_daily_same_applydate1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
   MAX(N_recs) = N_recs
    ;
 run ;

 * 3.2.2 Process instances with non mulitple apply dates *;

%LET ByVars = snz_uid TaxYear wff_fdr_list_nbr  EligibleEndDate;
PROC SORT DATA= wff_fam_daily_rate2 ; BY &ByVars.  ; run ; 

 DATA wff_daily_rate_oneapply1 ;
  SET wff_fam_daily_rate2  ;
  BY &ByVars.;

  %HashTblFullJoin( RCVtble = wff_daily_same_applydate1
                   ,RCVtblCd =na
                   ,RCVcode =snz_uid TaxYear
                   ,RCVvars =N_recs
                   ) ;

  IF N_recs gt 1 THEN DELETE ;
  DROP N_recs ;

  FORMAT RateSD RateED ddmmyy10. ; 

  PreEligibleEndDate = LAG1(EligibleEndDate)  ;
  PreCeasedDate = LAG1(CeasedDate)  ;
  IF first.TaxYear THEN RateSD = MAX(ApplyDate, TaxYearSD) ;
  ELSE DO ;
    IF PreCeasedDate lt PreEligibleEndDate THEN RateSD = PreCeasedDate + 1;
    IF RateSD = . THEN RateSD = ApplyDate ;
  END ;
  RateED = EligibleEndDate;
  IF CeasedDate lt EligibleEndDate THEN RateED = CeasedDate;
  Duration = (RateED - RateSD) + 1 ;
  amount = totalrate * Duration ;
 run ;

 * 3.2.2 Process instances with mulitple apply dates *;

%LET ByVars = snz_uid TaxYear wff_fdr_list_nbr wff_snz_unique_nbr EligibleEndDate ;
PROC SORT DATA= wff_fam_daily_rate2 ; BY &ByVars.  ; run ; 

DATA wff_daily_rate_dupapply1 (SORTEDBY = &ByVars.) ;
  SET wff_fam_daily_rate2 ;
  BY &ByVars.;

  %HashTblFullJoin( RCVtble = wff_daily_same_applydate1
                   ,RCVtblCd =na
                   ,RCVcode =snz_uid TaxYear
                   ,RCVvars =N_recs
                   ) ;

  IF N_recs le 1 THEN DELETE ;
  DROP N_recs ;
  FORMAT  RateSD RateED ddmmyy10. ; 
  IF last.wff_fdr_list_nbr THEN OUTPUT ;
 run ;

 %LET ByVars = snz_uid TaxYear wff_fdr_list_nbr wff_snz_unique_nbr EligibleEndDate ;
 PROC SORT DATA= wff_daily_rate_dupapply1 ; BY &ByVars.  ; run ; 

 DATA wff_daily_rate_dupapply2 (SORTEDBY = &ByVars.) ;
  SET wff_daily_rate_dupapply1 ;
  BY &ByVars.;

    FORMAT RateSD RateED ddmmyy10. ; 

    PreEligibleEndDate = LAG1(EligibleEndDate)  ;
    PreCeasedDate = LAG1(CeasedDate)  ;
    IF first.TaxYear THEN RateSD = MAX(ApplyDate, TaxYearSD) ;
    ELSE DO ;
      IF PreCeasedDate lt PreEligibleEndDate THEN RateSD = PreCeasedDate + 1;
      IF RateSD = . THEN RateSD = ApplyDate ;
    END ;
    RateED = EligibleEndDate;
    IF CeasedDate lt EligibleEndDate THEN RateED = CeasedDate;
    Duration = (RateED - RateSD) + 1 ;
    amount = totalrate * Duration ;
 run ;

*3.1.0 Convert IR tax rate to InCDudCode *;
DATA fdr_InCDudCode ;
 SET IncomeDeductionCodes (WHERE = (IDI_tble = "fam_daily_rate") );
run ;

%FrmtDataTight(FCMinfile = fdr_InCDudCode
              ,FCMFmtNm = $fdr_InCDudCode
              ,FCMStart = IDI_var
              ,FCMLabel = InCDudCode
              ) ;

DATA wff_fam_daily_rate4 (KEEP= &IMMIOvars. TaxYear);
 &IMMIOfmts. ; 
 SET wff_daily_rate_oneapply1 
      wff_daily_rate_dupapply2 ; 

  ARRAY FTcRate(*) wff_fdr_daily_ctc_rate_amt wff_fdr_daily_fstc_rate_amt 
                   wff_fdr_daily_ftc_rate_amt wff_fdr_daily_iwp_rate_amt wff_fdr_daily_ptc_rate_amt 
                   wff_fdr_daily_ptc_rate_amt      
                  ;
  FTcRateList = COMPBL('wff_fdr_daily_ctc_rate_amt wff_fdr_daily_fstc_rate_amt 
                   wff_fdr_daily_ftc_rate_amt wff_fdr_daily_iwp_rate_amt wff_fdr_daily_ptc_rate_amt 
                   wff_fdr_daily_ptc_rate_amt') ;
  
  * read through each rate code and proces non zero values *;
  DO i = 1 TO DIM(FTcRate) ;
    IF FTcRate(i) NOT IN (0, .) THEN DO ;
      TaxCreditValue = SCAN(FTcRateList,i) ;
      TaxCreditRate = FTcRate(i) ;
      FORMAT StartDate EndDate date9. ;
      * if valid spell then process *;
      IF RateSD lt RateED THEN DO ;
        ** convert into monthly amounts and thin file format **;
        N_months = INTCK('month',RateSD,RateED) ;
        DO mn = 0 TO N_months ;
          StartDate = INTNX('month',RateSD,mn) ;
          EndDate = INTNX('month',StartDate,1) -1 ;
          Amount = TaxCreditRate * ((MIN(RateED,EndDate) - MAX(RateSD,StartDate)) + 1);
          InCDudCode = PUT(TaxCreditValue, $fdr_InCDudCode.);
          Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
          Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
          Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
          OUTPUT ;
        END ; DROP mn ;
      END ;
    END ;
  END ;
run ;

* 3.2 Sum by month *;
%LET ClassVars = snz_uid TaxYear StartDate EndDate Level1 Level2 Level3 InCDudCode ;
PROC MEANS DATA = wff_fam_daily_rate4 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_paid_monthly1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(Amount) = 
    ;
 run ;

 * 3.3 Calculate total tax credits paid *;
%LET ClassVars = snz_uid TaxYear StartDate EndDate  ;
PROC MEANS DATA = wff_paid_monthly1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_paid_monthly2 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(Amount) = 
    ;
run ;

* 3.4 Combine indiviudal and total results *;
DATA wff_paid_monthly3 ;
  &IMMIOfmts. ;  
  SET wff_paid_monthly2 (IN=A)
      wff_paid_monthly1 ;

 IF A THEN DO ;
  InCDudCode = 'fdrtpi' ;
  Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
  Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
  Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
 END ;
run ;

* 3.5 Reconcile with annual family tax credit return 

* 3.5.1 Annual paid amounts *;
%LET ClassVars = snz_uid TaxYear Level1 Level2 Level3  InCDudCode ;
PROC MEANS DATA = wff_paid_monthly3 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_paid_annual1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(Amount) = fdr_amount
    ;
run ;

 * 3.5.2 Identify all tax credit codes to scale *;
 %LET ClassVars = InCDudCode ;
 PROC MEANS DATA = wff_paid_annual1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = FTC_codes (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    N(snz_uid) = N_recs
    ;
 run ;

 DATA FTC_codes ;
  SET FTC_codes ;

  LENGTH FTC_codesSt $100. ;
  RETAIN FTC_codesSt ;
  FTC_codesSt = STRIP(FTC_codesSt)||" "||STRIP(InCDudCode) ;
  CALL SYMPUTX('FTC_codesSt', FTC_codesSt) ;
  CALL SYMPUTX('FTC_codesN', _N_) ;
 run ;

 *3.5.3 Add annualised tax credit IR payment results to the ir_tax_return dataset *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return2 ; BY &ByVars. ; run ; 
 PROC SORT DATA= wff_paid_annual1 ; BY &ByVars. ; run ; 

 DATA wff_scale1 (KEEP = snz_uid TaxYear Level1 Level2 Level3 fdr_Variance fdr_Scale);
  &IMMIOfmts. ;
  MERGE ir_annual_return2 (IN=A WHERE = (Level3 = 'Regular pay all tax credits IR') )
        wff_paid_annual1 (IN=B 
                          WHERE = (Level3 = 'Regular pay all tax credits IR')
                          RENAME = (InCDudCode = fdr_InCDudCode  )
                          ) ;
  BY &ByVars.;
  IF A OR B ;

  * identify variance for scaling *;
  fdr_Variance = (fdr_Amount - Amount)  ;
  AbsVar = ABS(fdr_Variance) ;
  fdr_Scale = Amount / fdr_Amount ;
 run ;

 /* Check variance *;
%LET ClassVars = TaxYear ;
PROC MEANS DATA = wff_scale1  NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = check  (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    MEAN(fdr_Variance AbsVar Amount) = 
    ;
 run ;
  PROC PRINT DATA = check (obs=...) ; run ;
 6    2005-03-31     3630.59    3642.21    2788.87
 7    2006-03-31     -307.72     514.93    3919.25
 8    2007-03-31      -22.98     451.86    5597.66
 9    2008-03-31        3.79     440.89    6562.10
10    2009-03-31     -141.71     449.43    6883.64
11    2010-03-31      -19.09     431.28    7061.71
12    2011-03-31       34.10     421.98    7154.01
13    2012-03-31       -3.00     437.67    7229.36
14    2013-03-31       -0.77     422.54    7353.37
15    2014-03-31      -23.07     416.93    7318.80
16    2015-03-31     -154.79     424.89    7540.09
17    2016-03-31       16.75     444.72    7439.85
18    2017-03-31       21.32     449.84    7686.43
19    2018-03-31     3474.00    3667.61    5610.69
 *MdB June 2016 Still large variances if anyone can reduce them let me know!
      Assume 2018 tax year result is becuase PTS results have not all been loaded
*/

 * 3.5.3 Determine scale for each snz_uid taxyear and InCDudCode *;
 DATA wff_scale2 (KEEP = snz_uid TaxYear level: InCDudCode fdr_Scale);
  SET wff_scale1;

  LENGTH InCDudCode $6. ;
  DO i = 1 TO &FTC_codesN. ;
    InCDudCode = SCAN(COMPBL("&FTC_codesSt."), i) ;
    Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
    Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
    Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
    OUTPUT  ;
  END ; DROP i ;
 run ;

 * 3.5.4 Scale monthly IR paid to annual IR paid *;
 DATA wff_paid_monthly4 ;
  SET wff_paid_monthly3 ;

  * scale monthyl amount to match annual result *;
  * if no annula result then monthly is made 0 *;
  %HashTblFullJoin( RCVtble = wff_scale2
                   ,RCVtblCd =na
                   ,RCVcode =snz_uid TaxYear InCDudCode
                   ,RCVvars =fdr_Scale
                   ) ;
  IF fdr_Scale = . THEN fdr_Scale = 0 ;
  amount = amount * fdr_Scale ;
  IF amount NOT IN (0, .) THEN OUTPUT ;
  DROP fdr_Scale ;
 run ;

 *3.6 Update annual tax return dataset with scaled tax credit payment data *;
%LET ClassVars = snz_uid TaxYear Level1 Level2 Level3  InCDudCode ;
PROC MEANS DATA = wff_paid_monthly4 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = wff_paid_annual2 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(Amount) = fdr_amount
    ;
run ;

 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return2 ; BY &ByVars. ; run ; 
 PROC SORT DATA= wff_paid_annual2 ; BY &ByVars. ; run ; 

 DATA ir_annual_return3 (SORTEDBY = &ByVars.
                         DROP = ScaledVariance AbsVar
                        )
       wff_reconcile1 ;
  &IMMIOfmts. ;
  MERGE ir_annual_return2 (IN=A  )
        wff_paid_annual2 (IN=B
                 RENAME = (InCDudCode = fdr_InCDudCode
                            )
                 ) ;
  BY &ByVars.;
  IF A OR B ;

  %HashTblFullJoin( RCVtble = wff_scale2
                   ,RCVtblCd =na
                   ,RCVcode =snz_uid TaxYear Level1 Level2 Level3
                   ,RCVvars =fdr_Scale
                   ) ;
  LABEL fdr_amount = 'Scaled amount from '
        fdr_Scale = 'Amount of scaling required'
  * identify variance after scaling *;
  ScaledVariance = (fdr_Amount - Amount)  ;
  AbsVar = ABS(ScaledVariance) ;
  IF     Level3 = 'Regular pay all tax credits IR' 
     AND AbsVar gt 2 THEN OUTPUT wff_reconcile1 ;

  ** if IR3/PTS/TC_return missing then add in fdr information *;
  IF amount = 0 THEN amount = .;
  IF fdr_amount = 0 THEN fdr_amount = . ;
  Amount = COALESCE(Amount, fdr_Amount) ;
  Period = "Annual" ;
  tempTaxYear = TaxYear ;
   %IDICharDates( IDIinvar = tempTaxYear
                 ,IDIoutvar = EndDate
                 ,IDIDateFrm = YYYY-MM-DD ) ;
   StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;
  InCDudCode = COALESCEC(InCDudCode, fdr_InCDudCode) ;
  DROP fdr_InCDudCode ;
  OUTPUT ir_annual_return3 ;
 run ;

 * 3.7 Calculate total tax credits paid each period *;

 * 3.7.1 Identify regular IR and MSD monthly payments
         Note these have already been scaled to match annula IR3/PTS/FTC values 
              IR daily rate data starts from April 2005 *;
 DATA TaxCreditMonthly1 (KEEP = &IMMIOvars. TaxYear Period);
  SET wff_paid_monthly4 
      IMMIO_IncomeOutgoing1 (WHERE = (level2 = 'Tax credit')) ;
  Period = PUT(InCDudCode, $Income_period. ) ;
 run ;

 * 3.7.2 Calculate total regular payed *;
 * Monthly IR payment data starts from April 2005 only *;
 %LET ClassVars =  snz_uid TaxYear StartDate EndDate Level1 Level2;
 PROC MEANS DATA = TaxCreditMonthly1 (WHERE = (Level3 IN ('Regular pay all tax credits IR'
                                                          ,'Regular pay all tax credits MSD')
                                                AND StartDate ge '01Apr2005'd 
                                                AND Period = "Month")
                                      ) NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = TaxCreditMonthly2 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = 
    ;
 run ;

 * 3.7.3 Combine individual and Totals together **;
 DATA TaxCreditMonthly3 ;
  SET TaxCreditMonthly2 (IN=A)
      TaxCreditMonthly1  ;

  IF A THEN DO ;
    InCDudCode = 'dertpr' ;
    Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
    Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
    Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
    Period = PUT(InCDudCode, $Income_period. ) ;
  END ;
 run ;

 * 3.7.4 Identify annual records that are totals of monthly series *;
  %LET ClassVars = snz_uid TaxYear Level1 Level2 Level3 InCDudCode ;
  PROC MEANS DATA = TaxCreditMonthly3 (WHERE = (Period = "Month")) NOPRINT NWAY MISSING ;
    CLASS &ClassVars.  ; 
    OUTPUT OUT = TotaltaxCreditAnnual1 (DROP = _TYPE_ _FREQ_ 
                               SORTEDBY = &ClassVars.
                               )
      SUM(amount) = ttc_amount
      ;
   run ;

 DATA TotaltaxCreditAnnual2 ;
  SET TotaltaxCreditAnnual1 (RENAME = (InCDudCode = ttc_InCDudCode )) ;
  Period ='Annual' ;
 run ;

 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 Period;
 PROC SORT DATA= TaxCreditMonthly3 ; BY &ByVars. ; run ; 
 PROC SORT DATA= TotaltaxCreditAnnual2; BY &ByVars. ; run ; 

 DATA TaxCreditMonthly4 (SORTEDBY = &ByVars.
                         DROP = ttc_InCDudCode ttc_amount)
      tc_recon1 ;
  FORMAT &ByVars. ; 
  MERGE TaxCreditMonthly3 (IN=A)
        TotaltaxCreditAnnual2 (IN=B) ;
  BY &ByVars.;
  IF A ;
  ** annual and monthly total do not match *;
  IF B AND ABS(amount - ttc_amount) gt 2 THEN OUTPUT tc_recon1 ;

  ** if monthly values then do not output annual value *;
  IF A AND NOT B THEN OUTPUT TaxCreditMonthly4 ;
 run ;  

 * 3.7.5 Scale any annualised monthly total to the annual total *;
 DATA tc_recon2 ;
  SET tc_recon1 ;
  tc_scale = amount / ttc_amount ;
 run ;

 DATA TaxCreditMonthly5 ;
  SET TaxCreditMonthly4 ;

  %HashTblFullJoin( RCVtble = tc_recon2
                   ,RCVtblCd =sc
                   ,RCVcode =snz_uid TaxYear Level1 Level2 Level3
                   ,RCVvars =tc_scale
                   ) ;
  IF tc_scale = . THEN tc_scale = 1 ;
  amount = amount * tc_scale ;
  DROP tc_scale ;
 run ;

 * 3.7.4 Add tax credit results to annual dataset *;
 %LET ClassVars = snz_uid TaxYear Level1 Level2 Level3 InCDudCode;
 PROC MEANS DATA = TaxCreditMonthly5 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = TotaltaxCreditAnnual1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = ttc_amount
    ;
 run ;

 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return3 ; BY &ByVars. ; run ; 
 PROC SORT DATA= TotaltaxCreditAnnual1 ; BY &ByVars. ; run ; 

 DATA ir_annual_return4 (SORTEDBY = &ByVars.
                         DROP = Variance AbsVar
                        )
       ttc_reconcile1 ;
  &IMMIOfmts. ;
  MERGE ir_annual_return3 (IN=A  )
        TotaltaxCreditAnnual1 (IN=B
                           RENAME = (InCDudCode = ttc_InCDudCode )
                             
                          ) ;
  BY &ByVars.;
  IF A OR B ;

  LABEL ttc_amount = "Total amount of tax credits paid based on sum of IR and MSD pay" ;

  * identify variance for scaling *;
  Variance = (ttc_Amount - Amount)  ;
  AbsVar = ABS(Variance) ;
  IF B AND AbsVar gt 2 THEN OUTPUT ttc_reconcile1 ;

  ** if IR3/PTS/TC_return missing then add in ttc information *;
  IF amount = 0 THEN amount = .;
  IF ttc_amount = 0 THEN ttc_amount = . ;
  Amount = COALESCE(Amount, ttc_Amount) ;
  tempTaxYear = TaxYear ;
   %IDICharDates( IDIinvar = tempTaxYear
                 ,IDIoutvar = EndDate
                 ,IDIDateFrm = YYYY-MM-DD ) ;
   StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;
  InCDudCode = COALESCEC(InCDudCode, ttc_InCDudCode) ;
  DROP ttc_InCDudCode period ;
  OUTPUT ir_annual_return4 ;
 run ;

 * 3.8 Add updated tax credit information to IMMIO_IncomeOutgoing *;
 DATA IMMIO_IncomeOutgoing2 ;
  SET TaxCreditMonthly3 (DROP = period) 
      IMMIO_IncomeOutgoing1 (WHERE = (level2 ne 'Tax credit')) ;
 run ;


  * Housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
  DELETE wff_reconcile: wff_scale: 
         wff_paid_monthly: 
         wff_paid_annual: 
         wff_fam_daily_rate:
         wff_daily_rate_dupapply:
         wff_daily_rate_oneapply:
         wff_daily_same_apply:
         ir_annual_return1-ir_annual_return3
         TotaltaxCreditAnnual:
         IMMIO_IncomeOutgoing1 
         TaxCreditMonthly: 
         tc_recon: ; 
 run ;


******************************************************************************;
   ** Stage 4 non taxable income support assistance **;

  ** 4.1 Subset MSD income support IR table table to ids of interest *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema =  MSD_clean
                    ,SIDId_IDIdataset = msd_second_tier_expenditure
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = MSD_IS2ndTier1
                   );

 ** 4.2 Generate a monthly total amount for each payment event **
    Exclude Family Tax Credit payments whilst on main benefit 
    this is taken from IRD tax credit sources 
 *;

*4.2.2 extract only relevent values from msd_second_tier_expenditure *;
DATA MSD_IS2ndTier2 (KEEP =  &IMMIOvars. TaxYear);
  &IMMIOfmts. ;
 SET MSD_IS2ndTier1 (KEEP = snz_uid 
                            msd_ste_start_date 
                            msd_ste_end_date 
                            msd_ste_supp_serv_code 
                            msd_ste_daily_gross_amt
                     WHERE = (snz_uid ne .)  ) ;

  **Convert char dates to num dates *;
  %IDICharDates( IDIinvar = msd_ste_start_date
               ,IDIoutvar = MSD_Event_SD
               ,IDIDateFrm = YYYY-MM-DD ) ;

  %IDICharDates( IDIinvar = msd_ste_end_date
               ,IDIoutvar = MSD_Event_ED
               ,IDIDateFrm = YYYY-MM-DD ) ;

  FORMAT SplMonthSD
         SplMonthED ddmmyy10. ;

  ** Calender month start and end of each spell *;
  SplMonthSD = MDY(MONTH(MSD_Event_SD),1,YEAR(MSD_Event_SD)) ; 
  SplMonthED = INTNX('month',MDY(MONTH(MSD_Event_ED),1,YEAR(MSD_Event_ED)),1)-1  ; 
  Nmonths = INTCK('month',SplMonthSD,SplMonthED) ;

  ** calculate the total second tier rate for each calender month *;
  DO i = 0 TO Nmonths ;
     StartDate = INTNX('month',SplMonthSD,i) ;
     EndDate = INTNX('month',StartDate,1)-1 ;
     amount =  msd_ste_daily_gross_amt * 
                  (MIN(EndDate, MSD_Event_ed) - (MAX(StartDate, MSD_Event_SD))+1);
     ** tax year *;
     LENGTH TaxYear $10. ;
     IF MDY(1,1,YEAR(StartDate)) le StartDate le MDY(3,31,YEAR(StartDate)) THEN TaxYear = CATT(YEAR(StartDate),"-03-31") ;
     ELSE TaxYear = CATT(YEAR(StartDate)+1,"-03-31") ;

     * exclude any records outside of date range *;
     IF TaxYear IN (%TaxYearList) THEN DO ;
       InCDudCode = CATT('ste',msd_ste_supp_serv_code) ;
       Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
       Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
       Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
       OUTPUT ;
     END ;
  END ; DROP i ;
 run ;

 ** 4.3 Sum the total second teir rate in each calender month  *;
 %LET ClassVar = snz_uid    
                 TaxYear      
                 StartDate EndDate       
                 Level1 Level2 Level3                 
                 InCDudCode
                ;
 PROC MEANS DATA = MSD_IS2ndTier2 NOPRINT NWAY;
 CLASS &ClassVar. ;
 OUTPUT OUT= MSD_IS2ndTier3 (SORTEDBY = &ClassVar.
                             DROP = _TYPE_ _FREQ_
                             COMPRESS = yes)
  SUM(Amount) =;
 run ;

 * 4.4 Total supplimentary paid in each month *;
 %LET ClassVar = snz_uid    
                 TaxYear      
                 StartDate EndDate       
                 Level1 Level2       
                ;
 PROC MEANS DATA = MSD_IS2ndTier3 (WHERE = (level3 NOT IN ('Family tax credit regular pay MSD')) ) NOPRINT NWAY;
 CLASS &ClassVar. ;
 OUTPUT OUT= MSD_IS2ndTier4 (SORTEDBY = &ClassVar.
                             DROP = _TYPE_ _FREQ_
                             COMPRESS = yes)
  SUM(Amount) =;
 run ;

 * 4.5 Combine total and individual amounts *;
 DATA MSD_IS2ndTier5 ;
  SET MSD_IS2ndTier4 (IN=A)
      MSD_IS2ndTier3 ;

  IF A THEN DO ;
   InCDudCode= 'stetot' ;
   Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
  END ;
 run ;

  * Housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
  DELETE MSD_IS2ndTier1-MSD_IS2ndTier4 ; 
 run ;

  ** 4.6 Subset MSD income support table table to ids of interest *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema =  MSD_clean
                    ,SIDId_IDIdataset = msd_third_tier_expenditure
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = MSD_IS3rdTier1
                   );

 ** 4.7 Generate a monthly total amount for each payment event **;
DATA MSD_IS3rdTier2 (KEEP =  &IMMIOvars. TaxYear );
  &IMMIOfmts. ;
 SET MSD_IS3rdTier1 (KEEP = snz_uid 
                            msd_tte_decision_date 
                            msd_tte_pmt_amt
                            msd_tte_recoverable_ind
                            msd_tte_lump_sum_svc_code
                     WHERE = (snz_uid ne .)
                    ) ;
 
 **Convert char dates to num dates *;
 %IDICharDates( IDIinvar = msd_tte_decision_date
               ,IDIoutvar = MSD_Event_SD
               ,IDIDateFrm = YYYY-MM-DD ) ;

 %IDICharDates( IDIinvar = msd_tte_decision_date
               ,IDIoutvar = MSD_Event_ED
               ,IDIDateFrm = YYYY-MM-DD ) ;

  ** Calender month start of each payment *;
  StartDate = MDY(MONTH(MSD_Event_SD),1,YEAR(MSD_Event_SD)) ;
  EndDate = INTNX('month',StartDate,1)-1 ;

  ** tax year *;
  LENGTH TaxYear $10. ;
  IF MDY(1,1,YEAR(StartDate)) le StartDate le MDY(3,31,YEAR(StartDate)) THEN TaxYear = CATT(YEAR(StartDate),"-03-31") ;
  ELSE TaxYear = CATT(YEAR(StartDate)+1,"-03-31") ;

  * exclude any records outside of date range *;
  IF TaxYear NOT IN (%TaxYearList) THEN DELETE ;
 
  ** identify recoverable and non recoverable payments *;
  IF msd_tte_recoverable_ind = "N" THEN DO ;
     InCDudCode= CATT('tte', msd_tte_lump_sum_svc_code );
     Amount = msd_tte_pmt_amt ;
  END ;
  ELSE DO ;
     InCDudCode= CATT('ttl', msd_tte_lump_sum_svc_code );
     Amount = msd_tte_pmt_amt*-1 ;
  END ;
  Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
  Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
  Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
  OUTPUT ;

  * Total *;
  IF msd_tte_recoverable_ind = "N" THEN DO ;
     InCDudCode='ttetot';
  END ;
  ELSE DO ;
     InCDudCode= 'ttltot';
  END ;
  Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
  Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
  Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
  OUTPUT ;
 run ;

 ** 4.8 Sum the total third teir rate in each calender month  *;
 %LET ClassVar = snz_uid    
                 TaxYear      
                 StartDate EndDate       
                 Level1 Level2                     
                 Level3                 
                 InCDudCode
                ;
 PROC MEANS DATA = MSD_IS3rdTier2 NOPRINT NWAY;
 CLASS &ClassVar. ;
 OUTPUT OUT= MSD_IS3rdTier3 (SORTEDBY = &ClassVar.
                            DROP = _TYPE_ _FREQ_
                            WHERE = (amount ne 0)
                           )
  SUM(Amount) =;
 run ;

 * 4.9 Combine ISE results  *;
 DATA IncomeSupport1 ;
  SET MSD_IS3rdTier3
      MSD_IS2ndTier5 ;
 run ;

 * Housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
  DELETE MSD_IS3rdTier:
         MSD_IS2ndTier:
         ; 
 run ;

 * 4.10 Update annual tax summary *;
 %LET ClassVars = snz_uid TaxYear Level1 Level2 Level3 InCDudCode;
 PROC MEANS DATA = IncomeSupport1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = TotalIncomeSupport1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = ise_amount
    ;
 run ;

 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return4 ; BY &ByVars. ; run ; 
 PROC SORT DATA= TotalIncomeSupport1 ; BY &ByVars. ; run ; 

 DATA ir_annual_return5 (SORTEDBY = &ByVars.)  ;
  &IMMIOfmts. ;
  MERGE ir_annual_return4 (IN=A  )
        TotalIncomeSupport1 (IN=B
                           RENAME = (InCDudCode = ise_InCDudCode )
                             
                          ) ;
  BY &ByVars.;
  IF A OR B ;

  Amount = COALESCE(Amount, ise_Amount) ;
  tempTaxYear = TaxYear ;
  %IDICharDates( IDIinvar = tempTaxYear
               ,IDIoutvar = EndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
  StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;
  InCDudCode = COALESCEC(InCDudCode, ise_InCDudCode) ;
  DROP ise_InCDudCode ;
 run ;

 * 4.11 Add income support payments to IMMIO_IncomeOutgoing *; 
 DATA IMMIO_IncomeOutgoing3 ;
  SET IncomeSupport1 (IN=A)  
      IMMIO_IncomeOutgoing2 ;
 run ;


 * Housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
  DELETE ir_annual_return4
         TotalIncomeSupport:
         IncomeSupport: 
         IMMIO_IncomeOutgoing2
         ; 
 run ;


*****************************************************************;
  ** Stage 5: Student Assistance *;

  ** 5.1 Student Loan borrowing variables annual *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema =  sla_clean
                    ,SIDId_IDIdataset = MSD_borrowing
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = SLA_yrly_amt1
                   );

  ** 5.2 Convert into thin file *;

*5.2.1 Identify variables of interest *;
 DATA MSD_borrowingcodes1 ;
  SET IncomeDeductionCodes (WHERE = (IDI_tble = 'msd_borrowing' )  ) ;

  CALL SYMPUTX(CATT('irait_var_',_N_), IDI_var) ;
  CALL SYMPUTX(CATT('irait_cd_',_N_), InCDudCode) ;
  CALL SYMPUTX(CATT('irait_pv_',_N_), PersonView) ;
  CALL SYMPUTX('irait_N', _N_) ;
 run ;

 * MSD borrowing information is from 1999/2000 onwards but exclude 
   any loan information as this is also recorded in the IR transfer table *;
 DATA SLA_yrly_amt2 (KEEP =&IMMIOvars. TaxYear
                     WHERE = ("&IMMIO_RptSD."d le StartDate le "&IMMIO_RptED."d)
                    );
    &IMMIOfmts.     ;
  SET SLA_yrly_amt1 (WHERE = (snz_uid ne .));

  ** convert dates **;
  %IDICharDates(IDIinvar = msd_sla_sl_study_start_date
               ,IDIoutvar = StartDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
  %IDICharDates(IDIinvar = msd_sla_sl_study_end_date
               ,IDIoutvar = EndDate
               ,IDIDateFrm = YYYY-MM-DD ) ;
  StartDate = MDY(MONTH(StartDate),1,YEAR(StartDate));
  EndDate = MDY(MONTH(EndDate),1,YEAR(EndDate));

   * start date is based on month of the study end date *;  
  TaxYearDate = MDY(MONTH(EndDate),1,YEAR(EndDate)) ;

  ** tax year *;
  LENGTH TaxYear $10. ;
  IF MDY(1,1,YEAR(TaxYearDate)) le TaxYearDate le MDY(3,31,YEAR(TaxYearDate)) THEN TaxYear = CATT(YEAR(TaxYearDate),"-03-31") ;
  ELSE TaxYear = CATT(YEAR(TaxYearDate)+1,"-03-31") ;
 
  * convert to thin file format *;
  %ThinFileConvert ;
 run ;

  /* Housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
  DELETE SLA_yrly_amt1 ; 
 run ;*/

 * 5.3 Loans transferred to IR from MSD this data starts from 1992 *;

  ** 5.3.1 Extract student loan transactions *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema =  sla_clean
                    ,SIDId_IDIdataset = ird_loan_transfer
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = IR_loantransf1
                   );

*5.2.1 Identify variables of interest *;
 DATA IR_loan transfers1 ;
  SET IncomeDeductionCodes (WHERE = (IDI_tble = 'ird_loan_transfer' )  ) ;

  CALL SYMPUTX(CATT('irait_var_',_N_), IDI_var) ;
  CALL SYMPUTX(CATT('irait_cd_',_N_), InCDudCode) ;
  CALL SYMPUTX(CATT('irait_pv_',_N_), PersonView) ;
  CALL SYMPUTX('irait_N', _N_) ;
 run ;

 * 5.3.2 Loan transfers from MSD *;
 DATA IR_loantransf2 ( KEEP = &IMMIOvars. TaxYear
                     WHERE = ("&IMMIO_RptSD."d le StartDate le "&IMMIO_RptED."d)
                    );
  &IMMIOfmts.     ;
  SET IR_loantransf1 (WHERE = (snz_uid ne .));

  StartDate = MDY(1,1,ir_trn_academic_year_nbr) ;
  EndDate = MDY(12,31,ir_trn_academic_year_nbr) ;

  ** tax year Not sure if this is correct there might be a lag *;
  LENGTH TaxYear $10. ;
  IF MDY(1,1,YEAR(EndDate)) le EndDate le MDY(3,31,YEAR(EndDate)) THEN TaxYear = CATT(YEAR(EndDate),"-03-31") ;
  ELSE TaxYear = CATT(YEAR(EndDate)+1,"-03-31") ;

  %ThinFileConvert ;
 run ;

  ** Monthly Student Loan transactions IR *;
  ** avaliable from Janurary 2012 *;

  ** 5.4 Extract IRD customers to get snz_ird_uid *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema =  ir_clean
                    ,SIDId_IDIdataset = ird_customers
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = IRD_clients
                   );

  %LET ByVars = snz_uid snz_ird_uid ;
  PROC SORT DATA = IRD_clients (WHERE = (snz_uid ne .) ) NODUPKEY ; BY &ByVars. ; run ;

  %FrmtDataTight(FCMinfile = IRD_clients
                ,FCMFmtNm = IRDNo_SNZuid
                ,FCMStart = snz_ird_uid
                ,FCMLabel = snz_uid
                ) ;

  ** 5.5 Extract student loan transactions *;
 %Subset_IDIdataset2(SIDId_infile =&IMMIO_infile.
                    ,SIDId_Id_var =snz_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = 
                    ,SIDId_IDIschema = sla_clean
                    ,SIDId_IDIdataset = ird_amt_by_trn_type
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = SLA_trn_amt1
                   );

  * 5.5.1 dataset with the latest trnsactions *;
 %Subset_IDIdataset2(SIDId_infile = IRD_clients
                    ,SIDId_Id_var = snz_ird_uid
                    ,SIDId_IDIextDt = &IMMIO_IDIexDt.
                    ,SIDId_database = idi_adhoc
                    ,SIDId_IDIschema = clean_read_SLA
                    ,SIDId_IDIdataset = sla_ird_amt_by_trn_type
                    ,SIDId_Temp_database = idi_sandpit 
                    ,SIDId_Temp_dsn = idi_sandpit_srvprd
                    ,SIDId_Temp_schema = &IMMIO_SandPitSchema.
                    ,SIDId_outfile = SLA_trn_amt1_1
                   );

 PROC FORMAT ;
  VALUE $SLAtranType 
  "L" = "Lending"   
  "F" = "Establishment fee"  
  "G" = "Administration fee"  
  "I" = "Interest charged" 
  "J" = "Interest written-off" 
  "R" = "Loan Repayments" 
  "W" = "Write offs" 
  "P" = "Penalties added"    
  "Q" = "Penalties reversed"  
  other = "ERROR" 
 ;
  VALUE $TranTypeToInCDudCode 
  "L" = "trnltr"   
  "F" = "trnfee"  
  "G" = "trnadf"  
  "I" = "trnint" 
  "J" = "trnliw" 
  "R" = "trnrpy" 
  "W" = "trnlwo" 
  "P" = "trnpna"    
  "Q" = "trnpnr"
 other = "ERROR" 
  ;
  run ;

  ** 5.6 Format student loan transactions *;
  %use_fmt(SLA_trn_amt1, ir_att_trn_month_date, SLAcleanMths)  ;

  %LET KeepVars = ir_att_trn_month_date 
                  ir_att_trn_type_amt  
                  ir_att_trn_type_code  
                  snz_ird_uid;
  DATA SLA_trn_amt2 (KEEP = &IMMIOvars. TaxYear
                     WHERE = ("&IMMIO_RptSD."d le StartDate le "&IMMIO_RptED."d) )
       SLA_trn_NewCodes ;
    &IMMIOfmts.     ;
   SET SLA_trn_amt1 (KEEP = &KeepVars. snz_uid WHERE = (snz_uid ne .))
       SLA_trn_amt1_1 (IN=B KEEP = &KeepVars. WHERE = (snz_ird_uid ne .)) ;

   ** SNZ_uid from IRD no **;
   IF snz_uid = . THEN snz_uid = PUT(snz_ird_uid, IRDNo_SNZuid.) ;

   ** identify any overlapping months between SLA clean and sandpit *;
   IF B AND PUT(ir_att_trn_month_date, $SLAcleanMths.) = "Y" THEN DELETE ;

  ** convert dates **;
  %IDICharDates( IDIinvar = ir_att_trn_month_date
                ,IDIoutvar = StartDate
                ,IDIDateFrm = YYYY-MM-DD 
                ) ;
  StartDate = MDY(MONTH(StartDate),1,YEAR(StartDate)) ;
  EndDate = INTNX('month',StartDate,1)-1 ;

  Transaction = PUT(ir_att_trn_type_code,$SLAtranType.) ; 
  IF Transaction = "ERROR" THEN OUTPUT SLA_trn_NewCodes;
  ** tax year Not sure if this is correct there might be a lag *;
  LENGTH TaxYear $10. ;
  IF MDY(1,1,YEAR(StartDate)) le StartDate le MDY(3,31,YEAR(StartDate)) THEN TaxYear = CATT(YEAR(StartDate),"-03-31") ;
  ELSE TaxYear = CATT(YEAR(StartDate)+1,"-03-31") ;
 
  InCDudCode= PUT(ir_att_trn_type_code,$TranTypeToInCDudCode.) ; ;
  Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
  Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
  Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
  
  Amount = ir_att_trn_type_amt * -1 ;
  OUTPUT SLA_trn_amt2 ;
 run ;     

  * 5.7 Sum amounts by individual month and type of income or deduction *;
 %LET ClassVar = snz_uid    
                 TaxYear      
                 StartDate EndDate       
                 Level1 Level2                     
                 Level3                 
                 InCDudCode ;
 PROC MEANS DATA = SLA_trn_amt2 NOPRINT NWAY;
 CLASS &ClassVar. ;
 OUTPUT OUT= SLA_trn_amt3 (SORTEDBY = &ClassVar.
                           DROP = _TYPE_ _FREQ_
                           WHERE = (Amount ne 0)
                          )
  SUM(Amount) =;
 run ; 

 * 5.8 Combine student assistance transaction data *;
 DATA StudyAssistance1 ;
  SET SLA_trn_amt3 
      IR_loantransf2
      SLA_yrly_amt2 ;
  Period = PUT(InCDudCode, $Income_period. ) ;
 run ;

 *5.9 Identify any overlaps between monthly and annual amounts *;
  %LET ByVars = snz_uid taxyear 
                   Level1 Level2                     
                   Level3 ;
 PROC MEANS DATA = StudyAssistance1 (WHERE = (Period='Annual')) NOPRINT NWAY MISSING ;
  CLASS &ByVars.  ; 
  OUTPUT OUT = StudyAssistanceTY1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY =&ByVars.
                             )
    SUM(amount) = ann_amount 
    ;
 run ;
 PROC MEANS DATA = StudyAssistance1 (WHERE = (Period='Month')) NOPRINT NWAY MISSING ;
  CLASS &ByVars.  ; 
  OUTPUT OUT = StudyAssistanceTY2 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY =&ByVars.
                             )
    SUM(amount) = mth_amount 
    ;
 run ;

 DATA StudyAssistanceTY3 (SORTEDBY = &ByVars.);
  FORMAT &ByVars. ; 
  MERGE StudyAssistanceTY1 (IN=A)
        StudyAssistanceTY2 (IN=B) ;
  BY &ByVars.;
  IF A AND B ;
 run ;

 * 5.10 combine study information from other sources (ie ems pts ir3) *;
 * for student allowance favour ems over msd_borrowing *;
 * ems student loan repayments stop after April 2001 *; 

 DATA StudyAssistance3 
      StudyAssistance4;
  SET StudyAssistance1 (IN=A WHERE = (Level3 NOT IN ('Student allowance payments')))  
      IMMIO_IncomeOutgoing3 (WHERE = (level2 = 'Study') );

   * 5.9.1 Where overlaps exist favour the monthly records *;
   * becuase of the difficulty of aliging tax, calender and academic year I have not scaled.
     In many instances the values match in one year then in another they do not, with no clear pattern
     that I can make out. For now I take monthly data when avaliable *;
  IF A THEN DO ;
    %HashTblFullJoin( RCVtble = StudyAssistanceTY3
                     ,RCVtblCd =sc
                     ,RCVcode =snz_uid TaxYear Level1 Level2 Level3
                     ,RCVvars =mth_amount
                     ) ;
    IF period = 'Annual' AND mth_amount ne . THEN DELETE ;
    DROP period mth_amount ;
  END ;
  OUTPUT StudyAssistance3 ;

  * Create Summary totals *;
  sum = 0 ;
  IF Level3 IN ( "A bursary payment" 
                      ,"A bursary repaid"  
                      ,"B bursary payment" 
                      ,"B bursary repaid" 
                      ,"Bonded merit payment" 
                      ,"Bonded merit repaid" 
                      ,"Step up payment" 
                      ,"Step up repaid" 
                      ,"Student allowance payments"  
                      ,"Student allowance repayment" 
                      ,"Top scholar payment")
    THEN DO ; Sum = 1 ; InCDudCode = 'dersat' ; END ;
 
  IF Level3 IN ("Loan administration fee" 
                    ,"Loan balance transferred to IR" 
                     )
    THEN DO ; sum = 1 ; InCDudCode = 'dersld' ; END ;

  IF Level3 IN ("Loan interest charged" 
                      ,"Loan interest transferred to IR"  
                      ,"Loan interest written-off"
                      ,"Loan penalties added" 
                      ,"Loan penalties reversed"
                      ,"Loan principal written-off"
                      )
    THEN DO ; sum = 1 ; InCDudCode = 'dersli' ; END ;

  IF Level3 IN ( "Loan repayments to IR"  
                ,"Loan repayments to MSD"
                      )
    THEN DO ; sum = 1 ; InCDudCode = 'derslr' ; END ;
  IF sum = 1 THEN OUTPUT StudyAssistance4 ;
  DROP sum ;
 run ;

 *5.11 Sum summary totals *; 
 %LET ClassVars = snz_uid TaxYear StartDate EndDate InCDudCode
                  ;
 PROC MEANS DATA = StudyAssistance4 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = StudyAssistance4 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(amount) = 
    ;
 run ;

 DATA StudyAssistance5 ;
  SET StudyAssistance4 (IN=A)
      StudyAssistance3 ;

  IF A THEN DO ;
    Level1 = PUT(InCDudCode, $Income_1_lvl.) ;
    Level2 = PUT(InCDudCode, $Income_2_lvl.) ;
    Level3 = PUT(InCDudCode, $Income_3_lvl.) ;
  END ;

  source = SUBSTR(InCDudCode,1,3) ;
 run ;

 ** 5.12 Update annual tax return dataset with study assistance data *;
 %LET ClassVars = snz_uid TaxYear Level1 Level2 Level3 source InCDudCode ;
 PROC MEANS DATA = StudyAssistance5 (WHERE = (source NOT IN ('ems', 'der', 'ir3', 'pts') ) ) NOPRINT NWAY MISSING ;
  CLASS &ClassVars.  ; 
  OUTPUT OUT = StdyAsAnnual1 (DROP = _TYPE_ _FREQ_ 
                             SORTEDBY = &ClassVars.
                             )
    SUM(Amount) = amount
    ;
 run ;

 * 5.12.1 Tranpose amount by source *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= StdyAsAnnual1 ; BY &ByVars. ; run ; 

 PROC TRANSPOSE DATA = StdyAsAnnual1 
  SUFFIX = _amount 
  OUT = StdyAsAnnual2 (SORTEDBY = &ByVars. 
                       DROP = _NAME_ _LABEL_) ;
  BY &ByVars.;
  ID source ;
  VAR amount ;
 run ;
 
 * 5.12.2 Tranpose InCDudCode by source *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= StdyAsAnnual1 ; BY &ByVars. ; run ; 

 PROC TRANSPOSE DATA = StdyAsAnnual1 
  SUFFIX = _InCDudCode 
  OUT = StdyAsAnnual3 (SORTEDBY = &ByVars. 
                       DROP = _NAME_ _LABEL_) ;
  BY &ByVars.;
  ID source ;
  VAR InCDudCode ;
 run ;

 * 5.12.3 Update annual amounts table *;
 %LET ByVars = snz_uid TaxYear Level1 Level2 Level3 ;
 PROC SORT DATA= ir_annual_return5 ; BY &ByVars. ; run ; 
 PROC SORT DATA= StdyAsAnnual2 ; BY &ByVars. ; run ; 
 PROC SORT DATA= StdyAsAnnual3 ; BY &ByVars. ; run ; 

 DATA ir_annual_return6 (SORTEDBY = &ByVars. ) ;
  &IMMIOfmts. ;
  MERGE ir_annual_return5 (IN=A  )
        StdyAsAnnual2 (IN=B)
        StdyAsAnnual3 (IN=C);
  BY &ByVars.;
  IF A OR B OR C ;

  LABEL trn_Amount = 'Amount from sla_clean.ird_amt_by_trn_type'
        ilt_amount = 'Amount from sla_clean.ird_loan_transfer'
        sba_amount = 'Amount from sla_clean.msd_borrowing' 
        ;

  InCDudCode = COALESCEC(InCDudCode, trn_InCDudCode, ilt_InCDudCode, sba_InCDudCode) ;
  Amount = COALESCE(Amount, trn_Amount, ilt_amount, sba_amount) ;
  tempTaxYear = TaxYear ;
   %IDICharDates( IDIinvar = tempTaxYear
                 ,IDIoutvar = EndDate
                 ,IDIDateFrm = YYYY-MM-DD ) ;
   StartDate = INTNX('year',EndDate,-1, 'same') + 1 ;
  DROP trn_InCDudCode ilt_InCDudCode sba_InCDudCode ;
 run ;

 * 5.14 Update income and outgoings table *;
 DATA IMMIO_IncomeOutgoing4 ;
  SET IMMIO_IncomeOutgoing3 (WHERE = (level2 ne 'Study') )
      StudyAssistance5 (DROP = source) ;
 run ;


   * Housekeeping *;
 PROC DATASETS LIB = work NOLIST ;
  DELETE SLA_trn_amt:
         ir_annual_return5
         ird_clients
         StdyAsAnnual:
         IMMIO_IncomeOutgoing3
         StudyAssistance:
         IR_loantransf:
         SLA_yrly_amt:
         StudyAssistanceTY:
         ; 
 run ;
 
*****************************************************************;
  ** Stage 6: Combine income and deductions datasets *;

 * Filter relevent records for output *;

 %MACRO RecordFilter ;
   LevelN = PUT(InCDudCode, $LevelN. ) ;
   IF Level1 = 'Income' AND LevelN le &IMMIO_IncomeDetail. THEN OUTPUT ;
   IF Level1 = 'Loan' AND LevelN le &IMMIO_LoanDetail. THEN OUTPUT ;
   IF Level1 = 'Tax' AND LevelN le &IMMIO_TaxDetail. THEN OUTPUT ;
   IF Level1 = 'Transfer' AND LevelN le &IMMIO_TransferDetail. THEN OUTPUT ;
 %MEND ;

 * 6.1 create output dataset filter out any unwanted records *;
 DATA &IMMIO_Outfile. (KEEP = &IMMIOvars.) ;
  &IMMIOfmts. ;
  SET IMMIO_IncomeOutgoing4 ;
  %RecordFilter ;
 run ;

 * 6.2 create output dataset of annual amounts filter out any unwanted records *;
 DATA &IMMIO_annual. ;
  FORMAT snz_uid TaxYear Level1 Level2 Level3 Amount InCDudCode ;
  SET ir_annual_return6;
  %RecordFilter ;
  DROP startdate enddate leveln ;
 run ;

 * 6.3 meta dataset of income deduction codes for selected records *;
 DATA &IMMIO_InCDudCode. ;
  SET IncomeDeductionCodes ;
  %RecordFilter ;
  DROP PersonView ;
 run ;

 %LET ByVars = snz_uid
               StartDate
              ;
 PROC SORT DATA = &IMMIO_Outfile. ; BY &ByVars. ; run ;

 PROC PRINT DATA = &IMMIO_InCDudCode. (obs=2000) ; run ;

 PROC DATASETS LIB = work NOLIST ;
   DELETE ir_annual_return:
          IMMIO_IncomeOutgoing: ;
 run ;

 %PUT Macro end: IndMthMnyInOut_Macro ;
 %MEND ;  


