


/**********************************************************************
 DESKRIPTIV STATISTIKK

 
 produserer dataene etter eksploraitv analyser.
 
 
 Gjennomfører deskriptive analyser av variablene som inngår
 i de videre regresjonsmodellene.

 Det beregnes sentralmål og spredningsmål for blant annet
 markedsverdi, P/NTA, årlig aksjeavkastning, lønnsomhet,
 eiendomsverdier, belåningsgrad, driftsinntekter,
 finansposter og beta.

 Statistikken undersøkes både for det samlede analyseutvalget
 og separat for enkelte selskaper.

 
 kjører kursutvikling fra start på børs til og med 2025
 
**********************************************************************/

/*---------produserer dataene etter eksploraitv analyser. Beholder noen uendret for deskriptiv---------*/


use "$prosjekt/kjor_m_beta_nav_risk.dta", clear

drop if selskap=="public_property_invest_asa"

/*--- fiks p_nta */
gen nta_mnok= nta/1000000
format nta %15.0fc
gen p_nta= market_cap_mnok / nta_mnok
 gen ln_p_nta = ln(p_nta)
 
 /*-----log------*/
gen ln_mv = ln(market_cap_mnok)
gen ln_p_nav = ln(p_nav)
/*-----formater--------*/
format markedsverdi %15.0fc
format antall_aksjer %15.0fc
/*------lag årlig avkastning----------*/
replace adj_close=close_euornext if missing(adj_close)
bysort orgnr (ar): gen growth_pct_m = (adj_close - adj_close[_n-1]) / adj_close[_n-1] * 100
bysort orgnr (ar): gen growth_mv = adj_close - adj_close[_n-1]
  /* fix variables */
  * fix på OLT, hvor eiendommer er postert feil i proff.no, til immatrielle eiendeler, sjekket i årsrapport.
gen property_value = Sum_immaterielle_midler if (selskap=="olav_thon_eiendomsselskap_asa" & ar==2024)
replace property_value=Sum_varelager if selskap =="selvaag_bolig_asa"
replace property_value=Tomter_bygninger_og_annen_fast_ if missing(property_value)
gen ltv_property = Sum_gjeld/property_value
gen ltv_bank = ///
(Pantgjeld_til_kredittinstitusjo + Gjeld_til_kredittinstitusjoner) ///
/ property_value
gen equity_ratio = Sum_egenkapital / Sum_eiendeler
gen rental_income = Sum_driftsinntekter
gen debt_rate = Sum_annen_rentekostnad / Sum_gjeld
gen net_debt = Sum_gjeld - Sum_KasseBankPost
/*-----log------------*/
gen ln_property = ln(property_value)
gen ln_rental = ln(rental_income + 1)
gen ln_ebitda = asinh(ebitda)
gen ln_net_finance = asinh(net_finance)
gen utbytte_yield_p=utbytte_yield*100

/*-------MERK: ingen winsorisering for deskriptive data-----------*/
  
  
  
********************************************************************************
* Deskriptive analyser
********************************************************************************
  
   reg ln_mv ///
	  roe ///
      ln_property ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield ///
	  beta_obx ///
	  i.ar  if !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)

	  /*------totalt--------_*/
	  summarize market_cap_mnok p_nta growth_pct_m roe ebitda ltv ltv_property rental_income net_finance ///
          utbytte_yield_p beta_obx beta_osebx beta_osebx_re if e(sample),  detail
	/*------- for hvert selskap----------*/
	 bysort selskap: summarize market_cap_mnok p_nta growth_pct_m roe ebitda ltv ltv_property rental_income net_finance ///
          utbytte_yield_p beta_obx beta_osebx beta_osebx_re  



		  
/**********************************************************************
 ANALYSE AV RELATIV KURSUtVIKLING

 Konstruerer en indeksert fremstilling av kursutviklingen
 for selskapene og de relevante markedsindeksene.

 Justerte sluttkurser benyttes, og hvert selskap får
 en egen startverdi basert på sin første tilgjengelige
 observasjon i analyseperioden.

 Kursutviklingen indekseres slik at alle seriene starter
 på samme referansepunkt.

 Formålet er å sammenligne den relative kursutviklingen
 mellom eiendomsselskapene og markedsindeksene over tid.

 Resultatene presenteres grafisk.
**********************************************************************/
		  
use "$prosjekt/kursdata.dta", clear


*---------lag graf om relativ utvikling---------------*

drop if selskap=="public_property_invest_asa"

drop if rett_ar<2009
drop if missing(adj_close)

* Sorter først
sort selskap rett_ar

* Finn startkursen (første observasjon) for hvert selskap
bysort selskap (rett_ar): gen start_verdi = adj_close[1]

* Lag en indeksert variabel (alt starter på 100)
gen adj_close_index = (adj_close / start_verdi - 1) * 100

* Lag nye variabler for grafen
capture drop adj_index_* // Fjerner gamle hvis du kjører koden på nytt
separate adj_close_index, by(selskap) gen(adj_index_)




twoway ///
(line adj_index_1 rett_ar, lcolor("black") lwidth(medium) lpattern(dash)) ///
(line adj_index_2 rett_ar, lcolor("gray") lwidth(medium) lpattern(dash)) ///
(line adj_index_3 rett_ar, lcolor("black") lwidth(medium) lpattern(dot)) ///
(line adj_index_4 rett_ar, lcolor("navy") lwidth(medthick)) ///
(line adj_index_5 rett_ar, lcolor("gold") lwidth(medthick)) ///
(line adj_index_6 rett_ar, lcolor("orange_red") lwidth(medthick)) ///
(line adj_index_7 rett_ar, lcolor("brown") lwidth(medthick)) ///
(line adj_index_8 rett_ar, lcolor("forest_green") lwidth(medthick)) ///
(line adj_index_9 rett_ar, lcolor("orange") lwidth(medthick)) ///
(line adj_index_10 rett_ar, lcolor("stone") lwidth(medthick)) ///
, ///
yline(0, lcolor(black) lwidth(thin) lpattern(dash)) ///
title("Relativ avkastning per selskap") ///
xtitle("År") ///
ytitle("Relativ avkastning (%)") ///
legend( ///
    label(1 "OBX") ///
    label(2 "OBX Real Estate GR") ///
    label(3 "OSEBX") ///
	label(4 "Baltic Sea Properties AS") ///
    label(5 "Black Sea Property AS") ///
    label(6 "Entra ASA") ///
    label(7 "KMC Properties ASA") ///
    label(8 "Olav Thon Eiendomsselskap ASA") ///
    label(9 "Pioneer Property Group ASA") ///
    label(10 "Selvaag Bolig ASA") ///
    title("Selskap", size(small)) ///
    size(vsmall) ///
    cols(1) ///
) ///
graphregion(color(white)) ///
plotregion(color(white)) ///
ylabel(-100(100)600, grid) ///
xlabel(2009(2)2025, nogrid labsize(small) angle(45))


/*------------slutt---------------_*/
