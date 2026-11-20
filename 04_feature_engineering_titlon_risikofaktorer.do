


/**********************************************************************
 IMPORT OG KLARGJØRING AV TITLON-DATA

 Importerer daglige kursdata og tilhørende risikofaktorer
 fra TITLON-databasen.

 Variabelnavn standardiseres, og handelsdatoene klargjøres.

 Selskapenes sektortilhørighet kontrolleres. Feilaktige eller
 dupliserte sektorregistreringer fjernes for KMCP og SBO.

 Ticker for Pioneer Property Group standardiseres slik at
 preferanseaksjekursene kobles til selskapets øvrige data.

 Datasettet klargjøres for kobling mellom ticker,
 selskapsnavn og organisasjonsnummer.
**********************************************************************/


********************************************************************************
* FAMA-FRENCH FAKTORBELASTNINGER – TITLON
* MBA masteroppgave – norske børsnoterte eiendomsselskaper
*
* FORMÅL:
* 1. Importere og klargjøre daglige TITLON-data
* 2. Koble ticker til selskapsnavn og organisasjonsnummer
* 3. Beregne ukentlig aksjeavkastning
* 4. Aggregere daglige faktoravkastninger til ukentlige avkastninger
* 5. Beregne ukentlig markedsmeravkastning og risikofri rente
* 6. Estimere Fama-French trefaktormodell
* 7. Estimere utvidet femfaktormodell
* 8. Beregne rullerende faktorbelastninger per selskap og år
* 9. Eksportere ukesdata og årlige faktorbelastninger
*
* DATA:
* Daglige TITLON-data
*
* AVKASTNINGSDEFINISJON:
* Aksjer: Ordinær avkastning
* SMB, HML, MOM, LIQ: Ordinær daglig faktoravkastning
* OBX: Daglig logavkastning, konverteres til ordinær avkastning
* Risikofri rente: Daglig logaritmisk rente, konverteres til ordinær rente
*
* AGGREGERING:
* Daglige avkastninger geometrisk kjedet til ukentlige avkastninger
*
* ESTIMERING:
* Rullerende vindu på 104 uker
* Minimum 15 gyldige ukeobservasjoner
* Estimeringsvinduet avsluttes før analyseåret begynner
*
********************************************************************************


********************************************************************************
* STEG 1: OPPSETT
********************************************************************************


* Estimeringsparametere
local window = 104
local minobs = 15


********************************************************************************
* STEG 2: IMPORT AV DAGLIGE TITLON-DATA
********************************************************************************

import excel "$prosjekt\selskaper_samlet_dagskurser.xlsx", ///
    sheet("sheet1") firstrow clear

rename *, lower

* Formater handelsdato
format date %tdCCYY-NN-DD

* Kontroller datastrukturen
describe
summarize date

* Vis de første observasjonene
list date symbol in 1/15


********************************************************************************
* STEG 3: KONTROLL AV SEKTORTILHØRIGHET
********************************************************************************

* Kontroller selskapsklassifisering
bysort symbol: tab sector

* Fjern feilaktige sektorklassifiseringer
drop if symbol=="KMCP" & sector=="Industrials"
drop if symbol=="SBO" & sector=="Consumer Discretionary"

* Fjern eventuell eksisterende organisasjonsnummer
capture drop orgnr

* Standardiser PPG-ticker
replace symbol = "PPG" if symbol == "PPG PREF"


********************************************************************************
* STEG 4: KOBLING AV TICKER, SELSKAP OG ORGANISASJONSNUMMER
********************************************************************************



gen selskap = "baltic_sea_properties" if symbol == "BALT"
replace selskap = "black_sea_property_as" if symbol == "BSP"
replace selskap = "entra_asa" if symbol == "ENTRA"
replace selskap = "kmc_properties_asa" if symbol == "KMCP"
replace selskap = "olav_thon_eiendomsselskap_asa" if symbol == "OLT"
replace selskap = "pioneer_property_group_asa" if symbol == "PPG"
replace selskap = "selvaag_bolig_asa" if symbol == "SBO"

* Bruk long for å bevare alle sifrene i organisasjonsnummeret
gen long orgnr = .

replace orgnr = 988691771 if symbol == "BALT"
replace orgnr = 914892902 if symbol == "BSP"
replace orgnr = 999296432 if symbol == "ENTRA"
replace orgnr = 990727007 if symbol == "KMCP"
replace orgnr = 914594685 if symbol == "OLT"
replace orgnr = 914839327 if symbol == "PPG"
replace orgnr = 992587776 if symbol == "SBO"

* Generer år fra handelsdato
gen ar = year(date)

* Kontroller koblingen
assert !missing(orgnr)
assert !missing(selskap)

