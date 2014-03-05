set more off

log using /home/FUQUA/ay32/STATA/pmcRM.log, replace

*http://statalist.1588530.n2.nabble.com/st-re-combined-Correlationmatrix-Pearson-and-Spearman-LaTeX-output-td1637098.html
capt prog drop corrmat
*! corrmat CFB 2008dec09
prog corrmat
version 10.1
syntax varlist(numeric) using/
qui spearman `varlist', pw
tempname c
mat `c' = r(Rho)
local k: word count `varlist'
forv i = 2/`k' {
        local f: word `i' of `varlist'
        forv j = 1/`=`i'-1' {
                local s: word `j' of `varlist'
                qui corr `f' `s'
                mat `c'[`i', `j'] = r(rho)
        }
}
outtable using `using', mat(`c') replace format(%9.4f)
di _n "Spearman/Pearson correlations written to `using'.tex" _n
end 

// Overproduction
use /home/FUQUA/ay32/STATA/tradeprod3.dta

destring gvkey, replace
xtset gvkey fyear

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
estpost sum dprod bench benchpostredv benchzero benchlast size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /home/FUQUA/ay32/STATA/descriptivesprodtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

egen rdprod=rank(dprod)
egen rbench=rank(bench)
egen rbenchpostredv=rank(benchpostredv)
egen rbenchzero=rank(benchzero)
egen rbenchlast=rank(benchlast)
egen rsize=rank(size)
egen rmtb=rank(mtb)
egen rroa=rank(roa)

label variable rdprod "$\text{APC}_{i,j,t}$"
label variable rbench "$\text{Bench}_{i,j,t}$"
label variable rbenchpostredv "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable rbenchzero "$\text{Bench Zero}_{i,j,t}$"
label variable rbenchlast "$\text{Bench Last}_{i,j,t}$"
label variable rsize "$\text{Size}_{i,j,t}$"
label variable rmtb "$\text{MTB}_{i,j,t}$"
label variable rroa "$\text{ROA}_{i,j,t}$"

/*
You have to manually edit and then reconvert this.
estpost correlate dprod bench benchpostredv benchzero benchlast size mtb roa, matrix quietly
esttab using /home/FUQUA/ay32/STATA/prodcorr.tex, replace label notype unstack compress noobs nonotes nonumbers booktabs nomtitles f gaps plain

estpost correlate rdprod rbench rbenchpostredv rbenchzero rbenchlast rsize rmtb rroa, matrix quietly
esttab using /home/FUQUA/ay32/STATA/prodcorr.tex, append label notype unstack compress noobs nonotes nonumbers booktabs nomtitles f gaps plain
*/
//cells(rho(fmt(3)star)) 
estpost correlate dprod bench size mtb roa, matrix listwise
esttab, unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain
esttab using /home/FUQUA/ay32/STATA/prodcorr.tex, replace cells(rho(fmt(3)star)) unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain

estpost correlate rdprod rbench rsize rmtb rroa, matrix listwise
esttab, unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain
esttab using /home/FUQUA/ay32/STATA/prodcorr.tex, append cells(rho(fmt(3)star)) unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain

eststo clear

// corrmat dprod bench benchpostredv benchzero benchlast size mtb roa using prodcorr

eststo clear

// Main result, overproduction
eststo: quietly reg dprod bench size mtb roa, r cl(gvkey)
eststo: quietly areg dprod bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg dprod bench postreductionv benchpostredv size mtb roa i.fyear, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg dprod bench postreductionf benchpostredf size mtb roa i.year, absorb(gvkey) r cl(sicthree)
test bench+benchpostredv=0
estadd scalar pval=r(p)
*eststo: quietly areg dprod bench beforeone beforezero afterone aftertwo benchbeforeone benchbeforezero benchafterone benchaftertwo size mtb roa i.fyear, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *fyear) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" "$\mathbf{H}_{0}: \text{Managers do not overproduce to meet or beat earnings targets}$"))

esttab using /home/FUQUA/ay32/STATA/csrprodpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{No overproduction to meet or beat earnings targets}$"))

eststo clear


