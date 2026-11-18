# paperflow – Roadmap

Projektübergreifendes Gedächtnis. Agenten lesen diese Datei vor jedem Task und aktualisieren sie, wenn sich etwas ergibt, das über einen einzelnen Task hinausgeht. Regeln für die Arbeit: [AGENTS.md](AGENTS.md).

## Projektziel

paperflow ist ein Open-Source-PDF-Reader für Android (MIT, Google Play Store, Code auf GitHub). Er öffnet PDFs im Original-Layout und bietet zusätzlich einen eBook-Modus, der PDFs mit Textebene komplett offline neu umbricht, damit sich Fachtexte auf dem Handy bequem lesen lassen.

**Was die Software tut:** Import über Dateiauswahl, „Öffnen mit“ und „Teilen“ (die App legt eine eigene Kopie an); Bibliothek mit Lesestand; Original-Seitenansicht; eBook-Modus mit Reflow, bei dem Tabellen, Abbildungen und Formeln als zoombare Bildausschnitte erscheinen (Umrechnung beim Import im Hintergrund, zwischengespeichert); Lese-Einstellungen (Schrift, Größe, Zeilenabstand, hell/dunkel/Sepia); Markierungen und Notizen getrennt pro Ansicht; Oberfläche DE/EN.

**Zielgruppe:** Leser von Fachbüchern, wissenschaftlichen Papern und technischer Dokumentation, auch mit mehrspaltigem Layout.

**Nicht-Ziele:** OCR / gescannte PDFs; Cloud, Synchronisation, KI; Markierungen in die PDF schreiben; Markierungen zwischen Original und eBook abgleichen; Tabellen als echten Text nachbauen; Ordner automatisch überwachen; iOS-Release (Code bleibt plattformneutral). Details: `docs/project-brief.md`.

## Aktueller Status

Stand: 2026-11-18 – Roadmap angelegt, noch kein Task begonnen.

| Task | Titel | Status |
|---|---|---|
| 01 | Durchstich: Flutter-Gerüst, DE/EN, PDF öffnen und im Original anzeigen | offen |
| 02 | Reflow-Spike & Engine-Basis | offen |
| 03 | Spalten & Lesereihenfolge | offen |
| 04 | Blocktypen & Nicht-Text-Bereiche | offen |
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
- Tests liegen unter `tests/app/`, `tests/reflow_engine/`, `tests/integration/` und werden mit expliziten Pfaden ausgeführt (siehe `docs/testing.md`). *(Roadmap-Anlage)*

## Auffälligkeiten & Details

Dinge, die global noch zu beachten sind: Besonderheiten, bekannte Einschränkungen, kleinere Details. Wird laufend ergänzt.

- Hauptrisiko ist die Reflow-Qualität bei Mehrspaltern; deshalb liegen die Engine-Tasks (02–04) vor der App-Integration. *(Roadmap-Anlage)*
- Offene Entscheidungen des Nutzers: endgültige `applicationId` (Platzhalter `dev.paperflow`) und Copyright-Inhaber der MIT-Lizenz, beide spätestens in Task_12. *(Roadmap-Anlage)*
- In der Umgebung, in der die Roadmap angelegt wurde, war kein Flutter-SDK installiert. *(Roadmap-Anlage)*
