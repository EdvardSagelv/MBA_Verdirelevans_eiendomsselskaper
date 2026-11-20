

use "$prosjekt/kjor_m_beta_nav_risk_analyser.dta", clear




/**********************************************************************
 STEG 1: IMPORT OG KLARGJØRING AV UKENTLIGE KURSDATA

 Importerer ukentlige aksjekurser for selskapene og relevante
 markedsindekser. Datasettet lagres i Stata-format for videre
 bearbeiding.

 Indeksobservasjonene identifiseres separat slik at indekskursene
 kan kobles til hvert enkelt selskap basert på handelsdato.
**********************************************************************/

import excel "$prosjekt\uke_samlet.xlsx", sheet("uke_samlet") firstrow clear

save "$prosjekt/kursdata_uke.dta", replace


/*-----om du vil se data-----*/
browse

/*----lag alle til små bokstaver---------*/
rename *, lower

/**********************************************************************
 STEG 2: UTSKILLING OG KOBLING AV MARKEDSINDEKSER

 De tre markedsindeksene (OSEBX, OSEBX Real Estate og OBX) skilles
 ut fra det opprinnelige datasettet.

 Indeksseriene omformes til separate datasett med én observasjon
 per dato. Disse kobles deretter tilbake til selskapsdataene ved
 hjelp av handelsdato.

 Formålet er å sikre at hvert selskap får tilhørende markedsindeks
 for samme handelsuke. Indeksobservasjonene fjernes etter koblingen,
 slik at datasettet kun inneholder selskapsobservasjoner.
**********************************************************************/

preserve
keep if orgnr == 1
keep orgnr selskap date price 
rename price osebx_price
rename selskap osebx
rename orgnr indeks

save mkt, replace
restore

merge m:1 date using mkt

drop _merge


preserve
keep if orgnr == 2
keep orgnr selskap date price 
rename price osebx_re_price
rename selskap osebx_re
rename orgnr indeks_2

save mkt, replace
restore

merge m:1 date using mkt

drop _merge



preserve
keep if orgnr == 3
keep orgnr selskap date price 
rename price obx_price
rename selskap obx
rename orgnr indeks_obx

save mkt, replace
restore

merge m:1 date using mkt


drop if orgnr==1
drop if orgnr==2
drop if orgnr==3
drop _merge


save "$prosjekt/kursdata_uke_m_indeks.dta", replace



/**********************************************************************
 STEG 3: BEREGNING AV ÅRLIG BETA MOT OSEBX

 Ukentlige kursdata benyttes til å beregne logaritmisk avkastning
 for hvert selskap og den tilhørende markedsindeksen.

 Det estimeres separate lineære regresjoner for hvert selskap og
 kalenderår, der selskapets ukentlige logavkastning er avhengig
 variabel og markedsindeksens logavkastning er uavhengig variabel.

 Regresjonskoeffisienten til markedsavkastningen representerer
 selskapets estimerte beta. Antall observasjoner i hver regresjon
 registreres også for kontrollformål.

 Beta beregnes på grunnlag av foregående kalenderårs kursdata
 og forskyves ett år fremover. Dette gjør at beta fra år t
 knyttes til regnskapsåret t+1.
**********************************************************************/

use "$prosjekt/kursdata_uke_m_indeks.dta", clear

* Fjern observasjoner uten indeks (hvis relevant)
drop if missing(indeks)


gen wdate = wofd(date)      // ukedato (Stata intern week date)
format wdate %tw

gen year = year(date)       // år som numerisk variabel


bysort orgnr wdate (date): keep if _n == _N


xtset orgnr wdate           // bruker ukedato som tidsvariabel

sort orgnr date
by orgnr: gen ret = ln(price / price[_n-1])
by orgnr: gen mkt_ret = ln(osebx_price / osebx_price[_n-1])


gen beta = .
gen n_obs = .

levelsof orgnr, local(firms)
foreach f of local firms {
    levelsof year if orgnr==`f', local(years)
    foreach y of local years {
        reg ret mkt_ret if orgnr==`f' & year==`y'
        replace beta = _b[mkt_ret] if orgnr==`f' & year==`y'
        replace n_obs = e(N) if orgnr==`f' & year==`y'
    }
}


keep orgnr year beta n_obs
duplicates drop orgnr year, force

gen ar=year+1

save "$prosjekt/beta_mot_osebx.dta", replace


