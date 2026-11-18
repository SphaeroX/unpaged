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
- Screenshots: Workflow `.github/workflows/screenshots.yml` startet bei Pushes auf `main`, die App-Code, Assets, Android, Engine, `pubspec.*` oder `tests/screenshots/` ändern (und manuell), einen Android-Emulator (API 34, Pixel 6), führt `tests/screenshots/screenshots_test.dart` per `flutter drive` aus und committet geänderte Bilder in `docs/screenshots/` als `github-actions[bot]` mit `[skip ci]`. Die `README.md` bindet diese Dateien ein und ist damit immer aktuell. Neue Screens: Aufnahme im Test ergänzen und in der README-Tabelle verlinken.
- Demo-Video: `docs/media/unpaged-demo.mp4` (23 s, 1920×1080) mit Vorschaubild `docs/media/unpaged-demo.jpg`, in der README unter „Demo“ verlinkt. Es wird nicht automatisch erneuert, sondern bei größeren UI-Änderungen von Hand neu aufgenommen (Release-Build auf dem Emulator per `adb shell screenrecord`, Komposition außerhalb des Repos). Für einen Player direkt in der README die MP4 in ein GitHub-Issue ziehen und den `user-attachments`-Link einsetzen.
- Signatur: Mit den Repository-Secrets `ANDROID_KEYSTORE_BASE64` (Keystore als Base64), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` schreibt der Workflow `android/key.properties` + Keystore und `android/app/build.gradle.kts` signiert damit; ohne Secrets wird mit dem Debug-Schlüssel signiert (nur zum Testen, Updates zwischen beiden Varianten sind nicht möglich). Keystore und `key.properties` nie committen (stehen in `.gitignore`).

## Website (GitHub Pages)

- `site/` enthält die Landing-Page (`index.html`, Englisch und Deutsch per Umschalter bzw. `?lang=de`) und die Datenschutzerklärung (`privacy/index.html`, beide Sprachen auf einer Seite); gemeinsames CSS in `site/style.css`, Farben aus dem App-Icon.
- Workflow `.github/workflows/pages.yml` veröffentlicht `site/` nach https://sphaerox.github.io/unpaged/ (Datenschutz: https://sphaerox.github.io/unpaged/privacy/). Er kopiert vorher Icon, `docs/screenshots/` (en) und `docs/screenshots/de/`, das Demo-Video aus `docs/media/`, die Feature-Grafik und die Schrift Literata hinein; diese Dateien liegen nicht doppelt in `site/`. Läuft bei Änderungen daran und nach dem Screenshots-Workflow.
- Die Datenschutzerklärung beschreibt, was die App tatsächlich tut (keine Berechtigungen, alles lokal, Teilen/Drucken nur über den Systemdialog). Ändert sich das Verhalten der App (neue Berechtigung, neue Datenverarbeitung), Erklärung, Datum und `docs/play-console.md` im selben Schritt anpassen.

## Google Play

- Antworten auf die Formulare der Console (App-Inhalte, Data Safety, Einstufung, Zielgruppe, Store-Einstellungen) stehen in `docs/play-console.md`.
- App in der Play Console: „Unpaged“, Paket `io.github.sphaerox.unpaged`, kostenlos, Standardsprache `en-US`. Play App Signing: Google verwaltet den App-Signaturschlüssel, wir signieren nur mit dem Upload-Key (Alias `upload`, derselbe Keystore wie in den `ANDROID_*`-Secrets).
- API-Zugang: Google-Cloud-Projekt `unpaged-play`, Google Play Android Developer API aktiviert, Service-Account `play-upload@unpaged-play.iam.gserviceaccount.com` mit App-Rechten nur für Unpaged (Entwürfe, Releases in Produktion und Test-Tracks, Test-Tracks verwalten, Store-Präsenz; keine Finanz-/Admin-Rechte). Sein JSON-Key steht als Secret `PLAY_SERVICE_ACCOUNT_JSON` im Repo; lokal nie ins Repo legen.
- fastlane: `android/Gemfile`, `android/fastlane/Appfile` (Paketname), `android/fastlane/Fastfile` mit den Lanes `check` (prüft nur den API-Zugang und listet die Version-Codes) `upload` (Optionen `track:` internal/alpha/beta/production, `status:` draft/completed; Standard internal + draft) und `metadata` (Store-Eintrag aus `android/fastlane/metadata/android/`). Der versionCode wird aus Play ermittelt (höchster Code aller Tracks + 1), der versionName kommt aus `pubspec.yaml`. `upload` lädt nur das AAB, keine Texte, Bilder oder Changelogs.
- Store-Eintrag (Quelle im Repo, `en-US` und `de-DE`): `android/fastlane/metadata/android/<locale>/` mit `title.txt` (max. 30 Zeichen), `short_description.txt` (max. 80), `full_description.txt` (max. 4000, einfache HTML-Tags wie `<b>` erlaubt) und `video.txt` (YouTube-Link des Demo-Videos, „nicht gelistet“ auf dem Kanal des Maintainers; Datei liegt in `docs/media/`). Grafiken in `images/`: `icon.png` (512×512, vollflächig, Play rundet selbst), `featureGraphic.png` (1024×500) und `phoneScreenshots/` (1080×1920, Überschrift + Gerät; Play erlaubt höchstens 2:1, die rohen 1080×2400-Aufnahmen passen nicht direkt).
- Grafiken neu erzeugen: erst Screenshots aufnehmen (Englisch nach `docs/screenshots/`, Deutsch mit `--dart-define=SCREENSHOT_LOCALE=de` nach `docs/screenshots/de/`, siehe `docs/testing.md`), dann `uv run tool/store_assets.py` (Pillow; Farben aus dem Icon, Schriften aus `assets/fonts/`; Überschriften je Sprache stehen im Skript). Danach Workflow mit `lane=metadata` starten.
- Workflow `.github/workflows/play-upload.yml` („Google Play“, nur manuell): Eingaben `lane` (upload/metadata/check), `track`, `status`; bei `upload` laufen Tests, Signatur aus den Secrets (ohne Secrets bricht er ab), dann fastlane; das AAB bleibt als Artefakt `play-aab`.
- Lokal (Ruby 3.3 + Bundler nötig): in `android/` `bundle install`, dann `PLAY_SERVICE_ACCOUNT_JSON` mit dem JSON-Text setzen und `bundle exec fastlane android check` bzw. `upload`. `android/key.properties` muss auf den Upload-Keystore zeigen.
- Solange die App in der Console noch nicht veröffentlicht ist (Entwurfs-App), nimmt Play nur Releases mit `status:draft` an; ausrollen dann in der Console. Erstes Release: 1.0.0 (versionCode 2) per Workflow `lane=upload track=production status=draft` gebaut und am 18.11.2026 in der Console zur Prüfung eingereicht (versionCode 1 liegt als alter Entwurf im internen Track). Versionshinweise lädt die Lane nicht hoch; sie werden pro Release in der Console eingetragen.

---
Pflege: Bei neuen Konventionen oder Komponenten diese Datei sofort aktualisieren.
