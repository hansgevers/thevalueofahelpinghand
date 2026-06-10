/*
Stata code supporting paper "The value of a helping hand"
Author: Hans Gevers - Junior Research Fellow at the Estonian Business School
https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee
*/
		
*DATA COLLECTION

*survey data of Wave 4 up to Wave 9 (W4 2011 W5 2013 W6 2015 W7 2017 W8 2019/2020 W9 2021/2022)
global nums 2011 2013 2015

foreach WA of numlist 4 5 6 {
	foreach num of numlist 1 2 3 4 5 {
		clear
		local YE:word `=`WA'-3' of $nums

		*set working directory
		cd "C:\Users\hansg\Documents\working\SHARE data\sharew`WA'_rel9-0-0_ALL_datasets_stata\"
		use "sharew`WA'_rel9-0-0_gv_imputations.dta"
		keep if implicat==`num'
		
		*merge
		merge 1:1 mergeid using "sharew`WA'_rel9-0-0_cv_r"
		gen age_w`WA'=`YE'-yrbirth if yrbirth>0
		keep if interview==1
		drop _merge
		
		merge 1:1 mergeid using "sharew`WA'_rel9-0-0_gv_health.dta"
		drop _merge
		
		merge 1:1 mergeid using "sharew`WA'_rel9-0-0_gv_weights" 

		drop _merge
		
		merge 1:1 mergeid using "sharew`WA'_rel9-0-0_gv_housing" 
		
		drop _merge
		gen Qyear=`YE'
		codebook Qyear
		label variable Qyear "Year"
		isid mergeid
		
		*save per wave
		cd "C:\Users\hansg\Documents\working\SHARE data\weighting"
		*set working directory
		save "W`WA'_n_`num'.dta", replace
	}
}

*calculate longitudinal calibrated weights based on Wave 4 according to the SHARE procedure (more info: share-eric.eu)
noi run 4_CLIW_sup.do

*set working directory for export
cd "C:\Users\hansg\Documents\working\SHARE data\weighting"
foreach num of numlist 1 2 3 4 5 {
*for each imputation
	foreach numW of numlist 4 5 6 {
	
	*add weights
		clear
		use "W`numW'_n_`num'.dta"
		merge 1:1 mergeid using "W4_weights_n_`num'.dta", keep(match)
		drop _merge
		save "W`numW'_n_`num'.dta", replace
	}
	
	*combine across time horizon, i.e. Wave 4 to 9, per imputation
	clear
	use "W4_n_`num'.dta"
	append using "W5_n_`num'.dta"
	append using "W6_n_`num'.dta"
	*save
	save "C:\Users\hansg\Documents\working\SHARE data\weighting\Panel_imputation_n_`num'.dta", replace
	}
