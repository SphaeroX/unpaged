# Projektbild

> Wann lesen: wenn Ziel, Umfang oder Abgrenzung des Projekts unklar sind.

## Ziel und Zielgruppe

paperflow ist ein Open-Source-PDF-Reader für Android. Er öffnet PDFs im Original-Layout und bietet zusätzlich einen **eBook-Modus**, der den Text wie ein EPUB neu umbricht (Reflow), damit er sich auf dem Handy bequem lesen lässt. Alles läuft komplett offline auf dem Gerät.

Zielgruppe: Leser von Fachbüchern, wissenschaftlichen Papern und technischer Dokumentation, auch mit mehrspaltigem Layout.

## Kernfunktionen (v1)

- PDFs öffnen und in der Original-Seitenansicht lesen
- eBook-Modus: Offline-Reflow von PDFs mit Textebene; Tabellen, Abbildungen und Formeln als Bildausschnitt des Originals, Antippen öffnet eine Zoom-Ansicht; Umrechnung beim Import im Hintergrund, zwischengespeichert
- Bibliothek mit Lesestand pro Datei
- Lese-Einstellungen: Schrift, Schriftgröße, Zeilenabstand, Themes (hell / dunkel / Sepia)
- Markierungen und Notizen, nur in der App gespeichert, getrennt pro Ansicht (Original bzw. eBook)
- Import über „Öffnen mit“, „Teilen“ und die Dateiauswahl in der App; die App legt eine eigene Kopie ab
- Oberfläche auf Deutsch und Englisch

## Nicht-Ziele (v1)

- Gescannte PDFs / Texterkennung (OCR)
- Cloud, Synchronisation oder KI
- Markierungen in die PDF-Datei schreiben
- Markierungen zwischen Original und eBook-Modus abgleichen
- Tabellen als echten Text nachbauen
- Ordner automatisch überwachen
- iOS-Release (Code bleibt plattformneutral)

## Rahmenbedingungen

- Komplett offline, keine Daten verlassen das Gerät
- Open Source unter MIT; Code öffentlich auf GitHub; alle Abhängigkeiten MIT-kompatibel (kein MuPDF/AGPL)
- Veröffentlichung im Google Play Store (Entwicklerkonto vorhanden); Android zuerst, `minSdk 24`
- Ein Entwickler, Umsetzung mit Claude Code

## Hauptrisiko

Die Reflow-Qualität bei mehrspaltigen Fachtexten. Abgesichert durch die isoliert testbare Engine und Snapshot-Tests gegen echte PDFs. Was offline nicht sauber als Text umbrechbar ist (Tabellen, Formeln), erscheint bewusst als Bildausschnitt.

## Offene Entscheidungen

- Android-`applicationId` (Platzhalter `dev.paperflow`), festzulegen vor dem ersten Store-Upload
- Copyright-Inhaber der MIT-Lizenz: entschieden – „The paperflow authors“
- URL des Datenschutzhinweises für den Play Store

---
Pflege: Bei Änderungen an Zielen oder Umfang diese Datei aktualisieren.
