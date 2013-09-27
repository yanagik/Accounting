*Temporary library name;
*Change as needed;
libname temp 'D:\ay32\My Documents\Fall 2013';
*libname temp 'C:\Users\Temp\Documents\Fall 2013';

*Notes for winsorization macro;
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

*I will use data previously uploaded;
libname remote '/home/duke/ay32';

*Winsorization macro;
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

*Create table remotely;
*Quarterly COMPUSTAT data;
*Note that curcdQ is used for the quarterly database;
*http://www.wrds.us/index.php/forum_wrds/viewthread/174/; *Firm age;
proc sql;
create table compstat2
as select a.gvkey,
		a.conm,
		a.datadate,
		a.fyear,
		a.xrd,
		a.at,
		a.lt,
		a.prcc_f,
		a.csho,
		a.pstk,
		a.dltt,
		a.dlc,
		a.ib,
		a.dp,
		a.cogs,
		a.invch,
		a.invt,
		a.sale,
		a.xsga,
		a.oancf,
		a.ni,
		a.ceq,
		a.oibdp,
		a.re,
		a.wcap
from compm.funda as a
where 1986<=year(datadate)<=2005 and consol="C" and indfmt="INDL" and datafmt="STD" and popsrc="D" and curcd="USD" and gvkey ne "."; quit;
*1975<=fyearq<=2011;
*Download table;

*Merge SIC;
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

*Here we begin the RM part;
*Create lag;
data lag;
 set compustatcrsp;
 lagat=at;
 lagxrd=xrd;
 lagsale=sale;
 lagni=ni;
run;

*Merge lag;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table lagone
 as select a.*, b.lagat, b.lagsale, b.lagxrd, b.lagni
 from compustatcrsp a left join lag b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear+1);
quit;

*Merge lag;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table lagtwo
 as select a.*, b.lagsale as laglagsale
 from lagone a left join lag b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear+2);
quit;

*Thing is, Gunny (2010) uses different samples for each LHS variable;
*This is the screen for the set of common variables across subsamples;
data screen;
 set lagtwo;*n=172,331;
 if 4400 le sic < 5000 then delete;*n=156,700;
 if 6000 le sic < 7000 then delete;*n=119,142;
 sictwo=int(sic/100);
 sicthree=int(sic/10);
 year=year(datadate);*Calendar year;
 if lagat ne .;*n=85,605;
 if prcc_f ne .;*n=76,952;
 if csho ne .;*n=76,693;
 if pstk ne .;*n=76,632;
 if dltt ne .;*n=76,497;
 if dlc ne .;*n=76,407;
 if at ne .;*n=76,407;
 /*if ib ne .;*n=76,405;*Difference here;
 if xrd ne .;*n=46,407;
 if dp ne .;*n=46,288;*/
run;

*Abnormal R&D;
data ard;
 set screen;
 if xrd ne 0;*n=118,964;
 if xrd ne .;*n=97,951;
 if lagxrd ne .;
 if ib ne .;*n=76,405;
 if dp ne .;*n=46,288;
run;

*RHS variables used for abnormal R&D;
data ardvar;
 set ard;
 rdat=xrd/lagat;
 scaleint=1/lagat;
 mv=log(prcc_f*csho);
 q=(((prcc_f*csho) + pstk + dltt + dlc)/at);
 intat=(ib+dp+xrd)/lagat;
 lagrdat=lagxrd/lagat;
 niat=ni/at;
 chni=ni-lagni;
 chniat=chni/at;
 if 0 le niat le 0.01 then bench=1;
 else if 0 le chniat le 0.01 then bench=1;
 else bench=0;
 if 0 le niat le 0.01 then benchzero=1;
 else benchzero=0;
 if 0 le chniat le 0.01 then benchlast=1;
 else benchlast=0;
 size=log(at);
 mtb=mv/ceq;
 roa=ib/lagat;
 *zscore=3.3*((oibdp-dp)/at)+(sale/at)+1.4*(re/at)+1.2*(wcap/at);*Follows Sufi;
 zscore=0.3*(ni/at)+(sale/at)+1.4*(re/at)+1.2*(wcap/at)+0.6*(prcc_f*csho)/lt;*Follows Zang;
