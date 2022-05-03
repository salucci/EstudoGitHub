/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: segunda-feira, 27 de setembro de 2021     TIME: 13:03:45
PROJECT: Quadros
PROJECT PATH: \\ibge.gov.br\gtd\Gerência de Apoio Computacional\Censo 2010\Análises - Caride\Sigc2022\Quadros.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=SVG;
GOPTIONS XPIXELS=0 YPIXELS=0;
%macro HTML5AccessibleGraphSupported;
    %if %_SAS_VERCOMP(9, 4, 4) >= 0 %then ACCESSIBLE_GRAPH;
%mend;
FILENAME EGHTMLX TEMP;
ODS HTML5(ID=EGHTMLX) FILE=EGHTMLX
    OPTIONS(BITMAP_MODE='INLINE')
    %HTML5AccessibleGraphSupported
    ENCODING='utf-8'
    STYLE=HTMLBlue
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
;

/*   START OF NODE: Program 2   */
%LET _CLIENTTASKLABEL='Program 2';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='\\ibge.gov.br\gtd\Gerência de Apoio Computacional\Censo 2010\Análises - Caride\Sigc2022\Quadros.egp';
%LET _CLIENTPROJECTPATHHOST='CHI00557075';
%LET _CLIENTPROJECTNAME='Quadros.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';


libname CD20EXP odbc noprompt="driver=SQL Server;server=WSQLPRD46V;database=DBCENSO20; trusted_connection=yes;" schema=CD2020P_EXP2; 
run;

%Macro Periodo(per_ini,peri_fim,periodo);

data periodo;
set cd20exp.t_udomicri(keep=b0000 doca0107 B1001 b4004 doca0107 doca0003 B0001 B0002);
where "&per_ini." <= b4004 <= "&peri_fim.";

run;

proc sort data=periodo; by b0000 b4004;
run;

data dia; set periodo; by b0000 b4004;
 if first.b0000 then dif=0;
 if last.b4004 then dif + 1;
 if last.b0000;
 keep b0000 dif;
 run;
/*
data dia; set periodo;retain di;by b0000;
FORMAT Di DDMMYY6. ;
  FORMAT Df DDMMYY6. ;
 if first.b0000 then  
  Di = MDY((substr(b4004,5,2)),(substr(b4004,7,2)),(substr(b4004,3,2))) ;
 if last.b0000 then  
  Df = MDY((substr(b4004,5,2)),(substr(b4004,7,2)),(substr(b4004,3,2))) ; 
  DIF = INTCK('DAY',Di,Df) +1;
if last.b0000;
keep b0000 dif;
* dias=20201113 - 20201106;
run;
*/
data periodo; merge periodo dia; by b0000;
run;
/*
proc means data=work.periodo sum;
var doca0003;
run;

proc freq data=work.periodo; table dias;
run;	
*/

proc sort data=periodo; by b1001 b0001 b0002 b0000 b4004 dif;
run;


proc means data=work.periodo noprint;
by b1001 b0001 b0002 b0000 doca0107 dif;
var doca0003;
output out=br sum=doca0003x;
run;


data br; set br;
doca0003=doca0003x/dif;
run;

PROC univariate DATA=br noprint ; 
 var doca0003 doca0003x dif;
 output out=brasil sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;

PROC univariate DATA=br noprint ; 
 var doca0003 doca0003x dif;
 by b1001;
 output out=gr sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;

PROC univariate DATA=br noprint ; 
 var doca0003 doca0003x dif;
 by b1001 b0001;
 output out=uf sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;

proc sort data=br; by doca0107;
run;

PROC univariate DATA=br noprint ; by doca0107;
 var doca0003 doca0003x dif;
 output out=brasils sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;

proc sort data=br; by b1001 doca0107;
run;

PROC univariate DATA=br noprint ; 
by b1001 doca0107 ;
 var doca0003 doca0003x dif;
 output out=grs sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;

proc sort data=br; by b1001  b0001 doca0107;
run;

PROC univariate DATA=br noprint ; 
by b1001 b0001 doca0107;
 var doca0003 doca0003x dif;
 output out=ufs sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;

data brasil ;set brasil  brasils gr grs uf ufs;
if b1001=. then area= 0; else
if b1001 NE . and b0001 =. then area= b1001; else
area=b0001;

run;

proc sort data=brasil; by area doca0107;  
run;

