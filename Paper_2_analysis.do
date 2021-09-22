********************************************************************************
************** Paper 2 -  do-file****

use child_vacc_residence_hdss_final.dta,clear


*Considérer les enfants nés en gambie à partir de l'an 2000

*(1) Sélectionner les enfants nés sous surveillance
sort  concat_IndividualId EventDate EventCode
drop if EventDate < DoB

*Considérer les enfants nés en gambie à partir de l'an 2000
display %20.0f clock("01jan 2000","DMY")

capture drop birth birth_g
gen birth_g = (EventCode==2 & DoB <  1262304000000)

bysort concat_IndividualId (EventDate) : egen double birth_g1=max(birth_g)
drop if birth_g1==1 & hdss=="GM011"
*drop if birth_g1==1
*drop if birth_g1==1 & hdss=="SN011"


sort concat_IndividualId EventDate EventCode 
*drop if EventDate <DoB

forval i=1/20{
sort concat_IndividualId EventDate EventCode 
*Add 1 minute to the vaccine dates to the date of death
replace  EventDate= EventDate + 1*60*1000 if EventDate==EventDate[_n-1]
}

capture drop datebeg
sort concat_IndividualId EventDate EventCode
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc
lab var datebeg "Date of beginning"

count if datebeg>=EventDate


capture drop datebeg
sort IndividualId EventDate EventCode
qui by IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc
lab var datebeg "Date of beginning"

count if datebeg>=EventDate


*Insertion de l'education de la mère
***Niakhar
sort MotherId
merge m:1 MotherId using individual_parents_Niakhar_MO,keep(1 3)keepus(MO_educ ethnie)
drop _merge

capture drop MO_education
gen MO_education = cond(MO_educ==. | MO_educ==-1 | MO_educ==0 | MO_educ==14 | ///
                        MO_educ==15 | MO_educ==16 | MO_educ==17 | MO_educ==18 | ///
						MO_educ==19 | MO_educ==20 | MO_educ==21 | MO_educ==22 | ///
						MO_educ==23 | MO_educ==24 | MO_educ==25 | MO_educ==26 | ///
						MO_educ==27 | MO_educ==28 | MO_educ==29 | MO_educ==30 | ///
						MO_educ==31 | MO_educ==32 | MO_educ==33 | MO_educ==35,0, ///
				   cond(MO_educ==1 | MO_educ==2 | MO_educ==3 | MO_educ==4 | ///
				        MO_educ==5 | MO_educ==6 | MO_educ==36 | MO_educ==37,1, ///
				   cond(MO_educ==7 | MO_educ==8 | MO_educ==9 | MO_educ==10 | ///
				        MO_educ==11 | MO_educ==12 | MO_educ==13 | MO_educ==34 | ///
						MO_educ==38,2,.)))
*Ouagadougou
merge m:1 MotherId using  Ouaga_MO_educ,keep(1 3)keepus(education5 niv_vie  religion ethnic)
drop _merge

ta education5
replace MO_education = 0 if education5==0 | MO_education==9
replace MO_education = 1 if  education5==1
replace MO_education = 2 if education5==2 | education5==3 | education5==4

*Farafenni

merge m:1 MotherId using individual_parents_Farafenni_MO.dta, keep(1 3) keepus(educMO education_yearsMO ethnieMO)
drop _merge
destring education_yearsMO,replace
replace MO_education = 1 if education_yearsMO==1 | education_yearsMO==2 | ///
                            education_yearsMO==3 | education_yearsMO==4 | ///
							education_yearsMO==5 | education_yearsMO==6

replace MO_education=2 if education_yearsMO==7 | education_yearsMO==8 | ///
						  education_yearsMO==11 | education_yearsMO==12 | ///
						  education_yearsMO==13 | education_yearsMO==14 | ///
						  education_yearsMO==15 | education_yearsMO==16 | ///
						  education_yearsMO==17 | education_yearsMO==18 | ///
						  education_yearsMO==19
*Other variables?


**Structures familiales


*1 - Nuclear family - 2-Single parent 3 - Extended family

capture drop typo_1
gen typo_1 = cond(hh_type==.,., ///
             cond(hh_type==10,1, ///
			 cond(hh_type==50,2,3)))

label define ltypo_1 1"Single parent" 2"Two parent family" 3"Extended family", modify
label val typo_1 ltypo_1

