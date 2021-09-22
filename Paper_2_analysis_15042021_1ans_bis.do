********************************************************************************
************** Paper 2 -  do-file****

use child_vacc_residence_hdss_final.dta,clear



*Considérer les enfants nés en gambie à partir de l'an 2000

*(1) Sélectionner les enfants nés sous surveillance
sort  concat_IndividualId EventDate EventCode
drop if EventDate < DoB

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
merge m:1 MotherId using individual_parents_Niakhar_MO,keep(1 3)keepus(MO_educ ethnie RESI_cd_smat)
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
						
						
sort FatherId
merge m:1 FatherId using individual_parents_Niakhar_FA,keep(1 3)keepus(FA_educ)
drop _merge

capture drop FA_education
gen FA_education = cond(FA_educ==. | FA_educ==-1 | FA_educ==0 | FA_educ==14 | ///
                        FA_educ==15 | FA_educ==16 | FA_educ==17 | FA_educ==18 | ///
						FA_educ==19 | FA_educ==20 | FA_educ==21 | FA_educ==22 | ///
						FA_educ==23 | FA_educ==24 | FA_educ==25 | FA_educ==26 | ///
						FA_educ==27 | FA_educ==28 | FA_educ==29 | FA_educ==30 | ///
						FA_educ==31 | FA_educ==32 | FA_educ==33 | FA_educ==35,0, ///
				   cond(FA_educ==1 | FA_educ==2 | FA_educ==3 | FA_educ==4 | ///
				        FA_educ==5 | FA_educ==6 | FA_educ==36 | FA_educ==37,1, ///
				   cond(FA_educ==7 | FA_educ==8 | FA_educ==9 | FA_educ==10 | ///
				        FA_educ==11 | FA_educ==12 | FA_educ==13 | FA_educ==34 | ///
						FA_educ==38,2,.)))

replace FA_education=9 if  FatherId==""
		
*Ouagadougou
merge m:1 MotherId using  Ouaga_MO_educ,keep(1 3)keepus(education5 niv_vie  religion ///
emploi1 activity ethnic marital_st)

drop _merge

ta education5
replace MO_education = 0 if education5==0 | MO_education==9
replace MO_education = 1 if  education5==1
replace MO_education = 2 if education5==2 | education5==3 | education5==4

merge m:1 FatherId using  Ouaga_FA_educ,keep(1 3)keepus(education5)
drop _merge

ta education5
replace FA_education = 0 if education5==0 | FA_education==9
replace FA_education = 1 if  education5==1
replace FA_education = 2 if education5==2 | education5==3 | education5==4
replace FA_education=9 if  FatherId==""


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
						  
						  
merge m:1 FatherId using individual_parents_Farafenni_FA.dta, keep(1 3) keepus(educFA education_yearsFA)
drop _merge
destring education_yearsFA,replace
replace FA_education = 1 if education_yearsFA==1 | education_yearsFA==2 | ///
                            education_yearsFA==3 | education_yearsFA==4 | ///
							education_yearsFA==5 | education_yearsFA==6

replace FA_education=2 if education_yearsFA==7 | education_yearsFA==8 | ///
						  education_yearsFA==11 | education_yearsFA==12 | ///
						  education_yearsFA==13 | education_yearsFA==14 | ///
						  education_yearsFA==15 | education_yearsFA==16 | ///
						  education_yearsFA==17 | education_yearsFA==18 | ///
						  education_yearsFA==19
*Other variables?

label define lMO_education 0"None" 1"Primaire" 2"Secondaire&+" 9"Missing",modify
label val MO_education lMO_education 

label define lFA_education 0"None" 1"Primaire" 2"Secondaire&+" 9"Missing",modify
label val FA_education lFA_education 

ta FA_education
ta MO_education

replace FA_education=9 if  FatherId==""


*Child rank
sort MotherId DoB
capture drop child_rank
by MotherId DoB concat_IndividualId , sort: gen child_rank = _n == 1 
bys MotherId : replace child_rank = sum(child_rank)

*Correction de child rank

sort MotherId DoB concat_IndividualId 
capture drop MigDeadO_1
bys MotherId :gen MigDeadO_1 = MigDeadO[_n==1]
bys MotherId : replace MigDeadO_1 = sum(MigDeadO_1)
bys MotherId : replace child_rank = child_rank + 1 if MigDeadO_1==2


capture drop c_rank
recode child_rank (1=1 "rang 1")  (2=2 "rang 2") (3/max= 3 "rang 3&+"), gen(c_rank)


/*
*Number of siblings
capture drop n_siblings
bys MotherId : egen n_siblings = max(child_rank) 
*/
capture drop nsib
gen nsib = child_rank - 1

capture drop nsib_cat
recode nsib (0=0 "No sibling") (1 2 = 1 "1-2 siblings") (3/max = 3 ">=3 siblings"), gen (nsib_cat)

** Revoir la variable number of sibling de telle sorte qu'elle prenne en compte les décès et les émigrations dans le calcul
* du nombre de siblings.


capture drop  MigDeadY_bis
recode MigDeadY (3=0),gen(MigDeadY_bis)

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


capture drop typo_3_bis
gen typo_3_bis = cond(hh_type==.,., ///
             cond(hh_type==10 | hh_type==30,1, ///
			 cond(hh_type==50,2, ///
			 cond(hh_type==45 | hh_type==65 | hh_type==85 | hh_type==25,5, ///
			 cond(hh_type>=11&hh_type<=16 | hh_type>=23&hh_type<=24 ///
			 | hh_type>=31&hh_type<=36 | hh_type>=43&hh_type<=44 ///
			 | hh_type>=51&hh_type<=56 | hh_type>=63&hh_type<=64 ///
			 | hh_type>=71&hh_type<=76 | hh_type>=83&hh_type<=84,3, ///
			 cond(presence_PLK==1 | presence_MLK==1,4,0))))))
			 

label val typo_3_bis ltypo_2

					  
**Ajout de quelques variables (importantes)
* Saison de naissance

capture drop mois_naiss
gen mois_naiss = month(dofc(DoB))


capture drop saison_naiss
gen saison_naiss = cond(mois_naiss==6 | mois_naiss==7 | mois_naiss==8 | ///
                                mois_naiss==9 | mois_naiss==10, 1, 2)
label define lsaison_naiss 1"saison pluvieuse" 2 "saison sèche", modify
label val saison_naiss lsaison_naiss

*Année de naissance
capture drop année_naiss 
gen année_naiss = year(dofc(DoB))

capture drop année_naiss_gp10_ans
recode année_naiss (1990/1994 = 1990) (1995/1999 = 1995) (2000/2004 = 2000) ///
                     (2005/2009 = 2005) (2010/2014 = 2010) (2015/max = 2015), gen (année_naiss_gp10_ans)

capture drop hdss_anne_naiss
egen hdss_anne_naiss=group(hdss_1 année_naiss_gp10_ans), label


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

*hdss_period
forval i=1/20{
sort concat_IndividualId EventDate 
by concat_IndividualId : replace period = period[_n+1] if year(EventDate)==year(EventDate[_n+1]) & period==.
by concat_IndividualId : replace period = period[_n-1] if year(EventDate)==year(EventDate[_n-1]) & period==.
}

recode FA_education (9=0)
*Create new variables 
*Having resident YS
capture drop pres_YS
gen pres_YS = (MigDeadY==2)

*Having older resident OS
capture drop pres_OS
gen pres_OS = (MigDeadO==2)

capture drop MigDeadO_interv_new
recode MigDeadO_interv (0 = 0 "No Old sib") ///
                       (10 = 1 "O sib non resident") ///
					   (21 22 = 3 "O int <18m") ///
                       (23 24 25 26 27 28 = 4 "O int >18m") ///
					   (30 = 5 "O sib dead"),gen(MigDeadO_interv_new) 

recode MigDeadO_interv_new (5 = 4)

capture drop MigDeadO_interv_new_1
recode MigDeadO_interv (0 = 0 "No Old sib") ///
                       (10 = 1 "O sib non resident") ///
					   (21 22 23 = 3 "O int <24m") ///
                       (24 25 26 27 28 = 4 "O int >24m") ///
					   (30 = 5 "O sib dead"),gen(MigDeadO_interv_new_1)


*YaC
capture drop MigDeadO_interv
gen byte MigDeadO_interv= MigDeadO*10 + gp_ecart_O_new*(MigDeadO==2) 
label def lMigDeadO_interv 0 "No Old sib" 10 "O sib non resident" 21 "O int <12m" ///
		22 "O int 12-17m" 23 "O int 18-23m" 24 "O int 24-29m" 25 "O int 30-35m" ///
		26 "O int 36-41m" 27 "O int 42-47m" 28 "O int 48m +" 30 "O sib dead", modify
lab val MigDeadO_interv lMigDeadO_interv
* Only in model -with both MigDeadO_interv and res_O_DTH_TVC
* 				-with 24 used as reference category 
recode MigDeadO_interv 30=24 // recode dead in the Ref category "O int 24-29m"

capture drop MigDeadO_interv_new
recode MigDeadO_interv (0 = 0 "No Old sib") ///
                       (10 = 1 "O sib non resident") ///
					   (21 22 = 3 "O int <18m") ///
                       (23 24 25 26 27 28 = 4 "O int >18m") ///
					   (30 = 5 "O sib dead"),gen(MigDeadO_interv_new) 

recode MigDeadO_interv_new (5  1 = 0)

capture drop MigDeadO_interv_new_1
recode MigDeadO_interv (0 = 0 "No Old sib") ///
                       (10 = 1 "O sib non resident") ///
					   (21 22 23 = 3 "O int <24m") ///
                       (24 25 26 27 28 = 4 "O int >24m") ///
					   (30 = 5 "O sib dead"),gen(MigDeadO_interv_new_1)
					   
*Younger siblings
*YaC
capture drop MigDeadY_interv
gen byte MigDeadY_interv= MigDeadY*10 + gp_ecart_Y_new*(MigDeadY==2) 
label def lMigDeadY_interv 0 "No Younger sib" 10 "Y sib non resident" 21 "Y int <12m" ///
		22 "Y int 12-17m" 23 "Y int 18-23m" 24 "Y int 24-29m" 25 "Y int 30-35m" ///
		26 "Y int 36-41m" 27 "Y int 42-47m" 28 "Y int 48m +" 30 "Y sib dead", modify
lab val MigDeadY_interv lMigDeadY_interv
* Only in model -with both MigDeadO_interv and res_O_DTH_TVC
* 				-with 24 used as reference category 
recode MigDeadY_interv 30=24 // recode dead in the Ref category "O int 24-29m"

