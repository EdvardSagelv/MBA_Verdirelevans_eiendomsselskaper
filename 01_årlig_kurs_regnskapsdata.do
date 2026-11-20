


/**********************************************************************
STEG 1: IMPORT OG KLARGJØRING AV KURSDATA
 
 Kursdata er hentet fra Titlon, hvor sluttkursen for året er kopiert over til årskurser. Disse er kun tilgjengelig på lisens, se README.md. 
 Om du ikke har lisens og tilgang, kan du hente investing.com sine ukeskurser i excel-filen "uke_samlet.xlsx", og legge de til i "kursdata.xlsx".

 Importerer årlige kursdata og tilhørende markedsverdier.

 Variabelnavn standardiseres, og dato-/årsvariabler klargjøres
 for kobling mot regnskapsdata.

 Organisasjonsnummer og antall aksjer konverteres mellom
 numeriske og tekstbaserte formater for å sikre konsistent
 identifikasjon og håndtering av store tall.

 Observasjoner før 2009 fjernes for å avgrense analyseperioden.

 Regnskapsåret forskyves ett år tilbake, slik at markedsverdien
 fra år t knyttes til regnskapsinformasjon fra år t-1.
 Dette etablerer tidsstrukturen som benyttes i den videre
 analysen av regnskapsmessig verdirelevans.
**********************************************************************/

import excel "$prosjekt/kursdata.xlsx", sheet("Sheet1") firstrow clear

*-------formater----------
format markedsverdi %15.0fc
format antall_aksjer %15.0fc

*-------gen string-------------
gen str12 orgnr_str = string(orgnr, "%12.0f")
gen str12 aksjer_str = string(antall_aksjer, "%12.0f")
* Konverter orgnr_str og aksjer_str tilbake til numerisk
gen orgnr_num = real(orgnr_str)
gen aksjer_num = real(aksjer_str)

*-------drop før 2009------------
drop if Date<2009

* 1. Fiks alle kolonnenavn (kolonner) til små bokstaver
rename *, lower

* 2. Endre navn fra date til ar (hvis den nå heter 'date')
capture rename date ar

*--------gen "rett ar" for å ha kontroll etter kobling mot kursdata----------
gen rett_ar= ar
drop ar
gen ar= rett_ar - 1
rename rett_ar rett_ar_kursdata
*------sjekk duplicates------------
duplicates report orgnr_str ar
// bysort orgnr ar: gen n = _N
// browse if n > 1

*-------lagre til .dta-fil. 
save "$prosjekt/kursdata.dta", replace


/**********************************************************************
 STEG 2: IMPORT OG KONTROLL AV REGNSKAPSDATA

 Importerer historiske regnskapsdata for selskapene.

 Organisasjonsnummer konverteres til tekstformat for å sikre
 konsistent identifikasjon.

 Det kontrolleres for dupliserte observasjoner basert på
 organisasjonsnummer og regnskapsår. Eventuelle duplikater
 fjernes slik at datasettet får én observasjon per selskap og år.

 Årsvariabelen standardiseres til et firesifret regnskapsår.
**********************************************************************/


import excel "$prosjekt/ar_regnskap.xlsx", sheet("Sheet1") firstrow clear

* hvis orgnr er numerisk
gen str12 orgnr_str = string(orgnr, "%12.0f")

*---duplicates

duplicates report
duplicates tag orgnr_str ar, gen(dup)
browse if dup > 0
duplicates drop orgnr_str ar, force
*------drop hvis duplicates
drop dup


/**********************************************************************
 STEG 3: UTVALG OG STANDARDISERING AV REGNSKAPSVARIABLER

 Definerer hvilke regnskapsposter som skal inngå i transformasjon.

 Manglende verdier i de utvalgte regnskapspostene erstattes med
 null. Dette gjøres for å håndtere poster som ikke er rapportert
 separat i regnskapsmaterialet.

 Regnskapstallene divideres deretter med 1 000 for å standardisere
 beløpsstørrelsene til MNOK.
**********************************************************************/

