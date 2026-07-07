
## Case Study @HolidayCheck: Business Analyst - Media

#### **Hintergrund**: 
HolidayCheck Media verkauft Werbeprodukte an Hotels und Destinationen. Ein Hotelpartner hat sich beim Media Sales Teams gemeldet: "Wir investieren seit mehreren Monaten in Sponsored Placements und Display Advertising. Trotz steigender Investitionen sehen wir keine entsprechende Entwicklung bei Leads und Buchungen." Der Kunde bittet um eine Analyse und Handlungsempfehlung. 

- **Hotel Impressions**:    Anzeigehäufigkeit eines Hotelangebots
- **Clicks**:               Häufigkeit wie oft Nutzer auf ein Hotelangebot geklickt haben
- **Leads**:                Nutzerinteraktion NACH dem Click, z.B. Weiterleitung zum Anbieter, Buchungsanfrage,Kontaktformular oder begonnene Buchung
- **Cost**:                 Kosten der Kampagne oder des Traffics
- **CTR** (click through rate): Anteil der Impressions, die zu Clicks geführt haben
- **CPC** (cost per click):     Kosten pro Click
- **Conversion Rate**:          Anteil der Leads, die zu Buchungen geführt haben / Mögliche Conversion Rate auch: Anteil Clicks, die zu Leads geführt haben -> hier lead rate

#### **Teil 1 – SQL & Datenanalyse**

**Aufgabe 1:** 

*Berechne monatlich pro Hotel Impressions, Clicks, Leads, Cost, CTR, CPC und Conversion Rate.*
- CTR = clicks / impressions
- CPC = cost / clicks
- conversion rate = bookings / leads

**Aufgabe 2 & Aufgabe 8:**    

*Identifiziere Hotels mit steigenden Kosten und sinkenden Leads über mindestens drei Monate. Zeige die Top 10 auffälligsten Hotels.*

- 02a_rising_sinking_consec: strenge Definition: Kosten Monat 1 < Kosten Monat 2 < Kosten Monat 3 & Leads Monat 1 > Leads Monat 2 > Leads Monat 3 ergeben nur einen Treffer
- 02b_rising_sinking: lockere Definition: Kosten Monat 1 < Kosten Monat 3 & Leads Monat 1 > Leads Monat 3, für Monat 2 können Kosten und Leads steigen oder sinken

    - ano_score = prozentualer Kostenanstieg + prozentualer Leadrückgang
    - je höher, desto kritischer
    ->  Hotel 12: Zwischen Juli und September 2025 steigen die Kosten um 63,56 %, während die Leads um 55,13 % sinken

*Entwickle mindestens fünf Hypothesen für sinkende Leads bei steigenden Kosten.*

- Hypothesen für steigende Kosten bei sinkenen Leads:
    1. Die Anzeigen werden teurer, aber nicht relevanter: CPC steigt, CTR oder Lead Rate sinken.
    2. Die Zielgruppe passt nicht mehr gut zum beworbenen Hotel oder Angebot.
    3. Saisonale Effekte: Nachfrage kann je nach Monat, Region oder Reisezeitraum schwanken.
    4. Landingpage-Problem: Nutzer klicken, brechen aber vor der Anfrage oder Buchung ab.
    5. Kampagnen-Mix hat sich verändert: Mehr Budget fließt in weniger effiziente Kampagnentypen.
    6. Wettbewerb ist stärker geworden und erhöht die Werbekosten.
    7. Preis, Verfügbarkeit oder Bewertungen des Hotels sind weniger attraktiv geworden.

**Aufgabe 3:** 

*Berechne einen 3-Monats-Moving-Average für Leads und Revenue und identifiziere Trends.*

- 3-Monats-Moving Average: Durchschnitt aus aktuellem Monat, letztem Monat und vorletztem Monat 

    -> dynamischer Durchschnitt, glättet kurzfristige Veränderungen und zeigt stabilere Trends

- 03a_moving_average_trends: berechnet den 3-Monats-Moving-Average für jedes Hotel; für Januar und Februar 2024 sind keine Trends identifizierbar, da nicht ausreichend Daten vorliegen

    **Trends:**
    - increase: Anstieg in Leads UND Umsatz
    - decrease: Rückgang in Leads UND Umsatz
    - leads increase, revenue decrease
    - leads decrease, revenue increase
    - stable/mixed: Leads UND Umsatz stabil ODER nur eins davon stabil

    
