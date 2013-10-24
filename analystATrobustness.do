log using /mnt/home/ay32/STATA/analystCons.log, replace

use /mnt/home/ay32/STATA/cscorerobust.dta

// Set the data as a panel
destring gvkey, replace

// Generate bad news timeliness
gen bnt=cscore+gscore

// Create labels for ESTTAB
label variable coverage "$\text{Coverage}_{i,t}$"
label variable cscore "$\text{C-Score}_{i,t}$"
label variable gscore "$\text{G-Score}_{i,t}$"
label variable bnt "$\text{BNT}_{i,t}$"
label variable post "$\text{Post}_{i,t}$"
label variable treat "$\text{Treat}_{i,t}$"
label variable posttreat "$\text{Post}_{i,t}\times\text{Treat}_{i,t}$"
label variable posttreatpann "$\text{Post}_{i,t}\times\text{Treat}_{i,t}\times\text{NRec}_{i,t}$"
label variable posttreatnpann "$\text{Post}_{i,t}\times\text{Treat}_{i,t}\times\text{PRec}_{i,t}$"
label variable assets "$\text{Size}_{i,t}$"
label variable mtb "$\text{MTB}_{i,t}$"
label variable lev "$\text{Leverage}_{i,t}$"

eststo clear

eststo: quietly reg coverage post treat posttreat, r cl(gvkey)
eststo: quietly areg coverage post treat posttreat, absorb(gvkey) r cl(gvkey)
eststo: quietly reg bnt post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg bnt post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/bntrobust.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

eststo: quietly reg cscore post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg cscore post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)
eststo: quietly reg gscore post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg gscore post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/cscorerobust.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

clear

filefilter /mnt/home/ay32/STATA/bntrobust.tex /mnt/home/ay32/STATA/bntrobust2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/cscorerobust.tex /mnt/home/ay32/STATA/cscorerobust2.tex, from("\BS_{") to ("_{") replace
log close

