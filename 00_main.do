

****************************************************
* 00_MAIN FILE 
* MASTEROPPGAVE i MBA: Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper 

* Av: 
* - Edvard Hamnvik Sagelv, PhD
* - Sigurd Sogn Tjernes, BSc

* Hvordan opperer filene:

* Denne filen kjører alle filer i prosjektet. 
* kjør filene fra 01-08 i rekkefølge, da de har avhengigheter til hverandre. 
* Når filene er kjørt kan du kjøre 1 og 1, slik du ønsker
****************************************************


* installer pakker hvis ikke installert
*---installer asdoc - lagrer resultat til word.fil
ssc install asdoc, replace
*---intaller winsor - winsoriserer data
ssc install winsor2, replace 
*---Lagrer og eksporterer analyseresultater
ssc install estout, replace
/*----installer coefplot - type figur-----*/
ssc install coefplot, replace
*-----håndtere nødvendige pakkeavhengigheter i Stata-kode.
ssc install require, replace
*------flere nivåer av faste effekter (high-dimensional fixed effects).
ssc install reghdfe, replace
*-----gjør beregninger og dataoperasjoner mer effektive. 
ssc install ftools, replace

*-----Prosjektmappe------
* sett filbane - hvor du har lagret filene
global prosjekt "SETT INN DIN FILBANE"

* Gå til prosjektmappen
cd "$prosjekt"

*-----utils---------------
*------Steg 1: last og tranformer data-----------
	* 01_årlig_kurs_regnskapsdata
	do "$prosjekt/01_årlig_kurs_regnskapsdata.do"

	* 02_generer_beta
	do "$prosjekt/02_generer_beta.do"

	* 03_kobling_kurs_regnskap_beta
	do "$prosjekt/03_kobling_kurs_regnskap_beta.do"

	* 04_titlon_risikofaktorer
	do "$prosjekt/04_feature_engineering_titlon_risikofaktorer.do"

*-------Eksplorativ dataanalyse
* 05_eksplorativ_dataanalyse
    do "$prosjekt/05_eksplorativ_dataanalyse.do"

*--------06_deskriptiv_statistikk
* 06_deskriptiv_statistikk
    do "$prosjekt/06_deskriptiv_statistikk.do"

*---------hovedanalyser
* 07_hovedanalyser
    do "$prosjekt/07_hovedanalyser.do"

*---------sensitivitetsanalyser
* 08_sensitivitetsanalyser
    do "$prosjekt/08_sensitivitetsanalyser.do"


display "ALLE FILER ER KJØRT!"

****************************************************
* SLUTT
****************************************************