capture drop MigDeadY_interv_new
recode MigDeadY_interv (0 = 0 "No Younger sib") ///
                       (10 = 1 "Y sib non resident") ///
					   (21 22 = 3 "Y int <18m") ///
                       (23 24 25 26 27 28 = 4 "Y int >18m") ///
					   (30 = 5 "Y sib dead"),gen(MigDeadY_interv_new) 

recode MigDeadY_interv_new (5  1 = 0)

capture drop MigDeadO_interv_new_1
recode MigDeadO_interv (0 = 0 "No Old sib") ///
                       (10 = 1 "O sib non resident") ///
					   (21 22 23 = 3 "O int <24m") ///
                       (24 25 26 27 28 = 4 "O int >24m") ///
					   (30 = 5 "O sib dead"),gen(MigDeadO_interv_new_1)

* Création des variables dépendantes 
* Avoir recu la polio
capture drop complete
gen complete = (polio0_1==1 & polio1_1==1 & polio2_1==1   ///
				  & bcg_1==1 & measles_1==1 & fj_1==1)
	
*Delay vaccination [Vaccination à temps]

sort concat_IndividualId EventDate EventCode
capture drop datebeg
sort concat_IndividualId EventDate EventCode
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


lab var datebeg "Date of beginning"

stset EventDate , id(concat_IndividualId) failure(polio0==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio0==1 time DoB+(31557600000*5)+212000000) 

*for bcg et polio0 [it migth be less than 4 weeks]
* 4 semaines = 28 jours = 28/30.5 = 0.92 mois
capture drop tpolio0
gen tpolio0 = (polio0==1 & _t<=0.92)

capture drop tpolio0_date
gen double tpolio0_date = EventDate if tpolio0==1
sort concat_IndividualId tpolio0
bys concat_IndividualId: replace tpolio0_date = tpolio0_date[_n-1] if missing(tpolio0_date) & _n > 1 
bys concat_IndividualId: replace tpolio0_date = tpolio0_date[_N] if missing(tpolio0_date)
count if tpolio0_date==.
format tpolio0_date %tc
capture drop tpolio0_1
bys concat_IndividualId (EventDate): gen tpolio0_1=(EventDate>=tpolio0_date) if tpolio0_date!=.
bys concat_IndividualId (EventDate): replace tpolio0_1=0 if tpolio0_1==.
bys concat_IndividualId (EventDate): replace tpolio0_1=1 if EventDate==tpolio0_date

