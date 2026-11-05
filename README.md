# Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper
Dette er analyser, koder og datafiler for resultatene i masteroppgaven "Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper" av Edvard Hamnvik Sagelv og Sigurd Sogn Tjernes 


## Formål

Dette repositoriet inneholder Stata-koden som er benyttet i masteroppgaven for MBA ved UiT *«Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper»*, levert desember 2026. Formålet med analysen er å undersøke sammenhengen mellom regnskapsbaserte finansielle nøkkeltall og markedsbaserte verdsettelsesmål for norske børsnoterte eiendomsselskaper.

Analysen er basert på et observasjonelt paneldatasett med selskaps- og årsobservasjoner. Regnskapsdata kobles sammen med aksjekurser, markedsverdier, EPRA-baserte verdsettelsesmål og markedsbaserte risikofaktorer. Databehandlingen og de statistiske analysene er gjennomført i Stata.

## Datagrunnlag

Koden benytter følgende hovedkilder:

- **Årsregnskaper:** Regnskapsopplysninger fra selskapenes årsregnskaper publisert på proff.no.
- **Kursdata:** Historiske aksjekurser og markedsverdier for de aktuelle selskapene per år. Disse er kopiert ut manuelt fra sluttkurser i Titlon. 
- **Markedsindekser:** OSEBX, OSEBX Real Estate og OBX, benyttet til beregning av markedsbeta, data er hentet som ukesdata i Titlon.
- **EPRA-data:** EPRA NAV/NTA og tilsvarende verdsettelsesmål fra selskapenes rapportering, hentet fra årsregnskaper, eller beregnet selv som beskrevet i oppgaven, sjekk munin.uit.no når publisert.
- **Risikofri rente:** Rentedata fra Norges Bank, dette er 10-årig statsobligasjon, hentet fra Norges Bank. De er bare fom 2019, så dataene brukes ikke i prosjektet.
- **TITLON:** Markedsbaserte risikofaktorer, herunder SMB, HML, MOM og LIQ, samt risikofri rente.

Datagrunnlaget dekker i hovedsak perioden 2009–2025. Den endelige regresjonsanalysen omfatter et begrenset antall selskaper og selskapsår, noe som må tas hensyn til ved tolkning av resultatene.

Masteroppgave/
│
├── Data/
│   ├── Kursdata uke for uke/
│   │   └── uke_samlet.xlsx
│   ├── Titlon/
│   │   └── selskaper_samlet_dagskurser.xlsx
│   ├── Bearbeidet/
│   │   └── Alle bearbeidede .dta-filer
│   ├── kursdata.xlsx
│   ├── ar_regnskap.xlsx
│   ├── epra_nav_klar.xlsx
│   └── norges_bank_statsrente.xlsx
│
├── Stata/
│   ├── 00_setup.do
│   ├── Master.do
│   ├── 01_beta_ukentlige_kurser.do
│   ├── 02_regnskap_og_kursdata.do
│   ├── 03_epra_nav.do
│   ├── 04_titlon_faktorer.do
│   ├── 05_analysegrunnlag.do
│   ├── 06_deskriptiv_statistikk_diagnostikk.do
│   ├── 07_hovedanalyser.do
│   ├── 08_fremtidige_horisonter.do
│   ├── 09_sensitivitetsanalyser.do
│   └── 10_kursutvikling_grafer.do
│
└── Resultater/
    ├── Grafer/
    ├── Tabeller/
    └── Logg/



## Kodeoversikt

Do-filen er organisert i følgende hoveddeler:

### 1. Beregning av markedsbeta

Ukentlige aksjekurser kobles sammen med relevante markedsindekser. Deretter beregnes årlig beta for hvert selskap ved hjelp av regresjoner av aksjenes logaritmiske avkastning mot logaritmisk markedsavkastning.

Beta beregnes mot tre ulike referanseindekser:

- OSEBX
- OSEBX Real Estate
- OBX

Betaestimatene forskyves ett år frem, slik at beta fra foregående kalenderår kobles til det aktuelle regnskaps- og analyseåret. Dette er gjort for å benytte historisk tilgjengelig markedsinformasjon.

### 2. Klargjøring av kurs- og regnskapsdata

Kursdata og regnskapsdata importeres og klargjøres hver for seg. Selskapsidentifikatorer og årstall standardiseres for å muliggjøre sammenkobling av datakildene.

Regnskapsvariablene omregnes til millioner kroner. Deretter beregnes finansielle prestasjonsindikatorer innenfor følgende områder:

