set more off

log using /home/FUQUA/ay32/STATA/pmcRM.log, replace

// Overproduction
use /home/FUQUA/ay32/STATA/tradeprod3.dta

// Create labels for ESTTAB
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postreductionv "$\text{Post-reduction}_{j,t}$"
label variable postreductionf "$\text{Post-reduction}_{j,t}$"
label variable postreductionmy "$\text{Post-reduction}_{j,t}$"
label variable postincreasev "$\text{Post-increase}_{j,t}$"
label variable postincreasef "$\text{Post-increase}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostredv "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchpostredf "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchpostredmy "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchzero "$\text{Bench Zero}_{i,j,t}$"
label variable benchzeropostred "$\text{Bench Zero}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchlast "$\text{Bench Last}_{i,j,t}$"
label variable benchlastpostred "$\text{Bench Last}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchpostincv "$\text{Bench}_{i,j,t}\times\text{Post-increase}_{j,t}$"
label variable benchpostincf "$\text{Bench}_{i,j,t}\times\text{Post-increase}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

eststo clear

// Descriptives
estpost sum dprod bench benchzero benchlast size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /home/FUQUA/ay32/STATA/descriptivesprodtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

// Main result, overproduction
eststo: quietly reg dprod bench size mtb roa, r cl(gvkey)
eststo: quietly areg dprod bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg dprod bench postreductionv benchpostredv size mtb roa i.year, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg dprod bench postreductionf benchpostredf size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/csrprodpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Increases in tariffs
/*eststo: quietly areg dprod bench postincreasev benchpostincv size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod bench postreductionmy benchpostredmy size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/csrprodpostinc.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear*/

// Robustness check, split by z-score
eststo: quietly areg dprod bench postreductionv benchpostredv size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod bench postreductionv benchpostredv size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/zprod.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Robustness check, split earnings benchmarks, first half
eststo: quietly areg dprod benchzero postreductionv benchzeropostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod benchlast postreductionv benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

clear

// Abnormal R&D
use /home/FUQUA/ay32/STATA/traderd3.dta

// Set the data as a panel
destring gvkey, replace
xtset gvkey fyear

// Create fake dprod for esttab
generate dprod=.

// Create labels for ESTTAB
label variable drd "$\text{AR\&D}_{i,j,t}$"
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postreductionv "$\text{Post-reduction}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostredv "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchzero "$\text{Bench Zero}_{i,j,t}$"
label variable benchzeropostred "$\text{Bench Zero}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchlast "$\text{Bench Last}_{i,j,t}$"
label variable benchlastpostred "$\text{Bench Last}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

// Robustness check, split earnings benchmarks, second half
eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchlast postreductionv benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/splitbench.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Descriptives, R&D
estpost sum drd bench benchzero benchlast size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /home/FUQUA/ay32/STATA/descriptivesrdtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

// Main result, R&D
eststo: quietly reg drd bench size mtb roa, r cl(gvkey)
eststo: quietly areg drd bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg drd bench postreductionv benchpostredv size mtb roa i.year, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg drd bench postreductionf benchpostredf size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/csrrdpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// Robustness check, split by z-score
eststo: quietly areg drd bench postreductionv benchpostredv size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd bench postreductionv benchpostredv size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/zrd.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear
clear
// clear matrix

// Accruals-based earnings management
use /home/FUQUA/ay32/STATA/tradefrq3.dta

// Set the data as a panel
destring gvkey, replace
xtset gvkey fyear

// Create labels for ESTTAB
label variable frq "$\text{DAcc}_{i,j,t}$"
label variable postreductionv "$\text{Post-reduction}_{j,t}$"
label variable postreductionf "$\text{Post-reduction}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostred "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable benchpostredf "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

eststo clear

estpost sum frq bench size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
// esttab using /home/FUQUA/ay32/STATA/descriptivesprodtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

// fm sgaat scaleint mv q intat deltasaleat deltasaleatdd, byfm(sictwo)
eststo: quietly reg frq bench size mtb roa, r cl(gvkey)
eststo: quietly areg frq bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg frq bench postreductionv benchpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg frq bench postreductionf benchpostredf size mtb roa i.year, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/daccpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear
clear

// Alternate research design
use /home/FUQUA/ay32/STATA/prodhk.dta

// Set the data as a panel
destring gvkey, replace

// Create labels for ESTTAB
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postthree "$\text{Post-reduction}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable posttreatthree "$\text{Post-reduction}_{j,t}\times\text{Treat}_{i,j,t}$"
label variable treat "$\text{Treat}_{i,j,t}$"
label variable benchposttreatthree "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}\times\text{Treat}_{i,j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"

eststo clear

//eststo: quietly areg dprod bench postone treat posttreatone benchposttreatone size mtb roa i.year, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg dprod bench posttwo treat posttreattwo benchposttreattwo size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod bench postthree treat posttreatthree benchposttreatthree size mtb roa i.year, absorb(gvkey) r cl(sicthree)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/prodhk.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

clear

// Instrumental Variables
use /home/FUQUA/ay32/STATA/tradeprod3iv.dta

