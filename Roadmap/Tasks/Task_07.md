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

1. [ ] Widget-Tests für die Darstellung jedes Blocktyps mit einem kleinen Test-`ReflowDocument` schreiben.
2. [ ] Reader-Bildschirm mit lazy Liste umsetzen.
3. [ ] Bildausschnitt-Widget und Zoom-Ansicht per Widget-Test.
4. [ ] Umschalter mit Statusprüfung umsetzen.
5. [ ] Fehlerfall: JSON fehlt oder ist beschädigt → Hinweis und Angebot zur Neuberechnung.
6. [ ] Integrationstest: Korpus-PDF importieren, nach Fertigstellung in eBook umschalten, Ausschnitt antippen, Zoom erscheint.
7. [ ] Performance mit dem größten Korpus-Dokument manuell prüfen und notieren.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Widget: Überschrift, Absatz, Liste, Bildunterschrift werden mit unterschiedlichem Stil dargestellt.
- Widget: Bereichsblock zeigt das PNG; Antippen öffnet Zoom-Ansicht.
- Widget: Umschalter ist bei Status ≠ fertig deaktiviert bzw. zeigt Hinweis.
- Widget: Beschädigtes JSON führt zu Hinweis statt Absturz.
- Integration: Import → eBook → Zoom.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app` grün; Integrationstest grün oder begründet vermerkt.
- [ ] Mit dem größten Korpus-Dokument öffnet der eBook-Modus ohne spürbare Verzögerung (manuell geprüft, Beobachtung notiert).
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Seitenweises Blättern statt Scrollen ist nicht gefordert; Annahme: vertikales Scrollen.

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
