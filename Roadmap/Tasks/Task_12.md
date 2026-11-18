# Task_12: Release-Vorbereitung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_12.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die App ist bereit für den ersten Upload in den Google Play Store: endgültige `applicationId`, Signing, MIT-Lizenz, Lizenzhinweise der Abhängigkeiten, Datenschutzhinweis, Store-Texte in DE/EN und ein geprüfter Release-Build.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_01 bis Task_11 archiviert.
- **Relevantes Vorwissen:** Offene Entscheidungen in `docs/architecture.md` und `docs/project-brief.md` (applicationId, Copyright-Inhaber); Grenzen in Root-`AGENTS.md` (keine Keystores committen).

## Umfang

**Gehört dazu:**

- `applicationId` endgültig festlegen (Nutzer entscheidet) und überall ersetzen
- `LICENSE` (MIT) mit Copyright-Inhaber (Nutzer entscheidet)
- Lizenzübersicht der Abhängigkeiten in der App (z. B. Flutter `LicenseRegistry`/`showLicensePage`), inkl. Schriften und PDFium
- Datenschutzhinweis (keine Datenerhebung, alles offline) als Datei im Repo und in der App erreichbar
- Release-Signing über `key.properties` (nicht im Repo) und Anleitung in `docs/`
- App-Name, Icon, Versionsnummer
- Store-Texte DE/EN (Kurz- und Langbeschreibung) als Dateien im Repo
- Release-Build als App Bundle (`flutter build appbundle --release`), Prüfung auf Netzwerk-Berechtigung (darf nicht nötig sein)

**Gehört nicht dazu:**

- Der eigentliche Upload in die Play Console (macht der Nutzer)
- iOS-Release (Nicht-Ziel)

## Umsetzungsschritte

1. [ ] Offene Entscheidungen (applicationId, Copyright-Inhaber) beim Nutzer abfragen, bevor etwas ersetzt wird.
2. [ ] Test schreiben, dass die Lizenzseite die erwarteten Einträge enthält; Lizenzanzeige umsetzen.
3. [ ] `LICENSE`, Datenschutzhinweis und Store-Texte anlegen.
4. [ ] Signing-Konfiguration einrichten, `key.properties` und Keystore in `.gitignore` prüfen, Anleitung in `docs/` schreiben.
5. [ ] Icon, App-Name, Version setzen.
6. [ ] Manifest prüfen: keine `INTERNET`-Berechtigung im Release-Manifest; Test oder Skript, das dies belegt.
7. [ ] Release-Build erzeugen und auf einem Gerät die Kernabläufe manuell prüfen (Import, Original, eBook, Einstellungen, Lesestand, Markierungen).
8. [ ] Offene Entscheidungen in `docs/` schließen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Widget: Lizenzseite und Datenschutzhinweis sind aus der App erreichbar.
- Prüfung (Test oder Skript im Repo): Das zusammengeführte Release-Manifest enthält keine `INTERNET`-Berechtigung.
- Alle bestehenden Tests laufen grün (komplette Suite inklusive Integrationstests).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app tests/reflow_engine` grün; Integrationstests grün oder begründet vermerkt.
- [ ] `flutter build appbundle --release` erfolgreich mit Release-Signing.
- [ ] Kein Keystore und keine `key.properties` im Repo (`git ls-files` belegt das).
- [ ] `LICENSE`, Datenschutzhinweis und Store-Texte DE/EN liegen im Repo.
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Aus Task_08: OFL-Lizenzen der Schriften (`assets/fonts/*-OFL.txt`) in die Lizenzseite aufnehmen.
- `applicationId`: bei der Umbenennung in Unpaged festgelegt (2026-11-18) → `io.github.sphaerox.unpaged`.
- Name des Copyright-Inhabers für die MIT-Lizenz: vom Nutzer entschieden (2026-11-18) → „The Unpaged authors“ (Projekt umbenannt von „paperflow“).
- Bereits erledigt (auf Wunsch des Nutzers vorgezogen): GitHub-Actions-Workflow mit Release-APK bei Tags `v*` und optionaler Release-Signatur über `android/key.properties` bzw. Repository-Secrets (siehe `docs/conventions.md`, Abschnitt „CI und Release“). Offen bleibt das Erzeugen des echten Upload-Keystores durch den Nutzer und das Hinterlegen der Secrets.
- Stand 2026-11-18: Der Nutzer hat diesen Task vorerst zurückgestellt; die Datenschutz-URL ist noch offen.
- Hosting des Datenschutzhinweises für den Play Store (Play verlangt eine URL; z. B. GitHub-Seite des Repos) – mit dem Nutzer klären.

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