run;

*Sort zscore by median;
proc rank data=ardvar out=rdmed groups=2;
 var zscore;
 ranks zrank;
run;

*Abnormal production;
data aprod;
 set screen;
 if invt ne 0;
 if cogs ne 0;
 if cogs ne .;
 if sale ne .;*n=46,288;
 if lagsale ne .;*n=46,151;
 if laglagsale ne .;
run;

*RHS variables for abnormal production;
data aprodvar;
 set aprod;
 prod=cogs+invch;
 prodat=prod/lagat;
 scaleint=1/lagat;
 mv=log(prcc_f*csho);
 q=(((prcc_f*csho) + pstk + dltt + dlc)/at);
 intat=(ib+dp+xrd)/lagat;
 saleat=sale/lagat;
 deltasale=sale-lagsale;
 deltasaleat=deltasale/lagat;
 lagdeltasale=lagsale-laglagsale;
 lagdeltasaleat=lagdeltasale/lagat;
 niat=ni/at;
 chni=ni-lagni;
 chniat=chni/at;
 if 0 le niat le 0.01 then bench=1;
 else if 0 le chniat le 0.01 then bench=1;
 else bench=0;
 if 0 le niat le 0.01 then benchzero=1;
 else benchzero=0;
 if 0 le chniat le 0.01 then benchlast=1;
 else benchlast=0;
 size=log(at);
 mtb=mv/ceq;
 roa=ib/lagat;
 *zscore=3.3*((oibdp-dp)/at)+(sale/at)+1.4*(re/at)+1.2*(wcap/at);*Follows Sufi;
 zscore=0.3*(ni/at)+(sale/at)+1.4*(re/at)+1.2*(wcap/at)+0.6*(prcc_f*csho)/lt;*Follows Zang;
run;

*Sort zscore by median;
proc rank data=aprodvar out=prodmed groups=2;
 var zscore;
 ranks zrank;
run;

*AR&D # firms;
proc sort data=rdmed; by sicthree fyear; run;

*Count number of firms per industry-year;
proc summary data=rdmed;
 by sicthree fyear;
 var scaleint;
 output out=nofirmsrd (drop=_type_) mean=;
run;

*Merge it back;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table ardvarnofirms
 as select a.*, b._freq_ as n
 from rdmed a left join nofirmsrd b
 on (a.sicthree=b.sicthree) and (a.fyear=b.fyear);
quit;

*At least ten (footnote 19 [Frank et al. (2009)]);
data nscreenrd;
 set ardvarnofirms;
 if n<15 then delete;
 if 1988 le year le 2005;
run;*n=41,296;

*AProd # firms;
proc sort data=prodmed; by sicthree fyear; run;

*Count number of firms per industry-year;
proc summary data=prodmed;
 by sicthree fyear;
 var scaleint;
 output out=nofirmsprod (drop=_type_) mean=;
run;

*Merge it back;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table aprodvarnofirms
 as select a.*, b._freq_ as n
 from prodmed a left join nofirmsprod b
 on (a.sicthree=b.sicthree) and (a.fyear=b.fyear);
quit;

*At least ten (footnote 19 [Frank et al. (2009)]);
data nscreenprod;
 set aprodvarnofirms;
 if n<15 then delete;
 if 1988 le year le 2005;
run;*n=41,296;

*Sort before winsorize;
proc sort data=nscreenrd nodupkey; by gvkey fyear; run;*n=49,906;
proc sort data=nscreenprod nodupkey; by gvkey fyear; run;*n=49,906;

*Winsorize;
%Winsorize_Truncate(dsetin = nscreenrd, dsetout = winsorrd, byvar = none, vars = rdat scaleint mv q intat lagrdat, type = W, pctl = 1 99);
%Winsorize_Truncate(dsetin = nscreenprod, dsetout = winsorprod, byvar = none, vars = prodat scaleint mv q intat saleat deltasaleat lagdeltasaleat, type = W, pctl = 1 99);