*bcg
stset EventDate , id(concat_IndividualId) failure(bcg==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(bcg==1 time DoB+(31557600000*5)+212000000) 

capture drop tbcg
gen tbcg = (bcg==1 & _t<=0.92)

capture drop tbcg_date
gen double tbcg_date = EventDate if tbcg==1
sort concat_IndividualId tbcg
bys concat_IndividualId: replace tbcg_date = tbcg_date[_n-1] if missing(tbcg_date) & _n > 1 
bys concat_IndividualId: replace tbcg_date = tbcg_date[_N] if missing(tbcg_date)
count if tbcg_date==.
format tbcg_date %tc
capture drop tbcg_1
bys concat_IndividualId (EventDate): gen tbcg_1=(EventDate>=tbcg_date) if tbcg_date!=.
bys concat_IndividualId (EventDate): replace tbcg_1=0 if tbcg_1==.
bys concat_IndividualId (EventDate): replace tbcg_1=1 if EventDate==tbcg_date

sort concat_IndividualId EventDate EventCode
capture drop datebeg
sort concat_IndividualId EventDate EventCode
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc
* for polio1 [it migth be between 4 weeks – 2 months]
stset EventDate , id(concat_IndividualId) failure(polio1==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio1==1 time DoB+(31557600000*2)+212000000) 

capture drop tpolio1
gen tpolio1 = (polio1==1  & _t<=2.5)

stset EventDate , id(concat_IndividualId) failure(polio1==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio1==1 time DoB+(31557600000*5)+212000000) 

display %20.0f 31557600000/12


capture drop tpolio1_date
gen double tpolio1_date = EventDate if tpolio1==1
sort concat_IndividualId tpolio1
bys concat_IndividualId: replace tpolio1_date = tpolio1_date[_n-1] if missing(tpolio1_date) & _n > 1 
bys concat_IndividualId: replace tpolio1_date = tpolio1_date[_N] if missing(tpolio1_date)
count if tpolio1_date==.
format tpolio1_date %tc
capture drop tpolio1_1
bys concat_IndividualId (EventDate): gen tpolio1_1=(EventDate>=tpolio1_date) if tpolio1_date!=.
bys concat_IndividualId (EventDate): replace tpolio1_1=0 if tpolio1_1==.
bys concat_IndividualId (EventDate): replace tpolio1_1=1 if EventDate==tpolio1_date

* for polio2 [it migth be between 8 semaines - 4 mois]
stset EventDate , id(concat_IndividualId) failure(polio2==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio2==1 time DoB+(31557600000*5)+212000000) 

capture drop tpolio2
gen tpolio2 = (polio2==1 & _t<=4)


capture drop tpolio2_date
gen double tpolio2_date = EventDate if tpolio2==1
sort concat_IndividualId tpolio2
bys concat_IndividualId: replace tpolio2_date = tpolio2_date[_n-1] if missing(tpolio2_date) & _n > 1 
bys concat_IndividualId: replace tpolio2_date = tpolio2_date[_N] if missing(tpolio2_date)
count if tpolio2_date==.
format tpolio2_date %tc
capture drop tpolio2_1
bys concat_IndividualId (EventDate): gen tpolio2_1=(EventDate>=tpolio2_date) if tpolio2_date!=.
bys concat_IndividualId (EventDate): replace tpolio2_1=0 if tpolio2_1==.
bys concat_IndividualId (EventDate): replace tpolio2_1=1 if EventDate==tpolio2_date

* for measles and yellow fever [it migth be between 9 mois– 12mois]

*measles
stset EventDate , id(concat_IndividualId) failure(measles==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(measles==1 time DoB+(31557600000*5)+212000000) 

capture drop tmeasles
gen tmeasles = (measles==1 & _t<=12)

capture drop tmeasles_date
gen double tmeasles_date = EventDate if tmeasles==1
sort concat_IndividualId tmeasles
bys concat_IndividualId: replace tmeasles_date = tmeasles_date[_n-1] if missing(tmeasles_date) & _n > 1 
bys concat_IndividualId: replace tmeasles_date = tmeasles_date[_N] if missing(tmeasles_date)
count if tmeasles_date==.
format tmeasles_date %tc
capture drop tmeasles_1
bys concat_IndividualId (EventDate): gen tmeasles_1=(EventDate>=tmeasles_date) if tmeasles_date!=.
bys concat_IndividualId (EventDate): replace tmeasles_1=0 if tmeasles_1==.
bys concat_IndividualId (EventDate): replace tmeasles_1=1 if EventDate==tmeasles_date

*yellow fever
stset EventDate , id(concat_IndividualId) failure(fj==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(fj==1 time DoB+(31557600000*5)+212000000) 

capture drop tfj
gen tfj = (fj==1 & _t<=12)

capture drop tfj_date
gen double tfj_date = EventDate if tfj==1
sort concat_IndividualId tfj
bys concat_IndividualId: replace tfj_date = tfj_date[_n-1] if missing(tfj_date) & _n > 1 
bys concat_IndividualId: replace tfj_date = tfj_date[_N] if missing(tfj_date)
count if tfj_date==.
format tfj_date %tc
capture drop tfj_1
bys concat_IndividualId (EventDate): gen tfj_1=(EventDate>=tfj_date) if tfj_date!=.
bys concat_IndividualId (EventDate): replace tfj_1=0 if tfj_1==.
bys concat_IndividualId (EventDate): replace tfj_1=1 if EventDate==tfj_date

*Delay vaccination
capture drop good_vacc
gen good_vacc = (tpolio0_1==1 & tpolio1_1==1 & tpolio2_1==1   ///
				  & tbcg_1==1 & tmeasles_1==1 & tfj_1==1)

				  
				  
*Some corrections
capture drop nsib
gen nsib = child_rank - 1

*bys MotherId : replace nsib = nsib - 1 if (MigDeadY==3 | MigDeadO==3) & nsib>0

capture drop nsib_cat
recode nsib (0=0 "No sibling") (1 2 = 1 "1-2 siblings") (3/max = 3 ">=3 siblings"), gen (nsib_cat)


capture drop nsib_cat_bis
recode nsib (0=0 "No sibling") (1 = 1 "1siblings") (2=2 "2 siblings") (3/max = 3 ">=3 siblings"), gen (nsib_cat_bis)
replace nsib_cat_bis = 1 if MigDeadY_interv_new!=0 & nsib_cat_bis ==0
replace nsib_cat_bis = 1 if MigDeadO_interv_new!=0 & nsib_cat_bis ==0

capture drop nsib_cat_bis1
recode nsib (0=0 "No sibling") (1 = 1 "1siblings") (2/max=2 ">=2 siblings"), gen (nsib_cat_bis1)




*Considérer les enfants nés en gambie entre 2000 et 2018
display %20.0f clock("01jan 2000","DMY")
display %20.0f clock("01jan 2019","DMY")
capture drop  birth_g
gen birth_g = (EventCode==2 & DoB >=1262304000000 & DoB<1861920000000 & hdss=="GM011")
display %20.0f clock("13may 1999","DMY")

capture drop  birth_g1
bysort concat_IndividualId (EventDate) : egen double birth_g1=max(birth_g)
*drop if birth_g1==1 & hdss=="GM011"

* Considérer les enfants nés à Ouagadougou entre 2009 et 2017
display %20.0f clock("01jan 2009","DMY")
display %20.0f clock("01jan 2018","DMY")
capture drop  birth_b
gen birth_b = (EventCode==2 & DoB >= 1546387200000 & DoB< 1830384000000 & hdss=="BF021")

capture drop  birth_b1
bysort concat_IndividualId (EventDate) : egen double birth_b1=max(birth_b)

*Considérer les enfants nés à Niakhar entre 2000 et 2014
display %20.0f clock("01jan 2000","DMY")
display %20.0f clock("01jan 2015","DMY")
capture drop  birth_n
gen birth_n = (EventCode==2 & DoB >= 1262304000000 & DoB< 1735689600000 & hdss=="SN011")

capture drop  birth_n1
bysort concat_IndividualId (EventDate) : egen double birth_n1=max(birth_n)

**Echantillon considéré
capture drop echan
gen echan = (birth_g1==1 | birth_b1==1 | birth_n1==1)

*Echantillon sur 2009 - 2015
*Considérer les enfants nés à Niakhar entre 2010 et 2014
display %20.0f clock("01jan 2010","DMY")
display %20.0f clock("01jan 2015","DMY")
capture drop  birth_00_14
gen birth_00_14 = (EventCode==2 & DoB >=1577923200000 & DoB< 1735689600000)

capture drop  birth_00_14_1
bysort concat_IndividualId (EventDate) : egen double birth_00_14_1=max(birth_00_14)


**Caractéristiques sociodémographiques
capture drop hdss_period
egen hdss_period=group(hdss_1 period), label(hdss_period, replace)


* Recalculer l'âge de la mère
capture drop y3_mother_age_birth_bis
gen y3_mother_age_birth_bis =  cond(mother_age_birth==.,99, ///
                               cond(mother_age_birth<20,1, ///
							   cond(mother_age_birth>=20 & mother_age_birth<35,2,3)))
							   
label define lmother_age 99"Missing" 1"<20" 2"20 - 34 ans" 3"35ans&+", modify
label val y3_mother_age_birth_bis lmother_age

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop hdss_period_bis
egen hdss_period_bis=group(hdss_1 année_naiss), label(hdss_period_bis, replace)

capture drop hdss_period_bis1
egen hdss_period_bis1=group(hdss_1 année_naiss_gp10_ans), label(hdss_period_bis1, replace)

capture drop nomiss
gen nomiss = (typo_2!=.& nsib_cat!=.& MigDeadY_interv_new!=. & ///
         MigDeadO_interv_new!=. & gender!=.& saison_naiss!=.& ///
		 twin!=.& y3_mother_age_birth_bis!=.& MO_education!=.& hdss_period!=. & y3_mother_age_birth_bis!=99)

drop if nomiss==0

capture drop zd
gen zd = substr(locationid,1,6) if hdss=="BF021"

merge m:1 zd using zd, keep (1 3) keepus (type_zone) gen(mer_tz)
count if hdss=="BF021" & type_zone==.
label define type_zone 1"lotie" 2"Non lotie",modify
label val type_zone type_zone

capture drop hdss_bis 
gen hdss_bis = hdss

replace hdss_bis = "BF021_nl" if type_zone==2
save base_vaccin_V1_des,replace	

/*
keep if année_naiss >=2010
*Considérer les enfants nés en gambie à partir de l'an 2000
display %20.0f clock("01jan 2000","DMY")

capture drop birth birth_g
gen birth_g = (EventCode==2 & DoB <  1262304000000)

bysort concat_IndividualId (EventDate) : egen double birth_g1=max(birth_g)
drop if birth_g1==1 & hdss=="GM011"

save  base_vaccin_V1_des_2010_201x,replace
*/
XX
   

*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*               Vaccination coverage    (Kaplan-Meier Estimation)                                                          *                                     *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
use base_vaccin_V1_des,clear

*Choisir uniquement les enfants qui sont nés uniquement après 2010


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

**Modif YaC 28052021 - 060621 (après discussion - PhB)
log using estimation_taux_bis,replace
** Estimation des taux de vaccination [polio0, bcg]
foreach var of varlist polio0 bcg{
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss_bis) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

log close 

* By household structure
**Modif YaC 28052021 - 060621 (après discussion - PhB)
log using estimation_taux_hh_s,replace
** Estimation des taux de vaccination [polio0, bcg]
foreach var of varlist bcg polio0  polio1 polio2 measles fj complete {
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
levelsof hdss_bis, local(levels) 
foreach l of local levels {
    disp "`l'" "/" "`var'"
sts list  if hdss_bis=="`l'",  at(0 36) by(typo_2) failure  saving(`var'_`l', replace)
sts test typo_2, detail
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}
 }
log close 

***LR tests for the link between vaccination and HH structures



stset EventDate if echan==1, id(IndividualId) failure(polio0) origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(polio0==1 time DoB + (31557600000*3)+212000000)

sts list  if hdss_bis=="BF021",  at(0 36) by(typo_2) failure  saving(aa, replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace



**Modif YaC 28052021 - 060621 (après discussion - PhB)
log using estimation_taux_1_bis,replace
** Estimation des taux de vaccination [polio0, bcg]
foreach var of varlist polio1 polio2{
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss_bis) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

log close 


**Modif YaC 28052021 - 060621 (après discussion - PhB)
log using estimation_taux_3_bis,replace
** Estimation des taux de vaccination [measles, fj ]
foreach var of varlist measles fj {
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss_bis) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

 log close 
 
 
**Modif YaC 28052021 - 060621 (après discussion - PhB)
log using estimation_taux_4_bis,replace
** Estimation des taux de vaccination [measles, fj ]
foreach var of varlist polio0 bcg polio1 polio2 measles fj complete {
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0(1)12 15 18 21 24 27 30 33 36) by(hdss_bis) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

 log close 
 

**Modif YaC 28052021 - 060621 (après discussion - PhB)
log using estimation_taux_4_2_bis,replace
** Estimation des taux de vaccination [measles, fj ]
foreach var of varlist polio0 bcg polio1 polio2 measles fj complete {
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0 36) by(hdss_bis) failure  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

log close 

log using estimation_taux_5_bis,replace
** Estimation des taux de vaccination [measles, fj ]
foreach var of varlist  polio0 bcg polio1 polio2 measles fj complete {
stset EventDate if echan==1, id(IndividualId) failure(`var') origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(`var'==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0 36) by(hdss) surv  saving(`var', replace)
*sts graph, xlabel(0(5)60)
*save `var'_graph,replace
}

 log close 
 
 
*Rates by household structure


*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*               Vaccination coverage  timeless                                                          *                                     *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

use base_vaccin_V1_des,clear

**Modif YaC 28052021 - 060621 (après discussion - PhB)
 *Delay vaccination
*for bcg et polio0 [it migth be less than 4 weeks]
stset EventDate if echan==1 , id(concat_IndividualId) failure(bcg==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(bcg==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_bcg = s
sts gen ub_bcg=ub(s)
sts gen lb_bcg=lb(s)
gen Complement_bcg = 1- KM_bcg
gen ub_c_bcg = 1- ub_bcg
gen lb_c_bcg = 1- lb_bcg


capture drop upper
gen upper = 1
twoway  bar  upper _t if inrange(_t, 0, 0.92) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_bcg _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_bcg _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_bcg _t, sort lcolor(black)lpattern(dash) ///  
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Bcg", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin bcg (0-4semaines)", ///
span size(vsmall)) ///
legend(off))  
graph save timing_bcg_0_36,replace


**Modif 280521
*By HDSS
levelsof hdss_bis, local(levels) 
foreach l of local levels{
sts gen KM_bcg_`l' = s if hdss_bis=="`l'"
sts gen ub_bcg_`l'=ub(s) if hdss_bis=="`l'"
sts gen lb_bcg_`l'=lb(s) if hdss_bis=="`l'"
gen Complement_bcg_`l' = 1- KM_bcg_`l'
gen ub_c_bcg_`l' = 1- ub_bcg_`l' if hdss_bis=="`l'"
gen lb_c_bcg_`l' = 1- lb_bcg_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 1
su Complement_bcg_BF021, meanonly 
local max_BF021 = r(max)
su Complement_bcg_BF021_nl, meanonly 
local max_BF021_nl = r(max) 
su Complement_bcg_GM011, meanonly 
local max_GM011 = r(max)
su Complement_bcg_SN011, meanonly 
local max_SN011 = r(max)

twoway  bar  upper _t if inrange(_t, 0, 0.92) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_bcg_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///   /*Ouaga lotie*/
       (line lb_c_bcg_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
       (line Complement_bcg_BF021 _t, sort lcolor(red) lpattern(dash)) || /// 
	   (line ub_c_bcg_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// /*Ouaga */
       (line lb_c_bcg_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
       (line Complement_bcg_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || ///
	   (line ub_c_bcg_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///   /*Farafenni*/
	   (line lb_c_bcg_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
       (line Complement_bcg_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///    
	   (line ub_c_bcg_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///  /*Niakhar*/
       (line lb_c_bcg_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
       (line Complement_bcg_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Bcg", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin bcg (0-4semaines)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
 `max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)
 

*graph save timing_bcg_by_hdss_0_24,replace
graph save timing_bcg_by_hdss_0_36,replace
graph use "timing_bcg_by_hdss_0_36.gph", play("transform_graph.grec") name("timing_bcg_by_hdss_0_36", replace)

*rarea   ub_c_bcg lb_c_bcg _t , color(gray%20)  



*polio0
*for bcg et polio0 [it migth be less than 4 weeks]
stset EventDate if echan==1, id(concat_IndividualId) failure(polio0==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio0==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_polio0 = s
sts gen ub_polio0=ub(s)
sts gen lb_polio0=lb(s)
gen Complement_polio0 = 1- KM_polio0
gen ub_c_polio0 = 1- ub_polio0
gen lb_c_polio0 = 1- lb_polio0


twoway bar  upper _t if inrange(_t, 0, 0.92) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_polio0 _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_polio0 _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_polio0 _t, sort lcolor(black)lpattern(dash) /// 
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Polio0", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin polio0 (0-4semaines)", ///
span size(vsmall)) ///
legend(off)) 
   
graph save timing_polio0_0_36,replace

graph use "timing_polio0_0_36.gph", play("transform_graph.grec") name("timing_polio0_0_36", replace)

*By HDSS
levelsof hdss_bis , local(levels) 
foreach l of local levels{
sts gen KM_polio0_`l' = s if hdss_bis =="`l'"
sts gen ub_polio0_`l'=ub(s) if hdss_bis =="`l'"
sts gen lb_polio0_`l'=lb(s) if hdss_bis =="`l'"
gen Complement_polio0_`l' = 1- KM_polio0_`l'
gen ub_c_polio0_`l' = 1- ub_polio0_`l' if hdss_bis=="`l'"
gen lb_c_polio0_`l' = 1- lb_polio0_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 1
su Complement_polio0_BF021, meanonly 
local max_BF021 = r(max)
su Complement_polio0_BF021_nl, meanonly 
local max_BF021_nl = r(max)
su Complement_polio0_GM011, meanonly 
local max_GM011 = r(max) 
su Complement_polio0_SN011, meanonly 
local max_SN011 = r(max)
twoway  bar  upper _t if inrange(_t, 0, 0.92) , bcolor(gs14) barwidth (0.001) base(0) || /// 
    (line ub_c_polio0_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///   
    (line lb_c_polio0_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
    (line Complement_polio0_BF021 _t, sort lcolor(red) lpattern(dash)) || /// /*Ouaga - Non lotie*/
	(line ub_c_bcg_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// 
    (line lb_c_bcg_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
    (line Complement_polio0_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || /// 
	(line ub_c_polio0_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) /// /*Farafenni*/
	(line lb_c_polio0_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
    (line Complement_polio0_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///   
	(line ub_c_polio0_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) /// /*Niakhar*/
    (line lb_c_polio0_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
    (line Complement_polio0_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Polio0", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin polio0  (0-4semaines)", span size(vsmall)) legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
 `max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)
 
*graph save timing_polio0_by_hdss_0_24,replace
graph save timing_polio0_by_hdss_0_36,replace
graph use "timing_polio0_by_hdss_0_36.gph", play("transform_graph.grec") name("timing_polio0_by_hdss_0_36", replace)


*polio1
*for bcg et polio0 [it migth be less than 4 weeks]
stset EventDate if echan==1 , id(concat_IndividualId) failure(polio1==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio1==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_polio1 = s
sts gen ub_polio1=ub(s)
sts gen lb_polio1=lb(s)
gen Complement_polio1 = 1- KM_polio1
gen ub_c_polio1 = 1- ub_polio1
gen lb_c_polio1 = 1- lb_polio1


twoway  bar  upper _t if inrange(_t, 0.92, 2) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_polio1 _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_polio1 _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_polio1 _t, sort lcolor(black)lpattern(dash) /// 
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Polio1", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin polio1 (4 semaines – 2 mois)", ///
span size(vsmall)) ///
legend(off)) 
graph save timing_polio1_0_36,replace
graph use "timing_polio1_0_36.gph", play("transform_graph.grec") name("timing_polio1_0_36", replace)


*By HDSS
levelsof hdss_bis, local(levels) 
foreach l of local levels{
sts gen KM_polio1_`l' = s if hdss_bis=="`l'"
sts gen ub_polio1_`l'=ub(s) if hdss_bis=="`l'"
sts gen lb_polio1_`l'=lb(s) if hdss_bis=="`l'"
gen Complement_polio1_`l' = 1- KM_polio1_`l'
gen ub_c_polio1_`l' = 1- ub_polio1_`l' if hdss_bis=="`l'"
gen lb_c_polio1_`l' = 1- lb_polio1_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 1
su Complement_polio1_BF021, meanonly 
local max_BF021 = r(max) + 0.01
su Complement_polio1_BF021_nl, meanonly 
local max_BF021_nl = r(max)
su Complement_polio1_GM011, meanonly 
local max_GM011 = r(max)
su Complement_polio1_SN011, meanonly 
local max_SN011 = r(max) - 0.04
twoway   bar  upper _t if inrange(_t, 0.92, 2) , bcolor(gs14) barwidth (0.001) base(0) || ///
    (line ub_c_polio1_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///   /*Ouagadougou*/
    (line lb_c_polio1_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
    (line Complement_polio1_BF021 _t, sort lcolor(red) lpattern(dash)) || /// 
	(line ub_c_polio1_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// 
    (line lb_c_polio1_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
    (line Complement_polio1_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || /// 
	(line ub_c_polio1_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///   /*Farafenni*/
	(line lb_c_polio1_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
    (line Complement_polio1_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///    
	(line ub_c_polio1_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///  /*Niakhar*/
    (line lb_c_polio1_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
    (line Complement_polio1_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
	ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Polio1", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin polio1 (4 semaines – 2 mois)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
`max_GM011' 36 "Farafenni" `max_SN011' 24 "Niakhar", mlabsize(vsmall)  msymbol(i)

*graph save timing_polio1_by_hdss_0_24,replace
graph save timing_polio1_by_hdss_0_36,replace
graph use "timing_polio1_by_hdss_0_36.gph", play("transform_graph.grec") name("timing_polio1_by_hdss_0_36", replace)




*polio2
*for polio2 [8 semaines - 4 mois]
stset EventDate if echan==1 , id(concat_IndividualId) failure(polio2==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(polio2==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_polio2 = s
sts gen ub_polio2=ub(s)
sts gen lb_polio2=lb(s)
gen Complement_polio2 = 1- KM_polio2
gen ub_c_polio2 = 1- ub_polio2
gen lb_c_polio2 = 1- lb_polio2


twoway bar  upper _t if inrange(_t, 1.84, 4) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_polio2 _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_polio2 _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_polio2 _t, sort lcolor(black)lpattern(dash) /// 
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Polio2", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin polio2 (8 semaines - 4 mois)", ///
span size(vsmall)) ///
legend(off)) 
   
graph save timing_polio2_0_36,replace
graph use "timing_polio2_0_36.gph", play("transform_graph.grec") name("timing_polio2_0_36", replace)


*By HDSS
levelsof hdss_bis, local(levels) 
foreach l of local levels{
sts gen KM_polio2_`l' = s if hdss_bis=="`l'"
sts gen ub_polio2_`l'=ub(s) if hdss_bis=="`l'"
sts gen lb_polio2_`l'=lb(s) if hdss_bis=="`l'"
gen Complement_polio2_`l' = 1- KM_polio2_`l'
gen ub_c_polio2_`l' = 1- ub_polio2_`l' if hdss_bis=="`l'"
gen lb_c_polio2_`l' = 1- lb_polio2_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 1
su Complement_polio2_BF021, meanonly 
local max_BF021 = r(max)
su Complement_polio2_BF021_nl, meanonly 
local max_BF021_nl = r(max)
su Complement_polio2_GM011, meanonly 
local max_GM011 = r(max)
su Complement_polio2_SN011, meanonly 
local max_SN011 = r(max)
twoway  bar  upper _t if inrange(_t, 1.84, 4) , bcolor(gs14) barwidth (0.001) base(0) || ///
   (line ub_c_polio2_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///  /*Ouaga - Lotie*/
   (line lb_c_polio2_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
   (line Complement_polio2_BF021 _t, sort lcolor(red) lpattern(dash)) || ///  /*Ouaga - Non lotie*/
   (line ub_c_polio2_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// 
   (line lb_c_polio2_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
   (line Complement_polio2_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || /// 
   (line ub_c_polio2_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///   /*Farafenni*/
   (line lb_c_polio2_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
   (line Complement_polio2_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///    
   (line ub_c_polio2_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///   /*Niakhar*/
   (line lb_c_polio2_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
   (line Complement_polio2_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Polio2", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin polio2 (8 semaines - 4 mois)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
`max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)

*graph save timing_polio2_by_hdss_0_24,replace
graph save timing_polio2_by_hdss_0_36,replace
graph use "timing_polio2_by_hdss_0_36.gph", play("transform_graph.grec") name("timing_polio2_by_hdss_0_36", replace)



*measles
*for measles [9 mois– 12 mois]
stset EventDate if echan==1 , id(concat_IndividualId) failure(measles==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(measles==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_measles = s
sts gen ub_measles=ub(s)
sts gen lb_measles=lb(s)
gen Complement_measles = 1- KM_measles
gen ub_c_measles = 1- ub_measles
gen lb_c_measles = 1- lb_measles

capture drop upper
generate upper = 1

twoway  bar  upper _t if inrange(_t, 9, 12) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_measles _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_measles _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_measles _t, sort lcolor(black)lpattern(dash) /// 
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)24 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Rougeole", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la rougeole (9 mois– 12 mois)", ///
span size(vsmall)) ///
legend(off))   

graph save timing_measles_0_36,replace
graph use "timing_measles_0_36.gph", play("transform_graph.grec") name("timing_measles_0_36", replace)


*By HDSS
levelsof hdss_bis, local(levels) 
foreach l of local levels{
sts gen KM_measles_`l' = s if hdss_bis=="`l'"
sts gen ub_measles_`l'=ub(s) if hdss_bis=="`l'"
sts gen lb_measles_`l'=lb(s) if hdss_bis=="`l'"
gen Complement_measles_`l' = 1- KM_measles_`l'
gen ub_c_measles_`l' = 1- ub_measles_`l' if hdss_bis=="`l'"
gen lb_c_measles_`l' = 1- lb_measles_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 0.8
su Complement_measles_BF021, meanonly 
local max_BF021 = r(max)
su Complement_measles_BF021_nl, meanonly 
local max_BF021_nl = r(max)
su Complement_measles_GM011, meanonly 
local max_GM011 = r(max)
su Complement_measles_SN011, meanonly 
local max_SN011 = r(max)
twoway bar  upper _t if inrange(_t, 9, 12) , bcolor(gs14) barwidth (0.001) base(0)  || ///
  (line ub_c_measles_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///   /*Ouagadougou*/
  (line lb_c_measles_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
  (line Complement_measles_BF021 _t, sort lcolor(red) lpattern(dash)) || /// 
  (line ub_c_measles_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// 
  (line lb_c_measles_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
  (line Complement_measles_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || /// 
  (line ub_c_measles_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///   /*Farafenni*/
  (line lb_c_measles_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
  (line Complement_measles_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///    
  (line ub_c_measles_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///  /*Niakhar*/
  (line lb_c_measles_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
  (line Complement_measles_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Rougeole", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la rougeole (9 mois– 12 mois)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
`max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)

*graph save timing_measles_by_hdss_0_24,replace
graph save timing_measles_by_hdss_0_36,replace
graph use "timing_measles_by_hdss_0_36.gph", play("transform_graph.grec") name("timing_measles_by_hdss_0_36", replace)


*fièvre jaune
*for fièvre jaune [9 mois– 12 mois]
stset EventDate if echan==1, id(concat_IndividualId) failure(fj==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(fj==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_fj = s
sts gen ub_fj=ub(s)
sts gen lb_fj=lb(s)
gen Complement_fj = 1- KM_fj
gen ub_c_fj = 1- ub_fj
gen lb_c_fj = 1- lb_fj

capture drop upper
generate upper = 1

twoway  bar  upper _t if inrange(_t, 9, 12) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_fj _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_fj _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_fj _t, sort lcolor(black)lpattern(dash) /// 
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Fièvre jaune", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la fièvre jaune (9 mois– 12 mois)", ///
span size(vsmall)) ///
legend(off))   

graph save timing_fj_0_36,replace
graph use "timing_fj_0_36.gph", play("transform_graph.grec") name("timing_fj_0_36", replace)


*By HDSS
levelsof hdss_bis, local(levels) 
foreach l of local levels{
sts gen KM_fj_`l' = s if hdss_bis=="`l'"
sts gen ub_fj_`l'=ub(s) if hdss_bis=="`l'"
sts gen lb_fj_`l'=lb(s) if hdss_bis=="`l'"
gen Complement_fj_`l' = 1- KM_fj_`l'
gen ub_c_fj_`l' = 1- ub_fj_`l' if hdss_bis=="`l'"
gen lb_c_fj_`l' = 1- lb_fj_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 0.8
su Complement_fj_BF021, meanonly 
local max_BF021 = r(max)
su Complement_fj_BF021_nl, meanonly 
local max_BF021_nl = r(max)
su Complement_fj_GM011, meanonly 
local max_GM011 = r(max)
su Complement_fj_SN011, meanonly 
local max_SN011 = r(max)
twoway  bar  upper _t if inrange(_t, 9, 12) , bcolor(gs14) barwidth (0.001) base(0) || ///
  (line ub_c_fj_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///   /*Ouagadougou*/
  (line lb_c_fj_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
  (line Complement_fj_BF021 _t, sort lcolor(red) lpattern(dash)) || /// 
  (line ub_c_fj_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// 
  (line lb_c_fj_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
  (line Complement_fj_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || /// 
  (line ub_c_fj_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///   /*Farafenni*/
  (line lb_c_fj_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
  (line Complement_fj_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///    
  (line ub_c_fj_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///  /*Niakhar*/
  (line lb_c_fj_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
  (line Complement_fj_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
  ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%",labsize(vsmall)) ///
xlabel(0(3)36 ,labsize(vsmall)) ///
ytitle("Proportion d'enfants vaccinés" , size(small)) ///
xtitle("Age(mois)" , size(small)) ///
title("Fièvre jaune", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la fièvre jaune  (9 mois - 12 mois)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
`max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)

*graph save timing_fj_by_hdss__0_24,replace
graph save timing_fj_by_hdss__0_36,replace
graph use "timing_fj_by_hdss__0_36.gph", play("transform_graph.grec") name("timing_fj_by_hdss__0_36", replace)


*VAccination complète
stset EventDate if echan==1, id(concat_IndividualId) failure(complete==1) ///
origin(time DoB) time0(datebeg) scale(2629800000) ///
exit(complete ==1 time DoB+(31557600000*3)+212000000) 

*capture drop KM_`var' ub_`var' lb_`var' Complement_`var' ub_c_`var' lb_c_`var
sts gen KM_complete  = s
sts gen ub_complete =ub(s)
sts gen lb_complete =lb(s)
gen Complement_complete  = 1- KM_complete 
gen ub_c_complete  = 1- ub_complete 
gen lb_c_complete  = 1- lb_complete 

capture drop upper
generate upper = 1

twoway  bar  upper _t if inrange(_t, 11.99, 12) , bcolor(gs14) barwidth (0.001) base(0) || ///
       (line ub_c_complete _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line lb_c_complete _t, sort lwidth(thick)lpattern(solid) lcolor(cyan)) ///
       (line Complement_complete _t, sort lcolor(black)lpattern(dash) /// 
	   ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%" .9"90%" 1"100%",labsize(vsmall)) ///
	   xlabel(0(3)36 ,labsize(vsmall)) ///
	   ytitle("Proportion d'enfants vaccinés" , size(small)) ///
	   xtitle("Age(mois)" , size(small)) ///
	   title("Vaccination complète", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la fièvre jaune (9 mois– 12 mois)", ///
span size(vsmall)) ///
legend(off))   

graph save timing_complete_0_36,replace
graph use "timing_complete_0_36.gph", play("transform_graph.grec") name("timing_complete_0_36", replace)


*By HDSS
levelsof hdss_bis, local(levels) 
foreach l of local levels{
sts gen KM_complete_`l' = s if hdss_bis=="`l'"
sts gen ub_complete_`l'=ub(s) if hdss_bis=="`l'"
sts gen lb_complete_`l'=lb(s) if hdss_bis=="`l'"
gen Complement_complete_`l' = 1- KM_complete_`l'
gen ub_c_complete_`l' = 1- ub_complete_`l' if hdss_bis=="`l'"
gen lb_c_complete_`l' = 1- lb_complete_`l' if hdss_bis=="`l'"
}

capture drop upper
gen upper = 0.8
su Complement_complete_BF021, meanonly 
local max_BF021 = r(max)
su Complement_complete_BF021_nl, meanonly 
local max_BF021_nl = r(max)
su Complement_complete_GM011, meanonly 
local max_GM011 = r(max)
su Complement_complete_SN011, meanonly 
local max_SN011 = r(max)
twoway  bar  upper _t if inrange(_t, 11.99, 12) , bcolor(gs14) barwidth (0.001) base(0) || ///
  (line ub_c_complete_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///   /*Ouagadougou*/
  (line lb_c_complete_BF021 _t, sort lwidth(thick)lpattern(solid) lcolor(red%20)) ///
  (line Complement_complete_BF021 _t, sort lcolor(red) lpattern(dash)) || /// 
  (line ub_c_complete_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) /// 
  (line lb_c_complete_BF021_nl _t, sort lwidth(thick)lpattern(solid) lcolor(orange%20)) ///
  (line Complement_complete_BF021_nl _t, sort lcolor(orange) lpattern(dash)) || /// 
  (line ub_c_complete_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///   /*Farafenni*/
  (line lb_c_complete_GM011 _t, sort lwidth(thick)lpattern(solid) lcolor(blue%20)) ///
  (line Complement_complete_GM011 _t, sort lcolor(blue)lpattern(dash)) || ///    
  (line ub_c_complete_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///  /*Niakhar*/
  (line lb_c_complete_SN011 _t, sort lwidth(thick)lpattern(solid) lcolor(green%20)) ///
  (line Complement_complete_SN011 _t, sort lcolor(green)lpattern(dash) xscale(r(0 28)) legend(off) ///  
  ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%",labsize(vsmall)) ///
xlabel(0(3)36 ,labsize(vsmall)) ///
ytitle("Proportion d'enfants vaccinés" , size(small)) ///
xtitle("Age(mois)" , size(small)) ///
title("Vaccination complète", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la fièvre jaune  (9 mois - 12 mois)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
`max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)

*graph save timing_fj_by_hdss__0_24,replace
graph save timing_complete_by_hdss__0_36,replace
graph use "timing_complete_by_hdss__0_36.gph", play("transform_graph.grec") name("timing_complete_by_hdss__0_36", replace)
graph export "timing_complete_by_hdss__0_36.png", replace width(2000)
graph export "timing_complete_by_hdss__0_36.tif", replace width(2000)
graph export "timing_complete_by_hdss__0_36.pdf", replace 

use base_graphics_0_36_070621,clear
*use base_graphics_0_36_070621,clear
*save base_graphics_0_24,replace
save base_graphics_0_36_070621,replace


graph combine timing_bcg_0_24.gph timing_polio0_0_24.gph timing_polio1_0_24.gph  ///
,row(1) graphregion(color(white)) imargin(15 15 15 15)  note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))
graph export "polio0_polio1_polio2_hdss_0_36.png", replace width(2000)
graph export "polio0_polio1_polio2_hdss_0_36.tif", replace width(2000)
graph export "polio0_polio1_polio2_hdss_0_36.pdf", replace 


graph combine  timing_polio2_0_24.gph timing_fj_0_24.gph  timing_measles_0_24.gph  ///
,row(1) graphregion(color(white)) imargin(15 15 15 15)  note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))
graph export "bcg_fj_measles_hdss_0_36.png", replace width(2000)
graph export "bcg_fj_measles_hdss_0_36.tif", replace width(2000)
graph export "bcg_fj_measles_hdss_0_36.pdf", replace 

*By hdss
graph combine timing_bcg_by_hdss_0_36.gph timing_polio0_by_hdss_0_36.gph   ///
,row(1) graphregion(color(white)) imargin(15 15 15 15)  note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))
graph export "bcg_polio0_by_hdss_0_36.png", replace width(2000)
graph export "bcg_polio0_by_hdss_0_36.tif", replace width(2000)
graph export "bcg_polio0_by_hdss_0_36.pdf", replace 


graph combine  timing_polio1_by_hdss_0_36.gph timing_polio2_by_hdss_0_36.gph   ///
,row(1) graphregion(color(white)) imargin(15 15 15 15)  note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))
graph export "polio1_polio2_by_hdss_0_36.png", replace width(2000)
graph export "polio1_polio2_by_hdss_0_36.tif", replace width(2000)
graph export "polio1_polio2_by_hdss_0_36.pdf", replace 


graph combine  timing_fj_by_hdss__0_36.gph  timing_measles_by_hdss_0_36.gph  ///
,row(1) graphregion(color(white)) imargin(15 15 15 15)  note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))
graph export "fj_measles_by_hdss_0_36.png", replace width(2000)
graph export "fj_measles_by_hdss_0_36.tif", replace width(2000)
graph export "fj_measles_by_hdss_0_36.pdf", replace 



**Caractéristiques sociodémographiques
/*
capture drop hdss_period
egen hdss_period=group(hdss_1 period), label(hdss_period, replace)
*/

use base_graphics_0_36_070621,clear

* Recalculer l'âge de la mère
capture drop y3_mother_age_birth_bis
gen y3_mother_age_birth_bis =  cond(mother_age_birth==.,99, ///
                               cond(mother_age_birth<20,1, ///
							   cond(mother_age_birth>=20 & mother_age_birth<35,2,3)))
							   
label define lmother_age 99"Missing" 1"<20" 2"20 - 34 ans" 3"35ans&+", modify
label val y3_mother_age_birth_bis lmother_age

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*               Multivariate Analysis                                                         *                                     *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


*Complete vaccination
use base_vaccin_V1_des,clear
sort  concat_IndividualId EventDate EventCode
capture drop MO_education_bis
recode MO_education (0=0 "Non instruit") (1 2 = 1 "Instruit"),gen(MO_education_bis)


		 
sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


lab var datebeg "Date of beginning"


sort concat_IndividualId EventDate EventCode
cap drop lastrecord
qui by concat_IndividualId: gen lastrecord=_n==_N

cap drop lastrecord
qui by concat_IndividualId: gen lastrecord=(_n==_N) 
tab lastrecord
stset EventDate if echan==1, id(concat_IndividualId) failure(lastrecord==1)exit(time .) time0(datebeg) 


*** Create calendar time-varying covariate

forval num=2000/2019 {
display %20.0f clock("01Jan`num'","DMY")
}

cap drop calendar		
stsplit calendar, ///		
      at(1262304000000 ///
       1293926400000 ///
       1325462400000 ///
       1356998400000 ///
       1388534400000 ///
       1420156800000 ///
       1451692800000 ///
       1483228800000 ///
       1514764800000 ///
       1546387200000 ///
       1577923200000 ///
       1609459200000 ///
       1640995200000 ///
       1672617600000 ///
       1704153600000 ///
       1735689600000 ///
       1767225600000 ///
       1798848000000 ///
       1830384000000 ///
       1861920000000)




cap drop pyear 
recode calendar  (1262304000000=1 "2000") ///
       (1293926400000=2 "2001") ///
       (1325462400000=3  "2002") ///
       (1356998400000=4 "2003") ///
       (1388534400000=5 "2004") ///
       (1420156800000=6 "2005") ///
       (1451692800000=7 "2006") ///
       (1483228800000=8 "2007")  ///
       (1514764800000=9 "2008") ///
       (1546387200000=10 "2009") ///
       (1577923200000=11 "2010") ///
       (1609459200000=12 "2011") ///
       (1640995200000=13 "2012") ///
       (1672617600000=14 "2013") ///
       (1704153600000=15 "2014") ///
       (1735689600000=16 "2015") ///
       (1767225600000=17 "2016") ///
       (1798848000000=18 "2017") ///
       (1830384000000=19 "2018") ///
       (1861920000000=20 "2019"), gen(pyear)

	***correct lines with wrong value of censor_out and censo_death
	sort concat_IndividualId EventDate EventCode
	qui by concat_IndividualId: replace complete =0 if complete==1 & complete[_n+1]==1 & ///
	(pyear!=pyear[_n+1])
	
	sort concat_IndividualId EventDate EventCode
	qui by concat_IndividualId: replace good_vacc=0 if good_vacc==1 & good_vacc[_n+1]==1 & ///
	(pyear!=pyear[_n+1])

save base_vaccin_V1_des_T_1y,replace
XX

***Calcul de la variable sur l'etat de la vaccination du grand frère

*Création d'un fichier des frères ainés

use base_vaccin_V1_des_T_1y,clear
duplicates drop OsiblingId ,force
keep OsiblingId
rename OsiblingId concat_IndividualId  
drop if concat_IndividualId==""
merge 1:m concat_IndividualId using base_vaccin_V1_des_T_1y, keep (1 3) keepus (complete good_vacc)
replace complete=9 if _merge==1
replace good_vacc=9 if _merge==1
bys concat_IndividualId : egen complete_OS = max(complete)
bys concat_IndividualId : egen good_vacc_OS = max(good_vacc)

rename concat_IndividualId OsiblingId
duplicates drop OsiblingId ,force
save Osibling_file,replace


use base_vaccin_V1_des_T_1y,clear
*Etat de vaccin de l'ainés
sort OsiblingId
merge m:1 OsiblingId using Osibling_file, keep (1 3) keepus (complete_OS good_vacc_OS)

replace complete_OS = 3 if MigDeadO_interv_new==0
replace good_vacc_OS = 3 if MigDeadO_interv_new==0
capture drop complete_OS_bis
recode complete_OS (0 9 3 = 1 "Non") (1=2 "Oui"),gen(complete_OS_bis)

capture drop good_vacc_OS_bis
recode good_vacc_OS (0 9 3 = 1 "Non") (1=2 "Oui"), gen(good_vacc_OS_bis)
replace good_vacc_OS_bis = 1 if complete_OS_bis==1 & good_vacc_OS_bis==2


sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop incomplete
gen incomplete = 1 - complete			  			  				  
stset	EventDate if echan==1, id(concat_IndividualId) failure(complete==1) ///
        time0(datebeg) exit(complete==1 time DoB+(31557600000*3)+212000000) ///
		origin(time DoB) scale(31557600000)

/*
log using model_1_ensemble,replace
*M0
stcox ib2.typo_2 if nomiss==1, vce(cluster MotherId) iter(10)
*M1
stcox ib2.typo_2  ib0.nsib_cat  ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new i.gender ib1.saison_naiss i.twin if nomiss==1 ///
, vce(cluster MotherId) iter(10)

*M2
stcox ib2.typo_2 ib0.nsib_cat ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ///
i.gender ib1.saison_naiss i.twin ib1.y3_mother_age_birth_bis i.MO_education_bis ///
 if nomiss==1 ///
, vce(cluster MotherId) iter(10)
*M2
stcox ib2.typo_2 ib0.nsib_cat ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new i.gender i.twin ib1.saison_naiss  ///
ib1.y3_mother_age_birth_bis i.MO_education_bis  ib11.hdss_period ///
if nomiss==1, vce(cluster MotherId) iter(10)
log close
*/

*******************Par HDSS
*labelisation
*Senegal

label define lethnie -1"Le répondant ne sait pas" ///
                     -5"Autres - Sort du cadre prévu" ///
                      1"BAMBARA" ///
                      2"BASSARI" ///
                      3"DIOLA" ///
                      4"LAOBE" ///
                      5"LEBOU" ///
                      15"LIBANO-SYRIEN" ///
                      6"MANJAQUE" ///
                      7"MAURE" ///
                      8"PEULH" ///
                      9"SARAKHOLE" ///
                      10"SERERE" ///
                      11"SOCE-MANDINGUE" ///
                      12"SOUSSOU" ///
                      13"TOUCOULEUR" ///
                      14"WOLOF", modify

					  label val ethnie lethnie
label define lRESI_cd_smat 1"Célibataire" ///
                           2 "Veuf, veuve" ///
						   3"Divorcé(e)" ///
						   4"Marié(e)", modify
						   
label val RESI_cd_smat lRESI_cd_smat
capture drop sit_mat_SN011
recode RESI_cd_smat (4 = 1 "Mariées") (-1 0 1 2 3 = 0 "Non mariées"),gen(sit_mat_SN011)
capture drop ethnie_SN011
recode ethnie (-1 -5 1 2 3 4 5 15 6 7 8 9 11 12 13 14 = 0 "Non sérères") (10 = 1 "Sérères"),gen(ethnie_SN011)


**Ouagadougou
capture drop niv_vie_BF021
recode niv_vie (1=1 "Pauvre") (2 3 = 0 "Non Pauvre"),gen(niv_vie_BF021)

capture drop relig_BF021
recode religion (0 2 9 =0 "Non catholique") (1 = 1 "Catholique"),gen(relig_BF021)
rename ethnic ethnie_BF021
capture drop sit_mat_BF021
recode marital_st (2 = 1 "Mariées") (1 3 4 = 0 "Non mariées"),gen(sit_mat_BF021)

capture drop zd
gen zd = substr(locationid,1,6) if hdss=="BF021"

merge m:1 zd using zd, keep (1 3) keepus (type_zone) gen(mer_tz1)
count if hdss=="BF021" & type_zone==.
label define type_zone 1"lotie" 2"Non lotie",modify
label val type_zone type_zone

*Modifications 07062021 

replace pyear = 18 if pyear==19 & hdss=="BF021"
replace pyear = 19 if pyear==20 & hdss=="GM011"

** Ouagadougou
/*
log using ouaga_result_07052021,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ///
i.gender i.twin ib1.saison_naiss ///
ib1.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
i.ethnie_BF021  i.niv_vie_BF021 i.relig_BF021 ///
if nomiss==1 & hdss=="BF021" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close
*/

*replace pyear =38 if pyear==37 & hdss=="BF021"

*Choisir l'année de référence (selon la méthode de Philippe)
capture drop hdss_bis 
gen hdss_bis = hdss

replace hdss_bis = "BF021_nl" if type_zone==2


sort  concat_IndividualId EventDate EventCode

**Modif YaC 28052021 - 060621 (après discussion - PhB)
capture drop incomplete
gen incomplete = 1 - complete			  			  				  
stset	EventDate if echan==1, id(concat_IndividualId) failure(complete==1) ///
        time0(datebeg) exit(complete==1 time DoB+(31557600000*3)+212000000) ///
		origin(time DoB) scale(31557600000)

capture drop nomiss
gen nomiss = (typo_2!=.& nsib_cat!=.& MigDeadY_interv_new!=. & ///
         MigDeadO_interv_new!=. & gender!=.& saison_naiss!=.& ///
		 twin!=.& y3_mother_age_birth_bis!=.& MO_education!=.& hdss_period!=.)

log using stat_des_bis,replace 

*bys typo_2 : stdes if nomiss==1
bys typo_2 : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys typo_2 : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys typo_2 : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys typo_2 : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/



*bys nsib_cat : stdes if nomiss==1
bys nsib_cat : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys nsib_cat : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys nsib_cat : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys nsib_cat : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/


*bys MigDeadY_interv_new : stdes if nomiss==1
bys MigDeadY_interv_new : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys MigDeadY_interv_new : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys MigDeadY_interv_new : stdes if hdss_1==3  & nomiss==1 /*Farafenni*/
bys MigDeadY_interv_new : stdes if hdss_1==4  & nomiss==1 /*Niakhar*/


*bys MigDeadO_interv_new : stdes if nomiss==1
bys MigDeadO_interv_new : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys MigDeadO_interv_new : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys MigDeadO_interv_new : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys MigDeadO_interv_new : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/


*bys gender : stdes if nomiss==1
bys gender : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys gender : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys gender : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys gender : stdes if hdss_1==4  & nomiss==1 /*Niakhar*/



*bys saison_naiss : stdes if nomiss==1
bys saison_naiss : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys saison_naiss : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys saison_naiss : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys saison_naiss : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/


*bys twin : stdes if nomiss==1
bys twin : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys twin : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys twin : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys twin : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/


*bys y3_mother_age_birth_bis : stdes if nomiss==1
bys y3_mother_age_birth_bis : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys y3_mother_age_birth_bis : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys y3_mother_age_birth_bis : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys y3_mother_age_birth_bis : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/

*bys MO_education_bis :  stdes if nomiss==1
bys MO_education_bis : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys MO_education_bis : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys MO_education_bis : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys MO_education_bis : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/

*bys complete_OS_bis :  stdes if nomiss==1
bys complete_OS_bis : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys complete_OS_bis : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys complete_OS_bis : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys complete_OS_bis : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/

*bys good_vacc_OS_bis :  stdes if nomiss==1
bys good_vacc_OS_bis : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys good_vacc_OS_bis : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys good_vacc_OS_bis : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys good_vacc_OS_bis : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/

*bys sit_mat_BF021 : stdes if nomiss==1
bys sit_mat_BF021 : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys sit_mat_BF021 : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
*bys sit_mat_BF021 : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys sit_mat_SN011 : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/

*bys pyear : stdes if nomiss==1
bys pyear : stdes if hdss_1==1 & type_zone==1 & nomiss==1  /*Ouagadougou (Lotie)*/ 
bys pyear : stdes if hdss_1==1 & type_zone==2 & nomiss==1  /*Ouagadougou (Non lotie)*/
bys pyear : stdes if hdss_1==3 & nomiss==1 /*Farafenni*/
bys pyear : stdes if hdss_1==4 & nomiss==1 /*Niakhar*/

log close


log using rate_pyear	
levelsof hdss_bis, local(levels) 
foreach l of local levels {
stset EventDate if echan==1 & hdss_bis=="`l'", id(concat_IndividualId) failure(complete==1) origin(time DoB) ///
time0(datebeg) scale(2629800000)exit(complete==1 time DoB + (31557600000*3)+212000000)
sts list,  at(0 36) by(pyear) failure  saving("`l'", replace)
*sts graph, xlabel(0(5)60)
}
log close


*use base_vaccin_V1_des_bis_Year,clear

capture drop incomplete
gen incomplete = 1 - complete			  			  				  
stset	EventDate if echan==1, id(concat_IndividualId) failure(complete==1) ///
        time0(datebeg) exit(complete==1 time DoB+(31557600000*3)+212000000) ///
		origin(time DoB) scale(31557600000)



log using ouaga_result_060621,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ib1.complete_OS_bis ///
i.gender i.twin ib10.pyear ///
ib1.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="BF021" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close
estimates store ouaga
/*
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ib1.complete_OS_bis ///
i.gender i.twin ib10.pyear ///
ib1.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="GM011"  &  y3_mother_age_birth_bis!=99, shared(MotherId) forceshared iter(10)
*/


* Ouaga lotie (2017 - 0.5162 )
log using ouaga_result_060621_lotie,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ib1.complete_OS_bis ///
i.gender i.twin ib16.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="BF021" & type_zone==1 &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store ouaga_lotie

*Ouaga non lotie (2017 -  0.4407 )
log using ouaga_result_060621_non_lotie,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ib1.complete_OS_bis ///
i.gender i.twin ib16.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="BF021" & type_zone==2 &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store ouaga_non_lotie


**Farafenni
capture drop ethnieMO_1
encode ethnieMO,gen(ethnieMO_1)
capture drop ethnie_GM011
recode ethnieMO_1 (1 = 1 "Fula") (2 = 2 "Mandinka") (5 = 0 "Wolof") (3 4 = 3 "Autres"),gen(ethnie_GM011)
capture drop ethnie_GM011_bis 
gen ethnie_GM011_bis = (ethnieMO_1==5)
label define lethnie_GM011_bis 1"Wolof" 0"Autres",modify
label val ethnie_GM011_bis lethnie_GM011_bis 

/*
log using farafenni_result_07052021,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ///
i.gender i.twin ib1.saison_naiss ///
ib1.y3_mother_age_birth_bis i.MO_education_bis i.ethnie_GM011 ///
if nomiss==1 & hdss=="GM011" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close
*/

*Farafenni (2018 - 0.4705)
log using farafenni_result_060621,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ib1.complete_OS_bis ///
i.gender i.twin ib6.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  ///
if nomiss==1 & hdss=="GM011" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close
estimates store farafenni

/*
**Niakhar
log using niakhar_result_07052021,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new i.gender i.twin ib1.saison_naiss  ///
ib1.y3_mother_age_birth_bis i.MO_education_bis i.sit_mat_SN011 i.ethnie_SN011 ///
if nomiss==1 & hdss=="SN011" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close
*/

**Niakhar (2003 :  0.4799)
log using niakhar_result_060621,replace
stcox ib2.typo_2 ib0.nsib_cat_bis ib0.MigDeadY_interv_new ib0.MigDeadO_interv_new ib1.complete_OS_bis i.gender i.twin ib12.pyear  ///
ib2.y3_mother_age_birth_bis i.MO_education_bis i.sit_mat_SN011 ///
if nomiss==1 & hdss=="SN011" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store niakhar

*Graphiques
estimates replay ouaga
matrix list e(b)

coefplot ouaga, bylabel(Ouagadougou)  ///
|| farafenni, bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  xline(1, lwidth(vthin) lcolor(black))  byopts(row(1)) ///
 keep (1.typo_2  3.typo_2  4.typo_2 5.typo_2 1.nsib_cat_bis 2.nsib_cat_bis ///
       3.nsib_cat_bis 3.MigDeadY_interv_new 4.MigDeadY_interv_new ///
	   3.MigDeadO_interv_new 4.MigDeadO_interv_new) ///
	   mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
	   coeflabels( ///
			1.typo_2="Famille monoparentale" ///
			3.typo_2="Famille multigénérationelle" ///
			4.typo_2="Famille étendue horizontale" ///
			5.typo_2="Famille complexe" ///
			1.nsib_cat_bis="1 enfant" ///
			2.nsib_cat_bis="2 enfants" ///
			3.nsib_cat_bis="3 enfants et plus" ///
			3.MigDeadY_interv_new="Y int <18m" ///
			4.MigDeadY_interv_new="Y int >18m" ///
			3.MigDeadO_interv_new="O int <18m" ///
			4.MigDeadO_interv_new="O int >18m" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		1.typo_2=`""{bf: Structure familiale}" 	"Ref: Famille biparentale""' ///
		1.nsib_cat_bis=`""{bf:Nombre enfants résidents}" 	"Ref: Aucun""' ///
		 3.MigDeadY_interv_new=`""{bf:Présence enfant suivant}" 	"Ref: Aucun""' ///
		3.MigDeadO_interv_new=`""{bf:Présence enfant précédent}" 	"Ref: Aucun""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio (échelle logarithmique), size(medsmall)) xlabel(0.2 "0.2" 0.5"0.5" 1"1.0" 2"2.0" 3"3.0") xscale(log range(0.2 3)) baselevels levels(95) 
 
 
graph save complete_vacc,replace

graph export "complete_vacc.png", replace width(2000)
graph export "complete_vacc.tif", replace width(2000)
graph export "complete_vacc.pdf", replace 


***Avec Ouaga_lotie non_lotie
coefplot ouaga_lotie, bylabel(Ouaga - lotie)  ///
|| ouaga_non_lotie, bylabel(Ouaga - Non lotie) ///
|| farafenni, bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  xline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(1)) ///
 keep (1.typo_2  3.typo_2  4.typo_2 5.typo_2 1.nsib_cat_bis 2.nsib_cat_bis ///
       3.nsib_cat_bis 3.MigDeadY_interv_new 4.MigDeadY_interv_new ///
	   3.MigDeadO_interv_new 4.MigDeadO_interv_new) ///
	   mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
	   coeflabels( ///
			1.typo_2="Famille monoparentale" ///
			3.typo_2="Famille multigénérationelle" ///
			4.typo_2="Famille étendue horizontale" ///
			5.typo_2="Famille complexe" ///
			1.nsib_cat_bis="1 enfant" ///
			2.nsib_cat_bis="2 enfants" ///
			3.nsib_cat_bis="3 enfants et plus" ///
			3.MigDeadY_interv_new="Y int <18m" ///
			4.MigDeadY_interv_new="Y int >18m" ///
			3.MigDeadO_interv_new="O int <18m" ///
			4.MigDeadO_interv_new="O int >18m" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		1.typo_2=`""{bf: Structure familiale}" 	"Ref: Famille biparentale""' ///
		1.nsib_cat_bis=`""{bf:Nombre enfants résidents}" 	"Ref: Aucun""' ///
		 3.MigDeadY_interv_new=`""{bf:Présence enfant suivant}" 	"Ref: Aucun""' ///
		3.MigDeadO_interv_new=`""{bf:Présence enfant précédent}" 	"Ref: Aucun""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio, size(medsmall)) levels(95) 
 
 
graph save complete_vacc,replace

graph export "complete_vacc.png", replace width(2000)
graph export "complete_vacc.tif", replace width(2000)
graph export "complete_vacc.pdf", replace 


**Effets de la structure familiale

***Avec Ouaga_lotie non_lotie
coefplot ouaga_lotie, bylabel(Ouaga - lotie)  ///
|| ouaga_non_lotie, bylabel(Ouaga - Non lotie) ///
|| farafenni, bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  xline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2)) ///
 keep (1.typo_2  3.typo_2  4.typo_2 5.typo_2) ///
	   mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
	   coeflabels( ///
			1.typo_2="Famille monoparentale" ///
			3.typo_2="Famille multigénérationelle" ///
			4.typo_2="Famille étendue horizontale" ///
			5.typo_2="Famille complexe" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		1.typo_2=`""{bf: Structure familiale}" 	"Ref: Famille biparentale""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio, size(small)) levels(95) 
 
graph save complete_vacc_family_structure,replace

graph export "complete_vacc_family_structure.png", replace width(2000)
graph export "complete_vacc_family_structure.tif", replace width(2000)
graph export "complete_vacc_family_structure.pdf", replace 


*Dilution et competition

coefplot ouaga_lotie, bylabel(Ouaga - lotie)  ///
|| ouaga_non_lotie, bylabel(Ouaga - Non lotie) ///
|| farafenni, bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  yline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2) ///
title("Dilution des ressources", box bcolor(cyan) blcolor(magenta) bmargin(medium))) vertical ///
 keep (1.nsib_cat_bis 2.nsib_cat_bis ///
       3.nsib_cat_bis) ///
	   mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
	   coeflabels( ///
			1.nsib_cat_bis="1 enfant" ///
			2.nsib_cat_bis="2 enfants" ///
			3.nsib_cat_bis="3 enfants et plus" ///
			, notick labsize(small) labcolor(purple)  labgap(2) angle(45)) ///
 eform ytitle(Hazards Ratio, size(small)) ///
 xtitle("{bf:Nombre enfants résidents (Ref: Aucun)}", size(small) color(blue) ) ///
 levels(95) 
 
graph save dilution,replace
graph export "dilution.png", replace width(2000)
graph export "dilution.tif", replace width(2000)
graph export "dilution.pdf", replace 

**Compétition
***Avec Ouaga_lotie non_lotie
coefplot ouaga_lotie, bylabel(Ouaga - lotie)  ///
|| ouaga_non_lotie, bylabel(Ouaga - Non lotie) ///
|| farafenni, bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  xline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2) ///
title("Compétition pour les ressources", box bcolor(cyan) blcolor(magenta) bmargin(medium))) ///
 keep (3.MigDeadY_interv_new 4.MigDeadY_interv_new ///
	   3.MigDeadO_interv_new 4.MigDeadO_interv_new) ///
	   mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
	   coeflabels( ///
			3.MigDeadY_interv_new="Y int <18m" ///
			4.MigDeadY_interv_new="Y int >18m" ///
			3.MigDeadO_interv_new="O int <18m" ///
			4.MigDeadO_interv_new="O int >18m" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		 3.MigDeadY_interv_new=`""{bf:Cadet}" 	"Ref: Aucun""' ///
		3.MigDeadO_interv_new=`""{bf:Ainé}" 	"Ref: Aucun""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio, size(small)) levels(95) 

graph save competition,replace
graph export "competition.png", replace width(2000)
graph export "competition.tif", replace width(2000)
graph export "competition.pdf", replace 

graph combine dilution.gph competition.gph, col(2) 

graph save dilution_competition,replace 
graph export "dilution_competition.png", replace width(2000)
graph export "dilution_competition.tif", replace width(2000)
graph export "dilution_competition.pdf", replace 

save base_vaccin_V1_des_bis_Year, replace



*Delay vaccination
use base_vaccin_V1_des_bis_Year,clear

sort concat_IndividualId EventDate
bys concat_IndividualId : egen complete_bis = max(complete)

*drop if complete_bis ==0
		  			  				  
stset	EventDate if echan==1, id(concat_IndividualId) failure(good_vacc==1) ///
        time0(datebeg) exit(good_vacc==1 time DoB+(31557600000)+212000000) ///
		origin(time DoB) scale(31557600000)
	

		


log using ouaga_result_23052021_delay,replace
stcox ib2.typo_2 ib0.nsib_cat_bis  ib0.MigDeadO_interv_new ib1.good_vacc_OS_bis ///
i.gender i.twin ib10.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="BF021" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close
estimates store ouaga_delay

log using ouaga_result_23052021_delay_lotie,replace
stcox ib2.typo_2 ib0.nsib_cat_bis  ib0.MigDeadO_interv_new ib1.good_vacc_OS_bis ///
i.gender i.twin ib10.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="BF021" & type_zone==1 &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store ouaga_lotie_delay

log using ouaga_result_23052021_delay_non_lotie,replace
stcox ib2.typo_2 ib0.nsib_cat_bis  ib0.MigDeadO_interv_new ib1.good_vacc_OS_bis ///
i.gender i.twin ib10.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  i.sit_mat_BF021  ///
if nomiss==1 & hdss=="BF021" & type_zone==2 & y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store ouaga_non_lotie_delay
**Farafenni

log using farafenni_result_23052021_3_delay,replace
stcox ib2.typo_2 ib0.nsib_cat_bis  ib0.MigDeadO_interv_new ib1.good_vacc_OS_bis ///
i.gender i.twin ib1.pyear ///
ib2.y3_mother_age_birth_bis i.MO_education_bis  ///
if nomiss==1 & hdss=="GM011" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store farafenni_delay

**Niakhar
log using niakhar_result_23052021_3_delay,replace
stcox ib2.typo_2 ib0.nsib_cat_bis  ib0.MigDeadO_interv_new ib1.good_vacc_OS_bis i.gender i.twin ib1.pyear  ///
ib2.y3_mother_age_birth_bis i.MO_education_bis i.sit_mat_SN011 ///
if nomiss==1 & hdss=="SN011" &  y3_mother_age_birth_bis!=99, vce(cluster MotherId) iter(10)
log close

estimates store niakhar_delay

estimates replay niakhar_delay
matrix list e(b)
estimates replay niakhar


***Avec Ouaga_lotie non_lotie
coefplot (ouaga_lotie , label(Vaccination complète) offset(.14)) (ouaga_lotie_delay , label(Respect du calendier vaccinal) offset(-.14)), bylabel(Ouaga - lotie)  ///
|| (ouaga_non_lotie, offset(.14)) (ouaga_non_lotie_delay ,offset(-.14)), bylabel(Ouaga - Non lotie) ///
|| (farafenni, offset(.14)) (farafenni_delay, offset(-.14)), bylabel(Farafenni) ///
|| (niakhar, offset(.14)) (niakhar_delay, offset(-.14) drop(5.typo_2)), bylabel(Niakhar)  ///
||, xline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2)) ///
 keep (1.typo_2  3.typo_2  4.typo_2 5.typo_2) ///
	   coeflabels( ///
			1.typo_2="Monoparentale" ///
			3.typo_2="Multigénérationelle" ///
			4.typo_2="Etendue horizontale" ///
			5.typo_2="Complexe" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		1.typo_2=`""{bf: Structure familiale}" 	"Ref: Biparentale""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio (échelle logarithmique), size(small)) ///
  xlabel(0.1 "0.1" 0.2 "0.2" 0.5"0.5" 1"1.0" 2"2.0" 3"3.0") ///
 xscale(log axis(1))  levels(95) ///
 legend(rows(1) position (12))
 
graph save complete_vacc_family_structure_c_d,replace

graph export "complete_vacc_family_structure_c_d.png", replace width(2000)
graph export "complete_vacc_family_structure_c_d.tif", replace width(2000)
graph export "complete_vacc_family_structure_c_d.pdf", replace 

 *eform xtitle(Hazards Ratio (échelle logarithmique), size(medsmall)) xlabel(0.2 "0.2" 0.5"0.5" 1"1.0" 2"2.0" 3"3.0") xscale(log range(0.2 3)) baselevels levels(95) 

*XX A compléter après le sport

*Dilution et competition

coefplot (ouaga_lotie , label(Vaccination complète) offset(.04)) (ouaga_lotie_delay , label(Respect du calendier vaccinal) offset(-.04)), bylabel(Ouaga - lotie)  ///
|| (ouaga_non_lotie, offset(.04)) (ouaga_non_lotie_delay ,offset(-.04)), bylabel(Ouaga - Non lotie) ///
|| (farafenni, offset(.04)) (farafenni_delay, offset(-.04)), bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  yline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2)) ///
  vertical ///
 keep (1.nsib_cat_bis 2.nsib_cat_bis ///
       3.nsib_cat_bis) ///
	   coeflabels( ///
			1.nsib_cat_bis="1 enfant" ///
			2.nsib_cat_bis="2 enfants" ///
			3.nsib_cat_bis="3 enfants et plus" ///
			, notick labsize(small) labcolor(purple)  labgap(2) angle(45)) ///
 eform ytitle(Hazards Ratio (échelle logarithmique), size(small)) ///
 xtitle("{bf:Nombre enfants résidents (Ref: Aucun)}", size(small) color(blue) ) ///
   ylabel(0.5"0.5" 1"1.0" 2"2.0" 2.5"2.5") ///
 levels(95) yscale(log axis(1)) legend(rows(1) position (12))
 
graph save dilution_cp_d,replace
graph export "dilution_cp_d.png", replace width(2000)
graph export "dilution_cp_d.tif", replace width(2000)
graph export "dilution_cp_d.pdf", replace 

**Compétition
***Avec Ouaga_lotie non_lotie
coefplot (ouaga_lotie , label(Vaccination complète) offset(.14)) (ouaga_lotie_delay , label(Respect du calendier vaccinal) offset(-.14)), bylabel(Ouaga - lotie)  ///
|| (ouaga_non_lotie, offset(.14)) (ouaga_non_lotie_delay ,offset(-.14)), bylabel(Ouaga - Non lotie) ///
|| (farafenni, offset(.14)) (farafenni_delay, offset(-.14)), bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  xline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2) xrescale) ///
 keep (3.MigDeadY_interv_new 4.MigDeadY_interv_new ///
	   3.MigDeadO_interv_new 4.MigDeadO_interv_new) ///
	   coeflabels( ///
			3.MigDeadY_interv_new="Y int <18m" ///
			4.MigDeadY_interv_new="Y int >18m" ///
			3.MigDeadO_interv_new="O int <18m" ///
			4.MigDeadO_interv_new="O int >18m" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		 3.MigDeadY_interv_new=`""{bf:Cadet}" 	"Ref: Aucun""' ///
		3.MigDeadO_interv_new=`""{bf:Ainé}" 	"Ref: Aucun""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio (échelle logarithmique), size(small)) levels(95) xscale(log axis(1)) legend(rows(1) position (12))

