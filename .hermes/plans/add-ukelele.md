# Añadir Ukelele — Plan de Implementación

## Resumen

Añadir el instrumento ukelele (4 cuerdas, afinación estándar G C E A) con 4 presets
de afinación al sistema existente. El cambio es puramente data-driven: no requiere
modificar la lógica de cálculo de notas, acordes, escalas ni el SVG.

## Decisiones de diseño (grill-me session)

- **Atom**: `:ukelele`
- **Label UI**: `"Ukelele"` (sin "(4-string)")
- **URL string**: `"ukelele"`
- **Trastes**: 24 para todos los instrumentos (sin refactor — `@fret_count` ya es 24)
- **Afinaciones (4 presets)**:
  1. Standard → `["G", "C", "E", "A"]`
  2. D tuning → `["A", "D", "F#", "B"]`
  3. Baritone → `["D", "G", "B", "E"]`
  4. Half Step Down → `["F#", "B", "D#", "G#"]`
- **Nota sobre "ukulele"**: el string `"ukulele"` (con 'u') sigue siendo tratado
  como instrumento inválido → fallback a guitar. Solo `"ukelele"` es válido.

## Archivos a modificar

### 1. `lib/fretboard/music/instrument.ex`

- Añadir `@ukelele_presets` con los 4 presets
- Añadir entrada `:ukelele` en `@instruments` map:
  ```elixir
  ukelele: %{
    name: "Ukelele",
    strings: 4,
    standard_tuning: ["G", "C", "E", "A"],
    presets: @ukelele_presets,
    frets: 24
  }
  ```
- Actualizar `@type instrument_key :: :guitar | :bass_4 | :bass_5 | :ukelele`
- Añadir `{:ukelele, "Ukelele"}` a `instruments/0`
- Extender guards en 5 funciones: `when key in [:guitar, :bass_4, :bass_5, :ukelele]`
  - `instrument/1`
  - `instrument_strings/1`
  - `instrument_standard_tuning/1`
  - `instrument_tuning_presets/1`
  - `instrument_preset_names/1`

### 2. `lib/fretboard/music/url_codec.ex`

- Añadir `ukelele: "ukelele"` a `@instrument_to_string`
- Añadir `"ukelele" => :ukelele` a `@string_to_instrument`

### 3. Tests (escritos por Test Writer, verificados fallando)

- `test/fretboard/music/instrument_test.exs` — actualizar count 3→4, añadir
  tests para ukelele (name, strings, standard_tuning, 4 presets, frets, preset values)
- `test/fretboard/music_test.exs` — actualizar count 3→4, añadir tuple y tests
- `test/fretboard/music/url_codec_test.exs` — añadir tests de encode/decode para ukelele
- `test/fretboard_web/live/fretboard_live_test.exs` — actualizar count 3→4, assert "Ukelele"

## Lo que NO cambia

- `lib/fretboard/music.ex` — la facade delega a `Instrument`, no necesita cambios
- `lib/fretboard_web/live/fretboard_live.ex` — el dropdown ya itera `Music.instruments()`
- `lib/fretboard_web/components/modals.ex` — ya renderiza por `string_count`
- `lib/fretboard/music/note.ex`, `chord.ex`, `scale.ex` — agnósticos al instrumento
- `@fret_count 24` en el LiveView — ya es 24, no necesita cambios

## Workflow

1. **Test Writer** — escribe tests fallando, verifica `mix test` falla
2. **Implementer** — implementa cambios mínimos, verifica `mix test` pasa
3. **Reviewer** — `mix test`, `mix format --check-formatted`, `mix credo --strict`
