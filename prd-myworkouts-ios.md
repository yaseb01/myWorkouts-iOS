# Product Requirements Document: myWorkouts für iOS

## Produktüberblick
myWorkouts soll als iOS-App neu umgesetzt werden und die Kernidee der bestehenden Android-App übernehmen: Trainings live aufzeichnen, Sensor- und GPS-Daten erfassen, Workouts später analysieren und eine vollständige Historie pflegen.[page:1] Die iOS-Version richtet sich an sportlich aktive Nutzerinnen und Nutzer mit Fokus auf Outdoor-Sport, Herzfrequenz-basiertes Training, GPX-Tracks und Offline-Nutzung.[page:1]

Das Ziel ist keine 1:1-Portierung aller Android-Details im ersten Release, sondern ein stabiles, iOS-konformes Produkt, das die wichtigsten Nutzungsszenarien zuverlässig abdeckt und für spätere Erweiterungen vorbereitet ist.[page:1] Die App muss auf iPhone unter aktuellem iOS laufen; iPad-Unterstützung ist optional, sollte aber durch ein responsives Layout technisch mitgedacht werden.[page:1]

## Produktziele
- Workouts auf iOS live aufzeichnen, inklusive Zeit, Distanz, Kalorien, Höhenmeter und GPS-Track.[page:1]
- Herzfrequenz-Sensoren über iOS-kompatible Schnittstellen integrieren, damit pulsbasierte Trainingssteuerung möglich bleibt.[page:1]
- Eine Trainingshistorie mit Nachbearbeitung, manueller Erfassung und Analyse bereitstellen.[page:1]
- Offline-Karten und GPX-Import/-Export für Outdoor-Sport als zentrales Differenzierungsmerkmal erhalten.[page:1]
- Ziele, Motivation und lokale Datensouveränität in den Mittelpunkt stellen, statt primär auf Social-Features zu setzen.[page:1]

## Nicht-Ziele für Release 1
- Vollständige ANT+-Unterstützung ist für iOS nicht realistisch und daher kein Muss für Release 1, obwohl sie in Android stark genutzt wird.[page:1]
- Eine vollständige Server-Synchronisierung wie in „myWorkouts next“ ist nicht Teil des initialen Releases.[page:1]
- SOS per SMS, Waagen-Support und hochgradig anpassbare Tachometer-Layouts werden als spätere Ausbaustufen behandelt.[page:1]

## Nutzergruppen
| Nutzergruppe | Beschreibung | Hauptbedarf |
|---|---|---|
| Outdoor-Sportler | Läufer, Radfahrer, Wanderer, Skitouren- oder Bergsport-Nutzer mit Bedarf an GPS, Distanz und Höhenmetern.[page:1] | Zuverlässige Aufzeichnung, Offline-Karten, GPX-Export.[page:1] |
| Herzfrequenz-orientierte Trainierende | Personen, die nach Pulszonen trainieren und Trainingsintensität auswerten möchten.[page:1] | Bluetooth-Herzfrequenz, Zonen, Analyse der Belastung.[page:1] |
| Strukturierte Selbst-Tracker | Nutzer mit Fokus auf Historie, Statistik, Ziele und manuellem Nachtragen von Workouts.[page:1] | Logbuch, Ziele, periodische Vergleiche, Datenhoheit.[page:1] |

## Kernprobleme
Die bestehende Android-App kombiniert Live-Tracking, Sensorik, Karten, Historie, Zielsystem und GPX-Funktionen in einer einzigen App.[page:1] Auf iOS muss dieser Mehrwert erhalten bleiben, obwohl sich Plattformfähigkeiten insbesondere bei Sensoranbindung, Hintergrundverhalten und Dateiverwaltung von Android unterscheiden.[page:1]

Die zentrale Produktanforderung lautet daher: iOS-Nutzer sollen dieselben Kernjobs erledigen können wie auf Android, ohne dass die App wie ein technischer Fremdkörper wirkt.[page:1] Das bedeutet: native Navigation, HealthKit-/CoreLocation-/CoreBluetooth-konforme Integration, klare Berechtigungsflüsse und robuste Hintergrundverarbeitung.[page:1]

## Funktionsumfang Release 1

