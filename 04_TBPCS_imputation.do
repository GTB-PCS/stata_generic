/* Generic PCS script 
STEP 4. Impute cost data between patient groups (intensive vs continuation phase)
October 2, 2019 Takuya Yamanaka; Last changed: 15.11.19 I. Garcia Baena*/

set more off
cd "~\Dropbox\10.GTB\1.PCS_generic"
//loading dta file from step.3
use "TBPCS_iso3_2019_no_imp.dta", clear

/*******************************************************************************
                           EXTRAPOLATION

The plan is to scale up each patient's resource utilization in the current 
treatment phase based on their reported usage. This is done above using the scalar
and the s_ variables.

The other phase will be estimated based on average (m_) utilization of other 
patients in the other phase (not by facility...yet)
*******************************************************************************/ 
// PART 4 is only completed by intensive phase (phase1) patients. We use their averages to extrapolate
// for continuous phase (phase2) patients before diagnosis activities.

//Medians for part 4 major categories
sum c_med_before if phase=="phase1" & c_med_before!=. & mdr==0, d
gen m_med_before=r(p50) /*p50 is 1,065,500*/ /*IGB 9.2.17 gets 105550?!*/
sum c_nmed_before if phase=="phase1" & c_nmed_before!=. & mdr==0, d
gen m_nmed_before=r(p50)/*p50 is 500,000 */ /*IGB 9.2.17 gets the same*/
sum c_direct_before if phase=="phase1" & c_direct_before!=. & mdr==0, d
gen m_direct_before=r(p50)/*p50 is 2,060,000 */ /*IGB 9.2.17 gets the same*/
sum c_med_before if phase=="phase1" & c_med_before!=. & mdr==1, d
gen m_med_before_mdr=r(p50)/*p50 is 7,600,000*/ /*IGB 9.2.17 gets the same*/
sum c_nmed_before if phase=="phase1" & c_nmed_before!=. & mdr==1, d
gen m_nmed_before_mdr=r(p50)/*p50 is 7,200,000 */ /*IGB 9.2.17 gets the same*/
sum c_direct_before if phase=="phase1" & c_direct_before!=. & mdr==1, d
gen m_direct_before_mdr=r(p50) /*p50 is  1.48e+07*/ /*IGB 9.2.17 gets the same*/

//time and cost of time
sum t_before if phase=="phase1" & t_before!=. & mdr==0, d
gen m_t_before=r(p50) 
sum c_time_before if phase=="phase1" & c_time_before!=. & mdr==0, d
gen m_c_time_before=r(p50)  
sum t_before if phase=="phase1" & t_before!=. & mdr==1, d
gen m_t_before_mdr=r(p50)
sum c_time_before if phase=="phase1" & c_time_before!=. & mdr==1, d
gen m_c_time_before_mdr=r(p50)

/***************************************************************
DS- Patients -MEDIAN ALL SURVEY PARTICIPANTS
******************************************************************/
//CURRENT DS-TB TREATMENT DIRECT COSTS- INTENSIVE PHASE AVERAGES
sum s_c_med_current if phase=="phase1" & c_med_current!=. & mdr==0, d
gen m_med_current_int=r(p50)
sum s_c_nmed_current if phase=="phase1" & c_nmed_current!=. & mdr==0, d
gen m_nmed_current_int=r(p50)
sum s_c_direct_current if phase=="phase1" & c_direct_current!=. & mdr==0, d
gen m_direct_current_int=r(p50)

//sub-categories
sum s_c_nmed_current_travel_cost if phase=="phase1" & c_nmed_current_travel_cost!=. & mdr==0, d
gen m_direct_current_travel_cost_int=r(p50)
sum s_c_nmed_current_other_nmed if phase=="phase1" & c_nmed_current_other_nmed!=. & mdr==0, d
gen m_direct_current_other_nmed_int=r(p50)
sum s_c_nmed_current_food if phase=="phase1" & c_nmed_current_food!=. & mdr==0, d
gen m_direct_current_food_int=r(p50)

//CURRENT TREATMENT DIRECT COSTS- CONTINUATION PHASE AVERAGES
sum s_c_med_current if phase=="phase2" & c_med_current!=. & mdr==0, d
gen m_med_current_con=r(p50)
sum s_c_nmed_current if phase=="phase2" & c_nmed_current!=. & mdr==0, d
gen m_nmed_current_con=r(p50)
sum s_c_direct_current if phase=="phase2" & c_direct_current!=. & mdr==0, d
gen m_direct_current_con=r(p50)

