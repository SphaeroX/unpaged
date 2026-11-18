# Task_11: Markierungen im eBook-Modus

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_11.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Im eBook-Modus kann man Text markieren und Notizen anhängen. Markierungen werden an Block-ID und Offset verankert und zusätzlich mit Textzitat samt Kontext gespeichert, sodass sie nach einer Neuberechnung mit neuer `engineVersion` wieder zugeordnet werden.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_07 und Task_10 archiviert.
- **Relevantes Vorwissen:** `docs/architecture.md` (Markierungen); Markierungsmodell, Notiz-UI und Übersicht aus Task_10 wiederverwenden; Neuberechnung aus Task_06.

## Umfang

**Gehört dazu:**

- Modell-Erweiterung: Ansicht = ebook, Block-ID, Start-/End-Offset, zitierter Text, Kontext davor/danach, `engineVersion` zum Zeitpunkt der Markierung
- Textauswahl im Reader und Markier-Aktion; Darstellung als Hervorhebung im Text
- Notizen, Bearbeiten, Löschen, Übersicht (gemeinsame Bausteine aus Task_10)
- Neuverankerung nach Neuberechnung: exakte Block-ID + Zitat → passt; sonst Suche nach Zitat mit Kontext im ganzen Dokument; nicht auffindbar → Markierung als „verwaist“ in der Übersicht anzeigen, nicht löschen

**Gehört nicht dazu:**

- Abgleich mit Markierungen im Original (Nicht-Ziel)
- Markierungen über Bildausschnitte

## Umsetzungsschritte

1. [x] Modell-Erweiterung und Migration per TDD.
2. [x] Neuverankerungs-Algorithmus als reine Funktion per TDD (exakter Treffer, verschobener Block, geänderter Umbruch, mehrdeutiges Zitat → Kontext entscheidet, nicht auffindbar).
3. [x] Auswahl und Hervorhebung im Reader.
4. [x] Notiz-UI und Übersicht anbinden, verwaiste Markierungen kennzeichnen.
5. [x] Neuverankerung beim Laden nach Neuberechnung auslösen und Ergebnis speichern.
6. [x] Integrationstest: markieren, `engineVersion` künstlich erhöhen/neu berechnen, Markierung sitzt wieder an der richtigen Stelle.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Gleiches Dokument → Markierung unverändert.
- Unit: Block-IDs verschoben, Text gleich → Markierung über Zitat neu verankert.
- Unit: Zitat kommt zweimal vor → Kontext wählt das richtige Vorkommen.
- Unit: Zitat nicht mehr vorhanden → verwaist, nicht gelöscht.
- Widget: Hervorhebung erscheint im Reader.
- Integration: Markierung überlebt Neuberechnung.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [x] Markierungen aus Task_10 (Original) bleiben unverändert (bestehende Tests grün).
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Aus Task_10: Tabelle `Annotations` hat bereits `blockId`, `prefix`, `suffix`, `engineVersion`, `orphaned` (Schema v4, keine Migration nötig); `AnnotationRepository.add/update/delete/watch(bookId, ReadingView.ebook)`; Sheets/Liste in `lib/features/annotations/presentation/annotation_sheets.dart`. Im Widget-Test drift-Streams nur über `tester.runAsync` lesen.
- Annahme: Markierungen über Blockgrenzen hinweg werden auf einen Block begrenzt oder in mehrere Teile zerlegt; der Task entscheidet und dokumentiert.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 212 Tests grün; `flutter analyze` ohne Befund.
- Vom Nutzer freigegebene Testanpassung (geplante Änderung): Stil-Prüfungen in `reader_screen_test.dart` und `reader_settings_ui_test.dart` lesen den Stil über `tests/app/helpers/text_style.dart`, weil Reader-Text jetzt `SelectableText` ist; Prüfabsicht unverändert.
- Kein Integrationstest: Textauswahl auf dem Gerät ist hier nicht automatisierbar; Neuverankerung und Markieren sind über Widget-Tests (Auswahl per `EditableTextState`) und Unit-Tests abgedeckt.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** Markieren/Notiz im eBook-Modus über das Kontextmenü von `SelectableText`, Darstellung als farbige Spans, Antippen öffnet das Sheet, Liste mit Sprung zum Block und Kennzeichnung verwaister Markierungen, Neuverankerung nach Neuberechnung (`reanchor`, `AnnotationRepository.updateAnchor`). Entscheidung zur offenen Frage: Markierungen sind auf einen Block begrenzt.
- **Learnings & Stolpersteine:** `InlineSpan.visitChildren` besucht nur Spans mit Textinhalt – für Stil-Container `visitDirectChildren` rekursiv nutzen. In Widget-Tests lässt sich eine Auswahl mit `EditableTextState.userUpdateTextEditingValue(..., SelectionChangedCause.longPress)` + `showToolbar()` erzeugen; ein Tippen mit `SelectionChangedCause.tap`. `dart fix` hat erneut `unawaited(Navigator…)` kaputt „repariert“ (Regel jetzt in `docs/code-style.md`).
- **Wichtige Entscheidungen und ihre Gründe:** Kontext 30 Zeichen je Seite; Bewertung über gemeinsame Präfix-/Suffixlänge. Verwaiste Markierungen werden nie gelöscht und bei jedem Öffnen erneut gesucht (eine spätere Engine-Version könnte das Zitat wieder liefern).
- **Auswirkungen auf Folge-Tasks:** Task 12: keine Datenbankänderung mehr nötig (Schema v4). Die Lizenzseite muss die OFL-Schriften enthalten (Task 08).
- **Hinweise zu Tests und Befehlen:** `tests/app/features/annotations/ebook_annotations_test.dart` (Auswahl, Spans, Neuverankerung, verwaist), `reanchor_test.dart` (Algorithmus).
