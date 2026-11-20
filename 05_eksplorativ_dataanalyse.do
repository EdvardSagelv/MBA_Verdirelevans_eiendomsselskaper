


/**********************************************************************
 STEG 1: AVGRENSNING AV ANALYSEUTVALGET OG KONSTRUKSJON
 AV VERDSETTELSESMÅL

 Det sammenstilte datasettet benyttes som utgangspunkt for
 den videre analysen.

 Public Property Invest fjernes fra analyseutvalget.

 EPRA NTA omregnes til millioner kroner, og P/NTA beregnes
 som forholdet mellom markedsverdi og EPRA NTA.

 P/NTA, P/NAV og markedsverdi logaritmeres for å redusere
 skjevhet og gjøre verdsettelsesmålene mer egnet for
 regresjonsanalyse.
 
 til genereres et analysedatasett
 
**********************************************************************/

  use "$prosjekt/kjor_m_beta_nav_risk.dta", clear

drop if selskap=="public_property_invest_asa"

/*--- fiks p_nta */
gen nta_mnok= nta/1000000
format nta %15.0fc
gen p_nta= market_cap_mnok / nta_mnok

/*---avhengige variabler logaritmeres--------*/ 
gen ln_p_nta = ln(p_nta)
gen ln_mv = ln(market_cap_mnok)
gen ln_p_nav = ln(p_nav)

/**********************************************************************
 STEG 2: BEREGNING AV ÅRLIG AKSJEAVKASTNING

 Justert sluttkurs benyttes som grunnlag for beregning
 av årlig aksjeavkastning.

 Dersom justert sluttkurs mangler, benyttes sluttkursen
 fra Euronext som alternativ.

 Årlig prosentvis kursendring beregnes for hvert selskap
 basert på forskjellen mellom inneværende og foregående års
 justerte sluttkurs.

 Det beregnes også en absolutt kursendring.
**********************************************************************/

format markedsverdi %15.0fc
format antall_aksjer %15.0fc
replace adj_close=close_euornext if missing(adj_close)
bysort orgnr (ar): gen growth_pct_m = (adj_close - adj_close[_n-1]) / adj_close[_n-1] * 100
bysort orgnr (ar): gen growth_mv = adj_close - adj_close[_n-1]


/**********************************************************************
 STEG 3: KONSTRUKSJON AV EIENDOMS- OG FINANSIERINGSVARIABLER

 Konstruerer alternative mål på selskapenes eiendomsverdier
 og finansielle struktur.

 For eiendomsselskapene benyttes bokførte tomter, bygninger
 og annen fast eiendom som mål på eiendomsverdi.

 For Selvaag Bolig benyttes varelager som alternativt
 eiendomsrelatert balansegrunnlag, ettersom selskapets
 virksomhet er knyttet til boligutvikling.

 Det beregnes belåningsgrad relativt til eiendomsverdier,
 bankfinansiering relativt til eiendomsverdier,
 egenkapitalandel, driftsinntekter, gjennomsnittlig
 rentekostnad og netto gjeld.

 Variablene skal fange opp forskjeller i eiendomsrelatert
 kapitalstruktur, driftseffektivitet og finansiell risiko.
**********************************************************************/


  /* fix variables */
  * fix på OLT, hvor eiendommer er postert feil i proff.no, til immatrielle eiendeler, sjekket i årsrapport -> dette er verdi på invisteringseiendom
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


/**********************************************************************
 STEG 4: BEREGNING AV ÅRLIGE ENDRINGER (DELTA)

 Beregner endringer i sentrale finansielle nøkkeltall fra
 foregående til inneværende regnskapsår.

 Endringsvariablene konstrueres for hvert selskap separat.
 
 Formålet er å undersøke om endringer i selskapenes
 finansielle situasjon har sammenheng med verdsettelse
 og aksjeavkastning.
**********************************************************************/
* Sorter etter selskap og år
sort selskap ar