bysort orgnr: assert selskap == selskap[1]
bysort orgnr: assert symbol == symbol[1]

* Sorter etter selskap og dato
sort orgnr date

* Kontroller selskapsutvalget
tabulate symbol
tabulate selskap


********************************************************************************
* STEG 5: KONTROLL AV DAGLIGE OBSERVASJONER
********************************************************************************

* Kontroller at hver dato kun forekommer én gang per selskap
duplicates report orgnr date

* Krev én observasjon per selskap og dato
isid orgnr date

* Kontroller aksjekurser og faktorvariabler
summarize adjustedprice smb hml mom liq ///
    lndeltaobx bills_3month_lnrate, detail

* Kontroller at aksjekursene er positive
assert adjustedprice > 0 if !missing(adjustedprice)

* Kontroller faktoravkastningene
foreach v in smb hml mom liq {

    count if `v' <= -1 & !missing(`v')

    summarize `v', detail
}

* Undersøk om faktorene varierer mellom selskapene på samme dato
foreach v in smb hml mom liq {

    bysort date: egen sd_`v' = sd(`v')

    summarize sd_`v'

    drop sd_`v'
}


********************************************************************************
* STEG 6: OPPRETT UKENTLIG DATO
********************************************************************************

gen week = wofd(date)

format week %tw

* Kontroller ukedato
sort orgnr date

list symbol date week in 1/20


********************************************************************************
* STEG 7: AGGREGER DAGLIGE FAKTORAVKASTNINGER TIL UKESDATA
********************************************************************************

* Faktorene er ordinære daglige avkastninger i desimalform.
*
* Ukentlig avkastning beregnes ved geometrisk kjeding:
*
* R_uke = (1+R_1)*(1+R_2)*...*(1+R_n)-1
*
* Dette gjøres ved å summere ln(1+R_d) og deretter
* konvertere tilbake med exp()-1.
*
* Faktorene beholdes per organisasjonsnummer og uke.
* Dermed bevares eventuelle forskjeller mellom selskapene.

tempfile faktoruke aksjeuke



preserve

    * Geometrisk kjeding av ordinære daglige faktoravkastninger
    gen double ln_smb = ln(1+smb) if smb > -1 & !missing(smb)
    gen double ln_hml = ln(1+hml) if hml > -1 & !missing(hml)
    gen double ln_mom = ln(1+mom) if mom > -1 & !missing(mom)
    gen double ln_liq = ln(1+liq) if liq > -1 & !missing(liq)

    * OBX og risikofri rente er daglige logaritmiske bidrag
    gen double ln_obx = lndeltaobx
    gen double ln_rf = bills_3month_lnrate

    * Aggreger til ukentlige verdier
    collapse ///
        (sum) sum_smb=ln_smb ///
              sum_hml=ln_hml ///
              sum_mom=ln_mom ///
              sum_liq=ln_liq ///
              sum_obx=ln_obx ///
              sum_rf=ln_rf ///
        (count) n_days=date ///
                n_smb=ln_smb ///
                n_hml=ln_hml ///
                n_mom=ln_mom ///
                n_liq=ln_liq ///
                n_obx=ln_obx ///
                n_rf=ln_rf, ///
        by(orgnr week)

    * Konverter tilbake til ordinære ukentlige avkastninger
    gen double smb_w = exp(sum_smb)-1 if n_smb==n_days & n_days>0
    gen double hml_w = exp(sum_hml)-1 if n_hml==n_days & n_days>0
    gen double mom_w = exp(sum_mom)-1 if n_mom==n_days & n_days>0
    gen double liq_w = exp(sum_liq)-1 if n_liq==n_days & n_days>0

    * Ukentlig ordinær markedsavkastning
    gen double obx_w = exp(sum_obx)-1 if n_obx==n_days & n_days>0

    * Ukentlig ordinær risikofri rente
    gen double rf_w = exp(sum_rf)-1 if n_rf==n_days & n_days>0

    * Kontroller antall observasjoner
    summarize n_days n_smb n_hml n_mom n_liq n_obx n_rf

    * Kontroller ukentlige avkastninger
    summarize smb_w hml_w mom_w liq_w obx_w rf_w, detail

    * Behold relevante variabler
    keep orgnr week smb_w hml_w mom_w liq_w obx_w rf_w

    isid orgnr week

    save `faktoruke'

restore

********************************************************************************
* STEG 8: BEREGN UKENTLIG AKSJEAVKASTNING
********************************************************************************

preserve

    * Sorter etter selskap og dato
    sort orgnr date

    * Hent siste tilgjengelige justerte aksjekurs per uke
    collapse ///
        (lastnm) adjustedprice ///
        (max) week_end=date, ///
        by(orgnr symbol selskap week)

    * Formater dato
    format week_end %tdCCYY-NN-DD
    format week %tw

    * Kontroller én observasjon per selskap og uke
    isid orgnr week

    * Sorter etter selskap og uke
    sort orgnr week

    * Beregn ordinær ukentlig aksjeavkastning
    by orgnr: gen double ret = ///
        adjustedprice/adjustedprice[_n-1]-1 if _n>1

    * Kontroller avstand mellom observasjonene
    by orgnr: gen week_gap = week-week[_n-1] if _n>1

    * Ikke beregn avkastning over manglende kalenderuker
    replace ret = . if week_gap != 1 & !missing(week_gap)

    * Kontroller ukentlig aksjeavkastning
    summarize ret, detail

    save `aksjeuke'

