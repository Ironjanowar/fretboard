# Key Suggestions & 7th Chords

## Overview

Two-phase feature for the Fretboard visualizer:

- **Fase 1:** Extender los acordes diatónicos para soportar 7th chords, con un toggle Triads/7ths en el Key modal.
- **Fase 2:** Sugerir automáticamente tonalidades compatibles con los acordes seleccionados, con botón "Ver tonalidad" para sustituir los acordes activos por los diatónicos de esa tonalidad.

---

## Fase 1: Acordes de Séptima Diatónicos

### F1.1 — 3 fórmulas nuevas en Chord.ex

Añadir al map `@formulas`:

| Quality | Fórmula | Etiqueta | Aparece en |
|---|---|---|---|
| `min_maj7` | `[0, 3, 7, 11]` | `mMaj7` | harmonic minor, melodic minor, phrygian dominant |
| `aug_maj7` | `[0, 4, 8, 11]` | `augMaj7` | harmonic minor, melodic minor, phrygian dominant |
| `aug7` | `[0, 4, 8, 10]` | `aug7` | whole tone |

Añadir al map `@labels` las 3 etiquetas correspondientes.

Añadir al grupo "Sevenths" en `grouped_qualities/0`:

```elixir
{"Sevenths", [:"7", :maj7, :min7, :dim7, :m7b5, :min_maj7, :aug_maj7, :aug7]}
```

**Archivos:** `lib/fretboard/music/chord.ex`

### F1.2 — Extender infer_quality en Scale.ex para 7th chords

Añadir reglas de 7th chords **antes** del fallback a triadas. Prioridad:

1. `m7b5` — min3 + dim5 + min7 (intervalos 3, 6, 10)
2. `dim7` — min3 + dim5 + dim7 (intervalos 3, 6, 9)
3. `min7` — min3 + perf5 + min7 (intervalos 3, 7, 10)
4. `7` (dominant) — maj3 + perf5 + min7 (intervalos 4, 7, 10)
5. `maj7` — maj3 + perf5 + maj7 (intervalos 4, 7, 11)
6. `min_maj7` — min3 + perf5 + maj7 (intervalos 3, 7, 11)
7. `aug_maj7` — maj3 + aug5 + maj7 (intervalos 4, 8, 11)
8. `aug7` — maj3 + aug5 + min7 (intervalos 4, 8, 10)

Después de estas reglas, caer al clasificador de triadas existente.

**Archivos:** `lib/fretboard/music/scale.ex`

### F1.3 — diatonic_chords con modo :triad | :seventh

Añadir un parámetro opcional a `diatonic_chords/2` (actual) → `diatonic_chords/3`:

```elixir
@spec diatonic_chords(String.t(), atom(), :triad | :seventh) :: [%{root: String.t(), quality: atom()}]
def diatonic_chords(tonic, scale_type, mode \\ :triad)
```

- `:triad` (default) → comportamiento actual (usa `infer_quality` que ahora prueba 7th primero pero el modo `:triad` debe forzar solo triadas).
- `:seventh` → usa `infer_7th_quality` que intenta 7th chord y **hace fallback a triada** cuando el grado no tiene nota de 7ª disponible (ej: pentatonic, blues).

Para mantener `:triad` produciendo solo triadas, separar la lógica:
- `infer_triad_quality/2` — clasificador de triadas existente (reglas actuales).
- `infer_7th_quality/2` — clasificador de 7th con fallback a triada.

Mantener `infer_quality/2` existente como alias público de `infer_triad_quality/2` para no romper la API actual.

**Archivos:** `lib/fretboard/music/scale.ex`, `lib/fretboard/music.ex` (facade)

### F1.4 — Toggle Triads/7ths en Key modal

Añadir un toggle (radio buttons o select) en el Key modal junto a Tonic y Scale:

```
Tonic: [C ▾]   Scale: [Major ▾]   Chords: [Triads | 7ths]
```

Nuevo assign `key_chord_mode: :triad` en el LiveView. El evento `update_key` actualiza también `key_chord_mode`. El evento `apply_key` pasa el modo a `Music.diatonic_chords/3`.

El preview de diatonic chords en el modal usa el modo seleccionado.

**Archivos:** `lib/fretboard_web/live/fretboard_live.ex`, `lib/fretboard_web/components/modals.ex`

### F1.5 — Tests Fase 1

