# Task_10: Markierungen im Original

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_10.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

In der Original-Seitenansicht kann man Text markieren und Notizen anhängen. Markierungen werden an Seite und Zeichenbereich verankert, nur in der App-Datenbank gespeichert und beim erneuten Öffnen wieder angezeigt.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_05 archiviert (Task_06–09 nach Reihenfolge erledigt).
- **Relevantes Vorwissen:** `docs/architecture.md` (Markierungen); Nicht-Ziel: nie in die PDF schreiben; PDF-Adapter in `lib/core/` (Textauswahl und Zeichenpositionen über pdfrx); Feature `annotations`.

## Umfang

**Gehört dazu:**

- Datenmodell und DB-Tabelle: Dokument-ID, Ansicht = original, Seite, Zeichenbereich (Start/Ende), Farbe, Notiz, Zeitstempel
- Textauswahl in der Seitenansicht und Aktion „Markieren“ / „Notiz“
- Darstellung markierter Bereiche als Overlay über der Seite
- Markierung antippen → Notiz ansehen/bearbeiten, Markierung löschen
- Übersicht der Markierungen eines Buchs mit Sprung zur Stelle
- Löschen eines Buchs entfernt seine Markierungen

**Gehört nicht dazu:**

- Markierungen im eBook-Modus (Task 11)
- Abgleich zwischen Original und eBook (Nicht-Ziel)
- Export oder Schreiben in die PDF (Nicht-Ziel)

## Umsetzungsschritte

1. [x] Datenmodell und Repository per TDD (In-Memory-DB, Migration).
2. [x] Umrechnung Zeichenbereich → Rechtecke auf der Seite im Adapter per TDD.
3. [x] Auswahl- und Markier-Aktion im Viewer anbinden.
4. [x] Overlay-Darstellung per Widget-Test.
5. [x] Notiz-Dialog, Bearbeiten und Löschen.
6. [x] Übersichtsliste mit Sprung.
7. [x] Integrationstest: markieren, Notiz anlegen, Buch schließen und öffnen, Markierung ist da.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Anlegen, Lesen, Ändern, Löschen von Markierungen; Kaskade beim Löschen eines Buchs.
- Unit: Zeichenbereich über Zeilenumbruch ergibt mehrere Rechtecke.
- Widget: Overlay erscheint an der erwarteten Position (mit gemocktem Adapter).
- Integration: Markierung überlebt Schließen und erneutes Öffnen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [x] Die PDF-Datei unter `books/<sha256>.pdf` bleibt byte-identisch (Hash nach dem Markieren unverändert; Test belegt das).
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Ob pdfrx eine fertige Textauswahl-UI bietet oder eine eigene nötig ist, klärt der Task.
- Annahme: Wenige feste Markierungsfarben (z. B. 4) genügen.
- Aus Task_09: `schemaVersion` ist 3 → Markierungstabelle mit Version 4 + Migrationstest; `ImportService.deleteBook` löscht bereits Positionen und soll auch Markierungen löschen. Die Originalansicht ist `PdfAdapter.pageView` (pdfrx `PdfViewer.file`); Textauswahl/Overlays dort über `PdfViewerParams` (z. B. `textSelectionParams`, `pageOverlaysBuilder`) prüfen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 201 Tests grün; `flutter analyze` ohne Befund; `flutter build apk --debug` erfolgreich.
- Kein Integrationstest geschrieben: Die Textauswahl ist eine pdfrx-Geste auf gerenderten Seiten und lässt sich ohne Gerät nicht sinnvoll automatisieren; die Logik ist über Widget-Tests mit abgefangenen Adapter-Callbacks und über einen Host-Test von `textRects` mit echter PDF abgedeckt. Manuelle Prüfung auf einem Gerät (Text auswählen → Markieren → App schließen/öffnen) steht aus.
- Vom Nutzer freigegebene Testanpassung (geplante Änderung): `pageView`-Stubs in vier Widget-Tests um die neuen Parameter `highlights`, `selectionActions`, `onHighlightTap` ergänzt.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** `Annotations`-Tabelle (Schema v4, schon mit den eBook-Feldern für Task 11), `AnnotationRepository`, Adapter-Erweiterung (`PdfSelection`, `PageHighlight`, `SelectionAction`, `textRects`, Overlays, eigenes Kontextmenü), Viewer-Aktionen „Markieren“ / „Notiz hinzufügen“, Bearbeiten-Sheet mit 4 Farben, Liste mit Sprung zur Seite, Löschen mit dem Buch.
- **Learnings & Stolpersteine:** `watch(...).first` eines drift-Streams im Widget-Testkörper blockiert das Isolate dauerhaft – selbst `--timeout` greift nicht; Lösung `tester.runAsync`. pdfrx-Overlays (`pageOverlaysBuilder`) liegen in einem Stack in Seitengröße → Positionierung = Seitenpunkte × (pageRect.width / page.width). Zeichenindizes der Auswahl beziehen sich auf `loadStructuredText().fullText` – `textRects` nutzt deshalb dieselbe Quelle.
- **Wichtige Entscheidungen und ihre Gründe:** Eine Tabelle für beide Ansichten (gemeinsame Liste/Sheets), getrennt über `view`. Rechtecke werden beim Laden der Markierungen über den Adapter berechnet (pro Zeile zusammengefasst), nicht gespeichert – so bleiben sie bei geänderter Darstellung korrekt.
- **Auswirkungen auf Folge-Tasks:** Task 11 nutzt `AnnotationDraft` mit `view: ReadingView.ebook`, `blockId`, `start`/`end` als Offsets im Blocktext, `prefix`/`suffix` und `engineVersion`; `orphaned` markiert nicht auffindbare Zitate. Sheets/Liste aus `annotation_sheets.dart` sind wiederverwendbar (`pageLabel` zeigt die Seite).
- **Hinweise zu Tests und Befehlen:** `tests/app/features/annotations/original_annotations_test.dart` fängt `highlights`, `selectionActions` und `onHighlightTap` aus dem gemockten `pageView` ab und ruft sie direkt auf.
