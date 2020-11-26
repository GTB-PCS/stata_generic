/* Generic PCS script 
STEP 5. Tabulation and visualization
Last updated: 18.11.19 I. Garcia Baena; October 2, 2019 Takuya Yamanaka */


set more off
cd "~\Dropbox\10.GTB\1.PCS_generic"
//loading dta file from step.3
use "TBPCS_iso3_2019_imputed.dta", clear

*******************************
* Categorical vars for tables *
*******************************
foreach var of varlist ///
facility_type sex tb_type  treat_group_nmdr treat_group_mdr phase hiv self_admin ever_edu educ_level employ_before employ_now cope_impact ///
{
gen t_`var' = `var'
}

replace t_treat_group_nmdr = t_treat_group_mdr if t_treat_group_nmdr == ""
drop t_treat_group_mdr
rename t_treat_group_nmdr t_treat_group

replace t_educ_level = t_ever_edu if t_educ_level == ""
drop t_ever_edu
rename t_educ_level t_educ

foreach var of varlist ///
t_facility_type t_sex t_tb_type t_treat_group t_phase t_hiv t_self_admin t_educ t_employ_before t_employ_now t_cope_impact ///
{
replace `var' = "0" if `var' == "female" | `var' == "hiv_neg" | `var' == "no" | `var' == "educ1" | `var' == "disp_pub"
replace `var' = "1" if `var' == "male" | `var' == "tb_type1" | `var' == "tx_gp_mdr1" | `var' == "tx_gp_nmdr1" | `var' == "phase1" | `var' == "hiv_pos" | `var' == "dot1" | `var' == "educ2" | `var' == "educ3" | `var' == "educ4" | `var' == "full" | `var' == "health_centre_pub" | `var' == "cope_impact1"
replace `var' = "2" if `var' == "tb_type2" | `var' == "tx_gp_mdr2" | `var' == "tx_gp_nmdr2" | `var' == "phase2" | `var' == "hiv_unk" | `var' == "dot2" | `var' == "educ5" | `var' == "educ6" | `var' == "educ7" | `var' == "part" | `var' == "short" | `var' == "district_hosp_pub" | `var' == "regional_hosp_pub" | `var' == "zonal_hosp_pub" | `var' == "national_hosp_pub" | `var' == "cope_impact2"
replace `var' = "3" if `var' == "tb_type3" | `var' == "tx_gp_mdr3" | `var' == "tx_gp_mdr4" | `var' == "tx_gp_mdr5" | `var' == "tx_gp_nmdr3" | `var' == "tx_gp_nmdr4" | `var' == "dot3" | `var' == "educ8" | `var' == "educ9" | `var' == "unemploy_seek" | `var' == "unemploy_noseek"| `var' == "unable_sick"| `var' == "unable_disable" | `var' == "disp_ngo" | `var' == "disp_priv" | `var' == "cope_impact3"
replace `var' = "4" if `var' == "tx_gp_mdr6" | `var' == "tx_gp_nmdr5" | `var' == "student" | `var' == "homemaker" | `var' == "health_centre_ngo" | `var' == "health_centre_priv" | `var' == "cope_impact4"
replace `var' = "5" if `var' == "hosp_ngo" | `var' == "ref_hosp_ngo" | `var' == "zonal_hosp_ngo" | `var' == "hosp_priv" | `var' == "ref_hosp_priv" | `var' == "zonal_hosp_priv"
replace `var' = "9" if `var' == "other"
destring `var', force replace
}

gen t_insurance =0
replace t_insurance = 1 if ins_type1==1
replace t_insurance = 2 if ins_type2==1
replace t_insurance = 3 if ins_type3==1
replace t_insurance = 4 if ins_type4==1
replace t_insurance = 5 if ins_type5==1
replace t_insurance = 6 if ins_type6==1

gen age_0_14 = 0
replace age_0_14=1 if age<15
gen age_15_24 = 0
replace age_15_24=1 if age>=15 & age<25
gen age_25_34 = 0
replace age_25_34=1 if age>=25 & age<35
gen age_35_44 = 0
replace age_35_44=1 if age>=35 & age<45
gen age_45_54 = 0
replace age_45_54=1 if age>=45 & age<55
gen age_55_64 = 0
replace age_55_64=1 if age>=55 & age<65
gen age_65plus = 0
replace age_65plus=1 if age>=65

gen age_cat = 0
replace age_cat = 1 if age<15
replace age_cat = 2 if age>=15 & age<25
replace age_cat = 3 if age>=25 & age<35
replace age_cat = 4 if age>=35 & age<45
replace age_cat = 5 if age>=45 & age<55
replace age_cat = 6 if age>=55 & age<65
replace age_cat = 7 if age>=65


//define labels
#delimit ;
;
* yes_no;
label define yes_no
	0 No
	1 Yes
;
* male_female;
label define sex
	0 Female
	1 Male
;
* facility;
label define facility
	0 disp_pub
	1 health_centre_pub
	2 hosp_pub
	3 disp_ngo_priv
	4 health_centre_ngo_priv
	5 hosp_ngo_priv
	9 other
;
* TB type;
label define tb_type
	1 "PTB-BC"
	2 "PTB-CD"
	3 EPTB
;
* TB treatment group;
label define tb_group
	1 new
	2 relapse
	3 retreatment
	4 other
;
* TB treatment phase;
label define tb_phase
	1 intensive
	2 continuation
;
* HIV status;
label define hiv
	0 hiv_neg
	1 hiv_pos
	2 hiv_unk
;
* DOT;
label define dot
	1 self_admin
	2 home_dot 
	3 facility_dot
;
* Education level;
label define educ
	0 no_educ
	1 pre_primary
	2 secondary
	9 other
;
* Employment status;
label define employ
	1 full_time
	2 part_short
	3 unemploy_unable 
	4 student_home
	9 other
;
* insurance;
label define insu
	0 no_insu
	1 NHIF
	2 NSSF
	3 CHIF 
	4 TIKA
	5 Priv
	6 "don't know"
;
* Impact;
label define impact
	1 Richer
	2 Unchanged
	3 Poorer
	4 "Much poorer"
;
#delimit cr

//label on vars
label values t_facility_type facility
label values t_sex sex
label values t_tb_type tb_type
label values t_treat_group tb_group
label values t_phase tb_phase
label values t_hiv hiv
label values t_self_admin dot
label values t_educ educ
label values t_employ_before employ
label values t_employ_now employ
label values t_insurance insu
label values t_cope_impact impact

foreach var of varlist ///
mdr electricity	tv	motorcycle	radio	bicycle	sew	mobile	fridge	car	watch	bank mdr guard_dot	guard_dot_n	guard_drug	guard_drug_n	guard_fu	guard_fu_n	guard_hosp	guard_hosp_n borrow asset_sale current_hosp prev_hosp insurance sp vouchers ///
{
label values `var' yes_no
}

