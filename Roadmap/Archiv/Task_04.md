# Task_04: Blocktypen & Nicht-Text-Bereiche

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_04.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die Engine bestimmt den Typ jedes Blocks (Überschrift, Absatz, Liste, Bildunterschrift) und markiert Tabellen, Abbildungen und Formeln als Bereiche, die später als Bildausschnitt erscheinen. Damit ist das `ReflowDocument` inhaltlich vollständig für die Leseansicht.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_03 archiviert.
- **Relevantes Vorwissen:** Engine aus Task_02/03; Architektur-Entscheidung: Tabellen/Formeln/Abbildungen werden nie als Text nachgebaut, sondern als Bereich (Seite + Bounding-Box) markiert (`docs/project-brief.md`, Nicht-Ziele).

## Umfang

**Gehört dazu:**

- Blocktyp-Erkennung: Überschrift (Schriftgröße/-gewicht relativ zum Fließtext, Ebene), Absatz, Liste (Aufzählungszeichen, Nummerierung), Bildunterschrift („Abb.“, „Figure“, „Table“, „Tab.“ o. ä. nahe einem Bereich)
- Bereichstyp im Modell: `table`, `figure`, `formula` mit Quellseite und Bounding-Box; Platzhalter-Block in der Lesereihenfolge an der richtigen Stelle
- Heuristiken für Tabellen (rasterartige Textanordnung, ggf. Linien), Formeln (hoher Anteil mathematischer Zeichen, abweichende Schriften, zentrierte Einzelzeilen), Abbildungen (Seitenflächen ohne Text, die von einer Bildunterschrift begleitet werden; ggf. Bildobjekte aus pdfrx, falls der Adapter sie liefert)
- Text innerhalb markierter Bereiche erscheint nicht zusätzlich als Fließtext
- `engineVersion` erhöhen

**Gehört nicht dazu:**

- Rendern der PNG-Ausschnitte (Task 06, braucht pdfrx)
- Darstellung in der App (Task 07)
- Tabellen als echten Text nachbauen (Nicht-Ziel)

## Umsetzungsschritte

