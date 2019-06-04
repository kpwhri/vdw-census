/**********************************************
  Query the ACS Census Data API
  Hit the ACS 5-Year Detailed Tables
  https://www.census.gov/data/developers/data-sets/acs-5year.html
  https://api.census.gov/data/2017/acs/acs5.html

  More than a modest number of queries will require signing up for an API key:
  https://api.census.gov/data/key_signup.html

  Inputs:
    * ACS Group (table) - https://api.census.gov/data/2017/acs/acs5/groups.html
      For instance, B15002 is Sex by Educational Attainment
    * State of interest (one state at a time is queried)
    * ACS Year
    * Output directory for SAS dataset
    * File reference for JSON text file returned by API query
    * (Optional) Census API Key - I have this built into the macro since it shouldn't change
  Output:
    * SAS dataset containing all point estimates (not variances or addenda) for that group
**********************************************/

%MACRO get_acs_from_api(acsgroup, stfips, acsyear, outdir, key=false);

  filename response "&CODEHOME./api_response.txt";

  * Ensure variables in query are properly formatted.;
  %LET ACSYEAR = %CMPRES(&ACSYEAR.);
  %LET ACSGROUP = %CMPRES(%UPCASE(&ACSGROUP.));
  %LET CENSUS_KEY = %CMPRES(%UPCASE(&KEY.));

  %LET url = https://api.census.gov/data/&ACSYEAR./acs/acs5?get=NAME,group(&ACSGROUP.)%STR(&)for=tract:*%STR(&)in=state:&STFIPS.;
  %IF &CENSUS_KEY. ne FALSE %THEN %DO;
    %LET url = &URL.%STR(&)key=&CENSUS_KEY.;
  %END;
  %PUT Querying ACS 5-year data at &URL.;

  proc http
    url = "&URL."
    out = response;
  run;

  * API returns data in JSON format.;
  libname acsjson JSON fileref=response;

  * Read column names from first row of JSON data.;
  data acs_var_names;
    set acsjson.root;
    if _n_ = 1;
    array varlist {*} element:;
    do v = 1 to dim(varlist);
      put "Considering variable " varlist{v};
      if upcase(varlist{v}) in ('GEO_ID', 'STATE', 'COUNTY', 'TRACT')
        or reverse(upcase(trim(varlist{v}))) =: 'E' then do;
        put "... adding to final dataset";
        origname = compress('element' || v);
        kp = origname;
        rn = compress(origname || "=" || varlist{v});
        output;
      end;
    end;
    keep rn kp;
  run;

  proc sql noprint;
    select rn into :rn_stmt separated by ' '
      from acs_var_names;
    select kp into :kp_stmt separated by ' '
      from acs_var_names;
  quit;

  %*PUT Rename statement is &RN_STMT.;
  %*PUT Keep statement is &KP_STMT.;

  data &ACSGROUP.;
    set acsjson.root(firstobs=2);
    rename &RN_STMT.;
    keep &KP_STMT.;
  run;

  * Output contents to transform variable names into VDW Census Demog names.;
  proc contents data=&ACSGROUP. noprint memtype=data short out=&ACSGROUP._cols;
  run;

  * Re-create the variables as numeric & change names to square with VDW Census.;
  proc sql noprint;
    select name into :dropvars separated by " "
      from &ACSGROUP._cols
      where upcase(name) like compress(upcase("&ACSGROUP.%"));
    select catx('=', compress(name, '_E'), 'input(' || name || ', 8.)') into :fixvars separated by "; "
      from &ACSGROUP._cols
      where upcase(name) like compress(upcase("&ACSGROUP.%"));
  quit;

  data &OUTDIR..&ACSGROUP.;
    * Set these lengths to enforce similar attributes to VDW version.;
    length state $2. county $3.;
    set &ACSGROUP.;
    &FIXVARS.;
    drop &DROPVARS.;
    * Drop some additional variables that should not be found on VDW Census Demog;
    drop name geo_id element:;
  run;

  * Clean up datasets & downloaded JSON file.;
  proc datasets lib=work;
    delete acs_var_names &ACSGROUP.;
  run;
  data _null_;
    if fexist("response") then rc = fdelete("response");
    if rc ne 0 then do;
      msg = sysmsg();
      put "ERROR: " msg;
    end;
  run;

%MEND get_acs_from_api;