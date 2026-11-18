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

1. [ ] Datenmodell und Repository per TDD (In-Memory-DB, Migration).
2. [ ] Umrechnung Zeichenbereich → Rechtecke auf der Seite im Adapter per TDD.
3. [ ] Auswahl- und Markier-Aktion im Viewer anbinden.
4. [ ] Overlay-Darstellung per Widget-Test.
5. [ ] Notiz-Dialog, Bearbeiten und Löschen.
6. [ ] Übersichtsliste mit Sprung.
7. [ ] Integrationstest: markieren, Notiz anlegen, Buch schließen und öffnen, Markierung ist da.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Anlegen, Lesen, Ändern, Löschen von Markierungen; Kaskade beim Löschen eines Buchs.
- Unit: Zeichenbereich über Zeilenumbruch ergibt mehrere Rechtecke.
- Widget: Overlay erscheint an der erwarteten Position (mit gemocktem Adapter).
- Integration: Markierung überlebt Schließen und erneutes Öffnen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [ ] Die PDF-Datei unter `books/<sha256>.pdf` bleibt byte-identisch (Hash nach dem Markieren unverändert; Test belegt das).
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Ob pdfrx eine fertige Textauswahl-UI bietet oder eine eigene nötig ist, klärt der Task.
- Annahme: Wenige feste Markierungsfarben (z. B. 4) genügen.
- Aus Task_09: `schemaVersion` ist 3 → Markierungstabelle mit Version 4 + Migrationstest; `ImportService.deleteBook` löscht bereits Positionen und soll auch Markierungen löschen. Die Originalansicht ist `PdfAdapter.pageView` (pdfrx `PdfViewer.file`); Textauswahl/Overlays dort über `PdfViewerParams` (z. B. `textSelectionParams`, `pageOverlaysBuilder`) prüfen.

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
