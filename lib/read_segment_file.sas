* Given state, seg # & full link to segment file in zip archive, read related segments.;
%MACRO read_segment_file(state_abbr, segfile);
  %PUT NOTE: Reading ACS Segment &SEGFILE. for &STATE_ABBR.;

  * Generate the input & label statements for the segment.;
  proc sql noprint;
    create table selected_infile_lines as (
      select tblid, order, tranwrd(title, "'", "''") as label from dload.ACS_5yr_Seq_Table_Number_Lookup
      where seq = "&SEGFILE." and not(missing(order)) and order = int(order)
    );
    create table selected_title_lines as (
      select tblid, tranwrd(title, "'", "''") as label_prefix from dload.ACS_5yr_Seq_Table_Number_Lookup
      where seq = "&SEGFILE." and not(missing(position))
    );
    select  cats(I.tblid, put(order, z3.)) as acsinput length=256,
            cats(I.tblid, put(order, z3.), "='", label_prefix, ": ", compress(substrn(label, 1, 255)), "'") as acslabel length=300      into  :input_list separated by " ",
            :label_list separated by " "
      from selected_infile_lines I, selected_title_lines T
      where I.tblid = T.tblid;
  quit;

  * Getting 100s of Gs of this repeated message:
    NOTE: Truncation has occurred on the source line.
    Turning notes off temporarily to create a manageable log file.;
  options nonotes;

  data acs_seg_&STATE_ABBR._&SEGFILE.;
    infile inzip(e&ACS_FILE_NUM.&STATE_ABBR.&SEGFILE.000.txt) truncover dsd delimiter="," lrecl=3000;
    length fileid filetype $6. stusab state $2. chariter $3. sequence $4. logrecno $7.;
    input fileid filetype stusab chariter sequence logrecno &INPUT_LIST.;
    state = put(stfips(stusab), z2.);
    drop fileid filetype stusab chariter sequence;
    label &LABEL_LIST.;
  run;
  options notes;

  proc sort data=acs_seg_&STATE_ABBR._&SEGFILE.; by state logrecno; run;

  data temp_seg.acs_geo_seg_&STATE_ABBR._&SEGFILE. geo_only segno_only;
    merge temp_geo.acs_geo_&STATE_ABBR.(in=g) acs_seg_&STATE_ABBR._&SEGFILE.(in=s);
    by state logrecno;
    if g and s then output temp_seg.acs_geo_seg_&STATE_ABBR._&SEGFILE.;
      else if g then output geo_only;
      else if s then output segno_only;
  run;

  * Verify the merge;
  proc sql noprint;
    select nobs into :geoobs from dictionary.tables
      where libname = 'WORK' and memname = 'GEO_ONLY';
    select nobs into :segobs from dictionary.tables
      where libname = 'WORK' and memname = 'SEGNO_ONLY';
  quit;
  %IF %EVAL(&GEOOBS.) > 0 %THEN %DO;
    %PUT WARNING: Geography units not matching segment data for Segment &SEGFILE. in State &STATE_ABBR.;
  %END;
  %IF %EVAL(&SEGOBS.) > 0 %THEN %DO;
    %PUT WARNING: Segment units not matching geography data for Segment &SEGFILE. in State &STATE_ABBR.;
  %END;

  * Delete the current segment file to conserve disk space;
  proc datasets library=work;
    delete acs_seg_&STATE_ABBR._&SEGFILE.;
  run;

%mend;
