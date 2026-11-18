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

1. [x] Mapping-Funktionen Seite ↔ Block per TDD (inklusive Seiten ohne Text, z. B. reine Abbildungsseiten).
2. [x] Lesestand-Speicherung pro Ansicht per TDD (DB-Migration für das neue Schema).
3. [x] Viewer und Reader an das Speichern/Wiederherstellen anbinden.
4. [x] Fortschrittsberechnung und Anzeige in der Bibliothek.
5. [x] Moduswechsel mit Sprung umsetzen.
6. [x] Rückfall nach Neuberechnung per TDD.
7. [x] Integrationstest: lesen, App schließen, Weiterlesen, Modus wechseln.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Seite 5 → erster Block mit Quellseite 5; Seite ohne Blöcke → nächster Block danach.
- Unit: Block mit Quellseite 7 → Originalseite 7.
- Unit: Gespeicherte Block-ID fehlt nach Neuberechnung → Sprung zur gespeicherten Quellseite.
- Unit: Fortschritt in Prozent für beide Ansichten.
- Widget/Integration: Weiterlesen öffnet die letzte Ansicht an der letzten Stelle.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [x] DB-Migration getestet (altes Schema → neues ohne Datenverlust).
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Aus Task_08: aktuelle `schemaVersion` ist 2 → neue Tabelle mit Version 3 und `if (from < 3)`-Schritt; `tests/app/core/database/migration_test.dart` erweitern.
- Aus Task_05: Datenbank `lib/core/database/app_database.dart` hat `schemaVersion` 1; neue Tabelle → Version erhöhen, `onUpgrade`-Schritt, Migrationstest. Widget-Tests: `TestEnv`/`settleIo` (siehe `docs/testing.md`).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 189 Tests grün; `flutter analyze` ohne Befund.
- Integrationstest „Weiterlesen“ in `tests/integration/ebook_flow_test.dart` ergänzt, **nicht ausgeführt** (kein Gerät).
- Vom Nutzer freigegebene Testanpassung (geplante Änderung): Die `pageView`-Stubs in `library_screen_test`, `viewer_flow_test` und `reader_screen_test` berücksichtigen die neuen benannten Parameter `initialPage`/`onPageChanged`; die Prüfabsicht ist unverändert.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** Lesestand pro Ansicht (Tabelle `ReadingPositions`, Schema v3, Migrationstests v1→v3 und v2→v3), Zuordnung Seite ↔ Block mit Rückfall auf die Seite, Speichern im Original (Seitenwechsel) und im eBook (oberster Block nach Scroll-Ende), Sprung beim Moduswechsel, Weiterlesen in der zuletzt genutzten Ansicht, Fortschritt in Prozent in der Bibliothek. Keine Fremdbibliothek für die Liste: `CustomScrollView` mit Mittel-Sliver.
- **Learnings & Stolpersteine:** `ScrollEndNotification` kommt vor dem Neu-Layout → die Position im nächsten Frame bestimmen (`addPostFrameCallback` + `scheduleFrame`). `dart fix --apply` hat beim Entfernen eines unnötigen `unawaited(...)` einen Syntaxfehler erzeugt – nach `dart fix` immer `flutter analyze` laufen lassen. mocktail: Stubs mit benannten Parametern brauchen `any(named: '…')` für jeden Parameter, sonst passt der Stub nicht.
- **Wichtige Entscheidungen und ihre Gründe:** Fortschritt wird beim Speichern berechnet und mitgespeichert (die Bibliothek muss das Reflow-Dokument nicht laden). Der Moduswechsel übergibt die Seite (`initialPage`); ohne Seite setzt der Reader an der gespeicherten Position fort.
- **Auswirkungen auf Folge-Tasks:** Task 10/11: nächste `schemaVersion` ist 4. `ReaderScreen` baut Blöcke über `_item(index)` mit `GlobalKey` pro Index – Markierungen im eBook (Task 11) brauchen auswählbaren Text (`SelectionArea`/`SelectableText`) in `_TextBlock`. Löschen eines Buchs (`ImportService.deleteBook`) muss auch Markierungen entfernen.
- **Hinweise zu Tests und Befehlen:** `tests/app/features/progress/reading_flow_test.dart` fängt den `onPageChanged`-Callback des gemockten Adapters ab und ruft ihn direkt auf, um Seitenwechsel zu simulieren.