*"Discretionary" R&D;
proc sort data=winsorrd; by sicthree fyear; run;
proc reg data=winsorrd noprint;
 by sicthree fyear;
 model rdat=scaleint mv q intat lagrdat;
 output out=normalrd residual=drd;
run;
quit;

%Winsorize_Truncate(dsetin = normalrd, dsetout = winsor2rd, byvar = none, vars = drd size mtb roa, type = W, pctl = 1 99);

*"Discretionary" Production;
proc sort data=winsorprod; by sicthree fyear; run;
proc reg data=winsorprod noprint;
 by sicthree fyear;
 model prodat=scaleint mv q intat saleat deltasaleat lagdeltasaleat;
 output out=normalprod residual=dprod;
run;
quit;

%Winsorize_Truncate(dsetin = normalprod, dsetout = winsor2prod, byvar = none, vars = dprod size mtb roa, type = W, pctl = 1 99);

proc sort data=winsor2rd; by gvkey fyear; run;
proc sort data=winsor2prod; by gvkey fyear; run;

*Sort;
proc sort data=winsor2rd; by gvkey fyear; run;
proc sort data=winsor2prod; by gvkey fyear; run;

*Set data previously uploaded;
data schott;
 set remote.schotttrade;
run;

*Merge trade with R&D;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table traderd
 as select a.*, b.postreduction
 from winsor2rd a left join schott b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

*Merge trade with production;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table tradeprod
 as select a.*, b.postreduction, b.cut
 from winsor2prod a left join schott b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

*Delete observation if it doesn't match to the trade data;
data traderd2;
 set traderd;
 if postreduction=. then delete;
 benchpostred=bench*postreduction;
 benchzeropostred=benchzero*postreduction;
 benchlastpostred=benchlast*postreduction;
run;

data tradeprod2;
 set tradeprod;
 if postreduction=. then delete;
 benchpostred=bench*postreduction;
 benchzeropostred=benchzero*postreduction;
 benchlastpostred=benchlast*postreduction;
run;

*Sort data;
proc sort data=traderd2; by gvkey fyear; run;
proc sort data=tradeprod2; by gvkey fyear; run;

proc sql;
create table compstat
as select a.gvkey,
		a.conm,
		a.datadate,
		a.fyear,
		a.ni,
		a.ib,
		a.oancf,
		a.sale,
		a.ppegt,
		a.rect,
		a.at,
		a.prcc_f,
		a.csho,
		a.ceq
from compm.funda as a
where 1988<=year(datadate)<=2006 and consol="C" and indfmt="INDL" and datafmt="STD" and popsrc="D" and curcd="USD" and gvkey ne "."; quit;
*1975<=fyearq<=2011;
*Download table;

*Merge SIC codes;
proc sql;
create table compstatnames
as select *
from compstat as a, comp.names as b
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

*Create fake lags;
data lag;
 set compustatcrsp2;
 lagat=at;
 lagsale=sale;
 lagrect=rect;
 lagni=ni;
run;

*Merge lags;
proc sql;
 create table compstatlag
 as select a.*, b.lagat, b.lagsale, b.lagrect, b.lagni
 from compustatcrsp2 a left join lag b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear+1);
quit;*n=1,488,519;

*Define variables;
data variable;
 set compstatlag;
 sictwo=int(sic/100);
 sicthree=int(sic/10);
 ta=ni-oancf;
 scaleint=1/lagat;
 deltarev=sale-lagsale;
 deltaar=rect-lagrect;
 revar=deltarev-deltaar;
 taat=ta/lagat;
 deltarevat=deltarev/lagat;
 ppeat=ppegt/lagat;
 revarat=revar/lagat;
 niat=ni/at;
 chni=ni-lagni;
 chniat=chni/at;
 if 0 le niat le 0.01 then bench=1;
 else if 0 le chniat le 0.01 then bench=1;
 else bench=0;
 mv=prcc_f*csho;
 size=log(at);
 mtb=mv/ceq;
 roa=ib/lagat;
run;

*Delete missing variables;
data screen;
 set variable;
 if taat=. then delete;
 if scaleint=. then delete;
 if deltarevat=. then delete;
 if ppeat=. then delete;
 if deltaar=. then delete;
