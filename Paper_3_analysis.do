********************************************************************************
************** Paper 3 -  do-file****
/*
use residency_final_5HDSS_res,clear

*modify
drop if socialgpid=="."
drop if socialgpid==""
drop if socialgpid==" "
tostring hdss, replace

*Modif 210420
gen hdss_1 =""
replace hdss_1 = "GM011" if  hdss==1
replace hdss_1 = "BF041" if  hdss==2
replace hdss_1 = "BF021" if  hdss==3
replace hdss_1 = "SN011" if  hdss==4
replace hdss_1 = "SN012" if  hdss==5

drop hdss
rename hdss_1 hdss
capture drop concat_IndividualId 
egen concat_IndividualId = concat(hdss IndividualId)
duplicates drop concat_IndividualId,force

rename concat_IndividualId MotherId
rename DoB DoB_mother
save residency_final_5HDSS_unique,replace
*/
use child_network_sibling_sahel_011120.dta,clear

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


sort concat_IndividualId EventDate EventCode
cap drop censor_death
gen byte censor_death=(EventCode==7) 
stset EventDate, id(concat_IndividualId) failure(censor_death==1) ///
			time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)



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



*(1) Sélectionner les enfants nés sous surveillance
sort  concat_IndividualId EventDate EventCode
drop if EventDate < DoB
capture drop birth birth1
gen birth = EventCode==2
bysort concat_IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0
bys concat_IndividualId (EventDate): drop if  EventCode==2 & EventCode[_n-1]==2
bys concat_IndividualId (EventDate) : drop if  EventCode==3 & EventCode[_n-1]==3
bys concat_IndividualId (EventDate): drop if  EventCode==4 & EventCode[_n-1]==4
bys concat_IndividualId (EventDate): drop if  EventCode==5 & EventCode[_n-1]==5
bys concat_IndividualId (EventDate) : drop if  EventCode==6 & EventCode[_n-1]==6

sort hdss concat_IndividualId EventDate 

*(2) Supprimer les doublons
capture drop dup_e
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId socialgpId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1
sort concat_IndividualId EventDate
bys concat_IndividualId : replace EventCode=9 if _n==_N


sort MotherId
merge m:1 MotherId using residency_final_5HDSS_unique,keep(1 3)keepus(DoB_mother)

gen double DoB_mother_1 = cofd(DoB_mother)
format DoB_mother_1 %tc
drop DoB_mother 
rename DoB_mother_1 DoB_mother

replace DoBMO = DoB_mother if DoBMO==.


capture drop lastrecord
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 

sort hdss IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double ///
datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


*Subdiviser les périodes jusqu'au décès de la mère
* Create date of death of the mother
capture drop DoDMO_1
gen double DoDMO_1  = cofd(DoDMO)
format DoDMO_1 %tc

* Harmoniser les dates
foreach w of varlist DoDMO_1{
gen double `w'_1 = dofc(`w')
format `w'_1 %td
drop `w' 
rename `w'_1 `w'
}


foreach w of varlist DoDMO_1{
gen double `w'_1 = cofd(`w')
format `w'_1 %tc
drop `w' 
rename `w'_1 `w'
}



capture drop m_death
gen m_death = (EventDate==DoDMO_1)
*XX
sort concat_IndividualId EventDate EventCode
capture drop duplicated
expand 2 if m_death==1, gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}
* Replace with date 3 months before death
display %20.0f 30.458333*24*60*60*1000*3 // 3 months in milliseconds  7889400000 15778800000
bys concat_IndividualId : replace EventDate=(DoDMO_1 - 7894799914) if duplicated==1
* Replace code 
bys concat_IndividualId : replace EventCode=18 if duplicated==1
bys concat_IndividualId : replace EventCodeMO=81 if duplicated==1
replace residenceMO=1 if EventCodeMO==81

sort concat_IndividualId EventDate EventCode
bys concat_IndividualId (EventDate EventCode): replace residenceMO=residenceMO[_n+1] ///
		if EventCodeMO==81 & EventCodeMO[_n+1]!=7

**Create an extra line 6 month after mother's death 
capture drop m_death
gen m_death = (EventDate==DoDMO_1)

sort concat_IndividualId EventDate
capture drop duplicated
expand 2 if m_death==1,gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}


bys concat_IndividualId : replace EventDate=(DoDMO_1 + 15778800000) if duplicated==1
bys concat_IndividualId : replace EventCode=18 if duplicated==1
bys concat_IndividualId : replace EventCodeMO=89 if duplicated==1

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 81 "-3mDTH" 89 "+6mDTH" 9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
drop duplicated
replace residenceMO=0 if EventCodeMO==89


* Harmoniser les dates
foreach w of varlist DoDMO_1{
gen double `w'_1 = dofc(`w')
format `w'_1 %td
drop `w' 
rename `w'_1 `w'
}


foreach w of varlist DoDMO_1{
gen double `w'_1 = cofd(`w')
format `w'_1 %tc
drop `w' 
rename `w'_1 `w'
}



capture drop datebeg
sort concat_IndividualId EventDate 
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop censort_DTH6MO
gen censort_DTH6MO = (EventCodeMO==89)
label var censort_DTH6MO "6 month after mother death"

capture drop m_death_bis
bys concat_IndividualId : egen m_death_bis = max(m_death)
stset EventDate if m_death_bis==1  ///
, id(concat_IndividualId) failure(censort_DTH6MO==1) time0(datebeg) ///
				origin(time DoDMO_1-7889400000) scale(2629800000) 
				

capture drop mdth3m_3m_6m
stsplit mdth3m_3m_6m , at(0 3 6)
replace mdth3m_3m_6m=8 if mdth3m_3m_6m==. & EventDate>DoDMO_1
stset, clear
drop censort_DTH6MO
capture drop MO_DTH_TVC
recode mdth3m_3m_6m (0=1 "-3m before MO DTH")(3=2 "0 to 3m after MO DTH") ///
			(6 = 3 "3m to 6m after MO DTH") (8=4 "6m&+ MO DTH") (.=0 "mother alive or <=-6m MO DTH") ///
			,gen(MO_DTH_TVC) label(MO_DTH_TVC)  
lab var MO_DTH_TVC "Mother's death TVC"
sort concat_IndividualId EventDate EventCode



replace EventCodeMO=81 if MO_DTH_TVC==1
*replace EventCode=18 if MO_DTH_TVC==1

replace EventCodeMO=82 if MO_DTH_TVC==2 
*replace EventCode=18 if MO_DTH_TVC==1


replace EventCodeMO=87 if MO_DTH_TVC==3 & (EventCodeMO==89 | EventCodeMO==9) & EventDate<last_record_date

replace EventCodeMO=89 if MO_DTH_TVC==4 & EventDate<last_record_date

* Harmoniser les dates
foreach w of varlist DoDMO_1{
gen double `w'_1 = dofc(`w')
format `w'_1 %td
drop `w' 
rename `w'_1 `w'
}


foreach w of varlist DoDMO_1{
gen double `w'_1 = cofd(`w')
format `w'_1 %tc
drop `w' 
rename `w'_1 `w'
}







*replace EventCode=7 if EventDate==DoDMO
label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 81 "-3mDTH" 82 "+3m after MO DTH" 87 "3m to 6m after MO DTH"  89 "+6mDTH" ///
	9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
label val EventCodeMO eventlab


*(2) Supprimer les doublons
capture drop dup_e
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId socialgpId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1
*5

drop if EventDate<DoB 
*150
drop if EventDate>last_record_date
*15

*XX
**Ajouter les périodes pour le père
*Subdiviser les périodes jusqu'au décès de la mère
* Create date of death of the mother

*Subdiviser les périodes jusqu'au décès de la mère
* Create date of death of the mother
capture drop DoDFA_1
gen double DoDFA_1  = cofd(DoDFA)
format DoDFA_1 %tc

* Harmoniser les dates
foreach w of varlist DoDFA_1{
gen double `w'_1 = dofc(`w')
format `w'_1 %td
drop `w' 
rename `w'_1 `w'
}


foreach w of varlist DoDFA_1{
gen double `w'_1 = cofd(`w')
format `w'_1 %tc
drop `w' 
rename `w'_1 `w'
}



capture drop f_death
gen f_death = (EventDate==DoDFA_1)
*XX
sort concat_IndividualId EventDate EventCode
capture drop duplicated
expand 2 if f_death==1, gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}
* Replace with date 3 months before death
display %20.0f 30.458333*24*60*60*1000*3 // 3 months in milliseconds  7889400000 15778800000
bys concat_IndividualId : replace EventDate=(DoDFA_1 - 7894799914) if duplicated==1
* Replace code 
bys concat_IndividualId : replace EventCode=18 if duplicated==1
bys concat_IndividualId : replace EventCodeFA=81 if duplicated==1
replace EventCodeFA=1 if EventCodeFA==81

sort concat_IndividualId EventDate EventCode
bys concat_IndividualId (EventDate EventCode): replace residenceFA=residenceFA[_n+1] ///
		if EventCodeFA==81 & EventCodeFA[_n+1]!=7

**Create an extra line 6 month after mother's death 
capture drop f_death
gen f_death = (EventDate==DoDFA_1)

sort concat_IndividualId EventDate
capture drop duplicated
expand 2 if f_death==1,gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}


bys concat_IndividualId : replace EventDate=(DoDFA_1 + 15778800000) if duplicated==1
bys concat_IndividualId : replace EventCode=18 if duplicated==1
bys concat_IndividualId : replace EventCodeFA=89 if duplicated==1

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 81 "-3mDTH" 89 "+6mDTH" 9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
drop duplicated
replace residenceFA=0 if EventCodeFA==89
capture drop datebeg
sort concat_IndividualId EventDate 
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop censort_DTH6FA
gen censort_DTH6FA = (EventCodeFA==89)
label var censort_DTH6FA "6 month after father death"

capture drop f_death_bis
bys concat_IndividualId : egen f_death_bis = max(f_death)
stset EventDate if f_death_bis==1  ///
, id(concat_IndividualId) failure(censort_DTH6FA==1) time0(datebeg) ///
				origin(time DoDFA_1-7889400000) scale(2629800000) 
				

capture drop fdth3m_3m_6m
stsplit fdth3m_3m_6m , at(0 3 6)
replace fdth3m_3m_6m=8 if fdth3m_3m_6m==. & EventDate>DoDFA_1
stset, clear
drop censort_DTH6FA
capture drop FA_DTH_TVC
recode fdth3m_3m_6m (0=1 "-3m before FA DTH")(3=2 "0 to 3m after FA DTH") ///
			(6 = 3 "3m to 6m after FA DTH") (8=4 "6m&+ FA DTH") (.=0 "father alive or <=-6m FA DTH") ///
			,gen(FA_DTH_TVC) label(FA_DTH_TVC)  
lab var FA_DTH_TVC "Father's death TVC"
sort concat_IndividualId EventDate EventCode



replace EventCodeFA=81 if FA_DTH_TVC==1
*replace EventCode=18 if FA_DTH_TVC==1

replace EventCodeFA=82 if FA_DTH_TVC==2 
*replace EventCode=18 if MO_DTH_TVC==1


replace EventCodeFA=87 if FA_DTH_TVC==3 & (EventCodeFA==89 | EventCodeFA==9) & EventDate<last_record_date

replace EventCodeFA=89 if FA_DTH_TVC==4 & EventDate<last_record_date



*replace EventCode=7 if EventDate==DoDMO
label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 81 "-3mDTH" 82 "+3m after FA DTH" 87 "3m to 6m after FA DTH"  89 "+6mDTH" ///
	9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
label val EventCodeFA eventlab

*(2) Supprimer les doublons
capture drop dup_e
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId socialgpId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1
*12

drop if EventDate<DoB 
*116
drop if EventDate>last_record_date
*62



******
capture drop lastrecord
sort hdss concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 


stset EventDate , id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)

*Retenir uniquement les enfants de moins de 5 ans
sort hdss IndividualId EventDate EventCode	
capture drop fifthbirthday
display %20.0f (5*365.25*24*60*60*1)+212000 /*why 212000000? */ /*(2 days)*/
* 158000000000

display %20.0f (0.5*24*60*60*1)+212000 /*why 212000000? */ /*(2 days)*/

stsplit fifthbirthday, at(5.001) 
sort concat_IndividualId EventDate EventCode
order concat_IndividualId EventDate EventCode
edit concat_IndividualId EventDate EventCode _st _d fifthbirthday
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId :replace fifthbirthday=0 if EventCode==2

drop if fifthbirthday>0 



sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop lastrecord
sort hdss concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 


sort concat_IndividualId EventDate EventCode
cap drop censor_death
gen byte censor_death=(EventCode==7) 
stset EventDate, id(concat_IndividualId) failure(censor_death==1) ///
			time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)


		
* Correction 
bysort concat_IndividualId (DoBOsibling): replace DoBOsibling = DoBOsibling[1]
bysort concat_IndividualId (DoBYsibling): replace DoBYsibling = DoBYsibling[1]
bysort concat_IndividualId (DoBTwin): replace DoBTwin = DoBTwin[1]
format DoBYsibling %tc
format DoBOsibling %tc
sort concat_IndividualId EventDate EventCode
		

* Correction: Residence of the mother should be 0 after her death
replace residenceMO=0 if MO_DTH_TVC==3 | MO_DTH_TVC==4 
replace residenceMO=0 if MO_DTH_TVC==2 & EventCodeMO!=7

replace residenceFA=0 if FA_DTH_TVC==3 | FA_DTH_TVC==4 
replace residenceFA=0 if FA_DTH_TVC==2 & EventCodeFA!=7
	
	
// Because of tmerge many lines are duplicated/ drag the last value through following lines (eg eventcode of mother)- and this needs to be fixed (but just for the variables you work with)

* Generate indicator variables for death of mother and siblings:
capture drop Dead*
bysort concat_IndividualId (EventDate): gen byte DeadMO=sum(EventCodeMO[_n-1]==7) 
bysort concat_IndividualId (EventDate): gen byte DeadFA=sum(EventCodeFA[_n-1]==7) 
bysort concat_IndividualId (EventDate): gen byte DeadY =sum(EventCodeY[_n-1]==7) 
bysort concat_IndividualId (EventDate): gen byte DeadO =sum(EventCodeO[_n-1]==7) 
bysort concat_IndividualId (EventDate): gen byte DeadTwin =sum(EventCodeTwin[_n-1]==7) 
replace DeadMO= 1 if DeadMO>1 & DeadMO!=. 
replace DeadFA= 1 if DeadFA>1 & DeadFA!=. 
replace DeadY = 1 if DeadY >1 & DeadY !=. 
replace DeadO = 1 if DeadO >1 & DeadO !=. 
replace DeadTwin = 1 if DeadTwin >1 & DeadTwin !=. 



* New variable for residence accounting for death: 
capture drop MigDeadMO
gen byte MigDeadMO=(1+residenceMO+2*DeadMO) // !!!!!!!!!!!!!
recode MigDeadMO (4 = 3)
lab def MigDeadMO 1"mother non resident" 2 "mother res" 3 "mother dead" 4 "mother res dead",  modify
lab val MigDeadMO MigDeadMO
replace MigDeadMO=3 if MO_DTH_TVC>1 //fixing errors due to duplications from tmerge (mother is dead after death)
replace MigDeadMO=2 if MO_DTH_TVC==1  //fixing errors due to duplications from tmerge (mother is dead after death)



capture drop MigDeadFA
gen byte MigDeadFA=(1+residenceFA+2*DeadFA) // !!!!!!!!!!!!!
recode MigDeadFA (4 = 3)
lab def MigDeadFA 1"father non resident" 2 "father res" 3 "father dead" 4 "father res dead",  modify
lab val MigDeadFA MigDeadFA
replace MigDeadFA=3 if FA_DTH_TVC>1 //fixing errors due to duplications from tmerge (mother is dead after death)
replace MigDeadFA=2 if FA_DTH_TVC==1 //fixing errors due to duplications from tmerge (mother is dead after death)


capture drop MigDeadY
gen byte MigDeadY=cond(residenceY==., 0, 1 + (residenceY==1) + 2*(DeadY==1)) //residence missing when not yet born
recode MigDeadY(4=3) 
lab def MigDeadY 0 "no young sib" 1 "y sib non-res" 2 "y sib resident" 3 "y sib dead" 4 "y sib res dead",  modify
lab val MigDeadY MigDeadY
replace MigDeadY=2 if MigDeadY==3 & Y_DTH_TVC<2
replace MigDeadY=3 if MigDeadY!=3 & (Y_DTH_TVC==2 | Y_DTH_TVC==4)



capture drop MigDeadTwin
gen byte MigDeadTwin=cond(residenceTwin==., 0, 1 + (residenceTwin==1) + 2*(DeadTwin==1)) 
recode MigDeadTwin(4=3) 
lab def MigDeadTwin 0 "no twin" 1 "twin non-res" 2 "twin resident" 3 "twin dead" 4 "twin res dead",  modify
lab val MigDeadTwin MigDeadTwin
replace MigDeadTwin=2 if MigDeadTwin==3 & Twin_DTH_TVC<2
replace MigDeadTwin=3 if MigDeadTwin!=3 & (Twin_DTH_TVC==2 | Twin_DTH_TVC==4)


capture drop MigDeadO
gen byte MigDeadO=cond(residenceO==., 0, 1 + (residenceO==1) + 2*(DeadO==1))
recode MigDeadO(4=3) 
lab def MigDeadO 0 "no older sib" 1 "o sib non-res" 2 "o sib resident" 3 "o sib dead" 4 "o sib res dead",  modify
lab val MigDeadO MigDeadO
replace MigDeadO=2 if MigDeadO==3 & O_DTH_TVC<2
replace MigDeadO=3 if MigDeadO!=3 & (O_DTH_TVC==2 | O_DTH_TVC==4)



sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


*replace MigDeadFA = 4 if coresidFA==1 & MigDeadFA==1

drop if datebeg<DoB
*436 

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc


sort concat_IndividualId EventDate EventCode
cap drop censor_death
gen byte censor_death=(EventCode==7) 
stset EventDate, id(concat_IndividualId) failure(censor_death==1) ///
			time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)


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




 *XX

** Generate calendar periods
cap drop lastrecord
qui bys concat_IndividualId (EventDate): gen byte lastrecord=(_n==_N) 
tab lastrecord

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId  : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