- Lønnsomhet
- Rentabilitet
- Likviditet og arbeidskapital
- Soliditet og finansiell risiko
- Driftseffektivitet
- Gjeldsgrad og netto finansinntekter

### 3. Sammenkobling av datasett og verdsettelsesmål

Regnskapsdata kobles sammen med markedsdata, beregnede betaestimater og EPRA-baserte verdsettelsesmål.

På bakgrunn av disse dataene konstrueres blant annet:

- Markedsverdi
- P/NAV
- P/NTA
- Markedsmessig gjeldsdekning
- Utbytteavkastning

Sammenkoblingen skjer på selskaps- og årsnivå. Årsforskyvningen mellom regnskapsinformasjon og beta  er en sentral del av datakonstruksjonen.

### 4. Klargjøring av markedsbaserte risikofaktorer

TITLON-data importeres og klargjøres. Selskapsidentifikatorer kobles til de øvrige datasettene, og ukentlige observasjoner aggregeres til årlige faktorer.

Følgende faktorer inngår:

- SMB – størrelse
- HML – verdi
- MOM – momentum
- LIQ – likviditet

I tillegg klargjøres den risikofrie renten. Koden konstruerer faktorer fra samme år, som brukes i alternative analyser av aksjeavkastning for å forklare avkastning.

### 5. Datakontroll og variabelkonstruksjon

Før analyser kontrolleres datastruktur, manglende verdier, duplikater, korrelasjoner og potensielle uteliggere.

Videre konstrueres blant annet:

- Logaritmiske transformasjoner av utvalgte variabler
- Invers hyperbolsk sinus-transformasjoner (asinh) for variabler med null eller negative verdier
- Årlige endringer (delta) i finansielle nøkkeltall
- Årlig aksjeavkastning
- Fremtidige verdsettelses- og avkastningsmål med horisonter fra t+1 til t+5

Utvalgte variabler winsoriseres for å begrense påvirkningen fra ekstreme observasjoner. Variabeltransformasjoner og winsorisering er tilpasset variablenes egenskaper.

### 6. Deskriptiv statistikk og visualisering

Inneholder deskriptiv statistikk, korrelasjonsanalyser og undersøkelser av multikollinearitet. Det lages figurer for å illustrere fordelingen av utvalgte variabler.

### 7. Hovedanalyser

Hovedanalysene undersøker sammenhengen mellom finansielle nøkkeltall og tre sentrale utfallsmål:

1. **P/NTA:** Markedsbasert verdsettelse relativt til EPRA NTA.
2. **Markedsverdi:** Selskapenes markedsverdi.
3. **Aksjeavkastning:** Årlig aksjeavkastning.

Analysene gjennomføres med pooled OLS-regresjoner, årsdummier og robuste standardfeil. Det gjennomføres også analyser av fremtidige utfall for å undersøke sammenhengen mellom finansielle nøkkeltall og senere verdsettelse og avkastning.

### 8. Sensitivitetsanalyser

Det gjennomføres flere sensitivitetsanalyser for å undersøke hvor robuste hovedresultatene er overfor alternative modellspesifikasjoner og utvalg.

Disse omfatter blant annet:

- Ekskludering av selskaper eller enkeltobservasjoner
- Alternative betaestimater basert på ulike markedsindekser
- Random Effects-modeller med paneloppsett
- Inkludering av markedsbaserte risikofaktorer
- Bruk av årlige endringer i finansielle nøkkeltall

## Gjennomføring

Koden er skrevet som en Stata do-fil og er ment å kjøres i rekkefølge fra begynnelse til slutt. De ulike delene bygger på datasett som produseres i tidligere deler av filen.

Før kjøring må filbanene i import-, save- og merge-kommandoene tilpasses den lokale mappestrukturen. De nødvendige Excel-filene og øvrige datakildene må være tilgjengelige på de angitte plasseringene.

Koden lagrer flere mellomliggende Stata-datasett (`.dta`) underveis. Disse benyttes i senere deler av do-filen og gjør det mulig å kontrollere og gjenbruke bearbeidede data.

## Kontakt
Edvard Hamnvik Sagelv, PhD, mail: edvard_sagelv@hotmail.com
Sigurd Sogn Tjernes, BSc, mail: 

README-filen beskriver hovedstrukturen i analyseprosessen. De enkelte stegene, variabelkonstruksjonene og modellspesifikasjonene er nærmere dokumentert gjennom kommentarer i Stata-koden.
