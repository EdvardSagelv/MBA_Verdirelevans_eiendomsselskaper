

/**********************************************************************
 SENSITIVITETSANALYSER – AVGRENSNING AV UTVALGET

 Sensitivitetsanalyser: 
  De tre hovedmodellene estimeres på nytt med samme overordnede modellspesifikasjoner.
 
 1. Selskapene på Euronext Growth og Expand utelates.
 2. paneldataoppsett med tilfeldige selskapseffekter (Random Effects).
 3. bytte ut systematisk risiko-indeks: Beta mot OBX sammenlignes med beta mot OSEBX og OSEBX Real Estate.
 4. Uten spesifikke selskaper
		- SBO
		- OLT
		- KMC
		- BSP
 5. Årlig avkastning:
      - Inklusjon av trefaktormodellen (OBX, SMB og HML)
	  - inklusjon av trefaktormodellen + MOM og LIQ
	  - Delta-verdier 
	  - Delta-verdier + trefaktormodellen
	  - Delta-verdier + trefaktormodellen + MOM og LIQ
***********************************************************************/

/*---------------------------Uten Growth og Expand-----------------------*/


use "$prosjekt/kjor_m_beta_nav_risk_analyser.dta", clear

* de på euronext Growth og Expand-----------------------------
// BSP
// BALT
// PPG


*-----------P/NTA-----------------------------
reg ln_p_nta roe ltv utbytte_yield_p asset_turnover  beta_obx i.ar ///
    if !(selskap=="kmc_properties_asa" & ar==2024) & selskap !="pioneer_property_group_asa" & selskap !="black_sea_property_as" & selskap !="baltic_sea_properties", vce(robust)

*--------------markedsverdi----------------------
 reg ln_mv ///
	  roe ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	  i.ar if !(selskap=="kmc_properties_asa" & ar==2024) & selskap !="pioneer_property_group_asa" & selskap !="black_sea_property_as" & selskap !="baltic_sea_properties", ///
	  vce(robust)

*--------------------growth ----------------------------
reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if !(selskap=="kmc_properties_asa" & ar==2024) & selskap !="pioneer_property_group_asa" & selskap !="black_sea_property_as" & selskap !="baltic_sea_properties", vce(robust)


/**********************************************************************
 PANELDATA - RANDOM EFFECTS

 Estimerer alternative paneldatamodeller med tilfeldige
 selskapseffekter (Random Effects).

 Datasettet defineres som paneldata med selskap som
 panelidentifikator og år som tidsvariabel.

 Standardfeilene klustreres på selskapsnivå.

**********************************************************************/

/*-----sett orgnr og ar------*/
xtset orgnr ar
*----------P/NTA--------------------

xtreg ln_p_nta roe ltv utbytte_yield_p asset_turnover  beta_obx i.ar ///
    if !(selskap=="kmc_properties_asa" & ar==2024), re cluster(orgnr)

*----------markedsverdi------------------
	  xtreg ln_mv ///
	  roe ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	 if !(selskap=="kmc_properties_asa" & ar==2024), re cluster(orgnr)

*------------growth--------------------
xtreg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    if !(selskap=="kmc_properties_asa" & ar==2024), re cluster(orgnr)


/**********************************************************************
       ALTERNATIVE BETAMÅL

 Beta mot OBX sammenlignes med beta mot OSEBX og
 OSEBX Real Estate.

**********************************************************************/

	*----------P/NTA--------------------
	*OBX
	reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	*OSEBX
	reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_osebx i.ar  if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	*OSEBX RE GR
	reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_osebx_re i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

	*---------markedsverdi-------------------
	*OBX
	 reg ln_mv roe ltv ln_rental ln_net_finance utbytte_yield_p beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	*OSEBX
	 reg ln_mv roe ltv ln_rental ln_net_finance utbytte_yield_p beta_osebx i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	*OSEBX RE GR
	 reg ln_mv roe ltv ln_rental ln_net_finance utbytte_yield_p beta_osebx_re i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

	*--------------------growth ----------------------------
	*OBX
	reg growth_pct_m  ln_ebitda ltv_property ln_net_finance beta_obx i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	*OSEBX
	reg growth_pct_m  ln_ebitda ltv_property ln_net_finance beta_osebx i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	*OSEBX RE GR
	reg growth_pct_m  ln_ebitda ltv_property ln_net_finance beta_osebx_re i.ar if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
  
/**********************************************************************
 UTEN SBO

 Gjennomfører hovedanalysene uten Selvaag Bolig.

**********************************************************************/

*--------------P/NTA-----------------------
reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_obx i.ar ///
    if  selskap !="selvaag_bolig_asa" & !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