* Beregn endring fra året før - delta
by selskap: gen delta_roe = roe - roe[_n-1]
by selskap: gen delta_ebitda = ebitda - ebitda[_n-1]
by selskap: gen delta_kontantstrom = kontantstrom - kontantstrom[_n-1]
by selskap: gen delta_asset_turnover = asset_turnover - asset_turnover[_n-1]
by selskap: gen delta_ltv = ltv - ltv[_n-1]
by selskap: gen delta_ltv_property = ltv_property - ltv_property[_n-1]
by selskap: gen delta_utbytte_yield = utbytte_yield - utbytte_yield[_n-1]
by selskap: gen delta_beta_obx = beta_obx - beta_obx[_n-1]
by selskap: gen delta_net_finance = net_finance - net_finance[_n-1]
by selskap: gen delta_property_value = property_value - property_value[_n-1]
by selskap: gen delta_Sum_eiendeler = Sum_eiendeler - Sum_eiendeler[_n-1]
by selskap: gen delta_equity_ratio = equity_ratio - equity_ratio[_n-1]
by selskap: gen delta_net_debt = net_debt - net_debt[_n-1]
by selskap: gen delta_rental_income = rental_income - rental_income[_n-1]
by selskap: gen delta_debt_rate = debt_rate - debt_rate[_n-1]
 
 

/**********************************************************************
 STEG 5: EKSPLORATIV KORRELASJONSANALYSE OG
 KONTROLL AV MULTIKOLLINEARITET

 Gjennomfører en innledende regresjon for å etablere
 analyseutvalget som benyttes i den videre korrelasjonsanalysen.

 Pearsons korrelasjonskoeffisienter beregnes mellom aktuelle
 uavhengige variabler og endringsvariabler.

 Formålet er å undersøke graden av lineær samvariasjon
 mellom forklaringsvariablene og identifisere potensielle
 utfordringer med multikollinearitet.

 Analysene brukes som støtte ved utvelgelse og spesifikasjon
 av regresjonsmodellene.
**********************************************************************/

/*-----om du ikke har installert asdoc ----*/
// ssc install asdoc

/*------kjør regresjon for å holde e(sample) - de observasjonene som skal være med i analyser----------*/

   reg ln_mv ///
	  roe ///
      property_value ///
      ltv ///
      rental_income ///
	  net_finance ///
      utbytte_yield ///
	  beta_obx ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)

asdoc pwcorr roe ebitda kontantstrom asset_turnover ltv ltv_property utbytte_yield ///
    beta_obx net_finance ///
    property_value ///
    Sum_eiendeler equity_ratio net_debt ///
    rental_income debt_rate if e(sample) & !(selskap=="kmc_properties_asa" & ar==2024), sigstar(0.05)

	pwcorr roe ebitda kontantstrom asset_turnover ltv ltv_property utbytte_yield ///
    beta_obx net_finance ///
    property_value ///
    Sum_eiendeler equity_ratio net_debt delta_ebitda ///
    rental_income debt_rate if e(sample) & !(selskap=="kmc_properties_asa" & ar==2024), star(0.05)
	
	
	pwcorr delta_roe delta_ebitda delta_asset_turnover delta_ltv delta_ltv_property delta_utbytte_yield ///
    delta_beta_obx delta_net_finance ///
    delta_property_value ///
    delta_Sum_eiendeler delta_equity_ratio delta_net_debt delta_ebitda ///
    rental_income debt_rate delta_ebitda delta_ltv_property delta_net_finance if e(sample) & !(selskap=="kmc_properties_asa" & ar==2024), star(0.05)
	
	
	
	
/**********************************************************************
 STEG 6: IDENTIFISERING AV MULIGE UTELIGGERE - boksplott

 Undersøker fordelingen av aktuelle uavhengige variabler
 ved hjelp av boksplott.

 Variablene grupperes etter økonomisk innhold for å gjøre
 ekstreme observasjoner lettere å identifisere.

**********************************************************************/

/*------kjør regresjon for å holde e(sample) - de observasjonene som skal være med i analyser----------*/

   reg ln_mv ///
	  roe ///
      property_value ///
      ltv ///
      rental_income ///
	  net_finance ///
      utbytte_yield ///
	  beta_obx ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)
	  
