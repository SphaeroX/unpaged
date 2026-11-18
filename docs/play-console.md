# Play Console: Antworten und Einstellungen

> Wann lesen: bevor Formulare in der Play Console geändert werden oder wenn sich Berechtigungen, Datenverarbeitung oder Zielgruppe der App ändern. Grundlage ist das tatsächliche Verhalten der App (siehe `docs/architecture.md`, Abschnitt „Verbindliche Rahmenbedingungen“).

App: „Unpaged“, Paket `io.github.sphaerox.unpaged`, kostenlos.

## Datenschutzerklärung

https://sphaerox.github.io/unpaged/privacy/ (Quelle: `site/privacy/index.html`)

## App-Zugriff

Alle Funktionen sind ohne besondere Zugriffsrechte verfügbar: kein Login, keine Mitgliedschaft.

## Werbung

Nein, die App enthält keine Werbung.

## Einstufung des Inhalts (IARC-Fragebogen)

- Kategorie: Alle anderen App-Typen (Referenz/Produktivität, kein Spiel)
- Gewalt, Angst, Sexualität, Glücksspiel, Drogen, Alkohol, Tabak, derbe Sprache, rohe Humor: jeweils Nein
- Nutzer können miteinander kommunizieren oder Inhalte austauschen: Nein (Teilen geht nur über den Android-Teilen-Dialog an Apps des Nutzers)
- Standort wird mit anderen geteilt: Nein
- Digitale Käufe: Nein
- Web-Browser oder Suchmaschine: Nein
- Hinweis: Die App zeigt Inhalte aus PDFs, die der Nutzer selbst öffnet; sie liefert keine eigenen Inhalte aus.

## Zielgruppe und Inhalte

- Altersgruppen: 13–15, 16–17 und 18+ (Leser von Fachtexten; keine Gruppe unter 13, damit die Familien-Richtlinien nicht greifen)
- Spricht die App Kinder unbeabsichtigt an: Nein

## Datensicherheit (Data Safety)

- Erhebt oder teilt die App erforderliche Nutzerdatentypen? Nein.
  - Die App hat keine INTERNET-Berechtigung und sendet nichts. Daten, die nur auf dem Gerät verarbeitet werden (PDF-Kopie, eBook-Fassung, Markierungen, Notizen, Lesestand, Einstellungen), gelten bei Google nicht als „erhoben“.
  - Teilen und Drucken der Original-PDF startet der Nutzer selbst über den Systemdialog; das zählt nicht als Weitergabe durch die App.
- Damit entfallen die Fragen zu Verschlüsselung bei der Übertragung und zur Löschanfrage.

## Weitere Erklärungen

- Werbe-ID: Die App verwendet keine Werbe-ID.
- Behörden-App: Nein. Finanzfunktionen: keine. Gesundheits-App: Nein. News-App: Nein.
- Berechtigungen: keine (die zusammengeführte Manifest-Datei enthält nur die interne Kennung `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` von androidx).

## Store-Einstellungen

- App-Kategorie: Bücher & Nachschlagewerke
- Tags: passend zu PDF-Reader/eBook-Reader, soweit die Console sie anbietet
- E-Mail: prompt-engineered@protonmail.com (dieselbe öffentliche Kontaktadresse wie bei CycleScope)
- Website: https://sphaerox.github.io/unpaged/
- Telefon: keine

## Store-Eintrag

Texte und Grafiken kommen aus `android/fastlane/metadata/android/` (Lane `metadata`), siehe `docs/conventions.md`.
