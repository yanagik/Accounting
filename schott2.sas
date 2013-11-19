*Temporary library name;
libname temp 'D:\ay32\My Documents\Spring 2013';

*Now we're going to import the trade data and merge by subsample;
*It comes originally from Peter Schott's web site;
data schott;
 set temp.schott;
 if 1987 le year le 2005;*SIC data get matched from 1987, lose a year from first differencing;
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

/*proc means data=schottdamed; var deltaavt; run;*/

*Merge median back;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table schotttariffmed
 as select a.*, b.deltaavt as median
 from schotttariff a left join schottdamed b
 on (a.sicthree=b.sicthree);
quit;

proc sort data=schotttariffmed; by sicthree year; run;

*This is a suboptimal way of fixing the bad result. The design choice isn't really justifiable;
/*data percentneg;
 set schotttariffmed;
 if deltaavt<0 then neg=1;
 else neg=0;
run;

*I want the average by industry;
proc summary data=percentneg;
 by sicthree;
 var neg;
 output out=percentnegmu (drop=_type_ _freq_) mean=;
run;

data percentneg2;
 set percentnegmu;
 if neg<0.7 then less=1;
 else less=0;
run;

proc means data=percentneg2; var less; run;*11.2% of industries (134 total) have median changes > 0. The flip side is that almost 90% of the industries have median changes < 0;
*35.82% of industries have time series changes that are 40% or more positive. 64% ish of the industries have time series changes that are 60% or more negative.;
*53.73% of industries have time series changes that are 30% or more positive. 46% ish of the industries have time series changes that are 70% or more negative.;

*Merge less;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table schotttariffmed2
 as select a.*, b.less
 from schotttariffmed a left join percentneg2 b
 on (a.sicthree=b.sicthree);
quit;

data schotttariffmed3;
 set schotttariffmed2;
 *if less=0;
 if less=1;
run;*/

data triple;
 *set schotttariffmed3;
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
 if deltaavt=min then markermin=1;
 else markermin=0;
run;

*Create fake lag;
data indicatorlag;
 set indicator;
 lagdeltaavt=deltaavt;
 lagcandidate=candidate;
 lagincrease=increase;
run;

proc sort data=indicatorlag; by sicthree year; run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorlagmerge
 as select a.*, b.lagdeltaavt, b.lagcandidate, b.lagincrease
 from indicator a left join indicatorlag b
 on (a.sicthree=b.sicthree) and (a.year=b.year+1);
quit;

*Create fake lead;
data indicatorlead;
 set indicatorlagmerge;
 leaddeltaavt=deltaavt;
 leadcandidate=candidate;
 leadincrease=increase;
run;

proc sort data=indicatorlagmerge; by sicthree year; run;
proc sort data=indicatorlead; by sicthree year; run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorleadmerge
 as select a.*, b.leaddeltaavt, b.leadcandidate, b.leadincrease
 from indicatorlagmerge a left join indicatorlead b
 on (a.sicthree=b.sicthree) and (a.year=b.year-1);
quit;

*Repeat process for second lead;
proc sort data=indicatorleadmerge; by sicthree year; run;
proc sort data=indicatorlead; by sicthree year; run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorleadmerge2
 as select a.*, b.leadincrease as leadleadincrease
 from indicatorleadmerge a left join indicatorlead b
 on (a.sicthree=b.sicthree) and (a.year=b.year-2);
quit;

data indicator3;
 set indicatorleadmerge2;
 if markermin=1 & lagincrease=1 & leadincrease=1 then transitoryv=1;
 else transitoryv=0;
 if markermin=1 & leadincrease=1 & leadleadincrease=1 then transitoryf=1;*Confirmed to still work;
 /*if marker=1 & leadincrease=1 then transitory=1;
 else if marker=1 & leadleadincrease=1 then transitory=1;*/*Confirmed to NOT work;
 else transitoryf=0;
 if markermin=1 & transitoryv=0 then cutv=1;
 if markermin=1 & transitoryf=0 then cutf=1;
run;*n=57 (cf. 54);

/*data test;
 set indicator3;
 if cut=1;
 keep sicthree year cut;
run;*/

*Create postreduction indicator;
data indicator4;
 set indicator3;
 by sicthree;
 retain postreductionv;
 if first.sicthree then postreductionv=0;
 if cutv=1 then postreductionv=1;
 retain postreductionf;
 if first.sicthree then postreductionf=0;
 if cutf=1 then postreductionf=1;
