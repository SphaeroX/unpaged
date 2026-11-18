# Tech-Stack und Architektur

> Wann lesen: vor Strukturänderungen, neuen Komponenten, neuen Abhängigkeiten.

## Tech-Stack

| Bereich | Entscheidung | Grund |
|---|---|---|
| Sprache / Framework | Dart, Flutter (Kanal `stable`) | Eine Codebasis, iOS später ohne Neuschreiben möglich |
| PDF-Engine | `pdfrx` (PDFium) | Rendert Seiten und liefert Text mit Position jedes Zeichens; MIT-kompatibel |
| State Management | Riverpod **ohne** Codegenerierung | Testbar, kein build_runner für Provider |
| Datenbank | `drift` (SQLite) | Typsicher, Migrationen, offline |
| Lokalisierung | Flutter `gen-l10n`, ARB-Dateien EN (Vorlage) + DE | Standardweg von Flutter |
| Tests | `flutter_test`, `mocktail`, `integration_test` | Siehe `docs/testing.md` |
| Lint / Format | `very_good_analysis`, `flutter analyze`, `dart format` | Siehe `docs/code-style.md` |

### Abhängigkeiten und Lizenzen

| Paket | Zweck | Lizenz |
|---|---|---|
| `material_ui` | Material-Widgets (seit Flutter 3.50 eigenes Paket, nicht mehr `package:flutter/material.dart`) | BSD-3-Clause |
| `pdfrx` / `pdfrx_engine` (bringt `pdfium_dart`/`pdfium_flutter` mit) | PDF-Rendering und Text; PDFium wird als Native Asset gebündelt | MIT (PDFium: BSD-3-Clause/Apache-2.0) |
| `flutter_riverpod` | State Management | MIT |
| `file_picker` | Dateiauswahl | MIT |
| `intl`, `flutter_localizations` | l10n | BSD-3-Clause |
| `very_good_analysis` (dev) | Lint-Regeln | MIT |
| `mocktail` (dev) | Mocks | MIT |
| `integration_test`, `flutter_test` (dev) | Tests | BSD-3-Clause |

## Verbindliche Rahmenbedingungen

- **Komplett offline.** Keine Netzwerkzugriffe, keine Analytics, keine Crash-Reporter; es verlassen keine Daten das Gerät.
- **Lizenzen:** Jede Abhängigkeit muss MIT-kompatibel sein (MIT, BSD, Apache-2.0, Zlib o. ä.). Kein GPL/AGPL, daher kein MuPDF. Neue Abhängigkeit → Lizenz prüfen und hier eintragen.
- **Android zuerst**, `minSdk 24`. Code bleibt plattformneutral (keine Android-only-APIs außerhalb von Plattform-Adaptern).

## Architektur

- `lib/features/<feature>/` mit `data/`, `domain/`, `presentation/`. Features: `library`, `import`, `viewer` (Original), `reader` (eBook), `annotations`, `settings`.
- `lib/core/`: Datenbank, PDF-Adapter (einzige Stelle, die `pdfrx` importiert), Dateiablage, Theming, l10n.
- `packages/reflow_engine/`: **reines Dart-Paket ohne Flutter und ohne pdfrx.** Enthält die gesamte Layout-Analyse. Eingabe: Zeichen mit Position und Schriftgröße pro Seite; Ausgabe: `ReflowDocument`. Die App bindet es per `path`-Abhängigkeit ein.

### Reflow-Pipeline (beim Import, offline)

1. PDF in den App-Speicher kopieren: `books/<sha256>.pdf`. Der SHA-256 ist Dokument-ID und Duplikat-Schlüssel.
2. Adapter (`lib/core`) liest pro Seite Zeichen mit Position und Schriftgröße über pdfrx.
3. Engine: Zeichen → Zeilen → Blöcke; Spalten und Lesereihenfolge erkennen, Kopf-/Fußzeilen und Seitenzahlen entfernen, Silbentrennung auflösen, Blocktyp bestimmen (Überschrift, Absatz, Liste, Bildunterschrift).
4. Tabellen, Abbildungen, Formeln als Bereiche markieren und einmalig als PNG-Ausschnitt rendern.
5. `ReflowDocument` als JSON speichern, mit `engineVersion`. Ändert sich die Engine-Version, bei Bedarf neu berechnen.
6. Verarbeitung im Hintergrund-Isolate; Fortschritt in der Bibliothek sichtbar.

### Markierungen und Lesestand

- Original: verankert an Seite + Zeichenbereich.
- eBook: verankert an Block-ID + Offset, zusätzlich Textzitat mit Kontext, damit sie nach Neuberechnung wieder zugeordnet werden können.
- Lesestand pro Ansicht; beim Wechsel springt die App über die Quellseite des Blocks an die passende Stelle.
- Markierungen werden nur in der App-Datenbank gespeichert, nie in die PDF geschrieben, und nicht zwischen den Ansichten abgeglichen.

## Umgebung

- Flutter-SDK vom Kanal `stable` (eingerichtet mit Flutter 3.50.0 / Dart 3.14); die SDK-Untergrenze steht in `pubspec.yaml` (`environment`).
- Android: `applicationId`/`namespace` `dev.paperflow` (Platzhalter), `minSdk = 24` in `android/app/build.gradle.kts`.
- Material-Widgets immer aus `package:material_ui/material_ui.dart` importieren. Lokalisierung: `AppLocalizations.delegate` plus `GlobalMaterialLocalizations.delegates` aus `material_ui` (die Delegates aus `flutter_localizations` reichen für Material-Widgets nicht).
- pdfrx in der App vor direkter Dokument-API mit `pdfrxFlutterInitialize()` initialisieren; in Host-Tests (`flutter test`) stattdessen `pdfrxInitialize(tmpPath: ...)` aus pdfrx_engine, da dort keine Flutter-Plugins laufen.
- Abhängigkeiten nur mit `flutter pub add` / `flutter pub get` (im Engine-Paket `dart pub`). `pubspec.lock` der App wird versioniert.

## Offene Entscheidungen

- Android-`applicationId`: bis zur Release-Vorbereitung gilt der Platzhalter `dev.paperflow`.
- Name des Copyright-Inhabers für die MIT-Lizenz.
- Ob die pdfrx-Textextraktion außerhalb des Haupt-Isolates laufen kann (wird im Reflow-Spike geklärt).

---
Pflege: Bei Änderungen an Stack oder Architektur diese Datei sofort aktualisieren.
