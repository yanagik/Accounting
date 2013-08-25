log using /mnt/home/ay32/STATA/pmcRM.log, replace

use /mnt/home/ay32/STATA/tradeprod.dta

// Set the data as a panel
destring gvkey, replace
xtset gvkey fyear

// Create labels for ESTTAB
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postreduction "$\text{Post-reduction}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostred "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchzero "$\text{Bench Zero}_{i,j,t}$"
label variable benchzeropostred "$\text{Bench Zero}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchlast "$\text{Bench Last}_{i,j,t}$"
label variable benchlastpostred "$\text{Bench Last}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

eststo clear

// Descriptives
estpost sum dprod bench benchzero benchlast size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /mnt/home/ay32/STATA/descriptivesprodtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

// Main result, overproduction
eststo: quietly reg dprod bench size mtb roa, r cl(gvkey)
eststo: quietly areg dprod bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg dprod bench postreduction benchpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /mnt/home/ay32/STATA/csrprodpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Robustness check, split by z-score
eststo: quietly areg dprod bench postreduction benchpostred size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod bench postreduction benchpostred size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /mnt/home/ay32/STATA/zprod.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Robustness check, split earnings benchmarks, first half
eststo: quietly areg dprod benchzero postreduction benchzeropostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod benchlast postreduction benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

clear

use /mnt/home/ay32/STATA/traderd.dta

// Set the data as a panel
destring gvkey, replace
xtset gvkey fyear

// Create fake dprod
generate dprod=.

// Create labels for ESTTAB
label variable drd "$\text{AR\&D}_{i,j,t}$"
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postreduction "$\text{Post-reduction}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostred "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchzero "$\text{Bench Zero}_{i,j,t}$"
label variable benchzeropostred "$\text{Bench Zero}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchlast "$\text{Bench Last}_{i,j,t}$"
label variable benchlastpostred "$\text{Bench Last}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

// Robustness check, split earnings benchmarks, second half
eststo: quietly areg drd benchzero postreduction benchzeropostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchlast postreduction benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /mnt/home/ay32/STATA/splitbench.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Descriptives, R&D
estpost sum drd bench benchzero benchlast size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /mnt/home/ay32/STATA/descriptivesrdtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

// Main result, R&D
eststo: quietly reg drd bench size mtb roa, r cl(gvkey)
eststo: quietly areg drd bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg drd bench postreduction benchpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /mnt/home/ay32/STATA/csrrdpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Robustness check, split by z-score
eststo: quietly areg drd bench postreduction benchpostred size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd bench postreduction benchpostred size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchzero postreduction benchzeropostred size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchzero postreduction benchzeropostred size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /mnt/home/ay32/STATA/zrd.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear
clear
// clear matrix

use /mnt/home/ay32/STATA/tradefrq2.dta

// Set the data as a panel
destring gvkey, replace
xtset gvkey fyear

// Create labels for ESTTAB
label variable frq "$\text{DAcc}_{i,j,t}$"
label variable postreduction "$\text{Post-reduction}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostred "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

eststo clear

estpost sum frq bench size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
// esttab using /mnt/home/ay32/STATA/descriptivesprodtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

// fm sgaat scaleint mv q intat deltasaleat deltasaleatdd, byfm(sictwo)
eststo: quietly reg frq bench size mtb roa, r cl(gvkey)
eststo: quietly areg frq bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
// eststo: quietly areg dprod postreduction size mtb roa i.fyear, absorb(gvkey) r cl(sicthree)
eststo: quietly areg frq bench postreduction benchpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /mnt/home/ay32/STATA/daccpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear
clear

// Bar graph
use /mnt/home/ay32/STATA/bargraph.dta
label variable cut "Number of tariff rate reductions"
label variable year "Year"

twoway bar cut year
graph export /mnt/home/ay32/STATA/fig1.eps, as(eps) replace

clear

filefilter /mnt/home/ay32/STATA/descriptivesprodtrade.tex /mnt/home/ay32/STATA/descriptivesprodtrade2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/descriptivesrdtrade.tex /mnt/home/ay32/STATA/descriptivesrdtrade2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/csrprodpostred.tex /mnt/home/ay32/STATA/csrprodpostred2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/csrrdpostred.tex /mnt/home/ay32/STATA/csrrdpostred2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/splitbench.tex /mnt/home/ay32/STATA/splitbench2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/zprod.tex /mnt/home/ay32/STATA/zprod2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/zrd.tex /mnt/home/ay32/STATA/zrd2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/daccpostred.tex /mnt/home/ay32/STATA/daccpostred2.tex, from("\BS_{") to ("_{") replace

log close

