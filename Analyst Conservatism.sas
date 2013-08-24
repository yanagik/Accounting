*libname temp 'C:\Users\Temp\Documents\Summer 2013';
libname temp 'D:\ay32\My Documents\Fall 2013';

/**********************************************************************************************/
/* FILENAME:        Winsorize_Truncate.sas                                                    */
/* ORIGINAL AUTHOR: Steve Stubben (Stanford University)                                       */
/* MODIFIED BY:     Ryan Ball (UNC-Chapel Hill)                                               */
/* DATE CREATED:    August 3, 2005                                                            */
/* LAST MODIFIED:   August 3, 2005                                                            */
/* MACRO NAME:      Winsorize_Truncate                                                        */
/* ARGUMENTS:       1) DSETIN: input dataset containing variables that will be win/trunc.     */
/*                  2) DSETOUT: output dataset (leave blank to overwrite DSETIN)              */
/*                  3) BYVAR: variable(s) used to form groups (leave blank for total sample)  */
/*                  4) VARS: variable(s) that will be winsorized/truncated                    */
/*                  5) TYPE: = W to winsorize and = T (or anything else) to truncate          */
/*                  6) PCTL = percentile points (in ascending order) to truncate/winsorize    */
/*                            values.  Default is 1st and 99th percentiles.                   */
/* DESCRIPTION:     This macro is capable of both truncating and winsorizing one or multiple  */
/*                  variables.  Truncated values are replaced with a missing observation      */
/*                  rather than deleting the observation.  This gives the user more control   */
/*                  over the resulting dataset.                                               */
/* EXAMPLE(S):      1) %Winsorize_Truncate(dsetin = mydata, dsetout = mydata2, byvar = year,  */
/*                          vars = assets earnings, type = W, pctl = 0 98)                    */
/*                      ==> Winsorizes by year at 98% and puts resulting dataset into mydata2 */
/**********************************************************************************************/

*Get everything from WRDS needed to construct the natural experiment "setting";
*Log in to WRDS;
%let wrds = wrds.wharton.upenn.edu 4016; 		
options comamid=TCP remote=WRDS;				
signon username=_prompt_ ;
rsubmit;

*You have to upload the data from Marcin Kacperczyk;
libname remote '/home/duke/ay32';

*Winsorize and truncation macro;
%macro Winsorize_Truncate(dsetin = , 
                          dsetout = , 
                          byvar = none, 
                          vars = , 
                          type = W, 
                          pctl = 1 99);

    %if &dsetout = %then %let dsetout = &dsetin;
    
    %let varL=;
    %let varH=;
    %let xn=1;

    %do %until (%scan(&vars,&xn)= );
        %let token = %scan(&vars,&xn);
        %let varL = &varL &token.L;
        %let varH = &varH &token.H;
        %let xn = %EVAL(&xn + 1);
    %end;

    %let xn = %eval(&xn-1);

    data xtemp;
        set &dsetin;

    %let dropvar = ;
    %if &byvar = none %then %do;
        data xtemp;
            set xtemp;
            xbyvar = 1;

        %let byvar = xbyvar;
        %let dropvar = xbyvar;
    %end;

    proc sort data = xtemp;
        by &byvar;

    /*compute percentage cutoff values*/
    proc univariate data = xtemp noprint;
        by &byvar;
        var &vars;
        output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = L H;

    data &dsetout;
        merge xtemp xtemp_pctl; /*merge percentage cutoff values into main dataset*/
        by &byvar;
        array trimvars{&xn} &vars;
        array trimvarl{&xn} &varL;
        array trimvarh{&xn} &varH;

        do xi = 1 to dim(trimvars);
            /*winsorize variables*/
            %if &type = W %then %do;
                if trimvars{xi} ne . then do;
                    if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
                    if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
                end;
            %end;
            /*truncate variables*/
            %else %do;
                if trimvars{xi} ne . then do;
                    /*insert .T code if value is truncated*/
                    if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = .T;
                    if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = .T;
                end;
            %end;
        end;
        drop &varL &varH &dropvar xi;

    /*delete temporary datasets created during macro execution*/
    proc datasets library=work nolist;
        delete xtemp xtemp_pctl; quit; run;

