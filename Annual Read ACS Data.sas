/**************************************************
	Christopher Mack
	2019.06.04

	Download, unpack and read the American Community Survey data.
	N.b., this program requires a large amount of space in the work directory.

	Download three files first.
	From https://www2.census.gov/programs-surveys/acs/summary_file/2017/data/5_year_entire_sf/
		1. 2017_ACS_Geography_Files.zip
		2. Tracts_Block_Groups_Only.tar (download this one overnight)
				* https://www2.census.gov/programs-surveys/acs/summary_file/2017/documentation/user_tools/
				* untar it (it'll go into /Tracts_Block_Groups_only) before continuing
		3. ACS_5yr_Seq_Table_Number_Lookup.sas7bdat
	All 3 must be in the download directory specified below (&CODEHOME./download).
	Double check and alter "* Names of downloaded ACS files" section below if downloaded file names have changed.;

	The new ACS data has a different file hierarchy:
		* Tracts_Block_Groups_Only.tar is the base. When untarred, you get
		* Tracts_Block_Groups_Only\, a folder with a zip folder for each state or state analogue
				  Alabama_Tracts_Block_Groups_Only.zip
					...
					Wyoming_Tracts_Block_Groups_Only.zip
		* {State}_Tracts_Block_Groups_Only.zip contains the whole suite of segments
				* g20175al.txt - geography file
				* e20175al{0000000}.txt - point estimates for segment {0000000}
				* m20175al{0000000}.txt - margins of error for segment {0000000}

	Outstanding issues:
		1. MGR_Female and MGR_Male include "Professional, scientific, and technical services."
			 Unclear if they should be included.
			 Also note that these are %s of total population; not, e.g., % of males or females in management;

****************************************************/

/* EDIT SECTION */

* Any logon scripts & credentials;
%*include "\\HOME\mackcd1\Documents\Systems\sasntlogon.sas";
%*include "&GHRIDW_ROOT.\remote\RemoteStart.sas";
%*make_spm_comment(Process ACS Census data);
* options mprint;
options formchar='|-++++++++++=|-/|<>*' errorabend;

* Base directory;
%LET codehome = \\groups.ghc.org\data\CTRHS\VDW_SDOH\PROGRAMMING\Programs\VDWCensus;

* If set to prod, program will drop underlying ACS variables & clean up temp directories.
* Otherwise will save interim variables for QA purposes.;
%LET env = dev;

* Pull in StdVars;
%include "&GHRIDW_ROOT.\sasdata\CRN_VDW\lib\StdVars.sas";

* Names of downloaded ACS files:;
* ACS file year.;
%LET fileyear = 2017;
* Release-dependent identifier for source file names. Check the unpacked files for proper reference.;
%LET acs_file_num = 20175;
* File & folder names from downloaded ACS data;
%LET acs_geo_name = &FILEYEAR._ACS_Geography_Files.zip;
%LET acs_tract_block_name = Tracts_Block_Groups_Only;

* Map segment file data to labels (& use for input statement).;
* Used to be called SequenceNumberTableNumberLookup;
%LET seq_ref_table = ACS_5yr_Seq_Table_Number_Lookup;

* Decide whether to retain block group data (not needed for VDW);
%LET incl_bg = true;

/* END EDIT SECTION */

* Set dev v. production settings depending on ENV variable above.;
%include "&CODEHOME.\lib\environment.sas";
%set_environment(&ENV.);

* Location of downloaded ACS files.;
libname dload "&CODEHOME.\download";
%LET zipgeo = &CODEHOME.\download\&ACS_GEO_NAME.;
%LET zipsegdir = &CODEHOME.\download\&ACS_TRACT_BLOCK_NAME.;

* Set temp directories for unpacked geography & segment files.;
%LET temp_dir = &CODEHOME.\temp;
libname temp "&TEMP_DIR.";
libname temp_geo "&TEMP_DIR.\acs_geo_output";
libname temp_seg "&TEMP_DIR.\acs_seg_output";

libname output "&CODEHOME.\output";

* Read ACS metadata to allow processing of source data files.;
%include "&CODEHOME.\lib\define_acs_tables.sas";

* Macros to read geography & segment files from ACS.;
%include "&CODEHOME.\lib\read_geography_file.sas";
%include "&CODEHOME.\lib\read_segment_file.sas";

* Macro to loop over zipped folders by state.
* Calls %read_geography_file & %read_segment_file for each.;
%include "&CODEHOME.\lib\loop_state_folders.sas";
%loop_state_folders(incl_bg=&INCL_BG.);

* Final ETL - transform ACS variables into VDW Census Demog variables.;
%include "&CODEHOME.\lib\acs_to_vdw.sas";

title "ACS Records by State";
title2 "Quick common sense check of counts";
proc freq data=output.census_demog;
	tables state;
run;

* QA to look for extreme values (proportions < 0 or > 1). Detailed QA is a separate process.;
* N.b., it is not quick - this takes much longer than the actual ETL.;
%include "&CODEHOME.\lib\out_of_bounds_qa.sas";

* Clear out temp directories if running in prod mode.;
%&CLEAN_TEMP_DIRS.();

* Signoff;
* endrsubmit;
* signoff;