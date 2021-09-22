*use base_pyear.dta,clear

use pyear_bis.dta,clear
destring ouagalotie,replace
destring farafenni,replace
destring niakhar,replace

**Supprimer les dernières années
replace farafenni=. if year==2018
replace ouagalotie=. if year==2017
replace ouaganonlotie=. if year==2017
replace niakhar=. if year==2015
*ouagalotie ouaganonlotie farafenni niakhar

capture drop upper
gen upper = 1
label var upper "année de référence (60%)"

twoway (line ouagalotie year, sort lpattern(dot) lcolor(red)) || ///
       (line ouaganonlotie year, sort lcolor(orange) lpattern(dash_dot)) || ///
	   (line farafenni year, sort lpattern(longdash_dot) lcolor(blue)) || ///
       (line niakhar year, sort lpattern(shortdash_dot) lcolor(green) legend(rows(1) position (12)) ///
	     ylab( 0"0" 0.5"0.5" 1"1" 1.5"1.5"  2"2" ,labsize(vsmall)) ///
         xlabel(2000(1)2017 ,labsize(vsmall)) ///
		 xtitle("Années" , size(small)))  || ///
     (line upper year , sort lpattern(solid) lcolor(black)) 

graph save pyear,replace
graph export "pyear.png", replace width(2000)
graph export "pyear.tif", replace width(2000)
graph export "pyear.pdf", replace 

/*	 
		 || ///
scatteri `max_BF021' 2017 "Ouaga/Loti" `max_BF021_nl' 2017 "Ouaga/Non loti" ///
`max_GM011' 2017 "Farafenni" `max_SN011' 2017 "Niakhar", mlabsize(vsmall)  msymbol(i)

  
  (line Complement_complete_SN011 _t, sort lcolor(green)lpattern(dot) xscale(r(0 28)) legend(off) ///  
  ylab( 0"0%" .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%",labsize(vsmall)) ///
xlabel(0(3)36 ,labsize(vsmall)) ///
ytitle("Proportion d'enfants vaccinés" , size(small)) ///
 ///
title("Vaccination compète", size(small)) ///
note("La partie grise représente la période recommendée par l'OMS" "pour recevoir le vaccin contre la fièvre jaune  (9 mois - 12 mois)", ///
span size(vsmall))  ///
legend(off)) || ///
scatteri `max_BF021' 36 "Ouaga/Loti" `max_BF021_nl' 36 "Ouaga/Non loti" ///
`max_GM011' 36 "Farafenni" `max_SN011' 36 "Niakhar", mlabsize(vsmall)  msymbol(i)