//sub-categories
sum s_c_nmed_current_travel_cost if phase=="phase2" & c_nmed_current_travel_cost!=. & mdr==0, d
gen m_direct_current_travel_cost_con=r(p50)
sum s_c_nmed_current_other_nmed if phase=="phase2" & c_nmed_current_other_nmed!=. & mdr==0, d
gen m_direct_ct_other_nmed_con=r(p50)
sum s_c_nmed_current_food if phase=="phase2" & c_nmed_current_food!=. & mdr==0, d
gen m_direct_current_food_con=r(p50)

//CURRENT TREATMENT - TIME - INTENSIVE PHASE AVERAGES and time valuation (human capital approach)
sum s_t_current if phase=="phase1" & t_current!=. & mdr==0, d
gen m_t_current_int=r(p50)
sum s_c_time_current if phase=="phase1" & c_time_current!=. & mdr==0, d
gen m_c_time_current_int=r(p50)

//CURRENT TREATMENT - TIME - CONTINUATION PHASE AVERAGES and time valuation (human capital approach)
sum s_t_current if phase=="phase2" & t_current!=. & mdr==0, d
gen m_t_current_con=r(p50)
sum s_c_time_current if phase=="phase2" & c_time_current!=. & mdr==0, d
gen m_c_time_current_con=r(p50)

/***************************************************************
MDR- Patients - MEDIAN ALL SURVEY PARTICIPANTS
******************************************************************/

//CURRENT TREATMENT DIRECT COSTS- INTENSIVE PHASE AVERAGES
sum s_c_med_current if phase=="phase1" & c_med_current!=. & mdr==1, d
gen m_med_current_int_mdr=r(p50)
sum s_c_nmed_current if phase=="phase1" & c_nmed_current!=. & mdr==1, d
gen m_nmed_current_int_mdr=r(p50)
sum s_c_direct_current if phase=="phase1" & c_direct_current!=. & mdr==1, d
gen m_direct_current_int_mdr=r(p50)

//sub-categories
sum s_c_nmed_current_travel_cost if phase=="phase1" & c_nmed_current_travel_cost!=. & mdr==1, d
gen m_d_current_tra_cost_int_mdr=r(p50)
sum s_c_nmed_current_other_nmed if phase=="phase1" & c_nmed_current_other_nmed!=. & mdr==1, d
gen m_direct_ct_other_nmed_int_mdr=r(p50)
sum s_c_nmed_current_food if phase=="phase1" & c_nmed_current_food!=. & mdr==1, d
gen m_direct_current_food_int_mdr=r(p50)

//CURRENT TREATMENT DIRECT COSTS- conINUATION PHASE AVERAGES
sum s_c_med_current if phase=="phase2" & c_med_current!=. & mdr==1, d
gen m_med_current_con_mdr=r(p50)
sum s_c_nmed_current if phase=="phase2" & c_nmed_current!=. & mdr==1, d
gen m_nmed_current_con_mdr=r(p50)
sum s_c_direct_current if phase=="phase2" & c_direct_current!=. & mdr==1, d
gen m_direct_current_con_mdr=r(p50)

//sub-categories
sum s_c_nmed_current_travel_cost if phase=="phase2" & c_nmed_current_travel_cost!=. & mdr==1, d
gen m_d_current_tra_cost_con_mdr=r(p50)
sum s_c_nmed_current_other_nmed if phase=="phase2" & c_nmed_current_other_nmed!=. & mdr==1, d
gen m_direct_ct_other_nmed_con_mdr=r(p50)
sum s_c_nmed_current_food if phase=="phase2" & c_nmed_current_food!=. & mdr==1, d
gen m_direct_current_food_con_mdr=r(p50)

//CURRENT TREATMENT - TIME - INTENSIVE PHASE AVERAGES
sum s_t_current if phase=="phase1" & t_current!=. & mdr==1, d
gen m_t_current_int_mdr=r(p50)
sum s_c_time_current if phase=="phase1" & c_time_current!=. & mdr==1, d
gen m_c_time_current_int_mdr=r(p50)

//CURRENT TREATMENT - TIME - conINUATION PHASE AVERAGES
sum s_t_current if phase=="phase2" & t_current!=. & mdr==1, d
gen m_t_current_con_mdr=r(p50)
sum s_c_time_current if phase=="phase2" & c_time_current!=. & mdr==1, d
gen m_c_time_current_con_mdr=r(p50)

