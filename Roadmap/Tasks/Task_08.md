# Task_08: Lese-Einstellungen

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_08.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Nutzer passen den eBook-Modus an: Schrift, Schriftgröße, Zeilenabstand und Theme (hell / dunkel / Sepia). Die Einstellungen werden dauerhaft gespeichert und sofort angewendet.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_07 archiviert.
- **Relevantes Vorwissen:** Reader aus Task_07; Theming in `lib/core/` (`docs/code-style.md`: keine Farbwerte direkt in Widgets); Feature `settings`.

## Umfang

**Gehört dazu:**

- Einstellungsmodell und Persistenz (drift oder geeigneter lokaler Speicher; Entscheidung dokumentieren)
- Auswahl aus einigen mitgelieferten, frei lizenzierten Schriften (z. B. OFL) plus Systemschrift; Lizenzen im Projekt ablegen
- Schriftgröße und Zeilenabstand in sinnvollen Stufen mit Grenzen
- Themes hell, dunkel, Sepia für den Reader; das Theme gilt auch für die restliche App (Sepia → hell oder eigene Variante, im Task entscheiden)
- Einstellungs-UI (z. B. Bottom-Sheet im Reader) mit Live-Vorschau
- Texte EN/DE

**Gehört nicht dazu:**

- Einstellungen für die Originalansicht außer dem Theme
- Eigene Schriften des Nutzers importieren

## Umsetzungsschritte

1. [ ] Einstellungsmodell mit Defaults und Grenzen per TDD.
2. [ ] Persistenz per TDD (Speichern, Laden, Defaults bei leerem Speicher).
3. [ ] Themes in `lib/core/` definieren und per Widget-Test prüfen.
4. [ ] Schriften einbinden, Lizenzdateien ablegen, in `docs/architecture.md` vermerken.
5. [ ] Reader an die Einstellungen anbinden.
6. [ ] Einstellungs-UI mit Live-Vorschau per Widget-Test.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Unit: Defaults, Grenzen (Schriftgröße nicht unter/über Limit), Persistenz-Roundtrip.
- Widget: Änderung der Schriftgröße wirkt sofort im Reader.
- Widget: Theme-Wechsel ändert Hinter- und Vordergrundfarbe des Readers.
- Unit/Widget: Einstellungen überstehen einen Neustart (neuer Provider-Container liest gespeicherte Werte).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `flutter test tests/app` grün.
- [ ] Lizenzen der mitgelieferten Schriften liegen im Repo und sind MIT-kompatibel (z. B. OFL).
- [ ] `flutter analyze` ohne Befund.

## Offene Fragen / Annahmen

- Welche Schriften mitgeliefert werden, entscheidet der Task (Annahme: 2–3 gut lesbare Serif/Sans-Schriften unter OFL).

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