*------label data til figur
	label variable roe              "ROE"
	label variable ebitda           "EBITDA"
	label variable kontantstrom 	"Kontantstrøm"
	label variable asset_turnover   "Kapitalens omløpshastighet"
	label variable ltv              "Belåningsgrad"
	label variable ltv_property		"Belåningsgrad eiendom"
	label variable utbytte_yield    "Direkteavkastning"
	label variable beta_obx         "Beta (OBX)"
	label variable net_finance      "Netto finansinntekter"
	label variable property_value   "Eiendomsverdi"
	label variable Sum_eiendeler    "Sum eiendeler"
	label variable net_debt         "Netto gjeld"
	label variable equity_ratio 	"Egenkapitalandel"
	label variable rental_income    "Sum driftsinntekter"
	label variable debt_rate        "Gj. rentekostnad"
	
	
	graph box roe asset_turnover beta_obx if e(sample), ///
		horizontal ///
		name(g1, replace)

	graph box ltv ltv_property utbytte_yield equity_ratio debt_rate if e(sample), ///
		horizontal ///
		name(g2, replace)

	graph box ebitda rental_income net_finance if e(sample), ///
		horizontal ///
		name(g3, replace)

	graph box property_value Sum_eiendeler net_debt if e(sample), ///
    horizontal ///
    name(g4, replace)
	
	graph combine g1 g2 g3 g4, ///
		cols(2) ///
		title("Boksplott av mulige uavhengige variabler")
		
/*-------------------------box plot delta------------------*/

/*------kjør regresjon for å holde e(sample) - de observasjonene som skal være med i analyser----------*/
 reg ln_mv ///
	  roe ///
      property_value ///
      ltv ///
      rental_income ///
	  net_finance ///
      utbytte_yield ///
	  beta_obx ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)
	
	*label
	label variable delta_roe              "ROE"
	label variable delta_ebitda           "EBITDA"
	label variable delta_kontantstrom 	"Kontantstrøm"
	label variable delta_asset_turnover   "Kapitalens omløpshastighet"
	label variable delta_ltv              "Belåningsgrad"
	label variable delta_ltv_property		"Belåningsgrad eiendom"
	label variable delta_utbytte_yield    "Direkteavkastning"
	label variable delta_net_finance      "Netto finansinntekter"
	label variable delta_property_value   "Eiendomsverdi"
	label variable delta_Sum_eiendeler    "Sum eiendeler"
	label variable delta_net_debt         "Netto gjeld"
	label variable delta_equity_ratio 	"Egenkapitalandel"
	label variable delta_rental_income    "Sum driftsinntekter"
	label variable delta_debt_rate        "Gj. rentekostnad"


	graph box delta_roe delta_asset_turnover delta_utbytte_yield delta_ltv delta_ltv_property delta_equity_ratio delta_debt_rate if e(sample), ///
		horizontal ///
		ylabel(, format(%15.2fc)) ///
		name(g1, replace)


	graph box delta_ebitda delta_rental_income delta_net_finance if e(sample), ///
		horizontal ///
		ylabel(, format(%15.0fc) angle(45)) ///
		name(g2, replace)

	graph box delta_property_value delta_Sum_eiendeler delta_net_debt if e(sample), ///
		horizontal ///
		ylabel(, format(%15.0fc) angle(45)) ///
		name(g3, replace)
		

	graph combine g1 g2 g3, ///
		cols(2) ///
		title("Boksplott av mulige uavhengige variabler (delta)")


	/**********************************************************************
 STEG 7: WINSORISERING AV UTVALGTE VARIABLER

 Winsoriserer utvalgte finansielle nøkkeltall og endringsvariabler
 ved 5. og 95. persentil.

 Observasjoner utenfor disse grensene erstattes med verdiene
 ved de respektive persentilene.

 Variabler som ikke inngår i winsoriseringen, beholdes
 uendret.
**********************************************************************/

/*--------installer winsor2 om du ikke har det-----------*/
// ssc install winsor2 

	winsor2 roe asset_turnover beta_obx ebitda net_finance ltv ltv_property utbytte_yield equity_ratio ebitda net_finance ///
	delta_roe delta_ebitda delta_asset_turnover delta_ltv delta_ltv_property delta_utbytte_yield ///
		 delta_net_finance ///
		delta_property_value ///
		delta_Sum_eiendeler delta_equity_ratio delta_net_debt delta_ebitda ///
		rental_income debt_rate delta_ebitda delta_ltv_property delta_net_finance, replace cuts(5 95)