// Robustness check, split by analyst coverage (yes or no)
eststo: quietly areg dprod bench postreductionv benchpostredv size mtb roa i.fyear if hasann==0, absorb(gvkey) r cl(sicthree)
test bench+benchpostredv=0
estadd scalar pval=r(p)
eststo: quietly areg dprod bench postreductionv benchpostredv size mtb roa i.fyear if hasann==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" "$\mathbf{H}_{0}: \text{Managers do not overproduce to meet or beat earnings targets}$"))

esttab using /home/FUQUA/ay32/STATA/prodibes.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{No overproduction to meet or beat earnings targets}$"))

eststo clear

// Robustness check, split earnings benchmarks, first half
//eststo: quietly areg dprod benchzero postreductionv benchzeropostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg dprod benchlast postreductionv benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg dprod benchzero benchlast postreductionv benchzeropostred benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
test benchlast+benchlastpostred=0
estadd scalar pvalprod=r(p)

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
//eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg drd benchlast postreductionv benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd benchzero benchlast postreductionv benchzeropostred benchlastpostred size mtb roa i.year, absorb(gvkey) r cl(sicthree)
test benchzero+benchzeropostred=0
estadd scalar pvalrd=r(p)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pvalprod pvalrd, labels("Observations" "$\textit{R}^2$" "$ \mathbf{H}_{0}: \text{Managers do not overproduce to meet or beat earnings targets}$" "$\mathbf{H}_{0}: \text{Managers do not cut R\&D to meet or beat earnings targets}$"))

esttab using /home/FUQUA/ay32/STATA/splitbench.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pvalprod pvalrd, labels("Observations" "$\textit{R}^{2}$" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{No overproduction to meet or beat last year's earnings}$" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{R\&D not cut to meet or beat zero earnings}$"))

eststo clear

// Descriptives, R&D
estpost sum drd bench benchpostredv benchzero benchlast size mtb roa, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /home/FUQUA/ay32/STATA/descriptivesrdtrade.tex, replace label cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

egen rdrd=rank(drd)
egen rbench=rank(bench)
egen rbenchpostredv=rank(benchpostredv)
egen rbenchzero=rank(benchzero)
egen rbenchlast=rank(benchlast)
egen rsize=rank(size)
egen rmtb=rank(mtb)
egen rroa=rank(roa)

label variable rdrd "$\text{AR\&D}_{i,j,t}$"
label variable rbench "$\text{Bench}_{i,j,t}$"
label variable rbenchpostredv "$\text{Bench}_{i,j,t}\times\text{Post-reduction}_{j,t}$"
label variable rbenchzero "$\text{Bench Zero}_{i,j,t}$"
label variable rbenchlast "$\text{Bench Last}_{i,j,t}$"
label variable rsize "$\text{Size}_{i,j,t}$"
label variable rmtb "$\text{MTB}_{i,j,t}$"
label variable rroa "$\text{ROA}_{i,j,t}$"

/*estpost correlate drd bench benchpostredv benchzero benchlast size mtb roa, matrix quietly
esttab using /home/FUQUA/ay32/STATA/rdcorr.tex, replace label notype unstack compress noobs nonotes nonumbers booktabs nonum nomtitles f gaps plain

estpost correlate rdrd rbench rbenchpostredv rbenchzero rbenchlast rsize rmtb rroa, matrix quietly
esttab using /home/FUQUA/ay32/STATA/rdcorr.tex, append label notype unstack compress noobs nonotes nonumbers booktabs nonum nomtitles f gaps plain
*/

//cells(rho(fmt(3)star)) 
estpost correlate drd bench size mtb roa, matrix listwise
esttab, unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain
esttab using /home/FUQUA/ay32/STATA/rdcorr.tex, replace cells(rho(fmt(3)star)) unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain

estpost correlate rdrd rbench rsize rmtb rroa, matrix listwise
esttab, unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain
esttab using /home/FUQUA/ay32/STATA/rdcorr.tex, append cells(rho(fmt(3)star)) unstack not noobs compress label nonotes nonumbers booktabs nomtitles f gaps plain


//corrmat drd bench benchpostredv benchzero benchlast size mtb roa using rdcorr

eststo clear 

// Main result, R&D
eststo: quietly reg drd bench size mtb roa, r cl(gvkey)
eststo: quietly areg drd bench size mtb roa i.fyear, absorb(gvkey) r cl(gvkey)
eststo: quietly areg drd bench postreductionv benchpostredv size mtb roa i.year, absorb(gvkey) r cl(sicthree)
test bench+benchpostredv=0
estadd scalar pval=r(p)
//eststo: quietly areg drd bench postreductionf benchpostredf size mtb roa i.year, absorb(gvkey) r cl(sicthree)
*eststo: quietly areg drd benchzero beforeone beforezero afterone aftertwo benchbeforeone benchbeforezero benchafterone benchaftertwo size mtb roa i.fyear, absorb(gvkey) r cl(sicthree)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^2$" "$\mathbf{H}_{0}: \text{Managers do not cut R\&D to meet or beat earnings targets}$"))

esttab using /home/FUQUA/ay32/STATA/csrrdpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}$" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{R\&D not cut to meet or beat earnings targets}$"))