global myvars ///
    Lederlønn Leder_annen_godtgjørelse Sum_salgsinntekter Annen_driftsinntekt Sum_driftsinntekter ///
    Varekostnad Beholdningsendringer Lønnskostnader Herav_kun_lønn Ordinære_avskrivninger Nedskrivning ///
    Andre_driftskostnader Driftsresultat_EBIT Inntekt_på_invest_annet_foretak  ///
    Inntekt_på_investering_i_datters Sum_annen_renteinntekt Inntekt_på_invest_i_tilknyttet_ ///
    Sum_annen_finansinntekt Sum_finansinntekter Nedskrivning_fin_anleggsmidler Sum_annen_rentekostnad ///
    Andre_finanskostnader Sum_annen_finanskostnad Sum_finanskostnader Resultat_før_skatt Sum_skatt ///
    Ordinært_resultat Ekstraordinære_inntekter Ekstraordinære_kostnader Skatt_ekstraordinært Årsresultat ///
    Ordinært_utbytte Ekstraordinært_utbytte Tilleggsutbytte Sum_utbytte Konsernbidrag Goodwill ///
    Sum_immaterielle_midler Sum_anleggsmidler Tomter_bygninger_og_annen_fast_ /// Tomter_bygninger_og_annen_fast_eiendom Driftsløsøre_inventar_verktøy
    Maskineranleggbiler Driftsløsøre_inventar_verktøy Sum_varige_driftsmidler ///
    AksjerInvesteringer_i_dattersel Endr_behold_varer_under_tilvir ///
    Investeringer_i_aksjer_og_andele Andre_finansielle_fordringer Sum_finansielle_anleggsmidler ///
    Sum_varelager Kundefordringer Andre_fordringer Konsernfordringer Sum_fordringer Sum_investeringer ///
    KasseBankPost Sum_KasseBankPost Sum_omløpsmidler Sum_eiendeler AksjeSelskapskapital ///
    Annen_innskutt_egenkapital Sum_innskutt_egenkapital Sum_opptjent_egenkapital Annen_egenkapital ///
    Sum_egenkapital Sum_avsetninger_til_forpliktelse Pantgjeld_til_kredittinstitusjo ///
    Langsiktig_konserngjeld Ansvarlig_lånekapital Sum_annen_langsiktig_gjeld Annen_langsiktig_gjeld ///
    Sum_langsiktig_gjeld Gjeld_til_kredittinstitusjoner Leverandørgjeld Skyldig_offentlige_avgifter ///
    Kortsiktig_konserngjeld Annen_kortsiktig_gjeld Sum_kortsiktig_gjeld Sum_gjeld SUM_EGENKAPITAL_OG_GJELD ///
    Garantistillelser Pantstillelser 

* Først: sett missing til 0
foreach var of global myvars {
    replace `var' = 0 if missing(`var')
}

* Deretter: del på 1000
foreach var of global myvars {
    replace `var' = `var' / 1000
}


/**********************************************************************
 STEG 4: BEREGNING AV FINANSIELLE PRESTASJONSINDIKATORER

 På bakgrunn av de standardiserte regnskapspostene konstrueres
 finansielle nøkkeltall som beskriver selskapenes økonomiske
 situasjon og prestasjoner.

 Nøkkeltallene grupperes i fem hovedområder:

 1. Lønnsomhet:
    Bruttofortjeneste, EBITDA, driftsmargin, EBITDA-margin og
    nettoresultatmargin.

 2. Rentabilitet:
    Avkastning på egenkapital (ROE), totalkapitalrentabilitet
    (ROA) og kapitalavkastning (ROC).

 3. Likviditet og arbeidskapital:
    Likviditetsgrader, arbeidskapital og en forenklet
    kontantstrømindikator.

 4. Soliditet og finansiell risiko:
    Egenkapitalandel, gjeldsgrad, rentedekningsgrad og netto gjeld.

 5. Driftseffektivitet:
    Lønnskostnadsandel, kapitalens omløpshastighet,
    varelagerets omløpshastighet og lederlønnsandel.

 I tillegg beregnes belåningsgrad (LTV), netto finansinntekter
 og netto renteinntekter.
**********************************************************************/

