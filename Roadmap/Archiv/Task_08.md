# Task_08: Lese-Einstellungen

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_08.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Nutzer passen den eBook-Modus an: Schrift, Schriftgröße, Zeilenabstand und Theme (hell / dunkel / Sepia). Die Einstellungen werden dauerhaft gespeichert und sofort angewendet.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_07 archiviert.
- **Relevantes Vorwissen:** Reader aus Task_07; Theming in `lib/core/` (`docs/code-style.md`: keine Farbwerte direkt in Widgets); Feature `settings`.

## Umfang

**Gehört dazu:**

- Einstellungsmodell und Persistenz (drift oder geeigneter lokaler Speicher; Entscheidung dokumentieren)
- Auswahl aus einigen mitgelieferten, frei lizenzierten Schriften (z. B. OFL) plus Systemschrift; Lizenzen im Projekt ablegen
- Schriftgröße und Zeilenabstand in sinnvollen Stufen mit Grenzen
- Themes hell, dunkel, Sepia für den Reader; das Theme gilt auch für die restliche App (Sepia → hell oder eigene Variante, im Task entscheiden)
- Einstellungs-UI (z. B. Bottom-Sheet im Reader) mit Live-Vorschau
- Texte EN/DE

**Gehört nicht dazu:**

- Einstellungen für die Originalansicht außer dem Theme
- Eigene Schriften des Nutzers importieren

## Umsetzungsschritte

1. [x] Einstellungsmodell mit Defaults und Grenzen per TDD.
2. [x] Persistenz per TDD (Speichern, Laden, Defaults bei leerem Speicher).
3. [x] Themes in `lib/core/` definieren und per Widget-Test prüfen.
4. [x] Schriften einbinden, Lizenzdateien ablegen, in `docs/architecture.md` vermerken.
5. [x] Reader an die Einstellungen anbinden.
6. [x] Einstellungs-UI mit Live-Vorschau per Widget-Test.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Defaults, Grenzen (Schriftgröße nicht unter/über Limit), Persistenz-Roundtrip.
- Widget: Änderung der Schriftgröße wirkt sofort im Reader.
- Widget: Theme-Wechsel ändert Hinter- und Vordergrundfarbe des Readers.
- Unit/Widget: Einstellungen überstehen einen Neustart (neuer Provider-Container liest gespeicherte Werte).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/app` grün.
- [x] Lizenzen der mitgelieferten Schriften liegen im Repo und sind MIT-kompatibel (z. B. OFL).
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Welche Schriften mitgeliefert werden, entscheidet der Task (Annahme: 2–3 gut lesbare Serif/Sans-Schriften unter OFL).
- Aus Task_07: `ReaderScreen._TextBlock` bildet Stile aus `Theme.of(context).textTheme`; dort Schrift/Größe/Zeilenabstand anwenden. Schriften müssen offline im App-Bundle liegen (kein `google_fonts`-Download zur Laufzeit).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app` → 84 Tests grün (+ 84 Engine-Tests unverändert); `flutter analyze` ohne Befund.
- Schriften von `raw.githubusercontent.com/google/fonts` (OFL): Literata (variabel, Regular/Italic, ~1,8 MB) und Atkinson Hyperlegible (Regular/Bold/Italic). Lizenztexte unter `assets/fonts/*-OFL.txt`; Anzeige in der Lizenzseite folgt in Task 12.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** Einstellungsmodell mit Grenzen und robustem Laden, Speicherung in neuer Tabelle `Preferences` (Schema v2 inkl. Migration), `readerSettingsProvider`, App-Themes hell/dunkel/Sepia (Sepia für die ganze App), Einstellungs-Sheet im Reader mit Live-Vorschau, zwei gebündelte OFL-Schriften + Systemschrift.
- **Learnings & Stolpersteine:** `AsyncNotifier` hat bereits eine Methode `update` – eigene Methode deshalb `change`. Migrationstests: Rohdatenbank mit `sqlite3.openInMemory()` im Schema v1 anlegen, `userVersion = 1` setzen und mit `NativeDatabase.opened(raw)` öffnen.
- **Wichtige Entscheidungen und ihre Gründe:** Schlüssel/Wert-Tabelle statt eigener Einstellungsspalten, damit spätere Einstellungen ohne Schemaänderung dazukommen. Überschriften/Listen/Bildunterschriften skalieren relativ zur gewählten Schriftgröße.
- **Auswirkungen auf Folge-Tasks:** Task 09: nächste Schemaversion ist 3 (`if (from < 3)` in `onUpgrade`, Migrationstest erweitern). Task 12: OFL-Lizenzen der Schriften in die Lizenzseite (`LicenseRegistry.addLicense`) aufnehmen.
- **Hinweise zu Tests und Befehlen:** UI-Test der Einstellungen: `tests/app/features/settings/reader_settings_ui_test.dart` (Sheet über Tooltip „Reading settings“ öffnen).