run;

data trade;
 set indicator4;
run;*n=1962 industry-years;

/*data test;
 set trade;
 keep sicthree year avt deltaavt median marker increase leadincrease leadleadincrease cut;
run;*/

/*data test;
 set trade;
 keep sicthree year avt deltaavt median marker increase leadincrease leadleadincrease cut;
run;

proc gplot data=trade;
 by sicthree;
 symbol i=spline v=circle h=2;
 plot avt*year;
run;quit;

data trade2;
 set trade;
 keep sicthree year deltaavt median cut;
run;*/

data triplepos;
 set schotttariffmed;
 if abs(deltaavt)>3*abs(median) then candidate=1;
 else candidate=0;
 if candidate=1 & deltaavt<0 then decrease=1;
 else decrease=0;
run;

data trippos;
 set triplepos;
 if candidate=1;
 if deltaavt>0;
run;

proc summary data=trippos;
 by sicthree;
 var deltaavt;
 output out=tripposmax (drop=_type_ _freq_) max=;
run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table triplemax
 as select a.*, b.deltaavt as max
 from triplepos a left join tripposmax b
 on (a.sicthree=b.sicthree);
quit;

data indicatorpos;
 set triplemax;
 if max=. then delete;
 if deltaavt=max then markermax=1;
 else markermax=0;
run;

*Create fake lag;
data indicatorlagpos;
 set indicatorpos;
 lagdeltaavt=deltaavt;
 lagcandidate=candidate;
 lagdecrease=decrease;
run;

proc sort data=indicatorlagpos; by sicthree year; run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorlagmergepos
 as select a.*, b.lagdeltaavt, b.lagcandidate, b.lagdecrease
 from indicatorpos a left join indicatorlagpos b
 on (a.sicthree=b.sicthree) and (a.year=b.year+1);
quit;

proc sort data=indicatorlagpos; by sicthree year; run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorlagmergepos2
 as select a.*, b.lagdecrease as laglagdecrease
 from indicatorlagmergepos a left join indicatorlagpos b
 on (a.sicthree=b.sicthree) and (a.year=b.year+2);
quit;

*Create fake lead;
data indicatorleadpos;
 set indicatorlagmergepos2;
 leaddeltaavt=deltaavt;
 leadcandidate=candidate;
 leaddecrease=decrease;
run;

proc sort data=indicatorlagmergepos2; by sicthree year; run;
proc sort data=indicatorleadpos; by sicthree year; run;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorleadmergepos
 as select a.*, b.leaddeltaavt, b.leadcandidate, b.leaddecrease
 from indicatorlagmergepos2 a left join indicatorleadpos b
 on (a.sicthree=b.sicthree) and (a.year=b.year-1);
quit;

data indicator3pos;
 set indicatorleadmergepos;
 if markermax=1 & lagdecrease=1 & leaddecrease=1 then transitoryv=1;*Confirmed to work, which is bad;
 else transitoryv=0;
 if markermax=1 & lagdecrease=1 & laglagdecrease=1 then transitoryf=1;*Confirmed to work, which is bad;
 else transitoryf=0;
 if markermax=1 & lagdecrease=1 then transitorym=1;
 else if marker=1 & laglagdecrease=1 then transitorym=1;*Confirmed to NOT work, which in some sense is OK;
 else transitorym=0;
 if markermax=1 & transitoryv=0 then raisev=1;
 if markermax=1 & transitoryf=0 then raisef=1;
 if markermax=1 & transitorym=0 then raisem=1;
run;*n=57 (cf. 54);

*Create postincrease indicator;
data indicator4pos;
 set indicator3pos;
 by sicthree;
 retain postincreasev;
 if first.sicthree then postincreasev=0;
 if raisev=1 then postincreasev=1;
 retain postincreasef;
 if first.sicthree then postincreasef=0;
 if raisef=1 then postincreasef=1;
 retain postincreasem;
 if first.sicthree then postincreasem=0;
 if raisem=1 then postincreasem=1;
run;

data tradepos;
 set indicator4pos;
run;*n=1962 industry-years;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table tradeboth
 as select a.*, b.raisev, b.raisef, b.raisem, b.postincreasev, b.postincreasef, b.postincreasem
 from trade a left join tradepos b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

*My classification;
*Merge indicator and indicatorpos;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorboth
 as select a.*, b.max, b.markermax
 from indicator a left join indicatorpos b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

proc sort data=indicatorboth; by sicthree year; run;

