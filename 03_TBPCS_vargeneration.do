/* Generic PCS script 
STEP 3. variable generation and imputation of missing data
September 30, 2019 Takuya Yamanaka */

set more off
cd "~\Dropbox\10.GTB\1.PCS_generic"
//loading dta file from step.2
use "TBPCS_iso3_2019_cleaned.dta", clear

/*************************
          INCOME
*************************/
//Checked if no income data and no asset data. > variable names for asset need to be changed based on the questionnaire for each country
//This example is based on TZA
gen no_income=0

replace no_income=1 if income_pre==. & ///
electricity==. & ///
tv==. & ///
motorcycle==. & ///
radio==. & ///
bicycle==. & ///
sew==. & ///
mobile==. & ///
fridge==. & ///
car==. & ///
watch==. & ///
bank==. 

tab no_income

//How many people did not report personal income? /*47 with missing income , 148 with zero income*/
tab income_pre, m
gen income_pre_reported = income_pre // keep reported hh income for tabulation

//How many people did not report household income? /*3 with missing income , 68 with zero income*/
tab income_hh_pre, m
gen income_hh_pre_reported = income_hh_pre // keep reported hh income for tabulation

 //if no household income we use household assets based prediction. 
stepwise, pe(0.2) lr:reg income_hh_pre electricity ///
tv ///
motorcycle ///
radio ///
bicycle ///
sew ///
mobile ///
fridge ///
car ///
watch ///
bank ///
ls_livestock ///
ls_herds /// 
ls_poultry ///
ls_no_livestock ///
ls_other ///
toiletflush ///
toiletpit ///
toiletother 

predict income_hh_pred, xb 
tab income_hh_pred, m
gen income_imputed=0
replace income_imputed=1 if (income_hh_pre==. | income_hh_pre==0) & income_hh_pred !=.
replace income_hh_pre=income_hh_pred if (income_hh_pre==. | income_hh_pre==0) & income_hh_pred !=. /* 195 changes made to hh income (based on assets) */
replace income_hh_pre=1 if income_hh_pre < 1
tab income_hh_pre, m

//Calculates mean of personal income/household income for those with data (mean is 50.38%)
gen m_income_pre=income_pre/income_hh_pre_reported if income_hh_pre_reported!=.
replace m_income_pre=0 if m_income_pre==.
sum m_income_pre, d
gen mn_income_pre = r(mean)
 
//if only household earnings and not personal income reported then assume a percentage of household
replace income_pre=(income_hh_pre * mn_income_pre) if income_pre==. & income_hh_pre !=. & income_hh_pre !=0 /*48 changes made */

//annualize monthly income by multiplying by 12
gen income_hh_pre_annual=income_hh_pre *12
gen income_hh_now_annual=income_hh_now *12
gen income_pre_annual=income_pre *12
gen income_now_annual=income_now *12

label var income_hh_pre_annual "Annual income for household (pre-TB)"
label var income_hh_now_annual "Annual income for household (now)"
label var income_pre_annual "Annual income for individual (pre-TB)"
label var income_now_annual "Annual income for individual (now)"

/* Time valuation: HOURLY WAGE FOR Human Capital APPROACH */

//assuming 4.33 weeks per month. Income_pre is monthly and hours_worked is asked weekly
//gen hourly_wage = income_pre1/(hours_worked_pre*4.33) if income_pre1 !=. & hours_worked_pre !=.

gen hourly_wage = income_pre/(hours_worked_pre*4.33) if income_pre !=. & hours_worked_pre !=.

//if blank use 2000 hours per year or 160 hrs per month
replace hourly_wage=income_pre/160 if hours_worked_pre==. & income_pre !=.
replace hourly_wage=income_pre/160 if hours_worked_pre==0 & income_pre !=.

//Replace hourly_wage iwth minimum wage if desired
replace hourly_wage=1  if income_pre==0 & hourly_wage==0

/* TREATMENT DURATION */ //in months: 8 months MDR intensive and 12 months MDR continuation//
//if treat duration is missing use guidelines of 6 months DSTB 20 months MDR
gen treat_duration=treat_duration_int + treat_duration_cont
/*08.01.2020 IGB / PN: One may need to first ascertain why before replacing. Cleaning file
* should have taken care of any issue 
replace treat_duration=6 if treat_duration==. & mdr==0
replace treat_duration=20 if treat_duration==. & mdr==1 
*/

//long care seeking is defined as more than 4 weeks (15.38% of respondents)
gen delay=.
replace delay=0 if weeks_before_tx <= 4
replace delay=1 if weeks_before_tx > 4 & weeks_before_tx !=.
tab delay