restore


********************************************************************************
* STEG 9: KOBLE SAMMEN UKENTLIGE AKSJE- OG FAKTORAVKASTNINGER
********************************************************************************

use `aksjeuke', clear

* Koble ukentlige faktorer til selskapene
merge 1:1 orgnr week using `faktoruke'

* Kontroller koblingen
tabulate _merge

* Behold uker med både aksje- og faktorobservasjoner
keep if _merge==3

drop _merge

* Beregn selskapets meravkastning
gen double excess_ret = ret-rf_w

* Beregn markedets meravkastning
gen double mkt_excess = obx_w-rf_w

* Generer år fra siste handelsdato i uken
gen ar = year(week_end)

* Kontroller resultatene
summarize ret excess_ret obx_w mkt_excess ///
    smb_w hml_w mom_w liq_w rf_w, detail

* Kontroller observasjoner per selskap og år
sort orgnr week

tabulate symbol
tabulate ar

* Kontroller at ukesdataene er unike
isid orgnr week

* Lagre ukesdatasettet
save "$prosjekt\fama_french_ukedata.dta", replace


	
	
********************************************************************************
* STEG 10: KLARGJØRING FOR FAKTORREGRESJONER
********************************************************************************

* Faktorbelastningene estimeres separat for hvert selskap og kalenderår.
*
* Eksempel:
* Beta for 2023 estimeres med selskapets ukentlige avkastning
* og tilhørende faktoravkastninger fra kalenderåret 2023.
*
* Aksjeavkastning, markedsavkastning og risikofaktorer
* observeres dermed i samme periode.
*
* Identifiser selskaper
levelsof orgnr, local(orgnr_liste)

* Identifiser analyseår
levelsof ar, local(aar_liste)

* Minimum antall gyldige ukeobservasjoner
local minobs = 15


********************************************************************************
* STEG 11: OPPRETT FIL FOR FAKTORBELASTNINGER
********************************************************************************

* Resultatene lagres direkte i en Stata-fil.
* Dette gjør det mulig å hente resultatene uten tempfile.

local beta_fil "$prosjekt\fama_french_beta_aar.dta"

postfile beta_handle ///
    long orgnr ///
    str8 symbol ///
    str40 selskap ///
    int ar ///
    double alpha_3 ///
           beta_mkt_3 ///
           beta_smb_3 ///
           beta_hml_3 ///
           r2_3 ///
    int n_3 ///
    double alpha_5 ///
           beta_mkt_5 ///
           beta_smb_5 ///
           beta_hml_5 ///
           beta_mom_5 ///
           beta_liq_5 ///
           r2_5 ///
    int n_5 ///
    using "`beta_fil'", replace


********************************************************************************
* STEG 12: ESTIMER FAMA-FRENCH TREFAKTORMODELL OG FEMFAKTORMODELL
********************************************************************************

* Trefaktormodell:
*
* R_i - R_f = alpha
*           + beta_mkt * (R_m - R_f)
*           + beta_smb * SMB
*           + beta_hml * HML
*           + epsilon
*
* Femfaktormodell:
*
* R_i - R_f = alpha
*           + beta_mkt * (R_m - R_f)
*           + beta_smb * SMB
*           + beta_hml * HML
*           + beta_mom * MOM
*           + beta_liq * LIQ
*           + epsilon
*
* Begge modellene estimeres separat for hvert selskap og kalenderår.
*
* Bare ukentlige observasjoner fra det aktuelle kalenderåret
* inngår i regresjonene.