- `chord_test.exs`: verificar 3 nuevas fórmulas, etiquetas, grouped_qualities.
- `scale_test.exs`:
  - `infer_7th_quality` para cada grado de major, minor, harmonic_minor, melodic_minor, lydian, whole_tone.
  - `diatonic_chords/3` con `:seventh` para C major → `[Cmaj7, Dmin7, Emin7, Fmaj7, G7, Amin7, Bm7b5]`.
  - `diatonic_chords/3` con `:seventh` para A harmonic minor → `[Amin_maj7, Bdim7, Caug_maj7, Ddim7, E7, Fdim7, G#dim7]`.
  - Fallback a triada en pentatonic/blues.
  - `diatonic_chords/3` con `:triad` (default) sigue produciendo triadas.
- `music_test.exs`: facade `diatonic_chords/3`.
- LiveView test: toggle cambia el preview, apply_key con 7ths genera los acordes correctos.

---

## Fase 2: Sugerencias de Tonalidades

### F2.1 — suggest_keys en Scale.ex + facade en Music.ex

Nueva función `Scale.suggest_keys/1`:

```elixir
@spec suggest_keys([%{root: String.t(), quality: atom()}]) :: [map()]
```

**Algoritmo:**

1. Excluir `:chromatic` de los candidatos (demasiado genérico).
2. Para cada combinación de tonic (12 notas cromáticas) × scale_type (14 escalas restantes) = 168 candidatos:
   - Calcular `scale_notes(tonic, scale_type)`.
   - Para cada acorde de entrada, calcular `Chord.notes(root, quality)`.
   - Si **todas** las notas de **todos** los acordes están contenidas en las notas de la escala → candidato válido.
3. Para cada candidato válido, calcular `diatonic_chords(tonic, scale_type)` y puntuar:
   - **Triadas:** +1 si el acorde coincide exactamente con un acorde diatónico (root + quality).
   - **7th chords:** mapear a triada base (`maj7`→`major`, `7`→`major`, `min7`→`minor`, `dim7`→`dim`, `m7b5`→`dim`, `min_maj7`→`minor`, `aug_maj7`→`aug`, `aug7`→`aug`) y verificar si esa triada es diatónica. +1 si coincide.
4. Ordenar por score descendente, luego por tonic, luego por scale_type.

**Retorno:** lista de `%{tonic, scale_type, score, total, diatonic_chords}`.

Facade en `Music.ex`: `suggest_keys/1` delega a `Scale.suggest_keys/1`.

**Archivos:** `lib/fretboard/music/scale.ex`, `lib/fretboard/music.ex`

### F2.2 — Recálculo automático en handle_params

Añadir assign `key_suggestions: []`.

En `handle_params`, después de actualizar `active_chords`:
- Si `length(active_chords) >= 2` → `key_suggestions = Music.suggest_keys(active_chords)`.
- Si `< 2` → `key_suggestions = []`.

No requiere evento ni botón — se recalcula en cada cambio de URL.

**Archivos:** `lib/fretboard_web/live/fretboard_live.ex`

### F2.3 — Sección UI debajo de chord chips

Nueva sección en el render, después de `.chords-wrapper`:

```
Tonalidades compatibles:
  [C Major]  Ver tonalidad →
  [A Minor]  Ver tonalidad →
  ▸ 5 modos adicionales (Dorian, Phrygian, Lydian, Mixolydian, Locrian)
```

Solo se muestra si `key_suggestions` no está vacía.

Si `key_suggestions` está vacía y hay ≥2 acordes activos → mensaje: "No se encontraron tonalidades compatibles con estos acordes".

**Archivos:** `lib/fretboard_web/live/fretboard_live.ex` (render), posiblemente CSS en `app.css`.

### F2.4 — Agrupación de modos relativos

Las 7 escalas modales diatónicas comparten las mismas notas:
- `major`, `minor`, `dorian`, `phrygian`, `lydian`, `mixolydian`, `locrian`

**Lógica de agrupación:**

1. De las sugerencias con score máximo, identificar cuáles pertenecen a la misma familia modal (misma set de notas).
2. De cada familia, mostrar las dos principales: la `major` y su relativa `minor`.
3. Los modos restantes (dorian, phrygian, lydian, mixolydian, locrian) se colapsan bajo "N modos adicionales".
4. Escalas no modales (pentatonic, blues, harmonic_minor, melodic_minor, phrygian_dominant, whole_tone) se muestran individualmente sin agrupar.