run;

*15 observations per industry-year minimum;
proc sort data=screen; by sicthree fyear; run;

*Count number of firms per industry-year;
proc summary data=screen;
 by sicthree fyear;
 var taat;
 output out=nofirms (drop=_type_) mean=;
run;

*Merge it back;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table screenfirms
 as select a.*, b._freq_ as n
 from screen a left join nofirms b
 on (a.sicthree=b.sicthree) and (a.fyear=b.fyear);
quit;

*At least ten (footnote 19 [Frank et al. (2009)]);
data nscreen;
 set screenfirms;
 if n<15 then delete;
 *if 1988 le year le 2002;
run;*n=41,296;

proc sort data=nscreen nodupkey; by gvkey fyear; run;

*Sort before regression;
proc sort data=nscreen; by sicthree fyear; run;

data variable2;
 set nscreen;
 if 1988 le year(datadate) le 2005;
run;

*Winsorize;
%Winsorize_Truncate(dsetin = variable2, dsetout = winsor, byvar = none, vars = taat scaleint deltarevat ppeat revar, type = W, pctl = 1 99);

*Run cross-sectional regression by industry and year to get coefficients;
proc reg data=variable2 outest=coefficients noprint;
 by sicthree fyear;
 model taat=scaleint deltarevat ppeat;
run;
quit;

*Merge coefficients;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table regest
 as select a.*, b.scaleint as bone, b.deltarevat as btwo, b.ppeat as bthree
 from variable2 a left join coefficients b
 on (a.sicthree=b.sicthree) and (a.fyear=b.fyear);
quit;

*Define normal accruals;
data normal;
 set regest;
 na=bone*1+btwo*revar+bthree*ppegt;
 naat=na/lagat;
 *frq=abs(taat-naat);*We will turn this dial. Absolute value is unsigned. I want signed;
 frq=taat-naat;
 year=year(datadate);*Calendar year;
run;

*Truncate;
%Winsorize_Truncate(dsetin = normal, dsetout = truncate, byvar = none, vars = frq, type = T, pctl = 2.5 97.5);

proc sort data=truncate; by sicthree year; run;

*Merge trade with SG&A;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table tradefrq
 as select a.*, b.postreduction, b.cut
 from truncate a left join schott b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

/*Delete observation if it doesn't match to the trade data;
data traderd2;
 set traderd;
 if postreduction=. then delete;
 benchpostred=bench*postreduction;
run;*/

data tradefrq2;
 set tradefrq;
 if postreduction=. then delete;
 benchpostred=bench*postreduction;
run;

proc sort data=tradefrq2; by gvkey fyear; run;

proc download data=traderd2; run;
proc download data=tradeprod2; run;
proc download data=tradefrq2; run;

endrsubmit;

*Save datasets;
data temp.traderd2;
 set traderd2;
run;

data temp.tradeprod2;
 set tradeprod2;
run;

data temp.tradefrq2;
 set tradefrq2;
run;

*Create dataset from which to make bar graph in STATA;
data tradeprod;
 set temp.tradeprod2;
 if cut=1;
 keep sicthree year cut;
run;

proc sort data=tradeprod out=tradeprodind nodupkey; by sicthree; run;
proc sort data=tradeprodind; by year; run;

proc summary data=tradeprodind;
 by year;
 var cut;
 output out=bargraph (drop=_type_) sum=;
run;

*Export to STATA;
*http://www.ats.ucla.edu/stat/mult_pkg/faq/fromSAS_toStata.htm;
proc export data=temp.traderd2 outfile= "D:\ay32\My Documents\Fall 2013\traderd.dta" replace;
run;

proc export data=temp.tradeprod2 outfile= "D:\ay32\My Documents\Fall 2013\tradeprod.dta" replace;
run;

proc export data=temp.tradefrq2 outfile= "D:\ay32\My Documents\Fall 2013\tradefrq.dta" replace;
run;

proc export data=bargraph outfile= "D:\ay32\My Documents\Fall 2013\bargraph.dta" replace;
run;