//phase duration in days works under the assumptions that DSTB is split 2 months intensive,
// 4 months continuation (or 6 months for those with total duration of 8) and MDR
// is 8 months intensive, 12 months continuation. For those with a treatment duration of 8 months 
// we assume 2 months intensive 6 months continuation
gen phase_duration=.
replace phase_duration=duration_int*30 if phase=="phase1" // & mdr=="no"
replace phase_duration=duration_cont*30 if phase=="phase2" // & mdr=="yes"

//IGB 13.11.19 potential area for sensitivity analysis - should durations be hard coded instead?
/*Here we are assuming MDR intensive is 6 months and MDR continuation is 14 months, so 6x30 days=180 days and 14X30days=420 days
replace phase_duration=180 if phase=="phase1" & mdr==1
replace phase_duration=420 if phase=="phase2" & mdr==1
*/

//scalar should be the inverse of the percent of the phase completed. 
//For example if you are half done with the continuation phase, the scalar should be 2
gen scalar= phase_duration/phase_days
replace scalar=1 if scalar < 1 

//If individual patient income is higher than household, we replace household's income with the higher individual income
//percentage of HH income **THIS SHOULD BE DONE IN STEP 2
replace income_hh_pre=income_pre if income_pre > income_hh_pre & income_pre!=. & income_hh_pre !=.

//We create wealth quintiles based on household income pre disease
misstable summ income_hh_pre // Should be all included records, if missing then ensure cleaning is done
xtile hh_quintile =income_hh_pre, n(5)
tab hh_quintile

/*************************
        EXPENDITURE
*************************/
rename ex_total tot_ex
egen expend_hh_dis = rowtotal(ex_*), missing
egen expend_hh =rowmax(expend_hh_dis tot_ex)

misstable summ expend_hh // If still has some missing values, then review the cleaning process

gen expend_hh_annual = expend_hh*12
replace expend_hh_annual =1 if expend_hh_annual == 0


/*****************************************************************
 PART III- RELAPSE PATIENTS ONLY (COSTS OF PREVIOUS EPISODES)
 We have limited information on previous episodes (# of hospital days)

 We scale up costs based on number of days in hospital in previous 
 visits.
 *****************************************************************/
//gen n_prev_treat=tb_tx_times

//Length of stay: add variables that are the length of hospitalizations in part 5
//egen los_pre=rowtotal(hosp_dur_*), missing /*9 cases were hospitalised in previous episodes*/

/**************************************************************
 PART IV- NEW IN INTENSIVE PHASE ONLY (COSTS BEFORE DIAGNOSIS)
 
No need to scale it up here as patients will report all info 
as all of this happens prior to the interview.
***************************************************************/
//number of visits are any row with some value for at least one visit time
//egen n_visits_before=rownonmiss(r_*visit_before) if phase=="phase1"

//travel and visit times in hours (added across all visits) before TB diagnosis
//time component of cost before diagnosis (new intensive phase )

** 11.12.2019 IGB: Check for extreme values in travel time - are they hours or minutes?)
codebook repeat_4*travel_time1, c
preserve
	sort today pt_register
	keep if (repeat_41travel_time1 > 24 & repeat_41travel_time1 < .)
	keep pt_register patient_id age facility_cat int_name  r*_4*travel_time1  
	*export delimited using ".\cleaning_records_for_review\large_travel_time_before.csv", replace

restore
codebook repeat_4*visit_time1, c
preserve
	sort today pt_register
	keep if (repeat_4*visit_time1 > 24 & repeat_4*visit_time1 < .)
	keep pt_register patient_id age facility_cat int_name  r*_4*visit_time1  
	*export delimited using ".\cleaning_records_for_review\large_visit_time_before.csv", replace

restore

egen t_travel_before=rowtotal(repeat_4*travel_time1), missing
egen t_visit_before=rowtotal(repeat_4*visit_time1), missing
egen t_before=rowtotal(t_travel_before t_visit_before), missing

//putting a cost on that time this using the Human capital approach
gen c_traveltime_before=t_travel_before * hourly_wage
gen c_visittime_before=t_visit_before * hourly_wage
gen c_time_before=t_before * hourly_wage

//medical costs before TB diagnosis
egen c_med_before_room = rowtotal(repeat_4*day1), missing
egen c_med_before_cons = rowtotal(repeat_4*doctors1), missing
egen c_med_before_radio = rowtotal(repeat_4*radio1), missing
egen c_med_before_lab = rowtotal(repeat_4*lab1), missing
egen c_med_before_proc = rowtotal(repeat_4*proc1), missing
egen c_med_before_medicine = rowtotal(repeat_4*medicines1), missing
egen c_med_before_other = rowtotal(repeat_4*other), missing
egen c_med_before_dis=rowtotal(c_med_before_*), missing

