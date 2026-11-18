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
| Schriften Literata, Atkinson Hyperlegible (`assets/fonts/`, offline gebündelt) | Lese-Schriften | SIL OFL 1.1 (Lizenztexte daneben) |
| `sqlite3` (dev, direkt) | Migrationstests mit Rohdatenbank | MIT |
| `path_provider`, `path` | App-Speicherort | BSD-3-Clause |

## Verbindliche Rahmenbedingungen

- **Komplett offline.** Keine Netzwerkzugriffe, keine Analytics, keine Crash-Reporter; es verlassen keine Daten das Gerät.
- **Lizenzen:** Jede Abhängigkeit muss MIT-kompatibel sein (MIT, BSD, Apache-2.0, Zlib o. ä.). Kein GPL/AGPL, daher kein MuPDF. Neue Abhängigkeit → Lizenz prüfen und hier eintragen.
- **Android zuerst**, `minSdk 24`. Code bleibt plattformneutral (keine Android-only-APIs außerhalb von Plattform-Adaptern).

## Architektur

- `lib/features/<feature>/` mit `data/`, `domain/`, `presentation/`. Features: `library`, `import`, `viewer` (Original), `reader` (eBook), `annotations`, `settings`.
- `lib/core/`: Datenbank, PDF-Adapter (einzige Stelle, die `pdfrx` importiert), Dateiablage, Theming, l10n.
- `packages/reflow_engine/`: **reines Dart-Paket ohne Flutter und ohne pdfrx** (einzige Abhängigkeit: `meta`). Enthält die gesamte Layout-Analyse. Eingabe: `DocumentInput` → `PageInput` (Nummer, Breite, Höhe) → `TextChar` (Glyph, Box, `wordStart`); Koordinaten in Punkten, Ursprung oben links, y wächst nach unten. Ausgabe: `ReflowDocument` (`engineVersion`, `ReflowBlock`s mit ID `p<Seite>b<Index>`, Typ, Text, Seite, Box, bei Überschriften `level`). Blocktypen: `heading`, `paragraph`, `listItem`, `caption` sowie die Bereiche `table`, `figure`, `formula` (`BlockType.isRegion`); Bereiche haben leeren Text und werden über Seite + Box als Bildausschnitt gezeigt. Einstieg: `const ReflowEngine().reflow(input)`; `ReflowEngine.version` wird bei jeder Ausgabeänderung erhöht. Die App bindet das Paket per `path`-Abhängigkeit ein.
- Engine-Pipeline (`packages/reflow_engine/lib/src/`): `lines.dart` (vertikale Glyphfolgen verwerfen → Läufe in Inhaltsreihenfolge → Läufe nur bei kleinem horizontalem Abstand zu Zeilen verbinden; kleine Glyphen wie Kommas/Hochstellungen hängen am Zeilenband) → `running_elements.dart` (Kolumnentitel, Seitenzahlen, Randreste) → `reading_order.dart` (Spaltenlücke suchen, Zweispalter-Regionen links vor rechts) → `regions.dart` (Tabellen als Zellraster, Abbildungen/Tabellen über Bildunterschriften – zuerst Randlegenden: schmale Unterschrift bündig links in der Textspalte mit Beschriftungen rechts daneben ⇒ Bereich rechts davon ab Oberkante der Unterschrift bis zur nächsten Prosazeile, ohne solche bis zum gespiegelten oberen Rand; sonst Fläche darüber/darunter –, Formeln über Formelzeichen; Muster in `text_patterns.dart`) → Lesereihenfolge mit Bereichen als Platzhalterzeilen → `paragraphs.dart` (Absätze dokumentweit, Fortsetzung über Spalten-/Seitenwechsel und über Abbildungen hinweg bei unvollendetem Satz) → `classify.dart` (Überschrift mit Ebene, Listeneintrag, Bildunterschrift, Absatz) → `hyphenation.dart` (Trennstriche über das Vokabular des Dokuments auflösen) → `engine.dart`.
- PDF-Adapter (`lib/core/pdf/`): `PdfAdapter.extractText(path)` liefert `DocumentInput`. pdfrx gibt nur Glyph + enge Glyph-Box (keine Schriftgröße, keine Bild-/Linienobjekte); der Adapter verwirft PDFium-Leerzeichen/Zeilenumbrüche, setzt stattdessen `wordStart`, rechnet in Top-down-Koordinaten um und bildet U+0002 (PDFium-Trennstrich am Zeilenende) auf `-` ab. Schriftgrößen schätzt die Engine aus Glyph-Höhen.