%mend;

*IBES data;
proc sql;
create table ibes
as select a.ticker,
		  a.cusip,
		  a.oftic,
		  a.cname,
		  a.anndats,
		  a.fpedats,
		  a.fpi,
		  a.estimator,
		  a.analys,
		  a.measure,
		  a.value,
		  a.usfirm
from ibes.det_epsus as a
where 1980<=year(fpedats)<=2006; quit;
* and ticker ne "." and cusip ne "." and oftic ne "."
* and cusip ne "." and fpi=1 and measure="EPS" and usfirm=1;

*Screens;
data ibes;
 set ibes;
 if fpi=1;*One year ahead;
 if usfirm=1;
 if measure="EPS";
 year=year(fpedats);
 *if cusip=. then delete;
run;

*Create coverage measure;
proc sort data=ibes out=ibes2; by ticker year analys descending anndats; run;

*My ghetto way of saving the oldest forecast;
*The dataset is now at the firm-year-analyst level;
*Note that there may be multiple analysts per firm (year);
proc sort data=ibes2 out=ibes3 nodupkey; by ticker year analys; run;

*Count number of analysts;
proc summary data=ibes3;
 by ticker year;
 var analys;
 output out=ibescount (drop=_type_) mean=;
run;

*Merge count;
proc sql;
 create table ibes4
 as select a.*, b._freq_ as coverage
 from ibes3 a left join ibescount b
 on (a.ticker=b.ticker) and (a.year = b.year);
quit;*9,179 firms;

*IBES/CRSP link table code;
*The link table code is from Rabih Moussawi of WRDS;
proc sort data=ibes.idsum out=ibes1 (keep=ticker cusip cname sdates);
 where usfirm=1 and not(missing(cusip));
 by ticker cusip sdates;
run;

proc sql;
create table ibes2
as select *, min(sdates) as fdate, max(sdates) as ldate
from ibes1
group by ticker, cusip
order by ticker, cusip, sdates;
quit;

data ibes2;
set ibes2;
by ticker cusip;
if last.cusip;
label fdate="First Start date of CUSIP record";
label ldate="Last Start date of CUSIP record";
format fdate ldate date9.;
drop sdates;
run;

proc sort data=crsp.stocknames out=crsp1 (keep=PERMNO NCUSIP comnam namedt nameenddt);
where not missing(NCUSIP);
by PERMNO NCUSIP namedt;
run;

proc sql;
create table crsp2
as select PERMNO,NCUSIP,comnam,
min(namedt)as namedt,max(nameenddt) as nameenddt
from crsp1
group by PERMNO, NCUSIP
order by PERMNO, NCUSIP, NAMEDT;
quit;

data crsp2;
set crsp2;
by permno ncusip;
if last.ncusip;
label namedt="Start date of CUSIP record";
label nameenddt="End date of CUSIP record";
format namedt nameenddt date9.;
run;

* Create Link Table;
proc sql;
create table link1
as select *
from ibes2 as a, crsp2 as b
where a.CUSIP = b.NCUSIP
order by TICKER, PERMNO, ldate;
quit;

* Scoring Links;
data link2;
set link1;
by TICKER PERMNO;
if last.PERMNO; * Keep link with most recent company name;
name_dist = min(spedis(cname,comnam),spedis(comnam,cname));
if (not ((ldatenameenddt))) and name_dist < 30 then SCORE = 0;
else if (not ((ldatenameenddt))) then score = 1;
else if name_dist < 30 then SCORE = 2; else SCORE = 3;
keep TICKER PERMNO cname comnam score;
run;

*Perfect scores only;
data link3;
 set link2;
 if score=0;