*------------- markedsverdi-------------------
 reg ln_mv ///
	  roe ///
      ln_property ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	  i.ar if selskap !="selvaag_bolig_asa" & !(selskap=="kmc_properties_asa" & ar==2024) , ///
	  vce(robust)

*--------------------growth ----------------------------
reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if selskap !="selvaag_bolig_asa" & !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

/**********************************************************************
 UTEN OLT

 Gjennomfører hovedanalysene uten Olav Thon
 Eiendomsselskap.

**********************************************************************/
  

*--------------P/NTA-----------------------
reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_obx  i.ar ///
    if  selskap !="olav_thon_eiendomsselskap_asa" & !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

*------------- markedsverdi-------------------
 reg ln_mv ///
	  roe ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	  i.ar if selskap !="olav_thon_eiendomsselskap_asa" & !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)

*--------------------growth ----------------------------
reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if selskap !="olav_thon_eiendomsselskap_asa" & !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

/**********************************************************************
 UTEN KMC 

 Gjennomfører hovedanalysene uten KMC Properties.

**********************************************************************/
  
*--------------P/NTA-----------------------
reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_obx i.ar ///
    if  selskap !="kmc_properties_asa", vce(robust)

*------------- markedsverdi-------------------
 reg ln_mv ///
	  roe ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	  i.ar if selskap !="kmc_properties_asa" , ///
	  vce(robust)

*--------------------growth ----------------------------
reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx  ///
    i.ar ///
	if selskap !="kmc_properties_asa" , vce(robust)

/**********************************************************************
 UTEN BSP

 Gjennomfører hovedanalysene uten Black Sea Property.

**********************************************************************/
  
*--------------P/NTA-----------------------
reg ln_p_nta roe ltv utbytte_yield_p asset_turnover beta_obx i.ar ///
    if  selskap !="black_sea_property_as" & !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

*------------- markedsverdi-------------------
 reg ln_mv ///
	  roe ///
      ltv ///
      ln_rental ///
	  ln_net_finance ///
      utbytte_yield_p ///
	  beta_obx ///
	  i.ar if selskap !="black_sea_property_as" & !(selskap=="kmc_properties_asa" & ar==2024), ///
	  vce(robust)

*--------------------growth ----------------------------
reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_obx ///
    i.ar if selskap !="black_sea_property_as" & !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

	
 
/**********************************************************************

 UTVIDELSE MED MARKEDSFAKTORER
 Årlig avkastning:
      - Inklusjon av trefaktormodellen (OBX, SMB og HML)
	  - inklusjon av trefaktormodellen + MOM og LIQ
	  - Delta-verdier 
	  - Delta-verdier + trefaktormodellen
	  - Delta-verdier + trefaktormodellen + MOM og LIQ

 Utvider avkastningsmodellen med markedsbaserte
 risikofaktorer fra TITLON.

**********************************************************************/
  
  * Inkludert trefaktormodellen 
	reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_mkt_3 ///
    beta_smb_3 ///
    beta_hml_3 ///
	i.ar ///
    if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	
	** Inkludert trefaktormodellen + MOM og LIQ
	reg growth_pct_m ///
    ln_ebitda ///
    ltv_property ///
    ln_net_finance ///
    beta_mkt_5 ///
    beta_smb_5 ///
    beta_hml_5 ///
	beta_mom_5 ///
	beta_liq_5 ///
	i.ar ///
    if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	
/**********************************************************************
ENDRINGSVARIABLER (delta) OG MARKEDSFAKTORER

	  - Delta-verdier 
	  - Delta-verdier + trefaktormodellen
	  - Delta-verdier + trefaktormodellen + MOM og LIQ
	  
**********************************************************************/

  *------ delta------------
	reg growth_pct_m ///
    delta_ebitda ///
    delta_ltv_property ///
    delta_net_finance ///
    beta_obx ///
	i.ar ///
     if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)

   *------ delta + trefaktor-----------
	reg growth_pct_m ///
    delta_ebitda ///
    delta_ltv_property ///
    delta_net_finance ///
    beta_mkt_3 ///
    beta_smb_3 ///
    beta_hml_3 ///
	i.ar ///
    if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	
   *------ delta + trefaktor + MOM + LIQ-----------
	reg growth_pct_m ///
    delta_ebitda ///
    delta_ltv_property ///
    delta_net_finance ///
    beta_mkt_5 ///
    beta_smb_5 ///
    beta_hml_5 ///
	beta_mom_5 ///
	beta_liq_5 ///
	i.ar ///
    if !(selskap=="kmc_properties_asa" & ar==2024), vce(robust)
	
	*-----------slutt---------------------
