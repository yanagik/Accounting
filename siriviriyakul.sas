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
where 1986<=year(datadate)<=2012 and consol="C" and indfmt="INDL" and datafmt="STD" and popsrc="D" and curcd="USD" and gvkey ne "."; quit;
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

/*proc download data=compustatcrsp; run; quit;

data temp.siriviriyakulbase;
 set compustatcrsp;
run;

data compustatcrsp;
 set temp.siriviriyakulbase;
run;*/

*Here we begin the RM part;
*Create lag;
data lag;
 set compustatcrsp;
 lagat=at;
 lagxrd=xrd;
 lagsale=sale;
 lagni=ni;
 lagprcc=prcc_f;
 lagcsho=csho;
 lagceq=ceq;
run;

*Merge lag;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table lagone
 as select a.*, b.lagat, b.lagsale, b.lagxrd, b.lagni, b.lagprcc, b.lagcsho, b.lagceq
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
 if 6000 le sic le 6500 then delete;*n=119,142;
 sictwo=int(sic/100);
 sicthree=int(sic/10);
 naicsthree=int(naics/1000);
 year=year(datadate);*Calendar year;
 if lagat ne .;*n=85,605;
 if lagprcc ne .;*n=76,952;
 if lagcsho ne .;*n=76,693;
 if oancf ne .;
 if sale ne .;
 if lagsale ne .;
 if laglagsale ne .;
 if cogs ne .;
 if invch ne .;
 if xsga ne .;
 if ib ne .;
 if lagceq ne .;
 if xad = . then xad=0;
 if xrd = . then xrd=0;
run;

*Variables;
data variable;
 set screen;
 disx=xad+xrd+xsga;
 disxat=disx/lagat;
 lagsaleat=lagsale/lagat;
 cfoat=oancf/lagat;
 saleat=sale/lagat;
 chsale=sale-lagsale;
 chsaleat=chsale/lagat;
 prod=cogs+invch;
 prodat=prod/lagat;
 lagchsale=lagsale-laglagsale;
 lagchsaleat=lagchsale/lagat;
 scaleint=1/lagat;
 lagmv=log(lagprcc*lagcsho);
 niat=ni/lagat;
 if 0 le niat < 0.005 then bench=1;
 else bench=0;
 lagmtb=lagmv/lagceq;
 roa=ib/lagat;
run;

proc sort data=variable; by sictwo fyear; run;

*Count number of firms per industry-year;
proc summary data=variable;
 by sictwo fyear;
 var scaleint;
 output out=nofirms (drop=_type_) mean=;
run;

*Merge it back;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table varno
 as select a.*, b._freq_ as n
 from variable a left join nofirms b
 on (a.sictwo=b.sictwo) and (a.fyear=b.fyear);
quit;

*At least ten (footnote 19 [Frank et al. (2009)]);
data varnoscreen;
 set varno;
 if n<15 then delete;
 *if 1987 le year le 2001;
run;*n=41,296;

*Sort before winsorize;
proc sort data=varnoscreen nodupkey; by gvkey fyear; run;*n=49,906;

*Truncate;
%Winsorize_Truncate(dsetin = varnoscreen, dsetout = truncate, byvar = none, vars = disxat scaleint lagsaleat cfoat saleat prodat chsaleat lagchsaleat lagmv lagmtb roa, type = T, pctl = 1 99);

proc sort data=truncate; by sictwo fyear; run;

proc summary data=truncate;
 by sictwo fyear;
 var lagmv lagmtb roa;
 output out=truncate2 (drop=_type_) mean(lagmv)=mulagmv mean(lagmtb)=mulagmtb mean(roa)=muroa;
run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table truncate3
 as select a.*, b.mulagmv, b.mulagmtb, b.muroa
 from truncate a left join truncate2 b
 on (a.sictwo=b.sictwo) and (a.fyear=b.fyear);
quit;

data truncate4;
 set truncate3;
 dmlagmv=lagmv-mulagmv;
 dmlagmtb=lagmtb-mulagmtb;
 dmroa=roa-muroa;
 *if -0.075 le niat le 0.075;*The extremes cut;
run;

proc download data=truncate4; run; quit;
endrsubmit;

