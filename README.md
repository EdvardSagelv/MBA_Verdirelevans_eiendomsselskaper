# Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper
Dette er analyser, koder og datafiler for resultatene i masteroppgaven "Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper" av Edvard Hamnvik Sagelv og Sigurd Sogn Tjernes 


## Formål

Dette repositoriet inneholder Stata-koden som er benyttet i masteroppgaven for Erfaringsbasert master i økonomi og strategisk ledelse, Master of Buisness Administration (MBA) ved UiT Norges Arktiske Universitet: *«Regnskapsmessig verdirelevans for verdsettelse av norske børsnoterte eiendomsselskaper»*, levert desember 2026. Formålet med studien i denne oppgaven var å undersøke sammenhengen mellom regnskapsbaserte finansielle nøkkeltall og markedsbaserte verdsettelsesmål for norske børsnoterte eiendomsselskaper.

Analysen er basert på et observasjonelt paneldatasett med selskaps- og årsobservasjoner. Regnskapsdata kobles sammen med aksjekurser, markedsverdier, EPRA-baserte verdsettelsesmål og markedsbaserte risikofaktorer. Databehandlingen og de statistiske analysene er gjennomført i Stata.

## Datagrunnlag

Koden benytter følgende hovedkilder:

- **Årsregnskaper:** Regnskapsopplysninger fra selskapenes årsregnskaper registrert i Brønnøysundregisteret, publisert på proff.no.
- **Kursdata:** Historiske aksjekurser og markedsverdier for de aktuelle selskapene per år. Disse er hentet fra Titlon.
- - **TITLON:** Markedsbaserte risikofaktorer: SMB, HML, MOM og LIQ.
- **Markedsindekser:** OSEBX, OSEBX Real Estate og OBX, benyttet til beregning av markedsbeta, data er hentet som ukesdata i Investing.com.
- **EPRA-data:** EPRA NAV/NTA og tilsvarende verdsettelsesmål fra selskapenes rapportering, hentet fra årsregnskaper, eller beregnet selv som beskrevet i oppgaven, sjekk munin.uit.no når publisert.

Datagrunnlaget dekker perioden 2009–2025. Den endelige regresjonsanalysen omfatter et begrenset antall selskaper og selskapsår, noe som må tas hensyn til ved tolkning av resultatene.

## Tilgang til data
Kursdataene med tilhørende risikofaktorer er brukt under lisens fra TITLON, lenke: `https://titlon.uit.no`. 
TITLON er en database for kursdata til børser, som kan brukes av studenter og ansatte ved norske akademiske institusjoner.
For tilgang, bli student eller ansatt ved en norsk institusjon som har tilgang til TITLON, eller send mail til: titlon@uit.no
For mer informasjon om TITLON, se deres infoside ved UiT: `https://uit.no/forskning/forskningsgrupper/sub?p_document_id=352767&sub_id=417205` 

**Alternativ data:** Det kan brukes alternative kursdata fra investing.com. Disse kursdataene er tilnærmet like som TITLON, men antaes å ha svakere kvalitet og korrekthet. Alternative kursdata kan hentes fra filen `uke_samlet.xlsx`. Disse data har ikke SMB, HML, MOM og LIQ, og må eventuelt konstrueres selv. Se `www.investing.com` for mer informasjon, og omgjør kode for å legge til filen.

## Datasett i dette prosjektet
 - **kursdata.xlsx**: kursdata, hentet manuelt fra TITLON dagskurser, som sluttkurs per år.
MERK 1: disse data er brukt under lisens, og er ikke tilgjengelig i dette git-repositoriet. Filen er blank foruten om kolonnenavn. Alternative kursdata kan hentes fra investing.com, se filen `uke_samlet.xlsx`. Disse data har ikke SMB, HML, MOM og LIQ, og må eventuelt konstrueres selv.
MERK 2: antall aksjer for PPG er preferanseaksjer i TITLON. Disse er erstattet med antall utestående aksjer fra årsrapportene.
 - **ar_regnskap.xlsx**: årsregnskap fra selskapene, manuelt kopiert fra `www.proff.no`.
 - **epra_nav_klar.xlsx**: EPRA-baserte tall, hentet fra årsrapportene til selskapene.
 - **uke_samlet.xlsx**: Kursdata, uke-for-uke, lastet ned fra Investing.com. Orgnr er lagt til. 
 - **selskaper_samlet_dagskurser.xlsx**: kursdata, dag-for-dag, hentet fra TITLON. Brukes for å estimere beta for OBX, SMB, HML, MOM og LIQ i trefaktormodellen + utvidet modell.
MERK: disse dataene er brukt under lisens, og er ikke tilgjengelig i dette git-repositoriet. Filen er ikke lastet opp. 

## Mappestruktur

```text
Masteroppgave/
│
├── Data/
│   ├── kursdata.xlsx
│   ├── ar_regnskap.xlsx
│   ├── epra_nav_klar.xlsx
│   └── uke_samlet.xlsx
│
└──  Stata/
    ├── 00_main.do
    ├── 01_årlig_kurs_regnskapsdata.do
    ├── 02_generer_beta.do
    ├── 03_kobling_kurs_regnskap_beta.do
    ├── 04_feature_engineering_titlon_risikofaktorer.do
    ├── 05_eksplorativ_dataanalyse.do
    ├── 06_deskriptiv_statistikk.do
    ├── 07_hovedanalyser.do
    └── 08_sensitivitetsanalyser.do

```