*2 Single parent, couple, Three-generation household, Lateraly household, complex household

capture drop typo_2
gen typo_2 = cond(hh_type==.,., ///
             cond(hh_type==10,1, ///
			 cond(hh_type==50,2, ///
			 cond(presence_PVK==1 | presence_MVK==1,3, ///
			 cond(presence_PLK==1 | presence_MLK==1,4,5)))))
			 
			 
label define ltypo_2  1"Single parent" 2"Two parent family" 3"Three-generation family" ///
                      4"Extended-lateraly family" 5"Extended Complex Family", modify
					  
label val typo_2 ltypo_2


**Création de la variable incomplete vaccination

*polio0
capture drop polio0
gen polio0 = (EventCode==130)	

capture drop polio0_date
gen double polio0_date = EventDate if EventCode==130
sort concat_IndividualId polio0
bys concat_IndividualId: replace polio0_date = polio0_date[_n-1] if missing(polio0_date) & _n > 1 
bys concat_IndividualId: replace polio0_date = polio0_date[_N] if missing(polio0_date)
count if polio0_date==.
format polio0_date %tc
capture drop polio0_1
bys concat_IndividualId (EventDate): gen polio0_1=(EventDate>=polio0_date) if polio0_date!=.
bys concat_IndividualId (EventDate): replace polio0_1=0 if polio0_1==.
bys concat_IndividualId (EventDate): replace polio0_1=1 if EventDate==polio0_date


*polio1
capture drop polio1
gen polio1 = (EventCode==131)	
capture drop polio1_date
gen double polio1_date = EventDate if EventCode==131
sort concat_IndividualId polio1
bys concat_IndividualId: replace polio1_date = polio1_date[_n-1] if missing(polio1_date) & _n > 1 
bys concat_IndividualId: replace polio1_date = polio1_date[_N] if missing(polio1_date)
count if polio1_date==.
format polio1_date %tc
capture drop polio1_1
bys concat_IndividualId (EventDate): gen polio1_1=(EventDate>=polio1_date) if polio1_date!=.
bys concat_IndividualId (EventDate): replace polio1_1=0 if polio1_1==.
bys concat_IndividualId (EventDate): replace polio1_1=1 if EventDate==polio1_date


*polio2
capture drop polio2
gen polio2 = (EventCode==132)	
capture drop polio2_date
gen double polio2_date = EventDate if EventCode==132
sort concat_IndividualId polio2
bys concat_IndividualId: replace polio2_date = polio2_date[_n-1] if missing(polio2_date) & _n > 1 
bys concat_IndividualId: replace polio2_date = polio2_date[_N] if missing(polio2_date)
count if polio2_date==.
format polio2_date %tc
capture drop polio2_1
bys concat_IndividualId (EventDate): gen polio2_1=(EventDate>=polio2_date) if polio2_date!=.
bys concat_IndividualId (EventDate): replace polio2_1=0 if polio2_1==.
bys concat_IndividualId (EventDate): replace polio2_1=1 if EventDate==polio2_date


*polio3
capture drop polio3
gen polio3 = (EventCode==133)	
capture drop polio3_date
gen double polio3_date = EventDate if EventCode==133
sort concat_IndividualId polio3
bys concat_IndividualId: replace polio3_date = polio3_date[_n-1] if missing(polio3_date) & _n > 1 
bys concat_IndividualId: replace polio3_date = polio3_date[_N] if missing(polio3_date)
count if polio3_date==.
format polio3_date %tc
capture drop polio3_1
bys concat_IndividualId (EventDate): gen polio3_1=(EventDate>=polio3_date) if polio3_date!=.
bys concat_IndividualId (EventDate): replace polio3_1=0 if polio3_1==.
bys concat_IndividualId (EventDate): replace polio3_1=1 if EventDate==polio3_date




*hib1
capture drop hib1
gen hib1 = (EventCode==141)	
capture drop hib1_date
gen double hib1_date = EventDate if EventCode==141
sort concat_IndividualId hib1
bys concat_IndividualId: replace hib1_date = hib1_date[_n-1] if missing(hib1_date) & _n > 1 
bys concat_IndividualId: replace hib1_date = hib1_date[_N] if missing(hib1_date)
count if hib1_date==.
format hib1_date %tc
capture drop hib1_1
bys concat_IndividualId (EventDate): gen hib1_1=(EventDate>=hib1_date) if hib1_date!=.
bys concat_IndividualId (EventDate): replace hib1_1=0 if hib1_1==.
bys concat_IndividualId (EventDate): replace hib1_1=1 if EventDate==hib1_date

