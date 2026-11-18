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
| `integration_test`, `flutter_test`, `test` (dev) | Tests | BSD-3-Clause |
| `meta` (Engine) | Annotationen (`@immutable`) | BSD-3-Clause |
| `drift`, `drift_flutter` (bringt `sqlite3` mit gebündeltem SQLite) | Datenbank | MIT (SQLite: Public Domain) |
| `drift_dev`, `build_runner` (dev) | Codegenerierung für drift | MIT / BSD-3-Clause |
| `crypto` | SHA-256 der PDFs | BSD-3-Clause |
| `path_provider`, `path` | App-Speicherort | BSD-3-Clause |

## Verbindliche Rahmenbedingungen

- **Komplett offline.** Keine Netzwerkzugriffe, keine Analytics, keine Crash-Reporter; es verlassen keine Daten das Gerät.
- **Lizenzen:** Jede Abhängigkeit muss MIT-kompatibel sein (MIT, BSD, Apache-2.0, Zlib o. ä.). Kein GPL/AGPL, daher kein MuPDF. Neue Abhängigkeit → Lizenz prüfen und hier eintragen.
- **Android zuerst**, `minSdk 24`. Code bleibt plattformneutral (keine Android-only-APIs außerhalb von Plattform-Adaptern).

## Architektur

- `lib/features/<feature>/` mit `data/`, `domain/`, `presentation/`. Features: `library`, `import`, `viewer` (Original), `reader` (eBook), `annotations`, `settings`.
- `lib/core/`: Datenbank, PDF-Adapter (einzige Stelle, die `pdfrx` importiert), Dateiablage, Theming, l10n.
- `packages/reflow_engine/`: **reines Dart-Paket ohne Flutter und ohne pdfrx** (einzige Abhängigkeit: `meta`). Enthält die gesamte Layout-Analyse. Eingabe: `DocumentInput` → `PageInput` (Nummer, Breite, Höhe) → `TextChar` (Glyph, Box, `wordStart`); Koordinaten in Punkten, Ursprung oben links, y wächst nach unten. Ausgabe: `ReflowDocument` (`engineVersion`, `ReflowBlock`s mit ID `p<Seite>b<Index>`, Typ, Text, Seite, Box, bei Überschriften `level`). Blocktypen: `heading`, `paragraph`, `listItem`, `caption` sowie die Bereiche `table`, `figure`, `formula` (`BlockType.isRegion`); Bereiche haben leeren Text und werden über Seite + Box als Bildausschnitt gezeigt. Einstieg: `const ReflowEngine().reflow(input)`; `ReflowEngine.version` wird bei jeder Ausgabeänderung erhöht. Die App bindet das Paket per `path`-Abhängigkeit ein.
- Engine-Pipeline (`packages/reflow_engine/lib/src/`): `lines.dart` (vertikale Glyphfolgen verwerfen → Läufe in Inhaltsreihenfolge → Läufe nur bei kleinem horizontalem Abstand zu Zeilen verbinden; kleine Glyphen wie Kommas/Hochstellungen hängen am Zeilenband) → `running_elements.dart` (Kolumnentitel, Seitenzahlen, Randreste) → `reading_order.dart` (Spaltenlücke suchen, Zweispalter-Regionen links vor rechts) → `regions.dart` (Tabellen als Zellraster, Abbildungen/Tabellen über Bildunterschriften, Formeln über Formelzeichen; Muster in `text_patterns.dart`) → Lesereihenfolge mit Bereichen als Platzhalterzeilen → `paragraphs.dart` (Absätze dokumentweit, Fortsetzung über Spalten-/Seitenwechsel und über Abbildungen hinweg bei unvollendetem Satz) → `classify.dart` (Überschrift mit Ebene, Listeneintrag, Bildunterschrift, Absatz) → `hyphenation.dart` (Trennstriche über das Vokabular des Dokuments auflösen) → `engine.dart`.
- PDF-Adapter (`lib/core/pdf/`): `PdfAdapter.extractText(path)` liefert `DocumentInput`. pdfrx gibt nur Glyph + enge Glyph-Box (keine Schriftgröße, keine Bild-/Linienobjekte); der Adapter verwirft PDFium-Leerzeichen/Zeilenumbrüche, setzt stattdessen `wordStart`, rechnet in Top-down-Koordinaten um und bildet U+0002 (PDFium-Trennstrich am Zeilenende) auf `-` ab. Schriftgrößen schätzt die Engine aus Glyph-Höhen.

### Reflow-Pipeline (beim Import, offline)