* 1. LØNNSOMHET (PROFITABILITY)
gen bruttofortjeneste = Sum_salgsinntekter - Varekostnad
gen ebitda = Driftsresultat_EBIT + Ordinære_avskrivninger + Nedskrivning

gen driftsmargin = .
replace driftsmargin = Driftsresultat_EBIT / Sum_driftsinntekter if Sum_driftsinntekter >=0
replace driftsmargin = Driftsresultat_EBIT / Sum_salgsinntekter if missing(driftsmargin) & Sum_salgsinntekter > 0

*vurder sum_driftsinntekter isteden for salgsinntekter
gen ebitda_margin_salg = ebitda / Sum_salgsinntekter 
gen ebitda_margin_drift = ebitda / Sum_driftsinntekter
gen netto_margin = Årsresultat / Sum_driftsinntekter
gen operating_margin = Driftsresultat_EBIT / Sum_driftsinntekter

* 2. RENTABILITET (RETURN ON INVESTMENT)
gen roe = Årsresultat / Sum_egenkapital
gen roa = Resultat_før_skatt / Sum_eiendeler
gen roc = Driftsresultat_EBIT / (Sum_egenkapital + Sum_langsiktig_gjeld)

* 3. LIKVIDITET OG ARBEIDSKAPITAL
gen likviditetsgrad1 = Sum_omløpsmidler / Sum_kortsiktig_gjeld
gen likviditetsgrad2 = (Sum_omløpsmidler - Sum_varelager) / Sum_kortsiktig_gjeld
gen arbeidskapital = Sum_omløpsmidler - Sum_kortsiktig_gjeld
gen kontantstrom = Årsresultat + Ordinære_avskrivninger + Nedskrivning

* 4. SOLIDITET OG FINANSIELL RISIKO
gen ek_andel = Sum_egenkapital / Sum_eiendeler
gen gjeldsgrad = Sum_gjeld / Sum_egenkapital
gen rentedekning = Driftsresultat_EBIT / Sum_annen_rentekostnad
gen netto_gjeld = (Sum_langsiktig_gjeld + Gjeld_til_kredittinstitusjoner) - KasseBankPost

* 5. DRIFTSEFFEKTIVITET
gen lonn_andel_omsetning = Lønnskostnader / Sum_salgsinntekter
gen asset_turnover = Sum_driftsinntekter / Sum_eiendeler
gen varelager_omlop = Varekostnad / Sum_varelager
gen lederlonn_andel = Lederlønn / Lønnskostnader

*------------LTV------------------
gen ltv = Sum_gjeld / Sum_eiendeler

*-------------netto finansinntekter------------*
gen net_finance = Sum_finansinntekter - Sum_finanskostnader
gen net_interest = Sum_annen_renteinntekt - Sum_annen_rentekostnad

/**********************************************************************
 STEG 5: OPPRYDDING OG KONTROLL AV FINANSIELLE NØKKELTALL

 Kontrollerer de konstruerte nøkkeltallene for ugyldige
 numeriske verdier som kan oppstå ved divisjon med null.

 Verdier som ikke representerer reelle tall, erstattes med
 manglende observasjoner (missing).

 Manglende verdier beholdes som missing fremfor å bli
 automatisk erstattet med null, ettersom null og manglende
 regnskapsinformasjon ikke nødvendigvis har samme betydning.

 Det ferdig bearbeidede regnskapsdatasettet lagres for videre
 sammenstilling med markedsdata.
**********************************************************************/

* Erstatte uendelige verdier (hvis man deler på 0) med missing
foreach v of varlist bruttofortjeneste-lederlonn_andel {
    * Stata lagrer 'uendelig' som en type missing value. 
    * Vi tvinger alle verdier som ikke er reelle tall til å bli missing (.)
    replace `v' = . if `v' >= .
}

*------fiks ar-variabelen------------
replace ar = floor(ar/100)

*------lagre til .dta-fil
save "$prosjekt/kjor_2.dta", replace


/*-------slutt-----------*/