run;

*Sort before merge;
proc sort data=ibes4; by ticker; run;
proc sort data=link3; by ticker; run;

*Merge IBES/CRSP link table;
proc sql;
 create table ibescrsp
 as select a.*, b.permno
 from ibes4 a left join link3 b
 on (a.ticker=b.ticker);
quit;*n=1,488,519;

*Then screen;
data ibescrsp2;
 set ibescrsp;
 if permno=. then delete;
run;

/*CCM link;
data linktable;
 set crsp.ccmxpf_linktable;
run;

data linktable2;
 set linktable;
 if lpermno=. then delete;*Delete if missing PERMNO;
 yearbeg=year(linkdt);
 yearend=year(linkenddt);
run;*/

*Merge GVKEY back;
proc sql;
 create table ibescompstat
 as select a.*, b.gvkey
 from ibescrsp2 a left join crsp.ccmxpf_linktable b
 on (a.permno=b.lpermno) and (a.fpedats >= b.linkdt) and (a.fpedats <= b.linkenddt);
quit;*n=1,488,519;

data ibescompstat2;
 set ibescompstat;
 if gvkey=. then delete;
run;

*Set data previously uploaded;
data hkqje;
 set remote.hkqje;
 if stopped ne 1;*This is the difference between -1 and -2 reduction in coverage;
run;

*Merge "merger" identifier to ibescompstat2;
proc sql;
 create table ibescompstat3
 as select a.*, b.merger
 from ibescompstat2 a left join hkqje b
 on (a.permno=b.permno);
quit;*n=1,488,519;

*One thing you must note is that firms can be treated multiple times;
proc sort data=ibescompstat3 out=ibescompstat4 nodupkey; by gvkey year merger; run;

data firstmergeryears;*1984;
 set ibescompstat4;
 if year<1983 then delete;
 else if year=1984 then delete;
 else if year>1985 then delete;
 if year=1985 then post=1;
 else if year=1983 then post=0;
 if merger=1 then treat=1;
 else treat=0;
run;

data secondmergeryears;*1988;
 set ibescompstat4;
 if year<1987 then delete;
 else if year=1988 then delete;
 else if year>1989 then delete;
 if year=1989 then post=1;
 else if year=1987 then post=0;
 if merger=8 then treat=1;
 else treat=0;
run;

data thirdmergeryears;*1994;
 set ibescompstat4;
 if year<1993 then delete;
 else if year=1994 then delete;
 else if year>1995 then delete;
 if year=1995 then post=1;
 else if year=1993 then post=0;
 if merger=2 then treat=1;
 else treat=0;
run;

data fourthmergeryears;*And fifth;*1997;
 set ibescompstat4;
 if year<1996 then delete;
 else if year=1997 then delete;
 else if year>1998 then delete;
 if year=1998 then post=1;
 else if year=1996 then post=0;
 if merger=3 then treat=1;
 else if merger=4 then treat=1;
 else treat=0;
run;

data sixthmergeryears;*And seventh and eighth;*1998;
 set ibescompstat4;
 if year<1997 then delete;
 else if year=1998 then delete;
 else if year>1999 then delete;
 if year=1999 then post=1;
 else if year=1997 then post=0;
 if merger=8 then treat=1;
 else if merger=9 then treat=1;
 else if merger=10 then treat=1;
 else treat=0;
run;

data ninthmergeryears;*And seventh and eighth;*1999;
 set ibescompstat4;
 if year<1998 then delete;
 else if year=1999 then delete;
 else if year>2000 then delete;
 if year=2000 then post=1;
 else if year=1998 then post=0;
 if merger=12 then treat=1;
 else treat=0;
run;

data tenthmergeryears;*And eleventh, twelfth, and thirteenth;*2000;
 set ibescompstat4;
 if year<1999 then delete;
 else if year=2000 then delete;
 else if year>2001 then delete;
 if year=2001 then post=1;
 else if year=1999 then post=0;
 if merger=5 then treat=1;
 else if merger=6 then treat=1;
 else if merger=7 then treat=1;
 else if merger=13 then treat=1;
 else treat=0;
