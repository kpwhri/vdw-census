* Quick look for extremes values (< 0%, > 100%) in calculated variables.;

* I don't love that the code traverses the whole dataset for every variable.
  There's gotta be a better way. Please send me a pull request when you work it out!;

%make_spm_comment(ACS Census quick QA);

libname _output "\\groups.ghc.org\data\CTRHS\VDW_SDOH\PROGRAMMING\Programs\VDWCensus\output";

options nomlogic nomprint nosymbolgen;

%macro extremes(table, var);
  proc sql noprint;
    create table &var._ext_hi as
    select *, input(blockgp,best12.) as block_group, input(tract,best12.) as tract_num
    from &table
    where &var.>1;
  quit;

  %let DSID  = %sysfunc(open(&var._ext_hi, IS));
  %let anobs = %sysfunc(attrn(&DSID, NOBS));
  %let rc    = %sysfunc(close(&DSID));
  %IF %eval(&anobs. = 0) %THEN %do;
    %put NOTE: There are no high extreme values > 1 for &var.;
  %end;
  %else %do;
    proc sql noprint;
      select sum(block_group) into:blockgpvalues from &var._ext_hi;
      select sum(tract_num) into:tractvalues from &var._ext_hi;
    quit;
    %if %eval(&blockgpvalues>.) %then %do;
      %put WARNING: Extreme high values for &var. in blockgroups;
    %end;
    title "Review distribution of var=&var. for extreme values";
    proc univariate data=&table.;
      var &var.;
      histogram;
    run;
    title;
    %if %eval(&tractvalues>.) %then %do;
      %put WARNING: Extreme high values for &var. in census tracts;
    %end;
    title "Review distribution of var=&var. for extreme values";
    proc univariate data=&table.;
      var &var.;
      histogram;
    run;
    title;
    %if %eval(&blockgpvalues>.) and %eval(&tractvalues>.) %then %do;
      %put WARNING: Extreme high values for &var. in county level;
    %end;
    title "Review distribution of var=&var. for extreme values";
    proc univariate data=&table.;
      var &var.;
      histogram;
    run;
    title;
    %let rc=%sysfunc(close(&DSID));
  %end;

  proc sql noprint;
    create table &var._ext_lo as
    select *, input(blockgp,best12.) as block_group, input(tract,best12.) as tract_num
    from &table
    where 0>&var.>.;
  quit;

  %let DSID  = %sysfunc(open(&var._ext_lo, IS));
  %let anobs = %sysfunc(attrn(&DSID, NOBS));
  %let rc    = %sysfunc(close(&DSID));
  %IF %eval(&anobs. = 0) %THEN %do;
    %put NOTE: There are no low extreme values between . and 0 for &var.;
  %end;
  %else %do;
    proc sql noprint;
      select sum(block_group) into:blockgpvalues from &var._ext_lo;
      select sum(tract_num) into:tractvalues from &var._ext_lo;
    quit;
    %if %eval(0>&blockgpvalues>.) %then %do;
      %put WARNING: Extreme low values for &var. in blockgroups;
    %end;
    title "Review distribution of var=&var. for extreme values";
    proc univariate data=&table.;
      var &var.;
      histogram;
    run;
    title;
    %if %eval(0>&tractvalues>.) %then %do;
      %put WARNING: Extreme low values for &var. in census tracts;
    %end;
    title "Review distribution of var=&var. for extreme values";
    proc univariate data=&table.;
      var &var.;
      histogram;
    run;
    title;
    %if %eval(0>&blockgpvalues>.) and %eval(&tractvalues>.) %then %do;
      %put WARNING: Extreme low values for &var. in county level;
    %end;
    title "Review distribution of var=&var. for extreme values";
    proc univariate data=&table.;
      var &var.;
      histogram;
    run;
    title;
    %let rc=%sysfunc(close(&DSID));
  %end;
%mend extremes ;