### Reflow-Pipeline (beim Import, offline)

1. PDF in den App-Speicher kopieren: `books/<sha256>.pdf`. Der SHA-256 ist Dokument-ID und Duplikat-Schlüssel.
2. Adapter (`lib/core`) liest pro Seite Zeichen mit Position und Schriftgröße über pdfrx.
3. Engine: Zeichen → Zeilen → Blöcke; Spalten und Lesereihenfolge erkennen, Kopf-/Fußzeilen und Seitenzahlen entfernen, Silbentrennung auflösen, Blocktyp bestimmen (Überschrift, Absatz, Liste, Bildunterschrift).
4. Tabellen, Abbildungen, Formeln als Bereiche markieren und einmalig als PNG-Ausschnitt rendern.
5. `ReflowDocument` als JSON speichern, mit `engineVersion`. Ändert sich die Engine-Version, bei Bedarf neu berechnen.
6. Verarbeitung im Hintergrund-Isolate; Fortschritt in der Bibliothek sichtbar. Ergebnis des Spikes (Task 02): pdfrx führt PDFium-Aufrufe ohnehin in einem eigenen Worker-Isolate aus; zusätzlich funktionieren Extraktion (`pdfrxInitialize` im Isolate) und Engine in `Isolate.run` (belegt durch `tests/app/core/pdf/background_extraction_test.dart`, auf dem Host; Android in Task 06 prüfen).

### Bibliothek und Import (Task 05)

- Datenbank `lib/core/database/app_database.dart` (drift, Datei `unpaged` im App-Speicher; im Test `AppDatabase(NativeDatabase.memory())`). Tabelle `Books`: `id` (SHA-256, Primärschlüssel), `title` (aus dem Dateinamen; pdfrx bietet keine Metadaten), `pageCount`, `importedAt`, `reflowStatus` (`ReflowStatus`), `reflowProgress`. `schemaVersion` 1; jede Schemaänderung erhöht sie und bekommt einen `onUpgrade`-Schritt plus Migrationstest.
- Dateiablage `BookFileStore` (`<App-Support-Verzeichnis>/books/<sha256>.pdf`); der Provider wird in `main()` mit dem echten Verzeichnis überschrieben.
- `ImportService` (`lib/features/import/domain/`): Bytes lesen → `%PDF`-Prüfung → SHA-256 → Duplikat? → Kopie schreiben → `PdfAdapter.inspect` (bei Fehler Kopie löschen) → Eintrag. Ergebnis `ImportSuccess` / `ImportDuplicate` / `ImportFailure`.
- Quellen sind `PdfSource`s: Dateiauswahl (`PdfPicker`, liest über `PlatformFile.xFile`, funktioniert auch mit `content://`) und Android-Intents (`IncomingPdfChannel`, MethodChannel `io.github.sphaerox.unpaged/incoming_pdf`; `MainActivity.kt` kopiert geteilte Inhalte nach `cacheDir/incoming/` und meldet Pfad + Name; Intent-Filter für `VIEW` und `SEND` mit `application/pdf`).
- Startbildschirm ist `LibraryScreen` (Liste, Leerzustand, Import-Button, Löschen mit Rückfrage); Antippen öffnet `ViewerScreen` mit der gespeicherten Kopie.

### Reflow-Pipeline in der App (Task 06)

- `ReflowPipeline` (`lib/features/reflow/domain/`): `extractText` (pdfrx, PDFium im pdfrx-Worker-Isolate) → weniger als 20 Glyphen pro Seite ⇒ `noText` → Engine in `Isolate.run` → Bereiche mit `PdfAdapter.renderRegions` als PNG (Skalierung 3 px/pt, längste Seite höchstens `PdfrxAdapter.maxCropSide` = 3000 px; Pixel werden vor `PdfImage.dispose()` in Dart-Speicher kopiert, weil `dispose` den nativen Puffer freigibt, PNG-Kodierung in `Isolate.run`, eigener Encoder `lib/core/pdf/png_encoder.dart`) → `ReflowStore`. Status und Fortschritt (0 → 0,3 → 0,6 → 0,9 → 1) stehen in `Books`; Fehler ⇒ `failed` und Cache gelöscht.
- `ReflowStore`: `<App-Support>/reflow/<sha256>/document.json` (atomar geschrieben) und `…/crops/<blockId>.png`.
- `ReflowScheduler` (Interface `ReflowQueue`, Provider `reflowSchedulerProvider`) arbeitet Bücher nacheinander ab. Beim Start der Bibliothek: alle `pending`/`running` (unterbrochen) und `done` mit älterer `engineVersion` neu; `failed`/`noText` werden nicht automatisch wiederholt. Nach einem Import wird das Buch eingereiht.
- Löschen eines Buchs entfernt auch seinen Reflow-Cache.

