/**********************************************************************************
Fernando Gutierrez
MIS500
Module 8
Portfolio comments:
I needed to alter the original code in this example 
https://github.com/HHS-AHRQ/MEPS/blob/master/SAS/exercise_3a/Exercise3a.sas

I had to change the location of the data files so that the program could work correctly
*************************************************************************************


DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO IDENTIFY PERSONS WITH A CONDITION AND
              CALCULATE ESTIMATES ON USE AND EXPENDITURES FOR PERSONS WITH THE CONDITION
              THE CONDITION USED IN THIS EXERCISE IS DIABETES (CCS CODE=049 OR 050)

*********************************************************************************/;
********************START IMPORTING DATA FILES***********************************;
/* I created the following code to import the data files;
   Data files were H180 and H181;
   I had to create a folder on my folder shortcuts and insert the files from the website
   https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
   This section access the data in h180.ssp and gets it into the temporary library
   WORK so it can be accessed during the execution of the script.
*/;
FILENAME in_h180 '/folders/myshortcuts/DATA/h180.ssp';
proc xcopy in = in_h180 out = WORK IMPORT;
run;

LIBNAME sasdata '/folders/myfolders/SASDATA';

data sasdata.h180;
  set WORK.h180;
run;

FILENAME in_h181 '/folders/myshortcuts/DATA/h181.ssp';
proc xcopy in = in_h181 out = WORK IMPORT;
run;

LIBNAME sasdata '/folders/myfolders/SASDATA';

data sasdata.h181;
  set WORK.h181;
run;
*************END IMPORTING DATA FILES***********************;

/************************************************************
 The following section creates the output files where the results will
 be stored. The LS refers to the line size and the PS to the page size.
 NODATE indicates that the date will not appear on top of the page as that's
 the default.
 The FORMCHAR is used to guarantee that the page is going to rendered
 properly regardless of the computer used.
 */

OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "/folders/myfolders/SASDATA/Exercise4_log.TXT";
FILENAME MYPRINT "/folders/myfolders/SASDATA/Exercise4_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

/**********************************************************************
 This section creates the title heading that will appear on the page with the results
 The FORMAT keyword assigns a value to each of the numbers (in this case TOTAL, MALE, FEMALE)
 VALUE refers to the variables that appear on the results.
*/

TITLE1 '2018 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 'EXERCISE3.SAS: CALCULATE ESTIMATES ON USE AND EXPENDITURES FOR PERSONS WITH A CONDITION (DIABETES)';


PROC FORMAT;
  VALUE SEX
     . = 'TOTAL'
     1 = 'MALE'
     2 = 'FEMALE'
       ;

  VALUE YESNO
     . = 'TOTAL'
     1 = 'YES'
     2 = 'NO'
       ;
RUN;

*******************************************************************************;

/*	The variable CCCODEX contains codes for different type of health conditions.
	Since we are extracting only the data for those who have diabetes, only observations
	with codes "049" and "050" are extracted for this datafile.
	The data is taken from WORK.H180 and the datafile created is called DIAB
	but only for observations with a value 049 and 050 in the variable CCCODEX
	Then a title is created and frequency distributions are calculated for datafile DIAB
*/

DATA DIAB;
 SET WORK.H180;
    IF CCCODEX IN ('049', '050');
RUN;

TITLE3 "CHECK CCS CODES FOR DIABETIC CONDITIONS";
PROC FREQ DATA=DIAB;
  TABLES CCCODEX / LIST MISSING;
RUN;
********************************************************************;



/* 	A new datafile--DIABPERS--is created under the temporary library that
	extracts information only for those who have diabetes. This datafile 
	contains only 1 column (DUPERSID) and it is sorted by smallest to largest
	(dupersid is a number). NODUPKEY deletes any duplicates in DUPERSID
*/

PROC SORT DATA=DIAB OUT=DIABPERS (KEEP=DUPERSID) NODUPKEY;
  BY DUPERSID;
RUN;
****************************************************************************;


/* 	In this section we use the previously created DIABPERS to merge with the data
	in file H181. 
	BY DUPERSID is the match merging being used, this is, those 2 tables contain
	a variable called DUPERSID and the value is the same in both records. Similar to
	a one-to-one relationship.
	To only select those from H181 who have diabetes you use IN = DATA SET OPTION 
	If the DUPERSID from DIABPERS is not found in H181, that person does not have 
	diabetes. Remember that only the observations stored in DIABPERS include the DUPERSID
	numbers of those suffering that health condition.
*/

DATA  FY1;
MERGE WORK.H181 (IN=AA)
      DIABPERS   (IN=BB) ;
   BY DUPERSID;

      LABEL DIABPERS='PERSONS WHO REPORTED DIABETES';
      IF AA AND BB THEN DIABPERS = 1;
                   ELSE DIABPERS = 2;

RUN;
*****************************************************************************;
/* Two tables are created at this point. 
	One with the percentage of people who reported diabetes.
	Two with the percentage of people by gender.
*/
TITLE3 "Supporting crosstabs for the flag variables";
TITLE3 "UNWEIGHTED # OF PERSONS WHO REPORTED DIABETES, 2015";
PROC FREQ DATA=FY1;
  TABLES DIABPERS
         DIABPERS * SEX / LIST MISSING;
  FORMAT SEX      sex.
         DIABPERS yesno.
    ;
RUN;
/* Two tables are created at this point. Same as previous but this time weighted (PERWT15F)
	One with the percentage of people who reported diabetes.
	Two with the percentage of people by gender.
*/
TITLE3 "WEIGHTED # OF PERSONS WHO REPORTED DIABETES, 2015";
PROC FREQ DATA=FY1;
  TABLES DIABPERS
         DIABPERS * SEX /LIST MISSING;
  WEIGHT PERWT15F ;
  FORMAT SEX      sex.
         DIABPERS yesno.
    ;
RUN;


/* 	The final tables refer to the expenditures for people with diabetes.
	Graphics are set to OFF and listing to close to save resources.
	Procedure SURVEYMEANS is used to get different statistics like 
	number of observations (NOBS), sum of the weights (SUMWGT), sum total (SUM),
	standard deviation (STD), mean (MEAN), and standard error of the mean (STDERR).
	Data is stored in a location under the termporary folder "WORK"*/
ODS GRAPHICS OFF;
ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FY1 NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT PERWT15F ;
	DOMAIN DIABPERS('1') SEX*DIABPERS('1');
	VAR TOTEXP15 TOTSLF15 OBTOTV15;
      ods output domain=work.domain_results;
RUN;
ODS LISTING;
TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR PERSONS WHO REPORTED DIABETES, 2015";
PROC PRINT DATA=work.domain_results (DROP=DOMAINLABEL)  NOOBS LABEL BLANKLINE=3 ;
VAR SEX VARNAME N SUMWGT SUM STDDEV MEAN STDERR;
FORMAT N                      comma6.0
       SUMWGT   SUM    STDDEV comma17.0
       MEAN     STDERR        comma9.2
       DIABPERS               yesno.
       SEX                    sex.
   ;
RUN;

PROC PRINTTO;
RUN;