// Create labels for ESTTAB
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postincreasev "$\text{Post-increase}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostincv "$\text{Bench}_{i,j,t}\times\text{Post-increase}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"
label variable merlag "$\textit{mer}_{j,t-1}$"
label variable benchmerlag "$\text{Bench}_{i,j,t}\times\textit{mer}_{j,t-1}$"
eststo clear

eststo: quietly reg dprod bench postincreasev benchpostincv size mtb roa i.year, r cl(sicthree)
eststo: quietly ivregress 2sls dprod bench size mtb roa (postincreasev benchpostincv=merlag benchmerlag) i.year, r cl(sicthree)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3))) depvars
esttab using /home/FUQUA/ay32/STATA/iv.tex, label se star(* 0.10 ** 0.05 *** 0.01) indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

// mtitles("OLS" "First Stage" "First Stage" "Second Stage") 

eststo: quietly reg postincreasev bench size mtb roa merlag benchmerlag i.year, r cl(sicthree)
test merlag=benchmerlag=0
estadd scalar F_post=r(F)
eststo: quietly reg benchpostincv bench size mtb roa merlag benchmerlag i.year, r cl(sicthree)
test merlag=benchmerlag=0
estadd scalar F_benchpost=r(F)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3))) stats(F_post F_benchpost, labels("$\mathbf{H}_{0}: \text{Instruments are jointly insignificant}$" "$\mathbf{H}_{0}: \text{Instruments are jointly insignificant}$"))
esttab using /home/FUQUA/ay32/STATA/ivfs.tex, label se star(* 0.10 ** 0.05 *** 0.01) indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(F_post F_benchpost, labels("\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are jointly insignificant}$" "\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are jointly insignificant}$"))
eststo clear
clear

// Instrumental variables, alternative research design
use /home/FUQUA/ay32/STATA/prodinchkfediv2.dta

// Create labels for ESTTAB
label variable dprod "$\text{APC}_{i,j,t}$"
label variable postincreasev "$\text{Post-increase}_{j,t}$"
label variable bench "$\text{Bench}_{i,j,t}$"
label variable benchpostincv "$\text{Bench}_{i,j,t}\times\text{Post-increase}_{j,t}$"
label variable size "$\text{Size}_{i,j,t}$"
label variable mtb "$\text{MTB}_{i,j,t}$"
label variable roa "$\text{ROA}_{i,j,t}$"
label variable treat "$\text{Treat}_{i,j,t}$"
label variable postinc "$\text{Post-increase}_{j,t}$"
label variable postinctreat "$\text{Treat}_{i,j,t}\times\text{Post-increase}_{j,t}$"
label variable benchpostinctreat "$\text{Bench}_{i,j,t}\times\text{Treat}_{i,j,t}\times\text{Post-increase}_{j,t}$"

eststo: quietly reg dprod bench treat postinc postinctreat benchpostinctreat size mtb roa i.year, r cl(sicthree)
eststo: quietly ivregress 2sls dprod bench treat size mtb roa (postinc postinctreat benchpostinctreat=mer merlag mertreat merlagtreat benchmertreat benchmerlagtreat) i.year, r cl(sicthree)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/ivhk.tex, label se star(* 0.10 ** 0.05 *** 0.01) indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) mtitles("OLS" "IV") depvars

eststo clear
clear

// Bar graph
use /home/FUQUA/ay32/STATA/bargraph3.dta
label variable cut "Number of tariff rate reductions"
label variable year "Year"

twoway bar cut year
graph export /home/FUQUA/ay32/STATA/fig1b.eps, as(eps) replace

clear

/*use /home/FUQUA/ay32/STATA/sixteen.dta
label variable avt "Ad valorem tariff rate"
label variable year "Year"

twoway line avt year if sicthree==399
graph export /home/FUQUA/ay32/STATA/sic399.eps, as(eps) replace

clear*/

filefilter /home/FUQUA/ay32/STATA/descriptivesprodtrade.tex /home/FUQUA/ay32/STATA/descriptivesprodtrade2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/descriptivesrdtrade.tex /home/FUQUA/ay32/STATA/descriptivesrdtrade2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/csrprodpostred.tex /home/FUQUA/ay32/STATA/csrprodpostred2.tex, from("\BS_{") to ("_{") replace
//filefilter /home/FUQUA/ay32/STATA/csrprodpostinc.tex /home/FUQUA/ay32/STATA/csrprodpostinc2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/csrrdpostred.tex /home/FUQUA/ay32/STATA/csrrdpostred2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/splitbench.tex /home/FUQUA/ay32/STATA/splitbench2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/zprod.tex /home/FUQUA/ay32/STATA/zprod2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/zrd.tex /home/FUQUA/ay32/STATA/zrd2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/daccpostred.tex /home/FUQUA/ay32/STATA/daccpostred2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/prodhk.tex /home/FUQUA/ay32/STATA/prodhk2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/iv.tex /home/FUQUA/ay32/STATA/iv2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/ivhk.tex /home/FUQUA/ay32/STATA/ivhk2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/ivfs.tex /home/FUQUA/ay32/STATA/ivfs2.tex, from("\BS_{") to ("_{") replace

log close