stset EventDate , id(concat_IndividualId) failure(lastrecord==1) exit(time .)  time0(datebeg) 
		
		
*To get values of 01Jan for each year
foreach num in 1975 1980 1985 1990 1995 2000 2005 2010 2015 {
	display %20.0f  clock("01Jan`num'","DMY")
}

capture drop period 
stsplit period, at(473385600000 631152000000  789004800000 946771200000 1104537600000 1262304000000 ///
			1420156800000 1577923200000 1735689600000)
recode period (473385600000=1975) (631152000000=1980)  (789004800000=1985) ///
              (946771200000=1990) (1104537600000=1995) (1262304000000=2000) ///
			(1420156800000=2005) (1577923200000=2010) (1735689600000=2015)
label variable period period


sort concat_IndividualId EventDate
by concat_IndividualId: replace EventCode=30 if EventCode==EventCode[_n+1] ///
		& period!=. & period!=period[_n+1] & concat_IndividualId==concat_IndividualId[_n+1]
label define eventlab 30 "Period", modify
lab val EventCode eventlab



*(1) Sélectionner les enfants nés sous surveillance
sort  concat_IndividualId EventDate EventCode
drop if EventDate < DoB
capture drop birth birth1
gen birth = EventCode==2
bysort concat_IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0
*2,330


* Sélectionné les individus à partir de 1990
forval num=1990/2016 {
display %20.0f date("01Jan`num':","DMY")
}

capture drop entry_time
gen entry_time = 10958
format entry_time %td
gen double entry_time_1 = cofd(entry_time)
format entry_time_1 %tc
drop entry_time

sort concat_IndividualId EventDate EventCode
capture drop entry_d
bys concat_IndividualId : egen entry_d = max((EventDate[1]>=entry_time_1))

drop if entry_d==0
*73,049

/*

      Event occurered |      Freq.     Percent        Cum.
----------------------+-----------------------------------
                  BTH |    113,991       15.56       15.56
                  IMG |      3,790        0.52       16.07
                  OMG |     19,264        2.63       18.70
                  EXT |     10,491        1.43       20.13
                  ENT |      9,631        1.31       21.45
                  DTH |      7,442        1.02       22.46
                  OBE |    146,763       20.03       42.49
                  OBS |    321,622       43.89       86.39
               Period |     99,765       13.61      100.00
----------------------+-----------------------------------
                Total |    732,759      100.00

*/
sort concat_IndividualId EventDate EventCode
cap drop censor_death
gen byte censor_death=(EventCode==7) if residence==1
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
			time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)

			

*XX

* clean some inconsistent out-of-period data for some sites
tab hdss period [iw=_t-_t0],  missing
format datebeg %tc

replace period=2010 if period==2005 & hdss=="BF021" 
replace period=2010 if period==2005 & hdss=="BF041" 

* 
drop if period==0 
*0

*XX Arrêt
**Groupe d'âge de la mère (age of mother at birth of child)
capture drop mother_age_birth
gen mother_age_birth = (DoB - DoB_mother)/31557600000

**Erreurs (âge de la mère à la naissance inférieur à 13 ans ou supérieur à 52 ans)
capture drop error_m_age
gen byte error_m_age = cond(mother_age_birth==.,.,cond(mother_age_birth<13| mother_age_birth>52,1,0))



**Supprimer ces incohérences 
drop if error_m_age == 1
drop error_m_age

capture drop gp_mother_age_birth
gen byte gp_mother_age_birth = cond(mother_age_birth==.,4,cond(mother_age_birth<18,1,cond(mother_age_birth<36,2,3)))
label def gp_age 1"<18 years" 2"18 - 35 y" 3"35 years  +" 4"Missing",modify
label val gp_mother_age_birth gp_age

capture drop y3_mother_age_birth
gen int_mother_age_birth=int(mother_age_birth)
recode int_mother_age_birth (min/17=15 "15-17") (18/20=18 "18–20") (21/23=21 "21–23") ///
		(24/26=24 "24–26") (27/29=27 "27–29") (30/32=30 "30–32") (33/35=33 "33–35") ///
		(36/38=36 "36–38") (39/41=39 "39–41") (42/max=42 "42+") (.=99 "Missing"), gen(y3_mother_age_birth)
drop int_mother_age_birth


//creatng birth intervals (in months)
capture drop ecart_O 
gen ecart_O = (DoB - DoBOsibling)*12/31557600000
capture drop gp_ecart_O
gen byte gp_ecart_O = cond(ecart_O==.,0, ///
				cond(ecart_O<12,1, ///
				cond(ecart_O<15,2, ///
				cond(ecart_O<18,3, ///
				cond(ecart_O<21,4, ///
				cond(ecart_O<24,5, ///
				cond(ecart_O<27,6, ///
				cond(ecart_O<30,7, ///
				cond(ecart_O<33,0, ///
				cond(ecart_O<36,9, ///
				cond(ecart_O<39,10, ///
				cond(ecart_O<42,11, ///
				cond(ecart_O<45,12, ///
				cond(ecart_O<48,13, ///
				cond(ecart_O<51,14, ///
				cond(ecart_O<54,15, ///
				16))))))))))))))))
label def gp_age_so 0 "NoOS" 1 "<12 months" 2 "12-14 months" 3 "15-17 months" ///
		4 "18-20 months" 5 "21-23 months" 6 "24-26 months" 7 "27-29 months" ///
		8 "30-32 months" 9 "33-35 months" 10 "36-38 months" 11 "39-41 months" ///
		12 "42-44 months" 13 "45-47 months" 14 "48-50 months" 15 "51-53 months" 16"54 months +", modify
label val gp_ecart_O gp_age_so


capture drop gp_ecart_O_new
gen byte gp_ecart_O_new = cond(ecart_O==.,0, ///
				cond(ecart_O<12,1, ///
				cond(ecart_O<18,2, ///
				cond(ecart_O<24,3, ///
				cond(ecart_O<30,4, ///
				cond(ecart_O<36,5, ///
				cond(ecart_O<42,6, ///
				cond(ecart_O<48,7, ///
				8))))))))
label def lgp_ecart_O_new 0"NoOS" 1"<12 months" 2"12-17 months" 3"18-23 months" ///
		4 "24-29 months" 5 "30-35 months" 6 "36-41 months" 7 "42-47 months" 8 "48 months +",modify
label val gp_ecart_O_new lgp_ecart_O_new

capture drop gp_ecart_O_new_1
gen byte gp_ecart_O_new_1 = cond(ecart_O==.,0, ///
				cond(ecart_O<18,1,2 ))
label def lgp_ecart_O_new_1 0"NoOS" 1"<18 months" 2"18 months +" ,modify
label val gp_ecart_O_new_1 lgp_ecart_O_new_1

capture drop gp_ecart_O_new_2
gen byte gp_ecart_O_new_2 = cond(ecart_O==.,0, ///
				cond(ecart_O<24,1,2 ))
label def lgp_ecart_O_new_2 0"NoOS" 1"<24 months" 2"24 months +" ,modify
label val gp_ecart_O_new_2 lgp_ecart_O_new_2



capture drop ecart_Y 
gen ecart_Y = (DoBYsibling - DoB)*12/31557600000
capture drop gp_ecart_Y
gen byte gp_ecart_Y = cond(ecart_Y==.,0, ///
				cond(ecart_Y<12,1, ///
				cond(ecart_Y<15,2, ///
				cond(ecart_Y<18,3, ///
				cond(ecart_Y<21,4, ///
				cond(ecart_Y<24,5, ///
				cond(ecart_Y<27,6, ///
				cond(ecart_Y<30,7, ///
				cond(ecart_Y<33,0, ///
				cond(ecart_Y<36,9, ///
				cond(ecart_Y<39,10, ///
				cond(ecart_Y<42,11, ///
				cond(ecart_Y<45,12, ///
				cond(ecart_Y<48,13, ///
				cond(ecart_Y<51,14, ///
				cond(ecart_Y<54,15, ///
				16))))))))))))))))
label def gp_age_sy 0 "NoYS" 1 "<12 months" 2 "12-14 months" 3 "15-17 months" ///
		4 "18-20 months" 5 "21-23 months" 6 "24-26 months" 7 "27-29 months" ///
		8 "30-32 months" 9 "33-35 months" 10 "36-38 months" 11 "39-41 months" ///
		12 "42-44 months" 13 "45-47 months" 14 "48-50 months" 15 "51-53 months" 16"54 months +", modify
label val gp_ecart_Y gp_age_sy			

capture drop gp_ecart_Y_new 				
gen byte gp_ecart_Y_new = cond(ecart_Y==.,0, ///
				cond(ecart_Y<12,1, ///
				cond(ecart_Y<18,2, ///
				cond(ecart_Y<24,3, ///
				cond(ecart_Y<30,4, ///
				cond(ecart_Y<36,5, ///
				cond(ecart_Y<42,6, ///
				cond(ecart_Y<48,7, ///
				8))))))))
label def lgp_ecart_Y_new 0 "NoYS" 1 "<12 months" 2 "12-17 months" 3 "18-23 months" ///
		4 "24-29 months" 5 "30-35 months" 6 "36-41 months" 7 "42-47 months" 8 "48 months +" 
label val gp_ecart_Y_new lgp_ecart_Y_new

capture drop gp_ecart_Y_new_1
gen byte gp_ecart_Y_new_1 = cond(ecart_Y==.,0, ///
				cond(ecart_Y<18,1,2 ))
label def lgp_ecart_Y_new_1 0"NoOS" 1"<18 months" 2"18 months +" ,modify
label val gp_ecart_Y_new_1 lgp_ecart_Y_new_1

capture drop gp_ecart_Y_new_2
gen byte gp_ecart_Y_new_2 = cond(ecart_Y==.,0, ///
				cond(ecart_Y<24,1,2 ))
label def lgp_ecart_Y_new_2 0"NoOS" 1"<24 months" 2"24 months +" ,modify
label val gp_ecart_Y_new_2 lgp_ecart_Y_new_2


* Data errors:
* Gap between Younger sibling and index child DoB <9 months
browse concat_IndividualId DoB YsiblingId DoBYsibling ecart_Y MotherId  if ecart_Y<8 & lastrecord==1
gen temp=100*(ecart_Y<8)
*table hdss if lastrecord==1, contents(mean temp) // ET041 ET051 ET061 >1%
drop temp

* Gap between Older sibling and index child DoB <9 months
browse concat_IndividualId DoB OsiblingId DoBOsibling ecart_O MotherId  if ecart_O<8 & lastrecord==1
gen temp=100*(ecart_O<8)
*table hdss if lastrecord==1, contents(mean temp) // ET041 ET051 ET061 >1%
drop temp

* Fix these errors
drop if ecart_Y<8
drop if ecart_O<8

* Gap between Younger sibling and index child DoB >5 years
browse concat_IndividualId DoB YsiblingId DoBYsibling ecart_Y MotherId  if ecart_Y>60 & ecart_Y!=. & lastrecord==1
* Only 81 and none >61 months
* Gap between Older sibling and index child DoB >20 years
browse concat_IndividualId DoB OsiblingId DoBOsibling ecart_O MotherId  if ecart_O>240 & ecart_O!=. & lastrecord==1
* Only 3 
* No impact on sibling covariates

*YaC 10112020
/*
replace migrant_statusMO = 0 if MigDeadMO==1 //fixing migration status of mother if non-resident
bysort concat_IndividualId (EventDate): replace migrant_statusMO = migrant_statusMO[1] if migrant_statusMO==. //b/c we added lines, need to fill in mig status
*/
//identifies if the kid is resident or not- and then takes birth interval
capture drop gp_ecart_Yres
gen byte gp_ecart_Yres = cond(MigDeadY==2,gp_ecart_Y,0)
capture drop gp_ecart_Ores
gen byte gp_ecart_Ores = cond(MigDeadO==2,gp_ecart_O,0)
capture drop gp_ecart_Ores_new
gen byte gp_ecart_Ores_new = cond(MigDeadO==2,gp_ecart_O_new,0)
label val gp_ecart_Yres gp_age_sy
label val gp_ecart_Ores gp_age_so
label val gp_ecart_Ores_new lgp_ecart_O_new

*YaC
capture drop gp_ecart_Yres_new_1
gen byte gp_ecart_Yres_new_1 = cond(MigDeadY==2,gp_ecart_Y_new_1,0)
capture drop gp_ecart_Ores_new_1
gen byte gp_ecart_Ores_new_1 = cond(MigDeadO==2,gp_ecart_O_new_1,0)

capture drop gp_ecart_Yres_new_2
gen byte gp_ecart_Yres_new_2 = cond(MigDeadY==2,gp_ecart_Y_new_2,0)
capture drop gp_ecart_Ores_new_2
gen byte gp_ecart_Ores_new_2 = cond(MigDeadO==2,gp_ecart_O_new_2,0)

label val gp_ecart_Yres_new_2 lgp_ecart_Y_new_2  
label val gp_ecart_Ores_new_2 lgp_ecart_O_new_2  
label val gp_ecart_Ores_new_1 lgp_ecart_O_new_1
label val gp_ecart_Yres_new_1 lgp_ecart_Y_new_1

