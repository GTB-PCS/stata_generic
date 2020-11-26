/*
Cleaning is unique to each country, but there are some common checks that 
this script can suggest to be done. The aim of this script is to 
a) Hasten and guide the data cleaning process
b) Enable the survey team to walk though key steps in assuring data quality
and c) to generate one common clean dataset from which basic demographic  
information can begin to be tabulated / output, even as the costs and related 
analysis is being discussed.

updated: 4.12.19 Peter Nguhiu (Changed variable name from 'today' to 
'date_int' to correspond with the generic tool's naming convention)
Last updated: 08.01.2020 PN, IGB (Reviewed drug_pickup_n variable content
converting from categorical choices to integer days, included csv export options
to support monitoring activities during survey)
*/

global path "Z:\Users\pnguhiu\Dropbox\GTB_PCS_script"
cd "$path"
* Replace this path and file name with the dta produced from TBPCS_cleaning.do
use "TBPCS_KEN_2017_raw.dta" , clear

** A. Check and Identify if there are duplicated records
duplicates report pt_register age facility date_diag 
* once the reason for duplication is confirmed, the duplicated records can be dropped
duplicates tag pt_register age facility date_diag, gen(flag_dup)
* output list for survey team to cross check. Including district / clusters, interviewer 
* ids and patient ids if possible. It's important to limit access to this 
* list (in line with privacy and confidentiality requirements)
preserve
	sort deviceid start
	keep if flag_dup >= 1
	keep  start end pt_register date_int district patientid age sex  ///
	 facility diag_place start_date int_name
	export delimited using ".\cleaning_records_for_review\Duplicate records for cross checking.csv", replace
restore

** in the example dataset, records 240, 242, 245, 571, 572 and 627 are identified 
* for dropping (based on start and end time for instance)
if c(filename) == "TBPCS_KEN_2017_raw.dta" {
	drop if _n == 240 | _n == 242 | _n == 245 | _n == 572 | _n == 627
}

drop flag_dup 
 

** Check eligibility: if patients have not been in current phase for at least 2 weeks.
preserve
	sort deviceid start
	keep if (phase_weeks_int < 2 | phase_weeks_con < 2)
	keep start end pt_register date_int district patientid age sex  ///
	 facility diag_place start_date phase phase_weeks_int phase_weeks_con int_name
	export delimited using ".\cleaning_records_for_review\Patients on less than 2 weeks current phase, for cross checking.csv", replace
restore
//drop if (phase_weeks_int < 2 | phase_weeks_con < 2)


* 08.01.2020 PN: Are there records with missing cruicial variables?
misstable summarize patient_id age facility_cat start_date mdr phase 

 
** B. Ensure that the date variables are accurate.  
* First Check if the dates were saved day first (DMY), or month first (MDY) 
list date_int in 1/5 
capture confirm string variable date_int // Check if it's string and if so, generate a date variable.
if _rc == 0 {
	rename date_int date_int_old
	gen date_int = date(substr(date_int_old,1,10), "DMY")
	order date_int, before(date_int_old)
	format date_int %tdDD-Mon-CCYY
	label var date_int "Date Of Interview"
}
histogram date_int
* Check on histogram if any record has an interview date outside the period of survey (these 
* would be piloting data mainly, but could also be errors in the keying in of data)
* upon confirmed, any such records can be dropped
//drop if date_int < date("01-May-2017","DMY") | date_int > date("30-Jun-2017","DMY")