- 03b_moving_average_top_trends: 
    
    gibt die Rekorde der 3-Monats-Moving-Average der jeweiligen Trends heraus.

    Der längste Anstieg hielt 7 Monate bei Hotel 17 an, der längste Rückgang hielt bei Hotel 1 über 6 Monate an. 


| hotel_id	| country |	trend	| period_length (months) |
| :---: | :---: | :---: | :---: |
| 1	| Spain | decreasing | 6 |	
| 17 | Tunisia | increasing| 7 |	
| 20| Cyprus | stable/mixed	| 21 | 
| 10 |	Spain |	leads increase, revenue decrease | 2 |
| 19 |	Bulgaria | leads increase, revenue decrease | 2 |
| 2	| Greece | leads increase, revenue decrease | 2 |
| 3	| Turkey | leads decrease, revenue increase | 3 |
| 4	| Egypt | leads decrease, revenue increase | 3 |



**Aufgabe 4:** 

*Segmentiere Hotels nach Performance anhand von Revenue, Leads und Conversion Rate. Bilde mindestens vier Segmente.*

- Teilung von leads, revenue und conversion rate in Quartile; mit conversion rate = bookings/leads
- Scoring: 1 = schwächstes Viertel, 4 = stärkstes Viertel
- performance_score = leads_score + revenue_score + conversion_rate_score 

- Segmente: 
    1. Top Performer = Umsatzstark + Leads UND Konversionsrate überdurchschnittlich
    2. High Performer = Umsatzstark + Leads ODER Konversionsrate überdurchschnittlich
    3. Potential/Optimize = Mittelfeld in Umsatz, Leads, Konversionsrate 
    4. Weak Performer = Umsatzschwach + Leads UND Konversionsrate unterdurchschnittlich


| Segment Kategorie | Total | pro Jahr (2024) | pro Jahr (2025) |
| :---: | :---: | :---: | :---: |
| Top Performer | 1 | 1 | 3 |
| Hight Performer | 9 | 9 | 7 |
| Potential / Optimize | 6 | 6 | 6 |
| Weak Performer | 3 | 3 | 3 | 
| Gap | 1 | 1 | 1 |


#### **Teil 2 – Python & Advanced Analytics**

**Aufgabe 5:**

*Visualisiere Leads, Revenue und Cost über die Zeit.*

![timeseriesmonthly](/outputs/figures/monthly_time_series.png)

![timeseriesweekly](/outputs/figures/weekly_time_series.png)

- Leads und Cost bewegen sich saisonal ähnlich: Peaks im Sommer, niedrigere Werte in Winter-/Übergangsmonaten
- Revenue erreicht starke Werte im Sommer 2025, besonders Juli 2025 

**Aufgabe 6:**

*Führe eine Anomalie-Erkennung durch und beschreibe mögliche Ursachen.*

Anomalie/Outlier = auffälliger Wert, der stark vom normalen Verhalten abweicht

-  **z-score** = (aktueller Wert - Durschnitt) / Standardabweichung
    - 0: Wert ist normal
    - 1: Wert liegt eine Standardabweichung über dem Durchschnitt
    - -2: Wert ist deutlich niedriger als normal
    - 2: Wert ist sehr viel höher als normal

- **Poor ROAS**: Verhältnis zwischen Werbeausgaben und daraus resultierndem Buchungsumsatz ist schlecht. Unrentable Kamapgne
- **high CPC**: durch stärkeren Wettbewerb: Mehr Bieter im Wettbewerbsumfeld erhöhen Klickpreise
- **low CTR**: Ad / Creative Fatigue: Nutzer sehen ähnliche Anzeigen zu häufig, Klicks werden ineffizienter
- **low lr**: Landingpage-Probleme: Klicks kommen an, aber Klicks konvertieren nicht zu Leads
- **high CPL**: Ein Lead/gewonnener Interessent (z.B. eine Anfrage oder Zimmer-Auswahl) kostet plötzlich viel mehr Geld
- **AOV drop**: Problem vermutlich bei Kundenverhalten oder Preisstrategie des Hotels. Anzahl der Buchungen kann stabil sein, aber die Gäste buchen plötzlich deutlich 
            günstigere Zimmer, nutzen Rabatte oder verkürzen ihren Aufenthalt dramatisch