foreach o of local orgnr_liste {

    * Hent selskapsinformasjon
    quietly levelsof symbol if orgnr==`o', local(sym)
    local ticker : word 1 of `sym'

    quietly levelsof selskap if orgnr==`o', local(sel)
    local selskapsnavn : word 1 of `sel'


    foreach y of local aar_liste {

        * Initialiser resultater
        local a3 = .
        local bm3 = .
        local bs3 = .
        local bh3 = .
        local r23 = .
        local n3 = .

        local a5 = .
        local bm5 = .
        local bs5 = .
        local bh5 = .
        local bmo5 = .
        local bl5 = .
        local r25 = .
        local n5 = .


        ***********************************************************************
        * 12.1: FAMA-FRENCH TREFAKTORMODELL
        ***********************************************************************

        * Tell gyldige ukeobservasjoner for selskapet og året
        quietly count if ///
            orgnr==`o' & ///
            ar==`y' & ///
            !missing(excess_ret,mkt_excess,smb_w,hml_w)

        local obs3 = r(N)

        * Estimer dersom minimumskravet er oppfylt
        if `obs3'>=`minobs' {

            capture quietly regress excess_ret ///
                mkt_excess smb_w hml_w ///
                if orgnr==`o' & ar==`y'

            if _rc==0 {

                local a3  = _b[_cons]
                local bm3 = _b[mkt_excess]
                local bs3 = _b[smb_w]
                local bh3 = _b[hml_w]

                local r23 = e(r2)
                local n3  = e(N)
            }
        }


        ***********************************************************************
        * 12.2: FAMA-FRENCH FEMFAKTORMODELL
        ***********************************************************************

        * Tell gyldige ukeobservasjoner for selskapet og året
        quietly count if ///
            orgnr==`o' & ///
            ar==`y' & ///
            !missing(excess_ret,mkt_excess,smb_w,hml_w,mom_w,liq_w)

        local obs5 = r(N)

        * Estimer dersom minimumskravet er oppfylt
        if `obs5'>=`minobs' {

            capture quietly regress excess_ret ///
                mkt_excess smb_w hml_w mom_w liq_w ///
                if orgnr==`o' & ar==`y'

            if _rc==0 {

                local a5   = _b[_cons]
                local bm5  = _b[mkt_excess]
                local bs5  = _b[smb_w]
                local bh5  = _b[hml_w]
                local bmo5 = _b[mom_w]
                local bl5  = _b[liq_w]

                local r25 = e(r2)
                local n5  = e(N)
            }
        }


        ***********************************************************************
        * 12.3: LAGRE RESULTATER FOR SELSKAP OG ÅR
        ***********************************************************************

        post beta_handle ///
            (`o') ///
            ("`ticker'") ///
            ("`selskapsnavn'") ///
            (`y') ///
            (`a3') (`bm3') (`bs3') (`bh3') ///
            (`r23') (`n3') ///
            (`a5') (`bm5') (`bs5') (`bh5') ///
            (`bmo5') (`bl5') ///
            (`r25') (`n5')

    }
}

* Avslutt skriving av resultatfil
postclose beta_handle


********************************************************************************
* STEG 13: HENT OG KONTROLLER FAKTORBELASTNINGER
********************************************************************************

use "`beta_fil'", clear

* Sorter etter selskap og år
sort orgnr ar

* Kontroller datastruktur
describe

* Beskrivende statistikk for faktorbelastningene
summarize beta_mkt_3 beta_smb_3 beta_hml_3 ///
          beta_mkt_5 beta_smb_5 beta_hml_5 ///
          beta_mom_5 beta_liq_5

* Kontroller antall observasjoner i regresjonene
summarize n_3 n_5

* Kontroller manglende estimater
misstable summarize ///
    beta_mkt_3 beta_smb_3 beta_hml_3 ///
    beta_mkt_5 beta_smb_5 beta_hml_5 ///
    beta_mom_5 beta_liq_5

* Vis faktorbelastninger per selskap og år
list symbol ar ///
    beta_mkt_3 beta_smb_3 beta_hml_3 ///
    beta_mkt_5 beta_smb_5 beta_hml_5 ///
    beta_mom_5 beta_liq_5 ///
    n_3 n_5, sepby(symbol)

* Kontroller én observasjon per selskap og år
isid orgnr ar


********************************************************************************
* STEG 14: EKSPORT AV ÅRLIGE FAKTORBELASTNINGER
********************************************************************************

* Lagre Stata-fil
save "$prosjekt/fama_french_beta_aar.dta", replace


********************************************************************************
* STEG 15: MERGE FAMA-FRENCH TIL RESTEN 
********************************************************************************

* koble fama_french til resten 
use "$prosjekt/kjor_m_beta_nav.dta", clear


* Koble til årlige Fama-French-betaer
merge 1:1 orgnr ar using ///
    "$prosjekt/fama_french_beta_aar.dta"

* Kontroller resultatet av koblingen
tab _merge

* Behold observasjonene fra hoveddatasettet
keep if _merge == 1 | _merge == 3

* Fjern merge-variabelen
drop _merge


* Lagre endelig datasett
save "$prosjekt/kjor_m_beta_nav_risk.dta", replace
