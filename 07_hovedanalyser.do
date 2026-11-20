


		  
/**********************************************************************
 HOVEDANALYSER – REGRESJONSMODELLER

 Estimerer tre hovedmodeller:

 Modell 1: P/NTA
 Undersøker sammenhengen mellom finansielle nøkkeltall og
 selskapenes markedsverdi relativt til EPRA NTA.

 Modell 2: Markedsverdi
 Undersøker sammenhengen mellom finansielle nøkkeltall og
 selskapenes samlede markedsverdi.

 Modell 3: Årlig aksjeavkastning
 Undersøker sammenhengen mellom finansielle prestasjonsmål,
 kapitalstruktur og årlig prosentvis aksjeavkastning.

 Modellene estimeres med pooled OLS og robuste standardfeil.
Årsdummyer inkluderes for å kontrollere for felles
årsspesifikke forhold.

 KMC Properties 2024 utelates fra hovedmodellene som følge
 av tidligere identifiserte innflytelsesrike observasjoner.

 Regresjonsresultatene visualiseres med koeffisientplott
 og tilhørende konfidensintervaller.
**********************************************************************/

use "$prosjekt/kjor_m_beta_nav_risk_analyser.dta", clear
  

  /*-----installer estout, for lagring av reusltat videre til figurer------_*/
ssc install estout, replace
/*----installer coefplot - type figur-----*/
ssc install coefplot, replace
  
* start analyser
* hovedanalyse

	*-----------------P/NTA----------------------------
	eststo p_nta: reg ln_p_nta roe ltv utbytte_yield_p asset_turnover  beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	/*---figur---*/
	coefplot p_nta, ///
    keep(ln_p_nta roe ltv utbytte_yield_p  asset_turnover  beta_obx) ///
    drop(_cons) ///
    xline(0, lpattern(dash)) ///
    msymbol(O) ///
    mcolor(navy) ///
    ciopts(recast(rcap) lcolor(navy)) ///
    coeflabels( ///
        roe = "ROE (desimalform)" ///
        ltv = "Belåningsgrad (desimalform)" ///		
		asset_turnover = "Kapitalens omløpshastighet (desimalform)" ///
		utbytte_yield_p = "Direkteavkastning (%)" ///
        beta_obx = "Beta OBX (desimalform)" /// 
    ) ///
    xlabel(-2(1)4, labsize(small) glcolor(white)) ///
    ylabel(, labsize(small)) ///
    xtitle("Effekt på ln(P/NTA)") ///
    title("Drivere for P/NTA") ///
    note("R²:0,37") ///
    graphregion(color(white) margin(zero))

/*----------------verdsettelse-----------*/
	
eststo mv: reg ln_mv ///.
	  roe ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)
	/*---figur---*/
coefplot mv, ///
    keep(roe ln_property ltv ln_rental beta_obx utbytte_yield_p ln_net_finance) ///
    drop(_cons) ///
    xline(0, lpattern(dash)) ///
    msymbol(O) ///
    mcolor(navy) ///
    ciopts(recast(rcap) lcolor(navy)) ///
    coeflabels( ///
		roe = "ROE (desimalform)" ///
        ltv = "Belåningsgrad (desimalform)" ///
        ln_rental = "Sum driftsinntekter (ln)" ///
		ln_net_finance = "Netto finansinntekter (asinh)" ///
         utbytte_yield_p = "Direkteavkastning (%)" ///
		beta_obx = "Beta OBX (desimalform)" /// 
    ) ///
    xlabel(-9(1)4, labsize(small) glcolor(white)) ///
    ylabel(, labsize(small)) ///
    xtitle("Effekt på ln(markedsverdi)") ///
    title("Drivere for markedsverdi") ///
    note("R{sup:2}: 0,83") ///
    graphregion(color(white) margin(zero))

*--------------------årlig avkastning ----------------------------

	eststo growth: reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx  ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
		/*---figur---*/
	coefplot growth, ///
    keep(ln_ebitda ltv_property ln_net_finance beta_obx) ///
    drop(_cons) ///
    xline(0, lpattern(dash)) ///
    msymbol(O) ///
    mcolor(navy) ///
    ciopts(recast(rcap) lcolor(navy)) ///
    coeflabels( ///
        ln_ebitda = "EBITDA (asinh)" ///
        ltv_property = "Belåningsgrad Eiendom (desimalform)" ///
        ln_net_finance = "Netto finansinntekter (asinh)" ///
        beta_obx = "Beta OBX (desimalform)" ///
    ) ///
    xlabel(-30(10)100, labsize(small) glcolor(white)) ///
    ylabel(, labsize(small)) ///
    xtitle("Effekt på årlig avkastning (%)") ///
    title("Drivere for årlig avkastning") ///
    note("R²: 0,46") ///
    graphregion(color(white) margin(zero))
	
	
	