**Augabe 7:**

*Ermittle die Top 5 Hotels mit der höchsten Volatilität bei Leads und beschreibe, wie du diese Kunden betreuen würdest.*

| Rang | Hotel ID | Land | Region | Jahr |
| :---: | :---: | :---: | :---: | :---: |
| 1 | 18 | Spanien | Ibiza | 2024 | 
| 2 | 1 | Spanien | Mallorca | 2024 | 
| 3 | 12 | Ägypten | Marsa Alam | 2024 | 
| 4 | 4 | Ägypten | Hurghada | 2024 | 
| 5 | 15 | Österreich | Tirol | 2024 | 
| | | | | | 
| 1 | 18 | Spanien | Ibiza | 2025 | 
| 2 | 1 | Spanien | Mallorca | 2025 
| 3 | 12 | Ägypten | Marsa Alam | 2025 |
| 4 | 4 | Ägypten | Hurghada | 2025 |
| 5 | 15 | Österreich | Tirol | 2025 |

- Volatilität = Schwankung, z.B. Hotel mit hoher Volatilität in Leads = Hotel mit unstabilen Leads: in manchen Monaten sehr viele, in anderen sehr wenige. 

- Probleme bei Volatilität: 
    - Budgetplanung unsicher
    - Forecasts eher schwierig
    - Kampagnenüberwachung nötig
    - Enge Kundenbetreuung nötig 

- Erkennung möglich durch Coefficient of Variance CV = Standardabweichung / Durchschnitt

- Warum nicht nur Standardabweichung: Großes Hotel hat automatisch höhere absolute Schwankungen, CV setzt Schwankung ins Verhältnis zum Durchschnitt und macht dadurch Hotels vergleichbarer

- *Empfehlung für Hotels:* 
    - Budget ggfs. für Saisonale-Peaks reservieren und anpassen, allerdings sollten Peaks überprüft werden, da es regionale Unterschiede gibt wann Hochsaison ist
    - Kampagnenlogik aufbauen basierend auf Saisonalität

- Hotel 18: Saisonale Schwankungen, sowohl 2024 als auch 2025, Peak im Sommer und im Winter am niedrigsten
- Hotel 1: siehe Hotel 18
- Hotel 12: Niedrigster Wert im August 2025, aber höchster Wert im Juli 2025. Lead-Qualität prüfen, war es ein echter Kampagne-Peak / gab es gleichzeitig einen Umsatz-Peak?
    Vergleich mit Vorjahr: Niedrigster Wert auch im Sommer, Peak allerdings im Winter. Möglicherweise ein Tracking-Fehler. Auf jeden Fall Umsatz und Saison sowie Marktnachfrage für Region prüfen
- Hotel 4: Niedrigster Wert im Sommer und höchster Wert im Winter für beide Jahre. Saison sowie Marktnachfrage für Region prüfen
- Hotel 15: Als Winterurlaubsziel nicht unüblich mit niedrigem Wert im Sommer und Peak im Winter, Kampagnen und Budget an Saisonalität anpassen

#### **Teil 3 – Business Analyst Media**

**Aufgabe 8: siehe oben bei Aufgabe 2**

**Aufgabe 9:** 

*Welche zusätzlichen Daten würdest du anfordern? Priorisiere nach Must Have und Nice to Have.*

**Must Have**
| Priorität | Daten | Warum wichtig? |
|---:|---|---|
| 1 | Budget je Kampagne, Gebotsstrategie, Tagesbudget | Um zu verstehen, ob Kostenanstieg durch Budget-/Bid-Änderungen verursacht wurde. |
| 2 | Channel / Plattform / Placement | Um ineffiziente Kanäle zu identifizieren. |
| 3 | Impression Share, Auction Insights, Wettbewerbsdaten | Um Auktionsdruck und Marktveränderungen zu erklären. |
| 4 | Landingpage Sessions, Bounce Rate, Ladezeit, Formularabbrüche | Um Lead-Verluste nach dem Klick zu erklären. |
| 5 | Tracking-Events und Consent-Daten | Um Messprobleme auszuschließen. |
| 6 | Hotelpreise, Verfügbarkeit, Angebotsdetails | Um Nachfrage- und Angebotsprobleme zu prüfen. |
| 7 | Kampagnenänderungen mit Datum | Um Anomalien konkreten Änderungen zuzuordnen. |