data temp.siriviriyakul2012;
 set truncate4;
run;

data truncate4;
 set temp.siriviriyakul2012;
 *if -0.075 le niat le 0.075;
 if 1987 le year le 2001;
run;

*"Discretionary" expenditures;
proc sort data=truncate4; by sictwo fyear; run;
proc reg data=truncate4 outest=disxcoeff noprint;
 by sictwo fyear;
 model disxat=scaleint lagsaleat;
 output out=expend residual=disx2;
run;
quit;

data disxcoeff2;
 set disxcoeff;
 interceptdx=intercept;
 scaleintdx=scaleint;
 lagsaleatdx=lagsaleat;
run;

*Abnormal CFO;
proc reg data=truncate4 outest=dcfocoeff noprint;
 by sictwo fyear;
 model cfoat=scaleint saleat chsaleat;
 output out=cfo residual=dcfo;
run;
quit;

data dcfocoeff2;
 set dcfocoeff;
 interceptdc=intercept;
 scaleintdc=scaleint;
 saleatdc=saleat;
 chsaleatdc=chsaleat;
run;

*Abnormal production;
proc reg data=truncate4 outest=dprodcoeff noprint;
 by sictwo fyear;
 model prodat=scaleint saleat chsaleat lagchsaleat;
 output out=prod residual=dprod;
run;
quit;

data dprodcoeff2;
 set dprodcoeff;
 interceptdp=intercept;
 scaleintdp=scaleint;
 saleatdp=saleat;
 chsaleatdp=chsaleat;
 lagchsaleatdp=lagchsaleat;
run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table dxcfocoeff
 as select a.*, b.interceptdc, b.scaleintdc, b.saleatdc, b.chsaleatdc
 from disxcoeff2 a left join dcfocoeff2 b
 on (a.sictwo=b.sictwo) and (a.fyear=b.fyear);
quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table allcoeff
 as select a.*, b.interceptdp, b.scaleintdp, b.saleatdp, b.chsaleatdp, b.lagchsaleatdp
 from dxcfocoeff a left join dprodcoeff2 b
 on (a.sictwo=b.sictwo) and (a.fyear=b.fyear);
quit;

*Merge coefficients back to truncate4;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table truncatecoeff
 as select a.*, b.interceptdx, b.scaleintdx, b.lagsaleatdx, b.interceptdc, b.scaleintdc, b.saleatdc, b.chsaleatdc, b.interceptdp, b.scaleintdp, b.saleatdp, b.chsaleatdp, b.lagchsaleatdp
 from truncate4 a left join allcoeff b
 on (a.sictwo=b.sictwo) and (a.fyear=b.fyear+1);
quit;

data truncatecoeff2;
 set truncatecoeff;
 normdisx=interceptdx+scaleintdx*scaleint+lagsaleatdx*lagsaleat;
 lagdisx=disxat-normdisx;
 normcfo=interceptdc+scaleintdc*scaleint+saleatdc*saleat+chsaleatdc*chsaleat;
 lagdcfo=cfoat-normcfo;
 normprod=interceptdp+scaleintdp*scaleint+saleatdp*saleat+chsaleatdp*chsaleat+lagchsaleatdp*lagchsaleat;
 lagdprod=prodat-normprod;
run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table discfo
 as select a.*, b.dcfo
 from expend a left join cfo b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear);
quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table allthree
 as select a.*, b.dprod
 from discfo a left join prod b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear);
quit;

proc sort data=allthree out=allthree2; by fyear; run;

proc export data=allthree2 outfile= "D:\ay32\My Documents\Fall 2013\roy.dta" replace;
run;

/*Extremes test;
data extremes;
 set allthree2;
 if -0.075 le niat le 0.075;
run;*/

*Histogram;
proc univariate data =allthree2 noprint;
histogram niat / endpoints=-.075 to .075 by .005;
run;

*Production;
ods listing close;
ods output parameterestimates=pe;
proc reg data=allthree2;
 by fyear;
 model dprod=dmlagmv dmlagmtb dmroa bench; run;
quit;
ods listing;

proc means data=pe mean std t probt;
 var estimate; class variable;
run;

