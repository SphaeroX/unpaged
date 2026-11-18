# Task_06: Reflow-Pipeline in der App

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_06.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Beim Import startet die Reflow-Berechnung automatisch im Hintergrund: Zeichen extrahieren, Engine laufen lassen, Bildausschnitte für Tabellen/Formeln/Abbildungen rendern und das Ergebnis als JSON mit `engineVersion` zwischenspeichern. Der Fortschritt ist in der Bibliothek sichtbar, die UI bleibt flüssig.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_04 und Task_05 archiviert.
- **Relevantes Vorwissen:** `docs/architecture.md` (Reflow-Pipeline Schritte 2–6); Ergebnis der Isolate-Frage aus Task_02 (README und Erkenntnisse); Bereichsmodell aus Task_04; DB und Import aus Task_05.

## Umfang

**Gehört dazu:**

- Pipeline-Service: Adapter → Engine → Ausschnitt-Rendering → Speichern
- Ausführung außerhalb des UI-Isolates (konkreter Weg gemäß Ergebnis aus Task_02)
- PNG-Ausschnitte je Bereich, einmalig gerendert, abgelegt pro Dokument (z. B. `reflow/<sha256>/…`), Auflösung so, dass Zoom scharf bleibt
- `ReflowDocument` als JSON pro Dokument mit `engineVersion`
- Status pro Buch in der DB (ausstehend, läuft mit Fortschritt, fertig, fehlgeschlagen, kein Text vorhanden)
- Neuberechnung, wenn gespeicherte `engineVersion` kleiner als die aktuelle ist (beim Öffnen oder App-Start)
- Fortschrittsanzeige in der Bibliothek; PDFs ohne Textebene → Status „kein Text“ mit Hinweis, dass nur die Originalansicht verfügbar ist
- Löschen eines Buchs entfernt auch Cache und Ausschnitte

**Gehört nicht dazu:**

- eBook-Leseansicht (Task 07)
- OCR für gescannte PDFs (Nicht-Ziel)

## Umsetzungsschritte

1. [ ] Pipeline-Service mit gemocktem Adapter/Renderer per TDD (Reihenfolge, Statuswechsel, Fehlerfall).
2. [ ] Persistenz von JSON und Ausschnitten über die Dateiablage-Abstraktion per TDD.
3. [ ] Hintergrundausführung umsetzen und Fortschritt als Stream an die UI liefern.
4. [ ] Versionsprüfung und Neuberechnung per TDD.
5. [ ] Erkennung „kein Text“ (z. B. keine oder fast keine Zeichen) per TDD.
6. [ ] Fortschritt und Status in der Bibliothek anzeigen (Widget-Tests).
7. [ ] Integrationstest mit einer Korpus-PDF: Import → Status fertig → JSON und PNGs vorhanden.
8. [ ] Abbruch-/Neustart-Verhalten klären (App wird während der Berechnung beendet) und dokumentieren.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Erfolgreicher Durchlauf setzt Status auf fertig und speichert JSON mit aktueller `engineVersion`.
- Unit: Fehler in der Engine → Status fehlgeschlagen, App stürzt nicht ab.
- Unit: Gespeicherte ältere `engineVersion` löst Neuberechnung aus, gleiche nicht.
- Unit: Dokument ohne Textebene → Status „kein Text“.
- Unit: Löschen entfernt Cache und Ausschnitte.
- Widget: Bibliothek zeigt Fortschritt und Status.
- Integration: Korpus-PDF wird vollständig verarbeitet.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app tests/reflow_engine` grün; Integrationstest grün oder begründet vermerkt.
- [ ] Während der Berechnung bleibt die Bibliothek bedienbar (manuell geprüft und notiert, z. B. Scrollen ohne Ruckeln).
- [ ] Für eine Korpus-PDF mit Tabelle existiert nach dem Import ein PNG-Ausschnitt pro Tabellenbereich.
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Speicherort und Auflösung der Ausschnitte legt der Task fest und dokumentiert sie in `docs/architecture.md`.
- Ob nach einem App-Neustart abgebrochene Berechnungen automatisch fortgesetzt werden, entscheidet der Task (Annahme: ja, Neustart der Berechnung).
- Aus Task_05: `Books.reflowStatus` (`ReflowStatus.pending|running|done|failed|noText`) und `reflowProgress` existieren schon; `ImportService.deleteBook` muss zusätzlich Cache und Ausschnitte löschen; Pfade wie beim `BookFileStore` in `main()` aus dem App-Support-Verzeichnis ableiten.
- Aus Task_04: Bereichsblöcke (`BlockType.isRegion`) haben leeren Text; `page` + `box` (Top-down-Punkte der Seite) bestimmen den Ausschnitt. pdfrx rendert mit `PdfPage.render(x, y, width, height, fullWidth, fullHeight)` in Pixeln, Ursprung oben links.
- Aus Task_02: Engine-Ergebnis und Extraktion laufen in `Isolate.run` (Host belegt, `pdfrxInitialize(tmpPath: …)` im Isolate); auf Android noch zu prüfen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):**
- **Learnings & Stolpersteine:**
- **Wichtige Entscheidungen und ihre Gründe:**
- **Auswirkungen auf Folge-Tasks:**
- **Hinweise zu Tests und Befehlen:**
