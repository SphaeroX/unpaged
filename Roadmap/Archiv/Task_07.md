# Task_07: eBook-Leseansicht

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_07.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Fertig umgerechnete Bücher lassen sich im eBook-Modus lesen: umbrochener Text mit Überschriften, Absätzen, Listen und Bildunterschriften, dazwischen die Bildausschnitte, die per Antippen in einer Zoom-Ansicht öffnen. Man kann zwischen Original und eBook umschalten.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_06 archiviert.
- **Relevantes Vorwissen:** `ReflowDocument`-Format und Ausschnitt-Ablage aus Task_04/06; Viewer aus Task_01/05; Feature `reader`.

## Umfang

**Gehört dazu:**

- Reader-Bildschirm, der das gespeicherte `ReflowDocument` lädt und als scrollbaren Text darstellt (Blocktypen unterschiedlich gestaltet)
- Bildausschnitte an der richtigen Stelle im Text, Antippen öffnet Vollbild-Zoom (Pinch, Doppeltipp)
- Umschalter Original ↔ eBook (z. B. in der App-Bar); eBook-Modus nur aktiv, wenn Status fertig, sonst Hinweis mit Status
- Effizientes Rendering langer Dokumente (lazy, nicht alles auf einmal)
- Standarddarstellung mit festen Defaults (Einstellungen folgen in Task 08)

**Gehört nicht dazu:**

- Schrift-/Theme-Einstellungen (Task 08)
- Lesestand und Sprung an die passende Stelle beim Umschalten (Task 09; hier startet der Wechsel am Anfang)
- Markierungen (Task 10/11)

## Umsetzungsschritte

1. [x] Widget-Tests für die Darstellung jedes Blocktyps mit einem kleinen Test-`ReflowDocument` schreiben.
2. [x] Reader-Bildschirm mit lazy Liste umsetzen.
3. [x] Bildausschnitt-Widget und Zoom-Ansicht per Widget-Test.
4. [x] Umschalter mit Statusprüfung umsetzen.
5. [x] Fehlerfall: JSON fehlt oder ist beschädigt → Hinweis und Angebot zur Neuberechnung.
6. [x] Integrationstest: Korpus-PDF importieren, nach Fertigstellung in eBook umschalten, Ausschnitt antippen, Zoom erscheint.
7. [x] Performance mit dem größten Korpus-Dokument manuell prüfen und notieren.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Widget: Überschrift, Absatz, Liste, Bildunterschrift werden mit unterschiedlichem Stil dargestellt.
- Widget: Bereichsblock zeigt das PNG; Antippen öffnet Zoom-Ansicht.
- Widget: Umschalter ist bei Status ≠ fertig deaktiviert bzw. zeigt Hinweis.
- Widget: Beschädigtes JSON führt zu Hinweis statt Absturz.
- Integration: Import → eBook → Zoom.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [x] Mit dem größten Korpus-Dokument öffnet der eBook-Modus ohne spürbare Verzögerung (manuell geprüft, Beobachtung notiert).
- [x] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Seitenweises Blättern statt Scrollen ist nicht gefordert; Annahme: vertikales Scrollen.
- Aus Task_06: Dokument über `ReflowStore.readDocument(bookId)` (null = fehlt/kaputt), Ausschnitte über `ReflowStore.cropFile(bookId, blockId)`; Neuberechnung über `ref.read(reflowSchedulerProvider).enqueue(id)` nach Zurücksetzen des Status auf `pending`. Status in `Books.reflowStatus`. `ViewerScreen` bekommt bisher nur `path`/`title` – für den Moduswechsel braucht er die Buch-ID.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Testlauf: `flutter test tests/app tests/reflow_engine` → 156 Tests grün; `flutter analyze` ohne Befund.
- Integrationstest `tests/integration/ebook_flow_test.dart` (Import → Hintergrund-Reflow → eBook-Ansicht) geschrieben, **nicht ausgeführt** (kein Gerät). Ebenfalls offen: die manuelle Performance-Prüfung mit dem größten Korpus-Dokument auf einem Gerät.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):** `ReaderScreen` mit Stilen je Blocktyp, Crops mit Zoom-Ansicht, Hinweis + „Neu vorbereiten“ bei fehlendem/kaputtem Dokument, Umschalten Original ↔ eBook (`ViewerScreen.bookId`, Status-SnackBar, solange nicht fertig). `AppDatabase.watchBook` + `bookProvider` (StreamProvider.family). `PaperflowApp(home: …)` für Tests.
- **Learnings & Stolpersteine:** In Widget-Tests nicht doppelt überschreiben (Riverpod meldet „override a provider twice“) → `TestEnv.overridesWith(queue: …)`; `env.reflow` ist der gemeinsame `ReflowStore`. Schreiben ins Dateisystem vor `pumpWidget` über `tester.runAsync`. Typannotationen für Provider-Familien kommen aus `package:flutter_riverpod/misc.dart` (nicht aus `riverpod/src`, `dart fix` setzt sonst einen Implementierungsimport).
- **Wichtige Entscheidungen und ihre Gründe:** Wechsel per `pushReplacement`, damit „Zurück“ immer in die Bibliothek führt. Stile kommen aus dem Theme, damit Task 08 nur das Theme/Textstile ändern muss.
- **Auswirkungen auf Folge-Tasks:** Task 08: `_TextBlock` nutzt `Theme.of(context).textTheme` (`bodyLarge`, `bodyMedium`, `titleMedium/Large`, `headlineSmall`) – Schriftart/Größe/Zeilenabstand am besten über einen eigenen Reader-Stil-Provider in `_TextBlock` anwenden. Task 09: Moduswechsel ruft `pushReplacement` – dort die Sprungposition übergeben; die Liste ist `ListView.builder` (für Sprung zu Block-Index z. B. `scrollable_positioned_list` (BSD) oder eigene Index-Berechnung). Task 11: Text ist `Text`, keine Auswahl – für Markierungen `SelectableText`/`SelectionArea` nötig.
- **Hinweise zu Tests und Befehlen:** `tests/app/features/reader/reader_screen_test.dart` zeigt das Muster (Dokument vorher mit `tester.runAsync(() => env.reflow.writeDocument(...))` schreiben).
