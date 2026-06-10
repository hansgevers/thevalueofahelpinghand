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

*program for calculating Mundlak_Means
program define Mundlak_Means
	*syntax varname
	global variab household covid cjs gali rhfo ghto naly
	foreach V of numlist 1(1)7 {
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

*Only first imputation (2 3 4 5)
foreach IM of numlist 1 {
	clear
	*function for calculating the Mundlak Means for categoricals
	log using output_v6_`IM'.smcl, replace name("The_value_of_a_helping_hand")
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
	
	*set panel data structure outside IF-condition with variable id and time variable year
	xtset id Qyear

	*DESCRIPTIVES
	
	*describe used variables
	asdoc tabstat sphus age yedu thinc gender household cjs covid Qyear id gali rhfo ghto lifesat naly country, ///
	stat(mean sd min max N) save(stats_`IM'.doc)

	table sphus Qyear, statistic(percent Qyear, across(sphus)) nformat(%12.3f) export(perc1_`IM'.xls, replace)
	table sphus Qyear if rhfo!=2, statistic(fvproportion rhfo) nformat(%12.3f) export(prop1excl_`IM'.xls, replace)
	table sphus Qyear if ghto!=2, statistic(fvproportion ghto) nformat(%12.3f) export(prop2excl_`IM'.xls, replace)
	table sphus Qyear, statistic(fvproportion rhfo) nformat(%12.3f) export(prop1_`IM'.xls, replace)
	table sphus Qyear, statistic(fvproportion ghto) nformat(%12.3f) export(prop2_`IM'.xls, replace)
	table Qyear, statistic(fvproportion cjs) nformat(%12.3f) export(prop3_`IM'.xls, replace)
	table Qyear, statistic(fvproportion naly) nformat(%12.3f) export(prop4_`IM'.xls, replace)
	table Qyear, statistic(fvproportion gender) nformat(%12.3f) export(prop5_`IM'.xls, replace)

	*Spearman correlation
	asdoc spearman sphus age yedu thinc gender household cjs covid Qyear id gali rhfo ghto lifesat naly country, ///
	append save(stats_`IM'.doc)

	*Pearson correlation
	asdoc sktest age, save(sk_`IM'.doc)
	asdoc sktest yedu, append save(sk_`IM'.doc)
	asdoc sktest thinc, append save(sk_`IM'.doc)
	asdoc sktest lifesat, append save(sk_`IM'.doc)
	asdoc corr sphus age yedu thinc lifesat,pwcorr sphus age yedu thinc lifesat, append save(stats_`IM'.doc)
	pwcorr sphus age yedu thinc lifesat, star(.001) 

	*standardize income after description
	egen thincMean=mean(thinc)
	egen thincSD=sd(thinc)
	gen thinc2=(thinc-thincMean)/thincSD
	drop thinc
	rename thinc2 thinc
	
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

	generate i1=1.rhfo_None#1.ghto_None
	generate i2=1.rhfo_At#1.ghto_None
	generate i3=1.rhfo_Not#1.ghto_None
	generate i4=1.rhfo_None#1.ghto_At 
	generate i5=1.rhfo_At#1.ghto_At 
	generate i6=1.rhfo_Not#1.ghto_At 
	generate i7=1.rhfo_None#1.ghto_Not 
	generate i8=1.rhfo_At#1.ghto_Not 
	generate i9=1.rhfo_Not#1.ghto_Not 

	foreach n of numlist 1(1)9{
	bysort id: egen Mundlak_i`n'=mean(i`n')		
	}

	*visualize respondents over time
	vioplot age, over(Qyear) graphr(c(white)) title() subtitle() note() ytitle("age") ylab(, angle(horiz)) scheme(stmono1)
	graph export violinplot_v6_`IM'.tif, width(1600) height(1200) replace

	*visualize respondents average self-reported health (1 to 5) per year per country
	by country Qyear, sort: egen meanPlot=mean(sphus)
	separate meanPlot, by(country) gen(plot)
	label var plot11 "Austria"
	label var plot12 "Germany"
	label var plot13 "Sweden"
	label var plot14 "Netherlands"
	label var plot15 "Spain"
	label var plot16 "Italy"
	label var plot17 "France"
	label var plot18 "Denmark"
	label var plot20 "Switzerland"
	label var plot23 "Belgium"
	label var plot28 "Czech Republic"
	label var plot34 "Slovenia"
	twoway (line plot11 Qyear, lcolor(black) lpattern("l")) (line plot12 Qyear, lcolor(black) lpattern("_####_####")) (line plot13 Qyear, lcolor(black) lpattern("-_")) (line plot14 Qyear, lcolor(black) lpattern("_")) (line plot15 Qyear, lcolor(black) lpattern(".")) (line plot16 Qyear, lcolor(black) lpattern("..###..###")) (line plot17 Qyear, lcolor(black) lpattern(".-")) (line plot18 Qyear, lcolor(black) lpattern(".-##.-##")) (line plot20 Qyear, lcolor(black) lpattern("..##__##")) (line plot23 Qyear, lcolor(black) lpattern("-")) (line plot28 Qyear, lcolor(black) lpattern("-####-####")) (line plot34 Qyear, lcolor(black) lpattern("--__")), graphr(c(white)) xtitle("year") ytitle("health score") xlabel(2011 2013 2015 2017 2020 2022) legend(on) title() subtitle() note() scheme(stmono1)
	graph export meanplot_`IM'.tif, width(1600) height(1200) replace

	*MODELLING panels with level 

	*additional descriptives based on panel structure
	asdoc xttrans sphus, dec(3) save(transition_`IM'.doc)

	***Fixed effects estimator
	xtreg sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3).cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country, fe
	outreg2 using results_imp1_fe_`IM'.xls, excel replace stats(coef se) dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	*test for FE or RE use
	estimates store fixedR

	***Generalized least squares random effects estimator
	xtreg sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3).cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country, re
	outreg2 using results_imp1_re_`IM'.xls, excel replace stats(coef se) dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	*test for FE or RE use
	asdoc estat mundlak, save(REtest_`IM'.doc)
	xttest0
	estimates store randomR

	*test choice fixed with random
	asdoc hausman fixedR randomR, append save(REtest_`IM'.doc)

	***Correlated random effects estimator (with Mundlak means)
	xtreg sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3).cjs i.gali c.lifesat##c.lifesat ///
	i.naly i.rhfo##i.ghto ib(#3).country, cre vce(robust)
	outreg2 using results_imp1_cre_`IM'.xls, excel replace ///
	addstat(PanelLevelSD, `e(sigma_u)', RegresLevel, `e(sigma_e)', VarDueToInd, `e(rho)', ///
	MundlakChi2, `e(chi2_mundlak)', MundlakChiP, `e(p_mundlak)') stats(coef se) dec(3) alpha(0.001, 0.01, 0.05)

	xtreg sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3).cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country Mundlak_*, re vce(robust)
	outreg2 using results_imp1_Mundlak_`IM'.xls, excel replace stats(coef se) dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	asdoc test Mundlak_age Mundlak_thinc Mundlak_lifesat Mundlak_yedu Mundlak_age2 Mundlak_thinc2 Mundlak_lifesat2 Mundlak_yedu2 Mundlak_household_Single Mundlak_household_Couple Mundlak_household_Multiple Mundlak_covid_0 Mundlak_covid_1 Mundlak_cjs_Not Mundlak_cjs_Retired Mundlak_cjs_Employed Mundlak_cjs_Unemployed Mundlak_cjs_Permanently Mundlak_cjs_Homemaker Mundlak_cjs_Other Mundlak_gali_Not Mundlak_gali_Limited Mundlak_rhfo_None Mundlak_rhfo_At Mundlak_rhfo_Not Mundlak_ghto_None Mundlak_ghto_At Mundlak_ghto_Not Mundlak_naly_None Mundlak_naly_At Mundlak_naly_Not Mundlak_i1 Mundlak_i2 Mundlak_i3 Mundlak_i4 Mundlak_i5 Mundlak_i6 Mundlak_i7 Mundlak_i8 Mundlak_i9, save(Mundlak_`IM'.doc)

	***fixed effects ordered logit estimator with calibrated weights and robust standard errors
	feologit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt], or
	outreg2 using results_imp1_feo_`IM'.xls, excel stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) dec(3) ///
	alpha(0.001, 0.01, 0.05) symbol(***, **, *)

	***random effects ordered logit estimator with Mundlak means, calibrated weights and robust standard errors
	xtologit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender i.covid ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country Mundlak_* [pweight=my_wgt], or vce(robust)
	outreg2 using results_imp1_xto_`IM'.xls, excel replace stnum(replace coef=exp(coef), replace se=coef*se) cti(odds ratio) ///
	addstat(PanelLevelSD, `e(sigma_u)') dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *)
	asdoc test Mundlak_age Mundlak_thinc Mundlak_lifesat Mundlak_yedu Mundlak_age2 Mundlak_thinc2 Mundlak_lifesat2 Mundlak_yedu2 Mundlak_household_Single Mundlak_household_Couple Mundlak_household_Multiple Mundlak_covid_0 Mundlak_covid_1 Mundlak_cjs_Not Mundlak_cjs_Retired Mundlak_cjs_Employed Mundlak_cjs_Unemployed Mundlak_cjs_Permanently Mundlak_cjs_Homemaker Mundlak_cjs_Other Mundlak_gali_Not Mundlak_gali_Limited Mundlak_rhfo_None Mundlak_rhfo_At Mundlak_rhfo_Not Mundlak_ghto_None Mundlak_ghto_At Mundlak_ghto_Not Mundlak_naly_None Mundlak_naly_At Mundlak_naly_Not Mundlak_i1 Mundlak_i2 Mundlak_i3 Mundlak_i4 Mundlak_i5 Mundlak_i6 Mundlak_i7 Mundlak_i8 Mundlak_i9, save(xto_`IM'.doc)
	
	*additional slogit
	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2011, vce(robust)
	outreg2 using results_imp1_slo_`IM'.xls, excel replace dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2011)

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2013, vce(robust)
	outreg2 using results_imp1_slo_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2013)

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2015, vce(robust)
	outreg2 using results_imp1_slo_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2015)

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2017, vce(robust)
	outreg2 using results_imp1_slo_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2017)

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2020, vce(robust)
	outreg2 using results_imp1_slo_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2020)

	slogit sphus c.age##c.age c.yedu##c.yedu c.thinc##c.thinc i.gender ib(#1).household ib(#3)o2.cjs i.gali ///
	c.lifesat##c.lifesat i.naly i.rhfo##i.ghto ib(#3).country [pweight=my_wgt] if Qyear==2022, vce(robust)
	outreg2 using results_imp1_slo_`IM'.xls, excel dec(3) alpha(0.001, 0.01, 0.05) symbol(***, **, *) ctitle(2022)

	log close The_value_of_a_helping_hand
	translate output_v6_`IM'.smcl output_v6_`IM'.pdf
}