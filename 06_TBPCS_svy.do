/* Generic PCS script 
STEP 6. survey adjustment
Last updated: 5/24/2020 Takuya Yamanaka */

set more off
/*
cd "~\Dropbox\10.GTB\1.PCS_generic"
//loading dta file from step.3
use "TBPCS_iso3_2019_imputed.dta", clear
*/

use "C:\Users\Takuya\Dropbox\10.GTB\Working folder Taku-Nobu\Data review PNG TBPCS\PNG_TB_PCS_24May2020_8cat.dta", clear

****************************************
* creating weight variable and set svy *
****************************************
// results comparison with simple analysis: using weight = 0 >> This is to check weighting is properly working
gen weight0 = 1
svyset [pweight=weight0]
svy: prop cc1
svy: prop cc1, over(mdr)
// results from above should be the same as that from simple analysis without weighting

*******************************************************
* svy adjustment for under/over enrolment in each psu *
*******************************************************
// define primary sampling unit in the survey
gen psu = District	

// take the planned # of enrolment in each psu: from each country's protocol
gen  npro  = 25 // from protocol: in PNG, total sample size = 1000 = 40cluster(district)*25 planned enrolment/psu
replace npro = 50 if District=="Moresby North East"|District=="Moresby North West" // for districts with 2 clusters
replace npro = 75 if District=="Moresby South"|District=="Lae" // for districts with 3 clusters
replace npro = 100 if District=="Talasia" // for districts with 4 clusters


// calculate actual # of enrolment in the survey in each psu
gen  obs   = 1
egen nact  = count(obs), by (District)

// create weight variable
//For example, if a cluster only enrolled 20 patients, failing to enroll 25 patients as per protocol, the weight value will be 1.25. This mean that the individual observations in this cluster will have 1.25 times of weight so that 20 patients can represent effectively 25 patients
gen weight = npro/nact
gen nsvy = nact*weight

/*
// additional weight for DS/DR
qui count if mdr==1 | mdr==0
local tot=r(N)
gen tot = `tot'

qui count if mdr==1
local dr=r(N)
gen dr = `dr'

qui count if mdr==0
local ds=r(N)
gen ds = `ds'

gen p_dr_sample = dr/tot    // % of DR in survey sample     is 3.2%
gen p_dr_cn2018 = 449/74692 // % of DR in case notification is 0.6%: from global TB database
gen p_ds_sample = ds/tot
gen p_ds_cn2018 = 1- p_dr_cn2018

gen weight2 = .
replace weight2 = p_dr_cn2018/p_dr_sample if mdr==1 
replace weight2 = p_ds_cn2018/p_ds_sample if mdr==0
summ weight2 //
*/

// svyset uisng psu and weight variables
svyset District [pweight = weight]
tab District weight // you can see the weight for districts with less enrolments than plan is more than 1.0

/*
// multiple weights
svyset district, weight(weight) || mdr, weight(weight2)
*/

//Following script generates results with svy either by mean/median: using variables names defined in generic scripts 03&04
//********************************************************************************************************
* generating results with svy * please change/add/remove variables according to data and preference etc *
*********************************************************************************************************//
gen age_c=age
label variable age_c "Age group"
recode age_c min/14=1 15/24=2 25/34=3 35/44=4 45/54=5 55/64=6 65/max=7

************************************
* demographic variables
************************************
// categoricals
foreach var of varlist sex age_c employ_before emp_main educ_level insurance {
svy: tab `var' mdr, pearson ci per col
}

// continuous
// by mean
foreach var of varlist age hhsize income_hh_pre_annual{ 
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
// function for finding median using svy is not preinstalled in stata. If you need to use, please type the command ". findit epctile", and then install the package from a pop-up
foreach var of varlist age hhsize income_hh_pre_annual{ 
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

** various household income definitions: pre/now & individual/household
foreach var of varlist income_hh_pre_annual income_hh_now_annual income_pre_annual income_now_annual{ 
svy: mean `var'
svy: mean `var', over(mdr)
}

foreach var of varlist income_hh_pre_annual income_hh_now_annual income_pre_annual income_now_annual{ 
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

************************************
// crinical variables
************************************
// categoricals
foreach var of varlist tb_type phase hiv place_diag facility_type self_admin self_admin_int current_hosp delay {
svy: tab `var' mdr, pearson ci per col
}