### eBook-Ansicht (Task 07)

- `ReaderScreen` (`lib/features/reader/presentation/`) lädt das Dokument über `reflowDocumentProvider(bookId)` und zeigt die Blöcke in einer `ListView.builder` (lazy). Stile: Überschrift nach `level` (`headlineSmall` / `titleLarge` / `titleMedium`), Absatz `bodyLarge`, Listeneintrag eingerückt, Bildunterschrift kursiv. Bereiche als `Image.file` aus dem `ReflowStore`; Antippen öffnet eine Zoom-Ansicht (`InteractiveViewer`, Doppeltipp zoomt).
- Fehlt das Dokument oder ist es beschädigt: Hinweis + „Neu vorbereiten“ (Status `pending`, `reflowSchedulerProvider.enqueue`).
- Umschalten: `ViewerScreen` (mit `bookId`) hat eine Aktion „eBook-Ansicht“, die nur bei `ReflowStatus.done` wechselt (sonst SnackBar mit Status); `ReaderScreen` hat „Originalansicht“. Gewechselt wird per `pushReplacement`; der Sprung an die passende Stelle folgt in Task 09.

### Lese-Einstellungen (Task 08)

- `ReaderSettings` (`lib/features/settings/domain/`): Schrift (`literata`, `atkinson`, `system`), Größe 14–30 in 2er-Schritten (Standard 18), Zeilenabstand 1,2–2,0 in 0,1-Schritten (Standard 1,5), Theme (`light`, `dark`, `sepia`). Gespeichert als Schlüssel/Wert-Zeilen (`reader.*`) in der Tabelle `Preferences` (`schemaVersion` 2, Migration 1→2 legt sie an, Test `tests/app/core/database/migration_test.dart`).
- `readerSettingsProvider` (AsyncNotifier) wendet Änderungen sofort an und speichert sie. Das Theme gilt für die ganze App (`lib/core/theme/app_theme.dart`, Sepia mit eigenem Hintergrund `sepiaBackground`); Schrift/Größe/Zeilenabstand gelten im eBook-Modus. Bedienung über das Bottom-Sheet „Lese-Einstellungen“ im Reader.

### Lesestand (Task 09)

- Tabelle `ReadingPositions` (Schlüssel `bookId` + `view`, `page`, `blockId`, `progress`, `updatedAt`; Schema v3). `ReadingPositionRepository` speichert pro Ansicht, liefert `lastUsed` und den Fortschritt je Buch für die Bibliothek.
- Original: `PdfAdapter.pageView(path, initialPage:, onPageChanged:)` (pdfrx `initialPageNumber` / `PdfViewerParams.onPageChanged`); jeder Seitenwechsel wird gespeichert.
- eBook: Liste als `CustomScrollView` mit zwei Slivern um einen Mittel-Sliver, damit sie direkt bei einem Block startet; nach Scroll-Ende (im nächsten Frame) wird der oberste Block gespeichert.
- Zuordnung (`lib/features/progress/domain/reading_position.dart`): Seite → erster Block dieser Seite bzw. nächster danach; Block → Quellseite; fehlt die gespeicherte Block-ID (neue Engine-Version), gilt die gespeicherte Seite.
- Bibliothek: Antippen öffnet die zuletzt genutzte Ansicht an der gespeicherten Stelle (eBook nur bei `done`), Fortschritt „· 25 % gelesen“. Löschen entfernt auch die Positionen.

### Markierungen im Original (Task 10)

- Tabelle `Annotations` (Schema v4; für beide Ansichten): Buch, Ansicht, Seite, Zeichenbereich `start`/`end`, Zitat, Farbe (`HighlightColor`), Notiz; für das eBook zusätzlich `blockId`, `prefix`/`suffix` (Kontext), `engineVersion`, `orphaned`. `AnnotationRepository` (`lib/features/annotations/`).
- Original: Die Auswahl kommt aus pdfrx (`buildContextMenu` → `getSelectedTextRanges()`, Zeichenindizes in `PdfPageText.fullText` von `loadStructuredText`). Der Adapter liefert `PdfSelection`s an `SelectionAction`s („Markieren“, „Notiz hinzufügen“), berechnet mit `textRects(path, page, start, end)` die Rechtecke je Zeile und zeichnet `PageHighlight`s als Overlays (`pageOverlaysBuilder`, Tippen über `PdfOverlayInteractionRegion`).
- Antippen einer Markierung öffnet ein Sheet (Zitat, Farbe, Notiz, Löschen); die Liste „Markierungen“ springt zur Seite. Die PDF-Datei wird nie verändert; Löschen eines Buchs entfernt seine Markierungen.

