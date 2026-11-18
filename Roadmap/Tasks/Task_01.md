# Task_01: Durchstich: Flutter-Gerüst, DE/EN, PDF öffnen und im Original anzeigen

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_01.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Es gibt eine lauffähige Flutter-App mit deutscher und englischer Oberfläche, in der man über die Dateiauswahl eine PDF auswählt und sie in der Original-Seitenansicht (pdfrx) liest. Der Task belegt, dass Stack, Lint, l10n und die Teststruktur unter `tests/` zusammenpassen.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Keine (erster Task).
- **Relevantes Vorwissen:** Root-`AGENTS.md`; `docs/architecture.md` (Abschnitte Tech-Stack, Erster Implementierungsschritt); `docs/testing.md` (Teststruktur unter `tests/`, nicht `test/`); `docs/code-style.md`.

## Umfang

**Gehört dazu:**

- `flutter create --org dev.paperflow --project-name paperflow --platforms android .` und Entfernen des Standard-Ordners `test/`
- `minSdk 24`, `applicationId` vorläufig `dev.paperflow`
- Abhängigkeiten: `pdfrx`, `flutter_riverpod`, Datei-Auswahl-Paket (MIT-kompatibel), `very_good_analysis`, `mocktail`, `integration_test`; Lizenzen prüfen und in `docs/architecture.md` eintragen
- `analysis_options.yaml` mit very_good_analysis
- gen-l10n mit `app_en.arb` (Vorlage) und `app_de.arb`
- Grundgerüst `lib/core/` und `lib/features/viewer/` nach `docs/architecture.md`; PDF-Adapter-Schnittstelle in `lib/core/`, nur dort wird pdfrx importiert
- Startbildschirm mit Button „PDF öffnen“, danach Original-Seitenansicht der gewählten Datei (direkt aus dem gewählten Pfad, noch ohne Kopie)
- Fehlermeldung bei nicht lesbarer / beschädigter PDF

**Gehört nicht dazu:**

- Kopie in den App-Speicher, Hashing, Datenbank, Bibliothek (Task 05)
- Reflow / eBook-Modus (ab Task 02)
- Themes und Lese-Einstellungen (Task 08)
- „Öffnen mit“ / Teilen (Task 05)

## Umsetzungsschritte

1. [ ] Flutter-Gerüst erzeugen, `test/` entfernen, `minSdk` und `applicationId` setzen.
2. [ ] Abhängigkeiten hinzufügen, Lizenzen prüfen, `analysis_options.yaml` anlegen; `flutter analyze` muss ohne Befund laufen.
3. [ ] Ersten fehlschlagenden Widget-Test unter `tests/app/` schreiben (Startbildschirm zeigt lokalisierten Button) und prüfen, dass `flutter test tests/app` ihn findet.
4. [ ] l10n einrichten (EN-Vorlage, DE), App-Shell mit Riverpod (`ProviderScope`) bauen.
5. [ ] PDF-Adapter-Schnittstelle in `lib/core/` definieren (TDD mit Mock), pdfrx-Implementierung dahinter.
6. [ ] Dateiauswahl → Viewer-Bildschirm mit pdfrx-Seitenansicht; Fehlerfall anzeigen.
7. [ ] Integrationstest unter `tests/integration/`: App startet, Viewer zeigt eine mitgelieferte Test-PDF (Datei-Dialog im Test umgehen, z. B. über überschreibbaren Provider).
8. [ ] Befehle aus Root-`AGENTS.md` und `docs/testing.md` real ausführen und dort korrigieren, falls etwas abweicht.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Widget-Test: Startbildschirm zeigt den Button in EN und DE (Locale umschalten).
- Unit-Test: Viewer-Logik ruft den PDF-Adapter mit dem gewählten Pfad auf (Adapter gemockt).
- Widget-Test: Bei Adapter-Fehler erscheint eine lokalisierte Fehlermeldung statt eines Absturzes.
- Integrationstest: Eine kleine Test-PDF wird geöffnet und die erste Seite gerendert.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app` läuft grün; es gibt keinen Ordner `test/`.
- [ ] `flutter analyze` ohne Befund, `dart format --output=none --set-exit-if-changed .` mit Exit-Code 0.
- [ ] `flutter build apk --debug` erfolgreich.
- [ ] Integrationstest grün auf einem Emulator/Gerät, oder – falls keines verfügbar – im Task ausdrücklich als nicht ausgeführt vermerkt und dem Nutzer gemeldet.
- [ ] pdfrx wird ausschließlich in `lib/core/` importiert (`grep -r "package:pdfrx" lib/` zeigt nur Treffer dort).
- [ ] Alle neuen Abhängigkeiten mit Lizenz in `docs/architecture.md` eingetragen.

## Offene Fragen / Annahmen

- In der Cloud-Umgebung, in der die Roadmap angelegt wurde, war kein Flutter-SDK installiert; ggf. zuerst Flutter (stable) installieren.
- Annahme: Ein Android-Emulator ist für Integrationstests nicht in jeder Umgebung verfügbar; dann gilt das Vorgehen aus den Akzeptanzkriterien.

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
