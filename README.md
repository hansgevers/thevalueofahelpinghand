# thevalueofahelpinghand
Stata code and materials supporting the paper "The value of a helping hand"

To support reproducibility of the study, the Stata-files "data analysis.do" and "data preprocessing.do" are available. The former completes the analysis of all 5 estimators, plots, descriptives, and statistical tests. The latter generates the 5 imputed SHARE-datasets used based on the original complete datasets obtained via SHARE-ERIC. Both files are provided with comments, however, a minimum knowledge of Stata is advised to enable reproducing the results reported in the paper. To document the output of the file "data analysis.do", 5 Stata-log-files are available in pdf-format, one for each imputed dataset analysed. 

The calculation of calibrated longitudinal weights in the data preprocessing phase requires the do-files "4_CLIW.do" (4th Wave), "CalMar_long.do", and "margins_nuts1.dta". As the latter are included in the SHARE-package, for which registration is required, they are not made available. All three files are used as received, except for "4_CLIW.do" which has been reprogrammed to enable calculating the calibrated longitudinal weights from Wave 4 to Wave 9. To provide insight in the weighing procedure, illustrations of the calibrated longitudinal weights are available for the first imputed dataset used. Also, the illustrations used in the paper are included in high resolution without captions or titles.

Separate documentation is added to illustrate the stereotype ordered regressions and their margins which back the findings regardless the violation of the parallel regression assumption.
Note: For the Stereotype Ordered regressions, margins are referred to in the paper which are based on an interaction effect that is possibly not significant. Across years the interaction effect is 3 to 4 times sufficiently significant per imputed dataset.

Relevant hyperlinks:
www.share-eric.eu
www.stata.com

Author: Hans Gevers - https://orcid.org/0009-0001-0249-4142
