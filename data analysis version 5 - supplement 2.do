/*
Stata code supporting paper "The value of a helping hand"
Author: Hans Gevers - Junior Research Fellow at the Estonian Business School
https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee
*/

*DATA ANALYSIS

clear all
set linesize 100

*non-standard Stata packages used: asdoc, and outreg2 (activate line(s) if required)
*ssc install asdoc
*ssc install outreg2

*only imputation 1 (2 3 4 5)
foreach IM of numlist 1 {
	clear
	*function for calculating the Mundlak Means for categoricals
	log using output_`IM'.smcl, replace name("The_value_of_a_helping_hand")
	*set working directory
	cd "C:\Users\hansg\Documents\working\SHARE data\weighting"
	*define source file
	use "Panel_imputation_n_`IM'.dta"

	*PREPROCESSING

	*keep variables used
	keep mergeid country age implicat htype rhfo ghto lifesat naly gali sphus yedu gender thinc cjs Qyear my_wgt weight

	*exclude 1 obs for yedu
	drop if yedu==9997

	*reduce helping indicators to 3 categories
	replace rhfo=1 if rhfo>0
	replace ghto=1 if ghto>0
	replace naly=1 if naly>0

	*relabel helping indicators
	label define Lab 0 "None" 1 "At least 1" 2 "Not applicable"
	replace rhfo=2 if rhfo==-99
	label values rhfo Lab
	replace ghto=2 if ghto==-99
	label values ghto Lab
	replace naly=2 if naly==-99
	label values naly Lab

	*relabel job situation indicator
	replace cjs=6 if cjs==97
	replace cjs=0 if cjs==-99
	label define Lab3 0 "Not applicable" 1 "Retired" 2 "Employed or self-employed" 3 "Unemployed" ///
	4 "Permanently sick or disabled" 5 "Homemaker" 6 "Other"
	label values cjs Lab3
	*Note: other= (Rentier, Living off own property, Student, Doing voluntary work); employed & self-employed ///
	(including working for family business)

	*winsorize income
	winsor2 thinc, replace cuts(5 95)

	*test normality with Skewness and kurtosis tests given size of dataset
	sktest age
	sktest thinc
	sktest yedu

	*transform string id to numeric id
	egen id= group(mergeid)

	*regroup htype
	gen household=2
	tabstat id, by(htype) stat(N)
	tabulate htype, nolabel
	replace household=0 if htype==1
	replace household=1 if htype==3
	label define Lab2 0 "Single person responding" 1 "Couple, both responding" 2 "Multiple, at least 1 responding"
	label values household Lab2
	
	*standardize income after description
	egen thincMean=mean(thinc)
	egen thincSD=sd(thinc)
	gen thinc2=(thinc-thincMean)/thincSD
	drop thinc
	rename thinc2 thinc
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==11, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel replace dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Austria2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==12, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Germany2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==13, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Sweden2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==15, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Spain2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==16, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Italy2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==17, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(France2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==18, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Denmark2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==20, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Switzerland2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==23, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Belgium2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==28, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Czechia2011)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011 & country==34, vce(robust)
	outreg2 using results_imp1_sloCountry_sup2_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Slovenia2011)	
	
	log close The_value_of_a_helping_hand
	translate output_`IM'.smcl output_sup2_`IM'.pdf
}