eststo clear

/*// Robustness check, split by z-score
eststo: quietly areg drd bench postreductionv benchpostredv size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
eststo: quietly areg drd bench postreductionv benchpostredv size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.year if zrank==0, absorb(gvkey) r cl(sicthree)
//eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.year if zrank==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
esttab using /home/FUQUA/ay32/STATA/zrd.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3)))
*/

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
test bench+benchpostred=0
estadd scalar pval=r(p)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" ""$ \mathbf{H}_{0}: \text{Managers do not use AM to meet or beat earnings benchmarks}$"))

esttab using /home/FUQUA/ay32/STATA/daccpostred.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}$" "$ \mathbf{H}_{0}: \text{Managers do not use AM to meet or beat earnings benchmarks}$"))

eststo clear

// Robustness check, split by analyst coverage (yes or no)
eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.fyear if hasann==0, absorb(gvkey) r cl(sicthree)
test benchzero+benchzeropostred=0
estadd scalar pval=r(p)
eststo: quietly areg drd benchzero postreductionv benchzeropostred size mtb roa i.fyear if hasann==1, absorb(gvkey) r cl(sicthree)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" "$\mathbf{H}_{0}: \text{Managers do not overproduce to meet or beat earnings targets}$"))

esttab using /home/FUQUA/ay32/STATA/rdibes.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{No overproduction to meet or beat earnings targets}$"))

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
test bench+benchposttreatthree=0
estadd scalar pval=r(p)

esttab, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a pval, labels("Observations" "$\textit{R}^{2}$" "$ \mathbf{H}_{0}: \text{Managers do not use overproduction to meet or beat earnings benchmarks}$"))

esttab using /home/FUQUA/ay32/STATA/prodhk.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N pval, labels("Observations" "$\textit{R}^{2}$" "$\textit{p}-\text{value of } \mathbf{H}_{0}: \text{No overproduction to meet or beat earnings benchmarks}$"))

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

//eststo: quietly areg dprod bench postincreasev benchpostincv size mtb roa i.year, absorb(gvkey) r cl(sicthree)
eststo: quietly ivregress 2sls dprod bench size mtb roa (postincreasev benchpostincv=merlag benchmerlag) i.year, r cl(sicthree)
eststo: quietly reg postincreasev bench size mtb roa merlag benchmerlag i.year, r cl(sicthree)
test merlag=benchmerlag=0
estadd scalar F_post=r(F)
eststo: quietly reg benchpostincv bench size mtb roa merlag benchmerlag i.year, r cl(sicthree)
test merlag=benchmerlag=0
estadd scalar F_benchpost=r(F)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3))) stats(N r2_a F_post F_benchpost, labels("Observations" "$R^2$" "\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are  insignificant}$" "\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are  insignificant}$")) 
//esttab using /home/FUQUA/ay32/STATA/iv.tex, label se star(* 0.10 ** 0.05 *** 0.01) indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N F_post F_benchpost, labels("Observations" "\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are  insignificant}$" "\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are  insignificant}$"))

