# Testing-Strategie

> Wann lesen: bevor du Tests schreibst oder die Test-Konfiguration änderst.

## Testing-Suite

- `flutter_test` + `mocktail` für Unit- und Widget-Tests: Flutter-Standard, schneller Einzellauf, mocktail braucht keine Codegenerierung.
- `integration_test` für Kernabläufe auf Gerät/Emulator.
- Snapshot-Tests für `reflow_engine`: Ergebnis gegen gespeicherte JSON-Snapshots eines Korpus frei lizenzierter Test-PDFs.

## TDD-Ablauf (verbindlich)

1. Red: Test schreiben, ausführen, Fehlschlag prüfen.
2. Green: minimalen Code schreiben, bis der Test besteht.
3. Refactor: aufräumen, Tests bleiben grün.

## Befehle

Alle Befehle im Projekt-Root.

```bash
flutter test tests/app tests/reflow_engine            # alle Unit-/Widget-/Engine-Tests
flutter test tests/app/<pfad>_test.dart               # einzelne Datei
flutter test tests/app/<pfad>_test.dart --plain-name "<testname>"   # einzelner Test
flutter test tests/integration -d <device-id>         # Integrationstests (Gerät/Emulator nötig)
flutter test --coverage tests/app tests/reflow_engine # mit Coverage
```

Unit-, Widget- und Engine-Tests laufen auf dem Host ohne Gerät. Integrationstests brauchen ein Android-Gerät oder einen Emulator.

## Teststruktur

| Ordner | Inhalt | Regeln |
|---|---|---|
| `tests/app/` | Unit- und Widget-Tests der App, gespiegelt zu `lib/` (`lib/features/x/y.dart` → `tests/app/features/x/y_test.dart`) | Mocks mit mocktail; keine echten Dateisystem-/DB-Zugriffe außer drift in-memory |
| `tests/reflow_engine/` | Tests des Engine-Pakets, gespiegelt zu `packages/reflow_engine/lib/` | **Kein** Import von Flutter oder pdfrx |
| `tests/reflow_engine/corpus/` | Frei lizenzierte Test-PDFs + `SOURCES.md` (Quelle und Lizenz je Datei) | Nur Dateien mit nachgewiesener freier Lizenz |
| `tests/reflow_engine/snapshots/` | Erwartete Engine-Ergebnisse als JSON | Siehe Snapshot-Regeln |
| `tests/app/helpers/` | Gemeinsame Test-Hilfen (z. B. `buildTestApp` mit Provider-Overrides) | – |
| `tests/fixtures/` | Kleine, selbst erzeugte PDFs für App-Tests (keine Fremdlizenzen) | Pfade relativ zum Projekt-Root |
| `tests/integration/` | `integration_test`-Abläufe (Import, Lesen, Moduswechsel) | Nur Kernabläufe |

- Dateinamen enden auf `_test.dart`.
- Flutter sucht standardmäßig in `test/`; deshalb werden Testpfade immer explizit übergeben (siehe Befehle). Einen Ordner `test/` gibt es nicht.
- Die App hängt per `path` von `packages/reflow_engine` ab, damit `tests/reflow_engine/` aus dem Root laufen kann.

## Muster

- Abhängigkeiten werden über Riverpod-Provider ersetzt (`provider.overrideWithValue(mock)`), nie über globale Variablen.
- Der echte pdfrx-Adapter wird auf dem Host gegen echte PDFs getestet; PDFium wird beim ersten `flutter test` automatisch als Native Asset geladen. Initialisierung im Test: `setUpAll(() => pdfrxInitialize(tmpPath: Directory.systemTemp.path))`.
- Integrationstests binden Test-PDFs inline (Base64) ein, damit keine Test-Assets ins App-Bundle gelangen.
- Widget-Tests mit Datenbank/Dateien: `TestEnv` aus `tests/app/helpers/test_env.dart` (In-Memory-drift + Temp-Verzeichnis, `env.overrides`). Echte Datei-I/O läuft im Fake-Async-Kontext nicht von selbst → nach Aktionen `await settleIo(tester)`. Am Ende jedes Widget-Tests `await env.unmount(tester)` (drift-Stream-Timer laufen aus), im `tearDown` `env.dispose()` (wartet bewusst nicht auf drift, sonst hängt der Test).
- Nach Änderungen an drift-Tabellen: `dart run build_runner build --delete-conflicting-outputs`; die erzeugte `*.g.dart` wird eingecheckt.

## Snapshot-Regeln (Reflow-Engine)

- Snapshots werden **nie** neu erzeugt, nur damit ein Test wieder grün wird.
- Ein Snapshot darf nur geändert werden, wenn die Änderung eine bewusste, beschriebene Verbesserung der Engine ist; Grund und betroffene Dateien im Commit nennen und vorher Freigabe einholen.
- Snapshot-Dokumente sind in `tests/reflow_engine/snapshot_test.dart` (`snapshotDocuments`) explizit aufgelistet; ein Dokument kommt erst dazu, wenn die Engine sein Layout beherrscht. Fehlende Snapshots erzeugt nur `UPDATE_SNAPSHOTS=1 flutter test tests/reflow_engine/snapshot_test.dart` (bestehende werden dabei nie überschrieben); das Ergebnis wird von Hand geprüft.

## Zeichendaten für Engine-Tests (Fixtures)

- Die Engine-Tests laufen ohne pdfrx. Ihre Eingabe sind JSON-Fixtures `tests/reflow_engine/fixtures/<name>.json` (`DocumentInput`), die der echte pdfrx-Adapter aus `tests/reflow_engine/corpus/<name>.pdf` erzeugt.
- `tests/app/core/pdf/corpus_fixtures_test.dart` prüft, dass Fixtures und Adapter-Ausgabe übereinstimmen. Nach einer **bewussten** Adapter-Änderung: `UPDATE_FIXTURES=1 flutter test tests/app/core/pdf/corpus_fixtures_test.dart`, danach Engine-Tests laufen lassen. Fixtures sind Eingabedaten, keine Snapshots.
- Neue Korpus-PDF: Datei ablegen, Quelle und Lizenz in `tests/reflow_engine/corpus/SOURCES.md` eintragen, Fixture erzeugen. Synthetische PDFs entstehen mit `tests/reflow_engine/corpus/tool/generate_synthetic.py` (fpdf2, Anleitung im Skript).

## Welche Tests wann ausführen

- Änderung in `packages/reflow_engine/` → `flutter test tests/reflow_engine`
- Änderung in `lib/features/<x>/` → `flutter test tests/app/features/<x>`
- Änderung in `lib/core/` oder an `pubspec.yaml` → alle Unit-Tests; zusätzlich Integrationstests, wenn ein Gerät verfügbar ist

## Fertig-Kriterien

Eine Aufgabe ist fertig, wenn mechanisch prüfbar gilt:

1. Tests des betroffenen Bereichs laufen grün (Befehle oben).
2. `flutter analyze` meldet keine Probleme.
3. `dart format --output=none --set-exit-if-changed .` endet mit Exit-Code 0.
4. Kein bestehender Test und kein Snapshot wurde geändert, gelöscht oder abgeschwächt (außer ausdrücklich beauftragt).

## Harte Regeln

- Bei fehlschlagendem Test wird die Implementierung korrigiert, nicht der Test.
- Höchstens 3 Reparaturversuche pro fehlschlagendem Test; danach anhalten und berichten.
- Muss ein bestehender Test geändert werden: Grund nennen und Freigabe abwarten.

---
Pflege: Bei Änderungen an Testing-Suite oder -Strategie diese Datei sofort aktualisieren.
