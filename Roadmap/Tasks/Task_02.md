# Task_02: Reflow-Spike & Engine-Basis

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_02.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Das reine Dart-Paket `packages/reflow_engine` existiert und wandelt einspaltigen Text in Absätze um. Ein pdfrx-Adapter liefert die Zeichen, ein Korpus frei lizenzierter Test-PDFs und Snapshot-Tests sichern die Qualität ab. Der Spike klärt die technischen Unbekannten der Textextraktion früh, weil der Reflow das Hauptrisiko des Projekts ist.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_01 archiviert.
- **Relevantes Vorwissen:** `docs/architecture.md` (Reflow-Pipeline Schritte 2–3, Engine ohne Flutter/pdfrx); `docs/testing.md` (Snapshot-Regeln, `tests/reflow_engine/corpus/`, `snapshots/`); Erkenntnisse aus Task_01 zum PDF-Adapter.

## Umfang

**Gehört dazu:**

- Paket `packages/reflow_engine/` (reines Dart, eigene `analysis_options.yaml`), per `path` in der App eingebunden
- Eingabemodell: Seiten mit Zeichen (Glyph, Bounding-Box, Schriftgröße, ggf. Schriftname); Ausgabemodell `ReflowDocument` mit Blöcken (ID, Text, Quellseite, Bounding-Box) und `engineVersion`; JSON-Serialisierung
- Erste Engine-Stufe: Zeichen → Wörter → Zeilen → Absätze für einspaltigen Text
- Adapter in `lib/core/`, der über pdfrx pro Seite die Zeichen mit Positionen liefert und ins Eingabemodell übersetzt
- Test-PDF-Korpus unter `tests/reflow_engine/corpus/` (Zweispalter, Tabellen, Formeln, Abbildungen, einfacher Einspalter) mit `SOURCES.md` (Quelle, Lizenz je Datei)
- Weg, wie Engine-Tests ohne pdfrx an Zeichendaten kommen (z. B. extrahierte JSON-Fixtures + Extraktionsskript/-test), festlegen und in `docs/testing.md` dokumentieren
- Snapshot-Testinfrastruktur unter `tests/reflow_engine/` und erste Snapshots für den Einspalter
- Klären, ob die pdfrx-Textextraktion außerhalb des Haupt-Isolates läuft; Ergebnis in `Roadmap/README.md` und `docs/architecture.md`

**Gehört nicht dazu:**

- Spalten, Lesereihenfolge, Kopf-/Fußzeilen, Silbentrennung (Task 03)
- Blocktypen und Nicht-Text-Bereiche (Task 04)
- Hintergrundverarbeitung in der App, Cache, UI (Task 06/07)

## Umsetzungsschritte

1. [ ] Paketgerüst anlegen; einen ersten fehlschlagenden Test unter `tests/reflow_engine/` schreiben und prüfen, dass er aus dem Root mit `flutter test tests/reflow_engine` läuft.
2. [ ] Ein- und Ausgabemodelle samt JSON-Roundtrip per TDD bauen.
3. [ ] Zeilen- und Absatzbildung für einspaltigen Text per TDD mit kleinen, handgebauten Zeichenfolgen entwickeln.
4. [ ] Korpus zusammenstellen (nur nachweislich frei lizenzierte PDFs, z. B. CC-BY/CC0), `SOURCES.md` schreiben.
5. [ ] pdfrx-Adapter in `lib/core/` bauen (mit Test gegen eine Korpus-PDF) und Fixture-Weg für die Engine-Tests festlegen.
6. [ ] Isolate-Frage praktisch prüfen (kleiner Versuch) und Ergebnis dokumentieren.
7. [ ] Snapshots für den Einspalter erzeugen, manuell auf Plausibilität prüfen und einchecken.
8. [ ] `docs/testing.md` und `docs/architecture.md` aktualisieren; offene Entscheidung zur Isolate-Frage schließen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Modelle serialisieren verlustfrei nach JSON und zurück.
- Unit: Zeichen derselben Grundlinie werden zu einer Zeile, Wortabstände werden zu Leerzeichen.
- Unit: Zeilen mit normalem Zeilenabstand bilden einen Absatz; größerer Abstand oder Einzug beginnt einen neuen.
- Randfall: leere Seite, Seite mit nur einem Zeichen.
- Snapshot: Einspalter aus dem Korpus ergibt die eingecheckten Absätze.
- Adapter-Test: Für eine Korpus-PDF liefert der Adapter Zeichen mit plausiblen Positionen (Anzahl > 0, Boxen innerhalb der Seite).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/reflow_engine` grün; Snapshot-Test für den Einspalter vorhanden.
- [ ] `packages/reflow_engine` importiert weder Flutter noch pdfrx (`grep -rE "package:(flutter|pdfrx)" packages/reflow_engine/lib` ohne Treffer).
- [ ] `tests/reflow_engine/corpus/SOURCES.md` nennt für jede Datei Quelle und Lizenz.
- [ ] Isolate-Frage beantwortet und in `docs/architecture.md` (Offene Entscheidungen) geschlossen.
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Der Agent wählt die Korpus-PDFs selbst (Nutzerentscheidung); nur Dateien mit eindeutig freier Lizenz. Hinweis aus Task_01: arxiv.org ist in der Cloud-Umgebung erreichbar; viele aktuelle Paper stehen unter CC BY 4.0 bzw. CC0 (Lizenz-Link auf der `abs`-Seite prüfen). Zum Kleinhalten des Repos dürfen Seiten ausgeschnitten werden (bei CC BY mit Hinweis auf die Änderung in `SOURCES.md`).
- pdfrx liefert pro Zeichen nur Text und Box (`PdfPage.loadText()` → `PdfPageRawText.fullText`/`charRects`), **keine Schriftgröße**: Die Schriftgröße im Eingabemodell wird aus der Box-Höhe geschätzt.
- Ob die Engine-Tests mit JSON-Fixtures oder anders an Zeichendaten kommen, entscheidet dieser Task.

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
