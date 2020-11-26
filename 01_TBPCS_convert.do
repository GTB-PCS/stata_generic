/*********************************************************************
Part 1: Converting ONA or ODK output data into a raw stata DTA file

* Before importing, check that there are no "n/a" values in numeric fields; 
* they should be replaced with "" in Excel (using find and replace all) 

This code will 
a) read in data from the electronic data collection system
b) check that all records have been imported, and highlight in case there's 
a problem
c) ensure variables are named systematically
d) save a .dta version of the raw data ready for Part 2
*********************************************************************/

* A. read data 
* Change this path as needed to reflect your working folder
global path "Z:\Users\pnguhiu\Dropbox\GTB_PCS_script"
cd "$path"
* Replace this path and file name with the name of the ODK output csv
import delimited using "$path\Raw Data\TBPCS_KEN_2017_20191001.csv" , delimiters(",") clear

/* B. Check the total number of observations, if they tally with the interviews
length. If they differ it's likely because some of the rows 
in the CSV are containing illegal 'carriage return' characters 
within the freetext. 

If CSV is opened in excel, look for the comments column and clean it of any 
illegal characters
*/
describe, s 

* C. Name and label variables to match the generic data dictionary
* Remove group identifier prefixes. Prefixes may vary depending on ODK 
* variable names. Confirm with CSV and modify if necessary. 

rename g2* *  //These are general patient and clinical info
rename g3* *  //These are costs before TB treatment started
rename g4* *  // These are gosts during TB treatment
rename g5* *  //These are insurance and social protection group of data
rename g6* *  //These are household asset and reported income / expenditure
rename g7* *  //These are social impact variables
rename comments comments_interviewer

** Country specific depending on how variable groups were named. 
** Older versions of stata may replace long variable names with a name beginning with v
** check and rename

rename v408 hosp_guard_travel_cost_2
rename v430 hosp_guard_travel_cost_3
rename v452 hosp_guard_travel_cost_4
rename v474 hosp_guard_travel_cost_5

rename v414 hosp_reimburse_waived_2
rename v436 hosp_reimburse_waived_3
rename v458 hosp_reimburse_waived_4
rename v480 hosp_reimburse_waived_5     



 


* Save raw file
saveold "$path\TBPCS_KEN_2017_raw.dta", version(13) replace