ods html body="\\ibge.gov.br\gtd\Gerência de Apoio Computacional\Censo 2010\Análises - Caride\Sigc2022\quadro12P&periodo..htm"; run ;
proc print data=brasil label split='*';
var  doca0107 setor total_pessoas  xtotal cvtotal q1total mtotal q3total  
xdia mdia q1dia q3dia;
format area areaf. doca0107 $situf. xdia 6.1 mdia 5. q1dia 5. q3dia 5.
xtotal 6.1 cvtotal 6.1 q1total 6.1 mtotal 6.1 q3total 6.1 total 6.;

id area;
label area="Brasil, Grandes Regiões, UF's "
      doca0107="Situação do domicílio"
	  setor='Total de setores'
  	  total_pessoas='Total de pessoas '
	  xtotal='média diária(1)'
	  cvtotal='C. V.'
	  mtotal='mediana'
      q1total='Q1'
      q3total='Q3'
      xdia = 'Média de dias trabalhados'
      mdia = 'Mediana de dias trabalhados'
      q1dia  = 'Q1 de dias trabalhados'
      q3dia  = 'Q3 de dias trabalhados';
	  TITLE1 Quadro 12 - Setores em andamento com atualização no período, estatísticas básicas;
title2 da produtividade média diária (pessoas entrevistadas por dia) não acumulada,;
title3 segundo a área de investigação e situação do domicílio;
title4 "PERÍODO &periodo.: '&per_ini.' a '&peri_fim.' (Ano-Mês-Dia)";
footnote1 Fonte: IBGE-SIGC-CENSO 2020;
footnote2 (1) A média diária é calculada através da divisão da produção do recencadores no setor dividida pelo total de dias ;
Footnote3     dividida pelo número de dias trabalhados no período.;
RUN;
  ods html close ;     
run; 

proc sort data=br; by b1001  b0001 b0002 doca0107;
run;

PROC univariate DATA=br noprint ; 
by b1001 b0001 b0002 doca0107;
 var doca0003 doca0003x dif;
 output out=Muns sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;


PROC univariate DATA=br noprint ; 
by b1001 b0001 b0002 ;
 var doca0003 doca0003x dif;
 output out=Mun sum= Total total_pessoas T_dia
				cv =    cvtotal  cv_pessoas cv_dia
                mean=   xtotal   xpessoa xdia
				median= mtotal   mpessoa mdia
				q1 = q1total    q1pessoa q1dia
				q3 = q3total    q3pessoa q3dia
                N= setor       Npessoa ndia;
run;
data mun; set mun;   area=(b0001*100000) + b0002;
data muns; set muns; area=(b0001*100000) +b0002;

data br_P&periodo.; set brasil mun muns;

format  xdia 6.1 mdia 5. q1dia 5. q3dia 5.
xtotal 6.1 cvtotal 6.1 q1total 
6.1 mtotal 6.1 q3total 6.1 total 6.;

PERIODO=&PERIODO.;

keep area doca0107 setor total_pessoas xtotal
cvtotal mtotal q1total q3total xdia 
mdia q1dia q3dia b1001 b0001 b0002 PERIODO;
run;


proc export data=br_P&periodo.
     outfile="\\ibge.gov.br\gtd\Gerência de Apoio Computacional\Censo 2010\Análises - Caride\Sigc2022\BR_p&periodo..csv"
     dbms=csv 
     replace;
run;

%mend periodo;


%periodo (20201106,20201112,1);
run;

%periodo (20201113,20201119,2);
run;

%periodo (20201120,20201126,3);
run;

%periodo (20201127,20201203,4);
run;

%periodo (20201204,20201210,5);
run;
/*  filtro dos períodos de execução das tabelas 

06/11 a 12/11  periodo = 1
13/11 a 19/11  periodo = 2
20/11 a 26/11  periodo = 3
27/11 a 03/12  periodo = 4
04/12 a 10/12  periodo = 5

data periodo; set q12; 
*where '20201106' <= b4004 <= '20201112';
run;
*/ 

/*
run;
filename saida "\\ibge.gov.br\gtd\Gerência de Apoio Computacional\Censo 2010\Análises - Caride\Sigc2022\BR_p1.csv";
run;
data _null_; set BR_p1;
FILE SAIDA LRECL=10000 DELIMITER=",";
 put  b1001 b0001 b0002
  area doca0107 setor total_pessoas xtotal
cvtotal mtotal q1total q3total xdia 
mdia q1dia q3dia  ;
run;

proc export data=br_P1
     outfile="\\ibge.gov.br\gtd\Gerência de Apoio Computacional\Censo 2010\Análises - Caride\Sigc2022\BR_p1.csv"
     dbms=csv 
     replace;
run;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
