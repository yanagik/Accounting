*Set local folder;
libname temp 'D:\ay32\My Documents\Spring 2013';

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
*Log in to WRDS;
%let wrds = wrds.wharton.upenn.edu 4016; 		
options comamid=TCP remote=WRDS;				
signon username=_prompt_ ;
rsubmit;

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

libname deals '/wrds/tfn/sasdata/dealscan';
libname remote '/home/duke/ay32';

* Merging Company File with Package file;
proc sql;
create table Packageplus as
select *
from deals.company as a, deals.package as b
where a.Companyid = b.BorrowerCompanyID ;
quit;

* Adding Facility file;
proc sql;
create table facilityplus as
select *
from packageplus as a, deals.facility as b
where a.packageid = b.packageid ;
quit;

* Adding Pricing information ("All in spread" variables); 
proc sql;
create table pricingplus as
select *
from facilityplus as a, deals.currfacpricing as b
where a.facilityid = b.facilityid ;
quit;

data link;
 set remote.dealscanlink;
run;

*Merge link;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table baselink
 as select a.*, b.gvkey
 from pricingplus a left join link b
 on (a.facilityid=b.facid);
quit;

data screen;
 set baselink;*n=483,370;
 if gvkey=. then delete;*n=285,077;
 if allindrawn=. then delete;*n=253,898;
 if maturity=. then delete;*n=248,212;
 if facilityamt=. then delete;*n=248,137;
 keep companyid company primarysiccode facilityid facilitystartdate facilityamt maturity allindrawn gvkey;
run;

proc sort data=screen out=screen2 nodupkey; by facilityid facilitystartdate; run;

data dealscan;
 set screen2;
 year=year(facilitystartdate);
 month=month(facilitystartdate);
 if year>2007 then delete;
 if 1 le month le 3 then cqtr=1;
 else if 4 le month le 6 then cqtr=2;
 else if 7 le month le 9 then cqtr=3;
 else if 10 le month le 12 then cqtr=4;
run;*The problem is not here;

/*proc download data=dealscan; run;
endrsubmit;

*Save;
data temp.redodealscan;
 set dealscan;
run;*/

*Here ends the Dealscan part;
*Beginning COMPUSTAT part;
*Create table remotely;
*Quarterly COMPUSTAT data;
*Note that curcdQ is used for the quarterly database;
proc sql;
create table compstat
as select a.gvkey,
		a.datadate,
		a.fyearq,
		a.fqtr,
		a.datacqtr,
		a.atq,
		a.dlcq,
		a.dlttq,
		a.pstkq,
		a.txditcq,
		a.prccq,
		a.cshoq,
		a.ppentq,
		a.oibdpq,
		a.ibq
from comp.fundq as a
where 1988<=year(datadate)<=2008 and consol="C" and indfmt="INDL" and datafmt="STD" and popsrc="D" and curcdq="USD" and gvkey ne "."; quit;
*1975<=fyearq<=2011;
*Download table;

proc sql;
create table compstatnames
as select *
from compstat as a, comp.names as b
where a.gvkey = b.gvkey
and a.fyearq between b.year1 and b.year2
order by a.gvkey, a.fyearq;

*THIS SOLVES THE PROBLEM?!;
data linktable2;
 set crsp.ccmxpf_linktable;
 if lpermno=. then delete;*Delete if missing PERMNO;
run;

*Merge LPERMNO from linktable to COMPUSTAT data;
proc sql;
 create table ccm
 as select a.*, b.lpermno
 from compstatnames a left join linktable2 b
 on (a.gvkey=b.gvkey);
quit;*n=1,488,519;

*Delete duplicates;
proc sort data=ccm nodupkey; by gvkey fyearq fqtr; run;*n=1,200,335;
*The problem is not here either;
*real n=804,253 (cf. 804,199);

*Three-month buy-and-hold returns starting from the fourth month after a firm's fiscal quarter end *****;
proc sort data=ccm out=ccm3 nodupkey; by lpermno datadate; run; quit;

*THE PROBLEM IS HERE;
*Twelve-month buy-and-hold returns for the past year;
proc sql;
create table twelveret
as select ccm3.*,
		  exp(sum(log(1+ret)))-1 as twelvebhr,
		  std(ret) as stdret,
		  n(ret) as Nretfirm
from ccm3(keep=lpermno datadate) as a, crspa.msf as b
where a.lpermno=b.permno
and intck('month',a.datadate,b.date)between -11 and 0
group by a.lpermno,a.datadate
order by a.lpermno,a.datadate; quit;