graph save competition_cp_d,replace
graph export "competition_cp_d.png", replace width(2000)
graph export "competition_cp_d.tif", replace width(2000)
graph export "competition_cp_d.pdf", replace 

**Statut vaccinal
coefplot (ouaga_lotie , label(Vaccination complète) offset(.14)) (ouaga_lotie_delay , label(Respect du calendier vaccinal) offset(-.14)), bylabel(Ouaga - lotie)  ///
|| (ouaga_non_lotie, offset(.14)) (ouaga_non_lotie_delay ,offset(-.14)), bylabel(Ouaga - Non lotie) ///
|| (farafenni, offset(.14)) (farafenni_delay, offset(-.14)), bylabel(Farafenni) ///
|| niakhar, bylabel(Niakhar) ///
||,  xline(1, lwidth(vthin) lcolor(black)) omitted byopts(row(2)) ///
 keep (2.complete_OS_bis  2.good_vacc_OS_bis) ///
	   coeflabels( ///
			2.complete_OS_bis="complet" ///
			2.good_vacc_OS_bis="respecté" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		2.complete_OS_bis=`""{bf : Vaccination }" "{bf : complete}" "Ref: Non complet""' ///
		2.good_vacc_OS_bis=`""{bf : Calendrier}" "{bf : vaccinal}"	"Ref: non respecté""' ///
		, labcolor(blue)) ///
 eform xtitle(Hazards Ratio, size(small)) levels(95) legend(rows(1) position (12))
 
