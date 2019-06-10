/************************************************************

  Note that this program requires HTTP access to web resources.
  Please follow up locally if firewall or network issues arise.

  Downloads groups of ACS variables for specific states at the census tract level
  (block group data isn't available) via the Census Web API
  and compares them to a local QA version (i.e., with all the underlying ACS
  variables) of Census Demog.

  Uses the Census Web API to download a group of ACS variables for a specific state
  at the census tract level (block group data isn't available via the Web API)
  and compares them to the values from the VDW Census Demographics QA run
  because the production run drops the underlying ACS "building block" variables
  used to create calculated variables.  The production version drops the
  underlying variables that are compared here.

  The list of ACS variable "groups" can be found at
  https://api.census.gov/data/2017/acs/acs5/groups.html

  Census limits the number of requests available for unauthenticated users.
  Request an API key if necessary:
  https://api.census.gov/data/key_signup.html

  Lots of additional sources on the Census Web API.  Here are a few:
    - https://api.census.gov/data.html
    - https://www.census.gov/developers/
    - https://api.census.gov/data/2010/acs/acs5/ (discovery service)

  N.b., sometimes the call to the API results in a complaint.
  After waiting a bit, I've always gotten it to run eventually.
  Check the contents of the api_response.txt file.  If there's JSON, you're good.
  If you get a message like <Invalid key> or <Server not available>, try again.

*************************************************************/

/* EDIT SECTION */

* Any logon scripts & credentials;
%*include "\\HOME\mackcd1\Documents\Systems\sasntlogon.sas";
%*include "&GHRIDW_ROOT.\remote\RemoteStart.sas";
%*make_spm_comment(Test ACS Census data);
*options mprint;
options formchar='|-++++++++++=|-/|<>*' errorabend;

* Set the locations of files.;
* Base directory for all work.;
%LET codehome = \\groups.ghc.org\data\CTRHS\VDW_SDOH\PROGRAMMING\Programs\VDWCensus;
* Location of VDW Census Demographics QA data.;
libname cdemog "\\groups.ghc.org\data\CTRHS\VDW_SDOH\PROGRAMMING\Programs\VDWCensus\output";

* Parameters for API query - set state, group of ACS variables & ACS data year.;
%LET state = WA;
%LET acsgroup = B18101;
%LET acsyear = 2017;

* Optionally set CENSUS_KEY (or set to false to ignore);
%LET CENSUS_KEY = false;
%*LET CENSUS_KEY = MYHEXADECIMALKEYTHATIGOTFROMTHECENSUSAPI;

/* END EDIT SECTION */

libname _acs_api "&CODEHOME.";

* Convert state abbr. to FIPS code.;
%LET stfips = %SYSFUNC(stfips(%CMPRES(%UPCASE(&STATE.))), z2.);

* Macro that pulls a group of ACS variables from the Census Web API.;
%include "&CODEHOME.\lib\get_acs_from_api.sas";

* Get data from ACS Web API.;
%get_acs_from_api(acsgroup=&ACSGROUP.,
                  stfips=&STFIPS.,
                  acsyear=&ACSYEAR.,
                  outdir=_acs_api,
                  key=&CENSUS_KEY.);

proc sort data=_acs_api.&ACSGROUP.;
  by state county tract;
run;

* Select same data from VDW Census Demographics QA version.;
data select_&STATE.;
  set cdemog.census_demog(keep=state county tract blockgp &ACSGROUP.:);
  where state="&STFIPS." and missing(blockgp);
  drop blockgp;
run;

* Remove all formats & labels from VDW Census Demog to facilitate comparison.;
proc datasets lib=work memtype=data;
  modify select_&STATE.;
    attrib _all_ label=' ';
    attrib _all_ format=;
    attrib _all_ informat=;
run;
quit;

proc sort data=select_&STATE.;
  by state county tract;
run;

data _acs_api.select_&STATE.;
  set select_&STATE.;
run;

title "Comparing VDW Census data (select_&STATE.) to Census API data (_acs_api.&ACSGROUP.)";
title2 "Base: select_&STATE.      Compare: _acs_api.&ACSGROUP.";
proc compare base=select_&STATE. compare=_acs_api.&ACSGROUP.;
run;

* Checking value of SYSINFO from Proc Compare;
%LET rc = &SYSINFO.;
%PUT Return code is &RC.;
%PUT Return code is %SYSFUNC(putn(&RC., binary16.)) in binary format;
* Check out this page to analyze return codes:
http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000146743.htm;

proc datasets library=_acs_api;
  delete select_&STATE. &ACSGROUP.;
run;

* Signoff;
* endrsubmit;
* signoff;