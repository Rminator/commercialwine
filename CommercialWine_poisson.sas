libname mydata "/sscc/home/n/ngg135/assignment3/" access=readonly;

proc datasets library=mydata; 
run;
quit;

data training;
set mydata.wine;

proc contents data=training;
run;

proc means data=training ; 
run;

proc print data=training (obs=10);
run;

proc means nmiss data=training;
run;

proc means data=training NMISS N; 
run;

proc corr data=training;
with target;
run;


proc univariate data=training;
histogram TARGET /normal;
run;

proc univariate data=training;
histogram acidindex /normal;
run;

proc univariate data=training;
histogram Alcohol /normal;
run;

proc univariate data=training;
histogram Density /normal;
run;


proc univariate data=training;
histogram ResidualSugar /normal;
run;



proc univariate data=training;
    var acidindex alcohol chlorides citricacid density fixedacidity freesulfurdioxide labelappeal residualsugar stars sulphates totalsulfurdioxide volatileacidity ph;
    histogram;
    
data imp_training;
    set training;

    imp_alcohol = alcohol;
    i_imp_alcohol = 0;
    if missing(imp_alcohol) then do;
        imp_alcohol = 10.4892363;
        i_imp_alcohol = 1;
    end;

    imp_chlorides = chlorides;
    i_imp_chlorides = 0;
    if missing(imp_chlorides) then do;
        imp_chlorides = 0.0548225;
        i_imp_chlorides = 1;
    end;

    imp_freesulfurdioxide = freesulfurdioxide;
    i_imp_freesulfurdioxide = 0;
    if missing(imp_freesulfurdioxide) then do;
        imp_freesulfurdioxide = 30.8455713;
        i_imp_freesulfurdioxide = 1;
    end;

    imp_residualsugar = residualsugar;
    i_imp_residualsugar = 0;
    if missing(imp_residualsugar) then do;
        imp_residualsugar = 5.4187331;
        i_imp_residualsugar = 1;
    end;

    imp_stars = stars;
    i_imp_stars = 0;
    if missing(imp_stars) then do;
        imp_stars = 2.0;
        i_imp_stars = 1;
    end;

    imp_sulphates = sulphates;
    i_imp_sulphates = 0;
    if missing(imp_sulphates) then do;
        imp_sulphates = 0.5271118;
        i_imp_sulphates = 1;
    end;

    imp_totalsulfurdioxide = totalsulfurdioxide;
    i_imp_totalsulfurdioxide = 0;
    if missing(imp_totalsulfurdioxide) then do;
        imp_totalsulfurdioxide = 120.7142326;
       i_imp_totalsulfurdioxide = 1;
    end;

    imp_ph = ph;
    i_imp_ph = 0;
    if missing(imp_ph) then do;
        imp_ph = 3.2076282;
        i_imp_ph = 1;
    end;


proc univariate data=IMP_training;
histogram IMP_STARS /normal;
run;

proc univariate data=IMP_training;
histogram IMP_PH /normal;
run;

proc corr data=imp_training;
with target;
run;

*///Model Poisson///;

proc genmod data=imp_training;
    class labelappeal imp_stars i_imp_stars;
    model target = acidindex labelappeal imp_stars i_imp_stars / link=log dist=poi;
    output out=imp_training p=pr1;
    
    *///Negative Binomial///;
    
proc genmod data=imp_training;
   class labelappeal imp_stars i_imp_stars;
   model target = acidindex labelappeal imp_stars i_imp_stars / link=log dist=nb;
   output out=imp_training p=nbr1;
   
   *///zero inflared Binomial///;
proc genmod data=imp_training;
    class labelappeal imp_stars i_imp_stars;
    model target = acidindex labelappeal imp_stars i_imp_stars / link=log dist=ZIP;
    zeromodel acidindex i_imp_stars / link=logit;
    output out=imp_training p=zip1;
    
    
    *///zero inflated negative Binomial///;
    
proc genmod data=imp_training;
 class labelappeal imp_stars i_imp_stars;
   model target = acidindex labelappeal imp_stars i_imp_stars / link=log dist=ZINB;
    zeromodel acidindex i_imp_stars / link=logit;
    output out=imp_training p=zinb1 pzero=zzinb1;
    
    
   ods graphics on; 
proc reg data=imp_training;
    model  target = acidindex labelappeal imp_stars i_imp_stars;
    output out=imp_training p=yhat;
    
    *///Negative Binomial///;
    
libname mydata "/sscc/home/n/ngg135/assignment3/" access=readonly;

proc datasets library=mydata; 
run;
quit;

data testing;
set mydata.wine_test;
    

data testing_fixed;
    set testing;

    imp_stars = stars;
    i_imp_stars = 0;
    if missing(imp_stars) then do;
       imp_stars = 2.0;
       i_imp_stars = 1;
    end;



data testing_score;
    set testing_fixed;

    TEMP = -3.3657
    + AcidIndex * 0.4637
    + (i_imp_stars in (0)) * -3.4689;

   P_SCORE_ZERO = exp(TEMP) / (1 + exp(TEMP));

    temp = 1.8705
    + AcidIndex * -0.0214
    + (LabelAppeal in (-2)) * -0.9704
    + (LabelAppeal in (-1)) * -0.6029
    + (LabelAppeal in (0)) * -0.3409
    + (LabelAppeal in (1)) * -0.1574
    + (imp_stars in (1)) * -0.4068
   + (imp_stars in (2)) * -0.1999
    + (imp_stars in (3)) * -0.1046
    + (i_imp_stars in (0)) * 0.1854;

P_SCORE_ZIP_ALL = exp(TEMP);

P_TARGET = P_SCORE_ZIP_ALL * (1 - P_SCORE_ZERO);

keep index P_TARGET ;

data home.Wine_final_prediction_score;
 set testing_score;
 run;
 



