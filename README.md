# thevalueofahelpinghand
Supporting Stata code for the study The value of a helping hand

To support reproducibility of the study, the Stata-files data analysis.do and data preprocessing.do are available. The former completes the analysis of all 5 estimators, plots, descriptives, and the like. The latter generates the 5 imputed SHARE-datasets used based on the original complete datasets obtained via SHARE-ERIC. Both files are provided with comments to indicate the structure of the analysis. A minimum knowledge of Stata is advised to reproduce the results provided in this study.

Illustrations of the calibrated longitudinal weights are available, nevertheless, the calculation of these weights in the data preprocessing phase requires the do-files 4_CLIW.do (4th Wave), CalMar_long.do, and margins_nuts1.doc. As the latter are included in the SHARE-package, for which registration is required, they are not made available. All three files are used as received, except for 4_CLIW.do which has been modified to enable calculating the calibrated longitudinal weights from Wave 4 to Wave 9. Additionally, the illustrations used in the paper are included in high resolution without captions or titles.

www.share-eric.eu
