PROC SORT DATA = UTD.tgif;  BY customer_number; RUN;


proc means data = UTD.tgif;
run;



proc standard data=UTD.tgif mean=0 std=1 out=UTD.Allstandard;

run;





proc reg data = UTD.tgif;
model net_sales_tot = email_open_rate rest_loc_bar  rest_loc_Rest time_dinner points_ratio
time_late_nite
time_lunch
disc_pct_tot
disc_pct_trans
items_tot_distinct
net_amt_p_item
days_between_trans
guests_last_12mo;
output out = resid p = PUNITS r = RUNITS student = student;
run;quit;


data UTD.tgifRemoveOutliers;
set resid;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

** try these columns;
data UTD.tgif2 ;
SET UTD.tgifRemoveOutliers;
KEEP points_ratio
age
email_open_rate
email_click_rate
email_forward_rate
rest_loc_bar
rest_loc_Rest
rest_loc_rm_serv
rest_loc_Take_out
time_breakfast
time_dinner
time_late_nite
time_lunch
disc_app
disc_beverage
disc_dessert
disc_food
disc_other
disc_ribs
disc_sandwich
disc_ticket
disc_type_bogo
disc_type_dolfood
disc_type_free
disc_type_other
disc_type_pctfood
disc_chan_gmms
disc_chan_gps
disc_chan_other
disc_chan_value
disc_pct_tot
disc_pct_trans
items_tot_distinct
items_tot
net_amt_p_item
checks_tot
net_sales_p_chck
net_sales_tot
fd_cat_alcoh
fd_cat_app
fd_cat_bev
fd_cat_brunc
fd_cat_burg
fd_cat_dess
fd_cat_h_ent
fd_cat_kids
fd_cat_l_ent
fd_cat_other
fd_cat_side
fd_cat_soupsal
fd_cat_steak
days_between_trans
customer_number
;

run;


** steps: standard -- kmeans -- discrim *;

proc standard data=UTD.tgif2 mean=0 std=1 out=UTD.standard;
var
points_ratio
age
email_open_rate
email_click_rate
email_forward_rate
rest_loc_bar
rest_loc_Rest
rest_loc_rm_serv
rest_loc_Take_out
time_breakfast
time_dinner
time_late_nite
disc_food
time_lunch
disc_app
disc_beverage
disc_dessert
disc_other
disc_ribs
disc_sandwich
disc_ticket
disc_type_bogo
disc_type_dolfood
disc_type_free
disc_type_other
disc_type_pctfood
disc_chan_gmms
disc_chan_gps
disc_chan_other
disc_chan_value
disc_pct_tot
disc_pct_trans
items_tot_distinct
items_tot
net_amt_p_item
checks_tot
net_sales_p_chck
net_sales_tot
fd_cat_alcoh
fd_cat_app
fd_cat_bev
fd_cat_brunc
fd_cat_burg
fd_cat_dess
fd_cat_h_ent
fd_cat_kids
fd_cat_l_ent
fd_cat_other
fd_cat_side
fd_cat_soupsal
fd_cat_steak
days_between_trans
;

run;



* run 100 clusters to remove unusual customers *;

proc fastclus data = UTD.standard 
maxclusters = 100 out = UTD.clus_100 (keep = customer_number cluster) outseed=utd.seed2;
var
email_open_rate	rest_loc_bar
rest_loc_Rest	time_dinner	time_late_nite	time_lunch	disc_pct_tot	
disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
checks_tot	net_sales_p_chck	net_sales_tot	days_between_trans	
age	fd_cat_alcoh	fd_cat_app	
fd_cat_bev	fd_cat_burg	fd_cat_h_ent	fd_cat_dess	fd_cat_kids	fd_cat_steak;


run;

data utd.seed_final2;
	set utd.seed2;
	if _freq_>50;
run;

 proc fastclus data=utd.standard seed=utd.seed_final2 maxc=6  out=utd.out (keep = customer_number cluster);
      var email_open_rate	rest_loc_bar
	rest_loc_Rest	time_dinner	time_late_nite	time_lunch	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	checks_tot	net_sales_p_chck	net_sales_tot	days_between_trans	
	age	fd_cat_alcoh	fd_cat_app	
	fd_cat_bev	fd_cat_burg	fd_cat_h_ent	fd_cat_dess	fd_cat_kids	fd_cat_steak;
   run;

PROC SORT DATA = utd.out;  BY customer_number; RUN;

PROC SORT DATA = utd.tgif;  BY customer_number; RUN;


DATA utd.NEW(KEEP = customer_number cluster); 
SET utd.out;
RUN;

DATA utd.mergedtgif;
MERGE utd.TGIF utd.new;
BY CUSTOMER_NUMBER; RUN;

PROC SORT DATA = utd.mergedtgif; BY cluster; RUN;

DATA utd.cluster1;
SET utd.MERGEDTGIF;
WHERE CLUSTER=1;RUN;