* Clean Date of Diagnosis, Start Date and any other date variables
global date_vars date_diag start_date start_date_contphase 
describe $date_vars
foreach date_var in  $date_vars {
di "`date_var'"
capture confirm string variable `date_var' // Check if it's string and if so, generate a date variable.
if _rc == 0 {
	rename `date_var' `date_var'_old
	gen `date_var' = date(substr(`date_var'_old,1,10), "DMY")
	order `date_var', before(`date_var'_old)
	format `date_var' %tdDD-Mon-CCYY
}
}

* Check if any record has treatment start date older than 2 years from interview
* date. This would need further checks to confirm that such is still on treatment
list patientid date_diag start_date if start_date < (date_int - 365*2) 
* For record 861 there was an error in keying in start date. this can be corrected
replace start_date = date("21-Jan-2016", "DMY") if _n == 861

* Other checks can be done here e.g. diagnosis dates greater than one year before start date,
* diagnosis dates more recent than treatment start dates etc. These however need 
* a clear view of the TB treatment protocols in country (since for instance clinics
* may initiate treatment based on presumptive diagnosis as results from lab await)
list  patient_id age facility_cat date_diag if date_diag < (start_date - 365) 
list  patient_id age facility_cat date_diag if date_diag > start_date 


* B. Coding, and labelling of categorical variables. 
* First check if variable is a string variable, using  the confirm command
* If it's string (i.e. if command returns code 0), it can be encoded.
capture confirm string variable hiv // Check if it's string and if so, encode it.
if _rc == 0 {
	rename hiv hiv_old					// 
	replace hiv_old = strlower(hiv_old) //ensure all characters are lower case
	tab hiv_old  						// Check the levels and update the labels 
	label define hiv 1 "hiv_pos" 2 "hiv_neg" 3 "hiv_nd"  
	encode hiv_old, gen(hiv) label(hiv) noextend 
	order hiv, before(hiv_old)
	label variable hiv "HIV status"
}
tab hiv

capture confirm string variable sex // Check if it's string and if so, encode it.
if _rc == 0 {
	rename sex sex_old
	replace sex_old = strlower(sex_old)
	tab sex_old  						// Check the levels and update the labels 
	label define sex 1 "female" 0 "male"
	encode sex_old, gen (sex) label(sex) noextend 
	order sex, before(sex_old)
	label variable sex "Sex"
}
tab sex

capture confirm string variable tb_type // Check if it's string and if so, encode it.
if _rc == 0 {
	rename tb_type tb_type_old
	replace tb_type_old = strlower(tb_type_old)
	tab tb_type_old  						// Check the levels and update the labels 
	label define tb_type 1 "tb_type1" 2 "tb_type2" 3 "tb_type3"
	encode tb_type_old, gen (tb_type) label(tb_type) noextend 
	order tb_type, before(tb_type_old)
	label variable tb_type "TB Type"
}
tab tb_type

capture confirm string variable phase // Check if it's string and if so, encode it.
if _rc == 0 {
	rename phase phase_old
	replace phase_old = strlower(phase_old)
	tab phase_old  						// Check the levels and update the labels 
	label define phase 1 "phase1" 2 "phase2" 
	encode phase_old, gen (phase) label(phase) noextend 
	order phase, before(phase_old)
	label variable phase "Treatment phase"
}
tab phase

* 08.01.2020 PN: Drug Pickup is a categorical variable with choices tyipcally
* 1 - Every day, 2 - Every week, 3 - Every two weeks and 4 - Every month, 5 being other
capture confirm string variable drug_pickup_n // Check if it's string and if so, encode it.
if _rc == 0 {
	rename drug_pickup_n drug_pickup_n_old
	replace drug_pickup_n_old = strlower(drug_pickup_n_old)
	tab drug_pickup_n_old  // Check the levels and ensure the labels match
	label define drug_pickup_freq 1 "Every day" 2 "Every week" 3 "Every two weeks" 4 "Every month"
	encode drug_pickup_n_old, gen (drug_pickup_freq) label(drug_pickup_freq) noextend 
	order drug_pickup_freq, before(drug_pickup_n_old)
	label variable drug_pickup_freq "Drug pickup frequency"
}
tab phase
drop *_old

* 08.01.2020 PN: Important to convert drug_pickup_freq - a categorical variable to drug_pickup_n - a 
* continuous variable (days per week) so that it can be multiplied by expected weeks on treatment
* (in script 03) to give total days of drug pickup (n_pickup_int, n_pickup_cont)
gen drug_pickup_n = .
replace drug_pickup_n = 7 if drug_pickup_freq == 1
replace drug_pickup_n = 1 if drug_pickup_freq == 2
replace drug_pickup_n = 0.5 if drug_pickup_freq == 3
replace drug_pickup_n = 0.25 if drug_pickup_freq == 4
// Explore the variable drug_pickup_n_other to recover more pickup freq options
tab drug_pickup_n_other
replace drug_pickup_n = 0.125 if regexm(drug_pickup_n_other,"Every 2 months") //every 2 months.. adapt accordingly 

** Clean binary variables 
* This list checks variables that ought to be binary, and converts them accordingly.
* When modifying list, ensure there's a space separating variables from the 
* triple slash (///) 
/*
* For TZ, the binary variables are:
global binary_vars mdr participate current_hosp prev_hosp drug_pickup      ///
drug_pickup_fee food_supp guard_dot guard_drug guard_fu guard_hosp insurance       ///
electricity solar radio tv mobile fridge computer bicycle motorcycle car emp_main sp ///
vouchers house_tb dissavings borrow payback borrow_payback_start assetsale asset_income dropout
*/ 
global binary_vars mdr current_hosp prev_hosp      ///
 food_supp food_add radio television              ///
 sofaset cupboard dvd table clock electricity sp   ///
 vouchers ///
 social_effect0 social_effect1 social_effect2 ///
 social_effect3 social_effect4 social_effect5 social_effectother
 
* Please examine the list below to ensure that each variable 
* exists in your dataset, and has only two acceptable levels
codebook $binary_vars, c

foreach var of varlist $binary_vars {
// Check if it's already binary and if not, encode it.
capture confirm byte variable `var' 
if _rc != 0 {

	replace `var' = strlower(`var')
	gen byte `var'_new = .
	replace `var'_new = 1 if regexm(`var', "yes|true|include|1")
	replace `var'_new = 0 if regexm(`var', "no|false|0")
	label var `var'_new "`var'"
	order `var'_new, a(`var')
	
	label val `var'_new YesNo
	drop `var'
	rename `var'_new `var'
}
} 
**********************************
* Destring income and expenditure if they're string variables*
**********************************
** First check each reported income variable for string characters, replacing these with ""
//tab income_pre 