## Kodeoversikt

Do-filen er organisert i følgende hoveddeler:

### 00_main
Laster pakker og kjører utils-filer

### utils
#### 01_årlig_kurs_regnskapsdata

Kursdata og regnskapsdata importeres og klargjøres hver for seg. Selskapsidentifikatorer og årstall standardiseres for å muliggjøre sammenkobling av datakildene.

Regnskapsvariablene omregnes til millioner kroner. Deretter beregnes finansielle prestasjonsindikatorer. 

#### 02_generer_beta
Ukentlige aksjekurser kobles sammen med relevante markedsindekser. Deretter beregnes årlig beta for hvert selskap ved hjelp av regresjoner av aksjenes logaritmiske avkastning mot logaritmisk markedsavkastning. Konstruksjonen av beta uke-for-uke bruker data fra investing.com, da disse har flere år enn TITLON for selskapene på Euronext Growth og Expand. 

Beta beregnes mot tre ulike referanseindekser:

- OSEBX
- OSEBX Real Estate
- OBX

Betaestimatene forskyves ett år frem, slik at beta fra foregående kalenderår kobles til det aktuelle regnskaps- og analyseåret. Dette er gjort for å benytte historisk tilgjengelig markedsinformasjon.

#### 03_kobling_kurs_regnskap_beta

Regnskapsdata kobles sammen med markedsdata, beregnede betaestimater og EPRA-baserte verdsettelsesmål.

På bakgrunn av disse dataene konstrueres blant annet:

- Markedsverdi
- P/NAV
- P/NTA
- Markedsmessig gjeldsdekning
- Utbytteavkastning

Sammenkoblingen skjer på selskaps- og årsnivå. Årsforskyvningen mellom regnskapsinformasjon og beta, og kursdata.

#### 04_feature_engineering_titlon_risikofaktorer

TITLON-data importeres og klargjøres. Selskapsidentifikatorer kobles til de øvrige datasettene, og ukentlige observasjoner aggregeres til årlige faktorer.

Følgende faktorer inngår:

- SMB – størrelse
- HML – verdi
- MOM – momentum
- LIQ – likviditet

Koden konstruerer faktorer fra samme år, som brukes i sensitivitetsanalyser av aksjeavkastning for å forklare avkastning.

#### 05_eksplorativ_dataanalyse

Før analyser kontrolleres datastruktur, manglende verdier, duplikater, korrelasjoner og potensielle uteliggere.

Videre konstrueres:

- Logaritmiske transformasjoner av utvalgte variabler
- Invers hyperbolsk sinus-transformasjoner (asinh) for variabler med null eller negative verdier
- Årlige endringer (delta) i finansielle nøkkeltall
- Årlig aksjeavkastning

Utvalgte variabler winsoriseres for å begrense påvirkningen fra ekstreme observasjoner. Variabeltransformasjoner og winsorisering er tilpasset variablenes egenskaper.

#### 06_deskriptiv_statistikk

Inneholder deskriptiv statistikk, korrelasjonsanalyser og undersøkelser av multikollinearitet. Det lages figurer for å illustrere fordelingen av utvalgte variabler.

#### 07_hovedanalyser

Hovedanalysene undersøker sammenhengen mellom finansielle nøkkeltall og tre sentrale utfallsmål:

1. **P/NTA:** Markedsbasert verdsettelse relativt til netto substansverdi (NTA).
2. **Markedsverdi:** Selskapenes markedsverdi.
3. **Aksjeavkastning:** Årlig aksjeavkastning.

Analysene gjennomføres med pooled OLS-regresjoner, årsdummier og robuste standardfeil. 

Fremtidige verdsettelses- og avkastningsmål med horisonter fra t+1 til t+5. Det gjennomføres også analyser av fremtidige utfall for å undersøke sammenhengen mellom finansielle nøkkeltall og senere verdsettelse og avkastning.

#### 08_sensitivitetsanalyser

Det gjennomføres flere sensitivitetsanalyser for å undersøke hvor robuste hovedresultatene er overfor alternative modellspesifikasjoner og utvalg.

Disse omfatter blant annet:

- Ekskludering av selskaper eller enkeltobservasjoner
- Random Effects-modeller med paneloppsett
- Alternative betaestimater basert på ulike markedsindekser
- Inkludering av markedsbaserte risikofaktorer
- Bruk av årlige endringer i finansielle nøkkeltall

## Gjennomføring

Koden er skrevet som en Stata do-fil og er ment å kjøres i rekkefølge fra begynnelse til slutt. De ulike delene bygger på datasett som produseres i tidligere deler av filen.

Før kjøring må filbanene i import-, save- og merge-kommandoene tilpasses den lokale mappestrukturen. De nødvendige Excel-filene og øvrige datakildene må være tilgjengelige på de angitte plasseringene.

Koden lagrer flere mellomliggende Stata-datasett (`.dta`) underveis. Disse benyttes i senere deler av do-filen og gjør det mulig å kontrollere og gjenbruke bearbeidede data.

README-filen beskriver hovedstrukturen i analyseprosessen. De enkelte stegene, variabelkonstruksjonene og modellspesifikasjonene er nærmere dokumentert gjennom kommentarer i Stata-koden.

## Kontakt
Edvard Hamnvik Sagelv, PhD, mail: edvard.sagelv@gmail.com
Sigurd Sogn Tjernes, BSc, mail: 