//non-medical costs before TB diagnosis
egen c_nmed_before_travel =rowtotal(repeat_4*travel1), missing
egen c_nmed_before_food =rowtotal(repeat_4*food1), missing
*egen c_nmed_before_nutri =rowtotal(repeat_4*nutri1), missing // not applicable for TZA
egen c_nmed_before_accommodation=rowtotal(repeat_4*accomodation1), missing
egen c_nmed_before_dis=rowtotal (c_nmed_before_travel c_nmed_before_food c_nmed_before_accommodation /*c_nmed_before_nutri*/), missing

egen reimburse_before=rowtotal(repeat_4*reimburse1), missing
replace reimburse_before=0 if reimburse_before==.

// for combined visit costs choose maximum of reported total or sum of disaggregated costs
egen totalmed=rowtotal(repeat_4*totalmed1), missing
egen totalnmed=rowtotal(repeat_4*totalnmed1), missing

//medical costs before diagnosis
egen c_med_before=rowmax(c_med_before_dis totalmed)
replace c_med_before=c_med_before - reimburse_before
replace c_med_before=0 if c_med_before < 0 & c_med_before !=.
 
 //non-medical costs before diagnosis
egen c_nmed_before=rowmax(c_nmed_before_dis totalnmed)

//Signaling if total non-medical costs sum of disaggregated are lower than the non-disaggregated total (i.e. totalnmed) /*52 real changes made*/
gen test_flag2=.
replace test_flag2=1 if c_nmed_before_dis < totalnmed & totalnmed !=. /* 1 cases */
replace test_flag2=1 if c_nmed_before_dis ==. & totalnmed !=.

// must breakdown nmed categories for 5 patients who use totalnmed 
//collapse (sum) c_nmed_before_travel c_nmed_before_food c_nmed_before_accomodation
//Results show absolute amounts for the 3 components so we calculated the shares shown below for example country. 
//Replace these numbers with your shares.
//29.6% travel , 51.9% food, 10.0% nutri, 8.4% other/accom
/*
replace c_nmed_before_travel= .296  * totalnmed if test_flag2==1
replace c_nmed_before_food= .519 * totalnmed if test_flag2==1
replace c_nmed_before_nutri= .10 * totalnmed if test_flag2==1
replace c_nmed_before_accomodation= .084 * totalnmed if test_flag2==1
*/
//direct costs before diagnosis
egen c_direct_before=rowtotal(c_med_before c_nmed_before), missing
//costs before diagnosis (HC approach)
egen c_before= rowtotal(c_time_before c_direct_before), missing

/******************************************************************
 PART V - ALL PATIENTS (COSTS DURING CURRENT EPISODE)
*****************************************************************/
egen t_travel_current=rowtotal(repeat5*hosp_travel), missing
egen t_stay_current=rowtotal(repeat5*hosp_los), missing
* 11.12 2019 IGB/PN: Check lengths of stay at hospital, some have > 100 days
scatter repeat51hosp_los  today   if repeat51hosp_los  > 0, ysca(log) jitter(0.25) by(mdr)
preserve
	sort today pt_register
	keep if (t_stay_current > 100 & t_stay_current < .)
	keep pt_register patient_id age facility_cat int_name t_stay_current repeat5*hosp_los  
	*export delimited using ".\cleaning_records_for_review\large_dayshospitalised.csv", replace

restore

//convert lost days to hours
gen t_stay_current_hrs=t_stay_current*hours_worked_pre/7 
// working hours pre-disease (if missing, imputed with standard working hours per day (8hours) should be used)
// it was 24hours in the generic code 2017  
egen t_current = rowtotal (t_travel_current t_stay_current_hrs), missing

gen s_t_current=t_current * scalar

//putting a cost on that time (Human capital approach)
gen c_traveltime_current=t_travel_current * hourly_wage
gen c_staytime_current=t_stay_current * hourly_wage
gen c_time_current=t_current * hourly_wage

//cost of current episode hospital stays
//Hospital medical costs
egen c_med_current_day=rowtotal(repeat5*hosp_day), missing
egen c_med_current_cons=rowtotal(repeat5*hosp_cons), missing
egen c_med_current_radio=rowtotal(repeat5*hosp_radio), missing
egen c_med_current_lab=rowtotal(repeat5*hosp_lab), missing
egen c_med_current_proc=rowtotal(repeat5*hosp_proc), missing
egen c_med_current_med=rowtotal(repeat5*hosp_med), missing
egen c_med_current_oth=rowtotal(repeat5*hosp_other), missing


