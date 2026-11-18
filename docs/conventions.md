# Namenskonventionen und Best Practices

> Wann lesen: bei Benennung, Dateiorganisation, Commits und beim Anlegen neuer Komponenten.

## Namenskonventionen

- Dateien und Ordner: `snake_case` (Dart-Standard).
- Klassen/Typen: `UpperCamelCase`; Funktionen, Variablen, Provider: `lowerCamelCase`. Provider enden auf `Provider` (z. B. `libraryRepositoryProvider`).
- Tests: `<datei>_test.dart`, Ablage gespiegelt unter `tests/` (siehe `docs/testing.md`).
- ARB-Schlüssel: `lowerCamelCase`, nach Feature gruppiert (z. B. `libraryEmptyTitle`).

## Struktur und Organisation

- Neues Feature → eigener Ordner unter `lib/features/<feature>/` mit `data/`, `domain/`, `presentation/`.
- `domain/` importiert weder Flutter-Widgets noch `drift` noch `pdfrx`.
- `pdfrx` wird nur im PDF-Adapter unter `lib/core/` importiert; Features nutzen dessen Schnittstelle.
- Layout-Analyse gehört ausschließlich in `packages/reflow_engine/`, nie in die App.
- Neue Texte zuerst in der englischen ARB-Vorlage, dann deutsche Übersetzung im selben Schritt.

## Best Practices (projektspezifisch)

- Keine Netzwerkzugriffe und keine Abhängigkeit, die Daten sendet (Offline-Pflicht).
- Dokument-ID ist der SHA-256 der PDF; Dateien liegen unter `books/<sha256>.pdf` im App-Speicher.
- Persistierte Reflow-Ergebnisse tragen immer die `engineVersion`; jede Änderung an der Engine-Ausgabe erhöht sie.
- Rechenintensive Arbeit (Reflow, Rendering von Ausschnitten) nie im UI-Isolate.

## Git

- Commit-Nachrichten: Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
- Branch-Strategie: direkt auf `main`, sofern die Arbeitsumgebung keinen anderen Branch vorgibt.

## CI und Release

- Workflow `.github/workflows/android.yml` (GitHub Actions, Flutter 3.50.0, Java 21): bei jedem Push/PR auf `main` Format-Check, `flutter analyze`, `flutter test tests/app tests/reflow_engine` und Release-APK als Artefakt.
- Release: Tag `vX.Y.Z` pushen (`git tag v1.0.0 && git push origin v1.0.0`) oder den Workflow manuell mit Eingabe `version` (z. B. `1.0.0`) starten – dann legt er das Tag `v1.0.0` selbst an → APK `unpaged-X.Y.Z.apk` wird als GitHub-Release veröffentlicht (Versionsname aus dem Tag, Build-Nummer = Lauf-Nummer).
- Signatur: Mit den Repository-Secrets `ANDROID_KEYSTORE_BASE64` (Keystore als Base64), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` schreibt der Workflow `android/key.properties` + Keystore und `android/app/build.gradle.kts` signiert damit; ohne Secrets wird mit dem Debug-Schlüssel signiert (nur zum Testen, Updates zwischen beiden Varianten sind nicht möglich). Keystore und `key.properties` nie committen (stehen in `.gitignore`).

---
Pflege: Bei neuen Konventionen oder Komponenten diese Datei sofort aktualisieren.