eststo clear

// mtitles("OLS" "First Stage" "First Stage" "Second Stage") 

/*eststo: quietly reg postincreasev bench size mtb roa merlag benchmerlag i.year, r cl(sicthree)
test merlag=benchmerlag=0
estadd scalar F_post=r(F)
eststo: quietly reg benchpostincv bench size mtb roa merlag benchmerlag i.year, r cl(sicthree)
test merlag=benchmerlag=0
estadd scalar F_benchpost=r(F)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) replace indicate(Year Fixed Effects = *year) f cells(b(fmt(3)star) se(par fmt(3))) stats(F_post F_benchpost, labels("$\mathbf{H}_{0}: \text{Instruments are  insignificant}$" "$\mathbf{H}_{0}: \text{Instruments are  insignificant}$"))
esttab using /home/FUQUA/ay32/STATA/ivfs.tex, label se star(* 0.10 ** 0.05 *** 0.01) indicate(Year Fixed Effects = *year) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(F_post F_benchpost, labels("\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are  insignificant}$" "\textit{F}-\text{test of} $\mathbf{H}_{0}: \text{Instruments are  insignificant}$"))
eststo clear*/
clear

// Appendix validating setting and need for IVs
use /home/FUQUA/ay32/STATA/industryyear.dta

// Create labels for ESTTAB
label variable imp "$\textit{imp}_{j,t}$"
label variable postreductionv "$\text{Post-reduction}_{j,t}$"
label variable postincreasev "$\text{Post-increase}_{j,t}$"
label variable merlag "$\textit{mer}_{j,t-1}$"
eststo clear

eststo: quietly reg imp postreductionv, r cl(sicthree)
eststo: quietly reg imp postincreasev, r cl(sicthree)
eststo: quietly reg postincreasev imp, r cl(sicthree)
eststo: quietly reg postincreasev merlag, r cl(sicthree)
test merlag=0
estadd scalar F_test=r(F)
eststo: quietly ivregress 2sls imp (postincreasev=merlag), r cl(sicthree)
esttab, label se star(* 0.10 ** 0.05 *** 0.01) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(F_test, labels("\textit{F}-\text{test of } $\mathbf{H}_{0}: \text{Instrument is insignificant}$"))
esttab using /home/FUQUA/ay32/STATA/appendixb.tex, label se star(* 0.10 ** 0.05 *** 0.01) replace f cells(b(fmt(3)star) se(par fmt(3))) stats(N F_test, labels("Observations" "$\mathbf{H}_{0}: \text{Instrument is insignificant}$"))
eststo clear
clear


/*
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
//mer merlag mertreat merlagtreat benchmertreat benchmerlagtreat
eststo clear
clear*/

// Bar graph
use /home/FUQUA/ay32/STATA/bargraph3.dta
label variable cut "Number of tariff rate reductions"
label variable year "Year"

twoway bar cut year
graph export /home/FUQUA/ay32/STATA/fig1b.eps, as(eps) replace

clear

// Tariffs decrease graph
// Bar graph
use /home/FUQUA/ay32/STATA/eventtime.dta

gen avtperc=avt*100
label variable avtperc "Import tariff rate"
label variable sumby "Years before and after tariff rate reduction"

twoway connected avtperc sumby, yscale(range(3 6))
// graph export /home/FUQUA/ay32/STATA/fig2.eps, as(eps) replace

clear

// decinc.dta

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
//filefilter /home/FUQUA/ay32/STATA/ivhk.tex /home/FUQUA/ay32/STATA/ivhk2.tex, from("\BS_{") to ("_{") replace
//filefilter /home/FUQUA/ay32/STATA/ivfs.tex /home/FUQUA/ay32/STATA/ivfs2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/appendixb.tex /home/FUQUA/ay32/STATA/appendixb2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/prodcorr.tex /home/FUQUA/ay32/STATA/prodcorr2.tex, from("\BS_{") to ("_{") replace
filefilter /home/FUQUA/ay32/STATA/rdcorr.tex /home/FUQUA/ay32/STATA/rdcorr2.tex, from("\BS_{") to ("_{") replace


log close