//Hospital non medical costs
egen c_nmed_current_travel_cost =rowtotal(repeat5*hosp_travel_cost), missing
egen c_nmed_current_food =rowtotal(repeat5*hosp_food), missing
*egen c_nmed_current_nutri =rowtotal(r5*hosp_nutri), missing //not for TZA
egen c_nmed_current_other_nmed=rowtotal(repeat5*hosp_other_nmed), missing
 
// Total medical and non medical costs
egen c_med_current_dis=rowtotal(c_med_current_day c_med_current_cons c_med_current_radio c_med_current_lab c_med_current_proc c_med_current_med c_med_current_oth), missing
egen c_nmed_current_dis=rowtotal(c_nmed_current_travel_cost c_nmed_current_food /*c_nmed_current_nutri*/ c_nmed_current_other_nmed), missing

//Hospital reimbursements
egen reimburse_current=rowtotal(repeat5*hosp_reimburse), missing
gen s_reimburse_current= reimburse_current*scalar

// for combined hospital stay costs choose maximum of reported total or sum of disaggregated costs
egen hosp_tot_med=rowtotal(repeat5*hosp_tot_med), missing
egen hosp_tot_nmed=rowtotal(repeat5*hosp_tot_nmed), missing

egen c_med_current=rowmax(c_med_current_dis hosp_tot_med)
replace c_med_current=c_med_current - reimburse_current

egen c_nmed_current=rowmax(c_nmed_current_dis hosp_tot_nmed)

gen test_flag1=.
replace test_flag1=1 if c_nmed_current_dis < hosp_tot_nmed & hosp_tot_nmed!=. /*4 changes*/
replace test_flag1=1 if c_nmed_current_dis==. & hosp_tot_nmed!=.              /*1 change*/

egen c_direct_current=rowtotal(c_med_current c_nmed_current)
egen hosp_total_all=rowtotal(repeat5*hosp_total_all), missing
replace hosp_total_all= hosp_total_all- reimburse_current

//If the total is larger than the sum of the medical and non-medical amounts, use the total
gen test_flag4=.
gen c_direct_current2=.
replace c_direct_current2= hosp_total_all if c_direct_current < hosp_total_all & hosp_total_all !=.
replace c_direct_current2= hosp_total_all if c_direct_current==. & hosp_total_all !=.
replace test_flag4=1 if c_direct_current < hosp_total_all & hosp_total_all !=.
replace test_flag4=1 if c_direct_current==. & hosp_total_all !=.
replace c_direct_current=c_direct_current2 if test_flag4==1

//Using the commented collapse command below, we split teh total into parts 
//collapse (sum) c_nmed_current c_med_current c_direct_current 
//c_nonmed_current is 38.2%, c_med_current is 61.8%
//also replace non non-medical total if totall all is greater than parts
replace c_nmed_current=.382 * c_direct_current if test_flag4==1 

drop c_direct_current2

foreach type in day cons radio lab proc med oth{
gen s_c_med_current_`type' = c_med_current_`type' * scalar
}

foreach type in travel_cost food /*nutri*/ other_nmed{
gen s_c_nmed_current_`type' = c_nmed_current_`type' * scalar
}

gen s_c_time_current=c_time_current * scalar
gen s_c_med_current=c_med_current * scalar
gen s_c_nmed_current=c_nmed_current * scalar
gen s_c_direct_current= c_direct_current * scalar

egen c_current= rowtotal(s_c_time_current s_c_direct_current), missing

/***************************************************************
 Costs for DOT and food costs during ambulatory care

 We will not need to use other patient info here to extrapolate
 future behavior. We can use treatement duration and DOT or not DOT
 to estimate number of DOT visits and costs remain constant per DOT visit.
 
 ***************************************************************/
//Transform time loss in hours instead of minutes therefore we don't divide by 60
// Time loss is valued following human capital approach
gen t_dot_per=dot_prov_time
gen c_dot_time=t_dot_per * hourly_wage
egen c_direct_dot_per=rowtotal(c_dot_food c_travel_dot c_dot_fee), missing

//Estimating number of visits in DOT throughout TB or MDR episode 
// Number of times going to DOT 
** OPTION 1: Simple extrapolation from current frequency (Option 2 or 3 is preferred!)
gen n_dot_visits_1=. if self_admin=="dot1" /* self-administered in both phases */
replace n_dot_visits_1=treat_duration*4.33*dot_times_week  if self_admin=="dot2" | self_admin=="dot3" /* DOT in both phases*/