*hib2
capture drop hib2
gen hib2 = (EventCode==142)	
capture drop hib1_date
gen double hib2_date = EventDate if EventCode==142
sort concat_IndividualId hib2
bys concat_IndividualId: replace hib2_date = hib2_date[_n-1] if missing(hib2_date) & _n > 1 
bys concat_IndividualId: replace hib2_date = hib2_date[_N] if missing(hib2_date)
count if hib2_date==.
format hib2_date %tc
capture drop hib2_1
bys concat_IndividualId (EventDate): gen hib2_1=(EventDate>=hib2_date) if hib2_date!=.
bys concat_IndividualId (EventDate): replace hib2_1=0 if hib2_1==.
bys concat_IndividualId (EventDate): replace hib2_1=1 if EventDate==hib2_date


*hib3
capture drop hib3
gen hib3 = (EventCode==143)	
capture drop hib1_date
gen double hib3_date = EventDate if EventCode==143
sort concat_IndividualId hib3
bys concat_IndividualId: replace hib3_date = hib3_date[_n-1] if missing(hib3_date) & _n > 1 
bys concat_IndividualId: replace hib3_date = hib3_date[_N] if missing(hib3_date)
count if hib3_date==.
format hib3_date %tc
capture drop hib3_1
bys concat_IndividualId (EventDate): gen hib3_1=(EventDate>=hib3_date) if hib3_date!=.
bys concat_IndividualId (EventDate): replace hib3_1=0 if hib3_1==.
bys concat_IndividualId (EventDate): replace hib3_1=1 if EventDate==hib3_date


*hepb1
capture drop hepb1
gen hepb1 = (EventCode==151)	
capture drop hepb1_date
gen double hepb1_date = EventDate if EventCode==151
sort concat_IndividualId hepb1
bys concat_IndividualId: replace hepb1_date = hepb1_date[_n-1] if missing(hepb1_date) & _n > 1 
bys concat_IndividualId: replace hepb1_date = hepb1_date[_N] if missing(hepb1_date)
count if hepb1_date==.
format hepb1_date %tc
capture drop hepb1_1
bys concat_IndividualId (EventDate): gen hepb1_1=(EventDate>=hepb1_date) if hepb1_date!=.
bys concat_IndividualId (EventDate): replace hepb1_1=0 if hepb1_1==.
bys concat_IndividualId (EventDate): replace hepb1_1=1 if EventDate==hepb1_date

 
*hepb2
capture drop hepb2
gen hepb2 = (EventCode==152)	
capture drop hepb2_date
gen double hepb2_date = EventDate if EventCode==152
sort concat_IndividualId hepb2
bys concat_IndividualId: replace hepb2_date = hepb2_date[_n-1] if missing(hepb2_date) & _n > 1 
bys concat_IndividualId: replace hepb2_date = hepb2_date[_N] if missing(hepb2_date)
count if hepb2_date==.
format hepb2_date %tc
capture drop hepb2_1
bys concat_IndividualId (EventDate): gen hepb2_1=(EventDate>=hepb2_date) if hepb2_date!=.
bys concat_IndividualId (EventDate): replace hepb2_1=0 if hepb2_1==.
bys concat_IndividualId (EventDate): replace hepb2_1=1 if EventDate==hepb2_date


*hepb3
capture drop hepb3
gen hepb3 = (EventCode==153)	
capture drop hepb3_date
gen double hepb3_date = EventDate if EventCode==153
sort concat_IndividualId hepb3
bys concat_IndividualId: replace hepb3_date = hepb3_date[_n-1] if missing(hepb3_date) & _n > 1 
bys concat_IndividualId: replace hepb3_date = hepb3_date[_N] if missing(hepb3_date)
count if hepb3_date==.
format hepb3_date %tc
capture drop hepb3_1
bys concat_IndividualId (EventDate): gen hepb3_1=(EventDate>=hepb3_date) if hepb3_date!=.
bys concat_IndividualId (EventDate): replace hepb3_1=0 if hepb3_1==.
bys concat_IndividualId (EventDate): replace hepb3_1=1 if EventDate==hepb3_date