run;

data fourteenthmergeryears;*2001;
 set ibescompstat4;
 if year<2000 then delete;
 else if year=2001 then delete;
 else if year>2002 then delete;
 if year=2002 then post=1;
 else if year=2000 then post=0;
 if merger=14 then treat=1;
 else treat=0;
run;

data fifteenthmergeryears;*2005;
 set ibescompstat4;
 if year<2004 then delete;
 else if year=2005 then delete;
 else if year>2006 then delete;
 if year=2006 then post=1;
 else if year=2004 then post=0;
 if merger=15 then treat=1;
 else treat=0;
run;

data allobs;
 set firstmergeryears secondmergeryears thirdmergeryears fourthmergeryears sixthmergeryears ninthmergeryears tenthmergeryears fourteenthmergeryears fifteenthmergeryears;
run;

*out=allobs2 nodupkey;
proc sort data=allobs; by gvkey year post descending treat; run;
proc sort data=allobs out=allobs2 nodupkey; by gvkey year post; run;

*This is the dataset containing the indicator variables for the natural experiment and coverage;
data allobs3;
 set allobs2;
 posttreat=post*treat;
 if 1993 le year(datadate) le 2006;
run;

*Now get the COMPUSTAT data;
proc sql;
create table compstat2
as select a.gvkey,
		a.conm,
		a.datadate,
		a.fyear,
		a.at,
		a.ib,
		a.oancf,
		a.prcc_f,
		a.csho,
		a.ceq,
		a.dltt,
		a.dlc,
		a.dp,
		a.sale,
		a.xrd,
		a.xad,
		a.dvc
from compm.funda as a
where 1961<=year(datadate)<=2006 and consol="C" and indfmt="INDL" and datafmt="STD" and popsrc="D" and curcd="USD" and gvkey ne "."; quit;
*1975<=fyearq<=2011;
*Download table;

*Merge SIC codes;
proc sql;
create table compstatnames
as select *
from compstat2 as a, comp.names as b
where a.gvkey = b.gvkey
and a.fyear between b.year1 and b.year2
order by a.gvkey, a.fyear;

*Merge PERMNO;
proc sql;
 create table compustatcrsp
 as select a.*, b.lpermno as permno
 from compstatnames a left join crsp.ccmxpf_linktable b
 on (a.gvkey=b.gvkey) and (a.datadate >= b.linkdt) and (a.datadate <= b.linkenddt);
quit;*n=1,488,519;

data compustatcrsp2;
 set compustatcrsp;
 if permno=. then delete;
run;

proc sort data=compustatcrsp2 out=ccm2 nodupkey; by permno datadate; run;

data upload;
 set ccm2;
 keep permno datadate;
run;

proc sql;
create table twelveret
as select upload.*,
		  exp(sum(log(1+ret)))-1 as twelvebhr,
		  n(ret) as Nretfirm
from upload(keep=permno datadate) as a, crspa.ermport1 as b
where a.permno=b.permno
and intck('month',a.datadate,b.date)between -8 and 3
group by a.permno,a.datadate
order by a.permno,a.datadate; quit;

proc sort data=twelveret nodupkey; by permno datadate; run; quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table compustatret
 as select a.*, b.twelvebhr
 from ccm2 a left join twelveret b
 on (a.permno=b.permno) and (a.datadate=b.datadate);
quit;

*Variable construction;
*Create lag;
data lag;
 set compustatret;
 lagat=at;
 lagprc=prcc_f;
 lagcsho=csho;
run;

*Merge lag;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table lagone
 as select a.*, b.lagat, b.lagprc, b.lagcsho
 from compustatret a left join lag b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear+1);
quit;

proc sort data=lagone; by gvkey fyear; run;