** OPTION 2: current frequency and NTP protocol
//for patients in intensive: Current frequency (int) + NTP procol (cont)  
gen n_dot_visits_int_2 =.
replace n_dot_visits_int_2 = duration_int*4.33*dot_times_week if phase=="phase1" & (self_admin=="dot2" | self_admin=="dot3")
gen n_dot_visits_cont_2 =.
replace n_dot_visits_cont_2 = duration_cont*4.33*5 if phase=="phase1" & (self_admin=="dot2" | self_admin=="dot3") //frequency needs to be changed based on NTP protocol

//for patients in continuation: past frequency (int) + current frequency (cont)
replace n_dot_visits_int_2 = duration_int*4.33*dot_times_week_int if phase=="phase2" & (self_admin_int=="dot2" | self_admin_int=="dot3")
replace n_dot_visits_cont_2 = duration_cont*4.33*dot_times_week if phase=="phase2" & (self_admin=="dot2" | self_admin=="dot3")

//total number of visits
gen n_dot_visits_2 = n_dot_visits_int_2 + n_dot_visits_cont_2

** OPTION 3: Estimating frequency of DOTS visits for continuation phase
//for patients in intensive: Current frequency (int) + NTP procol (cont)  
gen n_dot_visits_int_3 =.
replace n_dot_visits_int_3 = duration_int*4.33*dot_times_week if phase=="phase1" & (self_admin=="dot2" | self_admin=="dot3")

gen n_dot_visits_cont_3 =.
sum dot_times_week if phase=="phase2",d
gen e_dot_times_week = r(mean) if phase=="phase1" & (self_admin=="dot2" | self_admin=="dot3")  //frequency for cont is estimated from the mean of DOTS visits for patients in cont
replace n_dot_visits_cont_3 = duration_cont*4.33*e_dot_times_week if phase=="phase1" & (self_admin=="dot2" | self_admin=="dot3")

//for patients in continuation: past frequency (int) + current frequency (cont)
replace n_dot_visits_int_3 = duration_int*4.33*dot_times_week_int if phase=="phase2" & (self_admin_int=="dot2" | self_admin_int=="dot3")
replace n_dot_visits_cont_3 = duration_cont*4.33*dot_times_week if phase=="phase2" & (self_admin_int=="dot2" | self_admin_int=="dot3") //frequency needs to be changed based on NTP protocol

//total number of visits
gen n_dot_visits_3 = n_dot_visits_int_3 + n_dot_visits_cont_3

**scripts go with OPTION 3
gen n_dot_visits = n_dot_visits_3

//Estimating time loss for all ambulatory care visits (in minutes, transformed dot_prov_time above)
gen t_dot=t_dot_per * n_dot_visits
replace t_dot=0 if t_dot_per==0 | t_dot_per==.
replace t_dot=0 if n_dot_visits==0 | n_dot_visits==.

//Estimating medical and non medical ambulatory care costs
gen c_med_dot= c_dot_fee*n_dot_visits
gen c_nmed_dot_travel= c_travel_dot*n_dot_visits
gen c_nmed_dot_food= c_dot_food*n_dot_visits
gen c_direct_dot=c_direct_dot_per *n_dot_visits

//Estimating total indirect costs using Human Capital approach
gen c_indirect_dot=c_dot_time *n_dot_visits

// Total for DOT costs
egen c_dot =rowtotal(c_indirect_dot c_direct_dot), missing

/****************************************************************
Costs of picking up drugs and food costs during ambulatory care

This section does not require any extrapolation as the questions
already assume a consistent utilization throughout phases.
****************************************************************/
** OPTION 1: Simple extrapolation from current frequency
gen n_pickup_total_1=. if drug_pickup=="no" /* no drug pickup visits */
replace n_pickup_total_1=treat_duration*4.33*drug_pickup_n  if drug_pickup=="yes" /* drug pickup for both phases*/

** OPTION 2: current frequency and NTP protocol (e.g. 1 per week for int and 1 per month for cont)
//for patients in intensive: Current frequency (int) + NTP procol (cont)  
gen n_pickup_int_2 =.
replace n_pickup_int_2 = duration_int*4.33*drug_pickup_n if phase=="phase1" & drug_pickup=="yes"
gen n_pickup_cont_2 =.
replace n_pickup_cont_2 = duration_cont*1 if phase=="phase1" & drug_pickup=="yes" //frequency needs to be changed based on NTP protocol