proc sort data=twelveret nodupkey; by lpermno datadate; run; quit;
*n=66,923. The problem is above;

proc sort data=ccm; by lpermno datadate; run;
proc sort data=twelveret; by lpermno datadate; run;

*Merge CRSP data;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table compustatcrsp
 as select a.*, b.twelvebhr, b.stdret, b.nretfirm
 from ccm a left join twelveret b
 on (a.lpermno=b.lpermno) and (a.datadate=b.datadate);
quit;

*The problem is before here;
data compustatcrsp2;
 set compustatcrsp;
 if Nretfirm<12 then delete;
 if twelvebhr=. then delete;
 asd=stdret*sqrt(Nretfirm);
 e=prccq*cshoq;
 f=dlcq+0.5*dlttq;
 sigmad=0.05+0.25*asd;
 sigmav=(e/(e+f))*asd+(f/(e+f))*sigmad;
 dd=(log((e+f)/f)+twelvebhr-0.5*sigmav**2)/sigmav;
 naivedd=cdf('NORMAL',-dd);
 if naivedd=. then delete;
run;

*Set Compstat data;
data valtacompstat;
 set compustatcrsp2;
 gvkeynum=gvkey*1;
 sicthree=int(sic/10);
 cqtrchar=substr(datacqtr,6,6);
 cqtr=cqtrchar*1;
 year=year(datadate);
run;

*Create variables for Table 3;
*Create all the COMPUSTAT variables first;
*The main problem is the cash flow volatility measure;
*You need all the observations, even though not all will be matched / merged to Dealscan;

proc sort data=valtacompstat; by gvkey datadate; run;

data variables;
 set valtacompstat;
 logat=log(atq);
 leverage=(dlcq+dlttq)/atq;
 mtb=(dlcq+dlttq+pstkq-txditcq+prccq*cshoq)/atq;*This is really more of a Tobin's Q;
 profitability=oibdpq/atq;
 tangibility=ppentq/atq;
 *loglm=log(maturity);
 *Create lag IBQ;
 laggvkey=lag(gvkey);
 lagibq=lag(ibq);
 if gvkey=laggvkey then lagibq=lagibq;
 else if gvkey ne laggvkey then lagibq=.;
 earningschange=ibq-lagibq;
run;

*http://www2.sas.com/proceedings/forum2008/093-2008.pdf;
proc expand data=variables out=ibqstd;
 convert earningschange = earningschangestd / method = none transformout = (movstd 8);
 by gvkey;
run;

proc expand data=ibqstd out=atqmu;
 convert atq = atqmean / method = none transformout = (movave 8);
 by gvkey;
run;

data variables2;
 set atqmu;
 cfv=earningschangestd/atqmean;
run;

*Here ends Compustat part;
*Merge Dealscan and Compustat;
*Sort before merge;
proc sort data=variables2;
 by gvkeynum year cqtr;
run;

proc sort data=dealscan;
 by gvkey year cqtr;
run;

*Merge allinspread to compstat;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table compstatdealscan
 as select a.*, b.allindrawn, b.facilityamt, b.maturity
 from variables2 a left join dealscan b
 on (a.gvkeynum=b.gvkey) and (a.year=b.year) and (a.cqtr=b.cqtr);
quit;

data test;
 set compstatdealscan;
 if allindrawn=. then delete;
 if facilityamt=. then delete;
 if maturity=. then delete;
run;

*Set HP data;
data hpfittedhhi;
 set remote.hpfittedhhi;
run;

*Sort before merging with HHI;
proc sort data=compstatdealscan;
 by year sicthree;
run;

*Merge HHI;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table csdshhi
 as select a.*, b.fithhi
 from compstatdealscan a left join hpfittedhhi b
 on (a.year=b.year) and (a.sicthree=b.sic3);
quit;

data table1;
 set csdshhi;
 if atq=. then delete;
 if leverage=. then delete;
 if profitability=. then delete;
 if mtb=. then delete;
 if tangibility=. then delete;
 if cfv=. then delete;
 if allindrawn=. then delete;
 if facilityamt=. then delete;
 if maturity=. then delete;
 if fithhi=. then delete;
 loglm=log(maturity);
 if 1992 le year le 2007;
 facilityamtscaled=facilityamt/1000000;
 atqscaled=atq/1000;
run;*n=13,037;

proc sort data=table1; by year fithhi; run;

proc rank data=table1 out=quartiles ties=low groups=4;
 by year;*Oops. I forgot to do this the first time;
 var fithhi;
 ranks fithhirank;