DATA utd.cluster2;
SET utd.MERGEDTGIF;
WHERE CLUSTER=2;RUN;

DATA utd.cluster3;
SET utd.MERGEDTGIF;
WHERE CLUSTER=3;RUN;

DATA utd.cluster4;
SET utd.MERGEDTGIF;
WHERE CLUSTER=4;RUN;

DATA utd.cluster5;
SET utd.MERGEDTGIF;
WHERE CLUSTER=5;RUN;

DATA utd.cluster6;
SET utd.MERGEDTGIF;
WHERE CLUSTER=6;RUN;

proc reg data = utd.cluster1;
model net_sales_p_chck = disc_pct_tot	
disc_pct_trans	items_tot	net_amt_p_item	days_between_trans
age checks_tot net_sales_tot/VIF COLLIN;
output out = utd.resid1 p = PUNITS r = RUNITS student = student;
run;


proc reg data = utd.cluster2;
model net_sales_p_chck = email_open_rate	rest_loc_bar
	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	days_between_trans	
	age	fd_cat_alcoh	
	fd_cat_bev	checks_tot net_sales_tot/VIF COLLIN;
output out = utd.resid2 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster3;
model net_sales_p_chck = email_open_rate	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	net_amt_p_item	
	fd_cat_alcoh	fd_cat_app	checks_tot net_sales_tot
	fd_cat_bev	fd_cat_kids	fd_cat_steak/ VIF COLLIN;
output out = utd.resid3 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster4;
model net_sales_p_chck = time_dinner	time_lunch	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	days_between_trans	checks_tot net_sales_tot
	age	fd_cat_alcoh	fd_cat_app	
	fd_cat_bev	fd_cat_burg	fd_cat_kids/VIF COLLIN;
output out = utd.resid4 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster5;
model net_sales_p_chck = email_open_rate
	rest_loc_Rest	time_late_nite	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	days_between_trans	checks_tot net_sales_tot
	age	fd_cat_alcoh	fd_cat_app	
	fd_cat_bev	fd_cat_h_ent	fd_cat_kids	fd_cat_steak/VIF COLLIN;
output out = utd.resid5 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster6;
model net_sales_p_chck = email_open_rate	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	days_between_trans	
	fd_cat_alcoh	checks_tot net_sales_tot
	fd_cat_bev	fd_cat_h_ent	fd_cat_dess	fd_cat_kids/VIF COLLIN;
output out = utd.resid6 p = PUNITS r = RUNITS student = student;
run;

data utd.cluster11;
set utd.resid1;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

data utd.cluster12;
set utd.resid2;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

data utd.cluster13;
set utd.resid3;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

data utd.cluster14;
set utd.resid4;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

data utd.cluster15;
set utd.resid5;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

data utd.cluster16;
set utd.resid6;
if student > 3.00 then delete;
if student < -3.00 then delete;
run;

proc reg data = utd.cluster11;
model net_sales_p_chck = disc_pct_tot	
disc_pct_trans	items_tot	net_amt_p_item	days_between_trans
checks_tot net_sales_tot/VIF COLLIN;
output out = utd.resid1 p = PUNITS r = RUNITS student = student;
run;


proc reg data = utd.cluster12;
model net_sales_p_chck =	rest_loc_bar	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	days_between_trans	
	fd_cat_alcoh	
	fd_cat_bev	checks_tot net_sales_tot/VIF COLLIN;
output out = utd.resid2 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster13;
model net_sales_p_chck = email_open_rate	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	net_amt_p_item	
	fd_cat_alcoh	fd_cat_app	checks_tot net_sales_tot
	fd_cat_bev	fd_cat_kids	fd_cat_steak/ VIF COLLIN;
output out = utd.resid3 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster14;
model net_sales_p_chck = time_dinner	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	days_between_trans	checks_tot net_sales_tot
	fd_cat_alcoh	fd_cat_app	
	fd_cat_bev	fd_cat_burg	fd_cat_kids/VIF COLLIN;
output out = utd.resid4 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster15;
model net_sales_p_chck = email_open_rate
	rest_loc_Rest	time_late_nite	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	days_between_trans	checks_tot net_sales_tot
	fd_cat_alcoh	fd_cat_app	
	fd_cat_bev	fd_cat_h_ent	fd_cat_kids	fd_cat_steak/VIF COLLIN;
output out = utd.resid5 p = PUNITS r = RUNITS student = student;
run;

proc reg data = utd.cluster16;
model net_sales_p_chck = email_open_rate	disc_pct_tot	
	disc_pct_trans	items_tot_distinct	items_tot	net_amt_p_item	
	days_between_trans	checks_tot net_sales_tot
	fd_cat_alcoh	
	fd_cat_bev	fd_cat_h_ent	fd_cat_dess	fd_cat_kids/VIF COLLIN;
output out = utd.resid6 p = PUNITS r = RUNITS student = student;
run;

proc means data=utd.mergedtgif; by cluster; run;

proc means data=utd.mergedtgif; run;