//for patients in continuation: past frequency (int) + current frequency (cont)
replace n_pickup_int_2 = duration_int*4.33 if phase=="phase2" & drug_pickup=="yes"
replace n_pickup_cont_2 = duration_cont*4.33*drug_pickup_n if phase=="phase2" & drug_pickup=="yes"

//total number of visits
egen n_pickup_total_2 = rowtotal(n_pickup_int_2 n_pickup_cont_2), missing

** OPTION 3: Estimating frequency of DOTS visits for continuation phase
//for patients in intensive: Current frequency (int) + NTP procol (cont)  
gen n_pickup_int_3 =.
replace n_pickup_int_3 = duration_int*4.33*drug_pickup_n if phase=="phase1" & drug_pickup=="yes"

gen n_pickup_cont_3 =.
sum drug_pickup_n if phase=="phase2",d
gen e_pickup_n_cont = r(mean) if phase=="phase1" & drug_pickup=="yes"  //frequency for cont is estimated from the mean of pickup visits for patients in cont
replace n_pickup_cont_3 = duration_cont*4.33*e_pickup_n_cont if phase=="phase1" & drug_pickup=="yes"

//for patients in continuation: past frequency (int) + current frequency (cont)
sum drug_pickup_n if phase=="phase1",d
gen e_pickup_n_int = r(mean) if phase=="phase2" & drug_pickup=="yes"  //frequency for int is estimated from the mean of pickup visits for patients in cont
replace n_pickup_int_3 = duration_int*4.33*e_pickup_n_int if phase=="phase2" & drug_pickup=="yes"
replace n_pickup_cont_3 = duration_cont*4.33*drug_pickup_n if phase=="phase2" & drug_pickup=="yes"

//total number of visits
egen n_pickup_total_3 = rowtotal(n_pickup_int_3 n_pickup_cont_3), missing

**scripts go with OPTION 3
gen n_pickup_total = n_pickup_total_3

 
// Pick up drug: direct non medical cost calculation (transport + food)
egen c_pickup_nmed_per=rowtotal(drug_pickup_lodge drug_pickup_cost drug_pickup_food), missing

// Pick up drug: direct medical cost calculation (fee)
gen c_pickup_med_per=drugpick_fee_amount

// Pick up drug: DM+DNM 
gen c_pickup_nmed = c_pickup_nmed_per * n_pickup_total
gen c_pickup_med = c_pickup_med_per * n_pickup_total

egen c_pickup_direct=rowtotal(c_pickup_med c_pickup_nmed), missing

// Pick up drug:for more detailed non-medical cost categories
gen c_pickup_nmed_accommodation=drug_pickup_lodge * n_pickup_total
gen c_pickup_nmed_travel=drug_pickup_cost * n_pickup_total
gen c_pickup_nmed_food=drug_pickup_food * n_pickup_total

//Indirect cost estimate (time) for pickup, using Human Capital Approach
gen t_pickup=.
replace t_pickup=(drug_pickup_time)* n_pickup_total
replace t_pickup=0 if drug_pickup_time==0 | drug_pickup_time==.
replace t_pickup=0 if n_pickup_total==0 | n_pickup_total==.

gen c_pickup_indirect=t_pickup * hourly_wage

// Pick up drug: total cost, direct plus indirect (human capital approach)
/* Total for pickup*/
egen c_pickup=rowtotal(c_pickup_direct c_pickup_indirect), missing

/*******************************************************************************************
  Cost during outpatient visits for medical follow-up (see the doctor or nurse, have tests)

*******************************************************************************************/
//per = per one visit
replace fu=. if fu < 0 
replace fu=0 if fu==.

//s = scaled up for phase and estimate the number of FU visit per month
gen s_fu_per =.
replace s_fu_per = fu * scalar / duration_int if phase=="phase1"
replace s_fu_per = fu * scalar / duration_cont if phase=="phase2"

/*Scripts for estimating the number of FU visits in the other phase or NTP protocol*/
**OPTION 1. Simple estimation 

gen s_fu_1 = s_fu_per * treat_duration

**OPTION 2. current frequency and NTP protocol (e.g. 2 per month for int and 1 per month for cont)
//for patients in intensive: Current frequency (int) + NTP procol (cont)  
gen s_fu_int_2 =.
replace s_fu_int_2 = s_fu_per * duration_int if phase=="phase1"
gen s_fu_cont_2 =.
replace s_fu_cont_2 = 1 * duration_cont if phase=="phase1" //frequency needs to be changed based on NTP protocol