foreach var in income_pre income_hh_pre income_now income_hh_now {
capture confirm string variable `var'
if _rc == 0 {
	replace `var' = strlower(`var')
	replace `var' = subinstr(`var',",","",.) //commas & blank spaces need to be cleared (e.g 5,000 or 60 000)
	replace `var' = regexr(`var',"unknown|known|uknown|unkown|unknwn|notworking|not working|the","")
	destring `var', replace
	}
}

codebook income_pre income_hh_pre income_now income_hh_now, c

* Expenditure variables
//global ex_var ex_educ ex_health ex_farm ex_food ex_cloth ex_utility ex_fuel ex_house ex_capital ex_rent ex_tax ex_drink ex_debt ex_transport ex_repair ///
//ex_stationery ex_cosme ex_deposit ex_loss ex_gamble ex_donation ex_legal ex_personal ex_other ex_other_s ///

global ex_weekly exp_weekly_oilsnfats exp_weekly_cereals exp_weekly_livestock ///
 exp_weekly_fish exp_weekly_meat exp_weekly_sugar exp_weekly_bread /// 
 exp_weekly_spices exp_weekly_vegetables exp_weekly_fruits exp_weekly_roots /// 
 exp_weekly_softdrinks exp_weekly_alcoholnsedatants exp_weekly_totalweeklycosts /// 
 exp_weekly_totalcostsnoitemise 
global ex_monthly exp_monthly_cosmetics exp_monthly_detergentnsoap /// 
 exp_monthly_hairdressing exp_monthly_rent exp_monthly_electricityfee /// 
 exp_monthly_water exp_monthly_kerosene exp_monthly_telephone exp_monthly_transport /// 
 exp_monthly_charcoal exp_monthly_firewood exp_monthly_cookinggas /// 
 exp_monthly_domesticworkersala exp_monthly_remittances exp_monthly_sanitarytowels /// 
 exp_monthly_othercosts exp_monthly_totalmontlhycosts exp_monthly_approxcostsitemise
global ex_annual exp_annual_education exp_annual_maintenancenrepair /// 
 exp_annual_clothingnwear exp_annual_weddingndowry exp_annual_funeral /// 
 exp_annual_capitalexpenditure exp_annual_otherexpenditure exp_annual_totalexpenditure /// 
 exp_annual_approxnonitemised
global other_costs drug_pickup_fee_amount voucher_travel voucher_food voucher_other 
 
foreach var of varlist $ex_weekly $ex_monthly $ex_annual $other_costs {
capture confirm string variable `var'
if _rc == 0 {
	replace `var' = strlower(`var')
	replace `var' = subinstr(`var',",","",.) //commas & blank spaces need to be cleared (e.g 5,000 or 60 000)
	replace `var' = regexr(`var'," ","") //blank space is character and needs to be cleared (eg 60 000)
	replace `var' = regexr(`var',"unknown|known|uknown|unkown|unknwn|notworking|not working|the","")
	destring `var', replace
}
}

** Clean weeks before diagnosis. 


** Clean hours_worked_pre
* Clear outlier values for hours_worked_pre: can't have more than 168 h per week
preserve
	sort today pt_register
	keep if hours_worked_pre> 168
	keep pt_register age facility_cat hours_worked_pre int_name
	export delimited using ".\cleaning_records_for_review\Patients with large hours worked for cross checking.csv", replace
restore
replace hours_worked_pre = . if hours_worked_pre > 168 
replace hours_worked_pre = . if hours_worked_pre == 0 


****************************
* Conduct limit checks on time and cost variables
****************************
* Are the treatment durations for intensive and continuation phases in line with 
* protocol? Identify those records outside the protocol's limits.
codebook treat_duration* if mdr, c
codebook treat_duration* if !mdr, c
//Ines added histograms
histogram treat_duration_int if mdr
histogram treat_duration_con if mdr
histogram treat_duration_int if !mdr
histogram treat_duration_con if !mdr
 
preserve
	sort pt_register mdr
	keep if treat_duration_int > 2.1 & treat_duration_int !=.
	keep if mdr == 0
	keep mdr phase treat_duration_int pt_register patient_id age facility_cat date_diag start_date int_name
	/*export delimited using ".\cleaning_records_for_review\large intensive phase duration_ds.csv", replace*/
restore
 
 //DS duration - phase 2 export outliers

preserve
	sort pt_register mdr
	keep if treat_duration_con> 4.1 & treat_duration_con !=.
	keep if mdr == 0
	keep mdr phase treat_duration_con pt_register patient_id age facility_cat date_diag start_date int_name
	/*export delimited using ".\cleaning_records_for_review\large continuation phase duration_ds.csv", replace*/
restore

// MDR duration - phase 1export outliers

preserve
	sort pt_register mdr
	keep if treat_duration_int > 8 & treat_duration_int !=.
	keep if mdr == 1
	keep mdr phase treat_duration_int pt_register patient_id age facility_cat date_diag start_date int_name
	/*export delimited using ".\cleaning_records_for_review\large intensive phase duration_dr.csv", replace*/
restore
 
// MDR duration - phase 2 export outliers

preserve
	sort pt_register mdr
	keep if treat_duration_con > 12.1 & treat_duration_con!=.
	keep if mdr == 1
	keep mdr phase treat_duration_con pt_register patient_id age facility_cat date_diag start_date int_name
/*export delimited using ".\cleaning_records_for_review\large continuation phase duration_dr.csv", replace*/
restore 
  
* In this example, some values need correction. 
* On discussion with NTP, these were corrected as per protocol 
replace treat_duration_int = 2 if !mdr & treat_duration_int < 2
replace treat_duration_con = 4 if !mdr & treat_duration_con < 4

replace treat_duration_int = 8 if mdr & treat_duration_int < 8
replace treat_duration_con = 12 if mdr & treat_duration_con < 12



** Pre-treatment variables ( before diagnosis, repeated items)
* Check if it's truly taken more than one year to diagnosis for instance..
list weeks_before_tx if weeks_before_tx > 52 
preserve
	sort pt_register mdr
	keep if weeks_before_tx > 52 & weeks_before_tx!=.
	keep mdr weeks_before_tx pt_register patient_id age facility_cat date_diag start_date int_name
	/*export delimited using ".\cleaning_records_for_review\large values for weeks before treatment.csv", replace*/
restore 
replace weeks_before_tx =. if weeks_before_tx >52  // Note how many records are affected

* Time variables - check if travel times (in hours) are greater than 8 hrs
codebook repeat_4travel_time_* , c
codebook repeat_4visit_time_* , c
** The right extremes ought to be discussed (are these travel and visit times feasible?)

* Cost variables - check if costs are reasonable and not extreme
codebook repeat_4* , c

** Current phase, hospitalization
* Length of stay in hospital (hosp_los) is measured in days
codebook repeat_5hosp_los_* , c
* produce a list of records with longer days hospitalised than actual current phase days
preserve
	sort deviceid start
	gen flag_los = 1 if repeat_5hosp_los_1 > (phase_weeks_int * 7) & phase == 1
	replace flag_los = 1 if repeat_5hosp_los_1 > (phase_weeks_con * 7) & phase == 2
	keep if flag_los >= 1
	keep  start end pt_register date_int district patientid age sex  ///
	 facility diag_place start_date phase_weeks*  repeat_5hosp_los_*
	/*export delimited using ".\cleaning_records_for_review\Long Hospital stay records for cross checking.csv", replace*/
restore

* Travel time - check if travel times (in hours) are greater than 8 hrs
codebook repeat_5hosp_travel_1 , c //Check for each repeat variable
preserve
	sort deviceid start
 	keep if repeat_5hosp_travel_1 > 8 & repeat_5hosp_travel_1 !=.
	keep pt_register today place patient_id age sex  ///
	 facility_cat diag_place start_date phase_days repeat_5hosp_travel_1
	/*export delimited using ".\cleaning_records_for_review\Large hosp travel times for cross checking.csv", replace*/
restore

* Cost variables - check if costs are reasonable and not extreme. This is harder to do since
* Hospitalization costs may actually be high
codebook repeat_5* , c


 

* reported ambulatory times and costs (DOT, Medical Followup, drug pickup)
*Times: check extremes - could they have been reported in minutes instead of hours?
codebook dot_prov_time drug_pickup*time fu, c
preserve
	sort deviceid start
 	keep if (dot_prov_time !=. & dot_prov_time >=5 | drug_pickup_time  !=. & drug_pickup_time >=3 | fu !=. & fu >=2)
	keep dot_prov_time fu pt_register today place patient_id age sex drug_pickup_time ///
	 facility_cat diag_place start_date phase_days int_name
	/*export delimited using ".\cleaning_records_for_review\Large ambulatory time variables for cross checking.csv", replace*/
restore

* 08.01.2020 PN/IGB: Check if there are records with high facility DOT and high facility pickup frequencies
preserve
	sort today pt_register
	keep if self_admin == "dot3" & regexm(dot_prov2, "1") & drug_pickup_n == 1 //On dot3 with dot_provider = hospital, but also reporting more than weekly drug_pickup
	keep pt_register patient_id age facility_cat int_name self_admin dot_prov2 dot_times_week dot_prov_time drug_pickup_n_days drug_pickup_time  
	//export delimited using ".\cleaning_records_for_review\likely_doublecounting_drug_pickup_freq_with_dot.csv", replace

restore
* Costs: check extremes
codebook c_dot_travel c_dot_fee c_dot_food c_travel_fu  ///
 c_accom_fu c_fees_fu c_radio_fu c_tests_fu c_oth_tests_fu c_med_fu ///
 c_oth_med_fu c_oth_fu c_food_supp c_food_add, c
 


saveold "$path\TBPCS_KEN_2017_cleaned.dta", version(13)
