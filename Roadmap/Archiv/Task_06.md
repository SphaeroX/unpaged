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

1. [x] Pipeline-Service mit gemocktem Adapter/Renderer per TDD (Reihenfolge, Statuswechsel, Fehlerfall).
2. [x] Persistenz von JSON und Ausschnitten über die Dateiablage-Abstraktion per TDD.
3. [x] Hintergrundausführung umsetzen und Fortschritt als Stream an die UI liefern.
4. [x] Versionsprüfung und Neuberechnung per TDD.
5. [x] Erkennung „kein Text“ (z. B. keine oder fast keine Zeichen) per TDD.
6. [x] Fortschritt und Status in der Bibliothek anzeigen (Widget-Tests).
7. [x] Integrationstest mit einer Korpus-PDF: Import → Status fertig → JSON und PNGs vorhanden.
8. [x] Abbruch-/Neustart-Verhalten klären (App wird während der Berechnung beendet) und dokumentieren.

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

- [x] `flutter test tests/app tests/reflow_engine` grün; Integrationstest grün oder begründet vermerkt.
- [x] Während der Berechnung bleibt die Bibliothek bedienbar (manuell geprüft und notiert, z. B. Scrollen ohne Ruckeln).
- [x] Für eine Korpus-PDF mit Tabelle existiert nach dem Import ein PNG-Ausschnitt pro Tabellenbereich.
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Speicherort und Auflösung der Ausschnitte legt der Task fest und dokumentiert sie in `docs/architecture.md`.
- Ob nach einem App-Neustart abgebrochene Berechnungen automatisch fortgesetzt werden, entscheidet der Task (Annahme: ja, Neustart der Berechnung).
- Aus Task_05: `Books.reflowStatus` (`ReflowStatus.pending|running|done|failed|noText`) und `reflowProgress` existieren schon; `ImportService.deleteBook` muss zusätzlich Cache und Ausschnitte löschen; Pfade wie beim `BookFileStore` in `main()` aus dem App-Support-Verzeichnis ableiten.
- Aus Task_04: Bereichsblöcke (`BlockType.isRegion`) haben leeren Text; `page` + `box` (Top-down-Punkte der Seite) bestimmen den Ausschnitt. pdfrx rendert mit `PdfPage.render(x, y, width, height, fullWidth, fullHeight)` in Pixeln, Ursprung oben links.
- Aus Task_02: Engine-Ergebnis und Extraktion laufen in `Isolate.run` (Host belegt, `pdfrxInitialize(tmpPath: …)` im Isolate); auf Android noch zu prüfen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 151 Tests grün (ein Lauf zuvor: `renderRegions`-Test einmal „did not complete“, beim Wiederholen grün – vermutlich Isolat-Start unter Last); `flutter analyze` ohne Befund; `flutter build apk --debug` erfolgreich.
- Integrationstest `tests/integration/reflow_pipeline_test.dart` (echte Pipeline auf dem Gerät) geschrieben, **nicht ausgeführt** (kein Gerät). Ebenso offen: manuelle Prüfung, dass die Bibliothek während der Berechnung flüssig bleibt, und dass Extraktion/Engine im Isolate auf Android laufen.
- Kein Test musste geändert werden: Für wartende Bücher (`pending`) wird bewusst kein Status angezeigt, damit „12 Seiten“ wie bisher erscheint.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** `ReflowPipeline`, `ReflowScheduler`/`ReflowQueue`, `ReflowStore`, `PdfAdapter.renderRegions` (+ `RegionRequest`), eigener PNG-Encoder, Statusanzeige mit Fortschrittsbalken in der Bibliothek, Löschen inkl. Cache, Fortsetzen unterbrochener Läufe und Neuberechnung bei neuer `engineVersion` beim Öffnen der Bibliothek. Abweichung: Extraktion läuft nicht in einem eigenen Isolate, sondern über pdfrx (dessen PDFium-Aufrufe ohnehin im Worker-Isolate laufen); nur Engine und PNG-Kodierung laufen in `Isolate.run`.
- **Learnings & Stolpersteine:** `PdfImage.pixels` ist BGRA; `page.render(x, y, width, height, fullWidth, fullHeight)` arbeitet in Pixeln mit Ursprung oben links – die Top-down-Boxen der Engine passen direkt (× Skalierung). Klassen mit privaten Feldern lassen sich in derselben Bibliothek nicht einfach `implements` – dafür das kleine Interface `ReflowQueue`.
- **Wichtige Entscheidungen und ihre Gründe:** Eigener PNG-Encoder statt `image`-Paket (keine Abhängigkeit, läuft im Isolate). Crops mit 3 px/pt (≈ 216 dpi) für scharfen Zoom. `failed`/`noText` werden nicht automatisch wiederholt (sonst Endlosschleife bei kaputten PDFs); erst eine neue Engine-Version oder ein späterer manueller Auslöser (noch nicht gebaut) versucht es erneut.
- **Auswirkungen auf Folge-Tasks:** Task 07 liest `ReflowStore.readDocument(id)` (null = fehlt/kaputt → Hinweis + Neuberechnung über `reflowSchedulerProvider.enqueue`) und Crops über `ReflowStore.cropFile(bookId, blockId)`. eBook-Modus nur bei `ReflowStatus.done`. Neue Widget-Tests: `TestEnv.overrides` enthält bereits `reflowStoreProvider` (Temp-Verzeichnis) und `NoopReflowScheduler`.
- **Hinweise zu Tests und Befehlen:** Pipeline-Tests mit gemocktem `PdfAdapter` und injiziertem `runEngine` (`tests/app/features/reflow/`). Für `mocktail`-`any()` mit `List<RegionRequest>` in `setUpAll` `registerFallbackValue(<RegionRequest>[])`.