//for patients in continuation: past frequency (int) + current frequency (cont)
replace s_fu_int_2 = 2 * duration_int if phase=="phase2"
replace s_fu_cont_2 = s_fu_per * duration_cont if phase=="phase2"

//total number of visits
egen s_fu_2 = rowtotal(s_fu_int_2 s_fu_cont_2), missing

** OPTION 3: Estimating frequency of DOTS visits for the other phase
//for patients in intensive: Current frequency (int) + from patient in cont (cont) 
gen s_fu_int_3 =.
replace s_fu_int_3 = s_fu_per * duration_int if phase=="phase1"

gen s_fu_cont_3 =.
sum s_fu_per if phase=="phase2", d
gen e_fu_per_cont = r(mean) if phase=="phase1"  //frequency for cont is estimated from the mean of FU visits for patients in cont
replace s_fu_cont_3 = e_fu_per_cont * duration_cont if phase=="phase1"

//for patients in continuation: mean from patients in int(int) + Current frequency (cont) 
sum s_fu_per if phase=="phase1", d
gen e_fu_per_int = r(mean) if phase=="phase2"  //frequency for cont is estimated from the mean of FU visits for patients in int
replace s_fu_int_3 = e_fu_per_int * duration_int if phase=="phase2"

replace s_fu_cont_3 = s_fu_per * duration_cont if phase=="phase2"

//total number of visits
egen s_fu_3 = rowtotal(s_fu_int_3 s_fu_cont_3), missing

**scripts go with OPTION 3
gen s_fu = s_fu_3

egen c_fu_nmed_per= rowtotal(c_travel_fu c_accom_fu), missing
egen c_fu_med_per= rowtotal(c_fees_fu c_radio_fu c_tests_fu c_proc_fu c_med_fu c_oth_med_fu c_oth_fu), missing

//more detailed medical and non-medical cost categories
gen c_fu_nmed_travel = c_travel_fu * s_fu
gen c_fu_nmed_accom = c_accom_fu * s_fu
gen c_fu_nmed= c_fu_nmed_per * s_fu
gen c_fu_med= c_fu_med_per * s_fu

//Direct medical and non-medical costs
egen c_fu_direct= rowtotal(c_fu_med c_fu_nmed), missing
gen t_fu = (travel_dur_fu)* s_fu
replace t_fu=0 if fu==0 | fu==.
replace t_fu=0 if travel_dur_fu==0 | travel_dur_fu==.
 
gen c_fu_indirect=t_fu* hourly_wage

/* Total for follow-up*/
egen c_fu=rowtotal(c_fu_direct c_fu_indirect), missing

/******************************************
  Costs for nutritional/food supplements 
******************************************/
/*OPTION 1: crude scaling*/
//assume 4.33 weeks per month. Treat duration is in months and amount reported per week
gen c_supp_1=(c_food_supp*4.33)*treat_duration
gen c_extra_1=(c_food_add*4.33)*treat_duration
egen c_food_1=rowtotal(c_supp_1 c_extra_1), missing

/*OPTION 2: Scaling within the current phase and imputation for the other phase (median)*/
//supp
gen c_supp_int_2=(c_food_supp*4.33)*duration_int if phase=="phase1"
gen c_supp_cont_2=(c_food_supp*4.33)*duration_cont if phase=="phase2"

sum c_supp_int_2 if phase=="phase1", d
replace c_supp_int_2 = r(p50) if phase=="phase2" & c_supp_cont!=.

sum c_supp_cont_2 if phase=="phase2", d
replace c_supp_cont_2 = r(p50) if phase=="phase1" & c_supp_int!=.

egen c_supp_2=rowtotal(c_supp_int_2 c_supp_cont_2), missing

//extra
gen c_extra_int_2=(c_food_add*4.33)*duration_int if phase=="phase1"
gen c_extra_cont_2=(c_food_add*4.33)*duration_cont if phase=="phase2"

sum c_extra_int_2 if phase=="phase1", d
replace c_extra_int_2 = r(p50) if phase=="phase2" & c_extra_cont!=.

sum c_extra_cont_2 if phase=="phase2", d
replace c_extra_cont_2 = r(p50) if phase=="phase1" & c_extra_int!=.

egen c_extra_2=rowtotal(c_extra_int_2 c_extra_cont_2), missing

//total
egen c_food_2=rowtotal(c_supp_2 c_extra_2), missing

**scripts go with OPTION 1
gen c_supp = c_supp_1
gen c_extra = c_extra_1

gen c_food = c_food_1