run;

proc sort data=quartiles; by gvkey year; run;

data table2;
 set quartiles;
 if fithhirank=0 then competition=1;
 else competition=0;
 depvar=log(allindrawn);
run;

%Winsorize_Truncate(dsetin = table2, dsetout = table2win, byvar = none, vars = leverage profitability mtb tangibility cfv, type = W, pctl = 1 99)

proc sort data=table2win; by gvkey fyearq fqtr; run;

*Meh. Close enough for my taste;
proc means data=table2win;
 var allindrawn maturity facilityamtscaled atqscaled leverage profitability mtb tangibility cfv naivedd competition;
run;

/*data schott;
 set temp.schott;
 if 1992 le year le 2005;
 sicthree=int(sic/10);
run;

*Sort before sum;
proc sort data=schott; by sicthree year; run;

*Sum duties (numerator);
proc summary data=schott;
 by sicthree year;
 var duties;
 output out=schottduty (drop=_type_ _freq_) sum=;
run;

*Sum customs value (denominator);
proc summary data=schott;
 by sicthree year;
 var dutyval;
 output out=schottcustom (drop=_type_ _freq_) sum=;
run;

*Merge sums together;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table schottnd
 as select a.sicthree, a.year, a.duties, b.dutyval
 from schottduty a left join schottcustom b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

*Compute ad valorem tariff;
data schotttariff;
 set schottnd;
 avt=duties/dutyval;
 if avt=. then delete;
 lagsicthree=lag(sicthree);
 lagavt=lag(avt);
 if sicthree=lagsicthree then lagavt=lagavt;
 else if sicthree ne lagsicthree then lagavt=.;
 deltaavt=avt-lagavt;
run;

proc summary data=schotttariff;
 by sicthree;
 var deltaavt;
 output out=schottdamed (drop=_type_ _freq_) median=;
run;

*Merge median back;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table schotttariffmed
 as select a.*, b.deltaavt as median
 from schotttariff a left join schottdamed b
 on (a.sicthree=b.sicthree);
quit;

proc sort data=schotttariffmed; by sicthree year; run;

data triple;
 set schotttariffmed;
 if abs(deltaavt)>3*abs(median) then candidate=1;
 else candidate=0;
 if candidate=1 & deltaavt>0 then increase=1;
 else increase=0;
run;

data tripneg;
 set triple;
 if candidate=1;
 if deltaavt<0;
run;

proc summary data=tripneg;
 by sicthree;
 var deltaavt;
 output out=tripnegmin (drop=_type_ _freq_) min=;
run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table triplemin
 as select a.*, b.deltaavt as min
 from triple a left join tripnegmin b
 on (a.sicthree=b.sicthree);
quit;

data indicator;
 set triplemin;
 if min=. then delete;
 if deltaavt=min then marker=1;
 else marker=0;
 *lagsicthree=lag(sicthree);
 lagincrease=lag(increase);
 if sicthree=lagsicthree then lagincrease=lagincrease;
 else if sicthree ne lagsicthree then lagincrease=.;
run;

*Create lead;
proc sort data=indicator; by sicthree descending year; run;

data indicator2;
 set indicator;
 leadsicthree=lag(sicthree);
 leadincrease=lag(increase);
 if sicthree=leadsicthree then leadincrease=leadincrease;
 else if sicthree ne leadsicthree then leadincrease=.;
run;

proc sort data=indicator2; by sicthree year; run;

data indicator3;
 set indicator2;
 if marker=1 & lagincrease=1 & leadincrease=1 then transitory=1;
 else transitory=0;
 if marker=1 & transitory=0 then cut=1;
run;*n=97;

*Create postreduction indicator;
data indicator4;
 set indicator3;
 by sicthree;
 retain postreduction;
 if first.sicthree then postreduction=0;
 if cut=1 then postreduction=1;
run;

data temp.valtapostred;
 set indicator4;
run;*/

data trade;
 set remote.valtapostred;
run;

*Merge trade with Dealscan / Compustat;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table table6
 as select a.*, b.postreduction
 from table2win a left join trade b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

data table62;
 set table6;
 if postreduction=. then delete;
run;

*Export here;
proc sort data=table62; by sicthree fyearq fqtr; run;

proc download data=table62; run;
endrsubmit;

*Save data;
*I can't believe this shit. One block of code cost me so much time;
data temp.redo62;
 set table62;
run;

*Export to STATA;
proc export data=temp.redo62 outfile= "D:\ay32\My Documents\Spring 2013\redovalta.dta" replace;
run;

