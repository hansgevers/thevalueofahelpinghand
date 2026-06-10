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

*program for calculating Mundlak_Means
program define Mundlak_Means
	*syntax varname
	global variab household cjs gali rhfo ghto naly
	foreach V of numlist 1(1)6 {
		local va: word `V' of $variab
		tab `va', gen(_dum_)
		levelsof `va', local(levels)
		local i = 1
		foreach l of local levels {
			local lbl : label (`va') `l'
			local clean = ustrword("`lbl'",1)
			rename _dum_`i' `va'_`clean'
			local ++i
		}
		foreach v of varlist `va'_* {
			bysort id: egen Mundlak_`v' = mean(`v')
		}
	}
end
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
	
	*visualize respondents over time
	vioplot age, over(Qyear) graphr(c(white)) title() subtitle() note() ytitle("age") ylab(, angle(horiz)) scheme(stmono1)
	graph export violinplot_sup_`IM'.tif, width(1600) height(1200) replace

	***Mundlak estimator - own writting
	*correlated random no weights and no order own calculated means
	bysort id: egen Mundlak_age=mean(age)
	bysort id: egen Mundlak_thinc=mean(thinc)
	bysort id: egen Mundlak_lifesat=mean(lifesat)
	bysort id: egen Mundlak_yedu=mean(yedu)
	bysort id: egen Mundlak_age2=mean(age^2)
	bysort id: egen Mundlak_thinc2=mean(thinc^2)
	bysort id: egen Mundlak_lifesat2=mean(lifesat^2)
	bysort id: egen Mundlak_yedu2=mean(yedu^2)
	
	Mundlak_Means

	generate i1=1.rhfo_None#ghto_None
	generate i2=1.rhfo_At#ghto_None
	*generate i3=1.rhfo_Not#ghto_None
	generate i4=1.rhfo_None#ghto_At 
	generate i5=1.rhfo_At#ghto_At 
	*generate i6=1.rhfo_Not#ghto_At 
	generate i7=1.rhfo_None#ghto_Not 
	generate i8=1.rhfo_At#ghto_Not 
	*generate i9=1.rhfo_Not#ghto_Not 

	bysort id: egen Mundlak_i1=mean(i1)
	bysort id: egen Mundlak_i2=mean(i2)
	*bysort id: egen Mundlak_i3=mean(i3)
	bysort id: egen Mundlak_i4=mean(i4)
	bysort id: egen Mundlak_i5=mean(i5)
	*bysort id: egen Mundlak_i6=mean(i6)
	bysort id: egen Mundlak_i7=mean(i7)
	bysort id: egen Mundlak_i8=mean(i8)
	*bysort id: egen Mundlak_i9=mean(i9)
	
	xtset id Qyear
	***random effects ordered logit estimator with Mundlak means and robust standard errors
	xtologit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country Mundlak_*, or vce(robust)
	outreg2 using results_imp1_xtoPlus_sup_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	addstat(PanelLevelSD, `e(sigma_u)') dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	asdoc test Mundlak_age Mundlak_thinc Mundlak_lifesat Mundlak_yedu Mundlak_age2 Mundlak_thinc2 Mundlak_lifesat2 Mundlak_yedu2 Mundlak_household_Single Mundlak_household_Couple Mundlak_household_Multiple Mundlak_cjs_Not Mundlak_cjs_Retired Mundlak_cjs_Employed Mundlak_cjs_Unemployed Mundlak_cjs_Permanently Mundlak_cjs_Homemaker Mundlak_cjs_Other Mundlak_gali_Not Mundlak_gali_Limited Mundlak_rhfo_None Mundlak_rhfo_At Mundlak_ghto_None Mundlak_ghto_At Mundlak_ghto_Not Mundlak_naly_None Mundlak_naly_At Mundlak_naly_Not Mundlak_i1 Mundlak_i2 Mundlak_i4 Mundlak_i5 Mundlak_i7 Mundlak_i8, save(xtoPlus_sup_`IM'.doc)

	xtologit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country Mundlak_* [pweight=my_wgt], or vce(robust)
	outreg2 using results_imp1_xtoPlus2_sup_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	addstat(PanelLevelSD, `e(sigma_u)') dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	asdoc test Mundlak_age Mundlak_thinc Mundlak_lifesat Mundlak_yedu Mundlak_age2 Mundlak_thinc2 Mundlak_lifesat2 Mundlak_yedu2 Mundlak_household_Single Mundlak_household_Couple Mundlak_household_Multiple Mundlak_cjs_Not Mundlak_cjs_Retired Mundlak_cjs_Employed Mundlak_cjs_Unemployed Mundlak_cjs_Permanently Mundlak_cjs_Homemaker Mundlak_cjs_Other Mundlak_gali_Not Mundlak_gali_Limited Mundlak_rhfo_None Mundlak_rhfo_At Mundlak_ghto_None Mundlak_ghto_At Mundlak_ghto_Not Mundlak_naly_None Mundlak_naly_At Mundlak_naly_Not Mundlak_i1 Mundlak_i2 Mundlak_i4 Mundlak_i5 Mundlak_i7 Mundlak_i8, save(xtoPlus2_sup_`IM'.doc)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2011, vce(robust)
	outreg2 using results_imp1_slo_sup_`IM'.xls, excel replace dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2011)
	margins rhfo#ghto, post
	outreg2 using slogM_sup_`IM'.xls, ctitle(Probability) excel replace noaster

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015, vce(robust)
	outreg2 using results_imp1_slo_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2015)
	margins rhfo#ghto, post
	outreg2 using slogM_sup_`IM'.xls, ctitle(Probability) excel noaster
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==11, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel replace dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Austria2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==12, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Germany2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==13, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Sweden2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==15, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Spain2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==16, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Italy2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==17, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(France2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==18, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Denmark2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==20, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Switzerland2015)
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==23, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Belgium2015)
	
	*slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	*c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==28, vce(robust)
	*outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Czechia2015)
	*convergence not achieved for Czech Republic
	
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=weight] if Qyear==2015 & country==34, vce(robust)
	outreg2 using results_imp1_sloCountry_sup_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(Slovenia2015)	
	
	log close The_value_of_a_helping_hand
	translate output_`IM'.smcl output_sup_`IM'.pdf
}