*******************************
* Continuous vars for tables *
*******************************
egen total_visits = rowtotal(n_visit_before n_dot_visits n_pickup_total s_fu), missing /*IGB replaced visits_before with n_visits_before on 18.11.19 please double check prior to use*/

/***********************************************
           Save dta file
***********************************************/
save TBPCS_iso3_2019_output.dta, replace


/******************************
* table for categorical vars *
******************************/
/*Overall*/
use "TBPCS_iso3_2019_output", clear
	tempname memhold // defining temporary file name "memhold"
	postfile `memhold' str50 var_cat cat n count using "TBPCS_iso3_2019_output1_cat_overall", replace //defining var names and file name for outputs using temporary file "memhold"
		local vars /// choosing vars from dataset for outputs
		"t_facility_type t_sex t_tb_type mdr t_treat_group t_phase t_hiv t_self_admin t_educ t_employ_before t_employ_now t_insurance borrow asset_sale coping current_hosp prev_hosp insurance sp vouchers social_food_insec	social_divorce	social_lossofjob	social_dropout	social_exclusion social_reloc days_lost any_socialeffect t_cope_impact  age_0_14	age_15_24	age_25_34	age_35_44	age_45_54	age_55_64	age_65plus below_poverty"
		foreach var_cat of local vars { //for each vars the scripts berow will be looped
		foreach cat of numlist 0 1 2 3 4 5 6 9 { // for categories defined here, the scripts berow will be looped /*make sure categories defined here cover all the categorical variables you choose above
			disp "`varname'" // show variable name
			qui count // count observation
			local n=r(N) // save observation as "n"
			qui count if `var_cat'==`cat' // count observation by category for each variables in vars
			local count=r(N) // save observation in each category as "count"
			post `memhold' ("`var_cat'") (`cat') (`n') (`count')  // post saved variable name, category name, n and count into memhold
		}
		}
		postclose `memhold'  // close memhold

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output1_cat_overall", clear
	
	drop if count==0 // drop if no observation
	gen prop = count/n // calc %
	
	local vars "n count"
	foreach x of local vars {
		tostring `x', format(%5.0f) force replace // changing from numeric to string for "n" and "count"
		}
	
	tostring prop, format(%5.3f) force replace
	destring prop, force replace
	replace prop=prop*100
	tostring prop, format(%5.1f) force replace
	gen per ="%"
	egen prop_per = concat(prop per)
	
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen n_prop = concat(beg prop_per end)
	keep var_cat cat n count prop_per n_prop 
	order var_cat cat n count prop_per n_prop 
	
	save "TBPCS_iso3_2019_output1_cat_overall", replace
	export excel using "TBPCS_iso3_2019_output1_cat_overall.xlsx", firstrow(variables) replace