/**********************************************************************
 STEG 4: BEREGNING AV BETA MOT OSEBX REAL ESTATE

 Beregner årlig beta med samme fremgangsmåte som i foregående steg,
 men benytter OSEBX Real Estate som referanseindeks.

 Beta beregnes separat for hvert selskap og kalenderår og
 forskyves ett år fremover.
**********************************************************************/

use "$prosjekt/kursdata_uke_m_indeks.dta", clear

* Fjern observasjoner uten indeks (hvis relevant)
drop if missing(indeks_2)


gen wdate = wofd(date)      // ukedato (Stata intern week date)
format wdate %tw

gen year = year(date)       // år som numerisk variabel


bysort orgnr wdate (date): keep if _n == _N


xtset orgnr wdate           // bruker ukedato som tidsvariabel

sort orgnr date
by orgnr: gen ret = ln(price / price[_n-1])
by orgnr: gen mkt_ret = ln(osebx_re_price / osebx_re_price[_n-1])


gen beta = .
gen n_obs = .

levelsof orgnr, local(firms)
foreach f of local firms {
    levelsof year if orgnr==`f', local(years)
    foreach y of local years {
        reg ret mkt_ret if orgnr==`f' & year==`y'
        replace beta = _b[mkt_ret] if orgnr==`f' & year==`y'
        replace n_obs = e(N) if orgnr==`f' & year==`y'
    }
}


keep orgnr year beta n_obs
duplicates drop orgnr year, force

gen ar=year+1

save "$prosjekt/beta_mot_osebx_re_gr.dta", replace


/**********************************************************************
 STEG 5: BEREGNING AV BETA MOT OBX

 Beregner årlig beta med OBX-indeksen som referanseindeks.

 Beta beregnes separat for hvert selskap og kalenderår og
 forskyves ett år fremover.
**********************************************************************/

use "$prosjekt/kursdata_uke_m_indeks.dta", clear

* Fjern observasjoner uten indeks (hvis relevant)
drop if missing(indeks_obx)


gen wdate = wofd(date)      // ukedato (Stata intern week date)
format wdate %tw

gen year = year(date)       // år som numerisk variabel


bysort orgnr wdate (date): keep if _n == _N


xtset orgnr wdate           // bruker ukedato som tidsvariabel

sort orgnr date
by orgnr: gen ret = ln(price / price[_n-1])
by orgnr: gen mkt_ret = ln(obx_price / obx_price[_n-1])


gen beta = .
gen n_obs = .

levelsof orgnr, local(firms)
foreach f of local firms {
    levelsof year if orgnr==`f', local(years)
    foreach y of local years {
        reg ret mkt_ret if orgnr==`f' & year==`y'
        replace beta = _b[mkt_ret] if orgnr==`f' & year==`y'
        replace n_obs = e(N) if orgnr==`f' & year==`y'
    }
}


keep orgnr year beta n_obs
duplicates drop orgnr year, force

gen ar=year+1

save "$prosjekt/beta_mot_obx.dta", replace


/**********************************************************************
 STEG 6: KLARGJØRING OG SAMMENSTILLING AV BETAVARIABLER

 Betaestimatene gis separate variabelnavn for å skille mellom
 referanseindeksene.

 Antall observasjoner fjernes fra de endelige betadatasettene
 etter at beregningene er kontrollert.

 De tre datasettene kobles sammen på selskapsidentifikator og år.

 Resultatet er et samlet datasett med alternative betamål som
 kan benyttes i hovedanalysene og sensitivitetsanalysene.
**********************************************************************/

use "$prosjekt/beta_mot_obx.dta", clear

rename beta beta_obx
drop n_obs

save "$prosjekt/beta_mot_obx.dta", replace



/* osebx*/

use "$prosjekt/beta_mot_osebx.dta", clear

rename beta beta_osebx
drop n_obs

save "$prosjekt/beta_mot_osebx.dta", replace

/* re */


use "$prosjekt/beta_mot_osebx_re_gr.dta", clear

rename beta beta_osebx_re
drop n_obs

save "$prosjekt/beta_mot_osebx_re_gr.dta", replace


/* merge osebx og re*/

use "$prosjekt/beta_mot_obx.dta", clear

merge 1:1 orgnr year using "$prosjekt/beta_mot_osebx.dta"

drop _merge

merge 1:1 orgnr year using "$prosjekt/beta_mot_osebx_re_gr.dta"

drop _merge

save "$prosjekt/beta_alle.dta", replace


/*---------slutt---------------*/