**Detección de familia modal:** dos escalas son de la misma familia si `Set(scale_notes(A)) == Set(scale_notes(B))`.

Si no hay score máximo, mostrar top 3 sugerencias sin agrupar (según decisión: fallback top 3).

**Archivos:** `lib/fretboard/music/scale.ex` (función auxiliar de agrupación), `lib/fretboard_web/live/fretboard_live.ex` (render).

### F2.5 — Botón "Ver tonalidad" → apply_suggested_key

Nuevo evento `apply_suggested_key` que recibe `tonic` y `scale_type`:

```elixir
def handle_event("apply_suggested_key", %{"tonic" => tonic, "scale_type" => scale_type}, socket) do
  # Usar el mismo chord_mode que tenga el key_modal, o :triad por defecto
  mode = socket.assigns[:key_chord_mode] || :triad
  active_chords = Music.diatonic_chords(tonic, String.to_existing_atom(scale_type), mode)

  {:noreply,
   push_url_patch(socket, socket.assigns.instrument, socket.assigns.tuning, active_chords, nil)}
end
```

Esto sustituye completamente los acordes activos por los diatónicos de la tonalidad elegida (mismo mecanismo que `apply_key`).

Las sugerencias se recalculan automáticamente en el siguiente `handle_params`.

**Archivos:** `lib/fretboard_web/live/fretboard_live.ex`

### F2.6 — Tests Fase 2

- `scale_test.exs`:
  - `suggest_keys` con C-F-G → C major, A minor, D dorian, etc. (score 3/3).
  - `suggest_keys` con C-Am-F-G → 7 modos con score 4/4.
  - `suggest_keys` con Cmaj7-Dm7-G7 → C major con score 3/3 (via 7th→triad matching).
  - `suggest_keys` con C major + C# major → solo escalas exóticas o vacío.
  - `suggest_keys` con lista vacía → todas las escalas (o filtrar por mínimos).
  - `suggest_keys` con 1 acorde → funciona pero no se muestra en UI.
  - Agrupación de modos relativos.
- `music_test.exs`: facade `suggest_keys/1`.
- LiveView test:
  - Con 2+ acordes, la sección de sugerencias aparece.
  - Con <2 acordes, no aparece.
  - Click en "Ver tonalidad" sustituye los acordes.
  - Mensaje cuando no hay compatibles.

---

## Decisiones

| # | Decisión | Detalle |
|---|---|---|
| 1 | Cálculo automático | En `handle_params`, sin botón manual |
| 2 | Ubicación UI | Sección inline debajo de chord chips |
| 3 | Score | Mostrar solo score máximo; si no hay, top 3 |
| 4 | Agrupación modos | Major + minor visibles, 5 modos colapsados |
| 5 | Comportamiento "Ver tonalidad" | Sustituir completamente (igual que `apply_key`) |
| 6 | Post-aplicación | Recalcular normalmente, sin estados especiales |
| 7 | Dos fases | Fase 1: 7th chords diatónicos. Fase 2: sugerencias |
| 8 | Toggle Triads/7ths | Dentro del Key modal |
| 9 | 3 fórmulas nuevas en selector | `min_maj7`, `aug_maj7`, `aug7` añadidas al select |
| 10 | Etiquetas | `mMaj7`, `augMaj7`, `aug7` |
| 11 | Progresiones | Se quedan en triadas (TODO futuro) |
| 12 | Fallback 7th | Triada cuando el grado no tiene nota de 7ª |
| 13 | Agrupación solo modos diatónicos | Pentatonic, blues, etc. se muestran individuales |
| 14 | Sin marcado de tonalidad activa | Sin estado extra |
| 15 | Sin compatibles | Mensaje simple; multi-tonalidad es TODO futuro |
| 16 | Mínimo 2 acordes | Con 0 o 1, no se muestra la sección |
| 17 | Plan en `plans/key-suggestions.md` | Estructura acordada |

---

## TODO futuro

- **Progresiones con 7ths:** Extender `Progression.ex` para que las progresiones puedan generar acordes de séptima. Requiere revisar cada progresión del catálogo (59) para verificar que las 7ths tienen sentido musical. Añadir toggle Triads/7ths al progression modal.
- **Detección de multi-tonalidad:** Permitir detectar cuando los acordes seleccionados provienen de dos tonalidades distintas sin notas en común (modulación). Estudiar algoritmos para segmentar el conjunto de acordes en grupos por tonalidad y mostrar múltiples sugerencias.