data variable;
 set lagone;
 mve=prcc_f*csho;
 lagmve=lagprc*lagcsho;
 earnings=ib/lagmve;
 assets=log(at);
 size=log(mve);
 mtb=mve/ceq;
 lev=(dltt+dlc)/mve;
 avat=(at+lagat)/2;
 conacc=(ib+dp-oancf)/avat;
 if twelvebhr<0 then d=1;
 else d=0;
 year=year(datadate);
run;

*Screen for C-Score;
data screen;
 set variable;*n=172,331;
 if prcc_f<1 then delete;
 if at<0 then delete;
 if ceq<0 then delete;
 if earnings=. then delete;
 if twelvebhr=. then delete;
 if size=. then delete;
 if mtb=. then delete;
 if lev=. then delete;
run;

*Truncate;
%Winsorize_Truncate(dsetin = screen, dsetout = truncate, byvar = fyear, vars = earnings twelvebhr size mtb lev dp, type = T, pctl = 1 99);

proc sort data=truncate; by gvkey fyear; run;

data descriptive;
 set truncate;
 if 1963 le year(datadate) le 2005;
run;

data regression;
 set descriptive;
 rsize=twelvebhr*size;
 rmtb=twelvebhr*mtb;
 rlev=twelvebhr*lev;
 dr=d*twelvebhr;
 drsize=d*twelvebhr*size;
 drmtb=d*twelvebhr*mtb;
 drlev=d*twelvebhr*lev;
 dsize=d*size;
 dmtb=d*mtb;
 dlev=d*lev;
run;

proc sort data=regression; by fyear; run;
proc reg data=regression outest=coefficients noprint;
 by fyear;
 model earnings=d twelvebhr rsize rmtb rlev dr drsize drmtb drlev size mtb lev dsize dmtb dlev;
 *output out=regression2 outest;
run;
quit;

*Merge coefficients;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table regest
 as select a.*, b.twelvebhr as muone, b.rsize as mutwo, b.rmtb as muthree, b.rlev as mufour, b.dr as lambdaone, b.drsize as lambdatwo, b.drmtb as lambdathree, b.drlev as lambdafour
 from regression a left join coefficients b
 on (a.fyear=b.fyear);
quit;

data conservatismo;
 set regest;
 gscore=muone+mutwo*size+muthree*mtb+mufour*lev;
 cscore=lambdaone+lambdatwo*size+lambdathree*mtb+lambdafour*lev;
 year=year(datadate);*Calendar year;
 sicthree=int(sic/10);
run;

*Merge "merger" identifier to ibescompstat2;
proc sql;
 create table truncatemerger
 as select a.*, b.merger
 from conservatismo a left join hkqje b
 on (a.permno=b.permno);
quit;*n=1,488,519;

*One thing you must note is that firms can be treated multiple times;
proc sort data=truncatemerger out=truncatemerger2 nodupkey; by gvkey year merger; run;

data firstmergeryears;*1984;
 set truncatemerger2;
 if year<1983 then delete;
 else if year=1984 then delete;
 else if year>1985 then delete;
 if year=1985 then post=1;
 else if year=1983 then post=0;
 if merger=1 then treat=1;
 else treat=0;
run;

data secondmergeryears;*1988;
 set truncatemerger2;
 if year<1987 then delete;
 else if year=1988 then delete;
 else if year>1989 then delete;
 if year=1989 then post=1;
 else if year=1987 then post=0;
 if merger=8 then treat=1;
 else treat=0;
run;

data thirdmergeryears;*1994;
 set truncatemerger2;
 if year<1993 then delete;
 else if year=1994 then delete;
 else if year>1995 then delete;
 if year=1995 then post=1;
 else if year=1993 then post=0;
 if merger=2 then treat=1;
 else treat=0;
run;