*CFO;
ods listing close;
ods output parameterestimates=pe;
proc reg data=allthree2;
 by fyear;
 model dcfo=dmlagmv dmlagmtb dmroa bench; run;
quit;
ods listing;

proc means data=pe mean std t probt;
 var estimate; class variable;
run;

*Disx;
ods listing close;
ods output parameterestimates=pe;
proc reg data=allthree2;
 by fyear;
 model disx2=dmlagmv dmlagmtb dmroa bench; run;
quit;
ods listing;

proc means data=pe mean std t probt;
 var estimate; class variable;
run;

*Everything behaved the way it should;

*Lagged coefficients in estimating RM;
*Production;
ods listing close;
ods output parameterestimates=pe;
proc reg data=truncatecoeff2;
 by fyear;
 model lagdprod=dmlagmv dmlagmtb dmroa bench; run;
quit;
ods listing;

proc means data=pe mean std t probt;
 var estimate; class variable;
run;

*CFO;
ods listing close;
ods output parameterestimates=pe;
proc reg data=truncatecoeff2;
 by fyear;
 model lagdcfo=dmlagmv dmlagmtb dmroa bench; run;
quit;
ods listing;

proc means data=pe mean std t probt;
 var estimate; class variable;
run;

*Disx;
ods listing close;
ods output parameterestimates=pe;
proc reg data=truncatecoeff2;
 by fyear;
 model lagdisx=dmlagmv dmlagmtb dmroa bench; run;
quit;
ods listing;

proc means data=pe mean std t probt;
 var estimate; class variable;
run;

*Instead of Fama-Macbeth, let's cluster by year OR firm;
*Inferences remain (mostly) unchanged;
proc surveyreg data=allthree2;
 cluster fyear;
 model dprod=dmlagmv dmlagmtb dmroa bench; run;
quit;

proc surveyreg data=allthree2;
 cluster fyear;
 model dcfo=dmlagmv dmlagmtb dmroa bench; run;
quit;

proc surveyreg data=allthree2;*Restricting observations to plus/minus 0.075 NIAT, this is sensitive to clustering by firm;
 cluster fyear;
 model disx2=dmlagmv dmlagmtb dmroa bench; run;
quit;

*Now, let's do the earnings management vs. rational economic circumstance comparison;
*"Discretionary" expenditures;
proc sort data=allthree2; by sictwo fyear; run;
proc reg data=allthree2 noprint;
 by sictwo fyear;
 model disx2=dmlagmv dmlagmtb dmroa;
 output out=abdis residual=resdis;
run;
quit;

*Abnormal CFO;
proc reg data=allthree2 noprint;
 by sictwo fyear;
 model dcfo=dmlagmv dmlagmtb dmroa;
 output out=abcfo residual=rescfo;
run;
quit;

*Abnormal production;
proc reg data=allthree2 noprint;
 by sictwo fyear;
 model dprod=dmlagmv dmlagmtb dmroa;
 output out=abprod residual=resprod;
run;
quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table abdiscfo
 as select a.*, b.rescfo
 from abdis a left join abcfo b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear);
quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table allres
 as select a.*, b.resprod
 from abdiscfo a left join abprod b
 on (a.gvkey=b.gvkey) and (a.fyear=b.fyear);
quit;

proc sort data=allres out=allres2; by fyear; run;

data allres3;
 set allres;
 if -0.075 le niat le 0.075;
run;

proc rank groups=30 out=thirty data=allres3;
 var niat;
 ranks niatrank;
run;

proc sort data=thirty; by niatrank; run;

proc summary data=thirty;
 by niatrank;
 var resdis rescfo resprod;
 output out=thirtyres (drop=_type_) mean(resdis)=muresdis mean(rescfo)=murescfo mean(resprod)=muresprod;
run;

/*PROC GCHART DATA=thirtyres;
      VBAR niatrank / sumvar=muresprod;
RUN;*/

proc sgplot data=thirtyres;
 vbar niatrank / response=muresprod;
run;

proc sgplot data=thirtyres;
 vbar niatrank / response=muresdis;
run;

proc sgplot data=thirtyres;
 vbar niatrank / response=murescfo;
run;