**Nice to Have**

| Daten | Nutzen |
|---|---|
| Wetter, Ferien, Feiertage, lokale Events | Erklärung saisonaler oder regionaler Schwankungen. |
| Wettbewerberpreise | Bewertung der relativen Attraktivität des Hotelangebots. |
| Creative-Versionen und Frequenz | Identifikation von Creative Fatigue. |
| Device, Geo, Audience, Demografie | Genauere Optimierung nach Segmenten. |
| Stornoquote und finale Buchungsqualität | Leads können hoch sein, aber wirtschaftlich schlecht. |
| Customer Lifetime Value | Bessere Budgetentscheidung als nur kurzfristiger ROAS. |


**Aufgabe 10:** 

*Formuliere eine Executive Summary und konkrete Handlungsempfehlungen.*

| KPI | 2025 vs. 2024 |
| :-: | :-: |
| Kosten | +2,06 % |
| Leads | -0,96 % |
| Bookings | +11,67 % |
| Revenue | +11,26 % |
| ROAS | +9,01 % |
| Bookings pro Lead | +12,75 | 

Der analysierte Datensatz umfasst Kampagnen-, Buchungs- und Hotelinformationen für 20 Hotel über einen Zeitraum von 24 Monaten von Januar 2024 bis Dezember 2025. 
Die Datenqualität des Datensatzes ist gut, es gibt kaum fehlende Datenpunkte, keine doppelten Buchungs_IDs und keine Plausibilitätsfehler. Ausschließlich bei Hotel 20
gibt es eine Datenanomalie. Buchungsinformationen wie Buchungs_IDs und Umsätze sind zu finden, aber keine Kampagnendaten wie Leads, Kampagnenkosten oder Kampagnentyp.

Auf aggregierter Ebene ist die Gesamtperformance positiv. Von 2024 auf 2025 steigen Bookings und Revenue deutlich, während die Kosten moderat ansteigen. Ein leichter Rückgang bei den Leads ist zu vernehmen, der sich aber nicht beim Umsatz bemerkbar gemacht hat. 
Bei einzelnen Kunden gibt es problematische Zeiträume bei denen die Leads auffällig sinken bei gleichzeitig steigenden Kosten (Hotel 12 Marsa Alam, Hotel 3 Antalya, 
Hotel 1 Mallorca, Hotel 18 Ibiza). Sowohl im Jahr 2024 als auch im Jahr 2025 bleiben dieselben Hotels (Hotel 18 Ibiza, Hotel 1 Mallorca, Hotel 12 Marsa Alam, Hotel 4 Hurghada, 
Hotel 15 Tyrol) an der Spitze der am volatilsten Kunden. Diese Kunden benötigen eine engere Betreuung, genaueres Monitoring der Zahlen und ggfs. Anpassungen der Budgetausgaben an die Saisonalität.


**Aufgabe 11:** 

*Soll der Kunde sein Werbebudget erhöhen? Beschreibe fehlende Informationen, relevante KPIs und deine Empfehlung.* 

**Annahme:** Bei Aufgabe 2 hatte nur das Hotel 18 Ibiza an drei aufeinanderfolgenden Monaten sowohl sinkende Leads bei gleichzeitig steigenden Kosten. 
Daher nutze ich Hotel 18 als Grundlage für meine Antwort bei dieser Aufgabe.

**Hotel 18 Ibiza Spain**

| KPI | 2025 vs. 2024 |
| :-: | :-: |
| Kosten | +8,76 % |
| Leads | -14,03 % |
| CPL | +26,51 % |
| Buchungen | +10,67 % |
| Umsatz | +10,7 % |
| ROAS | +1,78 % |
| Bookings/Lead | +28,73 % |