/**********************************************************************
 STEG 8: TRANSFORMASJON AV FORKLARINGSVARIABLER

 Konstruerer transformerte versjoner av sentrale
 finansielle variabler.

 Eiendomsverdier og driftsinntekter logaritmeres for å
 redusere skjevhet og håndtere store forskjeller i
 selskapenes størrelse.

 EBITDA og netto finansinntekter transformeres med
 invers hyperbolsk sinus (asinh). Denne transformasjonen
 kan benyttes også når variablene inneholder null eller
 negative verdier.

 Endringsvariabler som kan inneholde negative verdier,
 transformeres tilsvarende med asinh der dette er relevant.

 Direkteavkastning omregnes til prosentform.
**********************************************************************/


gen ln_property = ln(property_value)
gen ln_rental = ln(rental_income + 1)
gen ln_ebitda = asinh(ebitda)
gen ln_net_finance = asinh(net_finance)

/**********************************************************************
 STEG 8: Cooks D

Undersøker cooks d for innflytelsesrike observasjoner 

**********************************************************************/
	 
	 *----------------P/NTA------------------------------
	reg ln_p_nta roe ltv ln_rental utbytte_yield asset_turnover beta_obx i.ar
	*--predict cooks d
	 predict cooksd, cooksd
	gen obsnr = _n
	*--scatter 
	scatter cooksd obsnr, ///
		yline(`=4/_N', lcolor(red)) ///
		title("Cook's distanse") ///
		subtitle("P/NTA") ///
		ytitle("Cook's D") ///
		xtitle("Observasjon") ///
		msymbol(dot) ///
		mcolor(navy) ///
		graphregion(fcolor(white)) ///
		plotregion(fcolor(white)) ///
		scheme(s2mono)
		
		/*---- identifiser cooksd > 4/_N */
		list cooksd selskap ar if cooksd > 4/_N
	 
		* med ekstremobserasjon
	reg ln_p_nta roe ltv ln_rental utbytte_yield asset_turnover beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
		
		* uten ekstremobservasjon
	reg ln_p_nta roe ltv ln_rental utbytte_yield asset_turnover beta_obx i.ar if ///
			!(selskap=="selvaag_bolig_asa" & ar==2023) ///
			& !(selskap=="black_sea_property_as" & ar==2017) ///
			& !(selskap=="kmc_properties_asa" & ar==2023) ///
			& !(selskap=="kmc_properties_asa" & ar==2024) 

	  *se på disse selskapene
	  browse selskap ln_p_nav roe ltv beta_obx ln_rental ar if ///
			!(selskap=="selvaag_bolig_asa" & ar==2023) ///
			& !(selskap=="black_sea_property_as" & ar==2017) ///
			& !(selskap=="kmc_properties_asa" & ar==2023) ///
			& !(selskap=="kmc_properties_asa" & ar==2024) ///
			& !(selskap=="olav_thon_eiendomsselskap_asa" & ar==2010) 
	
	/*---drop cookd og obsnr */
	 drop cooksd
     drop obsnr
	
	*----------------------markedsverdi---------------------

		* modell 
	  reg ln_mv ///
	  roe ///
      ln_property ///
      ltv ///
      ln_rental ///
      beta_obx ///
	  utbytte_yield ///
	  ln_net_finance ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
      
	* Cooks d
	predict cooksd, cooksd
	gen obsnr = _n
	* scatter
	scatter cooksd obsnr, ///
		yline(`=4/_N', lcolor(red)) ///
		title("Cook's distanse") ///
		subtitle("Markedsverdi") ///
		ytitle("Cook's D") ///
		xtitle("Observasjon") ///
		msymbol(dot) ///
		mcolor(navy) ///
		graphregion(fcolor(white)) ///
		plotregion(fcolor(white)) ///
		scheme(s2mono)
	
	/*---- identifiser cooksd > 4/_N */
	list cooksd selskap ar if cooksd > 4/_N
	
	/*-------undersøk uten ekstremobservasjon */
	  reg ln_mv ///
	  roe ///
      ln_property ///
      ltv ///
      ln_rental ///
      beta_obx ///
	  utbytte_yield ///
	  ln_net_finance ///
	  i.ar if !(selskap=="olav_thon_eiendomsselskap_asa" & ar==2024) ///
			& !(selskap=="olav_thon_eiendomsselskap_asa" & ar==2012) ///
			& !(selskap=="olav_thon_eiendomsselskap_asa" & ar==2010) ///
			& !(selskap=="black_sea_property_as" & ar==2017) ///
			& !(selskap=="black_sea_property_as" & ar==2024) ///
			& !(selskap=="kmc_properties_asa" & ar==2024) ///
			& !(selskap=="kmc_properties_asa" & ar==2023) ///
			& !(selskap=="entra_asa" & ar==2023) ///
			& !(selskap=="pioneer_property_group_asa" & ar==2019) ///
			& !(selskap=="pioneer_property_group_asa" & ar==2020) 

			
			* se på disse selskapene og årene
		browse selskap ar ///
			 ln_mv roe ln_property ltv ln_rental beta_obx ///
			 utbytte_yield ln_net_finance 
			
	/*---drop cookd og obsnr */
	  drop cooksd
     drop obsnr
	
	*--------------------growth------------------------------------
	reg growth_pct_m ///
    ln_ebitda ///
    asset_turnover ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	 
	* Cooks d
	predict cooksd, cooksd
	gen obsnr = _n
	* scatter
	scatter cooksd obsnr, ///
    yline(`=4/_N', lcolor(red)) ///
    title("Cook's distanse") ///
    subtitle("Årlig Avkastning") ///
    ytitle("Cook's D") ///
    xtitle("Observasjon") ///
    msymbol(dot) ///
    mcolor(navy) ///
    graphregion(fcolor(white)) ///
    plotregion(fcolor(white)) ///
    scheme(s2mono)
	
	/*---- identifiser cooksd > 4/_N */
	list cooksd selskap ar if cooksd > 4/_N

	/*-------undersøk uten ekstremobservasjon */
	reg growth_pct_m ///
    ln_ebitda ///
    asset_turnover ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if ///
			 !(selskap=="selvaag_bolig_asa" & ar==2018) ///
			& !(selskap=="olav_thon_eiendomsselskap_asa" & ar==2010) ///
			& !(selskap=="olav_thon_eiendomsselskap_asa" & ar==2011) ///
			& !(selskap=="black_sea_property_as" & ar==2018) ///y
			& !(selskap=="black_sea_property_as" & ar==2017) ///
			& !(selskap=="kmc_properties_asa" & ar==2023) ///
			& !(selskap=="kmc_properties_asa" & ar==2024) 

	/*---drop cookd og obsnr */
		drop cooksd
     drop obsnr
	
	
	
/**********************************************************************
 STEG 8: VIF
	Sjekk VIF
**********************************************************************/
	
	* P/NTA
	reg ln_p_nta roe ltv ln_rental utbytte_yield asset_turnover beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* få VIF
	vif
	
	*markedsverdi
	reg ln_mv ///
	  roe ///
      ln_property ///
      ltv ///
      ln_rental ///
      beta_obx ///
	  utbytte_yield ///
	  ln_net_finance ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	  * få VIF
		vif
		
	/*--------eiendomsverdi og driftsinntekter skaper multikollinearitet med VIF------*/
	/*-------bedre uten eiendomsverdi ----*/
	reg ln_mv ///
	  roe ///
      ltv ///
      ln_rental ///
      beta_obx ///
	  utbytte_yield ///
	  ln_net_finance ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	  * få VIF
		vif
	
	*growth	
	reg growth_pct_m ///
    ln_ebitda ///
    asset_turnover ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* få VIF
	vif
	
/**********************************************************************
	 STEG 9: 	 residualer for normalitet
	Sjekk  residualer for normalitet
**********************************************************************/

		*-------------------P/NTA-----------------------
	reg ln_p_nta roe ltv ln_rental utbytte_yield asset_turnover beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* residualer
	predict resid if e(sample), residuals
	* residualplot
	qnorm resid , ///
    title("Q-Q-plot av regresjonsresidualer") ///
	subtitle("P/NTA") ///
    note("Referanselinjen indikerer normalfordeling") ///
    ytitle("Residualer") ///
    xtitle("Teoretiske normale kvantiler") ///
    msymbol(dot) ///
    msize(small) ///
    mcolor(navy) ///
    lcolor(navy) ///
	ylabel(-4(1)2) ///
    lpattern(solid) ///
    graphregion(fcolor(white)) ///
    plotregion(fcolor(white)) ///
    bgcolor(white) ///
    scheme(s2mono)
		
	/*------shapiro-wilk for normalitet -----*/
			swilk resid
	/*-----drop resid--------*/
	drop resid
	   
/*---------markedsverdi----------------*/
	  reg ln_mv ///
      ltv_property ///
      ln_rental ///
      beta_obx ///
	  utbytte_yield ///
	  net_finance ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* residualer
	predict resid if e(sample), residuals
	* residualplot
	qnorm resid , ///
    title("Q-Q-plot av regresjonsresidualer") ///
	subtitle("Markedsverdi") ///
    note("Referanselinjen indikerer normalfordeling") ///
    ytitle("Residualer") ///
    xtitle("Teoretiske normale kvantiler") ///
    yticks(-4(1)3) ///
    ylabel(-4(1)3) ///
    xlabel(-2(1)2) ///
    msymbol(dot) ///
    msize(small) ///
    mcolor(navy) ///
    lcolor(navy) ///
    lpattern(solid) ///
    graphregion(fcolor(white)) ///
    plotregion(fcolor(white)) ///
    bgcolor(white) ///
    scheme(s2mono)

	/*------shapiro-wilk for normalitet -----*/
	swilk resid
	/*-----drop resid--------*/
	drop resid

	*---------------growth---------------------------
	reg growth_pct_m ///
    ln_ebitda ///
    asset_turnover ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* residualer
	predict resid if e(sample), residuals
	* residualplot
	qnorm resid , ///
    title("Q-Q-plot av regresjonsresidualer") ///
	subtitle("Årlig Avkastning") ///
    note("Referanselinjen indikerer normalfordeling") ///
    ytitle("Residualer") ///
    xtitle("Teoretiske normale kvantiler") ///
    ylabel(-100(25)50) ///
    xlabel(-40(10)40) ///
    msymbol(dot) ///
    msize(small) ///
    mcolor(navy) ///
    lcolor(navy) ///
    lpattern(solid) ///
    graphregion(fcolor(white)) ///
    plotregion(fcolor(white)) ///
    bgcolor(white) ///
    scheme(s2mono)
	
	/*------shapiro-wilk for normalitet -----*/
	swilk resid
	/*-----drop resid--------*/
	drop resid


/**********************************************************************
	 *--------------rfvplot------------------

	 sjekk rfvplot for heteroskedastisitet
**********************************************************************/

	*-----------------P/NAV------------------------

	reg ln_p_nta roe ltv ln_rental utbytte_yield asset_turnover beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* residualer
	predict resid if !(selskap=="kmc_properties_asa" & ar==2024), residuals
	/*--------Breusch–Pagan-test ----------*/
	estat hettest
	 * rvfplot
	 rvfplot, ///
    yline(0, lcolor(red) lpattern(dash)) ///
    title("Residualer vs predikerte verdier") ///
    subtitle("P/NTA") ///
    ytitle("Residualer") ///
    xtitle("Predikerte verdier av log(P/NTA)") ///
	 yticks(-4(1)2) ///
    ylabel(-4(1)2) ///
    msymbol(dot) ///
    msize(small) ///
    mcolor(navy) ///
    lcolor(navy) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    scheme(s2mono)
	
	/*-----drop resid--------*/
	drop resid
	
	*---------------markedsverdi--------------
	   reg ln_mv ///
      ltv ///
      ln_rental ///
      beta_obx ///
	  utbytte_yield ///
	  net_finance ///
	  i.ar  if !(selskap=="kmc_properties_asa" & ar==2024)
	  * residualer
	predict resid if !(selskap=="kmc_properties_asa" & ar==2024), residuals
	/*--------Breusch–Pagan-test ----------*/
	  estat hettest
	 * rvfplot
	rvfplot, ///
    yline(0, lcolor(red) lpattern(dash)) ///
    title("Residualer vs predikerte verdier") ///
    subtitle("Markedsverdi") ///
    ytitle("Residualer") ///
    xtitle("Predikerte verdier av log(markedsverdi)") ///
	 yticks(-4(1)3) ///
    ylabel(-4(1)3) ///
    msymbol(dot) ///
    msize(small) ///
    mcolor(navy) ///
    lcolor(navy) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    scheme(s2mono)
	   
	 /*-----drop resid--------*/
	drop resid

	*----------------growth--------------------------
	reg growth_pct_m ///
    ln_ebitda ///
    asset_turnover ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024)
	* residualer
	predict resid if !(selskap=="kmc_properties_asa" & ar==2024), residuals
	/*--------Breusch–Pagan-test ----------*/
	 estat hettest
	* rvfplot
	  rvfplot, ///
    yline(0, lcolor(red) lpattern(dash)) ///
    title("Residualer vs predikerte verdier") ///
    subtitle("Årlig Avkastning") ///
    ytitle("Residualer") ///
    xtitle("Predikerte verdier av årlig avkastningv (%)") ///
	yticks(-100(25)50) ///
    ylabel(-100(25)50) ///
	xlabel(-50(10)50) ///
    msymbol(dot) ///
    msize(small) ///
    mcolor(navy) ///
    lcolor(navy) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    scheme(s2mono)

	/*-----drop resid--------*/
	drop resid
	
/**********************************************************************
KLARGJØRING AV ENDELIG ANALYSEDATASETT

 Gjentar konstruksjonen av sentrale analysevariabler med
 utgangspunkt i det den eksplorative analysen.

 Variablene winsoriseres og transformeres i samsvar med
 spesifikasjonene som benyttes i hovedanalysene.

 Datasettet lagres som et eget analysegrunnlag for å sikre
 at de videre regresjonsanalysene benytter et konsistent
 og bearbeidet datamateriale.
**********************************************************************/
		  

  use "$prosjekt/kjor_m_beta_nav_risk.dta", clear

/*--------drop ppubliv_property_invest_asa------_*/
drop if selskap=="public_property_invest_asa"
/*--- fiks p_nta */
gen nta_mnok= nta/1000000
format nta %15.0fc
gen p_nta= market_cap_mnok / nta_mnok
/*--------log-----------*/
gen ln_p_nta = ln(p_nta) 
gen ln_mv = ln(market_cap_mnok)
gen ln_p_nav = ln(p_nav)
/*------formater------------*/
format markedsverdi %15.0fc
format antall_aksjer %15.0fc
/*-------lag årlig avkastning---------*/
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
* Sorter etter selskap og år
sort selskap ar
* Beregn endring fra året før - delta
by selskap: gen delta_roe = roe - roe[_n-1]
by selskap: gen delta_ebitda = ebitda - ebitda[_n-1]
by selskap: gen delta_kontantstrom = kontantstrom - kontantstrom[_n-1]
by selskap: gen delta_asset_turnover = asset_turnover - asset_turnover[_n-1]
by selskap: gen delta_ltv = ltv - ltv[_n-1]
by selskap: gen delta_ltv_property = ltv_property - ltv_property[_n-1]
by selskap: gen delta_utbytte_yield = utbytte_yield - utbytte_yield[_n-1]
by selskap: gen delta_beta_obx = beta_obx - beta_obx[_n-1]
by selskap: gen delta_net_finance = net_finance - net_finance[_n-1]
by selskap: gen delta_property_value = property_value - property_value[_n-1]
by selskap: gen delta_Sum_eiendeler = Sum_eiendeler - Sum_eiendeler[_n-1]
by selskap: gen delta_equity_ratio = equity_ratio - equity_ratio[_n-1]
by selskap: gen delta_net_debt = net_debt - net_debt[_n-1]
by selskap: gen delta_rental_income = rental_income - rental_income[_n-1]
by selskap: gen delta_debt_rate = debt_rate - debt_rate[_n-1]
 /*------winsoriser-------_*/
winsor2 roe asset_turnover beta_obx ebitda net_finance ltv ltv_property utbytte_yield equity_ratio ebitda net_finance ///
delta_roe delta_ebitda delta_asset_turnover delta_ltv delta_ltv_property delta_utbytte_yield ///
     delta_net_finance ///
    delta_property_value ///
    delta_Sum_eiendeler delta_equity_ratio delta_net_debt delta_ebitda ///
    rental_income debt_rate delta_ebitda delta_ltv_property delta_net_finance, replace cuts(5 95)
/*------log eiendomsverdi og driftsinntekter------*/
gen ln_property = ln(property_value)
gen ln_rental = ln(rental_income + 1)
/*--------asinh på ebitda og netto finansinntekter------_*/
gen ln_ebitda = asinh(ebitda)
gen ln_net_finance = asinh(net_finance)
/*------direkteavkastning i %------*/
  gen utbytte_yield_p=utbytte_yield*100
/*--------lagre analysesett---------*/
  save "$prosjekt/kjor_m_beta_nav_risk_analyser.dta", replace
	
	

	/*----------slutt--------------*/
	