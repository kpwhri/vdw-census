* Clean up the working directories and files (optional).;
%MACRO cleanup_temp_dirs(lib);
  %IF %SYSFUNC(exist(output.census_demog)) %THEN %DO;
    proc datasets library=temp_geo kill;
    run;
    proc datasets library=temp_seg kill;
    run;
    data _null_;
      rc = fdelete("TEMP_DIR.\acs_geo_output");
      put rc=;
      msg = sysmsg();
      put msg=;
      rc = fdelete("&TEMP_DIR.\acs_seg_output");
      put rc=;
      msg = sysmsg();
      put msg=;
  %END;
  %ELSE %DO;
      %PUT WARNING: File "output.census_demog" could not be found.;
      %PUT WARNING: Temporary files not deleted.;
  %END;
%MEND;

%MACRO dummy();
%MEND;

%LET etl_keep_stmt =;
%LET clean_temp_dirs = dummy;
%MACRO set_environment(env);
  %PUT Value of env is &ENV.;
  %IF &ENV. = prod %THEN %DO;
    %LET etl_keep_stmt = keep geocode state county tract blockgp education1-education8
      medfamincome famincome1-famincome16 medhousincome housincome1-housincome16
      pov: english_speaker spanish_speaker borninus
      movedinlast12mon married divorced disability unemployment unemployment_male ins_medicare
      ins_medicaid hh_nocar hh_public_assistance hmowner_costs_mort hmowner_costs_no_mort
      homes_medvalue pct_crowding female_head_of_hh mgr_female mgr_male residents_65 same_residence
      fampoverty houspoverty
      &_SITEABBR.:;
    %LET clean_temp_dirs = cleanup_temp_dirs;
  %END;
  %PUT Running in &ENV. mode;
%MEND;