/*******************************************************************************
  CALCULATE TOTAL COSTS - Disaggregated by type     
********************************************************************************/
/*With HOSPITALIZATION*/
//DSTB patients in intensive phase costs and time
egen c_medical1= rowtotal(c_med_before s_c_med_current m_med_current_con c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before1=c_med_before
egen c_medical_after1=rowtotal(s_c_med_current m_med_current_con c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical1= rowtotal(c_nmed_before s_c_nmed_current m_nmed_current_con c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before1= c_nmed_before 
egen c_nmedical_after1= rowtotal(s_c_nmed_current m_nmed_current_con c_nmed_dot_food c_nmed_dot_travel c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect1=rowtotal(c_time_before s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect1=c_indirect1 + (hourly_wage * m_t_current_con) if hourly_wage!=. * m_t_current_con !=.
gen c_indirect_before1=c_time_before
egen c_indirect_after1=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect_after1=c_indirect_after1 + (hourly_wage * m_t_current_con) if hourly_wage!=. * m_t_current_con !=.

//DSTB patients in continuation phase costs and time
egen c_medical2= rowtotal( m_med_before s_c_med_current m_med_current_int c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before2=m_med_before
egen c_medical_after2=rowtotal( s_c_med_current m_med_current_int c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical2= rowtotal(m_nmed_before s_c_nmed_current m_nmed_current_int c_nmed_dot_food c_nmed_dot_travel c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before2=m_nmed_before
egen c_nmedical_after2= rowtotal(s_c_nmed_current m_nmed_current_int c_nmed_dot_food c_nmed_dot_travel c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect2=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect2=c_indirect2 + (hourly_wage * (m_t_current_int+m_t_before)) if hourly_wage!=.
gen c_indirect_before2=m_t_before * hourly_wage 
egen c_indirect_after2=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect_after2 = c_indirect_after2 + (hourly_wage * m_t_current_int) if hourly_wage!=.

//MDR patients in intensive phase costs and time
egen c_medical3= rowtotal( c_med_before s_c_med_current m_med_current_con_mdr c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before3=c_med_before
egen c_medical_after3=rowtotal( s_c_med_current m_med_current_con_mdr c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical3= rowtotal(c_nmed_before s_c_nmed_current m_nmed_current_con_mdr c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before3= c_nmed_before 
egen c_nmedical_after3= rowtotal(s_c_nmed_current m_nmed_current_con c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect3=rowtotal(c_time_before s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect3=c_indirect3 + (hourly_wage * m_t_current_con_mdr) if hourly_wage!=.
gen c_indirect_before3=c_time_before
egen c_indirect_after3=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect_after3=c_indirect_after3 + (hourly_wage * m_t_current_con) if hourly_wage!=. * m_t_current_con !=.

//MDR patients in continuation phase costs and time
egen c_medical4= rowtotal( m_med_before_mdr s_c_med_current m_med_current_int_mdr c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before4=m_med_before_mdr
egen c_medical_after4=rowtotal( s_c_med_current m_med_current_int_mdr c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical4= rowtotal(m_nmed_before_mdr s_c_nmed_current m_nmed_current_int_mdr c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before4= m_nmed_before 
egen c_nmedical_after4= rowtotal(s_c_nmed_current m_nmed_current_int_mdr c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect4=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect4=c_indirect4 + (hourly_wage * (m_t_current_int_mdr + m_t_before_mdr)) if hourly_wage!=.
gen c_indirect_before4=m_t_before_mdr * hourly_wage 
egen c_indirect_after4=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect_after4 = c_indirect_after4 + (hourly_wage * m_t_current_int_mdr) if hourly_wage!=.

/*Without HOSPITALIZATION*/
//DSTB patients in intensive phase costs and time
egen c_medical5= rowtotal(c_med_before /*s_c_med_current m_med_current_con*/ c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before5=c_med_before
egen c_medical_after5=rowtotal(/*s_c_med_current m_med_current_con*/ c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical5= rowtotal(c_nmed_before /*s_c_nmed_current m_nmed_current_con*/ c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before5= c_nmed_before 
egen c_nmedical_after5= rowtotal(/*s_c_nmed_current m_nmed_current_con*/ c_nmed_dot_food c_nmed_dot_travel c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect5=rowtotal(c_time_before /*s_c_time_current m_c_time_current_con*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
/*replace c_indirect5=c_indirect5 + (hourly_wage * m_t_current_con) if hourly_wage!=. * m_t_current_con !=.*/
gen c_indirect_before5=c_time_before
egen c_indirect_after5=rowtotal(/*s_c_time_current m_c_time_current_con*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
/*replace c_indirect_after5=c_indirect_after5 + (hourly_wage * m_t_current_con) if hourly_wage!=. * m_t_current_con !=.*/

//DSTB patients in continuation phase costs and time
egen c_medical6= rowtotal( m_med_before /*s_c_med_current m_med_current_int*/ c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before6=m_med_before
egen c_medical_after6=rowtotal(/*s_c_med_current m_med_current_int*/ c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical6= rowtotal(m_nmed_before /*s_c_nmed_current m_nmed_current_int*/ c_nmed_dot_food c_nmed_dot_travel c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before6=m_nmed_before
egen c_nmedical_after6= rowtotal(/*s_c_nmed_current m_nmed_current_int*/ c_nmed_dot_food c_nmed_dot_travel c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect6=rowtotal(/*m_c_time_current_int s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect6=c_indirect6 + (hourly_wage * (/*m_t_current_int+*/m_t_before)) if hourly_wage!=.
gen c_indirect_before6=m_t_before * hourly_wage 
egen c_indirect_after6=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
//replace c_indirect_after6 = c_indirect_after6 + (hourly_wage * m_t_current_int) if hourly_wage!=.

//MDR patients in intensive phase costs and time
egen c_medical7= rowtotal( c_med_before /*s_c_med_current m_med_current_con_mdr*/ c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before7=c_med_before
egen c_medical_after7=rowtotal( /*s_c_med_current m_med_current_con*/ c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical7= rowtotal(c_nmed_before /*s_c_nmed_current m_nmed_current_con_mdr*/ c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before7= c_nmed_before 
egen c_nmedical_after7= rowtotal(/*s_c_nmed_current m_nmed_current_con*/ c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect7=rowtotal(c_time_before /*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
//replace c_indirect7=c_indirect7 + (hourly_wage * m_t_current_con_mdr) if hourly_wage!=.
gen c_indirect_before7=c_time_before
egen c_indirect_after7=rowtotal(/*s_c_time_current m_c_time_current_con*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
//replace c_indirect_after7=c_indirect_after7 + (hourly_wage * m_t_current_con) if hourly_wage!=. * m_t_current_con !=.

//MDR patients in continuation phase costs and time
egen c_medical8= rowtotal( m_med_before_mdr /*s_c_med_current m_med_current_int_mdr*/ c_med_dot c_pickup_med c_fu_med), missing
gen c_medical_before8=m_med_before_mdr
egen c_medical_after8=rowtotal( /*s_c_med_current m_med_current_int_mdr*/ c_med_dot c_pickup_med c_fu_med), missing
egen c_nmedical8= rowtotal(m_nmed_before_mdr /*s_c_nmed_current m_nmed_current_int_mdr*/ c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
gen c_nmedical_before8= m_nmed_before 
egen c_nmedical_after8= rowtotal(/*s_c_nmed_current m_nmed_current_int_mdr*/ c_nmed_dot_travel c_nmed_dot_food c_pickup_nmed c_fu_nmed c_food), missing
egen c_indirect8=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
replace c_indirect8=c_indirect8 + (hourly_wage * (/*m_t_current_int_mdr +*/ m_t_before_mdr)) if hourly_wage!=.
gen c_indirect_before8=m_t_before_mdr * hourly_wage 
egen c_indirect_after8=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect c_guard_tot), missing
//replace c_indirect_after8 = c_indirect_after8 + (hourly_wage * m_t_current_int_mdr) if hourly_wage!=.


gen c_medical =.
gen c_medical_before =.
gen c_medical_after =.
gen c_nmedical =.
gen c_nmedical_before =.
gen c_nmedical_after =.
gen c_indirect=.
gen c_indirect_before=.
gen c_indirect_after=.

foreach var of varlist c_medical c_medical_before c_medical_after c_nmedical c_nmedical_before c_nmedical_after c_indirect c_indirect_before c_indirect_after{ 
replace `var'=`var'1 if phase=="phase1" & mdr==0 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'2 if phase=="phase2" & mdr==0 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'3 if phase=="phase1" & mdr==1 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'4 if phase=="phase2" & mdr==1 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'5 if phase=="phase1" & mdr==0 & (current_hosp==0 & prev_hosp==0)
replace `var'=`var'6 if phase=="phase2" & mdr==0 & (current_hosp==0 & prev_hosp==0)
replace `var'=`var'7 if phase=="phase1" & mdr==1 & (current_hosp==0 & prev_hosp==0)
replace `var'=`var'8 if phase=="phase2" & mdr==1 & (current_hosp==0 & prev_hosp==0)
}

/*********************************
 Make cost categories for pie chart 
*********************************/
/*with HOSPITALIZATION*/
//DSTB patients in intensive phase costs and time
egen cat_current_med1 =rowtotal(s_c_med_current m_med_current_con c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel1=rowtotal(s_c_nmed_current_travel_cost m_direct_current_travel_cost_con c_nmed_dot_travel c_pickup_nmed_travel c_fu_nmed_travel), missing
egen cat_current_accomodation1=rowtotal(s_c_nmed_current_other_nmed m_direct_ct_other_nmed_con c_fu_nmed_accom),missing
egen cat_current_food1=rowtotal(s_c_nmed_current_food m_direct_current_food_con c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri1=rowtotal(c_food), missing
egen cat_current_indirect1=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect), missing
replace cat_current_indirect1=cat_current_indirect1 + (hourly_wage * m_t_current_con)

//DSTB patients in continuation phase costs and time
egen cat_current_med2 =rowtotal(s_c_med_current m_med_current_int c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel2=rowtotal(s_c_nmed_current_travel_cost m_direct_current_travel_cost_int c_nmed_dot_travel c_pickup_nmed_travel  c_fu_nmed_travel), missing
egen cat_current_accomodation2=rowtotal(s_c_nmed_current_other_nmed m_direct_current_other_nmed_int c_fu_nmed_accom),missing
egen cat_current_food2=rowtotal(s_c_nmed_current_food m_direct_current_food_int c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri2=rowtotal(c_food), missing
egen cat_current_indirect2=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect), missing
replace cat_current_indirect2=cat_current_indirect2 + (hourly_wage * m_t_current_int)

//MDR patients in intensive phase costs and time
egen cat_current_med3 =rowtotal(s_c_med_current m_med_current_con_mdr c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel3=rowtotal(s_c_nmed_current_travel_cost m_d_current_tra_cost_con_mdr c_nmed_dot_travel c_pickup_nmed_travel  c_fu_nmed_travel), missing
egen cat_current_accomodation3=rowtotal(s_c_nmed_current_other_nmed m_direct_ct_other_nmed_con_mdr c_fu_nmed_accom),missing
egen cat_current_food3=rowtotal(s_c_nmed_current_food m_direct_current_food_con_mdr c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri3=rowtotal(c_food), missing
egen cat_current_indirect3=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect), missing
replace cat_current_indirect3=cat_current_indirect3 + (hourly_wage * m_t_current_con_mdr)

//MDR patients in continuation phase costs and time
egen cat_current_med4 =rowtotal(s_c_med_current m_med_current_int_mdr c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel4=rowtotal(s_c_nmed_current_travel_cost m_d_current_tra_cost_int_mdr c_nmed_dot_travel c_pickup_nmed_travel c_fu_nmed_travel), missing
egen cat_current_accomodation4=rowtotal(s_c_nmed_current_other_nmed m_direct_ct_other_nmed_int_mdr c_fu_nmed_accom),missing
egen cat_current_food4=rowtotal(s_c_nmed_current_food m_direct_current_food_int_mdr c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri4=rowtotal(c_food), missing
egen cat_current_indirect4=rowtotal(s_c_time_current c_indirect_dot c_pickup_indirect c_fu_indirect), missing
replace cat_current_indirect4=cat_current_indirect4 + (hourly_wage * m_t_current_int_mdr)

/*without HOSPITALIZATION*/
//DSTB patients in intensive phase costs and time
egen cat_current_med5 =rowtotal(/*s_c_med_current m_med_current_con*/ c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel5=rowtotal(/*s_c_nmed_current_travel_cost m_direct_current_travel_cost_con*/ c_nmed_dot_travel c_pickup_nmed_travel c_fu_nmed_travel), missing
egen cat_current_accomodation5=rowtotal(/*s_c_nmed_current_other_nmed m_direct_ct_other_nmed_con*/ c_fu_nmed_accom),missing
egen cat_current_food5=rowtotal(/*s_c_nmed_current_food m_direct_current_food_con*/ c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri5=rowtotal(c_food), missing
egen cat_current_indirect5=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect), missing
//replace cat_current_indirect5=cat_current_indirect5 + (hourly_wage * m_t_current_con)

//DSTB patients in continuation phase costs and time
egen cat_current_med6 =rowtotal(/*s_c_med_current m_med_current_int*/ c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel6=rowtotal(/*s_c_nmed_current_travel_cost m_direct_current_travel_cost_int*/ c_nmed_dot_travel c_pickup_nmed_travel  c_fu_nmed_travel), missing
egen cat_current_accomodation6=rowtotal(/*s_c_nmed_current_other_nmed m_direct_current_other_nmed_int*/ c_fu_nmed_accom),missing
egen cat_current_food6=rowtotal(/*s_c_nmed_current_food m_direct_current_food_int*/ c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri6=rowtotal(c_food), missing
egen cat_current_indirect6=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect), missing
//replace cat_current_indirect6=cat_current_indirect6 + (hourly_wage * m_t_current_int)

//MDR patients in intensive phase costs and time
egen cat_current_med7 =rowtotal(/*s_c_med_current m_med_current_con_mdr*/ c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel7=rowtotal(/*s_c_nmed_current_travel_cost m_d_current_tra_cost_con_mdr*/ c_nmed_dot_travel c_pickup_nmed_travel  c_fu_nmed_travel), missing
egen cat_current_accomodation7=rowtotal(/*s_c_nmed_current_other_nmed m_direct_ct_other_nmed_con_mdr*/ c_fu_nmed_accom),missing
egen cat_current_food7=rowtotal(/*s_c_nmed_current_food m_direct_current_food_con_mdr*/ c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri7=rowtotal(c_food), missing
egen cat_current_indirect7=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect), missing
//replace cat_current_indirect7=cat_current_indirect7 + (hourly_wage * m_t_current_con_mdr)

//MDR patients in continuation phase costs and time
egen cat_current_med8 =rowtotal(/*s_c_med_current m_med_current_int_mdr*/ c_med_dot c_pickup_med c_fu_med), missing
egen cat_current_travel8=rowtotal(/*s_c_nmed_current_travel_cost m_d_current_tra_cost_int_mdr*/ c_nmed_dot_travel c_pickup_nmed_travel c_fu_nmed_travel), missing
egen cat_current_accomodation8=rowtotal(/*s_c_nmed_current_other_nmed m_direct_ct_other_nmed_int_mdr*/ c_fu_nmed_accom),missing
egen cat_current_food8=rowtotal(/*s_c_nmed_current_food m_direct_current_food_int_mdr*/ c_nmed_dot_food c_pickup_nmed_food), missing
egen cat_current_nutri8=rowtotal(c_food), missing
egen cat_current_indirect8=rowtotal(/*s_c_time_current*/ c_indirect_dot c_pickup_indirect c_fu_indirect), missing
//replace cat_current_indirect8=cat_current_indirect8 + (hourly_wage * m_t_current_int_mdr)


gen cat_before_med=c_medical_before
gen cat_before_nmed=c_nmedical_before
gen cat_before_indirect=c_indirect_before

gen cat_current_med =.
gen cat_current_travel =.
gen cat_current_accomodation =.
gen cat_current_food=.
gen cat_current_nutri=.
gen cat_current_indirect=.

foreach var of varlist cat_current_med cat_current_travel cat_current_accomodation cat_current_food cat_current_nutri cat_current_indirect{ 
replace `var'=`var'1 if phase=="phase1" & mdr==0 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'2 if phase=="phase2" & mdr==0 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'3 if phase=="phase1" & mdr==1 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'4 if phase=="phase2" & mdr==1 & (current_hosp==1 | prev_hosp==1)
replace `var'=`var'5 if phase=="phase1" & mdr==0 & (current_hosp==0 & prev_hosp==0)
replace `var'=`var'6 if phase=="phase2" & mdr==0 & (current_hosp==0 & prev_hosp==0)
replace `var'=`var'7 if phase=="phase1" & mdr==1 & (current_hosp==0 & prev_hosp==0)
replace `var'=`var'8 if phase=="phase2" & mdr==1 & (current_hosp==0 & prev_hosp==0)
replace `var'=0 if `var'==.
}
gen cat_caregiver=c_guard_tot

foreach var of varlist cat_*{
replace `var'=0 if `var'==.
}

drop cat_current*1 cat_current*2 cat_current*3 cat_current*4 

egen cat_direct=rowtotal(cat_before_med cat_before_nmed cat_current_med cat_current_travel cat_current_accomodation cat_current_food cat_current_nutri), missing
egen cat_indirect=rowtotal(cat_before_indirect cat_current_indirect), missing
egen total_cost_hc=rowtotal(cat_direct cat_indirect), missing


//MULTIPLY TOTAL COST IF PATIENTS FROM SAME HOUSEHOLD ARE SURVEYED.
//one other person in house means costs go up 50%, more than one oteher person doubles costs
//tab  house_tb_n

/*****************************************************************************
                         CATASTROPHIC COST
								
Definition 1 (cc1) uses the output based approach:

HH Income(PRE-TB) - HH Income(POST-TB) + DIRECT COSTS
------------------------------------------------------  > THRESHOLD
   					HH Income(PRE-TB)			
					
					
Definition 2 (cc2) uses the human capital approach, which involves utilizing 
an hourly wage for each respondent:

             INDIRECT COSTS + DIRECT COSTS
------------------------------------------------------  > THRESHOLD
   					HH Income(PRE-TB)			
					
*****************************************************************************/
gen threshold=.2

//Using annualized hh income to calculate the post-pre annual income
gen income_diff_time=treat_duration
replace income_diff_time=12 if income_diff_time > 12 & income_diff_time !=.
gen income_lost1=(income_hh_pre-income_hh_now)*income_diff_time

//Optional : add the drop in income from onset of symptoms to diagnosis
//must convert time into months
*gen income_lost2=(income_hh_diag - income_hh_pre) * (weeks_before_tx/4.33)

egen income_diff=rowtotal(income_lost1 /*income_lost2*/), missing
//if households happen to earn more after TB then change income loss to 0
replace income_diff=0 if (income_diff) < 0

//Numerator (pct1_num) for indicator-definition 1
egen pct1_num=rowtotal(income_diff cat_direct), missing

//Indicator definition 1
gen pct1= pct1_num/ income_hh_pre_annual
label var pct1 "Cost as percent of annual hh income (output approach)"

//Indicator-definition 2
gen pct2= total_cost_hc/income_hh_pre_annual
label var pct2 "Cost as percent of annual hh income (human capital approach)"

//Indicator-definition 3
gen pct3= total_cost_hc/expend_hh_annual
label var pct3 "Cost as percent of annual hh expenditure (human capital approach)"

//Generating dichotomic results below threshold not catastrophic vs above catastrophic
gen cc1=.
replace cc1=0 if pct1 <= threshold & pct1 !=.
replace cc1=1 if pct1 > threshold & pct1 !=.
label var cc1 "Catastrophic cost definition 1 (output approach)"

gen cc2=.
replace cc2=0 if pct2 <= threshold & pct2 !=.
replace cc2=1 if pct2 > threshold & pct2 !=.
label var cc2 "Catastrophic cost definition 2 (human capital approach)"

gen cc3=.
replace cc3=0 if pct3 <= threshold & pct3 !=.
replace cc3=1 if pct3 > threshold & pct3 !=.
label var cc3 "Catastrophic cost definition 3 (expenditure & human capital approach)"

//Indicator definition 4- Households dissaving yes/no (dichotomic)
gen cc4=.
replace cc4=0 if coping==0
replace cc4=1 if coping==1
label var cc4 "Catastrophic cost definition 3 (Any dissaving)"

// Indicator 5 where only direct medical and non-medical are considered (excluding indirect cost estimates)
gen pct_conservative=cat_direct/income_hh_pre_annual
gen cc_conservative=.
replace cc_conservative=0 if pct_conservative <=threshold & pct_conservative !=.
replace cc_conservative=1 if pct_conservative > threshold & pct_conservative !=.


/*******************************************************************
						CONVERT TO USD (vietnam example)
Using period average of X between July 24th 2016 and 14 October 2016
Costs are converted to United States Dollars (US$) using the average annual 
exchange rate during enrollment of US$1 = X.Country units (oanda.com).
********************************************************************/
#delimit ;
;
global moneyvars 
income_pre_reported
income_hh_pre_reported
income_hh_pred
income_imputed
m_income_pre
mn_income_pre
income_hh_pre_annual
income_hh_now_annual
income_pre_annual
income_now_annual
expend_hh_dis
expend_hh
expend_hh_annual
c_traveltime_before
c_visittime_before
c_time_before
c_med_before_room
c_med_before_cons
c_med_before_radio
c_med_before_lab
c_med_before_proc
c_med_before_medicine
c_med_before_other
c_med_before_dis
c_nmed_before_travel
c_nmed_before_food
c_nmed_before_accommodation
c_nmed_before_dis
reimburse_before
totalmed
totalnmed
c_med_before
c_nmed_before
c_direct_before
c_before
c_traveltime_current
c_staytime_current
c_time_current
c_med_current_day
c_med_current_cons
c_med_current_radio
c_med_current_lab
c_med_current_proc
c_med_current_med
c_med_current_oth
c_nmed_current_travel_cost
c_nmed_current_food
c_nmed_current_other_nmed
c_med_current_dis
c_nmed_current_dis
reimburse_current
s_reimburse_current
hosp_tot_med
hosp_tot_nmed
c_med_current
c_nmed_current
c_direct_current
hosp_total_all
s_c_med_current_day
s_c_med_current_cons
s_c_med_current_radio
s_c_med_current_lab
s_c_med_current_proc
s_c_med_current_med
s_c_med_current_oth
s_c_nmed_current_travel_cost
s_c_nmed_current_food
s_c_nmed_current_other_nmed
s_c_time_current
s_c_med_current
s_c_nmed_current
s_c_direct_current
c_current
c_dot_time
c_direct_dot_per
c_med_dot
c_nmed_dot_travel
c_nmed_dot_food
c_direct_dot
c_indirect_dot
c_dot
c_pickup_nmed_per
c_pickup_med_per
c_pickup_nmed
c_pickup_med
c_pickup_direct
c_pickup_nmed_accommodation
c_pickup_nmed_travel
c_pickup_nmed_food
c_pickup_indirect
c_pickup
c_fu_nmed_per
c_fu_med_per
c_fu_nmed_travel
c_fu_nmed_accom
c_fu_nmed
c_fu_med
c_fu_direct
c_fu_indirect
c_fu
c_supp
c_extra
c_food
caregiver_wage_1
caregiver_wage_2
caregiver_wage
c_guard_dot
c_guard_pickup
c_guard_fu
c_guard_hosp
c_guard_tot
coping_amount
m_med_before
m_nmed_before
m_direct_before
m_med_before_mdr
m_nmed_before_mdr
m_direct_before_mdr
m_c_time_before
m_c_time_before_mdr
m_med_current_int
m_nmed_current_int
m_direct_current_int
m_direct_current_travel_cost_int
m_direct_current_other_nmed_int
m_direct_current_food_int
m_med_current_con
m_nmed_current_con
m_direct_current_con
m_direct_current_travel_cost_con
m_direct_ct_other_nmed_con
m_direct_current_food_con
m_c_time_current_int
m_c_time_current_con
m_med_current_int_mdr
m_nmed_current_int_mdr
m_direct_current_int_mdr
m_d_current_tra_cost_int_mdr
m_direct_ct_other_nmed_int_mdr
m_direct_current_food_int_mdr
m_med_current_con_mdr
m_nmed_current_con_mdr
m_direct_current_con_mdr
m_d_current_tra_cost_con_mdr
m_direct_ct_other_nmed_con_mdr
m_direct_current_food_con_mdr
m_c_time_current_int_mdr
m_c_time_current_con_mdr
c_medical1
c_medical_before1
c_medical_after1
c_nmedical1
c_nmedical_before1
c_nmedical_after1
c_indirect1
c_indirect_before1
c_indirect_after1
c_medical2
c_medical_before2
c_medical_after2
c_nmedical2
c_nmedical_before2
c_nmedical_after2
c_indirect2
c_indirect_before2
c_indirect_after2
c_medical3
c_medical_before3
c_medical_after3
c_nmedical3
c_nmedical_before3
c_nmedical_after3
c_indirect3
c_indirect_before3
c_indirect_after3
c_medical4
c_medical_before4
c_medical_after4
c_nmedical4
c_nmedical_before4
c_nmedical_after4
c_indirect4
c_indirect_before4
c_indirect_after4
c_medical
c_medical_before
c_medical_after
c_nmedical
c_nmedical_before
c_nmedical_after
c_indirect
c_indirect_before
c_indirect_after
cat_before_med
cat_before_nmed
cat_before_indirect
cat_current_med
cat_current_travel
cat_current_accomodation
cat_current_food
cat_current_nutri
cat_current_indirect
cat_caregiver
cat_direct
cat_indirect
total_cost_hc
income_lost1
income_diff
pct1_num
income_pre
income_now ;
#delimit cr

 //convert to USD. replace 1 with exchange rate of local currency to USD
 foreach var of varlist $moneyvars{
 replace `var'=`var'/2284.84
 }
/*
 //Identify outliers
 foreach var of varlist cat_* {    
   quietly summarize `var'    
   cap g Z_`var'= (`var' > 6*r(sd)) if `var' < .      
   list `var' Z_`var' if Z_`var' == 1
}
*/

/*************************************************
	Impoverishment
****************************************************/

/* IMPOVERISHMENT INCIDENCE using the PPP$ 1.90/DAY (2011) POVERTY LINE. 

Variables: 
income_hh_pre = monthly household income pre-TB
hh_members = number of members in the patient's household
total_cost_output = total costs using output-based approach (not human capital) for indirect costs and direct costs
*/


*Step 1: Generating poverty threshold
gen hhsize = hhsize_a + hhsize_c
gen poverty_threshold_month=1.9 * 30.41 * hhsize
gen poverty_threshold_year= 1.9 * 365 * hhsize

*Step 2: Number of patients below poverty line
gen below_poverty=.
replace below_poverty=1 if income_hh_pre_reported < poverty_threshold_month & income_hh_pre_reported!=.
replace below_poverty=0 if income_hh_pre_reported >= poverty_threshold_month & income_hh_pre_reported!=.


*Step 3: Pushed below poverty line after TB
gen income_hh_pre_annual_reported = income_hh_pre_reported*12
gen below_poverty_after=.
replace below_poverty_after=1 if (income_hh_pre_annual_reported-pct1_num) < poverty_threshold_year & income_hh_pre_annual_reported !=.  
replace below_poverty_after=0 if (income_hh_pre_annual_reported-pct1_num) >= poverty_threshold_year & income_hh_pre_annual_reported !=.  

/*
/****************************************************
     LABELS. Add more labels to key variables here
	 Two shown for example.
****************************************************/
label var hourly_wage "Estimated hourly wage"
label var income_pre "Individual income pre-TB"
save "$data/countryname_clean", replace
*/



/***********************************************
           Save dta file
***********************************************/
save TBPCS_iso3_2019_imputed.dta, replace