data fourthmergeryears;*And fifth;*1997;
 set truncatemerger2;
 if year<1996 then delete;
 else if year=1997 then delete;
 else if year>1998 then delete;
 if year=1998 then post=1;
 else if year=1996 then post=0;
 if merger=3 then treat=1;
 else if merger=4 then treat=1;
 else treat=0;
run;

data sixthmergeryears;*And seventh and eighth;*1998;
 set truncatemerger2;
 if year<1997 then delete;
 else if year=1998 then delete;
 else if year>1999 then delete;
 if year=1999 then post=1;
 else if year=1997 then post=0;
 if merger=8 then treat=1;
 else if merger=9 then treat=1;
 else if merger=10 then treat=1;
 else treat=0;
run;

data ninthmergeryears;*And seventh and eighth;*1999;
 set truncatemerger2;
 if year<1998 then delete;
 else if year=1999 then delete;
 else if year>2000 then delete;
 if year=2000 then post=1;
 else if year=1998 then post=0;
 if merger=12 then treat=1;
 else treat=0;
run;

data tenthmergeryears;*And eleventh, twelfth, and thirteenth;*2000;
 set truncatemerger2;
 if year<1999 then delete;
 else if year=2000 then delete;
 else if year>2001 then delete;
 if year=2001 then post=1;
 else if year=1999 then post=0;
 if merger=5 then treat=1;
 else if merger=6 then treat=1;
 else if merger=7 then treat=1;
 else if merger=13 then treat=1;
 else treat=0;
run;

data fourteenthmergeryears;*2001;
 set truncatemerger2;
 if year<2000 then delete;
 else if year=2001 then delete;
 else if year>2002 then delete;
 if year=2002 then post=1;
 else if year=2000 then post=0;
 if merger=14 then treat=1;
 else treat=0;
run;

data fifteenthmergeryears;*2005;
 set truncatemerger2;
 if year<2004 then delete;
 else if year=2005 then delete;
 else if year>2006 then delete;
 if year=2006 then post=1;
 else if year=2004 then post=0;
 if merger=15 then treat=1;
 else treat=0;
run;

data allobscomp;
 set firstmergeryears secondmergeryears thirdmergeryears fourthmergeryears sixthmergeryears ninthmergeryears tenthmergeryears fourteenthmergeryears fifteenthmergeryears;
run;

*out=allobs2 nodupkey;
proc sort data=allobscomp; by gvkey year post descending treat; run;
proc sort data=allobscomp out=allobscomp2 nodupkey; by gvkey year post; run;

*This is the dataset containing the indicator variables for the natural experiment and coverage;
data cscore;
 set allobscomp2;
 posttreat=post*treat;
 if 1983 le year(datadate) le 2006;
run;

*Unconditional conservatism;
data screen2;
 set variable;
 if avat=. then delete;
 if conacc=. then delete;
 if size=. then delete;
 if mtb=. then delete;
 if lev=. then delete;
 year=year(datadate);
run;

*Noncentered;
proc expand data=screen out = ma;
 by gvkey;
 convert conacc = conacc_ma / transformout=(movave 3);
run;

proc sort data=ma nodupkey; by gvkey fyear; run;

*Winsorize;
%Winsorize_Truncate(dsetin = ma, dsetout = winsor, byvar = none, vars = size mtb lev, type = W, pctl = 1 99);

proc sort data=winsor; by gvkey fyear; run;

*Merge "merger" identifier to ibescompstat2;
proc sql;
 create table winsormerger
 as select a.*, b.merger
 from winsor a left join hkqje b
 on (a.permno=b.permno);
quit;*n=1,488,519;

*One thing you must note is that firms can be treated multiple times;
proc sort data=winsormerger out=winsormerger2 nodupkey; by gvkey year merger; run;

data firstmergeryears;*1984;
 set winsormerger2;
 if year<1983 then delete;
 else if year=1984 then delete;
 else if year>1985 then delete;
 if year=1985 then post=1;
 else if year=1983 then post=0;
 if merger=1 then treat=1;
 else treat=0;
run;

