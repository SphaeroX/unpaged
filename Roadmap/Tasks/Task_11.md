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

1. [ ] Modell-Erweiterung und Migration per TDD.
2. [ ] Neuverankerungs-Algorithmus als reine Funktion per TDD (exakter Treffer, verschobener Block, geänderter Umbruch, mehrdeutiges Zitat → Kontext entscheidet, nicht auffindbar).
3. [ ] Auswahl und Hervorhebung im Reader.
4. [ ] Notiz-UI und Übersicht anbinden, verwaiste Markierungen kennzeichnen.
5. [ ] Neuverankerung beim Laden nach Neuberechnung auslösen und Ergebnis speichern.
6. [ ] Integrationstest: markieren, `engineVersion` künstlich erhöhen/neu berechnen, Markierung sitzt wieder an der richtigen Stelle.

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

- [ ] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [ ] Markierungen aus Task_10 (Original) bleiben unverändert (bestehende Tests grün).
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Annahme: Markierungen über Blockgrenzen hinweg werden auf einen Block begrenzt oder in mehrere Teile zerlegt; der Task entscheidet und dokumentiert.

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