1. PDF in den App-Speicher kopieren: `books/<sha256>.pdf`. Der SHA-256 ist Dokument-ID und Duplikat-Schlüssel.
2. Adapter (`lib/core`) liest pro Seite Zeichen mit Position und Schriftgröße über pdfrx.
3. Engine: Zeichen → Zeilen → Blöcke; Spalten und Lesereihenfolge erkennen, Kopf-/Fußzeilen und Seitenzahlen entfernen, Silbentrennung auflösen, Blocktyp bestimmen (Überschrift, Absatz, Liste, Bildunterschrift).
4. Tabellen, Abbildungen, Formeln als Bereiche markieren und einmalig als PNG-Ausschnitt rendern.
5. `ReflowDocument` als JSON speichern, mit `engineVersion`. Ändert sich die Engine-Version, bei Bedarf neu berechnen.
6. Verarbeitung im Hintergrund-Isolate; Fortschritt in der Bibliothek sichtbar. Ergebnis des Spikes (Task 02): pdfrx führt PDFium-Aufrufe ohnehin in einem eigenen Worker-Isolate aus; zusätzlich funktionieren Extraktion (`pdfrxInitialize` im Isolate) und Engine in `Isolate.run` (belegt durch `tests/app/core/pdf/background_extraction_test.dart`, auf dem Host; Android in Task 06 prüfen).

### Bibliothek und Import (Task 05)

- Datenbank `lib/core/database/app_database.dart` (drift, Datei `paperflow` im App-Speicher; im Test `AppDatabase(NativeDatabase.memory())`). Tabelle `Books`: `id` (SHA-256, Primärschlüssel), `title` (aus dem Dateinamen; pdfrx bietet keine Metadaten), `pageCount`, `importedAt`, `reflowStatus` (`ReflowStatus`), `reflowProgress`. `schemaVersion` 1; jede Schemaänderung erhöht sie und bekommt einen `onUpgrade`-Schritt plus Migrationstest.
- Dateiablage `BookFileStore` (`<App-Support-Verzeichnis>/books/<sha256>.pdf`); der Provider wird in `main()` mit dem echten Verzeichnis überschrieben.
- `ImportService` (`lib/features/import/domain/`): Bytes lesen → `%PDF`-Prüfung → SHA-256 → Duplikat? → Kopie schreiben → `PdfAdapter.inspect` (bei Fehler Kopie löschen) → Eintrag. Ergebnis `ImportSuccess` / `ImportDuplicate` / `ImportFailure`.
- Quellen sind `PdfSource`s: Dateiauswahl (`PdfPicker`, liest über `PlatformFile.xFile`, funktioniert auch mit `content://`) und Android-Intents (`IncomingPdfChannel`, MethodChannel `dev.paperflow/incoming_pdf`; `MainActivity.kt` kopiert geteilte Inhalte nach `cacheDir/incoming/` und meldet Pfad + Name; Intent-Filter für `VIEW` und `SEND` mit `application/pdf`).
- Startbildschirm ist `LibraryScreen` (Liste, Leerzustand, Import-Button, Löschen mit Rückfrage); Antippen öffnet `ViewerScreen` mit der gespeicherten Kopie.

### Reflow-Pipeline in der App (Task 06)

- `ReflowPipeline` (`lib/features/reflow/domain/`): `extractText` (pdfrx, PDFium im pdfrx-Worker-Isolate) → weniger als 20 Glyphen pro Seite ⇒ `noText` → Engine in `Isolate.run` → Bereiche mit `PdfAdapter.renderRegions` als PNG (Skalierung 3 px/pt, PNG-Kodierung in `Isolate.run`, eigener Encoder `lib/core/pdf/png_encoder.dart`) → `ReflowStore`. Status und Fortschritt (0 → 0,3 → 0,6 → 0,9 → 1) stehen in `Books`; Fehler ⇒ `failed` und Cache gelöscht.
- `ReflowStore`: `<App-Support>/reflow/<sha256>/document.json` (atomar geschrieben) und `…/crops/<blockId>.png`.
- `ReflowScheduler` (Interface `ReflowQueue`, Provider `reflowSchedulerProvider`) arbeitet Bücher nacheinander ab. Beim Start der Bibliothek: alle `pending`/`running` (unterbrochen) und `done` mit älterer `engineVersion` neu; `failed`/`noText` werden nicht automatisch wiederholt. Nach einem Import wird das Buch eingereiht.
- Löschen eines Buchs entfernt auch seinen Reflow-Cache.

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

---
Pflege: Bei Änderungen an Stack oder Architektur diese Datei sofort aktualisieren.