Einerseits sind Buchungen und Umsätze von 2024 auf 2025 gestiegen. Andererseits ist die Lead-Generierung deutlich ineffizienter geworden und die Kosten dafür gestiegen. 
Das beduetet, dass das Problem nicht direkt an der Umsatz-Generierung liegt, sondern vor allem im oberen Bereich des Trichters an der Werbekampagne bzw. an den Klicks und Leads, die ineffizienter geworden sind.

Wie aus Aufgabe 2 zu entnehmen ist die auffälligste Periode von Juni 2025 zu August 2025. Hier haben wir einen Anstieg von +14,8 % bei den Kosten und einen Rückgang von -37,43 %. 
Dem genauerem Vergleich der KPIs von Juni zu August 2025 kann man entnehmen, dass die Kosten pro Lead drastisch um 83,5 % gestiegen sind. 

Relevante KPIs
| KPI | Warum wichtig? |
| :-: | :-: |
| Kosten | Zeigt, ob der Kunde tatsächlich mehr investiert |
| Leads | Zentrale Zielgröße des Kunden |
| CPL | Wichtigster Effizienz-KPI für Lead-Kampagnen |
| Klicks | Prüft, ob das Problem bereits beim Traffic entsteht |
| CPC | Zeigt, ob Media-Einkauf teurer wird |
| Lead Rate | Zeigt, ob Klicks schlechter in Leads konvertieren |
| Buchungen | Prüft, ob Leads auch zu Geschäft führen |
| Konversionsrate Bookings/Lead | Bewertet Lead-Qualität |
| Umsatz | Zeigt Business Impact |
| ROAS | Bewertet Umsatz je Werbe-Euro |
| AOV Umsatz/Buchung | Zeigt, ob hochwertige Buchungen entstehen |


|Fehlende Information | Warum wichtig? |
| :-: | :-: |
| Marge / Profitabilität: | Umsatz alleine reicht nicht aus, um Profitabilität anzuzeigen |
| Landingpage Daten | Nutzer-Absprungrate, Ladezeiten, Formularabbrüche können sinkende Leads erklären | 
| weitere Hotelinformationen | Verfügbarkeit und Preisgestaltung der Hotels können trotz gutem Traffic zu sinkenden Leads führen |
| Wettbewerbsdaten | Könnte Kostenanstieg und geringere Sichtbarkeit erklären |
| Wetter / Events / Ferienzeiten | Können saisonale Effekte erklären |
| Stornierungen | Bei steigenden Buchungen gleicher oder sinkender Umsatz |

**Empfehlung:**
Das Werbebudget zunächst nicht erhöhen, da der Umsatz und die Buchungen gestiegen sind. Zuerst weitere KPIs heranziehen, um die sinkenden Leads zu erklären. 
Die Werbekampagne optimieren und in Hinsicht auf Kampagnetypen analysieren, z.B. welcher Typ generiert mehr Klicks und Leads und ggfs. das Budget auf bessere Placements umschichten. 
Wenn die fehlenden Informationen keinen Aufschluss darüber geben, kann das Budget für eine Testperiode unter kontrollierten Bedingungen und nur für zunächst einen bestimmten Zeitraum erhöht werden

#### **Teil 4 - Chatbot**

Dieser Chatbot ist regelbasiert aufgebaut und generiert kein beliebiges SQL, sondern ordnet bestimmte Nutzerfragen sicheren und vorbereiteten SQL-Abfragen zu. 

Der Bot soll ein erster Einstieg und ein Bespiel dafür darstellen, wie der Zugriff auf Daten und Ergebnisse schnell(er) erzeugt werden könnte. 

Momentan arbeitet er auf einer sehr spezifischen Frage-Antwort Basis und nutzt keine externe LLM-API.
Die Eingabe muss demnach sehr nah an den Beispielen liegen, wenn sie für den Bot zu unspezifisch ist, fragt er nach einer eindeutigeren Frage mit der Hilfe von Beispielen.

Die Voraussetzungen für den Chatbot sind:

1) die durch load.py erzeugte DuckDB-Datei liegt vor
2) die requirements.txt wurde installiert

Zum Starten des Chatbots: streamlit run chatbot_streamlit.py
Zum Beenden des Chatbots: ctrl+c







