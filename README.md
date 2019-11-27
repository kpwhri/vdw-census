# HCSRN VDW Census

SAS programs to download and create files to the [HCSRN](http://www.hcsrn.org) VDW Census Demographics specifications.

Full specifications can be found in the [HCSRN document library](https://www.hcsrn.org/share/page/site/VDW/documentlibrary#filter=path%7C%2Fdata_documentation%2Fdata_specifications_and_guidelines%2FVDW%2520Specifications%7C&amp;amp;page=1).

Original build by Christopher Mack at KPWHRI with extensive work by David Tabano, formerly at KPCO.
Still more work to update to the new 2017 ACS file releases.

Please feel free to make a pull request to offer improvements!

---

## Full instructions can be found in Annual Read ACS Data.sas

This suite of programs downloads, unpacks and reads the American Community Survey data
and offers a QA package for testing selected blocks of variables using the ACS Web API.

N.b., this program requires a large amount of space in the work directory.

1. Start by downloading the data from the ACS website from
https://www2.census.gov/programs-surveys/acs/summary_file/2017/data/5_year_entire_sf/

   Three files:
  - 2017_ACS_Geography_Files.zip
  - Tracts_Block_Groups_Only.tar (download this one overnight)
    - https://www2.census.gov/programs-surveys/acs/summary_file/2017/documentation/user_tools/
    - untar it (it'll go into /Tracts_Block_Groups_only) before continuing
  - ACS_5yr_Seq_Table_Number_Lookup.sas7bdat
    - https://www2.census.gov/programs-surveys/acs/summary_file/2017/documentation/user_tools/

2. Copy all 3 to the download directory specified (&CODEHOME./download).
3. Double check and alter the *"* Names of downloaded ACS files"* section if downloaded file names have changed.

The 2017 ACS data has a new file hierarchy:
  - Tracts_Block_Groups_Only.tar is the base. When untarred, you get
  - Tracts_Block_Groups_Only\, a folder with a zip folder for each state or state analogue  
       Alabama_Tracts_Block_Groups_Only.zip  
          \...  
       Wyoming_Tracts_Block_Groups_Only.zip  
  - {StateAbbr}_Tracts_Block_Groups_Only.zip contains the whole suite of segments
    - g20175al.txt - geography file
    - e20175al{0000000}.txt - point estimates for segment {0000000}
    - m20175al{0000000}.txt - margins of error for segment {0000000}  
    ... We're not currently using the margins of error. But we probably should.
