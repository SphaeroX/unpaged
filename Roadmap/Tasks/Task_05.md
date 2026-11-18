# Task_05: Bibliothek & Import

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_05.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Importierte PDFs landen als eigene Kopie im App-Speicher und erscheinen in einer persistenten Bibliothek. Import funktioniert über die Dateiauswahl, „Öffnen mit“ und „Teilen“; Duplikate werden erkannt, Bücher lassen sich löschen. Ab hier öffnet der Viewer Bücher aus der Bibliothek.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_01 archiviert (Task_02–04 sind unabhängig, aber nach Reihenfolge bereits erledigt).
- **Relevantes Vorwissen:** `docs/architecture.md` (Pipeline Schritt 1: `books/<sha256>.pdf`, Hash = Dokument-ID); `docs/conventions.md`; Features `library` und `import`.

## Umfang

**Gehört dazu:**

- drift-Datenbank in `lib/core/` mit Tabelle für Bücher (ID = SHA-256, Titel aus PDF-Metadaten oder Dateiname, Seitenzahl, Importdatum, Reflow-Status-Feld für Task 06) und Migrationsstrategie
- Import-Service: Datei lesen, SHA-256 berechnen, nach `books/<sha256>.pdf` kopieren, Eintrag anlegen
- Duplikaterkennung: gleicher Hash → kein zweiter Eintrag, Hinweis an den Nutzer und Öffnen des vorhandenen Buchs
- Bibliotheksansicht mit Liste (Titel, Seitenzahl), leerem Zustand und Import-Button
- Löschen mit Bestätigungsdialog: entfernt DB-Eintrag und Datei
- Android-Intents für „Öffnen mit“ (`ACTION_VIEW`, `application/pdf`) und „Teilen“ (`ACTION_SEND`) inklusive `content://`-URIs
- Alle Texte in EN/DE

**Gehört nicht dazu:**

- Reflow-Berechnung und Fortschrittsanzeige (Task 06)
- Lesestand (Task 09)
- Ordner automatisch überwachen (Nicht-Ziel)

## Umsetzungsschritte

1. [ ] drift einrichten (Codegenerierung nur für drift erlaubt), Schema per TDD mit In-Memory-Datenbank.
2. [ ] Hashing- und Kopier-Logik per TDD (Dateisystem über Abstraktion mockbar).
3. [ ] Import-Service inklusive Duplikat- und Fehlerfällen (unlesbare Datei, keine PDF) per TDD.
4. [ ] Bibliotheksansicht und Löschen mit Riverpod per Widget-Tests.
5. [ ] Viewer aus Task_01 auf Bücher aus der Bibliothek umstellen.
6. [ ] Intent-Handling für „Öffnen mit“ und „Teilen“ einbauen (MIT-kompatibles Paket oder eigener Platform-Channel), Lizenz eintragen.
7. [ ] Integrationstest: Import über Dateiauswahl-Ersatz → Eintrag in Bibliothek → Öffnen → Löschen.
8. [ ] `docs/architecture.md` um DB-Schema-Hinweise und Abhängigkeiten ergänzen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Gleiche Datei zweimal importiert → ein Eintrag, zweiter Import meldet Duplikat.
- Unit: Kopie liegt unter `books/<sha256>.pdf`, Hash stimmt.
- Unit: Löschen entfernt Datei und Eintrag; fehlende Datei beim Löschen führt nicht zum Absturz.
- Unit: Nicht-PDF oder beschädigte Datei → lokalisierte Fehlermeldung, kein Eintrag.
- Widget: leerer Zustand, Liste, Bestätigungsdialog beim Löschen.
- Integration: Import → Bibliothek → Öffnen → Löschen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app` grün; Integrationstest grün oder (ohne Gerät) begründet als nicht ausgeführt vermerkt.
- [ ] Manuell auf Gerät/Emulator geprüft und im Task notiert: PDF über „Öffnen mit“ aus einem Dateimanager und über „Teilen“ landet in der Bibliothek.
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Welches Paket für Intents genutzt wird (oder eigener Platform-Channel), entscheidet der Task nach Lizenzprüfung.
- Aus Task_01: `file_picker` liefert auf Android ggf. `content://`-URIs, dann ist `PlatformFile.path` `null`. Der Import muss deshalb über Bytes/Streams (z. B. `PlatformFile.xFile`) kopieren; `PdfPicker` entsprechend umbauen.

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