1. [x] Fehlschlagende Snapshot-Tests für die Korpus-PDFs mit Tabellen, Formeln und Abbildungen anlegen (erwartete Typen und Bereiche von Hand prüfen).
2. [x] Modell um Blocktyp und Bereichsblöcke erweitern (JSON-Roundtrip-Test).
3. [x] Überschriften- und Listen-Erkennung per TDD.
4. [x] Bildunterschriften-Erkennung per TDD.
5. [x] Tabellen-, Formel- und Abbildungs-Heuristiken per TDD mit synthetischen Seiten.
6. [x] Falls nötig: Adapter in `lib/core/` um Bild-/Linienobjekte erweitern (eigener Test), Engine bleibt pdfrx-frei.
7. [x] Ältere Snapshots dürfen sich nur ändern, wo neue Typinformationen hinzukommen; jede Änderung begründen und Freigabe einholen (Snapshot-Regeln).
8. [x] `engineVersion` erhöhen, Heuristiken und bekannte Grenzen dokumentieren.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Zeile mit deutlich größerer Schrift vor Fließtext → Überschrift mit Ebene.
- Unit: Zeilen mit „•“, „–“, „1.“, „a)“ am Anfang → Listeneinträge.
- Unit: „Figure 3:“ unter einem textfreien Bereich → Bildunterschrift + Abbildungsbereich.
- Unit: Rasterartig angeordnete kurze Textstücke → Tabellenbereich, deren Text nicht im Fließtext.
- Unit: Zentrierte Zeile mit hohem Anteil mathematischer Zeichen → Formelbereich.
- Snapshot: Korpus-PDFs mit Tabellen, Formeln, Abbildungen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/reflow_engine` grün.
- [x] Jedes Korpus-Dokument mit Tabelle/Formel/Abbildung enthält im Snapshot mindestens einen Bereich des passenden Typs mit Seite und Bounding-Box.
- [x] Änderungen an bestehenden Snapshots sind im Commit begründet und vom Nutzer freigegeben.
- [x] `engineVersion` erhöht; `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Annahme: Fehlklassifikationen werden in Kauf genommen, solange kein Text verloren geht; im Zweifel lieber als Bildausschnitt.
- Aus Task_03: Listeneinträge mit hängendem Einzug zerfallen derzeit in zwei Absätze (Einzugsregel in `paragraphs.dart`); Formelzeilen erscheinen als Textblöcke (`two_column_formulas`, ab Seite 2); Beschriftungen in Abbildungen erzeugen Textmüll (`two_column_figures`, `single_column_tables`). `two_column_figures` und `single_column_tables` haben noch keinen Snapshot. Snapshot-Änderungen aus den geplanten Verbesserungen von Task 04 sind vom Nutzer pauschal freigegeben (von Hand prüfen, im Commit begründen, am Ende auflisten).
- pdfrx 3 bietet in der öffentlichen API keine Bild- oder Linienobjekte (Stand Task_01); Abbildungen müssen daher über textfreie Flächen + Bildunterschrift erkannt werden, sofern Task_02 nichts anderes herausfindet.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 108 Tests grün (Engine 84); `flutter analyze` ohne Befund.
- Snapshot-Änderungen (vom Nutzer pauschal freigegeben, von Hand geprüft): alle bestehenden Snapshots (Blocktypen, `level`, Bereiche, `engineVersion` 3); neu: `two_column_figures`, `single_column_tables`. Bereiche je Dokument: `two_column_tables` 1 Tabelle, `single_column_tables` 2 Tabellen + 1 Formel, `two_column_figures` 1 Abbildung + 7 Formeln, `two_column_formulas` 27 Formeln.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** `BlockType` um `heading`, `listItem`, `caption`, `table`, `figure`, `formula` erweitert, `ReflowBlock.level` (nur Überschriften, im JSON weggelassen wenn `null`). Neue Dateien: `text_patterns.dart` (Bildunterschrift, Listenmarker, nummerierte Überschrift, Abschnittswörter, Formel-Heuristik), `regions.dart` (Erkennung der Bereiche), `classify.dart` (Blocktyp/Ebene). `paragraphs.dart` verarbeitet jetzt `FlowItem`s (Zeilen + Bereiche) und liefert `Draft`s. `engineVersion` 3. Zusätzlich: Schriftgröße nur noch aus Buchstaben/Ziffern geschätzt (Klammern und Formelzeichen sind höher), zentrierte Titelzeilen gelten nicht als Einzug, erwarteter Zeilenabstand ≥ 1,6 × Schriftgröße.
- **Learnings & Stolpersteine:** Gleichungsnummern dürfen nur an die nächstgelegene Formel links von ihnen gehängt werden – sonst entsteht ein Formelbereich über beide Spalten, der als „spannende“ Zeile die Lesereihenfolge der ganzen Seite zerstört. Bündig gesetzte Fließtextzeilen mit Chemie-/Einheitenformeln („∼ 1 × 10²⁰ cm⁻³“) sehen wie Formeln aus → Regel „bündig mit Prosa-Nachbarn = Prosa“. Titel können > 20 Wörter und mehrere Zeilenstücke haben. Bereiche nehmen an der Lesereihenfolge als Platzhalter-`TextLine` mit einer Glyphe `\u0001` teil.
- **Wichtige Entscheidungen und ihre Gründe:** Abbildungsbereich = Fläche zwischen Bildunterschrift und nächster Prosazeile darüber (bei Tabellen-Bildunterschriften darunter) in der Spalte der Bildunterschrift, inklusive aller Beschriftungszeilen darin; Prosa = ≥ 6 echte Wörter. Tabellen = ≥ 3 Zeilen mit je ≥ 3 kurzen Zellen, dann um angrenzende Nicht-Prosa-Zeilen erweitert. Überschriften: größere Schrift (≥ 1,15× Fließtext, Ebene nach Größenrang), nummerierte Überschriften (Ebene = Tiefe + 1; „1.“ mit Punkt nur bis 5 Wörter, sonst Liste) und Abschnittswörter (Abstract, References …). Ein Absatz läuft über Abbildung/Tabelle/Bildunterschrift weiter, wenn der Satz unvollendet ist; vor einer Formel endet er.
- **Auswirkungen auf Folge-Tasks:** Task 06: Bereichsblöcke haben `text == ''`, Seite und Box (Top-down-Punkte) → daraus PNG-Ausschnitte rendern (pdfrx `render` mit x/y/width/height, PDF-Koordinaten beachten). Task 07: Darstellung je `BlockType`; `level` für Überschriftenstil. Task 11: Markierungen nur auf Textblöcken (nicht `isRegion`). Bekannte Grenzen: Titel und Autoren verschmelzen teils zu einem Absatz (`single_column_text`), Mathe-Schriften ohne Unicode-Zuordnung ergeben `�`, überlappende Bruchzeilen bleiben teils als Textmüll.
- **Hinweise zu Tests und Befehlen:** Unit-Tests der Blocktypen in `tests/reflow_engine/src/block_types_test.dart` (Helfer `prose()`, `typed()`), Mustertests indirekt darüber. Für Korpus-Analysen hat sich ein temporärer Dump-Test bewährt, der für jedes Fixture `id typ box | text` in eine Datei schreibt.
