# Task_03: Spalten & Lesereihenfolge

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_03.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die Engine bringt mehrspaltige Seiten in die richtige Lesereihenfolge, entfernt Kopf- und Fußzeilen sowie Seitenzahlen und löst Silbentrennungen am Zeilenende auf. Damit wird der eBook-Text für wissenschaftliche Paper und Fachbücher überhaupt erst lesbar.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_02 archiviert.
- **Relevantes Vorwissen:** Engine-Modelle und Snapshot-/Fixture-Weg aus Task_02 (Erkenntnisse lesen); Korpus unter `tests/reflow_engine/corpus/`; Snapshot-Regeln in `docs/testing.md`.

## Umfang

**Gehört dazu:**

- Spaltenerkennung pro Seite (ein- und zweispaltig, auch Wechsel auf derselben Seite, z. B. einspaltiger Titelbereich über zwei Spalten)
- Lesereihenfolge: Spalte für Spalte, oben nach unten
- Erkennung von Kopf-/Fußzeilen und Seitenzahlen über Wiederholung an gleicher Position auf mehreren Seiten
- Silbentrennung: Wort mit Trennstrich am Zeilenende + Fortsetzung zusammenführen; echte Bindestriche (z. B. „E-Mail“, „Offline-Modus“) erhalten
- Absätze, die über Spalten- oder Seitengrenzen laufen, zusammenführen
- `engineVersion` erhöhen

**Gehört nicht dazu:**

- Blocktypen (Überschrift, Liste, Bildunterschrift) und Nicht-Text-Bereiche (Task 04)
- Mehr als drei Spalten oder komplexe Magazin-Layouts (nur Absicherung gegen Absturz)

## Umsetzungsschritte