*bcg
capture drop bcg
gen bcg = (EventCode==161)	
capture drop bcg_date
gen double bcg_date = EventDate if EventCode==161 
sort concat_IndividualId bcg
bys concat_IndividualId: replace bcg_date = bcg_date[_n-1] if missing(bcg_date) & _n > 1 
bys concat_IndividualId: replace bcg_date = bcg_date[_N] if missing(bcg_date)
count if bcg_date==.
format bcg_date %tc
capture drop bcg_1
bys concat_IndividualId (EventDate): gen bcg_1=(EventDate>=bcg_date) if bcg_date!=.
bys concat_IndividualId (EventDate): replace bcg_1=0 if bcg_1==.
bys concat_IndividualId (EventDate):replace bcg_1=1 if EventDate==bcg_date


*measles
capture drop measles
gen measles = (EventCode==171 )	
capture drop measles_date
gen double measles_date = EventDate if EventCode==171 
sort concat_IndividualId measles
bys concat_IndividualId: replace measles_date = measles_date[_n-1] if missing(measles_date) & _n > 1 
bys concat_IndividualId: replace measles_date = measles_date[_N] if missing(measles_date)
count if measles_date==.
format measles_date %tc
capture drop measles_1
bys concat_IndividualId (EventDate): gen measles_1=(EventDate>=measles_date) if measles_date!=.
bys concat_IndividualId (EventDate): replace measles_1=0 if measles_1==.
bys concat_IndividualId (EventDate):replace measles_1=1 if EventDate==measles_date



*yellow fever
capture drop fj
gen fj = (EventCode==181)	
capture drop fj_date
gen double fj_date = EventDate if EventCode==181
sort concat_IndividualId fj 
bys concat_IndividualId: replace fj_date = fj_date[_n-1] if missing(fj_date) & _n > 1 
bys concat_IndividualId: replace fj_date = fj_date[_N] if missing(fj_date)
count if fj_date==.
format fj_date %tc
capture drop fj_1
bys concat_IndividualId (EventDate): gen fj_1=(EventDate>=fj_date) if fj_date!=.
bys concat_IndividualId (EventDate): replace fj_1=0 if fj_1==.
bys concat_IndividualId (EventDate):replace fj_1=1 if EventDate==fj_date


 
*dtcoq1
capture drop dtcoq1
gen dtcoq1 = (EventCode==191)	
capture drop dtcoq1_date
gen double dtcoq1_date = EventDate if EventCode==191
sort concat_IndividualId dtcoq1
bys concat_IndividualId: replace dtcoq1_date = dtcoq1_date[_n-1] if missing(dtcoq1_date) & _n > 1 
bys concat_IndividualId: replace dtcoq1_date = dtcoq1_date[_N] if missing(dtcoq1_date)
count if dtcoq1_date==.
format dtcoq1_date %tc
capture drop dtcoq1_1
bys concat_IndividualId (EventDate) : gen dtcoq1_1=(EventDate>=dtcoq1_date) if dtcoq1_date!=.
bys concat_IndividualId (EventDate) : replace dtcoq1_1=0 if dtcoq1_1==.
bys concat_IndividualId (EventDate):replace dtcoq1_1=1 if EventDate==dtcoq1_date


 
*dtcoq2
capture drop dtcoq2
gen dtcoq2 = (EventCode==192)	
capture drop dtcoq1_date
gen double dtcoq2_date = EventDate if EventCode==192
sort concat_IndividualId dtcoq2
bys concat_IndividualId: replace dtcoq2_date = dtcoq2_date[_n-1] if missing(dtcoq2_date) & _n > 1 
bys concat_IndividualId: replace dtcoq2_date = dtcoq2_date[_N] if missing(dtcoq2_date)
count if dtcoq2_date==.
format dtcoq2_date %tc
capture drop dtcoq2_1
bys concat_IndividualId (EventDate) : gen dtcoq2_1=(EventDate>=dtcoq2_date) if dtcoq2_date!=.
bys concat_IndividualId (EventDate) : replace dtcoq2_1=0 if dtcoq2_1==.
bys concat_IndividualId (EventDate):replace dtcoq2_1=1 if EventDate==dtcoq2_date


 
*dtcoq3
capture drop dtcoq3
gen dtcoq3 = (EventCode==193)	
capture drop dtcoq3_date
gen double dtcoq3_date = EventDate if EventCode==193

