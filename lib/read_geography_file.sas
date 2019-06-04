/*******************************************
  Process ACS geography file for specific state.
  &INCL_BG. is the include-block-group flag.  By default, block group data isn't processed.

  Rob Penfold had hoped to bring in ur (urban-rural flag).
  That doesn't appear to obtain in the tract/block group data.
********************************************/

%macro read_geography_file(state_abbr, incl_bg=false);

  %PUT NOTE: Reading geography file for &STATE_ABBR.;

  data temp_geo.acs_geo_&STATE_ABBR.;
    infile inzip(g&ACS_FILE_NUM.&STATE_ABBR..csv) missover dsd lrecl=500;
    length geolevel fileid $6. stusab $2. sumlevel $3. component $2. logrecno $7. us region division $1.
      statece state $2. county $3. cousub $5. place $5. tract $6. blockgp $1.
      concit $5. aianhh $4. aianhhfp $5. aihhtli $1. aitsce $3. aits $5. anrc $5. cbsa $5.
      csa $3. metdiv $5. macc $1. memi $1. necta $5. cnecta $3. nectadiv $5.
      ua $5. blank1 $1. cdcurr $2. sldu $3. sldl $3. blank2 blank3 $1. zcta5 $5.
      submcd $5. sdelm $5. sdsec $5. sduni $5. ur $1. pci $1. blank4 $1. blank5 $1.
      puma5 $5. blank6 $1. geoid $20. name $200. bttr $1. btbg $1. blank7 $1.;
    input fileid stusab sumlevel component logrecno us region division
      statece state county cousub place tract blockgp
      concit aianhh aianhhfp aihhtli aitsce aits anrc cbsa csa metdiv macc memi necta cnecta nectadiv
      ua blank1 cdcurr sldu sldl blank2 blank3 zcta5 submcd sdelm sdsec sduni ur pci blank4 blank5
      puma5 blank6 geoid name bttr btbg blank7;
    if sumlevel in ('140', '150') then do;
      if sumlevel = '140' then geolevel = "Tract";
      else if sumlevel = '150' then geolevel = "BlkGrp";
      output;
    end;
    keep logrecno state county tract;
    %IF &INCL_BG. = true %THEN %DO;
      keep blockgp;
    %END;
    %ELSE %DO;
      if not(missing(blockgp)) then delete;
    %END;
  run;

  proc sort data=temp_geo.acs_geo_&STATE_ABBR.; by state logrecno; run;

%mend;