/*by DS and DR*/
use "TBPCS_iso3_2019_output", clear
	tempname memhold
	postfile `memhold' str50 var_cat mdr cat n count p_chi p_exact using "TBPCS_iso3_2019_output2_cat_dsdr", replace
		local vars ///
		"t_facility_type t_sex t_tb_type mdr t_treat_group t_phase t_hiv t_self_admin t_educ t_employ_before t_employ_now t_insurance borrow asset_sale coping current_hosp prev_hosp insurance sp vouchers  social_food_insec	social_divorce	social_lossofjob	social_dropout	social_exclusion social_reloc days_lost any_socialeffect t_cope_impact  age_0_14	age_15_24	age_25_34	age_35_44	age_45_54	age_55_64	age_65plus below_poverty"
		foreach var_cat of local vars {
		foreach mdr of numlist 0 1 {
		foreach cat of numlist 0 1 2 3 4 5 6 9 {
			disp "`varname'"
			qui count if mdr==`mdr'
			local n=r(N)
			qui count if `var_cat'==`cat' & mdr==`mdr'
			local count=r(N)
			qui tab `var_cat' mdr, r chi2 exact
			local p_chi=r(p)
			local p_exact=r(p_exact)
			post `memhold' ("`var_cat'") (`mdr') (`cat') (`n') (`count') (`p_chi') (`p_exact')
		}
		}
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output2_cat_dsdr", clear
	
	label define mdr 0 "DS-TB" 1 "DR-TB" 
	label values mdr mdr
	
	drop if count==0	
	gen prop = count/n
	
	local vars "n count"
	foreach x of local vars {
		tostring `x', format(%5.0f) force replace
		}
	
	tostring prop, format(%5.3f) force replace
	destring prop, force replace
	replace prop=prop*100
	tostring prop, format(%5.1f) force replace
	gen per ="%"
	egen prop_per = concat(prop per)
	
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen n_prop = concat(beg prop_per end)
	
	replace p_chi=. if mdr==0
	tostring p_chi, format(%5.3f) force replace
	replace p_chi="<0.001" if p_chi=="0.000"
	
	replace p_exact=. if mdr==0
	tostring p_exact, format(%5.3f) force replace
	replace p_exact="<0.001" if p_exact=="0.000"
	
	keep var_cat mdr cat n count prop_per n_prop p_chi p_exact
	order var_cat mdr cat n count prop_per n_prop p_chi p_exact
	
	egen varname = concat(var_cat cat)
	gen sort =.
/*if you would like to have table with a specific order of the variables, please define order here*/
/*Otherwise, the order of the variables will be alphabetic order after reshaping from long to wide form below*/
/*	replace sort = 0 if var_cat=="t_sex"
	replace sort = 1 if var_cat=="t_facility_type"
	etc */
	  
	reshape wide n count prop_per n_prop p_chi p_exact, i(varname) j(mdr)
//	sort sort cat
	keep varname cat n0 count0 n_prop0 n1 count1 n_prop1 p_chi1 p_exact1
	order varname cat n0 count0 n_prop0 n1 count1 n_prop1 p_chi1 p_exact1
	
	save "TBPCS_iso3_2019_output2_cat_dsdr", replace
	export excel using "TBPCS_iso3_2019_output2_cat_dsdr.xlsx", firstrow(variables) replace

/*coping mechanism by hh income quintile*/
use "TBPCS_iso3_2019_output", clear
	tempname memhold
	postfile `memhold' str50 var_cat quin cat n count using "TBPCS_iso3_2019_output2-2_cope", replace
		local vars ///
		"borrow asset_sale coping sp vouchers  social_food_insec	social_divorce	social_lossofjob	social_dropout	social_exclusion social_reloc days_lost any_socialeffect t_cope_impact"
		foreach var_cat of local vars {
		foreach quin of numlist 1 2 3 4 5 {
		foreach cat of numlist 0 1 2 3 4 5{
			disp "`varname'"
			qui count if hh_quintile==`quin'
			local n=r(N)
			qui count if `var_cat'==`cat' & hh_quintile==`quin'
			local count=r(N)
			post `memhold' ("`var_cat'") (`quin') (`cat') (`n') (`count') 
		}
		}
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output2-2_cope", clear
	
	label define quin 1 "poorest" 2 "less poor" 3 "average" 4 "less wealthy" 5 "wealthiest" 
	label values quin quin
	
	drop if count==0	
	gen prop = count/n
	
	local vars "n count"
	foreach x of local vars {
		tostring `x', format(%5.0f) force replace
		}
	
	tostring prop, format(%5.3f) force replace
	destring prop, force replace
	replace prop=prop*100
	tostring prop, format(%5.1f) force replace
	gen per ="%"
	egen prop_per = concat(prop per)
	
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen n_prop = concat(beg prop_per end)
		
	egen varname = concat(var_cat cat)
	//egen grpname = concat(quin cat)
	//destring grpname, force replace	
	drop if cat==0
	keep var_cat quin n count prop_per n_prop varname
	order var_cat quin n count prop_per n_prop varname

/*if you would like to have table with a specific order of the variables, please define order here*/
/*Otherwise, the order of the variables will be alphabetic order after reshaping from long to wide form below*/
/*	gen sort =.
	replace sort = 0 if var_cat=="t_sex"
	replace sort = 1 if var_cat=="t_facility_type"
	etc */
	reshape wide n count prop_per n_prop, i(varname) j(quin)
//	sort sort cat
	
	save "TBPCS_iso3_2019_output2-2_cope", replace
	export excel using "TBPCS_iso3_2019_output2-2_cope.xlsx", firstrow(variables) replace

	
/****************************
  table for continuous vars 
****************************/
/*Overall*/
use "TBPCS_iso3_2019_output", clear	
	tempname memhold
	postfile `memhold' str50 var_cont n mean sd lb ub med min max using "TBPCS_iso3_2019_output3_cont_overall", replace
		local vars "age duration_int duration_cont treat_duration phase_days weeks_before_tx visit_before hhsize rooms income_hh_pre_reported expend_hh s_t_current n_dot_visits t_dot n_pickup_total s_fu t_fu t_pickup t_guard_dot t_guard_pickup t_guard_fu t_guard_hosp t_guard_tot t_stay_current total_visits income_hh_pred income_pre income_now"
		foreach var_cont of local vars {
			disp "`var_cont'"
			qui summ `var_cont' if `var_cont'!=., detail
			local n=r(N)
			local mean=r(mean)
			local sd=r(sd)
			local med=r(p50)
			local min=r(p25)
			local max=r(p75)
			ci means `var_cont' if `var_cont'!=.
			local lb=r(lb)
			local ub=r(ub)
			post `memhold' ("`var_cont'") (`n') (`mean') (`sd') (`lb') (`ub') (`med') (`min') (`max') 
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output3_cont_overall", clear
	drop if n==0
	
	local vars "mean sd lb ub"
	foreach x of local vars {
		tostring `x', format(%15.1fc) force replace
		}
	local vars "med min max"
	foreach x of local vars {
		tostring `x', format(%15.0fc) force replace
		}
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen sd_ = concat(beg sd end)
	egen ci = concat(beg lb join ub end)
	egen iqr = concat(beg min join max end)
	drop sd
	rename sd_ sd
	
	keep var_cont n mean ci sd med iqr 
	order var_cont n mean ci sd med iqr 
	
	save "TBPCS_iso3_2019_output3_cont_overall", replace
	export excel using "TBPCS_iso3_2019_output3_cont_overall.xlsx", firstrow(variables) replace

/*by DS and DR*/
use "TBPCS_iso3_2019_output", clear
	
	tempname memhold
	postfile `memhold' str50 var_cont mdr n mean sd lb ub med min max p_ttest p_ranksum using "TBPCS_iso3_2019_output4_cont_dsdr", replace
		local vars "age duration_int duration_cont treat_duration phase_days weeks_before_tx visit_before hhsize rooms income_hh_pre_reported expend_hh s_t_current n_dot_visits t_dot n_pickup_total s_fu t_fu t_pickup t_guard_dot t_guard_pickup t_guard_fu t_guard_hosp t_guard_tot  t_stay_current total_visits income_hh_pred income_pre income_now"
		foreach var_cont of local vars {
		foreach mdr of numlist 0 1 {
			disp "`var_cont'"
			qui summ `var_cont' if mdr==`mdr', detail
			local n=r(N)
			local mean=r(mean)
			local sd=r(sd)
			local med=r(p50)
			local min=r(p25)
			local max=r(p75)
			ci means `var_cont' if mdr==`mdr'
			local lb=r(lb)
			local ub=r(ub)
			ttest `var_cont', by(mdr)
			local p_ttest = r(p)
			ranksum `var_cont', by(mdr)
			local p_ranksum = 2 * normprob(-abs(r(z)))
			post `memhold' ("`var_cont'") (`mdr') (`n') (`mean') (`sd') (`lb') (`ub') (`med') (`min') (`max') (`p_ttest') (`p_ranksum') 
		}
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output4_cont_dsdr", clear
	
	label define mdr 0 "DS-TB" 1 "DR-TB" 
	label values mdr mdr

	drop if n==0
	
	local vars "mean sd lb ub"
	foreach x of local vars {
		tostring `x', format(%15.1fc) force replace
		}
	local vars "med min max"
	foreach x of local vars {
		tostring `x', format(%15.0fc) force replace
		}

	local vars "p_ttest p_ranksum"
	foreach x of local vars {
		replace `x'=. if mdr==0
		tostring `x', format(%15.3fc) force replace
		}
	
	replace p_ttest="<0.001" if p_ttest=="0.000"
	replace p_ranksum="<0.001" if p_ranksum=="0.000"
	
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen sd_ = concat(beg sd end)
	egen ci = concat(beg lb join ub end)
	egen iqr = concat(beg min join max end)
	drop sd
	rename sd_ sd
	
	keep var_cont mdr n  mean ci sd med iqr p_ttest p_ranksum
	order var_cont mdr n  mean ci sd med iqr p_ttest p_ranksum


/*if you would like to have table with a specific order of the variables, please define order here*/
/*Otherwise, the order of the variables will be alphabetic order after reshaping from long to wide form below*/
/*	gen sort =.
	replace sort = 0 if var_cont=="age"
	replace sort = 1 if var_cont=="duration_int"
	etc */
	
	reshape wide n mean ci sd med iqr p_ttest p_ranksum, i(var_cont) j(mdr)
	drop p_ttest0
	drop p_ranksum0
	
//	sort sort
	save "TBPCS_iso3_2019_output4_cont_dsdr", replace
	export excel using "TBPCS_iso3_2019_output4_cont_dsdr.xlsx", firstrow(variables) replace

*******************
* Table for costs *
*******************
/* Main cost categories only */
//Overall
use "TBPCS_iso3_2019_output", clear
	
	tempname memhold
	postfile `memhold' str50 cost n mean sd lb ub med min max using "TBPCS_iso3_2019_output5_cost_overall", replace
		local vars "cat_before_med cat_before_nmed cat_current_med cat_current_travel cat_current_accomodation cat_current_food cat_current_nutri cat_direct cat_before_indirect cat_current_indirect cat_indirect total_cost_hc income_diff pct1_num"
		foreach cost of local vars {
			disp "`cost'"
			qui summ `cost' if `cost'!=. , detail
			local n=r(N)
			local mean=r(mean)
			local sd=r(sd)
			local med=r(p50)
			local min=r(p25)
			local max=r(p75)
			qui ci means `cost' if `cost'!=.
			local lb=r(lb)
			local ub=r(ub)
			post `memhold' ("`cost'") (`n') (`mean') (`sd') (`lb') (`ub') (`med') (`min') (`max') 
		}

		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output5_cost_overall", clear

	gen mean_dup = mean
	
	local vars "mean sd lb ub"
	foreach x of local vars {
		tostring `x', format(%15.1fc) force replace
		}
	local vars "med min max"
	foreach x of local vars {
		tostring `x', format(%15.0fc) force replace
		}
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen sd_ = concat(beg sd end)
	egen ci = concat(beg lb join ub end)
	egen iqr = concat(beg min join max end)
	drop sd
	rename sd_ sd
	
	keep cost n mean ci sd med iqr mean_dup
	order cost n mean ci sd med iqr mean_dup
	
	save "TBPCS_iso3_2019_output5_cost_overall", replace
	export excel using "TBPCS_iso3_2019_output5_cost_overall.xlsx", firstrow(variables) replace

/* Main cost categories only */
//by DS and DR
use "TBPCS_iso3_2019_output", clear
	
	tempname memhold
	postfile `memhold' str50 cost mdr n mean sd lb ub med min max using "TBPCS_iso3_2019_output6_cost_dsdr", replace
		local vars "cat_before_med cat_before_nmed cat_current_med cat_current_travel cat_current_accomodation cat_current_food cat_current_nutri cat_direct cat_before_indirect cat_current_indirect cat_indirect total_cost_hc income_diff pct1_num"
		foreach cost of local vars {
		foreach mdr of numlist 0 1 {
		disp "`cost'"
			qui summ `cost' if `cost'!=. & mdr==`mdr', detail
			local n=r(N)
			local mean=r(mean)
			local sd=r(sd)
			local med=r(p50)
			local min=r(p25)
			local max=r(p75)
			qui ci means `cost' if `cost'!=.& mdr==`mdr'
			local lb=r(lb)
			local ub=r(ub)
			post `memhold' ("`cost'") (`mdr') (`n') (`mean') (`sd') (`lb') (`ub') (`med') (`min') (`max') 
		}
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output6_cost_dsdr", clear

	gen mean_dup = mean
	
	local vars "mean sd lb ub"
	foreach x of local vars {
		tostring `x', format(%15.1fc) force replace
		}
	local vars "med min max"
	foreach x of local vars {
		tostring `x', format(%15.0fc) force replace
		}
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen sd_ = concat(beg sd end)
	egen ci = concat(beg lb join ub end)
	egen iqr = concat(beg min join max end)
	drop sd
	rename sd_ sd
	
	keep cost mdr n mean ci sd med iqr mean_dup
	order cost mdr n mean ci sd med iqr mean_dup
	reshape wide n mean ci sd med iqr mean_dup, i(cost) j(mdr)
	
	save "TBPCS_iso3_2019_output6_cost_dsdr", replace
	export excel using "TBPCS_iso3_2019_output6_cost_dsdr.xlsx", firstrow(variables) replace

*******************
* Odds ratio *
*******************

//OR category
use "TBPCS_iso3_2019_output", clear

	tempname memhold
	postfile `memhold' str50 or_cat n count using "TBPCS_iso3_2019_output7_cc_prop", replace
		local vars ///
		"age_cat t_sex mdr delay t_hiv hh_quintile"
		foreach or_cat of local vars {
		foreach cat of numlist 0 1 2 3 4 5 6 7{
			disp "`or_cat'"
			qui count if `or_cat'==`cat'
			local n=r(N)
			qui count if `or_cat'==`cat' & cc1==1
			local count=r(N)
			post `memhold' ("`or_cat'") (`n') (`count')
		}
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output7_cc_prop", clear
		
	drop if n==0	

	gen prop = count/n
	
	local vars "n count"
	foreach x of local vars {
		tostring `x', format(%5.0f) force replace
		}
	
	tostring prop, format(%5.3f) force replace
	destring prop, force replace
	replace prop=prop*100
	tostring prop, format(%5.1f) force replace
	gen per ="%"
	egen prop_per = concat(prop per)
	
	gen beg =" ("
	gen join =" - "
	gen end =")"
	
	egen n_prop = concat(beg prop_per end)
		
	keep or_cat n count n_prop
	order or_cat n count n_prop
	
	save "TBPCS_iso3_2019_output7_cc_prop", replace
	export excel using "TBPCS_iso3_2019_output7_cc_prop.xlsx", firstrow(variables) replace



//Crude odds ratio
use "TBPCS_iso3_2019_output", clear

gen hh_quin_re = .
replace hh_quin_re = 1 if hh_quintile ==5
replace hh_quin_re = 2 if hh_quintile ==4
replace hh_quin_re = 3 if hh_quintile ==3
replace hh_quin_re = 4 if hh_quintile ==2
replace hh_quin_re = 5 if hh_quintile ==1

	tempname memhold
	postfile `memhold' str30 rf or1 lb_or1 ub_or1 p_log1 or2 lb_or2 ub_or2 p_log2 or3 lb_or3 ub_or3 p_log3 or4 lb_or4 ub_or4 p_log4 or5 lb_or5 ub_or5 p_log5  or6 lb_or6 ub_or6 p_log6 using "TBPCS_iso3_2019_output8_COR", replace
		local vars "age_cat t_sex mdr delay t_hiv hh_quin_re"
		foreach cat of local vars {
			disp "`cat'"
			qui logistic cc1 i.`cat'
			mat li r(table)
			matrix or=r(table)
			local or1=el(or,1,2)
			local lb_or1=el(or,5,2)
			local ub_or1=el(or,6,2)
			local p_log1=el(or,4,2)
			local or2=el(or,1,3)
			local lb_or2=el(or,5,3)
			local ub_or2=el(or,6,3)
			local p_log2=el(or,4,3)
			local or3=el(or,1,4)
			local lb_or3=el(or,5,4)
			local ub_or3=el(or,6,4)
			local p_log3=el(or,4,4)
			local or4=el(or,1,5)
			local lb_or4=el(or,5,5)
			local ub_or4=el(or,6,5)
			local p_log4=el(or,4,5)
			local or5=el(or,1,6)
			local lb_or5=el(or,5,6)
			local ub_or5=el(or,6,6)
			local p_log5=el(or,4,6)
			local or6=el(or,1,6)
			local lb_or6=el(or,5,6)
			local ub_or6=el(or,6,6)
			local p_log6=el(or,4,6)
			post `memhold' ("`cat'") (`or1') (`lb_or1') (`ub_or1') (`p_log1') (`or2') (`lb_or2') (`ub_or2') (`p_log2') (`or3') (`lb_or3') (`ub_or3') (`p_log3') (`or4') (`lb_or4') (`ub_or4') (`p_log4') (`or5') (`lb_or5') (`ub_or5') (`p_log5') (`or6') (`lb_or6') (`ub_or6') (`p_log6')
		}
		postclose `memhold' 

//producing table to export as excel file & formating
	use "TBPCS_iso3_2019_output8_COR", clear
	
	local vars "or2 lb_or2 ub_or2 p_log2"
	foreach x of local vars {
		replace `x'=. if or3==.
		}

	local vars "or3 lb_or3 ub_or3 p_log3"
	foreach x of local vars {
		replace `x'=. if or4==.
		}

	local vars "or4 lb_or4 ub_or4 p_log4"
	foreach x of local vars {
		replace `x'=. if or5==.
		}

	local vars "or5 lb_or5 ub_or5 p_log5"
	foreach x of local vars {
		replace `x'=. if or6==.
		}
		
	local vars "or1 lb_or1 ub_or1 or2 lb_or2 ub_or2 or3 lb_or3 ub_or3 or4 lb_or4 ub_or4 or5 lb_or5 ub_or5 or6 lb_or6 ub_or6"
	foreach x of local vars {
		tostring `x', format(%5.2f) force replace
		}
	local vars "p_log1 p_log2 p_log3 p_log4 p_log5 p_log6"
	foreach x of local vars {
		tostring `x', format(%5.3f) force replace
		}
	gen beg =" ("
	gen join =" - "
	gen end =")"

	egen ci1 = concat(beg lb_or1 join ub_or1 end)
	egen ci2 = concat(beg lb_or2 join ub_or2 end)
	egen ci3 = concat(beg lb_or3 join ub_or3 end)
	egen ci4 = concat(beg lb_or4 join ub_or4 end)
	egen ci5 = concat(beg lb_or5 join ub_or5 end)
	egen ci6 = concat(beg lb_or6 join ub_or6 end)
	
	keep rf or1 ci1 p_log1 or2 ci2 p_log2 or3 ci3 p_log3 or4 ci4 p_log4 or5 ci5 p_log5 or6 ci6 p_log6
	order rf or1 ci1 p_log1 or2 ci2 p_log2 or3 ci3 p_log3 or4 ci4 p_log4 or5 ci5 p_log5 or6 ci6 p_log6
	
	local vars "ci1 ci2 ci3 ci4 ci5 ci6"
	foreach x of local vars {
		replace `x'="." if `x'=="(. - .)"
		}

	gen sort =.
	replace sort = 0 if rf=="age_cat"
	replace sort = 1 if rf=="t_sex"
	replace sort = 2 if rf=="mdr"
	replace sort = 3 if rf=="delay"
	replace sort = 4 if rf=="t_hiv"
	replace sort = 5 if rf=="hh_quin_re"
	
	reshape long or ci p_log, i(rf) j(cat)
	sort sort cat
	drop if or=="."
	drop if cat==6
	
	replace p_log = "<0.001" if p_log == "0.000" 
	
	save "TBPCS_iso3_2019_output8_COR", replace
	export excel using "TBPCS_iso3_2019_output8_COR.xlsx", firstrow(variables) replace