1. [x] Fehlschlagende Snapshot-Tests für den Zweispalter im Korpus anlegen (erwartete Reihenfolge von Hand prüfen).
2. [x] Spaltenerkennung per TDD mit synthetischen Seiten entwickeln (eine, zwei Spalten, gemischt).
3. [x] Lesereihenfolge implementieren.
4. [x] Kopf-/Fußzeilen- und Seitenzahl-Erkennung per TDD (synthetisches Mehrseiten-Dokument).
5. [x] Silbentrennung per TDD inklusive Gegenbeispielen mit echten Bindestrichen.
6. [x] Absatz-Fortsetzung über Spalten- und Seitengrenzen.
7. [x] Bestehende Einspalter-Snapshots müssen unverändert grün bleiben; sonst Ursache in der Implementierung suchen.
8. [x] `engineVersion` erhöhen, Erkenntnisse zu Heuristiken und Schwellwerten dokumentieren.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Zweispaltige Seite → linke Spalte vollständig vor rechter.
- Unit: Gemischte Seite (Titel über volle Breite, darunter zwei Spalten) → Titel zuerst.
- Unit: Wiederholte Zeile oben/unten auf ≥ 3 Seiten wird entfernt; einmaliger Text an ähnlicher Position bleibt.
- Unit: „Infor-“ + „mation“ → „Information“; „Offline-“ am Zeilenende + „Modus“ bleibt „Offline-Modus“ nur wenn der Bindestrich echt ist (Heuristik dokumentieren).
- Snapshot: Zweispalter aus dem Korpus in korrekter Reihenfolge, ohne Kopf-/Fußzeilen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/reflow_engine` grün, inklusive neuer Zweispalter-Snapshots und unveränderter Snapshots aus Task_02.
- [x] Im Zweispalter-Snapshot kommen keine Seitenzahlen und keine laufenden Kopfzeilen vor.
- [x] `engineVersion` ist höher als nach Task_02.
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Annahme: Schwellwerte für Spaltenlücken und Wiederholungserkennung werden empirisch am Korpus bestimmt und im Task dokumentiert.
- Unklar, wie gut sich echte von Trenn-Bindestrichen ohne Wörterbuch unterscheiden lassen; ein Wörterbuch wäre eine neue Abhängigkeit und braucht Rückfrage.
- Aus Task_02: `buildLines` verbindet Glyphen gleicher Baseline über die ganze Seitenbreite – Spalten müssen vor bzw. bei der Zeilenbildung getrennt werden. Fixtures der Zweispalter: `tests/reflow_engine/fixtures/two_column_tables.json`, `two_column_figures.json`. PDFium markiert erkannte Trennstriche am Zeilenende als U+0002; der Adapter macht daraus `-`, die Engine sieht also ein normales `-` am Zeilenende.
- Das Entfernen der Seitenzahlen ändert den bestehenden Snapshot `single_column_text` → Änderung begründen und Freigabe einholen (Snapshot-Regeln).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 76 Tests grün; `flutter analyze` / `dart analyze` ohne Befund; Format sauber.
- Snapshot-Änderungen (vom Nutzer pauschal für Task 03/04 freigegeben, von Hand geprüft): `single_column_text` – Seitenzahlen entfernt, Absatz über die Seitengrenze 2→3 zusammengeführt; `synthetic_single_column` – nur `engineVersion` 1→2. Neu: `synthetic_two_column` (zusätzlich exakter Erwartungstest), `two_column_tables`, `two_column_formulas`.
- Korpus: `single_column_formulas` war tatsächlich zweispaltig → umbenannt in `two_column_formulas` (PDF + Fixture + SOURCES). Neu: `synthetic_two_column.pdf` (CC0); Generator schreibt jetzt mit festem Datum (byte-stabil).

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** Zeilenbildung neu (Läufe in PDF-Inhaltsreihenfolge, dann Zusammenführen nur bei horizontaler Nähe ≤ 1,2× Zeilenhöhe), Spaltenerkennung mit Regionen (`reading_order.dart`), Entfernen von Kolumnentiteln/Seitenzahlen/Randresten (`running_elements.dart`), dokumentweite Absatzbildung mit Fortsetzung über Spalten und Seiten, Silbentrennung (`hyphenation.dart`), `engineVersion` 2. Zusätzlich (nicht geplant): vertikalen Text verwerfen (arXiv-Stempel), Schriftgrößen-Schätzung für Zeilen nur aus x-Höhen-Buchstaben, Erkennung abwechselnder Kolumnentitel (Titel/Autor der ersten zwei Seiten).
- **Learnings & Stolpersteine:** Glyphen über die ganze Seitenbreite nach Baseline zu gruppieren ist bei Zweispaltern falsch: hohe Formelglyphen in einer Spalte verschmieren sonst Zeilen der anderen. Die PDF-Inhaltsreihenfolge (LaTeX: erst linke, dann rechte Spalte) ist ein starkes Signal. Spaltenlücken sind teils nur ~10 pt breit (≈1,4× Glyphhöhe) – Schwellen nicht zu groß wählen. Kommas/`°`/Hochstellungen überlappen das Zeilenband nur zu 30–50 %; deshalb Sonderregel für kleine Glyphen (< 0,8× Zeilenhöhe, Band ±35 %). Mit synthetischen Testgeometrien lassen sich solche Fehler oft nicht reproduzieren – Testdaten aus den Fixtures übernehmen (siehe `lines_test.dart`).
- **Wichtige Entscheidungen und ihre Gründe:** Silbentrennung ohne Wörterbuch: Ein Trennstrich bleibt, wenn das Dokument das Wort anderswo mit Bindestrich schreibt oder die Fortsetzung groß/nicht-alphabetisch beginnt; sonst wird er entfernt. Absatzfortsetzung nach Spalten-/Seitenwechsel nur, wenn die vorige Zeile nicht mit `.!?:` endet und die Schriftgröße passt. Die „kurze Zeile“-Regel greift nur nach Satzende (sonst Flattersatz-Fehler). Seitenrand-Regel nur für Mini-Zeilen (≤ 2 Glyphen), weil bestehende Tests kurze Zeilen bei x = 0 nutzen.
- **Auswirkungen auf Folge-Tasks:** Task 04: Listen mit hängendem Einzug zerfallen derzeit in zwei Blöcke („1. A measurement…“ / „that yields…“); Formelzeilen erscheinen als Textblöcke (`two_column_formulas`, Seite 2); Abbildungs-Beschriftungen in `two_column_figures` erzeugen Textmüll; Titel/Autoren verschmelzen teils zu einem Block. Bekannte Grenzen: abgesetzte Akzente (`supe´rieure`, `´` als eigener Block), Ligaturen teils als `i feld` extrahiert, mehr als zwei Spalten werden nicht unterstützt.
- **Hinweise zu Tests und Befehlen:** Regressionstests auf echten Daten in `tests/reflow_engine/corpus_test.dart` (Gruppe `corpus regressions`). Helfer `typesetLine` (realistische Glyphhöhen), `column`, `verticalText` in `tests/reflow_engine/helpers.dart`. Zum Untersuchen echter Daten: kurzzeitig einen Test anlegen, der `loadFixture(name)` lädt und Glyphen/Zeilen ausgibt (danach löschen).
