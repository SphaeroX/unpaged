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

1. [ ] Fehlschlagende Snapshot-Tests für den Zweispalter im Korpus anlegen (erwartete Reihenfolge von Hand prüfen).
2. [ ] Spaltenerkennung per TDD mit synthetischen Seiten entwickeln (eine, zwei Spalten, gemischt).
3. [ ] Lesereihenfolge implementieren.
4. [ ] Kopf-/Fußzeilen- und Seitenzahl-Erkennung per TDD (synthetisches Mehrseiten-Dokument).
5. [ ] Silbentrennung per TDD inklusive Gegenbeispielen mit echten Bindestrichen.
6. [ ] Absatz-Fortsetzung über Spalten- und Seitengrenzen.
7. [ ] Bestehende Einspalter-Snapshots müssen unverändert grün bleiben; sonst Ursache in der Implementierung suchen.
8. [ ] `engineVersion` erhöhen, Erkenntnisse zu Heuristiken und Schwellwerten dokumentieren.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Zweispaltige Seite → linke Spalte vollständig vor rechter.
- Unit: Gemischte Seite (Titel über volle Breite, darunter zwei Spalten) → Titel zuerst.
- Unit: Wiederholte Zeile oben/unten auf ≥ 3 Seiten wird entfernt; einmaliger Text an ähnlicher Position bleibt.
- Unit: „Infor-“ + „mation“ → „Information“; „Offline-“ am Zeilenende + „Modus“ bleibt „Offline-Modus“ nur wenn der Bindestrich echt ist (Heuristik dokumentieren).
- Snapshot: Zweispalter aus dem Korpus in korrekter Reihenfolge, ohne Kopf-/Fußzeilen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/reflow_engine` grün, inklusive neuer Zweispalter-Snapshots und unveränderter Snapshots aus Task_02.
- [ ] Im Zweispalter-Snapshot kommen keine Seitenzahlen und keine laufenden Kopfzeilen vor.
- [ ] `engineVersion` ist höher als nach Task_02.
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Annahme: Schwellwerte für Spaltenlücken und Wiederholungserkennung werden empirisch am Korpus bestimmt und im Task dokumentiert.
- Unklar, wie gut sich echte von Trenn-Bindestrichen ohne Wörterbuch unterscheiden lassen; ein Wörterbuch wäre eine neue Abhängigkeit und braucht Rückfrage.

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