*XX
* drop pregnant parts
drop if birth_int_YS ==1
//creating dummy variables of each category of birth intervals-when resident
sort concat_IndividualId EventDate
gen byte birth_int_Yres_12m = cond(gp_ecart_Y_new==1&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_12m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==1
label val birth_int_Yres_12m lbirth_int_YS

gen byte birth_int_Yres_12_17m = cond(gp_ecart_Y_new==2&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_12_17m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==2
label val birth_int_Yres_12_17m lbirth_int_YS

gen byte birth_int_Yres_18_23m = cond(gp_ecart_Y_new==3&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_18_23m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==3
label val birth_int_Yres_18_23m lbirth_int_YS

gen byte birth_int_Yres_24_29m = cond(gp_ecart_Y_new==4&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_24_29m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==4
label val birth_int_Yres_24_29m lbirth_int_YS

gen byte birth_int_Yres_30_35m = cond(gp_ecart_Y_new==5&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_30_35m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==5
label val birth_int_Yres_30_35m lbirth_int_YS

gen byte birth_int_Yres_36_41m  = cond(gp_ecart_Y_new==6&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_36_41m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==6
label val birth_int_Yres_36_41m lbirth_int_YS

gen byte birth_int_Yres_42_47m  = cond(gp_ecart_Y_new==7&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_42_47m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==7
label val birth_int_Yres_42_47m lbirth_int_YS

gen byte birth_int_Yres_48_more  = cond(gp_ecart_Y_new==8&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_48_more=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==8
label val birth_int_Yres_48_more lbirth_int_YS

//combination of birth interval and period after birth (including pregnancy)
capture drop gp_birth_int_YS
gen int gp_birth_int_YS= MigDeadY*1000 + birth_int_Yres_12m + ///
	cond(birth_int_Yres_12_17m==0,0,10+ birth_int_Yres_12_17m) + ///
	cond(birth_int_Yres_18_23m==0,0,20+ birth_int_Yres_18_23m) + ///
	cond(birth_int_Yres_24_29m==0,0,30+ birth_int_Yres_24_29m) + ///
	cond(birth_int_Yres_30_35m==0,0,40+ birth_int_Yres_30_35m) + ///
	cond(birth_int_Yres_36_41m==0,0,50+ birth_int_Yres_36_41m) + ///
	cond(birth_int_Yres_42_47m==0,0,60+ birth_int_Yres_42_47m) + ///
	cond(birth_int_Yres_48_more==0,0,70+ birth_int_Yres_48_more)

label define lgp_birth_int_YS ///
0 "NoYS"	///
1 "Int <12m - pregnant" ///	
11 "Int 12-17m - pregnant" ///	
21 "Int 18-23m - pregnant" ///	
31 "Int 24-29m - pregnant" ///	
41 "Int 30-35m - pregnant" ///	
51 "Int 36-41m - pregnant" ///	
61 "Int 42-47m - pregnant" ///
71 "Int >=48m + - pregnant" ///	
1000 "y sibling non-res" ///
2002 "Int <12m - 0-6m" ///	
2003 "Int <12m - 6-12m" ///	
2004 "Int <12m - 12m +" ///	
2012 "Int 12-17m - 0-6m" ///	
2013 "Int 12-17m - 6-12m" ///	
2014 "Int 12-17m - 12m +" ///	
2022 "Int 18-23m - 0-6m" ///	
2023 "Int 18-23m - 6-12m" ///	
2024 "Int 18-23m - 12m +" ///	
2032 "Int 24-29m - 0-6m" ///	
2033 "Int 24-29m - 6-12m" ///	
2034 "Int 24-29m - 12m +" ///	
2042 "Int 30-35m - 0-6m" ///	
2043 "Int 30-35m - 6-12m" ///	
2044 "Int 30-35m - 12m +" ///	
2052 "Int 36-41m - 0-6m" ///	
2053 "Int 36-41m - 6-12m" ///	
2054 "Int 36-41m - 12m +" ///	
2062 "Int 42-47m - 0-6m" ///	
2063 "Int 42-47m - 6-12m" ///	
2064 "Int 42-47m - 12m +" ///	
2072 "Int >=48m + - 0-6m" ///	
2073 "Int >=48m + - 6-12m" ///	
2074 "Int >=48m + - 12m +" ///	
3000 "y sibling dead", modify	

label val gp_birth_int_YS lgp_birth_int_YS

*recode gp_birth_int_YS (2074=2073)


*XX
capture drop birth_int_gp_YS
* Same variable but with different coding order
recode gp_birth_int_YS ///
(0 =0 "NoYS"					) ///
(1 =1 "Int <12m - pregnant" 	) ///	
(11=11 "Int 12-17m - pregnant" 	) ///	
(21=21 "Int 18-23m - pregnant" 	) ///	
(31=31 "Int 24-29m - pregnant" 	) ///	
(41=41 "Int 30-35m - pregnant" 	) ///	
(51=51 "Int 36-41m - pregnant" 	) ///	
(61=61 "Int 42-47m - pregnant" 	) ///
(71=71 "Int >=48m+ - pregnant" ) ///	
(1000=100 "y sibling non-res" 	) ///
(2002=200 "Int <12m - 0-6m" 	) ///	
(2003=300 "Int <12m - 6-12m" 	) ///	
(2004=400 "Int <12m - 12m+" 	) ///	
(2012=210 "Int 12-17m - 0-6m" 	) ///	
(2013=310 "Int 12-17m - 6-12m" 	) ///	
(2014=410 "Int 12-17m - 12m+" 	) ///	
(2022=220 "Int 18-23m - 0-6m" 	) ///	
(2023=320 "Int 18-23m - 6-12m" 	) ///	
(2024=420 "Int 18-23m - 12m+" 	) ///	
(2032=230 "Int 24-29m - 0-6m" 	) ///	
(2033=330 "Int 24-29m - 6-12m" 	) ///	
(2034=430 "Int 24-29m - 12m+" 	) ///	
(2042=240 "Int 30-35m - 0-6m" 	) ///	
(2043=340 "Int 30-35m - 6-12m" 	) ///	
(2044=440 "Int 30-35m - 12m+" 	) ///	
(2052=250 "Int 36-41m - 0-6m" 	) ///	
(2053=350 "Int 36-41m - 6-12m" 	) ///	
(2054=450 "Int 36-41m - 12m+"	) ///	
(2062=260 "Int 42-47m - 0-6m" 	) ///	
(2063=360 "Int 42-47m - 6-12m" 	) ///	
(2064=460 "Int 42-47m - 12m+" 	) ///	
(2072=270 "Int >=48m+ - 0-6m" 	) ///	
(2073=370 "Int >=48m+ - 6-12m" 	) ///	
(2074=470 "Int >=48m+ - 12m+" 	) ///
(3000=500 "y sibling dead"		), gen(birth_int_gp_YS)	
 
*XX
*YaC
*New variables
recode birth_int_gp_YS ///
(0 =0 "NoYS") ///
(1 11 = 1 "Int <18m - pregnant") ///
(21 31 41 51 61 71 = 2 "Int >18m - pregnant") ///
(100=3 "y sibling non-res") ///
(200 210 = 4 "Int <18m - 0-6m") ///
(300 310 = 5 "Int <18m - 6-12m") ///
(400 410 = 6 "Int <18m - 12m+") ///
(220 230 240 250 260 270 = 7 "Int >18m -  0-6m") ///
(320 330 340 350 360 370 = 8 "Int >18m -  6-12m") ///
(420 430 440 450 460 470 = 9 "Int >18m -  12m+") ///
(500= 10 "y sibling dead"), gen(birth_int_gp_YS_new)


recode birth_int_gp_YS ///
(0 =0 "NoYS") ///
(1 11 21 = 1 "Int <24m - pregnant") ///
(31 41 51 61 71 = 2 "Int >24m - pregnant") ///
(100=3 "y sibling non-res") ///
(200 210 220 = 4 "Int <24m - 0-6m") ///
(300 310 320 = 5 "Int <24m - 6-12m") ///
(400 410 420 = 6 "Int <24m - 12m+") ///
(230 240 250 260 270 = 7 "Int >24m -  0-6m") ///
(330 340 350 360 370 = 8 "Int >24m -  6-12m") ///
(430 440 450 460 470 = 9 "Int >24m -  12m+") ///
(500= 10 "y sibling dead"), gen(birth_int_gp_YS_new_bis)


capture drop pregnant_YS
gen byte pregnant_YS = (birth_int_YS==1)
lab define pregnant 1 "3-9m pregnant" 0 "No this period"
label val pregnant_YS pregnant

capture drop twin
gen byte twin = (TwinId!="")
label define twin 1 "Yes" 0 "No",modify
label val twin twin

* Setting mortality analysis <5-year-old 
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)
/*
    113,644  subjects
     7,571  failures in single-failure-per-subject data
  486,006.55  total analysis time at risk and under observation

*/

*compress

*Vérifications et corrections
/*
foreach var of varlist MigDeadMO Sex y3_mother_age_birth migrant_statusMO MO_DTH_TVC MigDeadO gp_ecart_Ores ///
                       MigDeadY  birth_int_Yres_12m birth_int_Yres_12_17m ///
                       birth_int_Yres_18_23m birth_int_Yres_24_29m birth_int_Yres_30_35m birth_int_Yres_36_41m ///
                       birth_int_Yres_42_47m birth_int_Yres_48_more twin period {
					   
					   tab `var' [iw=_t-_t0], miss
					   }
*/
foreach var of varlist birth_int_Yres_12m birth_int_Yres_12_17m  ///
                       birth_int_Yres_18_23m birth_int_Yres_24_29m birth_int_Yres_30_35m birth_int_Yres_36_41m ///
                       birth_int_Yres_42_47m birth_int_Yres_48_more  {
					   
					   replace `var' = 0 if `var'==.
					   }

*adding the period around the death to the mig-death var of mother					   
capture drop MigDeadMO_MO_DTH_TVC
gen MigDeadMO_MO_DTH_TVC=	cond(MigDeadMO==2 & MO_DTH_TVC==0,0, cond(MigDeadMO==1 & MO_DTH_TVC==0,1, ///
							cond(MO_DTH_TVC==1,2, cond(MO_DTH_TVC==2,3, cond(MO_DTH_TVC==3,4,5))))) 
							
label define lMigDeadMO_MO_DTH_TVC 0 "mother resident" 	1 "mother non resident" ///
						2 "-3m before MO DTH" 	3 "0 to 3m after MO DTH" ///
						4 "3m to 6m after MO DTH" 		5 "6m+ mother's death", modify 
replace MigDeadMO_MO_DTH_TVC=0 if MO_DTH_TVC==0 & MigDeadMO_MO_DTH_TVC==5										
label val MigDeadMO_MO_DTH_TVC lMigDeadMO_MO_DTH_TVC



*adding the period around the death to the mig-death var of father					   
capture drop MigDeadFA_FA_DTH_TVC
gen MigDeadFA_FA_DTH_TVC=	cond(MigDeadFA==2 & FA_DTH_TVC==0,0, cond(MigDeadFA==1 & FA_DTH_TVC==0,1, ///
							cond(FA_DTH_TVC==1,2, cond(FA_DTH_TVC==2,3, cond(FA_DTH_TVC==3,4,5))))) 
							
label define lMigDeadFA_FA_DTH_TVC 0 "father resident" 	1 "father non resident" ///
						2 "-3m before FA DTH" 	3 "0 to 3m after FA DTH" ///
						4 "3m to 6m after FA DTH" 		5 "6m+ father's death", modify 
replace MigDeadFA_FA_DTH_TVC=0 if FA_DTH_TVC==0 & MigDeadFA_FA_DTH_TVC==5					
label val MigDeadFA_FA_DTH_TVC lMigDeadFA_FA_DTH_TVC




capture drop MigDeadO_O_DTH_TVC
gen MigDeadO_O_DTH_TVC=	cond(MigDeadO==2 & O_DTH_TVC==0,0, cond(MigDeadO==1 & O_DTH_TVC==0,1, ///
							cond(O_DTH_TVC==1,2, cond(O_DTH_TVC==2,3, 4)))) 
							
replace MigDeadO_O_DTH_TVC=9 if MigDeadO==0
label define lMigDeadO_O_DTH_TVC 0 "O sib resident" 	1 "O sib non resident" ///
						2"-3m before DTH" 	3"-3m after  DTH" ///
						4"3m&+  DTH"  9"no O sib", modify
						 
						
label val MigDeadO_O_DTH_TVC lMigDeadO_O_DTH_TVC


capture drop MigDeadY_Y_DTH_TVC
gen MigDeadY_Y_DTH_TVC=	cond(MigDeadY==2 & Y_DTH_TVC==0,0, cond(MigDeadY==1 & Y_DTH_TVC==0,1, ///
							cond(Y_DTH_TVC==1,2, cond(Y_DTH_TVC==2,3, 4)))) 
							
replace MigDeadY_Y_DTH_TVC=9 if MigDeadY==0
label define lMigDeadY_Y_DTH_TVC 0 "Y sib resident" 	1 "Y sib non resident" ///
						2"-3m before DTH" 	3"-3m after  DTH" ///
						4"3m&+  DTH"  9"no Y sib", modify

label val MigDeadY_Y_DTH_TVC lMigDeadY_Y_DTH_TVC

				
				
capture drop MigDeadTwin_Twin_DTH_TVC
gen MigDeadTwin_Twin_DTH_TVC=	cond(MigDeadTwin==2 & Twin_DTH_TVC==0,0, cond(MigDeadTwin==1 & Twin_DTH_TVC==0,1, ///
							cond(Twin_DTH_TVC==1,2, cond(Twin_DTH_TVC==2,3,4)))) 
							
replace MigDeadTwin_Twin_DTH_TVC=9 if MigDeadTwin==0
label define lMigDeadTwin_Twin_DTH_TVC 0 "Twin resident" 	1 "Twin non resident" ///
						2"-3m before Twin's death" 	3"-3m after Twin's death" ///
						4"3m&+  Twin's death"  9"no Twin", modify

label val MigDeadTwin_Twin_DTH_TVC lMigDeadTwin_Twin_DTH_TVC



recode birth_int_Yres_48_more (4=3) //combined b/c not a lot of cases in this category (right-censoring since kids are older than 5)
label define lbirth_int_Yres_48_more 1 "pregnant_YS" 2 "0-6m" 3 "6m +", modify
label val birth_int_Yres_48_more lbirth_int_Yres_48_more

gen byte res_O_DTH_TVC= cond(MigDeadO<2,0, O_DTH_TVC) //adds whether resident or not to death categories
lab val res_O_DTH_TVC DTH_TVC 

gen byte res_Y_DTH_TVC= cond(MigDeadY<2,0, Y_DTH_TVC)
lab val res_Y_DTH_TVC DTH_TVC 

gen byte res_Twin_DTH_TVC= cond(MigDeadTwin<2,0, Twin_DTH_TVC)
lab val res_Twin_DTH_TVC DTH_TVC 


gen byte MigDeadO_interv= MigDeadO*10 + gp_ecart_O_new*(MigDeadO==2) 
label def lMigDeadO_interv 0 "No Old sib" 10 "O sib non resident" 21 "O int <12m" ///
		22 "O int 12-17m" 23 "O int 18-23m" 24 "O int 24-29m" 25 "O int 30-35m" ///
		26 "O int 36-41m" 27 "O int 42-47m" 28 "O int 48m +" 30 "O sib dead", modify
lab val MigDeadO_interv lMigDeadO_interv
* Only in model -with both MigDeadO_interv and res_O_DTH_TVC
* 				-with 24 used as reference category 
recode MigDeadO_interv 30=24 // recode dead in the Ref category "O int 24-29m"


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

recode MigDeadO_interv_new (5 = 4)

capture drop MigDeadO_interv_new_1
recode MigDeadO_interv (0 = 0 "No Old sib") ///
                       (10 = 1 "O sib non resident") ///
					   (21 22 23 = 3 "O int <24m") ///
                       (24 25 26 27 28 = 4 "O int >24m") ///
					   (30 = 5 "O sib dead"),gen(MigDeadO_interv_new_1)

* Same with younger sibling:
* Only in model -with both birth_int_gp_YS and res_Y_DTH_TVC
* 				-with 24 used as reference category 
recode birth_int_gp_YS 500=230 // recode dead in the Ref category "Int 24-29m - 0-6m"
recode birth_int_gp_YS_new (10=7) // recode dead in the Ref category "Int 24-29m - 0-6m"

recode birth_int_gp_YS_new_bis (10=7) // recode dead in the Ref category "Int 24-29m - 0-6m"

note: After computing all time-varying covariates


/*
log using tables_verif,replace
table MigDeadY birth_int_Yres_12m 		[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_12_17m 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_18_23m 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_24_29m 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_30_35m 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_36_41m 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_42_47m 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY birth_int_Yres_48_more 	[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadMO migrant_statusMO 		[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadMO MO_DTH_TVC 				[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadY Y_DTH_TVC 				[iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadO O_DTH_TVC 				[iw=_t-_t0], content(freq) format(%10.0f) missing
log close
*/

*interaction entre hdss et period_cl

encode hdss, gen(hdss_1)

egen hdss_period=group(hdss_1 period), label
tab hdss_period [iw=_t-_t0]
*recode Centre_period (35 36 37=38)

*

	  

	  
save analysis_final, replace

XX Arrêt
/*
*Suite : Voir les intervalles intergénésiques - Tester plusieurs modèles - 
Finir 

*/

use analysis_final,clear

*YaC 04122020

*Corrections après discussions avec Philippe

capture drop Pgrandparents
gen Pgrandparents = 0 if coresidPGF==0 & coresidPGM==0
replace Pgrandparents = 1 if coresidPGF==1 & coresidPGM==0
replace Pgrandparents = 2 if coresidPGF==0 & coresidPGM==1
replace Pgrandparents = 3 if coresidPGF==1 & coresidPGM==1

label define lPgrandparents 0"Aucun des 2" 1"PGF present" 2"PGM present" 3"PGF & PGM present",modify
label val Pgrandparents lPgrandparents

capture drop Mgrandparents
gen Mgrandparents = 0 if coresidMGF==0 & coresidMGM==0
replace Mgrandparents = 1 if coresidMGF==1 & coresidMGM==0
replace Mgrandparents = 2 if coresidMGF==0 & coresidMGM==1
replace Mgrandparents = 3 if coresidMGF==1 & coresidMGM==1

label define lMgrandparents 0"Aucun des 2" 1"MGF present" 2"MGM present" 3"MGF & MGM present",modify
label val Mgrandparents lMgrandparents

capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)

tab hdss if censor_death==1 & _st==1 // number of deaths per site
capture drop last_obs
bys concat_IndividualId: gen last_obs=(_n==_N) 

tab hdss if last_obs==1 & _st==1  //number of children under 5 per site

bys hdss : ta  EventCode _st 

*Description de l'échantillon

bys coresidMO : stdes
bys coresidFA : stdes

bys MigDeadMO_MO_DTH_TVC : stdes
bys MigDeadFA_FA_DTH_TVC : stdes

bys coresidPGF : stdes
bys coresidPGM : stdes

bys coresidMGF : stdes
bys coresidMGM : stdes

bys coresid_paunt : stdes
bys coresid_puncle : stdes

bys coresid_maunt : stdes
bys coresid_muncle : stdes


coresid_maunt
coresid_muncle




bys hdss : stdes 

bys gender : stdes

bys hdss_period : stdes

bys birth_int_gp_YS_new : stdes

bys res_Y_DTH_TVC : stdes

bys MigDeadO_interv_new : stdes

bys res_O_DTH_TVC : stdes

bys MigDeadTwin_Twin_DTH_TVC : stdes

bys y3_mother_age_birth :  stdes


stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      ib7.birth_int_gp_YS_new ib0.res_Y_DTH_TVC  ///
	  ib4.MigDeadO_interv_new ib0.res_O_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGM##ib0.coresidPGF  ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle  ///
	  , vce(cluster MotherId) iter(10)

* Descriptives statistics
display %20.0f 30*24*60*60*1000
* 2635200000

* statistiques descriptives sur la présence des parents biologiques et la mortalité des enfants
bys MigDeadMO_MO_DTH_TVC : stdes
bys coresidMO : stdes

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(2635200000)
		
 

sts test coresidMO, logrank
sts graph, by(coresidMO) ///
title("Courbes de survie selon la") /// Title!
t1title("corésidence avec la mère") /// subtitle!
xti("Age (mois)") /// x label!
ytitle("Probabilité de survie (%)") /// y label!
yla(.75 "75%" .80 "80%" .85 "85%" .90 "90%"  .95"95%"  1"100%", angle(0)) /// Y-label values! Angle(0) rotates them.
xla(0(10)60) /// X-label values! From 0 to 6 years with 1 year intervals in between
text(0.8 3 "Log-Rank {it:p}<0.001", placement(e) size(medium)) /// floating label with italics!
legend(order(1 "non corésidents" 2 "corésidents") rows(1) position(6)) /// Legend, forced on two rows
plot1opts(lpattern(dash) lcolor(red)) /// this forces the first line to be dashed and red
plot2opts(lpattern(solid) lcolor(blue)) ///
note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 
graph save "Figure (mère) 1",replace 

graph export "Figure (mère) 1.png", replace width(2000)
graph export "Figure (mère) 1.tif", replace width(2000)


sts test coresidFA, logrank
sts graph, by(coresidFA) ///
title("Courbes de survie selon la") /// Title!
t1title("corésidence avec le père") /// subtitle!
xti("Age (mois)") /// x label!
ytitle("Probabilité de survie (%)") /// y label!
yla(.75 "75%" .80 "80%" .85 "85%" .90 "90%"  .95"95%"  1"100%", angle(0)) /// Y-label values! Angle(0) rotates them.
xla(0(10)60) /// X-label values! From 0 to 6 years with 1 year intervals in between
text(0.8 3 "Log-Rank {it:p}<0.001", placement(e) size(medium)) /// floating label with italics!
legend(order(1 "non corésidents" 2 "corésidents") rows(1) position(6)) /// Legend, forced on two rows
plot1opts(lpattern(dash) lcolor(red)) /// this forces the first line to be dashed and red
plot2opts(lpattern(solid) lcolor(blue)) ///
note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 

graph save "Figure (père) 2",replace 

graph export "Figure (père) 2.png", replace width(2000)
graph export "Figure (père) 2.tif", replace width(2000)

graph combine "Figure (mère) 1.gph" "Figure (père) 2.gph", row(1)

grc1leg "Figure (mère) 1.gph" "Figure (père) 2.gph", row(1) ring(0) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "père_mère.png", replace width(2000)
graph export "père_mère.tif", replace width(2000)

****

// stat des gran-parents

sts gen s_coresidMGM = s, by(coresidMGM)
sts gen s_coresidMGF = s, by(coresidMGF)
sts gen s_coresidPGF = s, by(coresidPGF)
sts gen s_coresidPGM = s, by(coresidPGM)

sts test coresidMGM, logrank /*0.0469 */
sts test coresidMGF, logrank /*0.0005*/
sts test coresidPGM, logrank /*0.5868*/
sts test coresidPGF, logrank /*0.0198*/

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(2635200000)
		


sort _t
twoway connected s_coresidMGM _t if coresidMGM==1, connect(J) msymbol(none) color(lime) ///
    || connected s_coresidMGM _t if coresidMGM==0, connect(J) msymbol(none) color(lime)  lpattern(dash) ///
    || connected s_coresidMGF _t if coresidMGF==1, connect(J) msymbol(none) color(red) ///
    || connected s_coresidMGF _t if coresidMGF==0, connect(J) msymbol(none) color(red) lpattern(dot) ///
    || connected s_coresidPGM _t if coresidPGM==1, connect(J) msymbol(none) color(blue) ///
    || connected s_coresidPGM _t if coresidPGM==0, connect(J) msymbol(none) color(blue) lpattern(tight_dot) ///
    || connected s_coresidPGF _t if coresidPGF==1, connect(J) msymbol(none) lstyle(p4) ///
    || connected s_coresidPGF _t if coresidPGF==0, connect(J) msymbol(none) lstyle(p4) lpattern(dash_3dot) ///
	title("Courbes de survie selon la" ,size(vsmall)) /// Title!
t1title("corésidence avec les grand-parents" ,size(vsmall)) /// subtitle!ytitle("") /// y label!
	xti("Age (mois)",size(vsmall)) /// x label!
ytitle("Probabilité de survie (%)",size(vsmall)) /// y label!
yla(.90 "90%"  0.92 "92%"  0.94 "94%"   .96"96%"  .98"98%"  1"100%", ///
angle(0)) /// Y-label values! Angle(0) rotates them.
xla(0(10)60) /// X-label values! From 0 to 6 years with 1 year intervals in between
    legend(order (1 "GMM corésident" 2 "GMM non corésident   -   (log-rank p < 0.05)"  ///
        3 "GPM corésident" 4 "GPM non corésident   -   (log-rank p < 0.05)" ///
        5 "GMP corésident" 6 "GMP non corésident   -   (log-rank p > 0.05)" ///        
        7 "GPP corésident" 8 "GPP non corésident   -   (log-rank p < 0.05") rows(4) position (6) size(vsmall)) ///
		note("GMM : Grand-mère maternelle; GMP : Grand-mère paternelle" "GPM : Grand-père maternel; GPP :Grand-père paternel" , span size(vsmall)) 
		

graph save "Figure (gparents) 2",replace 
graph export "Figure (gparents) 2.png", replace width(2000)
graph export "Figure (gparents) 2.tif", replace width(2000)
	

	
// stat des uncles and aunts

sts gen s_coresid_maunt = s, by(coresid_maunt)
sts gen s_coresid_muncle = s, by(coresid_muncle)
sts gen s_coresid_paunt = s, by(coresid_paunt)
sts gen s_coresid_puncle = s, by(coresid_puncle)

sts test coresid_maunt, logrank /*0.0681*/
sts test coresid_muncle, logrank /* 0.0000*/
sts test coresid_paunt, logrank /*0.9984*/
sts test coresid_puncle, logrank /*0.0667*/


sort _t
twoway connected s_coresid_maunt _t if coresid_maunt==1, connect(J) msymbol(none) lstyle(p1) ///
    || connected s_coresid_maunt _t if coresid_maunt==0, connect(J) msymbol(none) lstyle(p1)  lpattern(dash) ///
    || connected s_coresid_muncle _t if coresid_muncle==1, connect(J) msymbol(none) lstyle(p2) ///
    || connected s_coresid_muncle _t if coresid_muncle==0, connect(J) msymbol(none) lstyle(p2) lpattern(dash) ///
    || connected s_coresid_paunt _t if coresid_paunt==1, connect(J) msymbol(none) lstyle(p3) ///
    || connected s_coresid_paunt _t if coresid_paunt==0, connect(J) msymbol(none) lstyle(p3) lpattern(dash) ///
    || connected s_coresid_puncle _t if coresid_puncle==1, connect(J) msymbol(none) lstyle(p4) ///
    || connected s_coresid_puncle _t if coresid_puncle==0, connect(J) msymbol(none) lstyle(p4) lpattern(dash) ///
	xti("Age (mois)" ,size(vsmall)) /// x label!
title("Courbes de survie selon la",size(vsmall)) /// Title!
t1title("corésidence avec les oncles et les tantes",size(vsmall)) /// subtitle!ytitle("") /// y label!
ytitle("",size(vsmall)) ///
yla(.90 "90%"  0.92 "92%"  0.94 "94%"   .96"96%"  .98"98%"  1"100%", ///
angle(0)) /// Y-label values! Angle(0) rotates them.
xla(0(10)60) /// X-label values! From 0 to 6 years with 1 year intervals in between
    legend(order (1 "TM corésidente" 2 "TM non corésidente   -   (log-rank p > 0.05)"  ///
        3 "OM corésident" 4 "OM non corésident   -   (log-rank p < 0.01)" ///
        5 "TP corésident" 6 "TP non corésident   -   (log-rank p > 0.05)" ///        
        7 "OP corésident" 8 "OP non corésident   -   (log-rank p > 0.05)") rows(4) position (6) size(vsmall)) ///
		note("TM : Tante maternelle; TP : Tante paternelle" "OM : Oncle maternel; OP : Oncle paternel" , span size(vsmall)) 
		
graph save "Figure (oncles_tantes) 2",replace 
graph export "Figure (oncles_tantes) 2.png", replace width(2000)
graph export "Figure (oncles_tantes) 2.tif", replace width(2000)
	
graph combine "Figure (gparents) 2.gph" "Figure (oncles_tantes) 2.gph", row(1)

graph save "Figure (oncles_tantes_gp) 2",replace 
graph export "Figure (oncles_tantes_gp) 2.png", replace width(2000)
graph export "Figure (oncles_tantes_gp) 2.tif", replace width(2000)

	
grc1leg "Figure (gparents) 2.gph" "Figure (oncles_tantes) 2.gph", row(1) ring(0) span ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))
	
*sts graph, by(coresidMGM coresidMGF)
XX


* Modèle test [juste pour voir si ca va dans le bon sens]
stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      i.MigDeadO_O_DTH_TVC i.MigDeadY_Y_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGF##ib0.coresidPGM  ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle 


* Modèle test [juste pour voir si ca va dans le bon sens]

* Under5 mortality
* Setting mortality analysis <5-year-old 
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)

log using mort_results,replace
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)

stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      ib7.birth_int_gp_YS_new ib0.res_Y_DTH_TVC  ///
	  ib4.MigDeadO_interv_new ib0.res_O_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGM##ib0.coresidPGF  ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle  ///
	  , vce(cluster MotherId) iter(10)
	 log close

	 
log using mort_results_bis,replace
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)
bootstrap, rep(2) seed(09051986) : stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      ib7.birth_int_gp_YS_new ib0.res_Y_DTH_TVC  ///
	  ib4.MigDeadO_interv_new ib0.res_O_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGM##ib0.coresidPGF  ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle  ///
	  , vce(cluster MotherId) iter(10) 
	 log close
*est store u5
*esttab u5, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 
 
set scheme s1color 
 **Coefplot relative to paternal gran-parents
 matrix list e(b)
 
 coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(1.coresidPGM 	1.coresidPGF  1.coresidPGM#1.coresidPGF) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(1.coresidPGM=`""Grand-mère" "uniquement""' ///
			  1.coresidPGF =`""Grand-père" "uniquement""' 1.coresidPGM#1.coresidPGF=`""Grand-mère" "et" "Grand-père""' ///
			,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(1.coresidPGM=`""{bf: Grands-parents}" "{bf: paternels}" "Ref: Aucun""' , labcolor(blue)) ///
		xlabel(0.5 1 2, format(%9.2f)) xscale(log range(0.5 2)) baselevels
graph save p_grand_parents,replace

 
 **Coefplot relative to maternal grand-parents
 matrix list e(b)
 
 coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(1.coresidMGM 	1.coresidMGF  1.coresidMGM#1.coresidMGF) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(1.coresidMGM=`""Grand-mère" "uniquement""' ///
			  1.coresidMGF =`""Grand-père" "uniquement""' 1.coresidMGM#1.coresidMGF=`""Grand-mère" "et" "Grand-père""' ///
			,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(1.coresidMGM=`""{bf: Grands-parents}" "{bf: maternels}" "Ref: Aucun""' , labcolor(blue)) ///
		xlabel(0.5 1 2, format(%9.2f)) xscale(log range(0.5 2)) baselevels
graph save m_grand_parents,replace

 
 grc1leg "p_grand_parents.gph" "m_grand_parents.gph", row(1) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph save "grand_parents",replace 

graph export "grand_parents.png", replace width(2000)
graph export "grand_parents.tif", replace width(2000)



 **Coefplot relative to maternal uncles and aunts
 
 set scheme s1color 
 matrix list e(b)
 
 coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(1.coresid_maunt 1.coresid_muncle ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(1.coresid_maunt="Résidente" 	1.coresid_muncle ="Résident"  ///
			,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(1.coresid_maunt=`""{bf: Tante maternelle}" "Ref: Non résident""'  ///
		1.coresid_muncle=`""{bf: Oncle maternel}"  "Ref: Non résident""', labcolor(blue)) ///
		xlabel(0.5 1 2, format(%9.2f)) xscale(log range(0.5 2)) baselevels
graph save m_aunts_uncles,replace


 **Coefplot relative to paternal uncles and aunts

 coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(1.coresid_paunt 1.coresid_puncle ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(1.coresid_paunt="Résidente" 	1.coresid_puncle ="Résident"  ///
			,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(1.coresid_paunt=`""{bf: Tante paternelle}" "Ref: Non résident""'  ///
		1.coresid_puncle=`""{bf: Oncle paternel}"  "Ref: Non résident""', labcolor(blue)) ///
		xlabel(0.5 1 2, format(%9.2f)) xscale(log range(0.5 2)) baselevels
graph save p_aunts_uncles,replace

 
  grc1leg "p_aunts_uncles.gph" "m_aunts_uncles.gph", row(1) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph save "aunts_uncles",replace 

graph export "aunts_uncles.png", replace width(2000)
graph export "aunts_uncles.tif", replace width(2000)



XX
 graph combine p_grand_parents.gph m_grand_parents.gph ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))

* Grand parents
coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(1.presenceMGF_bis  2.presenceMGF_bis 1.presencePGF_bis 2.presencePGF_bis ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(1.presenceMGF_bis="Resident & < 65yrs" 2.presenceMGF_bis="Resident & > 65yrs" ///
		            1.presencePGF_bis="Resident & < 65yrs" 2.presencePGF_bis="Resident & > 65yrs" ///
				,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(1.presenceMGF_bis=`""{bf:Maternal Grand Father}" "Ref : Non-resident""' ///
		1.presencePGF_bis=`""{bf:Paternal Grand Father}" "Ref : Non-resident ""' ///
				, labcolor(blue)) ///
		xlabel(0.5 1 2 4, format(%9.2f)) xscale(log range(0.5 5)) baselevels
graph save graph_MGF_PGF,replace



 
 
 
 
stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      ib9.birth_int_gp_YS_new ib0.res_Y_DTH_TVC  ///
	  ib4.MigDeadO_interv_new ib0.res_O_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.Pgrandparents ///
	  ib0.Mgrandparents ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle  ///
	  , vce(cluster MotherId) iter(10)


* 0 - 1 ans
* Setting mortality analysis <1-year-old 
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*1)+212000000) scale(31557600000)

stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      ib7.birth_int_gp_YS_new ib0.res_Y_DTH_TVC  ///
	  ib4.MigDeadO_interv_new ib0.res_O_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGF##ib0.coresidPGM  ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle  ///
	  , vce(cluster MotherId) iter(10)
	  
* 1 - 4 ans
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB + 31557600000) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)

stcox i.gender ib20.hdss_period i.MigDeadMO_MO_DTH_TVC i.MigDeadFA_FA_DTH_TVC ///
      ib7.birth_int_gp_YS_new ib0.res_Y_DTH_TVC  ///
	  ib4.MigDeadO_interv_new ib0.res_O_DTH_TVC ///
	  i.MigDeadTwin_Twin_DTH_TVC ib21.y3_mother_age_birth ///
	  ib0.coresidMGM##ib0.coresidMGF ///
	  ib0.coresidPGF##ib0.coresidPGM  ///
	  ib0.coresid_maunt ib0.coresid_muncle ///
	  ib0.coresid_paunt ib0.coresid_puncle  ///
	  ,vce(cluster MotherId) iter(10)
	  
XX
	  
* Basic model without macro, but with Centre*period "fixed effect"
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 
est store u5
esttab u5, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 
esttab u5, eform p wide lab mtitle sca(chi2 ll N_sub risk N_fail) 		









**********************************************************************************************************


use analysis_final,clear


* To detect some very few inconsistencies due to same date of events
sort concat_IndividualId EventDate
qui bys concat_IndividualId (EventDate): gen foll_MigDeadMO=MigDeadMO[_n+1]
lab var foll_MigDeadMO "Following event"
lab val foll_MigDeadMO MigDeadMO
tab MigDeadMO foll_MigDeadMO, missing
browse concat_IndividualId DoB EventDate MotherId MigDeadMO if foll_MigDeadMO<3 & MigDeadMO==3
browse  DoB EventDate MotherId MigDeadMO if concat_IndividualId=="288GH03169729"

qui bys concat_IndividualId (EventDate): gen foll_MigDeadO=MigDeadO[_n+1]
lab var foll_MigDeadO "Following event"
lab val foll_MigDeadO MigDeadO
tab MigDeadO foll_MigDeadO, missing

qui bys concat_IndividualId (EventDate): gen foll_MigDeadY=MigDeadY[_n+1]
lab var foll_MigDeadY "Following event"
lab val foll_MigDeadY MigDeadY
tab MigDeadY foll_MigDeadY, missing
*/

*tab CentreId if lastrecord==1 

/* Without birth intervals, for ERC proposal
log using model_ERC_080818,replace
stcox ib2.MigDeadMO ib2.MigDeadO i.Sex ib21.y3_mother_age_birth ib0.migrant_statusMO ///
        ib2.MigDeadY  ib0.twin i.period, vce(cluster MotherId)
estimates store model_ERC_090818
matrix list e(b)

coefplot, yline(1) eform levels(95) ///
		keep(1.MigDeadMO  3.MigDeadMO ///
			0.MigDeadO 1.MigDeadO  3.MigDeadO  0.MigDeadY 1.MigDeadY  3.MigDeadY) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*2) xlabel(, angle(vertical)) ///
		coeflabels(1.MigDeadMO = "non resident" 3.MigDeadMO ="dead" ///
				0.MigDeadO ="none" 1.MigDeadO="non resident" 3.MigDeadO="dead" ///
				0.MigDeadY ="none" 1.MigDeadY="non resident" 3.MigDeadY="dead", ///
				notick labsize(small) labcolor(purple) labgap(2)) ///
		vertical ///
		groups(1.MigDeadMO 3.MigDeadMO = "{bf:Mother}" 0.MigDeadO 1.MigDeadO 3.MigDeadO = "{bf:Older sibling}" ///
				0.MigDeadY 1.MigDeadY 3.MigDeadY = "{bf:Younger sibling}") 
log close
*/
tab hdss if censor_death==1 & _st==1 //to count number of deaths in each hdss
/* Under-5 Deaths  
*/

table hdss [iw=_t-_t0], content(freq) format(%10.0f) missing row //to count person-years in each hdss 
//(the weight is for providing the duration for each line- ie the exposure period, if not used it just gives number of lines/events and not the length of period between the events)
/* Under-5 PYAR
 
*/
table MigDeadY gp_ecart_Y_new [iw=_t-_t0], content(freq) format(%10.0f) missing //PYARS for each category
table MigDeadO gp_ecart_O_new [iw=_t-_t0], content(freq) format(%10.0f) missing
* To get "No Older Sibling" as the baseline when including both MigDeadO ib0.gp_ecart_Ores in the model
cap drop MigDeadObis
recode MigDeadO (2=0), gen(MigDeadObis)
lab val MigDeadObis MigDeadO
tab MigDeadObis gp_ecart_Ores_new 
table MigDeadY_Y_DTH_TVC gp_birth_int_YS [iw=_t-_t0], content(freq) format(%10.0f) missing
table MigDeadO_O_DTH_TVC gp_ecart_O [iw=_t-_t0], content(freq) format(%10.0f) missing


gen p1000censor_death=censor_death*1000
table birth_int_gp_YS MigDeadY_Y_DTH_TVC  [iw=_t-_t0], content(freq) format(%10.0f) missing
table birth_int_gp_YS MigDeadY_Y_DTH_TVC  [iw=_t-_t0], content(mean p1000censor_death) missing
table gp_ecart_Ores_new  MigDeadO_O_DTH_TVC [iw=_t-_t0], content(freq) format(%10.0f) missing
table gp_ecart_Ores_new  MigDeadO_O_DTH_TVC [iw=_t-_t0], content(mean p1000censor_death) missing
table res_Twin_DTH_TVC  [iw=_t-_t0], content(freq) format(%10.0f) missing
table res_Twin_DTH_TVC  [iw=_t-_t0], content(mean p1000censor_death) missing
table period [iw=_t-_t0], content(mean rain mean PREC_NEW mean TEMP_NEW)  missing
/*
   period |     mean(rain)  mean(PREC_NEW)  mean(TEMP_NEW)
----------+-----------------------------------------------
     1990 |       658.4963        877.2901        26.79589
     1995 |       812.0327        939.6726        25.76668
     2000 |       901.4801        1026.887        25.46796
     2005 |        940.505        1082.506        24.76947
     2010 |       996.9833        1064.584        24.48016
     2015 |       969.3855         976.555        23.34827
*/
table period [iw=_t-_t0], content(mean travel mean vacc mean edu mean hiv mean gdp_ppp_)  missing
/*
   period | mean(travel)    mean(vacc)     mean(edu)     mean(hiv)  mean(gdp_~_)
----------+---------------------------------------------------------------------
     1990 |     144.5116             .             .             .      .6165305
     1995 |     174.1794             .             .             .     .57485906
     2000 |     209.6926      8.874839       3.39524      6.264101     .58444086
     2005 |     230.3512      8.947402      4.189189      6.477051     .90230432
     2010 |      258.483      8.322821      3.824535      5.194046             .
     2015 |      268.872      8.339012      4.841929      7.656536             .
*/

save, replace

* Extract indicator of Older sibling death (including before index child birth)
use osibling.dta, clear
keep if OsiblingId!=""
bysort concat_IndividualId (EventDate): egen byte everDeadO =max(EventCodeO==7) 
keep concat_IndividualId everDeadO
duplicates drop
save everDeadO, replace
use analysis_final,clear
merge m:1 concat_IndividualId using everDeadO.dta
drop if _merge==2
drop _merge
recode everDeadO (.=0)
capture drop DeadOafterDoB
bysort concat_IndividualId (EventDate): egen byte DeadOafterDoB =max(res_O_DTH_TVC!=0) 
capture drop DeadObeforeDoB
gen byte DeadObeforeDoB=everDeadO==1 & DeadOafterDoB==0 & MigDeadO!=1

compress
save analysis_final, replace

XX
************************************************************************************************
cd "C:\Users\menasheoren\Documents\UCLouvain\imocha\paper child mortality and siblings\2018 analysis\"

*log using session08-08-2019, replace
use analysis_final,clear

* To mimick Molitoris et al (2019) for <1 without/with younger sibling and no twin
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+31557600000+106000000) scale(31557600000)
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		/*ib0.MigDeadTwin_Twin_DTH_TVC */ ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        /* ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC */ ///
		if MigDeadTwin_Twin_DTH_TVC==9  ///
		, vce(cluster MotherId) iter(10) 
est store u1_noY
esttab u1_noY, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 		

stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC  ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        /* ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC */ ///
		/*if MigDeadTwin_Twin_DTH_TVC==9 */ ///
		, vce(cluster MotherId) iter(10) 
est store u1_twin
esttab u1_twin, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 		

		
outreg2 using Analyses_under1_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_under1_noY, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_under1_noY, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_under1_noY, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_under1_noY, word stats(ci_high) ///
	cdec(2) nor2 eform  
	
* Same with	twins and younger sibling
* Simple codes for younger sibling (because <1 year)
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib0.MigDeadY ib0.birth_int_YS ///
		, vce(cluster MotherId) iter(20)
est store u1
esttab u1, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 		

outreg2 using Analyses_under1_Y, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_under1_Y, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_under1_Y, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_under1_Y, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_under1_Y, word stats(ci_high) ///
	cdec(2) nor2 eform  	
	
*To mimick Molitoris et al (2019) for 1-4 without/with younger sibling and no twin
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB+31557600000+106000000) ///
		exit(time DoB+(5*31557600000)+212000000) scale(31557600000)
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		/* ib0.MigDeadTwin_Twin_DTH_TVC */ ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        /* ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC */ ///
		if MigDeadTwin_Twin_DTH_TVC==9 ///
		, vce(cluster MotherId) iter(10) 

stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC  ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC  ///
		/*if MigDeadTwin_Twin_DTH_TVC==9 */ ///
		, vce(cluster MotherId) iter(10)
		
est store age1to4
esttab age1to4, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 
		
outreg2 using Analyses_1-4_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_1-4_noY, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_1-4_noY, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_1-4_noY, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_1-4_noY, word stats(ci_high) ///
	cdec(2) nor2 eform  	
	
* Same with	twins and younger sibling
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10)
est store onefour		
		
outreg2 using Analyses_1-4_Y, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_1-4_Y, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_1-4_Y, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_1-4_Y, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_1-4_Y, word stats(ci_high) ///
	cdec(2) nor2 eform  	
	
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) scale(31557600000)
/*  583,145  subjects
     41,393  failures in single-failure-per-subject data
  1,819,653  total analysis time at risk and under observation
*/
* To mimick Molitoris et al (2019) for <5 without/with younger sibling and no twin
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		/* ib0.MigDeadTwin_Twin_DTH_TVC */ ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        /* ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC */ ///
		if MigDeadTwin_Twin_DTH_TVC==9 ///
		, vce(cluster MotherId) iter(10) 
		
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC  ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        /* ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC */ ///
		, vce(cluster MotherId) iter(10) 
est store u5_noys
esttab u5_noys, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail)		
		
outreg2 using Analyses_under5_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_under5_noY, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_under5_noY, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_under5_noY, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_under5_noY, word stats(ci_high) ///
	cdec(2) nor2 eform  	

* Full model for under5

table CentreId [iw=_t-_t0], content(freq) format(%10.0f) missing row // person-years per site
tab CentreId if censor_death==1 & _st==1 // number of deaths per site
tab CentreId if last_obs==1 //number of children under 5 per site

* Basic model without macro, but with Centre*period "fixed effect"
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 
est store u5
esttab u5, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 
esttab u5, eform p wide lab mtitle sca(chi2 ll N_sub risk N_fail) 		
		
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib0.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 		
est store u5_preg		
		
outreg2 using Analyses_under5, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_under5, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_under5, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_under5, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_under5, word stats(ci_high) ///
	cdec(2) nor2 eform  		
log close


stcurve, hazard yscale(log) kernel(rectangle) width(.08333)  ///
        at(Sex=1 period=2000 y3_mother_age_birth=21 MigDeadMO_MO_DTH_TVC=0 migrant_statusMO=0 ///
		MigDeadTwin_Twin_DTH_TVC=9 ///
		MigDeadO_int=24 res_O_DTH_TVC=0 ///
		birth_int_gp_YS=230 res_Y_DTH_TVC=0 ///
		res_Y_DTH_TVC=0 CentreLab=22) outfile(baseline_curve, replace)

predict cs, csnell
sts generate km = s
generate H = -ln(km)
line H cs cs, sort ytitle("") clstyle(. refline) sav(coxsnell, replace)

predict mg, mgale
lowess mg _t, mean noweight title("") note("") m(o) sav(mgaleresid, replace)

predict dev, deviance
predict xb, xb
scatter dev xb, sav(deviance_xb, replace)

predict ld, ldisplace
predict lmax, lmax
scatter ld _t, mlabel(obs) sav(lldispl, replace)

***Full model under5 using multilevel mixed-effects parametric survival model

*first to avoid delayed entries/gaps, need to force events to start at same time- and instead of using DoB in stset use the beginning of each episode
*identifying new episodes (ie. when res changes from 0 to 1 - identified as datebeg being different to previous eventdate- and not date of birth)
sort concat_IndividualId EventDate 
bys concat_IndividualId: gen totalchange = sum(EventDate[_n-1]!=datebeg & datebeg!=DoB)
*gen ind_ep=0
*bys concat_IndividualId: replace ind_ep= cond(ind_ep<totalchange & (EventDate[_n-1]!=datebeg & datebeg!=DoB), ind_ep[_n-1]+1, ind_ep[_n-1]) if _n!=1
egen ChildID= concat(concat_IndividualId totalchange) 
*creating var with beginning of each episode
gen double start_date = DoB 
bys ChildID: replace start_date = datebeg[1]
format start_date %tC
bys ChildID: gen age_beg = (datebeg[1]- DoB) /31557600000


*stset using new date varaible & not DoB
stset EventDate if residence==1, id(ChildID) failure(censor_death==1) ///
		time0(datebeg) origin(time start_date) scale(31557600000)
		
* checking if all children start at same time: bys ChildID (EventDate): gen ind0= _t0[1]!=0		
		
mestreg i.Sex c.age_beg ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		|| MotherId:  , distribution(weibull) iter(10) 		 
		
		
		///|| concat_IndividualId:
		
/*mestreg i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		|| MotherId:, distribution(weibull) iter(10) 
	//delayed entries or gaps not allowed	
*/

* Neyman-Pearson acceptance test (a posteriori)
* prob event: 40,650 / 561,438  = .07240336
* compute standard deviation using age at death or censoring (last observation)
capture drop last_age
capture drop cum_time
capture drop last_obs
bysort concat_IndividualId (_t): egen double last_age=max(_t) if _st==1
bysort concat_IndividualId (_t): egen double cum_time=sum(_t-_t0) if _st==1
bysort concat_IndividualId (_t): gen double last_obs=last_age==_t if _st==1
summ _d  [iw=cum_time] if last_obs==1
* Event prob (weighted by person-years of exposure): .0230845 (against .07240336 unweighted) 
foreach variable of varlist Sex ///
		y3_mother_age_birth MigDeadMO_MO_DTH_TVC migrant_statusMO ///
		MigDeadTwin_Twin_DTH_TVC ///
		MigDeadO_int res_O_DTH_TVC ///
        birth_int_gp_YS res_Y_DTH_TVC ///
		{
			display "`variable' MDES for level..."
			quietly levelsof `variable', local(i)
			foreach level of local i {
				quietly gen dummy`level'=`variable'==`level'
				quietly summ dummy`level'  [iw=_t-_t0] 
				local sd = r(sd)
				drop dummy*
				quietly power cox, n(561438) power(0.95) alpha(0.05) eventprob(.0230845) r2(.2) ///
					sd(`sd') effect(hratio) direction(upper) onesided
				display "`level': >" %5.2f r(delta) " or : <" %5.2f 1/r(delta)
			}
}

quietly levelsof period, local(i)
quietly levelsof CentreLab, local(j)
foreach centre of local j {
	foreach per of local i {
		quietly gen dummy`per'_`centre'=period==`per' & CentreLab==`centre'
		quietly summ dummy`per'_`centre' [iw=_t-_t0] 
		local sd = r(sd)
		drop dummy*
		if `sd'>0 { 
			quietly power cox, n(561438) power(0.95) alpha(0.05) eventprob(.0234952) r2(.2) ///
				sd(`sd') effect(hratio) direction(upper) onesided 
			display "MDES for period : " `per' " and Centre : " `centre' " >" %6.2f r(delta) " or : <" %4.2f 1/r(delta)
		}
	}
}

** Checks 
**Graphiques
* sex + twin + period 

coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(2.Sex 1.twin 1994.period 1999.period 2004.period 2009.period) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(2.Sex="Female" 1.twin="Yes" ///
				1994.period="1994" 1999.period="1999" 2004.period="2004" 2009.period="2009" ///
				,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(2.Sex=`""{bf:Gender}" "Ref : Male""' 1.twin=`""{bf:Multiple birth}" "Ref : No ""' ///
				1994.period=`""{bf:Period}" "Ref : 1989""', labcolor(blue)) ///
		xlabel(0.5 1 2 4, format(%9.2f)) xscale(log range(0.5 5)) baselevels
graph save graph_sex_twin_period,replace

***2. relative to mother
coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(15.y3_mother_age_birth 18.y3_mother_age_birth ///
			 24.y3_mother_age_birth 27.y3_mother_age_birth 30.y3_mother_age_birth ///
			 33.y3_mother_age_birth 36.y3_mother_age_birth 39.y3_mother_age_birth ///
			 42.y3_mother_age_birth ///
			 1.MigDeadMO_MO_DTH_TVC ///
			 1.migrant_statusMO 2.migrant_statusMO ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(15.y3_mother_age_birth="15-17" 18.y3_mother_age_birth="18-21" ///
				24.y3_mother_age_birth="24-26" 27.y3_mother_age_birth="27-29" ///
				30.y3_mother_age_birth="30-32" 33.y3_mother_age_birth="33-35" ///
				36.y3_mother_age_birth="36-38" 39.y3_mother_age_birth="39-41" ///
				42.y3_mother_age_birth="42+" ///
				1.MigDeadMO_MO_DTH_TVC="Non-resident" ///
				1.migrant_statusMO="0-24 months" 2.migrant_statusMO="2-5 years" ///
				, notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(15.y3_mother_age_birth=`""{bf: Mother´s age at birth}" "Ref: 21-23 years""' ///
				1.MigDeadMO_MO_DTH_TVC=`""{bf: Mother out-migration status}" "Ref: Permanent resident""'  ///
				1.migrant_statusMO=`""{bf:Mother in-migration status}" "Ref: Permanent resident" "or resident 10+"""', labcolor(blue)) ///
		xlabel(0.5 1 2, format(%9.1f)) xscale(log range(0.5 2)) baselevels
graph save graph_mother_1,replace

coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep(2.MigDeadMO_MO_DTH_TVC ///
			 3.MigDeadMO_MO_DTH_TVC 4.MigDeadMO_MO_DTH_TVC 5.MigDeadMO_MO_DTH_TVC ///
			 6.MigDeadMO_MO_DTH_TVC ) ///
		mlabel format(%9.1f) mlabposition(12) mlabgap(*1) ///
		coeflabels(2.MigDeadMO_MO_DTH_TVC="6-3m < death" ///
			3.MigDeadMO_MO_DTH_TVC="3m-15d < death" 4.MigDeadMO_MO_DTH_TVC="+/-15d death" ///
			5.MigDeadMO_MO_DTH_TVC="15d-3m > death" ///
			6.MigDeadMO_MO_DTH_TVC="3-6m > death"  ///
			,notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(2.MigDeadMO_MO_DTH_TVC=`""{bf: Mother death status}" "Ref: Permanent resident""' , labcolor(blue)) ///
		xlabel(1 2 5 10 20, format(%9.0f)) xscale(log range(1 20)) baselevels
graph save graph_mother_2,replace

graph combine graph_mother_2.gph graph_mother_1.gph 

* relative to twin
coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep( 9.MigDeadTwin_Twin_DTH_TVC  ///
			 1.MigDeadTwin_Twin_DTH_TVC 2.MigDeadTwin_Twin_DTH_TVC 3.MigDeadTwin_Twin_DTH_TVC ///
			 4.MigDeadTwin_Twin_DTH_TVC 5.MigDeadTwin_Twin_DTH_TVC 6.MigDeadTwin_Twin_DTH_TVC ///
			 ) ///
		order( 9.MigDeadTwin_Twin_DTH_TVC  ///
			 1.MigDeadTwin_Twin_DTH_TVC 2.MigDeadTwin_Twin_DTH_TVC 3.MigDeadTwin_Twin_DTH_TVC ///
			 4.MigDeadTwin_Twin_DTH_TVC 5.MigDeadTwin_Twin_DTH_TVC 6.MigDeadTwin_Twin_DTH_TVC ///
			 ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(9.MigDeadTwin_Twin_DTH_TVC="No twin" ///
			 1.MigDeadTwin_Twin_DTH_TVC="Twin non resident" ///
			 2.MigDeadTwin_Twin_DTH_TVC="6-3m < death" ///
			 3.MigDeadTwin_Twin_DTH_TVC="3m-15d < death" ///
			 4.MigDeadTwin_Twin_DTH_TVC="+/-15d death" ///
			 5.MigDeadTwin_Twin_DTH_TVC="15d-3m > death" ///
			 6.MigDeadTwin_Twin_DTH_TVC="3-6m > death" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(9.MigDeadTwin_Twin_DTH_TVC=`""{bf:Twin sibling status}" "Ref: Resident""' ///
				2.MigDeadTwin_Twin_DTH_TVC=`""{bf:Twin death status}" "Ref: Resident""' , labcolor(blue)) ///
		xlabel(1 2 4 8 15 30, format(%9.0f)) xscale(log range(.5 30)) baselevels
graph save graph_twin_sibling,replace

* relative to older sibling
coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep( 0.MigDeadO_interv 10.MigDeadO_interv ///
			 21.MigDeadO_interv 22.MigDeadO_interv 23.MigDeadO_interv ///
			 25.MigDeadO_interv 26.MigDeadO_interv 27.MigDeadO_interv 28.MigDeadO_interv ///
			 1.res_O_DTH_TVC 2.res_O_DTH_TVC 3.res_O_DTH_TVC ///
			 4.res_O_DTH_TVC 5.res_O_DTH_TVC ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(0.MigDeadO_interv="No older sibling" ///
			 10.MigDeadO_interv="Non resident" ///
			 21.MigDeadO_interv="O int <12m" 22.MigDeadO_interv="O int 12-17m" ///
			 23.MigDeadO_interv="O int 18-23m" 25.MigDeadO_interv="O int 30-35m" ///
			 26.MigDeadO_interv="O int 36-41m" 27.MigDeadO_interv="O int 42-47m" ///
			 28.MigDeadO_interv="O int 48m +" ///
			 1.res_O_DTH_TVC="6-3m < death" 2.res_O_DTH_TVC="3m-15d < death" ///
			 3.res_O_DTH_TVC="+/-15d death" 4.res_O_DTH_TVC="15d-3m > death" ///
			 5.res_O_DTH_TVC="3-6m > death" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(0.MigDeadO_interv=`""{bf:Older sibling status}" "Ref: Resident""' ///
				21.MigDeadO_interv=`""{bf:Birth interval with older sibling}" "Ref: 24-29m""' ///
				1.res_O_DTH_TVC=`""{bf:Older sibling death status}" "Ref: Resident""' , labcolor(blue)) ///
		xlabel(1 2 4 8, format(%9.1f)) xscale(log range(.7 8)) baselevels
graph save graph_older_sibling, replace

* relative to younger sibling
coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep( 0.birth_int_gp_YS 100.birth_int_gp_YS ///
			 1.res_Y_DTH_TVC 2.res_Y_DTH_TVC 3.res_Y_DTH_TVC ///
			 4.res_Y_DTH_TVC 5.res_Y_DTH_TVC ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels(0.birth_int_gp_YS="No younger sibling" ///
			 100.birth_int_gp_YS="Non resident" ///
			 1.res_Y_DTH_TVC="6-3m < death" 2.res_Y_DTH_TVC="3m-15d < death" ///
			 3.res_Y_DTH_TVC="+/-15d death" 4.res_Y_DTH_TVC="15d-3m > death" ///
			 5.res_Y_DTH_TVC="3-6m > death" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings(0.birth_int_gp_YS=`""{bf:Younger sibling status}" "Ref: Resident""' ///
				1.res_Y_DTH_TVC=`""{bf:.    Younger sibling death status}" "Ref: Resident""' , labcolor(blue)) ///
		xlabel(1 2 4 8, format(%9.1f)) xscale(log range(.7 8)) baselevels
graph save graph_younger_sibling, replace

coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep( 1.birth_int_gp_YS  11.birth_int_gp_YS  21.birth_int_gp_YS  31.birth_int_gp_YS  ///
			 41.birth_int_gp_YS  51.birth_int_gp_YS  61.birth_int_gp_YS  71.birth_int_gp_YS ///
			200.birth_int_gp_YS 210.birth_int_gp_YS 220.birth_int_gp_YS  ///
			240.birth_int_gp_YS 250.birth_int_gp_YS 260.birth_int_gp_YS 270.birth_int_gp_YS ///
			300.birth_int_gp_YS 310.birth_int_gp_YS 320.birth_int_gp_YS 330.birth_int_gp_YS  ///
			340.birth_int_gp_YS 350.birth_int_gp_YS 360.birth_int_gp_YS  ///
			400.birth_int_gp_YS 410.birth_int_gp_YS 420.birth_int_gp_YS 430.birth_int_gp_YS  ///
			440.birth_int_gp_YS 450.birth_int_gp_YS 460.birth_int_gp_YS  ///
			) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels( 1.birth_int_gp_YS="Int <12m"  11.birth_int_gp_YS="Int 12-17m" ///
			21.birth_int_gp_YS="Int 18-23m"  31.birth_int_gp_YS="Int 24-29m" ///
			41.birth_int_gp_YS="Int 30-35m"  51.birth_int_gp_YS="Int 36-41m" ///
			61.birth_int_gp_YS="Int 42-47m"  71.birth_int_gp_YS="Int >=48m+" ///
			200.birth_int_gp_YS="Int <12m" 210.birth_int_gp_YS="Int 12-17m" ///
			220.birth_int_gp_YS="Int 18-23m"  ///
			240.birth_int_gp_YS="Int 30-35m" 250.birth_int_gp_YS="Int 36-41m" ///
			260.birth_int_gp_YS="Int 42-47m" 270.birth_int_gp_YS="Int >=48m+" ///
			300.birth_int_gp_YS="Int <12m" 310.birth_int_gp_YS="Int 12-17m" ///
			320.birth_int_gp_YS="Int 18-23m" 330.birth_int_gp_YS="Int 24-29m"  ///
			340.birth_int_gp_YS="Int 30-35m" 350.birth_int_gp_YS="Int 36-41m" ///
			360.birth_int_gp_YS="Int 42-47m"  ///
			400.birth_int_gp_YS="Int <12m" 410.birth_int_gp_YS="Int 12-17m" ///
			420.birth_int_gp_YS="Int 18-23m" 430.birth_int_gp_YS="Int 24-29m"  ///
			440.birth_int_gp_YS="Int 30-35m" 450.birth_int_gp_YS="Int 36-41m" ///
			460.birth_int_gp_YS="Int 42-47m"  ///
			, notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( 1.birth_int_gp_YS=`"{bf: 6-m pregnant with younger sibling}"' ///
				200.birth_int_gp_YS=`""{bf: 0-5m after younger sibling birth}" "Ref: Int 24-29m - 0-5m" " ""' ///
				300.birth_int_gp_YS=`"{bf: 5-11m after younger sibling birth}"' ///
				400.birth_int_gp_YS=`"{bf: 12m+ after younger sibling birth}"' ///
				, labcolor(blue)) ///
		xlabel(0.5 1 2 4, format(%9.1f)) xscale(log range(0.5 5)) baselevels
graph save graph_after_before_ysib_birth, replace 

* plot death bell-curves
* use order(coeflist) option
coefplot, xline(1) eform xtitle(Hazards Ratio) levels(95) ///
		keep( 2.MigDeadMO_MO_DTH_TVC ///
			 3.MigDeadMO_MO_DTH_TVC 4.MigDeadMO_MO_DTH_TVC 5.MigDeadMO_MO_DTH_TVC ///
			 6.MigDeadMO_MO_DTH_TVC ///
			 2.MigDeadTwin_Twin_DTH_TVC 3.MigDeadTwin_Twin_DTH_TVC ///
			 4.MigDeadTwin_Twin_DTH_TVC 5.MigDeadTwin_Twin_DTH_TVC 6.MigDeadTwin_Twin_DTH_TVC ///
			 1.res_O_DTH_TVC 2.res_O_DTH_TVC 3.res_O_DTH_TVC ///
			 4.res_O_DTH_TVC 5.res_O_DTH_TVC ///
			 1.res_Y_DTH_TVC 2.res_Y_DTH_TVC 3.res_Y_DTH_TVC ///
			 4.res_Y_DTH_TVC 5.res_Y_DTH_TVC ) ///
		order( 2.MigDeadMO_MO_DTH_TVC ///
			 2.MigDeadTwin_Twin_DTH_TVC ///
			 1.res_O_DTH_TVC ///
			 1.res_Y_DTH_TVC ///
			 3.MigDeadMO_MO_DTH_TVC ///
			 3.MigDeadTwin_Twin_DTH_TVC ///
			 2.res_O_DTH_TVC ///
			 2.res_Y_DTH_TVC ///
			 4.MigDeadMO_MO_DTH_TVC ///
			 4.MigDeadTwin_Twin_DTH_TVC ///
			 3.res_O_DTH_TVC ///
			 3.res_Y_DTH_TVC ///
			 5.MigDeadMO_MO_DTH_TVC ///
			 5.MigDeadTwin_Twin_DTH_TVC ///
			 4.res_O_DTH_TVC ///
			 4.res_Y_DTH_TVC ///
			 6.MigDeadMO_MO_DTH_TVC ///
			 6.MigDeadTwin_Twin_DTH_TVC ///
			 5.res_O_DTH_TVC ///
			 5.res_Y_DTH_TVC  ) ///
		mlabel format(%9.2f) mlabposition(12) mlabgap(*1) ///
		coeflabels( ///
			2.MigDeadMO_MO_DTH_TVC="Mother" ///
			3.MigDeadMO_MO_DTH_TVC="Mother" ///
			4.MigDeadMO_MO_DTH_TVC="Mother" ///
			5.MigDeadMO_MO_DTH_TVC="Mother" ///
			6.MigDeadMO_MO_DTH_TVC="Mother"  ///
			2.MigDeadTwin_Twin_DTH_TVC="Twin" ///
			3.MigDeadTwin_Twin_DTH_TVC="Twin" ///
			4.MigDeadTwin_Twin_DTH_TVC="Twin" ///
			5.MigDeadTwin_Twin_DTH_TVC="Twin" ///
			6.MigDeadTwin_Twin_DTH_TVC="Twin" ///
			1.res_O_DTH_TVC="Older sibling" ///
			2.res_O_DTH_TVC="Older sibling"  ///
			3.res_O_DTH_TVC="Older sibling" ///
			4.res_O_DTH_TVC="Older sibling"  ///
			5.res_O_DTH_TVC="Older sibling" ///
			1.res_Y_DTH_TVC="Younger sibling" ///
			2.res_Y_DTH_TVC="Younger sibling"  ///
			3.res_Y_DTH_TVC="Younger sibling" ///
			4.res_Y_DTH_TVC="Younger sibling"  ///
			5.res_Y_DTH_TVC="Younger sibling" ///
			 , notick labsize(small) labcolor(purple) labgap(2)) ///
		headings( ///
		2.MigDeadMO_MO_DTH_TVC=`""{bf: 6-3m < death}" 	"Ref: Resident""' ///
		3.MigDeadMO_MO_DTH_TVC=`""{bf:3m-15d < death}" 	"Ref: Resident""' ///
		4.MigDeadMO_MO_DTH_TVC=`""{bf:+/-15d death}" 	"Ref: Resident""' ///
		5.MigDeadMO_MO_DTH_TVC=`""{bf:15d-3m > death}" 	"Ref: Resident""' ///
		6.MigDeadMO_MO_DTH_TVC=`""{bf:3-6m > death}" 	"Ref: Resident""' ///
		, labcolor(blue)) ///
		xlabel(1 2 4 8 15 30 50, format(%9.0f)) xscale(log range(1 50)) baselevels

graph save graph_all_death, replace

 Some potential model simplifications:
*	- mother's age as continuous variable + squared
*	- all sibling's death (twin + younger + older)
*	- younger sibling: tvc (log?) from pregnancy for each birth interval

capture drop All_siblings_DTH_TVC
gen All_siblings_DTH_TVC=	///
					cond(MigDeadTwin_Twin_DTH_TVC<2 | res_O_DTH_TVC<1 | res_Y_DTH_TVC<1,0, ///
					cond(MigDeadTwin_Twin_DTH_TVC==2 | res_O_DTH_TVC==1 | res_Y_DTH_TVC==1,1, ///
					cond(MigDeadTwin_Twin_DTH_TVC==3 | res_O_DTH_TVC==2 | res_Y_DTH_TVC==2,2, ///
					cond(MigDeadTwin_Twin_DTH_TVC==4 | res_O_DTH_TVC==3 | res_Y_DTH_TVC==3,3, ///
					cond(MigDeadTwin_Twin_DTH_TVC==5 | res_O_DTH_TVC==4 | res_Y_DTH_TVC==4,4, ///
					cond(MigDeadTwin_Twin_DTH_TVC==6 | res_O_DTH_TVC==5 | res_Y_DTH_TVC==5,5, ///
					7))))))
replace MigDeadTwin_Twin_DTH_TVC=9 if MigDeadTwin==0
label define lAll_siblings_DTH_TVC 0 "Other" 	///
						1 "-6m to -3m sibling's death" 	2 "-3m to -15d sibling's death" ///
						3 "+/- 15d sibling's death" 	4 "15d to 3m sibling's death" ///
						5 "+3m to +6m sibling's death" 	6 "6m+ sibling's death" ///
						, modify
label val All_siblings_DTH_TVC lAll_siblings_DTH_TVC

recode MigDeadTwin (2 3 4=2), gen(MigDeadTwin2)
lab val MigDeadTwin2 MigDeadTwin
recode MigDeadO (2 3 4=2), gen(MigDeadO2)
lab val MigDeadO2 MigDeadO
recode MigDeadY (2 3 4=2), gen(MigDeadY2)
lab val MigDeadY2 MigDeadY
recode  gp_ecart_Yres (6/16=6), gen(gp_ecart_Yres2)
lab val gp_ecart_Yres2 gp_age_sy
recode birth_int_YS (.=0)
replace birth_int_YS=0 if MigDeadY2==1
lab def lbirth_int_YS 0 "no younger sibling", modify

egen Centre_period=group(CentreLab period), label
tab Centre_period [iw=_t-_t0]
recode Centre_period (35 36 37=38)

stcox 	i.Sex ib75.Centre_period ///
		c.mother_age_birth c.mother_age_birth#c.mother_age_birth ///
		ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin2  ///
		ib0.MigDeadO2  ///
		ib2.MigDeadY2 ib0.gp_ecart_Yres2 ib0.birth_int_YS ///
        ib0.All_siblings_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 
outreg2 using Analyses_under5simple, label word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
outreg2 using Analyses_under5simple, word stats(se) ///
	sdec(2) nor2 eform
outreg2 using Analyses_under5simple, word stats(pval) ///
	pdec(3) nor2 eform
outreg2 using Analyses_under5simple, word stats(ci_low) ///
	cdec(2) nor2 eform  		
outreg2 using Analyses_under5simple, word stats(ci_high) ///
	cdec(2) nor2 eform  		


/* Parametric model (polynomial 2 nodes)
stpm2 i.Sex ib2000.period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib9.MigDeadTwin_Twin_DTH_TVC ///
		ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		ib22.CentreLab ///
		, df(3) scale(hazard) eform
graph twoway (rarea hstpm_lci hstpm_uci _t, pstyle(ci) sort) ///
	(line hstpm _t, sort clpattern(l)), ///
	yscale(log) legend(off) sav(pm_df3, replace)
*/

/* Basic model with macro, but without Centre "fixed effect"
stcox 	i.Sex ib2000.period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.twin ///
		ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		PREC_NEW TEMP_NEW /* rain */ travel ///
		ib1.urbanicity ///
		, /*vce(cluster MotherId)*/
* with square terms for macro
stcox 	i.Sex ib2000.period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib9.MigDeadTwin_Twin_DTH_TVC ///
		ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		c.PREC_NEW c.PREC_NEW#c.PREC_NEW c.TEMP_NEW c.TEMP_NEW#c.TEMP_NEW /* rain */ ///
		c.travel c.travel#c.travel ///
		, /*vce(cluster MotherId)*/
* limited to 2000+ but interesting
stcox 	i.Sex ib2000.period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib9.MigDeadTwin_Twin_DTH_TVC ///
		ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		PREC_NEW TEMP_NEW /* rain */ travel vacc edu  ///
		ib1.urbanicity ///
		, /*vce(cluster MotherId)*/
* with square terms for macro
stcox 	i.Sex ib2000.period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib9.MigDeadTwin_Twin_DTH_TVC ///
		ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		c.PREC_NEW c.PREC_NEW#c.PREC_NEW c.TEMP_NEW c.TEMP_NEW#c.TEMP_NEW /* rain */ ///
		c.travel c.travel#c.travel ///
		c.vacc c.vacc#c.vacc c.edu c.edu#c.edu  ///
		, /*vce(cluster MotherId)*/

* limited to 2000-2009 (to account for GDP)
* Note: reducing effect of HIV neutralised by GDP => HIV correlated with GDP
stcox 	i.Sex ib2000.period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib9.MigDeadTwin_Twin_DTH_TVC ///
		ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		PREC_NEW TEMP_NEW /* rain */ travel vacc edu hiv gdp_ppp_ ///
		, /*vce(cluster MotherId)*/
*/
		
estimates store model_standard
matrix list e(b)

*Yac18082018
capture drop MigDeadMO_migrant_statusMO
gen MigDeadMO_migrant_statusMO = cond(MigDeadMO==2 & migrant_statusMO==0,0,cond(MigDeadMO==2 & migrant_statusMO!=0,1, ///
                                 cond(MigDeadMO==1,2,3)))
label define lMigDeadMO_migrant_statusMO 0 "permanent res. or res in-mig 10y+" 1 "Résident in-mig <10y" ///
			2 "mother non resident" 3 "mother dead",modify
label val MigDeadMO_migrant_statusMO lMigDeadMO_migrant_statusMO
								 
save, replace
* End of analysis for all sites (African average) 
log close

*************************************************************************************
**** Analysis of the specificity of each site as compared to the African average ****
*************************************************************************************
decode CentreLab, gen(Center_string)
global Center_string   ET051 ET061 ///
                      GH011 GH021 GH031 GM011	KE011 KE031 MW011 MZ021 ///
					  SN011 SN012 SN013	 TZ011
					   *TZ012 TZ013 ZA011 ZA021 ZA031
					   *BF021 BF041 CI011 ET021 ET031 ET041
					    
					 
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)
		
foreach lname of global Center_string {
	stcox 	i.Sex ib0.twin i.period ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadObis ib0.gp_ecart_Ores_new ///
        ib0.gp_birth_int_YS if Center_string=="`lname'", iter(11) vce(cluster MotherId)
	estimates store Model_`lname'
	outreg2 using comp_mort_HDSS_hz_02102018, excel ci  eform dec(2) ///
		addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
		e(risk), Failures, e(N_fail)) ctitle("`lname'")label  sideway
	outreg2 using comp_mort_HDSS_tstats_02102018, excel  eform dec(2) alpha(0.001, 0.01, 0.05)  ///
		noparen  tstat addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
		e(risk), Failures, e(N_fail)) ctitle("`lname'")label  sideway
}

*YaC 08102018
** Begin classification
** New (simplified) variables for classification

**Migration status
recode migrant_statusMO (0=0 "permanent res. or in-mig 10y+") (1 2 3=1 "Migrants"), ///
					gen(migrant_statusMO_cl)

*period
recode period (1989=1) (1994=2) (1999=3) (2004=4) (2009=5), gen(period_cl)

*Older sibling (ecart with older sibling)
recode gp_ecart_Ores_new (0=0 "NoOS") ///
				(1 2=1 "<18 months") (3 4=2 "18-29 months") (5 6=3 "30-41 months") ///
				(7 8 = 4 "42 months&+"), gen(gp_ecart_Ores_new_cl)
*Younger sibling
recode gp_birth_int_YS (0=0 "NoYS") (1 11 = 11 "Int <18m - pregnant") (21 31 = 21 "Int 18-29m - pregnant") ///
                       (41 51=51 "Int 30-41m - pregnant") (61 71 =71 "Int 42months&+ - pregnant") ///
					   (1000=1000 "y sibling non-res") ///
					   (2002 2012=2012 "Int <18m - 0-6m") (2022 2032=2032 "Int 18-29m - 0-6m") ///
					   (2042  2052 =2052 "Int 30-41m - 0-6m") ///
					   (2062 2072=2072 "Int 42months&+ - 0-6m") ///
					   (2003 2013=2013 "Int <18m - 6-12m") (2023 2033=2033 "Int 18-29m - 6-12m") ///
					   (2043 2053=2053 "Int 30-41m - 6-12m") (2063 2073=2073 "Int <42months&+ - 6-12m") ///
					   (2004 2014 =2014 "Int <18m - 12m&+") (2024 2034=2034 "Int 18-29m - 12m&+") ///
					   (2044 2054 =2054 "Int 30-41m - 12m&+") (2064= 2064 "Int 42months&+ - 12m&+") ///
					   (3000=3000 "y sibling dead"),gen(gp_birth_int_YS_cl)

*Mother death
recode MigDeadMO_MO_DTH_TVC (2 3=2 "-6m to -15d mother's death") (4 5=3 "-15d to 3m mother's death") ///
						(6 7=4 "+3m&+ mother's death") (0=0 "mother resident") ///
						(1=1 "mother non resident") ,gen(MigDeadMO_MO_DTH_TVC_cl)

					
						
						
*Age de la mère
replace mother_age_birth=0 if mother_age_birth==.

*Age de la mère au carrée
gen mother_age_birth_sqrd=mother_age_birth*mother_age_birth


*Age de la mère (Missing values)
gen m_age_missing_val = cond(mother_age_birth==0,1,0)
label define lm_age_missing_val 1 "Missing value" 0 "No Missing value",modify
label val m_age_missing_val lm_age_missing_val

*log using p_year_gp_birth_int_YS

decode CentreLab, gen(Center_string)
global Center_string BF021 BF041 CI011 ET021 ET031 ET041  ET051 ET061 ///
                      GH011 GH021 GH031 GM011	KE011 KE031 MW011 MZ021 ///
					  SN011 SN012 SN013	 TZ011 TZ012 TZ013 ZA011 ZA021 ZA031

foreach lname of global Center_string {
disp "`lname'"
table gp_birth_int_YS_cl [iw=_t-_t0] if Center_string=="`lname'", nol 
}



*Sex
foreach lname of global Center_string {
disp "`lname'"
table Sex [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*twin
foreach lname of global Center_string {
disp "`lname'"
table twin [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*period_cl
foreach lname of global Center_string {
disp "`lname'"
table period_cl [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*mother_age_birth
foreach lname of global Center_string {
disp "`lname'"
table c.mother_age_birth [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*mother_age_birth_sqrd
foreach lname of global Center_string {
disp "`lname'"
table mother_age_birth_sqrd [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*m_age_missing_val
foreach lname of global Center_string {
disp "`lname'"
table m_age_missing_val [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*MigDeadMO_MO_DTH_TVC_cl
foreach lname of global Center_string {
disp "`lname'"
table MigDeadMO_MO_DTH_TVC_cl [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*migrant_statusMO_cl
foreach lname of global Center_string {
disp "`lname'"
table migrant_statusMO_cl [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*MigDeadObis
foreach lname of global Center_string {
disp "`lname'"
table MigDeadObis [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*gp_ecart_Ores_new_cl
foreach lname of global Center_string {
disp "`lname'"
table gp_ecart_Ores_new_cl [iw=_t-_t0] if Center_string=="`lname'", nol 
}

*gp_birth_int_YS_cl
foreach lname of global Center_string {
disp "`lname'"
table gp_birth_int_YS_cl [iw=_t-_t0] if Center_string=="`lname'", nol 
}



**Classification
set maxiter 10
			   
foreach lname of global Center_string {
	gen center_`lname'=(Center_string=="`lname'")
	stcox 	(i.Sex ib0.twin c.period_cl c.mother_age_birth c.mother_age_birth_sqrd ib0.m_age_missing_val ///
		ib0.MigDeadMO_MO_DTH_TVC_cl ib0.migrant_statusMO_cl ///
		ib0.MigDeadObis ib0.gp_ecart_Ores_new_cl ///
        ib0.gp_birth_int_YS_cl)##center_`lname', iter(5) vce(cluster MotherId)
	estimates store Model_center`lname'
	outreg2 using comp_mort_HDSS_interaction_hz_08102018_verif, excel ci  eform dec(2) ///
		addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
		e(risk), Failures, e(N_fail)) ctitle("`lname'")label  sideway
	outreg2 using comp_mort_HDSS_interaction_tstat_08102018_verif, excel  eform dec(2) alpha(0.001, 0.01, 0.05)  ///
		noparen  tstat addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
		e(risk), Failures, e(N_fail)) ctitle("`lname'")label  sideway
}

**End classification
**************************************************************************************

**Results by site

**Analyses by country group 
* PhB: TO REVISE ACCORDING TO THE NEW RESULTS OF CLUSTER ANALYSIS
*Metric =  Gowers2
/*
 1.  BF021  Nanoro (group 1) ok
 2.  BF041  Ouagadougou (group 1) ok
 3.  CI011  Taabo (group 5) ok
 4.  ET021  Gilgel Gibe   (group 2) ok
 5.  ET031  Kilite Awlaelo (group 3) Ok
 6.  ET041  Kersa (group 3) ok
 7.  ET051  Dabat (group 4) ok 
 8.  ET061  Arba Minch  (group 3) ok
 9.  GH011  Navrongo HDSS (group 5) ok
 10. GH021  Kintampo HDSS  (group 5) ok
 11. GH031  Dodowa (<=2011) (group 4)  ok
 12. GM011  GM011	Farafenni HDSS  (group 2) ok
 13. KE011  Kilifi (group 4) ok
 14. KE031  Nairobi  (group 3) ok
 15. MW011  Karonga (group 3)  ok
 16. MZ021  Chokwe  HDSS   (group 2) ok
 17. SN011  Bandafassi (group 3)  ok
 18. SN012  IRD Mlomp (group 2) ok
 19. SN013  IRD Niakhar (group 4) ok
 20. TZ011  IHI Ifakara Rural (group 3) ok
 21. TZ012  IHI Rufiji  (group 5) ok
 22. TZ013  IHI Ifakara Urban   (group 4) ok
 23. ZA011  Agincourt (group 3) ok
 24. ZA021  Dikgale (group 3) ok
 25. ZA031  Africa Centre   (group 2) ok
*/

capture drop CentreLab
capture lab drop CentreLab
encode CentreId, gen(CentreLab)

capture drop group
recode CentreLab (1 2=1 "Group 1") (4 12 16 18 25 =2 "Group 2") ///
				(5 6 8 14 15 17 20 23 24 =3 "Group 3") (7 11 13 19 22=4 "Group 4") (3 9 10 21=5 "Group 5"), gen(group)

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
                time0(datebeg) origin(time DoB) exit(time .) scale(31557600000)

forval i=1/5 {
	stcox  i.Sex ib0.twin i.period ib21.y3_mother_age_birth ib0.MigDeadMO_migrant_statusMO ///
		ib0.MigDeadObis ib0.gp_ecart_Ores_new ///
        ib0.gp_birth_int_YS if group==`i', vce(cluster MotherId)
	estimates store Model_group`i'
	outreg2 using comp_mort_Group_interaction_hz, excel ci  eform dec(2) ///
		addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
		e(risk), Failures, e(N_fail)) ctitle("`i'") label  sideway
	outreg2 using comp_mort_Group_interaction_tstat, excel  eform dec(2) alpha(0.001, 0.01, 0.05)  ///
		noparen  tstat addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
		e(risk), Failures, e(N_fail)) ctitle("`i'") label  sideway
}



stcox  i.Sex ib0.twin i.period ib21.y3_mother_age_birth ib0.MigDeadMO_migrant_statusMO ///
		ib0.MigDeadObis ib0.gp_ecart_Ores_new ///
        ib0.gp_birth_int_YS , vce(cluster MotherId)
estimates store Model_Africa
outreg2 using comp_mort_Group_interaction_hz, excel ci  eform dec(2) ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) ctitle("Africa")label  sideway
outreg2 using comp_mort_Group_interaction_tstat, excel  eform dec(2) alpha(0.001, 0.01, 0.05)  ///
	noparen  tstat addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) ctitle("Africa")label  sideway

	
** testing for breastfeeding in model

merge m:1 CentreId using breastfeeding_duration_recent	

recode  median_duration_any_breastfeedin (7.2/18=1 "under 18 months") (18.01/20=2 "18-20 months") (20.01/22=3 "20-22 months") (22.01/24=4 "22-24 months") (24.01/max=5 "over 24 months"), gen(dur_bf)  //using categories in model this still drops b/c of collinearity with sites

gen sq_bf= median_duration_any_breastfeedin*median_duration_any_breastfeedin

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) scale(31557600000)

stcox 	i.Sex /*ib75.Centre_period*/ median_duration_any_breastfeedin   ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 
			
			
** testing if pregnancy effect still exists with smaller birth intervals

recode 	birth_int_gp_YS (0=0 "no YS") (100=100 "YS non-res") (1 11 21=1 "<24 preg") (31 41 51 61 71=2 ">24 preg") (200 210 220=3 "<24 0-6m") (230 240 250 260 270 =4 ">24 0-6m") ///
	(300 310 320=5 "<24 6-12m") (330 340 350 360=6 ">24 6-12m") (400 410 420=7 "<24 12+m") (430 440 450 460 = 8 ">24 12+m"), gen(int_gp_YS_smpl)
	
stcox 	i.Sex ib75.Centre_period   ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib4.int_gp_YS_smpl ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 	
		
** testing if differences whether female or male sibling, and by sex of index
gen res_O_DTH_TVC_F= res_O_DTH_TVC if SexOsibling==2
gen res_O_DTH_TVC_M= res_O_DTH_TVC if SexOsibling==1
gen res_Y_DTH_TVC_F= res_Y_DTH_TVC if SexYsibling==2
gen res_Y_DTH_TVC_M= res_Y_DTH_TVC if SexYsibling==1
gen MigDeadO_int_M= MigDeadO_int if SexOsibling==1
gen MigDeadO_int_F= MigDeadO_interv  if SexOsibling==2
gen birth_int_gp_YS_M= birth_int_gp_YS if SexYsibling==1
gen birth_int_gp_YS_F= birth_int_gp_YS if SexYsibling==2

/*
*female sib model
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int_F ib0.res_O_DTH_TVC_F ///
        ib230.birth_int_gp_YS_F ib0.res_Y_DTH_TVC_F ///
		, vce(cluster MotherId) iter(20) 
*/

*interactions with sibling sex, intervals and deaths
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_interv#SexOsibling ib0.res_O_DTH_TVC#SexOsibling ///
        ib230.birth_int_gp_YS#SexYsibling ib0.res_Y_DTH_TVC#SexYsibling ///
		if SexYsibling!=9 & SexOsibling!=9, vce(cluster MotherId) iter(20)  //removing unknown sex of siblings

est store u5_sibbysex
esttab u5_sibbysex, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail)		



*interactions with sibling sex and index child sex
stcox 	i.Sex#SexOsibling#SexYsibling ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_interv ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		if SexYsibling!=9 & SexOsibling!=9, vce(cluster MotherId) iter(20)  //removing unknown sex of siblings

est store u5_sex

*model with only male/ female index child
stcox 	ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_interv#SexOsibling ib0.res_O_DTH_TVC#SexOsibling ///
        ib230.birth_int_gp_YS#SexYsibling ib0.res_Y_DTH_TVC#SexYsibling ///
		if SexYsibling!=9 & SexOsibling!=9 & Sex==2, vce(cluster MotherId) iter(20)  //removing unknown sex of siblings
est store u5_sib_fem
stcox 	ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_interv#SexOsibling ib0.res_O_DTH_TVC#SexOsibling ///
        ib230.birth_int_gp_YS#SexYsibling ib0.res_Y_DTH_TVC#SexYsibling ///
		if SexYsibling!=9 & SexOsibling!=9 & Sex==1, vce(cluster MotherId) iter(20)  //removing unknown sex of siblings
est store u5_sib_male


*table of results
esttab u5_sibbysex  u5_sex , eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail)		
esttab u5_sib_male u5_sib_fem, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail)		
		
*sex of sibling and death of sibling combined
*older sib
gen Osib_mort_sex = O_DTH_TVC if O_DTH_TVC==0
replace Osib_mort_sex =	O_DTH_TVC if Sex==1 & SexOsibling==1
replace Osib_mort_sex = 10 if Sex==1 & SexOsibling==2 & O_DTH_TVC>0
replace Osib_mort_sex = 11 if Sex==2 & SexOsibling==1 & O_DTH_TVC>0
replace Osib_mort_sex = 12 if Sex==2 & SexOsibling==2 & O_DTH_TVC>0
label define l_Osib_dth 0 "O sib alive" 	1  "-6m to -3m O sib's death" 	2 "-3m to -15d O sib's death" ///
						3 "+/- 15d O sib's death, m O sib, m index" 		4 "15d to 3m O sib's death" ///
						5 "+3m to +6m O sib's death" 	6 "6m+ O sib's death" ///
						10 "f O sib dead, m index" 11 "m O sib dead, f index" 12 "f O sib dead, f index", modify
label val Osib_mort_sex l_Osib_dth
*younger sibling
gen Ysib_mort_sex = Y_DTH_TVC if Y_DTH_TVC==0
replace Ysib_mort_sex =	Y_DTH_TVC if Sex==1 & SexYsibling==1
replace Ysib_mort_sex = 10 if Sex==1 & SexYsibling==2 & Y_DTH_TVC>0
replace Ysib_mort_sex = 11 if Sex==2 & SexYsibling==1 & Y_DTH_TVC>0
replace Ysib_mort_sex = 12 if Sex==2 & SexYsibling==2 & Y_DTH_TVC>0
label define l_Ysib_dth 0 "Y sib alive" 	1  "-6m to -3m Y sib's death" 	2 "-3m to -15d Y sib's death" ///
						3 "+/- 15d Y sib's death, m Y sib, m index" 		4 "15d to 3m Y sib's death" ///
						5 "+3m to +6m Y sib's death" 	6 "6m+ Y sib's death" ///
						10 "f Y sib dead, m index" 11 "m Y sib dead, f index" 12 "f Y sib dead, f index", modify
label val Ysib_mort_sex l_Ysib_dth	
*full model
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.Osib_mort_sex ///
        ib230.birth_int_gp_YS ib0.Ysib_mort_sex ///
		, vce(cluster MotherId) iter(20) 
est store u5_sib_dthsex		

esttab u5_sib_dthsex , eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail)

*sib sex no interactions
stcox 	i.Sex i.SexOsibling i.SexYsibling ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_interv ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		if SexYsibling!=9 & SexOsibling!=9, vce(cluster MotherId) iter(20)  //removing unknown sex of siblings
est store u5_sibsex

***********************************

***model based on only one index child per mother

*random selection of child
drop maxr numkids random onekid
*bysort MotherId: gen rank=_n
*bysort MotherId: gen numkids=_N
*gen onekid=1 if numkids==1
*gen random= round(runiform() *10) //random number from 0-10
gen random= runiform()
sort MotherId random
bysort MotherId: egen maxr= max(random)
gen onekid=1 if maxr==random 


*model with only one child per mother
stcox 	i.Sex ib75.Centre_period ///
		ib21.y3_mother_age_birth ib0.MigDeadMO_MO_DTH_TVC ib0.migrant_statusMO ///
		ib0.MigDeadTwin_Twin_DTH_TVC ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		if onekid==1 ///
		, vce(cluster MotherId) iter(10)
		
est store u5_select
esttab u5_select, eform ci wide lab mtitle sca(chi2 ll N_sub risk N_fail) 
esttab u5_select, eform p wide lab mtitle sca(chi2 ll N_sub risk N_fail)

*** counting person-years in different variables in full model
table migrant_statusMO [iw=_t-_t0], content(freq) format(%10.0f) missing row 
table Sex [iw=_t-_t0], content(freq) format(%10.0f) missing row 
table y3_mother_age_birth [iw=_t-_t0], content(freq) format(%10.0f) missing row 
table MigDeadMO_MO_DTH_TVC [iw=_t-_t0], content(freq) format(%10.0f) missing row 
table MigDeadTwin_Twin_DTH_TVC [iw=_t-_t0], content(freq) format(%10.0f) missing row 
table DeadObeforeDoB [iw=_t-_t0], content(freq) format(%10.0f) missing row 
table MigDeadO_int  [iw=_t-_t0], content(freq) format(%10.0f) missing row  
table res_O_DTH_TVC  [iw=_t-_t0], content(freq) format(%10.0f) missing row  
table birth_int_gp_YS [iw=_t-_t0], content(freq) format(%10.0f) missing row
table res_Y_DTH_TVC [iw=_t-_t0], content(freq) format(%10.0f) missing row

*** counting person-years in different variables in model of only one-child
table migrant_statusMO [iw=_t-_t0] if onekid==1 , content(freq) format(%10.0f) missing row
table Sex [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row 
table y3_mother_age_birth [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row 
table MigDeadMO_MO_DTH_TVC [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row 
table MigDeadTwin_Twin_DTH_TVC [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row 
table DeadObeforeDoB [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row 
table MigDeadO_int  [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row  
table res_O_DTH_TVC  [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row  
table birth_int_gp_YS [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row
table res_Y_DTH_TVC [iw=_t-_t0] if onekid==1, content(freq) format(%10.0f) missing row







/*

**Groupe d'âge de la mère
capture drop mother_age_birth
gen mother_age_birth = (DoB - DoBMO)/31557600000


capture drop gp_mother_age_birth
gen byte gp_mother_age_birth = cond(mother_age_birth==.,4,cond(mother_age_birth<18,1,cond(mother_age_birth<36,2,3)))
label def gp_age 1"<18 years" 2"18 - 35 y" 3"35 years  +" 4"Missing",modify
label val gp_mother_age_birth gp_age

capture drop y3_mother_age_birth
gen int_mother_age_birth=int(mother_age_birth)
recode int_mother_age_birth (min/17=15 "15-17") (18/20=18 "18–20") (21/23=21 "21–23") ///
		(24/26=24 "24–26") (27/29=27 "27–29") (30/32=30 "30–32") (33/35=33 "33–35") ///
		(36/38=36 "36–38") (39/41=39 "39–41") (42/max=42 "42+") (.=99 "Missing"), gen(y3_mother_age_birth)
drop int_mother_age_birth


capture drop ecart_O 
gen ecart_O = (DoB - DoBOsibling)*12/31557600000
capture drop gp_ecart_O
gen byte gp_ecart_O = cond(ecart_O==.,0, ///
				cond(ecart_O<12,1, ///
				cond(ecart_O<15,2, ///
				cond(ecart_O<18,3, ///
				cond(ecart_O<21,4, ///
				cond(ecart_O<24,5, ///
				cond(ecart_O<27,6, ///
				cond(ecart_O<30,7, ///
				cond(ecart_O<33,0, ///
				cond(ecart_O<36,9, ///
				cond(ecart_O<39,10, ///
				cond(ecart_O<42,11, ///
				cond(ecart_O<45,12, ///
				cond(ecart_O<48,13, ///
				cond(ecart_O<51,14, ///
				cond(ecart_O<54,15, ///
				16))))))))))))))))
label def gp_age_so 0 "NoOS" 1 "<12 months" 2 "12-14 months" 3 "15-17 months" ///
		4 "18-20 months" 5 "21-23 months" 6 "24-26 months" 7 "27-29 months" ///
		8 "30-32 months" 9 "33-35 months" 10 "36-38 months" 11 "39-41 months" ///
		12 "42-44 months" 13 "45-47 months" 14 "48-50 months" 15 "51-53 months" 16"54 months +", modify
label val gp_ecart_O gp_age_so

capture drop gp_ecart_O_new
gen byte gp_ecart_O_new = cond(ecart_O==.,0, ///
				cond(ecart_O<12,1, ///
				cond(ecart_O<18,2, ///
				cond(ecart_O<24,3, ///
				cond(ecart_O<30,4, ///
				cond(ecart_O<36,5, ///
				cond(ecart_O<42,6, ///
				cond(ecart_O<48,7, ///
				8))))))))
label def lgp_ecart_O_new 0"NoOS" 1"<12 months" 2"12-17 months" 3"18-23 months" ///
		4 "24-29 months" 5 "30-35 months" 6 "36-41 months" 7 "42-47 months" 8 "48 months +",modify
label val gp_ecart_O_new lgp_ecart_O_new

*Older sibling don't compeet if he's not resident
*replace gp_ecart_O_new=0 if coresidOS==0

capture drop ecart_Y 
gen ecart_Y = (DoBYsibling - DoB)*12/31557600000
capture drop gp_ecart_Y
gen byte gp_ecart_Y = cond(ecart_Y==.,0, ///
				cond(ecart_Y<12,1, ///
				cond(ecart_Y<15,2, ///
				cond(ecart_Y<18,3, ///
				cond(ecart_Y<21,4, ///
				cond(ecart_Y<24,5, ///
				cond(ecart_Y<27,6, ///
				cond(ecart_Y<30,7, ///
				cond(ecart_Y<33,0, ///
				cond(ecart_Y<36,9, ///
				cond(ecart_Y<39,10, ///
				cond(ecart_Y<42,11, ///
				cond(ecart_Y<45,12, ///
				cond(ecart_Y<48,13, ///
				cond(ecart_Y<51,14, ///
				cond(ecart_Y<54,15, ///
				16))))))))))))))))
label def gp_age_sy 0 "NoYS" 1 "<12 months" 2 "12-14 months" 3 "15-17 months" ///
		4 "18-20 months" 5 "21-23 months" 6 "24-26 months" 7 "27-29 months" ///
		8 "30-32 months" 9 "33-35 months" 10 "36-38 months" 11 "39-41 months" ///
		12 "42-44 months" 13 "45-47 months" 14 "48-50 months" 15 "51-53 months" 16"54 months +", modify
label val gp_ecart_Y gp_age_sy			
				
gen byte gp_ecart_Y_new = cond(ecart_Y==.,0, ///
				cond(ecart_Y<12,1, ///
				cond(ecart_Y<18,2, ///
				cond(ecart_Y<24,3, ///
				cond(ecart_Y<30,4, ///
				cond(ecart_Y<36,5, ///
				cond(ecart_Y<42,6, ///
				cond(ecart_Y<48,7, ///
				8))))))))
label def lgp_ecart_Y_new 0 "NoYS" 1 "<12 months" 2 "12-17 months" 3 "18-23 months" ///
		4 "24-29 months" 5 "30-35 months" 6 "36-41 months" 7 "42-47 months" 8 "48 months +" 
label val gp_ecart_Y_new lgp_ecart_Y_new


* Data errors:
* Gap between Younger sibling and index child DoB <9 months
browse concat_IndividualId DoB YsiblingId DoBYsibling ecart_Y MotherId  if ecart_Y<8 & lastrecord==1
gen temp=100*(ecart_Y<8)
table hdss if lastrecord==1, contents(mean temp) // ET041 ET051 ET061 >1%
drop temp

* Gap between Older sibling and index child DoB <9 months
browse concat_IndividualId DoB OsiblingId DoBOsibling ecart_O MotherId  if ecart_O<8 & lastrecord==1
gen temp=100*(ecart_O<8)
table hdss if lastrecord==1, contents(mean temp) // ET041 ET051 ET061 >1%
drop temp

* Fix these errors
*drop if ecart_Y<8
*drop if ecart_O<8

* Gap between Younger sibling and index child DoB >5 years
browse concat_IndividualId DoB YsiblingId DoBYsibling ecart_Y MotherId  if ecart_Y>60 & ecart_Y!=. & lastrecord==1
* Only 81 and none >61 months
* Gap between Older sibling and index child DoB >20 years
browse concat_IndividualId DoB OsiblingId DoBOsibling ecart_O MotherId  if ecart_O>240 & ecart_O!=. & lastrecord==1
* Only 5
* No impact on sibling covariates

/*
replace migrant_statusMO = 0 if MigDeadMO==1
bysort concat_IndividualId (EventDate): replace migrant_statusMO = migrant_statusMO[1] if migrant_statusMO==.
*/
gen byte gp_ecart_Yres = cond(MigDeadY==2,gp_ecart_Y,0)
gen byte gp_ecart_Ores = cond(MigDeadO==2,gp_ecart_O,0)
gen byte gp_ecart_Ores_new = cond(MigDeadO==2,gp_ecart_O_new,0)
label val gp_ecart_Yres gp_age_sy
label val gp_ecart_Ores gp_age_so
label val gp_ecart_Ores_new lgp_ecart_O_new

sort concat_IndividualId EventDate
gen byte birth_int_Yres_12m = cond(gp_ecart_Y_new==1&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_12m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==1
label val birth_int_Yres_12m lbirth_int_YS

gen byte birth_int_Yres_12_17m = cond(gp_ecart_Y_new==2&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_12_17m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==2
label val birth_int_Yres_12_17m lbirth_int_YS

gen byte birth_int_Yres_18_23m = cond(gp_ecart_Y_new==3&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_18_23m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==3
label val birth_int_Yres_18_23m lbirth_int_YS

gen byte birth_int_Yres_24_29m = cond(gp_ecart_Y_new==4&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_24_29m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==4
label val birth_int_Yres_24_29m lbirth_int_YS

gen byte birth_int_Yres_30_35m = cond(gp_ecart_Y_new==5&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_30_35m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==5
label val birth_int_Yres_30_35m lbirth_int_YS

gen byte birth_int_Yres_36_41m  = cond(gp_ecart_Y_new==6&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_36_41m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==6
label val birth_int_Yres_36_41m lbirth_int_YS

gen byte birth_int_Yres_42_47m  = cond(gp_ecart_Y_new==7&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_42_47m=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==7
label val birth_int_Yres_42_47m lbirth_int_YS

gen byte birth_int_Yres_48_more  = cond(gp_ecart_Y_new==8&MigDeadY==2,birth_int_YS ,0)
replace birth_int_Yres_48_more=1 if birth_int_YS==1 & gp_ecart_Y_new[_n+1]==8
label val birth_int_Yres_48_more lbirth_int_YS

capture drop gp_birth_int_YS
gen int gp_birth_int_YS= MigDeadY*1000 + birth_int_Yres_12m + ///
	cond(birth_int_Yres_12_17m==0,0,10+ birth_int_Yres_12_17m) + ///
	cond(birth_int_Yres_18_23m==0,0,20+ birth_int_Yres_18_23m) + ///
	cond(birth_int_Yres_24_29m==0,0,30+ birth_int_Yres_24_29m) + ///
	cond(birth_int_Yres_30_35m==0,0,40+ birth_int_Yres_30_35m) + ///
	cond(birth_int_Yres_36_41m==0,0,50+ birth_int_Yres_36_41m) + ///
	cond(birth_int_Yres_42_47m==0,0,60+ birth_int_Yres_42_47m) + ///
	cond(birth_int_Yres_48_more==0,0,70+ birth_int_Yres_48_more)

label define lgp_birth_int_YS ///
0 "NoYS"	///
1 "Int <12m - pregnant" ///	
11 "Int 12-17m - pregnant" ///	
21 "Int 18-23m - pregnant" ///	
31 "Int 24-29m - pregnant" ///	
41 "Int 30-35m - pregnant" ///	
51 "Int 36-41m - pregnant" ///	
61 "Int 42-47m - pregnant" ///
71 "Int >=48m + - pregnant" ///	
1000 "y sibling non-res" ///
2002 "Int <12m - 0-6m" ///	
2003 "Int <12m - 6-12m" ///	
2004 "Int <12m - 12m +" ///	
2012 "Int 12-17m - 0-6m" ///	
2013 "Int 12-17m - 6-12m" ///	
2014 "Int 12-17m - 12m +" ///	
2022 "Int 18-23m - 0-6m" ///	
2023 "Int 18-23m - 6-12m" ///	
2024 "Int 18-23m - 12m +" ///	
2032 "Int 24-29m - 0-6m" ///	
2033 "Int 24-29m - 6-12m" ///	
2034 "Int 24-29m - 12m +" ///	
2042 "Int 30-35m - 0-6m" ///	
2043 "Int 30-35m - 6-12m" ///	
2044 "Int 30-35m - 12m +" ///	
2052 "Int 36-41m - 0-6m" ///	
2053 "Int 36-41m - 6-12m" ///	
2054 "Int 36-41m - 12m +" ///	
2062 "Int 42-47m - 0-6m" ///	
2063 "Int 42-47m - 6-12m" ///	
2064 "Int 42-47m - 12m +" ///	
2072 "Int >=48m + - 0-6m" ///	
2073 "Int >=48m + - 6m +" ///	
2074 "Int >=48m + - 12m +" ///	
3000 "y sibling dead", modify	

label val gp_birth_int_YS lgp_birth_int_YS

recode gp_birth_int_YS (2074=2073)
* Same variable but with different coding order
recode gp_birth_int_YS ///
(0 =0 "NoYS"					) ///
(1 =1 "Int <12m - pregnant" 	) ///	
(11=11 "Int 12-17m - pregnant" 	) ///	
(21=21 "Int 18-23m - pregnant" 	) ///	
(31=31 "Int 24-29m - pregnant" 	) ///	
(41=41 "Int 30-35m - pregnant" 	) ///	
(51=51 "Int 36-41m - pregnant" 	) ///	
(61=61 "Int 42-47m - pregnant" 	) ///
(71=71 "Int >=48m+ - pregnant" ) ///	
(1000=100 "y sibling non-res" 	) ///
(2002=200 "Int <12m - 0-6m" 	) ///	
(2003=300 "Int <12m - 6-12m" 	) ///	
(2004=400 "Int <12m - 12m+" 	) ///	
(2012=210 "Int 12-17m - 0-6m" 	) ///	
(2013=310 "Int 12-17m - 6-12m" 	) ///	
(2014=410 "Int 12-17m - 12m+" 	) ///	
(2022=220 "Int 18-23m - 0-6m" 	) ///	
(2023=320 "Int 18-23m - 6-12m" 	) ///	
(2024=420 "Int 18-23m - 12m+" 	) ///	
(2032=230 "Int 24-29m - 0-6m" 	) ///	
(2033=330 "Int 24-29m - 6-12m" 	) ///	
(2034=430 "Int 24-29m - 12m+" 	) ///	
(2042=240 "Int 30-35m - 0-6m" 	) ///	
(2043=340 "Int 30-35m - 6-12m" 	) ///	
(2044=440 "Int 30-35m - 12m+" 	) ///	
(2052=250 "Int 36-41m - 0-6m" 	) ///	
(2053=350 "Int 36-41m - 6-12m" 	) ///	
(2054=450 "Int 36-41m - 12m+"	) ///	
(2062=260 "Int 42-47m - 0-6m" 	) ///	
(2063=360 "Int 42-47m - 6-12m" 	) ///	
(2064=460 "Int 42-47m - 12m+" 	) ///	
(2072=270 "Int >=48m+ - 0-6m" 	) ///	
(2073=270 "Int >=48m+ - 6m+" 	) ///	
(3000=500 "y sibling dead"		), gen(birth_int_gp_YS)	
 
capture drop pregnant_YS
gen byte pregnant_YS = (birth_int_YS==1)
lab define pregnant 1 "3-9m pregnant" 0 "No this period"
label val pregnant_YS pregnant



cap drop censor_death
gen byte censor_death=(EventCode==7) 


sort hdss IndividualId EventDate EventCode
sort concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double ///
datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop twin
gen byte twin = (TwinId!="")
label define twin 1 "Yes" 0 "No", modify
label val twin twin

* Setting mortality analysis <5-year-old 
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)
/*
    123,163  subjects
      9,571  failures in single-failure-per-subject data
  532,999.03 total analysis time at risk and under observation
*/
compress
*keep if _st==1
*Suprimer les cas où la variable Sex est une valeur manquante.
*drop if Sex==9 /*Tous ces enfants viennent de Niakhar*/

*Vérifications et corrections
/*
foreach var of varlist MigDeadMO Sex y3_mother_age_birth migrant_statusMO MO_DTH_TVC MigDeadO gp_ecart_Ores ///
                       MigDeadY  birth_int_Yres_12m birth_int_Yres_12_17m ///
                       birth_int_Yres_18_23m birth_int_Yres_24_29m birth_int_Yres_30_35m birth_int_Yres_36_41m ///
                       birth_int_Yres_42_47m birth_int_Yres_48_more twin period {
					   
					   tab `var' [iw=_t-_t0], miss
					   }
*/
foreach var of varlist birth_int_Yres_12m birth_int_Yres_12_17m  ///
                       birth_int_Yres_18_23m birth_int_Yres_24_29m birth_int_Yres_30_35m birth_int_Yres_36_41m ///
                       birth_int_Yres_42_47m birth_int_Yres_48_more  {
					   
					   replace `var' = 0 if `var'==.
					   }


capture drop MigDeadMO_MO_DTH_TVC
gen MigDeadMO_MO_DTH_TVC=	cond(MigDeadMO==2 & MO_DTH_TVC==0,0, cond(MigDeadMO==1 & MO_DTH_TVC==0,1, ///
							cond(MO_DTH_TVC==1,2, cond(MO_DTH_TVC==2,3, cond(MO_DTH_TVC==3,4, ///
							cond(MO_DTH_TVC==4,5, cond(MO_DTH_TVC==5,6, 7)))))))
label define lMigDeadMO_MO_DTH_TVC 0 "mother resident" 	1 "mother non resident" ///
						2 "-6m to -3m mother's death" 	3 "-3m to -15d mother's death" ///
						4 "+/- 15d mother's death" 		5 "15d to 3m mother's death" ///
						6 "+3m to +6m mother's death" 	7 "6m+ mother's death", modify
label val MigDeadMO_MO_DTH_TVC lMigDeadMO_MO_DTH_TVC


recode birth_int_Yres_48_more (4=3)
label define lbirth_int_Yres_48_more 1 "pregnant_YS" 2 "0-6m" 3 "6m +", modify
label val birth_int_Yres_48_more lbirth_int_Yres_48_more

encode hdss,gen(hdss_1)
capture drop hdss_period
egen hdss_period=group(hdss_1 period), label

drop  if 1001 1011 1021 1031 1041 1051 1061 2001 2021 2031 2051 2061 2071 2122 3031


        
		
		
*Full model for under 5

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)
		

* Full model for under5
* Basic model without macro, but with Centre*period "fixed effect"
stcox 	i.gender ib20.hdss_period ///
		ib21.y3_mother_age_birth ib2.MigDeadMO ib2.MigDeadFA ///
		ib0.coresidMGM##ib0.coresidMGF ///
		ib0.coresidPGF##ib0.coresidPGM  ///
	    ib0.coresid_maunt ib0.coresid_muncle ///
	    ib0.coresid_paunt ib0.coresid_puncle ///
	    ib0.coresidOS ib0.coresidYS 

		
		///
		 ///
		DeadObeforeDoB ib24.MigDeadO_int ib0.res_O_DTH_TVC ///
        ib230.birth_int_gp_YS ib0.res_Y_DTH_TVC ///
		, vce(cluster MotherId) iter(10) 
		
		
		
		
/*		
*M1
stcox ib1.coresidMO ib1.coresidFA i.gender i.y3_mother_age_birth ,vce(cluster MotherId) iter(10) 
stcox ib1.coresidMO ib1.coresidFA i.gender i.y3_mother_age_birth i.gp_ecart_Yres_new  i.gp_ecart_Ores_new i.twin
*M2
stcox ib1.coresidMO ib1.coresidFA ///
       ib0.coresidMGM##ib0.coresidMGF ///
	   ib0.coresidPGF##ib0.coresidPGM  ///
	   ib0.coresid_maunt ib0.coresid_muncle ///
	   ib0.coresid_paunt ib0.coresid_puncle ///
	   ib0.coresidOS ib0.coresidYS ///
	  i.gender ib21.y3_mother_age_birth  i.twin ib4.hdss_1, vce(cluster MotherId) iter(10) 
*/

XX
stcox ib1.coresidMO ib1.coresidFA ///
       ib0.coresidMGM##ib0.coresidMGF ///
	   ib0.coresidPGF##ib0.coresidPGM  ///
	   ib0.coresid_maunt ib0.coresid_muncle ///
	   ib0.coresid_paunt ib0.coresid_puncle ///
	   ib0.coresidOS ib0.coresidYS ///
	  i.gender ib21.y3_mother_age_birth  i.twin ib4.hdss_1, vce(cluster MotherId) iter(10) 


outreg2 using Analyses_under5_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 


	
* <1 without/with younger sibling and no twin
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+31557600000+106000000) scale(31557600000)

stcox ib1.coresidMO ib1.coresidFA ///
      ib1.coresidPGM ib1.coresidMGM ///
	   ib1.coresidPGF ib1.coresidMGF ///
	   ib1.coresid_maunt ib1.coresid_muncle ///
	   ib1.coresid_paunt ib1.coresid_puncle ///
	   ib1.coresidOS  ///
	  i.gender i.y3_mother_age_birth  i.twin, vce(cluster MotherId) iter(10) 

	
	outreg2 using Analyses_under1_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 


	
*To  for 1-4 without/with younger sibling and no twin
stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB+31557600000+106000000) ///
		exit(time DoB+(5*31557600000)+212000000) scale(31557600000)
	
stcox ib1.coresidMO ib1.coresidFA ///
      ib1.coresidPGM ib1.coresidMGM ///
	   ib1.coresidPGF ib1.coresidMGF ///
	   ib1.coresid_maunt ib1.coresid_muncle ///
	   ib1.coresid_paunt ib1.coresid_puncle ///
	   ib1.coresidOS ib1.coresidYS ///
	  i.gender i.y3_mother_age_birth  i.twin, vce(cluster MotherId) iter(10) 
	
	outreg2 using nalyses_1-4_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
	


stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) scale(31557600000)

stcox ib1.coresidMO ib1.coresidFA ///
      ib1.coresidPGM ib1.coresidMGM ///
	  ib1.coresidPGF ib1.coresidMGF ///
	  ib1.coresid_maunt ib1.coresid_muncle ///
	  ib1.coresid_paunt ib1.coresid_puncle ///
	  i.gender i.y3_mother_age_birth ,vce(cluster MotherId) iter(10) 
	
	outreg2 using Analyses_under5_noY, replace word stats(coef) ///
	bdec(2) nor2 eform ///
	addstat(Wald Chi-square, e(chi2), Log Lik, e(ll), Subjects, e(N_sub), Time at risk, ///
	e(risk), Failures, e(N_fail)) 
	

*Descriptive statistics





sts test gender, logrank

bootstrap, reps(10): stcox ib0.coresidMO i.gender ,vce(cluster MotherId) iter(10) 
*/