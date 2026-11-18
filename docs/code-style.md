# Code-Styling und Formatierung

> Wann lesen: vor dem Schreiben, Ändern oder Formatieren von Code.

## Werkzeuge

- Formatter: `dart format` – Befehl: `dart format .`
- Linter: `very_good_analysis` – Befehl: `flutter analyze`
- Konfiguration liegt in `analysis_options.yaml` (App und `packages/reflow_engine/`); die Regeln dort sind maßgeblich und werden hier nicht wiederholt.

## Verbindlich

- Dart 3.14: Konstruktoren in der neuen Kurzform `const new(...)` schreiben (Lint `unnecessary_type_name_in_constructor`); `dart fix --apply` erledigt das.
- `public_member_api_docs` ist abgeschaltet (App-Code, keine öffentliche Bibliothek).
- Lint-Regeln nicht per `// ignore:` umgehen, außer mit Kommentar, der den Grund nennt.
- Keine generierten Riverpod-Provider (`riverpod_generator`); Provider von Hand schreiben. Codegenerierung ist nur für drift erlaubt.
- Alle sichtbaren Texte über `AppLocalizations` (ARB-Dateien), keine hart kodierten Strings in Widgets.
- Farben und Textstile über das Theme (`lib/core/`), keine Farbwerte direkt in Widgets.

## Empfehlung

- Kleine, reine Funktionen in der Engine bevorzugen; sie sind leichter per Snapshot und Unit-Test zu prüfen.

---
Pflege: Bei Änderungen an Stil- oder Tool-Regeln diese Datei sofort aktualisieren.
