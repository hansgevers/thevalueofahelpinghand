/*
Stata code supporting paper "The value of a helping hand"
Author: Hans Gevers - Junior Research Fellow at the Estonian Business School
https://orcid.org/0009-0001-0249-4142 hans.gevers@ebs.ee
*/

*DATA ANALYSIS

clear all
set linesize 100

*non-standard Stata packages used: feologit, asdoc, and outreg2 (activate line(s) if required)
*search st0596
*ssc install asdoc
*ssc install outreg2


foreach IM of numlist 1 2 3 4 5 {
	clear
	*function for calculating the Mundlak Means for categoricals
	log using output_sup_`IM'.smcl, replace name("The_value_of_a_helping_hand_sup")
	*set working directory
	cd "C:\Users\hansg\Documents\working\SHARE data\weighting"
	*define source file
	use "Panel_imputation_`IM'.dta"

	*PREPROCESSING

	*keep variables used
	keep mergeid country age implicat htype rhfo ghto lifesat naly gali sphus yedu gender thinc cjs Qyear my_wgt 

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

	*create variable for the health shock
	gen covid=0
	replace covid=1 if Qyear==2022

	*regroup htype
	gen household=2
	tabstat id, by(htype) stat(N)
	tabulate htype, nolabel
	replace household=0 if htype==1
	replace household=1 if htype==3
	label define Lab2 0 "Single person responding" 1 "Couple, both responding" 2 "Multiple, at least 1 responding"
	label values household Lab2

	*DESCRIPTIVES

	*standardize income after description
	egen thincMean=mean(thinc)
	egen thincSD=sd(thinc)
	gen thinc2=(thinc-thincMean)/thincSD
	drop thinc
	rename thinc2 thinc
	
	ologit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country
	asdoc estat parallel, save(TestAssum_`IM'.doc)
	
	gologit2 sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt], cluster(Qyear)
	outreg2 using results_imp1_go_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2011, vce(robust) base(5)
	outreg2 using results_imp1_ste_11_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	margins rhfo#ghto, post
	outreg2 using slog11_`IM'.xls, ctitle(Probability) excel noaster

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2013, vce(robust) base(5)
	outreg2 using results_imp1_ste_13_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	margins rhfo#ghto, post
	outreg2 using slog13_`IM'.xls, ctitle(Probability) excel noaster

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2015, vce(robust) base(5)
	outreg2 using results_imp1_ste_15_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	margins rhfo#ghto, post
	outreg2 using slog15_`IM'.xls, ctitle(Probability) excel noaster

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2017, vce(robust) base(5)
	outreg2 using results_imp1_ste_17_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	margins rhfo#ghto, post
	outreg2 using slog17_`IM'.xls, ctitle(Probability) excel noaster
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2020, vce(robust) base(5)
	outreg2 using results_imp1_ste_20_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	margins rhfo#ghto, post
	outreg2 using slog20_`IM'.xls, ctitle(Probability) excel noaster

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2022, vce(robust) base(5)
	outreg2 using results_imp1_ste_22_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	margins rhfo#ghto, post
	outreg2 using slog22_`IM'.xls, ctitle(Probability) excel noaster
	
	log close The_value_of_a_helping_hand_sup
	translate output_sup_`IM'.smcl output_sup_`IM'.pdf
}