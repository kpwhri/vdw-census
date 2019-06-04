* Loop over state ZIP folders.;
%MACRO loop_state_folders(incl_bg=false);

  * Create temporary directories for geo file & segment file output;
  %IF %SYSFUNC(fileexist("&TEMP_DIR.\acs_geo_output")) = 0 %THEN %DO;
    %LET _crdir = %SYSFUNC(dcreate(acs_geo_output, &TEMP_DIR.));
    %PUT Temporary geo directory created at &_CRDIR.;
  %END;
  %IF %SYSFUNC(fileexist("&TEMP_DIR.\acs_seg_output")) = 0 %THEN %DO;
    %LET _crdir = %SYSFUNC(dcreate(acs_seg_output, &TEMP_DIR.));
    %PUT Temporary seg directory created at &_CRDIR.;
  %END;

  * Get a list of ZIP files in the un-tarred data directory;
  filename _zipdir "&ZIPSEGDIR.";
  data _zipfiles(keep=memname);
    length memname $200;

    fid=dopen("_zipdir");
    if fid=0 then do;
      msg = sysmsg();
      put "Directory error: " msg;
      stop;
    end;

    memcount=dnum(fid);
    do i=1 to memcount;
      memname=dread(fid,i);
      * limit to *.zip files;
      if (reverse(lowcase(trim(memname))) =: 'piz.') then
        output;
    end;
    rc=dclose(fid);
  run;

  filename _zipdir clear;

  * Get the memnames into macro vars;
  proc sql noprint;
    select memname into: zname1- from _zipfiles;
    %LET zipcount = &SQLOBS.;
  quit;

  * For each ZIP file, gather the contents;
  %DO z = 1 %TO &ZIPCOUNT.;
    %PUT Unpacking &ZIPSEGDIR.\&&ZNAME&Z.;
    filename inzip ZIP "&ZIPSEGDIR.\&&ZNAME&Z.";

    data _contents&Z.(keep=ziploc memname);
      length ziploc memname $200.;
      ziploc = "&ZIPSEGDIR.\&&ZNAME&Z.";
      fid = dopen("inzip");

      if fid = 0 then do;
        msg = sysmsg();
        put "Directory error: " msg;
        stop;
      end;

      memcount = dnum(fid);
      do f = 1 to memcount;
        memname = dread(fid, f);
        * Save only full file names, not directories (if present);
        if first(reverse(trim(memname))) ne '/' then do;
          if f = 1 then do;
            call symput('st_name', substr(memname, 7, 2));
          end;
          output;
        end;
      end;
      rc = dclose(fid);
    run;

    %PUT NOTE: Processsing &ST_NAME.;

    * Read geography file for state;
    %read_geography_file(&ST_NAME., incl_bg=&INCL_BG.);

    * Gather only the necessary segment files references;
    * For given state, loop through segments to create list of segments for iteration.;
    proc sql noprint;
      select segfile into: segname1- from tables_looked_up;
      %LET segcount = &SQLOBS.;
    quit;
    %DO s = 1 %TO &SEGCOUNT.;
      %read_segment_file(&ST_NAME., &&SEGNAME&S.);
    %END;

    * Combine segment files for this state;
    data temp_seg.acs_all_&ST_NAME.;
      merge temp_seg.acs_geo_seg_&ST_NAME.:;
      * possible i should merge by logrecno state county tract blockgp;
      by state logrecno;
    run;

  %END;

  filename inzip clear;

  * Clean up temp files;
  proc datasets lib=work nodetails nolist;
    delete _contents:;
    delete _zipfiles;
  run;
  * Clean up individual segment files;
  *proc datasets lib=temp_seg nodetails nolist;
  * delete *******;
  *run;

%mend;