### 1. Home
Der Home-Screen zeigt das letzte Workout oder ein laufendes Workout sowie aggregierte Statistiken über mehrere Zeiträume.[page:1] Die Android-Version vergleicht Zeiträume wie Ziele, letzte 7 Tage, letzte 30 Tage, letztes Jahr und Gesamt sowie Metriken wie Anzahl, Dauer, Distanz, Kalorien und Höhenmeter; dieses Prinzip soll auf iOS übernommen, aber visuell vereinfacht werden.[page:1]

**Anforderungen**
- Letztes Workout mit Datum, Sportart, Dauer und relativer Zeit anzeigen.[page:1]
- Bei laufendem Workout ein kompakter Live-Status auf Home.[page:1]
- Statistik-Karten für definierte Zeiträume mit Umschaltung zwischen Absolut, Pro Woche und Prozentual.[page:1]
- Tap auf Zeitraum oder Metrik öffnet Detailansicht mit Drill-down.[page:1]

### 2. Workout-Aufzeichnung
Die App muss neue Workouts direkt von Home oder aus einer zentralen Aktion starten können.[page:1] Vor Start werden Sportart, Intensitätsbereich, Notiz, GPS-Aufzeichnung und verfügbare Sensoren konfiguriert.[page:1]

**Anforderungen**
- Workout-Setup mit Sportart, Intensität, optionaler Notiz und Sensor-/GPS-Optionen.[page:1]
- Live-Ansicht mit Zeit, Pause/Fortsetzen/Stop, Distanz, Pace oder Geschwindigkeit, Kalorien, Herzfrequenz und Höhenmetern.[page:1]
- Kartenansicht bei aktiver GPS-Aufzeichnung mit aktuellem Track, Auto-Center und Zoom.[page:1]
- Auto-Save in kurzen Intervallen sowie Wiederherstellung nach App-Absturz oder Neustart.[page:1]
- Hintergrundaufzeichnung gemäß iOS-Regeln für Location und Workout-Tracking.[page:1]

### 3. Sensorintegration
Die Android-App unterstützt Bluetooth-LE-Herzfrequenz sowie diverse ANT+-Sensoren wie Kadenz, Temperatur und Footpod.[page:1] Für iOS wird Release 1 auf die realistisch verfügbare Sensorwelt zugeschnitten: Bluetooth Low Energy Herzfrequenz zuerst, weitere Sensoren optional nach Gerätekompatibilität.[page:1]

**Anforderungen**
- Bluetooth-LE-Herzfrequenzsensor koppeln, merken und wiederverbinden.[page:1]
- Herzfrequenz live anzeigen, aufzeichnen und in Zonen auswerten.[page:1]
- Architektur für spätere Erweiterungen auf Kadenz, Speed-Sensoren oder Apple-Watch-Quellen vorsehen.[page:1]
- Sensorstatus, Batteriestatus soweit verfügbar und Diagnoseinformationen anzeigen.[page:1]

### 4. Karten und Orientierung
Die Android-App bietet Offline-Karten, Full-Screen-Karten und GPS-Position auch ohne laufendes Workout.[page:1] Dieses Modul ist für die Positionierung der iOS-App besonders wichtig und soll in einer modernen, einfachen Karten-UX umgesetzt werden.[page:1]

**Anforderungen**
- Kartenansicht im Workout mit Track, aktueller Position und Zoom.[page:1]
- Ad-hoc-Karte ohne laufendes Workout mit aktueller GPS-Position.[page:1]
- Unterstützung für Offline-Karten oder offline verfügbare Kartenausschnitte, sofern technisch und lizenzrechtlich sauber umsetzbar.[page:1]
- GPX-Tracks anzeigen und als Strecke auf Karte visualisieren.[page:1]

### 5. Trainingslogbuch
Das Logbuch ist die chronologische Historie aller Workouts und muss auf iOS eine erstklassige Such-, Filter- und Bearbeitungserfahrung bieten.[page:1] Die Android-Funktionen für manuelles Nachtragen, Bearbeiten und Löschen werden übernommen.[page:1]