*Merge year of markermax;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table indicatorboth2
 as select a.*, b.year as yearmax
 from indicatorboth a left join indicatorboth b
 on (a.sicthree=b.sicthree) and (a.markermin=b.markermax=1);
quit;

proc sort data=indicatorboth2; by sicthree year; run;

*Create postreduction indicator;
data postreduction;
 set indicatorboth2;
 by sicthree;
 retain postreductionmy;
 if first.sicthree then postreductionmy=0;
 if markermin=1 then postreductionmy=1;
 *lagavtpostreduction=lagavt*postreduction;
 retain postincreasemy;
 if first.sicthree then postincreasemy=0;
 if markermax=1 then postincreasemy=1;
run;

/*proc reg data=postreduction;
 by sicthree;
 model avt=lagavt lagavtpostreduction;
run;quit;*/

proc reg data=postreduction noprint outest=betas outseb;
 by sicthree;
 model avt=postreductionmy;
run;quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table betas2
 as select a.*, b.postreductionmy as postreductionmyse
 from betas a left join betas b
 on (a.sicthree=b.sicthree) and (b._TYPE_="SEB");
quit;

data betas3;
 set betas2;
 tstat=postreductionmy/postreductionmyse;
 if postreductionmy=postreductionmyse & tstat=1 then delete;
 if postreductionmy>0 then transitory=1;
 else if postreductionmy<0 & abs(tstat)<2.58 then transitory=1;
 else transitory=0;
run;*n=66 out of 113 have nontransitory changes;

data betas4;
 set betas3;
 if transitory=0;
run;

proc reg data=postreduction noprint outest=betasinc outseb;
 by sicthree;
 model avt=postincreasemy;
run;quit;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table betasinc2
 as select a.*, b.postincreasemy as postincreasemyse
 from betasinc a left join betasinc b
 on (a.sicthree=b.sicthree) and (b._TYPE_="SEB");
quit;

data betasinc3;
 set betasinc2;
 tstat=postincreasemy/postincreasemyse;
 if postincreasemy=postincreasemyse then delete;
 if postincreasemy<0 then transitory=1;
 else if postincreasemy>0 & abs(tstat)<2.58 then transitory=1;
 else transitory=0;
 if tstat=. then delete;
run;*n=17 out of 103 have nontransitory changes;

proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table betasboth
 as select a.*, b.transitory as transitoryinc
 from betas3 a left join betasinc3 b
 on (a.sicthree=b.sicthree);
quit;

*Merge transitory indicator;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table postreductionind
 as select a.*, b.transitory, b.transitoryinc
 from postreduction a left join betasboth b
 on (a.sicthree=b.sicthree);
quit;

proc sort data=postreductionind; by sicthree year; run;

data postreductionind2;
 set postreductionind;
 if transitory=1 then postreductionmy=0;
 else if transitoryinc=1 then postincreasemy=0;
 if markermin=1 & transitory=0 then cutmy=1;
run;

*Merge with tradeboth;
proc sql;*http://sbaleone.bus.miami.edu/PERLCOURSE/SASFILES/SQL_EXAMPLES.sas;
 create table postreductionind3
 as select a.*, b.postreductionmy, b.postincreasemy, b.cutmy
 from tradeboth a left join postreductionind2 b
 on (a.sicthree=b.sicthree) and (a.year=b.year);
quit;

*Export;
data temp.schotttrade3;
 set postreductionind3;
run;

proc export data=temp.schotttrade2 outfile= "D:\ay32\My Documents\Spring 2013\tradeboth.dta" replace;
run;

data sixteen;
 set temp.schotttrade3;
 if 203 le sicthree le 224 then delete;
 if 226 le sicthree le 242 then delete;
 if 244 le sicthree le 250 then delete;
 if 252 le sicthree le 280 then delete;
 if sicthree=282 then delete;
 if 285 le sicthree le 300 then delete;
 if 302 le sicthree le 307 then delete;
 if 309 le sicthree le 330 then delete;
 if sicthree=332 then delete;
 if 334 le sicthree le 352 then delete;
 if 354 le sicthree le 380 then delete;
 if 382 le sicthree le 385 then delete;
 if 387 le sicthree le 398 then delete;
run;

proc gplot data=sixteen;
 by sicthree;
 symbol i=spline v=circle h=2;
 plot avt*year;
run;quit;

proc export data=sixteen outfile= "D:\ay32\My Documents\Fall 2013\sixteen.dta" replace;
run;