graph save vaccin_OS,replace 
graph export "vaccin_OS.png", replace width(2000)
graph export "vaccin_OS.tif", replace width(2000)
graph export "vaccin_OS.pdf", replace 




graph combine dilution_cp_d.gph competition_cp_d.gph , col(2) 

graph save dilution_competition_c_d,replace 
graph export "dilution_competition_c_d.png", replace width(2000)
graph export "dilution_competition_c_d.tif", replace width(2000)
graph export "dilution_competition_c_d.pdf", replace 

use base_pyear.dta,clear

capture drop upper
gen upper = 1
label var upper "année de référence (50%)"

twoway (line ouagalotie year, sort lpattern(dash) lcolor(red)) || ///
       (line ouaganonlotie year, sort lcolor(orange) lpattern(dash)) || ///
	   (line farafenni year, sort lpattern(dash) lcolor(blue)) || ///
       (line niakhar year, sort lpattern(dash) lcolor(green) legend(rows(1) position (12)) ///
	     ylab( 0"0" 0.5"0.5" 1"1" 1.5"1.5"  2"2" 2.5"2.5" 3"3" ,labsize(vsmall)) ///
         xlabel(2000(1)2018 ,labsize(vsmall)) ///
		 xtitle("Années" , size(small)))  || ///
     (line upper year , sort lpattern(dash) lcolor(gs14)) 
		 		
graph save graph_anne,replace 
graph export "graph_anne.png", replace width(2000)
graph export "graph_anne.tif", replace width(2000)
graph export "graph_anne.pdf", replace 