**Anforderungen**
- Chronologische Liste aller Workouts mit Kernmetadaten.[page:1]
- Detailansicht pro Workout mit Metriken, Diagrammen und Karte, sofern vorhanden.[page:1]
- Manuelles Erfassen eines Workouts ohne GPS-/Sensordaten.[page:1]
- Bearbeiten von Sportart, Intensität, Notiz, Zeit und Pulsdaten.[page:1]
- Löschen einzelner Workouts mit Sicherheitsabfrage.[page:1]

### 6. Analyse
Die Android-App erlaubt Verlaufsgrafiken für Herzfrequenz, Kadenz, Geschwindigkeit, Temperatur und weitere Werte sowie periodische Vergleiche.[page:1] Release 1 auf iOS fokussiert auf die wichtigsten Analysebausteine, damit das Produkt nutzbar bleibt, ohne die erste Version zu überladen.[page:1]

**Anforderungen**
- Workout-Detail mit Kennzahlen wie Dauer, Durchschnittspuls, Distanz, Kalorien, Höhenmeter.[page:1]
- Diagramme für Herzfrequenz und Geschwindigkeit/Pace; weitere Metriken modular ergänzbar.[page:1]
- Zoombare Charts für den Workout-Verlauf.[page:1]
- Vergleich von Zeiträumen auf aggregierter Ebene.[page:1]
- Export des GPS-Tracks als GPX-Datei mit iOS-Share-Sheet.[page:1]

### 7. Ziele und Motivation
Die Android-App bietet Wochenziele, tägliche Erinnerungen und Prozentwerte zur Zielerreichung.[page:1] Diese Funktionen passen gut zu iOS und sollten im ersten Release enthalten sein, weil sie einen hohen Alltagsnutzen bei vergleichsweise geringer technischer Komplexität liefern.[page:1]

**Anforderungen**
- Ziele für Anzahl Workouts, Gesamtdauer, Kalorien, Distanz und Höhenmeter pro Woche.[page:1]
- Gewichtung oder Priorisierung von Zielgrößen.[page:1]
- Tägliche lokale Erinnerung mit konfigurierbarer Uhrzeit.[page:1]
- Fortschrittsanzeige als Prozentwert und visueller Wochenstatus.[page:1]

### 8. Einstellungen und Stammdaten
Biologische Daten, Trainingsintensitäten, Sportarten und Maßeinheiten gehören zu den Grundlagen der bestehenden Android-App.[page:1] Diese Bereiche sind auf iOS ebenfalls notwendig, damit Kalorienberechnung, Zonen-Logik und Personalisierung funktionieren.[page:1]

**Anforderungen**
- Erfassung von Geschlecht, Geburtsdatum, Gewicht, Größe und optional VO2max.[page:1]
- Definition und Bearbeitung von Trainingsintensitäten/Pulszonen.[page:1]
- Verwaltung beliebiger Sportarten mit Name, Kürzel, Farbe und Favoritenstatus.[page:1]
- Auswahl metrischer oder imperialer Einheiten.[page:1]
- Datenschutz-, Lizenz-, Versions- und Supportseiten.[page:1]

## iOS-spezifische Anforderungen
| Bereich | Anforderung |
|---|---|
| Plattform | Unterstützung für aktuelle iOS-Versionen auf iPhone; UI konsequent in SwiftUI oder UIKit/SwiftUI-Hybrid, aber mit nativer Bedienlogik. |
| Sensorik | CoreBluetooth für BLE-Sensoren; ANT+ wird nicht als Primärziel angenommen, da Android-Features hier nicht direkt übertragbar sind.[page:1] |
| Standort | CoreLocation mit sauberem Berechtigungsdialog für „Beim Verwenden“ und optional Hintergrundnutzung. |
| Health | Optionaler Import/Export ausgewählter Trainingsdaten via HealthKit, sofern Produktstrategie Datensouveränität und Nutzermehrwert nicht verwässert. |
| Benachrichtigungen | Lokale Notifications für Ziele und Motivation.[page:1] |
| Dateien | GPX-Import über iOS-Dateiauswahl/Share Sheet; GPX-Export via Share Sheet.[page:1] |

## Informationsarchitektur
Die App soll fünf Hauptbereiche in einer unteren Tab-Bar besitzen:
1. Home
2. Aufzeichnen
3. Historie
4. Analyse
5. Einstellungen

