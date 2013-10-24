log using /mnt/home/ay32/STATA/analystCons.log, replace

use /mnt/home/ay32/STATA/cscore2.dta

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

estpost sum coverage cscore gscore bnt treat posttreat posttreatpann posttreatnpann assets mtb lev, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /mnt/home/ay32/STATA/descscore.tex, replace label cells("mean(fmt(3)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

eststo: quietly reg coverage post treat posttreat, r cl(gvkey)
eststo: quietly areg coverage post treat posttreat, absorb(gvkey) r cl(gvkey)
eststo: quietly reg bnt post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg bnt post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/bnt.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

eststo: quietly reg cscore post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg cscore post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)
eststo: quietly reg gscore post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg gscore post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/cscore.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

eststo: quietly reg cscore post treat posttreatpann posttreatnpann assets mtb lev, r cl(gvkey)
eststo: quietly areg cscore post treat posttreatpann posttreatnpann assets mtb lev, absorb(gvkey) r cl(gvkey)
eststo: quietly reg gscore post treat posttreatpann posttreatnpann assets mtb lev, r cl(gvkey)
eststo: quietly areg gscore post treat posttreatpann posttreatnpann assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/cscorep.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

eststo: quietly reg bnt post treat posttreatpann posttreatnpann assets mtb lev, r cl(gvkey)
eststo: quietly areg bnt post treat posttreatpann posttreatnpann assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/bntp.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

clear

/*use /mnt/home/ay32/STATA/conacc2.dta

// Set the data as a panel
destring gvkey, replace

// Create labels for ESTTAB
label variable con "$\text{Con-Acc}_{i,t}$"
label variable coverage "$\text{Coverage}_{i,t}$"
label variable post "$\text{Post}_{i,t}$"
label variable treat "$\text{Treat}_{i,t}$"
label variable posttreat "$\text{Post}_{i,t}\times\text{Treat}_{i,t}$"
label variable posttreatpann "$\text{Post}_{i,t}\times\text{Treat}_{i,t}\times\text{NRec}_{i,t}$"
label variable posttreatnpann "$\text{Post}_{i,t}\times\text{Treat}_{i,t}\times\text{PRec}_{i,t}$"
label variable assets "$\text{Size}_{i,t}$"
label variable mtb "$\text{MTB}_{i,t}$"
label variable lev "$\text{Leverage}_{i,t}$"

estpost sum coverage con treat posttreat assets mtb lev, detail listwise
esttab, cells("mean sd min p50 max")
esttab using /mnt/home/ay32/STATA/desconacc.tex, replace label cells("mean(fmt(3)) sd(fmt(2)) min(fmt(2)) p50(fmt(2)) max(fmt(2))") booktabs nonum nomtitles f gaps plain

eststo clear

eststo: quietly reg coverage post treat posttreat, r cl(gvkey)
eststo: quietly areg coverage post treat posttreat, absorb(gvkey) r cl(gvkey)
eststo: quietly reg con post treat posttreat assets mtb lev, r cl(gvkey)
eststo: quietly areg con post treat posttreat assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/conacc.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))

eststo clear

eststo: quietly reg con post treat posttreatpann posttreatnpann assets mtb lev, r cl(gvkey)
eststo: quietly areg con post treat posttreatpann posttreatnpann assets mtb lev, absorb(gvkey) r cl(gvkey)

esttab, ar2 se star(* 0.10 ** 0.05 *** 0.01) // indicate("Year Fixed Effects = *fyear" "Industry Fixed Effects = *sictwo")

esttab using /mnt/home/ay32/STATA/conaccp.tex, label se star(* 0.10 ** 0.05 *** 0.01) ar2 replace f cells(b(fmt(3)star) se(par fmt(3)))
eststo clear

clear*/

// clear matrix
filefilter /mnt/home/ay32/STATA/descscore.tex /mnt/home/ay32/STATA/descscore2.tex, from("\BS_{") to ("_{") replace
//filefilter /mnt/home/ay32/STATA/desconacc.tex /mnt/home/ay32/STATA/desconacc2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/bnt.tex /mnt/home/ay32/STATA/bnt2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/bntp.tex /mnt/home/ay32/STATA/bntp2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/cscore.tex /mnt/home/ay32/STATA/cscore2.tex, from("\BS_{") to ("_{") replace
filefilter /mnt/home/ay32/STATA/cscorep.tex /mnt/home/ay32/STATA/cscorep2.tex, from("\BS_{") to ("_{") replace
//filefilter /mnt/home/ay32/STATA/conacc.tex /mnt/home/ay32/STATA/conacc2.tex, from("\BS_{") to ("_{") replace
//filefilter /mnt/home/ay32/STATA/conaccp.tex /mnt/home/ay32/STATA/conaccp2.tex, from("\BS_{") to ("_{") replace

log close