data secondmergeryears;*1988;
 set winsormerger2;
 if year<1987 then delete;
 else if year=1988 then delete;
 else if year>1989 then delete;
 if year=1989 then post=1;
 else if year=1987 then post=0;
 if merger=8 then treat=1;
 else treat=0;
run;

data thirdmergeryears;*1994;
 set winsormerger2;
 if year<1993 then delete;
 else if year=1994 then delete;
 else if year>1995 then delete;
 if year=1995 then post=1;
 else if year=1993 then post=0;
 if merger=2 then treat=1;
 else treat=0;
run;

data fourthmergeryears;*And fifth;*1997;
 set winsormerger2;
 if year<1996 then delete;
 else if year=1997 then delete;
 else if year>1998 then delete;
 if year=1998 then post=1;
 else if year=1996 then post=0;
 if merger=3 then treat=1;
 else if merger=4 then treat=1;
 else treat=0;
run;

data sixthmergeryears;*And seventh and eighth;*1998;
 set winsormerger2;
 if year<1997 then delete;
 else if year=1998 then delete;
 else if year>1999 then delete;
 if year=1999 then post=1;
 else if year=1997 then post=0;
 if merger=8 then treat=1;
 else if merger=9 then treat=1;
 else if merger=10 then treat=1;
 else treat=0;
run;

data ninthmergeryears;*And seventh and eighth;*1999;
 set winsormerger2;
 if year<1998 then delete;
 else if year=1999 then delete;
 else if year>2000 then delete;
 if year=2000 then post=1;
 else if year=1998 then post=0;
 if merger=12 then treat=1;
 else treat=0;
run;

data tenthmergeryears;*And eleventh, twelfth, and thirteenth;*2000;
 set winsormerger2;
 if year<1999 then delete;
 else if year=2000 then delete;
 else if year>2001 then delete;
 if year=2001 then post=1;
 else if year=1999 then post=0;
 if merger=5 then treat=1;
 else if merger=6 then treat=1;
 else if merger=7 then treat=1;
 else if merger=13 then treat=1;
 else treat=0;
run;

data fourteenthmergeryears;*2001;
 set winsormerger2;
 if year<2000 then delete;
 else if year=2001 then delete;
 else if year>2002 then delete;
 if year=2002 then post=1;
 else if year=2000 then post=0;
 if merger=14 then treat=1;
 else treat=0;
run;

data fifteenthmergeryears;*2005;
 set winsormerger2;
 if year<2004 then delete;
 else if year=2005 then delete;
 else if year>2006 then delete;
 if year=2006 then post=1;
 else if year=2004 then post=0;
 if merger=15 then treat=1;
 else treat=0;
run;

data allobscomp;
 set firstmergeryears secondmergeryears thirdmergeryears fourthmergeryears sixthmergeryears ninthmergeryears tenthmergeryears fourteenthmergeryears fifteenthmergeryears;
run;

*out=allobs2 nodupkey;
proc sort data=allobscomp; by gvkey year post descending treat; run;
proc sort data=allobscomp out=allobscomp2 nodupkey; by gvkey year post; run;

*This is the dataset containing the indicator variables for the natural experiment and coverage;
data conacc;
 set allobscomp2;
 posttreat=post*treat;
 if 1993 le year(datadate) le 2006;
 con=conacc_ma*(-1);
run;

proc download data=cscore; run;
proc download data=conacc; run;

endrsubmit;

data temp.cscore;
 set cscore;
run;

data temp.conacc;
 set conacc;
run;

/*data test;
 set temp.cscore;
 if 1993 le year le 2006;
run;

data test2;
 set temp.conacc;
 if 1993 le year le 2006;
run;*/

*Export;
proc export data=temp.cscore outfile= "D:\ay32\My Documents\Fall 2013\cscore.dta" replace;
run;

proc export data=temp.conacc outfile= "D:\ay32\My Documents\Fall 2013\conacc.dta" replace;
run;
