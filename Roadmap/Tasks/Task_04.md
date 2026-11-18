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

1. [ ] Fehlschlagende Snapshot-Tests für die Korpus-PDFs mit Tabellen, Formeln und Abbildungen anlegen (erwartete Typen und Bereiche von Hand prüfen).
2. [ ] Modell um Blocktyp und Bereichsblöcke erweitern (JSON-Roundtrip-Test).
3. [ ] Überschriften- und Listen-Erkennung per TDD.
4. [ ] Bildunterschriften-Erkennung per TDD.
5. [ ] Tabellen-, Formel- und Abbildungs-Heuristiken per TDD mit synthetischen Seiten.
6. [ ] Falls nötig: Adapter in `lib/core/` um Bild-/Linienobjekte erweitern (eigener Test), Engine bleibt pdfrx-frei.
7. [ ] Ältere Snapshots dürfen sich nur ändern, wo neue Typinformationen hinzukommen; jede Änderung begründen und Freigabe einholen (Snapshot-Regeln).
8. [ ] `engineVersion` erhöhen, Heuristiken und bekannte Grenzen dokumentieren.

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

- [ ] `flutter test tests/reflow_engine` grün.
- [ ] Jedes Korpus-Dokument mit Tabelle/Formel/Abbildung enthält im Snapshot mindestens einen Bereich des passenden Typs mit Seite und Bounding-Box.
- [ ] Änderungen an bestehenden Snapshots sind im Commit begründet und vom Nutzer freigegeben.
- [ ] `engineVersion` erhöht; `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Annahme: Fehlklassifikationen werden in Kauf genommen, solange kein Text verloren geht; im Zweifel lieber als Bildausschnitt.
- Ob pdfrx Bild- oder Linienobjekte liefert, ist offen; Ergebnis aus Task_02 prüfen.

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