sort concat_IndividualId dtcoq3
bys concat_IndividualId: replace dtcoq3_date = dtcoq3_date[_n-1] if missing(dtcoq3_date) & _n > 1 
bys concat_IndividualId: replace dtcoq3_date = dtcoq3_date[_N] if missing(dtcoq3_date)
count if dtcoq3_date==.
format dtcoq3_date %tc

capture drop dtcoq3_1
bys concat_IndividualId (EventDate): gen dtcoq3_1=(EventDate>=dtcoq3_date) if dtcoq3_date!=.
bys concat_IndividualId (EventDate): replace dtcoq3_1=0 if dtcoq3_1==.
bys concat_IndividualId (EventDate):replace dtcoq3_1=1 if EventDate==dtcoq3_date

br concat_IndividualId EventDate EventCode  polio0_1 polio1_1 polio2_1 polio3_1 hepb1_1 ///
   hepb2_1 hepb3_1 hib1_1 hib2_1 hib3_1 bcg_1 measles_1 fj_1

save base_vaccin_V1,replace
XX

use base_vaccin_V1,clear

* Création des variables dépendantes 
* Avoir recu la polio
capture drop complete
gen complete = (polio0_1==1 & polio1_1==1 & polio2_1==1   ///
				  & bcg_1==1 & measles_1==1 & fj_1==1)
				  
capture drop incomplete
gen incomplete = 1 - complete
 
   


**Rates by single calendar year
sort concat_IndividualId EventDate EventCode
capture drop datebeg
sort concat_IndividualId EventDate EventCode
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

lab var datebeg "Date of beginning"

display %20.0f  365.25 *5* 24 * 60 * 60 * 1000
display %20.0f  365.25 *1* 24 * 60 * 60 * 1000

display %20.0f  365.25 *2* 24 * 60 * 60 * 1000

XX
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*               Vaccination coverage    (Kaplan-Meier Estimation)                                                          *                                     *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

