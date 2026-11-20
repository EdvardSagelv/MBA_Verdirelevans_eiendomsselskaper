


/**********************************************************************
 STEG 1: KOBLING AV REGNSKAPS- OG KURSDATA

 Regnskapsdata kobles sammen med kursdata basert på
 organisasjonsnummer og år.

 Markedsverdien fra år t kobles til regnskapsinformasjonen
 fra år t-1. Dette gir en tidsmessig struktur der regnskapstallene
 representerer foregående regnskapsår i forhold til
 markedsverdien.

 Koblingsresultatet kontrolleres for å identifisere observasjoner
 som finnes i begge datasett.

 Kun observasjoner med treff i begge datasettene beholdes.
**********************************************************************/


*--- Step 3: Merge the cleaned datasets ---
use "$prosjekt/kjor_2.dta", clear
// use "C:\Users\esa039\OneDrive - UiT Office 365\Studier\MBA 2024-26\Masteroppgave\Data\kursdata.dta", clear

* markedsverdi2020=regnskap2019+beta2018

merge 1:1 orgnr ar using "$prosjekt/kursdata.dta"


* Inspect merge results
tab _merge

* Keep only matched observations (optional)
keep if _merge == 3
 drop _merge
 
/**********************************************************************
 STEG 2: BEREGNING AV MARKEDSBASERTE VERDSETTELSESMÅL

 Beregner forholdstall mellom markedsverdi og regnskapsmessige
 størrelser.

 Markedsverdi omregnes til millioner kroner (MNOK).

 Bokført egenkapital benyttes som et regnskapsbasert NAV-mål,
 og P/NAV beregnes som forholdet mellom markedsverdi og bokført
 egenkapital.

 P/NAV over 1 indikerer at markedet verdsetter selskapet høyere
 enn bokført egenkapital, mens P/NAV under 1 indikerer en rabatt.
 
 lengre ned kobles dette også til NTA. Dette er et eget excel-ark, hvor NTA er hentet fra årsrapporter.

 Det beregnes også et mål på markedsverdi relativt til gjeld.
**********************************************************************/

gen mkt_coverage = markedsverdi / Sum_gjeld

gen nav = Sum_egenkapital
gen market_cap_mnok= markedsverdi/1000000
gen p_nav = market_cap_mnok / nav

sum market_cap_mnok, detail

// sum market_cap_mnok
// hist 8

/**********************************************************************
 STEG 3: KOBLING AV BETAESTIMATER

 De beregnede betaestimatene kobles til regnskaps- og
 markedsdatasettet basert på organisasjonsnummer og år.

 Ettersom betaestimatene er forskjøvet ett år fremover,
 representerer de foregående kalenderårs markedsrisiko.

 Dette innebærer at beta for år t er beregnet på grunnlag av
 ukentlige kursobservasjoner fra år t-1.

 Datasettet lagres med tilhørende betavariabler for de ulike
 referanseindeksene.
**********************************************************************/

// regnskap 2010
// beta 2009


merge 1:1 orgnr ar using "$prosjekt/beta_alle.dta"

drop _merge

rename year ar_beta


save "$prosjekt/kjor_m_beta.dta", replace


			

/**********************************************************************
 STEG 4: IMPORT OG KOBLING AV EPRA NAV/NTA

 Importerer det bearbeidede datasettet med EPRA-baserte
 verdsettelsesmål.

 EPRA NAV/NTA kobles til regnskaps- og markedsdatasettet
 basert på organisasjonsnummer og år.

 Observasjoner uten identifisert selskap fjernes, og det
 sammenstilte datasettet lagres for videre analyse.
**********************************************************************/
			

import excel "$prosjekt/epra_nav_klar.xlsx", sheet("Sheet1") firstrow clear

save "$prosjekt/epra_nav_klar.dta", replace

*------------merge epra nav-----------------------*
  
  use "$prosjekt/kjor_m_beta.dta", clear

  merge 1:1 orgnr ar using "$prosjekt/epra_nav_klar.dta"
  
  drop _merge
  
  drop if missing(selskap)
  
  save "$prosjekt/kjor_m_beta_nav.dta", replace

  
  /*----------slutt-------------*/