*QA numeric/calculated fields for values <0 or >1;
%extremes(_output.census_demog, Disability)
%extremes(_output.census_demog, Divorced)
%extremes(_output.census_demog, English_Speaker)
%extremes(_output.census_demog, FAMPOVERTY)
%extremes(_output.census_demog, Female_Head_of_HH)
%extremes(_output.census_demog, HH_NoCar)
%extremes(_output.census_demog, HH_Public_Assistance)
%extremes(_output.census_demog, HOUSPOVERTY)
%extremes(_output.census_demog, Ins_Medicaid)
%extremes(_output.census_demog, Ins_Medicare)
/* %extremes(_output.census_demog, KPCO_ACS_18overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_25overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_65overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_AS) */
/* %extremes(_output.census_demog, KPCO_ACS_BA) */
/* %extremes(_output.census_demog, KPCO_ACS_HP) */
/* %extremes(_output.census_demog, KPCO_ACS_HS) */
/* %extremes(_output.census_demog, KPCO_ACS_IN) */
/* %extremes(_output.census_demog, KPCO_ACS_MU) */
/* %extremes(_output.census_demog, KPCO_ACS_NHWH) */
/* %extremes(_output.census_demog, KPCO_ACS_OT) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_AS) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_BA) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_HP) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_HS) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_IN) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_MU) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_NHWH) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_OT) */
/* %extremes(_output.census_demog, KPCO_ACS_Total_Pop_WH) */
/* %extremes(_output.census_demog, KPCO_ACS_WH) */
/* %extremes(_output.census_demog, KPCO_ACS_female18overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_female25overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_female65overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_femaleunder18pop) */
/* %extremes(_output.census_demog, KPCO_ACS_male18overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_male25overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_male65overpop) */
/* %extremes(_output.census_demog, KPCO_ACS_maleunder18pop) */
/* %extremes(_output.census_demog, KPCO_ACS_under18pop) */
%extremes(_output.census_demog, MGR_Female)
%extremes(_output.census_demog, MGR_Male)
%extremes(_output.census_demog, Married)
%extremes(_output.census_demog, MovedInLast12Mon)
%extremes(_output.census_demog, Pct_crowding)
%extremes(_output.census_demog, Residents_65)
%extremes(_output.census_demog, Same_residence)
%extremes(_output.census_demog, Spanish_Speaker)
%extremes(_output.census_demog, Unemployment)
%extremes(_output.census_demog, Unemployment_Male)
%extremes(_output.census_demog, education1)
%extremes(_output.census_demog, education2)
%extremes(_output.census_demog, education3)
%extremes(_output.census_demog, education4)
%extremes(_output.census_demog, education5)
%extremes(_output.census_demog, education6)
%extremes(_output.census_demog, education7)
%extremes(_output.census_demog, education8)
%extremes(_output.census_demog, famincome1)
%extremes(_output.census_demog, famincome2)
%extremes(_output.census_demog, famincome3)
%extremes(_output.census_demog, famincome4)
%extremes(_output.census_demog, famincome5)
%extremes(_output.census_demog, famincome6)
%extremes(_output.census_demog, famincome7)
%extremes(_output.census_demog, famincome8)
%extremes(_output.census_demog, famincome9)
%extremes(_output.census_demog, famincome10)
%extremes(_output.census_demog, famincome11)
%extremes(_output.census_demog, famincome12)
%extremes(_output.census_demog, famincome13)
%extremes(_output.census_demog, famincome14)
%extremes(_output.census_demog, famincome15)
%extremes(_output.census_demog, famincome16)
%extremes(_output.census_demog, housincome1)
%extremes(_output.census_demog, housincome2)
%extremes(_output.census_demog, housincome3)
%extremes(_output.census_demog, housincome4)
%extremes(_output.census_demog, housincome5)
%extremes(_output.census_demog, housincome6)
%extremes(_output.census_demog, housincome7)
%extremes(_output.census_demog, housincome8)
%extremes(_output.census_demog, housincome9)
%extremes(_output.census_demog, housincome10)
%extremes(_output.census_demog, housincome11)
%extremes(_output.census_demog, housincome12)
%extremes(_output.census_demog, housincome13)
%extremes(_output.census_demog, housincome14)
%extremes(_output.census_demog, housincome15)
%extremes(_output.census_demog, housincome16)
/* %extremes(_output.census_demog, kpco_geolevel) */
/* %extremes(_output.census_demog, medfamincome) */
/* %extremes(_output.census_demog, medhousincome) */
%extremes(_output.census_demog, pov_100_124)
%extremes(_output.census_demog, pov_125_149)
%extremes(_output.census_demog, pov_150_174)
%extremes(_output.census_demog, pov_175_184)
%extremes(_output.census_demog, pov_185_199)
%extremes(_output.census_demog, pov_50_74)
%extremes(_output.census_demog, pov_75_99)
%extremes(_output.census_demog, pov_gt_200)
;
