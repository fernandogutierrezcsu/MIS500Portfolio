DATA work.expense;
 set work.FY1 (keep = TOTEXP15 DUPERSID DIABPERS);
 diabetic = (DIABPERS EQ 1);
RUN;

Proc TTest data= work.expense side =l;
 Class diabetic;
 var TOTEXP15;
RUN;