### Markierungen im eBook-Modus (Task 11)

- Reader-Blöcke sind `SelectableText.rich`; Markierungen erscheinen als farbige Spans. Das Kontextmenü ergänzt „Markieren“ und „Notiz hinzufügen“; Antippen innerhalb einer Markierung öffnet das Bearbeiten-Sheet. Eine Markierung liegt immer in genau einem Block (Auswahl über Blockgrenzen ist nicht möglich).
- Verankerung (`lib/features/annotations/domain/reanchor.dart`): Block-ID + Offsets im Blocktext + Zitat mit je 30 Zeichen Kontext davor/danach + `engineVersion`. Beim Öffnen des Readers werden Markierungen mit anderer Engine-Version (oder verwaiste) neu verankert: gleiche Block-ID mit gleichem Zitat → bleibt; sonst Suche nach dem Zitat im ganzen Dokument, bei mehreren Treffern entscheidet der Kontext; nicht gefunden → `orphaned` (bleibt erhalten, erscheint in der Liste als „In der aktuellen Fassung nicht gefunden“).
- Die Liste „Markierungen“ im Reader springt zum Block (`ReaderScreen.initialBlockId`).

### Markierungen und Lesestand

- Original: verankert an Seite + Zeichenbereich.
- eBook: verankert an Block-ID + Offset, zusätzlich Textzitat mit Kontext, damit sie nach Neuberechnung wieder zugeordnet werden können.
- Lesestand pro Ansicht; beim Wechsel springt die App über die Quellseite des Blocks an die passende Stelle.
- Markierungen werden nur in der App-Datenbank gespeichert, nie in die PDF geschrieben, und nicht zwischen den Ansichten abgeglichen.

## Umgebung

- Flutter-SDK vom Kanal `stable` (eingerichtet mit Flutter 3.50.0 / Dart 3.14); die SDK-Untergrenze steht in `pubspec.yaml` (`environment`).
- Android: `applicationId`/`namespace` `io.github.sphaerox.unpaged` (festgelegt bei der Umbenennung in Unpaged, 2026-11-18), `minSdk = 24` in `android/app/build.gradle.kts`.
- App-Icon: Master ist `assets/branding/unpaged_icon.svg` (nicht im App-Bundle, Farben `#1F2A5C`, `#F4F1EA`, `#FF8A5B`). Daraus abgeleitet, ohne Generator-Abhängigkeit: Adaptive Icon ab API 26 (`mipmap-anydpi-v26/ic_launcher.xml` mit Vector-Drawables `ic_launcher_foreground`/`ic_launcher_monochrome` und Farbe `ic_launcher_background`; die `<group>` bildet die Master-Koordinaten mit Faktor 0,42 in die 66-dp-Safe-Zone ab) und PNG-Fallbacks `mipmap-*/ic_launcher.png` für API 24/25. Bei Änderungen am Master alle drei Stellen mitziehen.
- Material-Widgets immer aus `package:material_ui/material_ui.dart` importieren. Lokalisierung: `AppLocalizations.delegate` plus `GlobalMaterialLocalizations.delegates` aus `material_ui` (die Delegates aus `flutter_localizations` reichen für Material-Widgets nicht).
- pdfrx in der App vor direkter Dokument-API mit `pdfrxFlutterInitialize()` initialisieren; in Host-Tests (`flutter test`) stattdessen `pdfrxInitialize(tmpPath: ...)` aus pdfrx_engine, da dort keine Flutter-Plugins laufen.
- Abhängigkeiten nur mit `flutter pub add` / `flutter pub get` (im Engine-Paket `dart pub`). `pubspec.lock` der App wird versioniert.

## Offene Entscheidungen

- Copyright-Inhaber der MIT-Lizenz: „The Unpaged authors“ (entschieden, LICENSE folgt in Task 12).

---
Pflege: Bei Änderungen an Stack oder Architektur diese Datei sofort aktualisieren.
