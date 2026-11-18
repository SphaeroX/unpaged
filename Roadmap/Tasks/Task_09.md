# Task_09: Lesestand

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_09.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die App merkt sich pro Buch und pro Ansicht, wo man aufgehört hat. Die Bibliothek zeigt den Fortschritt und öffnet Bücher zum Weiterlesen an der letzten Stelle. Beim Wechsel zwischen Original und eBook springt die App über die Quellseite des Blocks an die passende Stelle.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_07 archiviert (Task_08 nach Reihenfolge erledigt; Schriftgröße beeinflusst die Scrollposition, deshalb blockbasiert speichern).
- **Relevantes Vorwissen:** `docs/architecture.md` (Markierungen und Lesestand); `ReflowDocument` mit Block-ID und Quellseite; DB aus Task_05.

## Umfang

**Gehört dazu:**

- Lesestand Original: Seite (+ Position innerhalb der Seite)
- Lesestand eBook: Block-ID (+ Offset), unabhängig von Schriftgröße und Theme
- Speichern bei Scroll-Ende/Verlassen des Bildschirms (gedrosselt)
- Fortschritt in Prozent in der Bibliothek; „Weiterlesen“ öffnet die zuletzt genutzte Ansicht an der gespeicherten Stelle
- Moduswechsel: Original-Seite → erster Block mit dieser Quellseite; eBook-Block → dessen Quellseite
- Verhalten nach Neuberechnung (neue `engineVersion`): Block-ID nicht mehr vorhanden → Rückfall auf Quellseite

**Gehört nicht dazu:**

- Synchronisation zwischen Geräten (Nicht-Ziel)
- Lesezeichen-Liste

## Umsetzungsschritte

1. [ ] Mapping-Funktionen Seite ↔ Block per TDD (inklusive Seiten ohne Text, z. B. reine Abbildungsseiten).
2. [ ] Lesestand-Speicherung pro Ansicht per TDD (DB-Migration für das neue Schema).
3. [ ] Viewer und Reader an das Speichern/Wiederherstellen anbinden.
4. [ ] Fortschrittsberechnung und Anzeige in der Bibliothek.
5. [ ] Moduswechsel mit Sprung umsetzen.
6. [ ] Rückfall nach Neuberechnung per TDD.
7. [ ] Integrationstest: lesen, App schließen, Weiterlesen, Modus wechseln.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Seite 5 → erster Block mit Quellseite 5; Seite ohne Blöcke → nächster Block danach.
- Unit: Block mit Quellseite 7 → Originalseite 7.
- Unit: Gespeicherte Block-ID fehlt nach Neuberechnung → Sprung zur gespeicherten Quellseite.
- Unit: Fortschritt in Prozent für beide Ansichten.
- Widget/Integration: Weiterlesen öffnet die letzte Ansicht an der letzten Stelle.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [ ] DB-Migration getestet (altes Schema → neues ohne Datenverlust).
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Aus Task_08: aktuelle `schemaVersion` ist 2 → neue Tabelle mit Version 3 und `if (from < 3)`-Schritt; `tests/app/core/database/migration_test.dart` erweitern.
- Aus Task_05: Datenbank `lib/core/database/app_database.dart` hat `schemaVersion` 1; neue Tabelle → Version erhöhen, `onUpgrade`-Schritt, Migrationstest. Widget-Tests: `TestEnv`/`settleIo` (siehe `docs/testing.md`).

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