Diese Struktur übersetzt die Android-Navigation in ein iOS-typisches Modell und macht die wichtigsten Jobs sofort sichtbar.[page:1] Der Aufzeichnen-Tab ist der primäre Einstieg für aktive Nutzung; Home und Historie bedienen Wiederkehr und Rückblick.[page:1]

## User Stories
- Als Läufer möchte ich ein Workout mit GPS und Herzfrequenz starten, damit ich Distanz, Zeit und Belastung zuverlässig erfasse.[page:1]
- Als Radfahrer möchte ich meinen Track auf einer Karte sehen und später als GPX exportieren, damit ich die Tour dokumentieren oder teilen kann.[page:1]
- Als strukturierter Nutzer möchte ich vergangene Workouts durchsuchen, bearbeiten und manuell ergänzen, damit mein Trainingslog vollständig bleibt.[page:1]
- Als zielorientierter Nutzer möchte ich Wochenziele definieren und Erinnerungen erhalten, damit ich mein Training konsistent halte.[page:1]
- Als datensensibler Nutzer möchte ich die App lokal sinnvoll verwenden können, damit ich nicht zwingend auf Cloud-Sync angewiesen bin.[page:1]

## Funktionale Anforderungen
| ID | Anforderung | Priorität |
|---|---|---|
| FR-01 | App muss ein Workout mit Zeitmessung starten, pausieren, fortsetzen und beenden können.[page:1] | Must |
| FR-02 | App muss GPS-Track, Distanz und Höhenmeter aufzeichnen können.[page:1] | Must |
| FR-03 | App muss Bluetooth-LE-Herzfrequenzsensoren unterstützen.[page:1] | Must |
| FR-04 | App muss Workout-Historie lokal speichern und wieder anzeigen.[page:1] | Must |
| FR-05 | App muss manuelle Workouts ohne Live-Aufzeichnung erfassen können.[page:1] | Must |
| FR-06 | App muss Workout-Details mit Kennzahlen und mindestens einem Verlaufsdiagramm anzeigen.[page:1] | Must |
| FR-07 | App muss GPX-Dateien importieren und exportieren können.[page:1] | Should |
| FR-08 | App soll periodische Statistiken und Zielverfolgung bereitstellen.[page:1] | Should |
| FR-09 | App soll Offline-Karten oder einen funktional vergleichbaren Offline-Modus unterstützen.[page:1] | Should |
| FR-10 | App soll Diagnoseinformationen für Sensor- und Aufzeichnungsstatus anzeigen.[page:1] | Could |

## Nicht-funktionale Anforderungen
- Die App muss auch bei langen Outdoor-Aktivitäten stabil laufen und Zwischenstände regelmäßig sichern, da die Android-Version explizit auf automatische Speicherung und Wiederherstellung setzt.[page:1]
- Die Aufzeichnung darf bei gesperrtem Bildschirm nicht unzuverlässig werden, soweit iOS-Hintergrundregeln dies zulassen.[page:1]
- Die Benutzeroberfläche muss bei direkter Sonneneinstrahlung gut lesbar sein; eine kontrastreiche Workout-Ansicht ist Pflicht.
- Datenschutz muss „privacy by default“ folgen: lokale Speicherung als Standard, transparente Berechtigungen, klar verständliche Datenexporte.
- Die App muss auch ohne Konto sinnvoll benutzbar sein, weil die Kernfunktionen der Android-Version lokal zentriert sind.[page:1]

## UX-Anforderungen
Die iOS-Version soll nicht wie eine Android-Portierung wirken, sondern bekannte iOS-Muster nutzen: Tab-Bar, große Titel in Listen, systemnahe Sheets, Health-/Bluetooth-/Location-Permissions im passenden Moment und ein reduziertes, sporttaugliches Interface.[page:1] Während eines laufenden Trainings zählt Ablesbarkeit mehr als visuelle Komplexität; große Zahlen, wenige sekundäre Aktionen und schnelle Wechsel zwischen Metriken und Karte sind zentral.[page:1]

