# paperflow

Open-Source-PDF-Reader für Android (MIT) mit Offline-eBook-Modus, der PDFs mit Textebene neu umbricht (Reflow). Flutter/Dart, pdfrx, Riverpod, drift; die Layout-Analyse liegt im reinen Dart-Paket `packages/reflow_engine/`.

## Oberste Regeln

1. **Test-Driven Development ist Pflicht.** Immer zuerst einen fehlschlagenden Test mit `flutter_test` (+ `mocktail`) schreiben, dann den minimalen Code, dann refaktorieren (Red, Green, Refactor). Kein Produktivcode ohne vorher fehlschlagenden Test. Bugfixes beginnen mit einem Test, der den Fehler reproduziert.
   - Bestehende Tests nie ändern, löschen oder abschwächen, um Grün zu erreichen. Schlägt ein Test fehl, wird die Implementierung korrigiert. Ist der Test selbst falsch, begründen und Freigabe einholen.
   - Engine-Snapshots nie neu erzeugen, nur damit ein Test grün wird (Regeln in `docs/testing.md`).
   - Reparaturbudget: höchstens 3 Versuche pro fehlschlagendem Test, danach anhalten und berichten (welche Tests, was versucht, Vermutung zur Ursache).
   - Führe zuerst die Tests aus, die zur Änderung gehören (Zuordnung in `docs/testing.md`); die komplette Suite nur bei Änderungen an `lib/core/`, `pubspec.yaml` oder gemeinsam genutztem Code.
2. **Dokumentation aktuell halten.** Ändert sich Tech-Stack, Architektur, Konventionen, Code-Style oder Testing, aktualisiere sofort im selben Arbeitsschritt die passende Datei in `docs/`. Eine Aufgabe ist erst erledigt, wenn `docs/` stimmt.
3. **Flutter-Werkzeuge verwenden.** Abhängigkeiten nur mit `flutter pub` (im Engine-Paket `dart pub`), Flutter-Kanal `stable`. Alle Tests liegen unter `tests/` (nicht `test/`); Testpfade daher immer explizit angeben.

## Befehle

```bash
flutter pub get                                        # Abhängigkeiten installieren
flutter test tests/app tests/reflow_engine             # alle Unit-/Widget-/Engine-Tests
flutter test tests/app/<pfad>_test.dart --plain-name "<testname>"   # einzelner Test
flutter test tests/integration -d <device-id>          # Integrationstests (Gerät/Emulator)
flutter analyze                                        # Lint
dart format .                                          # Format
flutter build apk --release                            # Release-Build
```

Integrationstests und APK-Builds brauchen das Android-SDK (`ANDROID_HOME`); Integrationstests zusätzlich ein Gerät oder einen Emulator.

## Dokumentation (bei Bedarf laden)

Lies nur die Dateien, die für deine aktuelle Aufgabe relevant sind:

- [docs/architecture.md](docs/architecture.md) – Lies das vor Strukturänderungen, neuen Komponenten oder Abhängigkeiten. Tech-Stack, Architektur, Reflow-Pipeline.
- [docs/testing.md](docs/testing.md) – Lies das, bevor du Tests schreibst oder die Test-Konfiguration änderst. Teststruktur, Snapshot-Regeln, Fertig-Kriterien.
- [docs/code-style.md](docs/code-style.md) – Lies das vor dem Schreiben oder Formatieren von Code. Styling und Formatierung.
- [docs/conventions.md](docs/conventions.md) – Lies das bei Benennung, Dateiorganisation oder Commits. Namenskonventionen und Best Practices.
- [docs/project-brief.md](docs/project-brief.md) – Lies das, wenn Ziel, Umfang oder Nicht-Ziele des Projekts unklar sind.

## Grenzen

- Keine Netzwerkzugriffe, keine Analytics oder Crash-Reporter: Die App ist komplett offline.
- Keine Abhängigkeit ohne MIT-kompatible Lizenz (kein GPL/AGPL, kein MuPDF). Neue Abhängigkeiten in `docs/architecture.md` eintragen.
- `packages/reflow_engine/` importiert nie Flutter oder pdfrx.
- Keine Signing-Schlüssel, `key.properties` oder Keystores committen.
- Keine Funktionen aus den Nicht-Zielen in `docs/project-brief.md` umsetzen (z. B. OCR, Cloud, Markierungen in die PDF schreiben).

## Roadmap

Arbeit an Roadmap-Tasks richtet sich nach [Roadmap/AGENTS.md](Roadmap/AGENTS.md); aktuelle Task-Dateien liegen in `Roadmap/Tasks/`.