/**********************************************************************


	KONSTRUKSJON AV FREMTIDIGE UTFALLSMÅL (T+1 TIL T+5)

 Utvider datasettet slik at hver selskapsobservasjon
 representerer flere fremtidige tidshorisonter.

 Det konstrueres fem horisonter, fra ett til fem år frem
 i tid.

 Fremtidig markedsverdi og P/NTA kobles til den aktuelle
 regnskapsobservasjonen ved hjelp av tidsforskyvning.

 Tilsvarende beregnes akkumulert kursendring fra
 utgangspunktet til hvert av de fem fremtidige årene.

 Formålet er å undersøke om regnskapsmessige prestasjonsmål
 har sammenheng med senere verdsettelse og aksjeavkastning,
 og om sammenhengene varierer mellom tidshorisontene.
**********************************************************************/
  use "$prosjekt/kjor_m_beta_nav_risk_analyser.dta", clear

	/*installer */
 //  ssc install require, replace
 //  ssc install reghdfe, replace
 //  ssc install ftools, replace
  
	*stack
	xtset orgnr ar
	expand 5
	bysort orgnr ar: gen horizon = _n
	gen ln_mv_future    = .
	gen ln_p_nta_future = .
	* horizon 1 = allerede t+1
	replace ln_mv_future    = ln_mv if horizon == 1
	replace ln_p_nta_future = ln_p_nta if horizon == 1
	* resten må forskyves
	forvalues h = 2/5 {
		replace ln_mv_future    = F`=`h'-1'.ln_mv if horizon == `h'
		replace ln_p_nta_future = F`=`h'-1'.ln_p_nta if horizon == `h'
	}
	gen ar_future = ar + horizon

	gen growth_future = .
	forvalues h = 1/5 {
		replace growth_future = (F`h'.adj_close - adj_close) / adj_close ///
			if horizon == `h'
	}
	
	gen growth_future_pct=growth_future*100
	
	


/**********************************************************************
INTERAKSJONSMODELL – FREMTIDIG P/NTA

 Estimerer sammenhengen mellom finansielle nøkkeltall
 og fremtidig P/NTA på fem ulike tidshorisonter.

 Interaksjonsledd mellom tidshorisont og kapitalens
 omløpshastighet benyttes for å undersøke om den
 estimerte sammenhengen varierer mellom årene.

 En samlet Wald-test benyttes for å undersøke om
 interaksjonsleddene er statistisk signifikante.

 Marginaleffekter beregnes for hver tidshorisont og
 presenteres grafisk med konfidensintervaller.
**********************************************************************/

	


*----------------------p/nta--------------------------
	*interaction
	reg ln_p_nta_future ///
	c.roe ///
	c.ltv ///
	c.utbytte_yield_p ///
	c.asset_turnover##i.horizon  ///
	c.beta_obx ///
	i.horizon ///
	i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	/*--------wald-test for test interaksjon mellom statistisk driver og horisont-------*/
	testparm 1.horizon#c.asset_turnover 2.horizon#c.asset_turnover 3.horizon#c.asset_turnover 4.horizon#c.asset_turnover 5.horizon#c.asset_turnover
	/*-----marginsplot-------*/
		margins horizon, dydx(asset_turnover)
marginsplot, ///
    xdimension(horizon) ///
    recast(line) ///
    plot1opts(lcolor(navy) lwidth(medthick)) ///
    ci1opts(recast(rcap) lcolor(navy%50)) ///
    yline(0, lpattern(dash) lcolor(black)) ///
    xlabel(1 "t+1" 2 "t+2" 3 "t+3" 4 "t+4" 5 "t+5", labsize(small)) ///
	yscale(range(0 3)) ///
    ylabel(-1(1)4, grid labsize(small) glcolor(gs12%30) glpattern(dash)) ///
	xlabel(, nogrid) ///
	 legend(order(3 "Kapitalens omløpshastighet (desimalform)")) ///
    xtitle("År fra regnskap") ///
    ytitle("P/NTA (ln)") ///
    legend(order(2 "Kapitalens omløpshastighet") ///
           position(1) ring(0) cols(1) ///
           region(lcolor(none))) ///
    title("Verdirelevans av fremtidig P/NTA") ///
	subtitle("Kapitalens omløpshastighet (desimalform)") ///
    graphregion(color(white) lcolor(none)) ///
    plotregion(color(white) lcolor(none)) ///
    xscale(lcolor(black)) ///
    yscale(lcolor(black)) 
	
	
/**********************************************************************
INTERAKSJONSMODELL – FREMTIDIG MARKEDSVERDI

 Undersøker sammenhengen mellom finansielle nøkkeltall
 og fremtidig markedsverdi over en femårsperiode.

 Det inkluderes interaksjonsledd mellom tidshorisont og
 belåningsgrad og driftsinntekter.


**********************************************************************/
	reg ln_mv_future ///
    c.roe ///
    c.ln_property ///
    c.ltv##i.horizon ///
    c.ln_rental##i.horizon ///
    c.ln_net_finance ///
    c.utbytte_yield_p ///
    c.beta_obx ///
    i.horizon ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	/*--------wald-test for test interaksjon mellom statistisk driver og horisont-------*/
	*ltv
	testparm 2.horizon#c.ltv 3.horizon#c.ltv 4.horizon#c.ltv 5.horizon#c.ltv
	*driftsinntekter
	testparm 2.horizon#c.ln_rental 3.horizon#c.ln_rental 4.horizon#c.ln_rental 5.horizon#c.ln_rental
		/*-----marginsplot--lagres og kombineres -----*/
	margins horizon, dydx(ltv)
	marginsplot, ///
    xdimension(horizon) ///
    recast(line) ///
    plot1opts(lcolor(navy) lwidth(medthick)) ///
    ci1opts(recast(rcap) lcolor(navy)) ///
    yline(0, lpattern(dash) lcolor(black)) ///
    xlabel(1 "t+1" 2 "t+2" 3 "t+3" 4 "t+4" 5 "t+5", labsize(small)) ///
    yscale(range(-8 -2)) ///
    ylabel(-10(1)1, grid labsize(small) glcolor(gs12%30) glpattern(dash)) ///
	xlabel(, nogrid) ///
    xtitle("År fra regnskap") ///
    ytitle("Markedsverdi (ln)") ///
    legend(order(3 "Belåningsgrad (desimalform)") ///
           position(1) ring(0) cols(1) ///
           region(lcolor(none))) ///
    title("A: Belåningsgrad (desimalform)") ///
    graphregion(color(white) lcolor(none)) ///
    plotregion(color(white) lcolor(none)) ///
    name(fig1, replace)
	
	/*-----marginsplot--lagres og kombineres -----*/
	margins horizon, dydx(ln_rental)
	marginsplot, ///
    xdimension(horizon) ///
    recast(line) ///
    plot1opts(lcolor(orange) lwidth(medthick)) ///
    ci1opts(recast(rcap) lcolor(orange)) ///
    yline(0, lpattern(dash) lcolor(black)) ///
    xlabel(1 "t+1" 2 "t+2" 3 "t+3" 4 "t+4" 5 "t+5", labsize(small)) ///
    yscale(range(0 0.6)) ///
    ylabel(0(0.1)0.6, grid labsize(small) glcolor(gs12%30) glpattern(dash)) ///
	xlabel(, nogrid) ///
    xtitle("År fra regnskap") ///
    ytitle("Markedsverdi (ln)") ///
    legend(order(2 "Sum driftsinntekter (ln)") ///
           position(1) ring(0) cols(1) ///
           region(lcolor(none))) ///
    title("B: Driftsinntekter (ln)") ///
    graphregion(color(white) lcolor(none)) ///
    plotregion(color(white) lcolor(none)) ///
    name(fig2, replace)
	
	/* kombiner figurer */
	graph combine fig1 fig2, ///
    col(2) ///
	title("Verdirelevans av fremtidig markedsverdi") ///
    graphregion(color(white))
	
	
	

/**********************************************************************
INTERAKSJONSMODELL – FREMTIDIG AKSJEAVKASTNING

 Estimerer sammenhengen mellom finansielle prestasjonsmål
 og fremtidig akkumulert aksjeavkastning.

 Modellen inkluderer interaksjoner mellom tidshorisont
 og EBITDA, belåningsgrad relativt til eiendomsverdier
 og netto finansinntekter.

**********************************************************************/
*interaction
reg growth_future_pct ///
    c.ln_ebitda##i.horizon ///
    c.ltv_property ///
    c.ln_net_finance##i.horizon ///
    beta_obx ///
    i.horizon ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

	/*--------wald-test for test interaksjon mellom statistisk driver og horisont-------*/
	*ebitda
	testparm 2.horizon#c.ln_ebitda 3.horizon#c.ln_ebitda 4.horizon#c.ln_ebitda 5.horizon#c.ln_ebitda
	*netto finansinntekter
	testparm 2.horizon#c.ln_net_finance 3.horizon#c.ln_net_finance 4.horizon#c.ln_net_finance 5.horizon#c.ln_net_finance

		/*-----marginsplot--lagres og kombineres -----*/

	margins horizon, dydx(ln_ebitda ln_net_finance)
	marginsplot, ///
    xdimension(horizon) ///
    recast(line) ///
    plot1opts(lcolor(navy) lwidth(medthick)) ///
    plot2opts(lcolor(orange) lwidth(medthick)) ///
    ci1opts(recast(rcap) lcolor(navy%50)) ///
    ci2opts(recast(rcap) lcolor(orange%50)) ///
    yline(0, lpattern(dash) lcolor(black)) ///
    xlabel(1 "t+1" 2 "t+2" 3 "t+3" 4 "t+4" 5 "t+5", labsize(small)) ///
	yscale(range(0 20)) ///
    ylabel(0(2)14, grid labsize(small) glcolor(gs12%30) glpattern(dash)) ///
    xtitle("År fra regnskap") ///
	title("") ///
    legend(order(3 "EBITDA (asinh)" 4 "Netto finansinntekter (asinh)") ///
           position(1) ring(0) cols(1) ///
           region(lcolor(none))) ///
    ytitle("Avkastning (%)") ///
    graphregion(color(white) lcolor(none)) ///
    plotregion(color(white) lcolor(none)) ///
    xscale(lcolor(black)) ///
    yscale(lcolor(black)) ///
	title("Verdirelevans av fremtidig avkastning") 
	
	
	/*----------slutt-------------*/
