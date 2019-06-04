* Find the files that need to be uncompressed by looking up the required tables in ACS_5yr_Seq_Table_Number_Lookup.;
* Enter the tables being used in the datalines below.;
* N.b., there are a few tables that span multiple segments.  That is why the multilabel option (hlo 'M') is enabled.;
* (Hint: It appears the first 5 characters of the ACS field number identify the table.);

* Set up the list of ACS Tables we will be drawing from.;

data tables;
  length table $7.;
  input table $ @@;
  datalines;
B01001 B01001A B01001B B01001C B01001D B01001E B01001F B01001G B01001H B01001I
B05001 B07001 B08201 B12001 B15002 B16007 B17001 B17026 B18101
B19001 B19013 B19057 B19101 B19113 B23001 B25014 B25026 B25077 B25091 B25115
C24040 C27006 C27007
;
run;

proc sort data=dload.&SEQ_REF_TABLE.(keep=tblid seq) nodupkey
  out = SequenceNumberTableNumberLookup;
  by seq tblid;
run;

data fmt;
  set SequenceNumberTableNumberLookup;
  retain fmtname '$TableLookup' type 'c' hlo 'M';
  rename tblid=start seq=label;
run;

proc format cntlin=fmt;
run;

data tables_looked_up;
  set tables;
  segfile = put(table, $TableLookup.);
  if anyalpha(segfile) then do;
    put "WARNING: Sequence Lookup Error:";
    put "WARNING:  Table " table " did not have a sequence number.";
    put "WARNING:  No file will be downloaded.";
  end;
  else output;
run;

proc sort data=tables_looked_up(keep=segfile) nodupkey; by segfile; run;

* Can use this dataset to verify that we have all the fields we need;
proc sql;
  create table sequence_check as
    select *
    from dload.&SEQ_REF_TABLE.
    where tblid in (select distinct table from tables)
  ;
quit;

* data temp.sequence_check;
*   set sequence_check;
* run;