log using estimation_taux,replace
** Estimation des taux de vaccination [polio0, bcg]
foreach var of varlist polio0 bcg{
stset EventDate , id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + 157788000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

log close 

log using estimation_taux_1,replace
** Estimation des taux de vaccination [polio0, bcg]
foreach var of varlist polio1 polio2{
stset EventDate , id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + 157788000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

log close 

log using estimation_taux_2,replace
** Estimation des taux de vaccination [dtcoq1, dtcoq2, dtcoq3]
foreach var of varlist dtcoq1 dtcoq2 dtcoq3{
stset EventDate , id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + 157788000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

log close 

log using estimation_taux_3,replace
** Estimation des taux de vaccination [measles, fj ]
foreach var of varlist measles fj {
stset EventDate , id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + 157788000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

 log close 
 
 
log using estimation_taux_4,replace
** Estimation des taux de vaccination [measles, fj ]
foreach var of varlist hepb1  hepb2 hepb3  hib1 hib2 hib3 {
stset EventDate , id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + 157788000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}




*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*               Vaccination coverage  timeless                                                          *                                     *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


stset EventDate , id(IndividualId) failure(polio0==1) origin(time DoB) ///
 time0(datebeg) scale(2629800000)exit( polio0==1 time DoB + 157788000000)

 *Delay vaccination
*for bcg et polio0 [it migth be less than 4 weeks]
stset EventDate , id(IndividualId) failure(bcg==1) origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(bcg==1 time DoB + 157788000000)
*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_bcg = s
sts gen ub_bcg=ub(s)
sts gen lb_bcg=lb(s)
gen Complement_bcg = 1- KM_bcg
gen ub_c_bcg = 1- ub_bcg
gen lb_c_bcg = 1- lb_bcg

twoway (line ub_c_bcg _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) (line lb_c_bcg _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_bcg _t, sort lcolor(black)lpattern(solid) ylabel(0(0.1)1) xlabel(0(5)60) ///
	   ytitle("Proportions d'enfants vaccinés") ///
	   xtitle("Age(mois)") title("Couverture vaccinale du bcg") ///
	   note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin bcg (0-4semaines)") legend(on)) , ///
       xline(0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8, lwidth(thick) lcolor(gs12)) ///
       xline(0 0.92, lcolor(black) lpattern(dash)) ///
       legend(off)
	   
graph save timing_bcg,replace
	   


sort MotherId DoB
capture drop child_rank
by MotherId concat_IndividualId (DoB), sort: gen child_rank = _n == 1 
bys MotherId : replace child_rank = sum(child_rank)

capture drop c_rank
recode child_rank (1=1 "rang 1")  (2=2 "rang 2") (3=3 "rang 3") (4/max = 4 " rang 4&+"), gen(c_rank)




sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


sort concat_IndividualId EventDate EventCode
cap drop censor_death
gen byte censor_death=(EventCode==7) 
stset EventDate, id(concat_IndividualId) failure(censor_death==1) ///
			time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)

stset	EventDate, id(concat_IndividualId) failure(censor_death==1) ///
        time0(datebeg) exit(time DoB+(31557600000*5)+212000000) ///
		origin(time DoB) scale(31557600000)


   
**Variables dépendantes

*(1) Vaccination complète (entre 0 et 1 an)

stset	EventDate, id(concat_IndividualId) failure(polio0==1) ///
        time0(datebeg) exit(time DoB+(31557600000)+212000000) ///
		origin(time DoB) scale(31557600000)
		
* Entre 0 et 5 ans

		
stset	EventDate, id(concat_IndividualId) failure(polio0==1) ///
        time0(datebeg) exit(time DoB+(31557600000*5)+212000000) ///
		origin(time DoB) scale(31557600000)

		
		stset	EventDate, id(concat_IndividualId) failure(polio0_1==1) ///
        time0(datebeg) entry(time DoB+(31557600000))  exit () ///
		origin(time DoB) scale(31557600000)
XX

				  			  				  
stset	EventDate, id(concat_IndividualId) failure(incomplete==0) ///
        time0(datebeg) exit(incomplete==0 time DoB+(31557600000)+212000000) ///
		origin(time DoB) scale(31557600000)
		
stcox ib2.typo_1 i.MigDeadY i.MigDeadO i.gender ib7.hdss_period  i.ib21.y3_mother_age_birth  i.twin

stcox ib2.typo_2 i.MigDeadY i.MigDeadO i.gender ib7.hdss_period  i.ib21.y3_mother_age_birth  i.twin ib0.MO_education


log using vacc_results_less_1year,replace	
stcox i.gender ib7.hdss_period  i.c_rank ib2.MigDeadMO ib2.MigDeadFA i.ib21.y3_mother_age_birth ///
      ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGF##ib0.coresidPGM ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle i.twin
log close
	  
		

	
stset	EventDate, id(concat_IndividualId) failure(complete==1) ///
        time0(datebeg) exit(complete==1 time DoB+(31557600000*5)+212000000) ///
		origin(time DoB) scale(31557600000)
	  


log using vacc_results_less_5year,replace	
stcox i.gender ib7.hdss_period  i.c_rank ib2.MigDeadMO ib2.MigDeadFA i.ib21.y3_mother_age_birth ///
      ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGF##ib0.coresidPGM ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle i.twin
log close

	  *M1
	  stcox ib2.MigDeadMO ib2.MigDeadFA
	  
	  *M2
	stcox  b2.MigDeadMO ib2.MigDeadFA ///
      ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGF##ib0.coresidPGM ///

stcox i.gender i.c_rank ib2.MigDeadMO ib2.MigDeadFA i.ib21.y3_mother_age_birth ///
      ib0.coresidMGM ib0.coresidMGF ///
	  ib0.coresidPGF ib0.coresidPGM ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle i.twin
	  
	  
stcox ib2.MigDeadMO ib2.MigDeadFA

bys hdss : stcox ib2.MigDeadMO ib2.MigDeadFA

*(2) Vaccination complète à temps
sort concat_IndividualId EventDate


* Harmoniser les dates
foreach w of varlist EventDate DoB{
gen double `w'_1 = dofc(`w')
format `w'_1 %td
drop `w' 
rename `w'_1 `w'
}


foreach w of varlist EventDate DoB{
gen double `w'_1 = cofd(`w')
format `w'_1 %tc
drop `w' 
rename `w'_1 `w'
}


*Add 12  hours to ENT
sort  concat_IndividualId EventDate EventCode 
bys concat_IndividualId : replace EventDate=EventDate+12*60*60*1000 if EventCode==6&EventCode[_n-1]==5

*Add 12  hours if DoB=DoDFA
sort  concat_IndividualId EventDate EventCode 
bys concat_IndividualId : replace EventDate=EventDate+12*60*60*1000 if EventCode==7&EventDate==DoB



