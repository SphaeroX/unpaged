# paperflow – Roadmap

Projektübergreifendes Gedächtnis. Agenten lesen diese Datei vor jedem Task und aktualisieren sie, wenn sich etwas ergibt, das über einen einzelnen Task hinausgeht. Regeln für die Arbeit: [AGENTS.md](AGENTS.md).

## Projektziel

paperflow ist ein Open-Source-PDF-Reader für Android (MIT, Google Play Store, Code auf GitHub). Er öffnet PDFs im Original-Layout und bietet zusätzlich einen eBook-Modus, der PDFs mit Textebene komplett offline neu umbricht, damit sich Fachtexte auf dem Handy bequem lesen lassen.

**Was die Software tut:** Import über Dateiauswahl, „Öffnen mit“ und „Teilen“ (die App legt eine eigene Kopie an); Bibliothek mit Lesestand; Original-Seitenansicht; eBook-Modus mit Reflow, bei dem Tabellen, Abbildungen und Formeln als zoombare Bildausschnitte erscheinen (Umrechnung beim Import im Hintergrund, zwischengespeichert); Lese-Einstellungen (Schrift, Größe, Zeilenabstand, hell/dunkel/Sepia); Markierungen und Notizen getrennt pro Ansicht; Oberfläche DE/EN.

**Zielgruppe:** Leser von Fachbüchern, wissenschaftlichen Papern und technischer Dokumentation, auch mit mehrspaltigem Layout.

**Nicht-Ziele:** OCR / gescannte PDFs; Cloud, Synchronisation, KI; Markierungen in die PDF schreiben; Markierungen zwischen Original und eBook abgleichen; Tabellen als echten Text nachbauen; Ordner automatisch überwachen; iOS-Release (Code bleibt plattformneutral). Details: `docs/project-brief.md`.

## Aktueller Status

Stand: 2026-11-18 – Task_01 bis Task_04 erledigt.

| Task | Titel | Status |
|---|---|---|
| 01 | Durchstich: Flutter-Gerüst, DE/EN, PDF öffnen und im Original anzeigen | erledigt |
| 02 | Reflow-Spike & Engine-Basis | erledigt |
| 03 | Spalten & Lesereihenfolge | erledigt |
| 04 | Blocktypen & Nicht-Text-Bereiche | erledigt |
| 05 | Bibliothek & Import | offen |
| 06 | Reflow-Pipeline in der App | offen |
| 07 | eBook-Leseansicht | offen |
| 08 | Lese-Einstellungen | offen |
| 09 | Lesestand | offen |
| 10 | Markierungen im Original | offen |
| 11 | Markierungen im eBook-Modus | offen |
| 12 | Release-Vorbereitung | offen |

Status ist `offen`, `läuft` (Datei trägt das Präfix `RUN_`) oder `erledigt` (Datei liegt in `Archiv/`). Die Tabelle wird beim Archivieren eines Tasks aktualisiert.

## Taskübergreifende Entwicklungsinfos

Globale Informationen, Architekturentscheidungen und Wissen, das für das gesamte Projekt gilt. Wird laufend ergänzt; jeden Eintrag mit dem Task kennzeichnen, aus dem er stammt.

- Projektregeln, Stack und Architektur stehen in der Root-`AGENTS.md` und in `docs/`; hier nur, was sich während der Roadmap ergibt. *(Roadmap-Anlage)*
- Flutter 3.50 / Dart 3.14: Material kommt aus `package:material_ui/material_ui.dart`; Konstruktoren als `const new(...)`; Details in `docs/architecture.md` und `docs/code-style.md`. *(Task_01)*
- Externe Abhängigkeiten (pdfrx, Dateiauswahl, später DB) stecken hinter Interfaces in `lib/core/` mit Riverpod-Provider; Tests ersetzen sie per `overrideWithValue`. *(Task_01)*
- Engine-Ein-/Ausgabe, Koordinatensystem (oben links, y nach unten) und Adapter-Besonderheiten: `docs/architecture.md`. Fixture- und Snapshot-Workflow: `docs/testing.md`. *(Task_02)*
- Isolate-Frage geklärt: Extraktion und Engine laufen in `Isolate.run` (Host belegt). *(Task_02)*
- Engine-Pipeline und Zuständigkeit der Dateien: `docs/architecture.md` (Abschnitt Architektur). *(Task_03)*
- Der Nutzer hat Snapshot-Änderungen, die aus den geplanten Verbesserungen von Task 03/04 folgen, pauschal freigegeben (von Hand prüfen, im Commit begründen, im Abschlussbericht auflisten). Für spätere Tasks gilt wieder die Einzelfreigabe. *(Task_03)*
- Liste der freigegebenen Snapshot-Änderungen für den Abschlussbericht: Task 03 (`single_column_text`: Seitenzahlen entfernt, Absatz über Seite 2→3; `synthetic_single_column`: nur Version), Task 04 (alle Snapshots: Blocktypen/Ebenen/Bereiche, Version 3). *(Task_04)*
- Engine-Ausgabe ist ab `engineVersion` 3 inhaltlich vollständig: Blocktypen inkl. Bereiche (Tabelle/Abbildung/Formel mit leerem Text, Seite + Box). *(Task_04)*
- Tests liegen unter `tests/app/`, `tests/reflow_engine/`, `tests/integration/` und werden mit expliziten Pfaden ausgeführt (siehe `docs/testing.md`). *(Roadmap-Anlage)*

## Auffälligkeiten & Details

Dinge, die global noch zu beachten sind: Besonderheiten, bekannte Einschränkungen, kleinere Details. Wird laufend ergänzt.

- Hauptrisiko ist die Reflow-Qualität bei Mehrspaltern; deshalb liegen die Engine-Tasks (02–04) vor der App-Integration. *(Roadmap-Anlage)*
- Offene Entscheidungen des Nutzers: endgültige `applicationId` (Platzhalter `dev.paperflow`) und Copyright-Inhaber der MIT-Lizenz, beide spätestens in Task_12. *(Roadmap-Anlage)*
- Cloud-Umgebung: Flutter unter `/opt/flutter`, Android-SDK unter `/opt/android-sdk` (nachinstalliert, nicht persistent). APK-Builds funktionieren; Integrationstests laufen dort **nicht** (kein Gerät/Emulator) und müssen lokal nachgeholt werden. *(Task_01)*
- Bekannte Engine-Grenzen: mehr als zwei Spalten, abgesetzte Akzente (`supe´rieure`), teils zerlegte Ligaturen (`i feld`). *(Task_03)*
- pdfrx liefert keine Schriftgrößen und keine Bild-/Linienobjekte, nur Zeichen + Boxen. *(Task_01)*