// continuous
// by mean
foreach var of varlist weeks_before_tx prev_hosp_times{ 
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of varlist weeks_before_tx prev_hosp_times{ 
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

************************************
// # of facility visits
************************************
// by mean
foreach var of varlist visit_before n_dot_visits n_pickup_total s_fu { 
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of varlist visit_before n_dot_visits n_pickup_total s_fu { 
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

************************************
// Lost time
************************************
// by mean
foreach var of t_before t_dot t_pickup t_fu t_current t_guard_dot t_guard_pickup t_guard_fu t_guard_hosp t_guard_tot  { 
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of t_before t_dot t_pickup t_fu t_current t_guard_dot t_guard_pickup t_guard_fu t_guard_hosp t_guard_tot  { 
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}



************************************
// patient costs
************************************
** Before diagnosis
// by mean
foreach var of varlist c_med_before_dis c_nmed_before_dis c_nmed_before_travel /*c_nmed_before_accomodation*/ c_nmed_before_food c_direct_before {
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of varlist c_med_before_dis c_nmed_before_dis c_nmed_before_travel /*c_nmed_before_accomodation*/ c_nmed_before_food c_direct_before { 
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

** After diagnosis: direct medical
foreach var of varlist c_med_dot c_pickup_med c_fu_med c_med_hosp c_medical_after {
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of varlist c_med_dot c_pickup_med c_fu_med c_med_hosp c_medical_after {
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

** After diagnosis: direct non-medical
foreach var of varlist cat_current_travel cat_current_accommodation cat_current_food cat_current_nutri c_nmed_after {
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of varlist cat_current_travel cat_current_accommodation cat_current_food cat_current_nutri c_nmed_after {
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}

** Total/subtotal costs
foreach var of varlist cat_med cat_nmed cat_direct income_diff pct1_num {
svy: mean `var'
svy: mean `var', over(mdr)
}

// by median
foreach var of varlist cat_med cat_nmed cat_direct income_diff pct1_num {
epctile `var', p(50) over(mdr) svy           
epctile `var', p(50) svy
}
*/
***********************************************
// % of catastrophic costs and cost drivers
***********************************************
// catastrophic costs
svy: prop cc1, over(mdr)
svy: prop cc1 if mdr==1
svy: prop cc1 if mdr==0

svy, subpop(mdr): proportion  cc1 
// both of codes above should show the same results
svy: prop cc1



// raw data for pie chart: using means
foreach var of varlist cat_current_med cat_current_travel cat_current_accomodation cat_current_food cat_current_nutri cat_current_indirect{ 
svy: mean `var'
svy: mean `var', over(mdr)
}

***********************************************
// Coping mechanism
***********************************************
** categoricals
foreach var of varlist /*dissavings*/ borrow asset_sale coping {
svy: tab `var' mdr, pearson ci per col
}


***********************************************
// Social consequences and perceived impact
***********************************************
** categoricals 
foreach var of varlist social_no social_food_insec social_divorce social_lossofjob social_dropout social_exclusion social_reloc social_other cope_impact {
svy: tab `var' mdr, pearson ci per col
}


***********************************************
// Social protection and vouchers
***********************************************
** categoricals 
foreach var of varlist sp vouchers sp_type voucher_type {
svy: tab `var' mdr, pearson ci per col
}

***********************************************
// Risk factor analysis: logistic regression 
// no stepwise like function is developed within svyset command: Reason is written in the link below
// https://www.stata.com/support/faqs/statistics/stepwise-regression-with-svy-commands/
***********************************************
// univariate: categoricals
foreach var of varlist age_c mdr hh_quintile current_hosp delay /*sex educ_level facility_type phase self_admin*/ {
svy: logistic cc1 i.`var'  
}

// univariate: numeric
foreach var of varlist age hhsize {
svy: logistic cc1 `var'  
}

// multivariate: *please change variables according the results of univariate etc
svy: logistic cc1 i.mdr hhsize ib(5).hh_quintile i.delay



