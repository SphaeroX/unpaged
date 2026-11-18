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

Diese Befehle sind festgelegt, aber erst nach dem Flutter-Gerüst (erster Implementierungsschritt) lauffähig; der erste Task prüft sie und korrigiert diese Datei bei Bedarf.

## Teststruktur

| Ordner | Inhalt | Regeln |
|---|---|---|
| `tests/app/` | Unit- und Widget-Tests der App, gespiegelt zu `lib/` (`lib/features/x/y.dart` → `tests/app/features/x/y_test.dart`) | Mocks mit mocktail; keine echten Dateisystem-/DB-Zugriffe außer drift in-memory |
| `tests/reflow_engine/` | Tests des Engine-Pakets, gespiegelt zu `packages/reflow_engine/lib/` | **Kein** Import von Flutter oder pdfrx |
| `tests/reflow_engine/corpus/` | Frei lizenzierte Test-PDFs + `SOURCES.md` (Quelle und Lizenz je Datei) | Nur Dateien mit nachgewiesener freier Lizenz |
| `tests/reflow_engine/snapshots/` | Erwartete Engine-Ergebnisse als JSON | Siehe Snapshot-Regeln |
| `tests/integration/` | `integration_test`-Abläufe (Import, Lesen, Moduswechsel) | Nur Kernabläufe |

- Dateinamen enden auf `_test.dart`.
- Flutter sucht standardmäßig in `test/`; deshalb werden Testpfade immer explizit übergeben (siehe Befehle). Einen Ordner `test/` gibt es nicht.
- Die App hängt per `path` von `packages/reflow_engine` ab, damit `tests/reflow_engine/` aus dem Root laufen kann.

## Snapshot-Regeln (Reflow-Engine)

- Snapshots werden **nie** neu erzeugt, nur damit ein Test wieder grün wird.
- Ein Snapshot darf nur geändert werden, wenn die Änderung eine bewusste, beschriebene Verbesserung der Engine ist; Grund und betroffene Dateien im Commit nennen und vorher Freigabe einholen.
- Wie die Engine-Tests ohne pdfrx an Zeichendaten kommen (z. B. aus den Korpus-PDFs extrahierte JSON-Fixtures), legt der Reflow-Spike fest und trägt es hier ein.

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