/****************************************************************************
 Costs for guardians - Only consider them if they lost income.
****************************************************************************/
//number of people * number of occasions * number of hours * hourly wage rate (human capital approach)
// Estimating caregiver wage. Option 1 is to give everyone minimum wage $115 per month
//Option 1: Replace caregiver hourly_wage with minimum wage if desired
gen caregiver_wage_1= .
replace caregiver_wage_1=40000/160 //40000 Tsh per month

//Option 2: Give caregiver an equal proportion of household income after deducting patient income
gen caregiver_wage_2=.
replace caregiver_wage_2 = (income_hh_pre - income_pre)/(hhsize_a - 1) if hhsize_a > 1
//curently in wage per month
replace caregiver_wage_2= caregiver_wage_2/160  /*now in hourly wage*/
replace caregiver_wage_2=0 if caregiver_wage_2 < 0 & caregiver_wage_2 !=.
sum caregiver_wage_2, d
replace caregiver_wage_2= r(p50) if caregiver_wage_2==. //50% percentile is 14081 VND

**script continues with OPTION 2
gen caregiver_wage = caregiver_wage_2

 //Caregiver time loss count in hours.
//DOT visits: time loss (hours)and time valuation (human capital approach)
gen t_guard_dot= guard_dot * n_dot_visits * t_dot_per
*replace t_guard_dot= guard_loi * n_dot_visits * t_dot_per if guard_loi !=. 
gen c_guard_dot=t_guard_dot* caregiver_wage if guard_dot_n==1

//Drug Pickups: time loss (hours) and time valuation (human capital approach)

gen t_guard_pickup= guard_drug * (t_pickup)
*replace t_guard_pickup= guard_loi  * (t_pickup) if guard_loi !=.
gen c_guard_pickup= t_guard_pickup * caregiver_wage if guard_drug_n==1

// Follow-up visits: time loss (hours) and time valuation (human capital approach)

gen t_guard_fu= guard_fu * s_fu * (travel_dur_fu)
*replace t_guard_fu= guard_loi * s_fu * (travel_dur_fu) if guard_loi !=. 
gen c_guard_fu= t_guard_fu * caregiver_wage if guard_fu_n==1

// Hospitalizations: time loss and time valuation. Used scaled hospitalizations.
gen t_guard_hosp= guard_hosp * s_t_current
*replace t_guard_hosp= guard_loi * s_t_current if guard_loi !=. 
gen c_guard_hosp=  t_guard_hosp * caregiver_wage if guard_hosp_n==1

//Total Caregiver time and indirect cost: dot, pick up, follow-up and hospitalisation
egen t_guard_tot = rowtotal(t_guard_dot t_guard_pickup t_guard_fu t_guard_hosp), missing
egen c_guard_tot = rowtotal(c_guard_dot c_guard_pickup c_guard_fu c_guard_hosp), missing
replace t_guard_tot=0 if t_guard_tot==.
replace c_guard_tot=0 if c_guard_tot==.

/***********************************************
           Dissaving
***********************************************/
/*
label var dissaving_tot "Total amount of savings used"
label var borrow_tot "Total amount borrowed"
label var asset_proceeds  "Total amount of assets sold"
*/
//add all types of dissaving
egen coping_amount= rowtotal(/*dissaving_tot*/ borrow_tot asset_proceeds), missing
label var coping_amount "Total amount for all types of coping"

//coping will be a dummy if any type of dissaving happens
gen coping=0
*replace coping=1 if dissavings==1
replace coping=1 if borrow==1
replace coping=1 if asset_sale==1

label var coping "Any type of dissaving experienced (0/1)"

/**********************
SOCIAL EFFECTS
**********************/
/*gen divorce=0
gen food_insecurity=0
gen job_loss=0
gen interrupted_school=0
gen social_excl=0
gen reloc=0

replace divorce=1 if strpos(social_effect, "divorce")> 0
replace food_insecurity=1 if strpos(social_effect, "food")> 0
replace job_loss=1 if strpos(social_effect, "job")> 0
replace interrupted_school=1 if strpos(social_effect, "school")> 0
replace interrupted_school=1 if dropout==1
replace social_excl=1 if strpos(social_effect, "excl")> 0
*/

//Any working days lost
gen days_lost=.
replace days_lost=1 if working_days_lost > 0 & working_days_lost !=.
replace days_lost=0 if working_days_lost == 0 

//any social effect
egen any_socialeffect = rowtotal(social_food_insec	social_divorce	social_lossofjob	social_dropout	social_exclusion	social_reloc days_lost),missing
replace any_socialeffect = 1 if any_socialeffect>1


/***********************************************
           Save dta file
***********************************************/
save TBPCS_iso3_2019_no_imp.dta, replace