## Datenmodell
**Kernobjekte**
- Workout: ID, Sportart, Startzeit, Endzeit, Dauer, Distanz, Kalorien, Höhenmeter, Notiz, Intensität, Quellenstatus.
- Sensor-Samples: Zeitstempel + Messwerte für Herzfrequenz, Geschwindigkeit, Kadenz, Temperatur und weitere optionale Daten.[page:1]
- GPS-Track: Liste von Koordinatenpunkten mit Zeit, Höhe, Genauigkeit.[page:1]
- Ziel: Typ, Wochenziel, Gewichtung, Einheit, aktiv/inaktiv.[page:1]
- Sportart: Name, Kürzel, Farbe, Favorit.[page:1]
- Pulszone: Name, Kürzel, Minimal- und Maximalwert bzw. Prozentdefinition.[page:1]

## Technische Leitplanken
- Native Entwicklung in Swift.
- Empfohlene UI-Schicht: SwiftUI mit gezielten UIKit-Bridges für Karten oder Spezialcharts.
- CoreLocation für GPS, CoreBluetooth für BLE-Herzfrequenz, UserNotifications für Erinnerungen.
- Datenhaltung lokal, z. B. über SwiftData oder Core Data.
- GPX-Parser und GPX-Exporter als eigenes Modul.
- Kartenstrategie früh festlegen: Apple Maps reicht für Online-Basisfunktionen, für echte Offline-Karten kann ein alternatives Karten-Framework nötig sein.

## Risiken und Annahmen
| Thema | Risiko / Annahme |
|---|---|
| ANT+ | Die Android-App setzt stark auf ANT+; iOS wird dieses Spektrum voraussichtlich nicht gleichwertig abdecken können.[page:1] |
| Offline-Karten | Volle Offline-Kartenfunktion kann auf iOS technisch und lizenzseitig komplexer sein als auf Android.[page:1] |
| Hintergrundbetrieb | iOS limitiert Hintergrundverhalten stärker; das beeinflusst Wiederverbindung, Auto-Save und Langzeittracking. |
| Sensorvielfalt | Einige Spezialsensoren aus Android könnten auf iOS nur eingeschränkt oder gar nicht verfügbar sein.[page:1] |
| Produktumfang | Die Android-Funktionsliste ist sehr breit; ohne klare Priorisierung droht ein überladener Release 1.[page:1] |

## MVP-Empfehlung
Für ein marktfähiges erstes iOS-Release sollte der MVP folgende Pakete enthalten:
- Workout-Aufzeichnung mit GPS, Distanz, Zeit, Pace/Geschwindigkeit, Kalorien und Höhenmetern.[page:1]
- Bluetooth-LE-Herzfrequenz inklusive Pulszonen.[page:1]
- Historie, Workout-Details und Basisanalyse.[page:1]
- GPX-Import/-Export.[page:1]
- Ziele und lokale Benachrichtigungen.[page:1]
- Biologische Daten, Sportarten, Einheiten und Datenschutzeinstellungen.[page:1]

Offline-Karten auf hohem Niveau, zusätzliche Sensortypen, Cloud-Sync und SOS-Funktionen sollten erst nach Validierung des Grundprodukts folgen.[page:1]

## Erfolgskriterien
- Nutzer können ein Workout ohne Anleitung innerhalb weniger Minuten starten und beenden.
- Eine aufgezeichnete Einheit liefert konsistente Kernmetriken und bleibt auch nach App-Neustart erhalten.[page:1]
- BLE-Herzfrequenzsensoren lassen sich zuverlässig koppeln und in Trainingsdetails auswerten.[page:1]
- GPX-Import und -Export funktionieren robust über typische iOS-Datei-Workflows.[page:1]
- Wöchentliche Ziele und Benachrichtigungen erhöhen die regelmäßige Nutzung.[page:1]

## Offene Fragen
1. Soll Apple Watch als Datenquelle oder Companion-App früh berücksichtigt werden?
2. Wie wichtig ist echte Offline-Kartenunterstützung im Vergleich zu lokal gecachten Kartenausschnitten?
3. Soll HealthKit nur exportieren, oder auch Workouts und biometrische Daten importieren?
4. Ist ein lokaler-only Modus dauerhaft Produktprinzip, oder wird später ein optionales Konto-/Sync-Modell verfolgt?[page:1]
5. Welche Android-Analysefunktionen müssen zwingend im ersten iOS-Release enthalten sein und welche können später folgen?[page:1]
