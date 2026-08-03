# Multi-Tonalidad

## Overview

Extensión del sistema de key suggestions para detectar cuando un grupo de acordes proviene de múltiples tonalidades, en lugar de una sola. Se activa **solo como fallback** cuando `suggest_keys/1` no encuentra ninguna tonalidad común que contenga todos los acordes.

---

## Decisiones (grill-me)

| # | Decisión | Detalle |
|---|---|---|
| 1 | Activación | Solo cuando `suggest_keys` devuelve `[]` (sin tonalidad común) |
| 2 | Algoritmo | Greedy Set Cover — seleccionar iterativamente la key que cubre más acordes restantes |
| 3 | Solapamiento | Permitir que un acorde aparezca en varios grupos si encaja en varias tonalidades |
| 4 | Máximo de grupos | 3 grupos. Acordes restantes → "sin tonalidad compatible" |
| 5 | Desempate de key ganadora | Mayor coincidencia diatónica, luego priorizar escalas comunes (major > minor > modos > exóticas) |
| 6 | Estructura de retorno | `[%{key: %{tonic, scale_type, score, total, diatonic_chords}, chords: [chord_map]}]` |
| 7 | UI | Bloques por grupo: tarjeta de key completa + fila "Tus acordes" con chips del input |
| 8 | Acordes sin grupo | Sección final "Acordes sin tonalidad compatible" con chips grises |
| 9 | Ubicación del código | `suggest_multi_keys/1` en `Scale.ex`, facade `Music.suggest_multi_keys/1` |
| 10 | Botón "Ver tonalidad" | Sustituye todos los acordes por los diatónicos de la key clicada (igual que ahora) |
| 11 | Texto de encabezado | "No hay una tonalidad común. Se encontraron N tonalidades:" |
| 12 | Integración async | Mismo `assign_async`, dos resultados: `key_suggestions` + `multi_key_suggestions` |
| 13 | Agrupación de modos relativos | No agrupar en multi-tonalidad. Cada grupo muestra su key ganadora directamente |
| 14 | Criterio de cobertura | Estricto: todas las notas del acorde ⊆ notas de la escala (igual que `suggest_keys`) |
| 15 | Scoring diatónico | Mismo mapeo 7th→triad de `suggest_keys` (`@seventh_to_triad`) |
| 16 | Mínimo de acordes | 3 acordes para activar multi-tonalidad. Con 2, mensaje "No se encontraron" |
| 17 | Prioridad de escalas | Derivar del orden de `@grouped_scale_types` existente |
| 18 | Orden de grupos | Por cobertura descendente (más acordes cubiertos primero) |
| 19 | Color de "Tus acordes" | Mismo color que el acorde tiene en los chord chips superiores (índice del input original) |
| 20 | Todos grupos de 1 acorde | Si todos los grupos son de 1 acorde, mostrar mensaje "No se encontraron" en lugar de N grupos |
| 21 | Plan en `plans/multi-tonality.md` | Documento formal antes de implementar |

---

## Algoritmo: Greedy Set Cover

### `suggest_multi_keys/1`

```elixir
@spec suggest_multi_keys([%{root: String.t(), quality: atom()}]) :: [map()]
```

**Pasos:**

1. Precomputar las notas de cada acorde (`Chord.notes/2` → `MapSet`).
2. Para cada uno de los 168 candidatos (12 tónicas × 14 escalas, sin `:chromatic`):
   - Calcular `scale_notes(tonic, scale_type)` → `MapSet`.
   - Calcular cuántos acordes del input tienen todas sus notas ⊆ escala (cobertura estricta).
   - Calcular cuántos de esos acordes coinciden con un diatónico de la escala (score diatónico, vía `@seventh_to_triad`).
3. **Iteración Greedy (máximo 3 grupos):**
   - Seleccionar la key con mayor cobertura (más acordes cubiertos).
   - Desempate: mayor score diatónico, luego prioridad de escala (orden de `@grouped_scale_types`).
   - Crear grupo: `%{key: result_map, chords: [acordes cubiertos por esta key]}`.
   - Los acordes cubiertos **no se eliminan** del pool (permitir solapamiento), pero se marcan como cubiertos para el conteo de cobertura de la siguiente iteración.
   - Solo se cuentan acordes no cubiertos previamente para la cobertura de la siguiente key.
4. **Parada:**
   - Tras 3 grupos, o cuando no queden acordes por cubrir, o cuando no haya key que cubra ningún acorde restante.
5. **Filtro de grupos de 1:**
   - Si todos los grupos son de 1 acorde, devolver `[]` (el UI mostrará el mensaje "No se encontraron").
6. **Acordes sin grupo:**
   - Los acordes que no fueron cubiertos por ningún grupo se incluyen en el resultado como `%{key: nil, chords: [acordes sin tonalidad]}` al final de la lista.

**Retorno:**

```elixir
[
  %{
    key: %{tonic: "C", scale_type: :major, score: 3, total: 5, diatonic_chords: [...]},
    chords: [%{root: "C", quality: :major}, %{root: "F", quality: :major}, ...]
  },
  %{
    key: %{tonic: "G", scale_type: :major, score: 2, total: 5, diatonic_chords: [...]},
    chords: [%{root: "D", quality: :major}, %{root: "A", quality: :minor}]
  },
  %{
    key: nil,
    chords: [%{root: "Bb", quality: :major}]  # sin tonalidad compatible
  }
]
```

- `key` reutiliza el formato de `suggest_keys/1` (tonic, scale_type, score, total, diatonic_chords).
- `key: nil` marca el grupo de acordes sin tonalidad.
- `chords` lista los acordes del input que pertenecen a este grupo (con solapamiento posible entre grupos con `key` real).
- `score` = cuántos de los acordes del grupo son diatónicos en esa key.
- `total` = total de acordes del input completo (no del grupo).

### Prioridad de escalas (desempate)

Derivar del orden de `@grouped_scale_types`:

```elixir
# Orden de prioridad (de mayor a menor):
# major, minor, harmonic_minor, melodic_minor,
# pentatonic_major, pentatonic_minor, blues,
# dorian, phrygian, lydian, mixolydian, locrian,
# phrygian_dominant, whole_tone
```

Generar un mapa `%{scale_type => priority_index}` a partir del orden aplanado de `@grouped_scale_types`. Menor índice = mayor prioridad.

---

## Cambios por archivo

### 1. `lib/fretboard/music/scale.ex` — `suggest_multi_keys/1`

Nueva función pública `suggest_multi_keys/1`:

- Reutiliza `scale_notes/2`, `diatonic_chords/3`, `@seventh_to_triad`, `@triad_qualities`, `triad_base_quality/1`.
- Nueva constante derivada: `@scale_priority` (map de scale_type → índice de prioridad) generada desde `@grouped_scale_types`.
- Nuevas funciones privadas:
  - `candidate_coverages(chords, chord_note_sets)` — calcula para cada uno de los 168 candidatos qué acordes cubre y su score diatónico.
  - `select_best_candidate(candidates, covered)` — selecciona la key con mayor cobertura entre acordes no cubiertos, con desempate por score diatónico y prioridad de escala.
  - `greedy_groups(chords, chord_note_sets, max_groups)` — bucle iterativo del Greedy Set Cover.

### 2. `lib/fretboard/music.ex` — facade

```elixir
@spec suggest_multi_keys([%{root: String.t(), quality: atom()}]) :: [map()]
def suggest_multi_keys(chords), do: Scale.suggest_multi_keys(chords)
```

### 3. `lib/fretboard_web/live/fretboard_live.ex`

#### 3a. `mount` — nuevo assign

```elixir
multi_key_suggestions: AsyncResult.loading()
```

#### 3b. `handle_params` — async unificado

Reemplazar el `assign_async` actual:

```elixir
|> assign_async(:key_suggestions, fn ->
  if length(chords) >= 2 do
    suggestions = Music.suggest_keys(chords)
    multi =
      if suggestions == [] and length(chords) >= 3 do
        Music.suggest_multi_keys(chords)
      else
        []
      end
    {:ok, %{key_suggestions: suggestions, multi_key_suggestions: multi}}
  else
    {:ok, %{key_suggestions: [], multi_key_suggestions: []}}
  end
end)
```

Nota: `assign_async` puede actualizar múltiples assigns si el resultado los incluye. Verificar que `assign_async(:key_suggestions, ...)` con `%{key_suggestions: ..., multi_key_suggestions: ...}` actualiza ambos assigns — si no, usar dos `assign_async` anidados o un `assign` tras resolver.

#### 3c. `render` — sección multi-tonalidad

Después del bloque `<.async_result>` existente, añadir un nuevo bloque para `@multi_key_suggestions`:

```heex
<.async_result :let={multi_key_suggestions} assign={@multi_key_suggestions}>
  <:loading>
    <div :if={length(@active_chords) >= 3} class="key-suggestions-wrapper">
      <p class="key-suggestions-loading">Analizando tonalidades...</p>
    </div>
  </:loading>
  <:failed>
    <div :if={length(@active_chords) >= 3} class="key-suggestions-wrapper">
      <p class="text-muted">Error al calcular tonalidades.</p>
    </div>
  </:failed>
  <div :if={multi_key_suggestions != [] and length(@active_chords) >= 3} class="key-suggestions-wrapper">
    <label class="section-label" style="width:100%">
      No hay una tonalidad común. Se encontraron {length(Enum.filter(multi_key_suggestions, &(&1.key != nil)))} tonalidades:
    </label>

    <%= for {group, i} <- Enum.with_index(multi_key_suggestions) do %>
      <%= if group.key == nil do %>
        <%!-- Acordes sin tonalidad compatible --%>
        <div class="multi-key-unmatched">
          <span class="multi-key-unmatched-label">Acordes sin tonalidad compatible:</span>
          <%= for chord <- group.chords do %>
            <span class="chord-chip chord-chip--unmatched">
              {Music.chord_label(chord.root, chord.quality)}
            </span>
          <% end %>
        </div>
      <% else %>
        <%!-- Grupo tonal --%>
        <div class="multi-key-group">
          <span class="multi-key-group-label">Tonalidad {i + 1}</span>
          <div
            class="key-card"
            phx-click="apply_suggested_key"
            phx-value-tonic={group.key.tonic}
            phx-value-scale_type={group.key.scale_type}
          >
            <div class="key-card-header">
              <span class="key-card-title">
                {Music.scale_label(group.key.scale_type)} {group.key.tonic}
              </span>
              <span class="key-card-score">{group.key.score}/{group.key.total}</span>
            </div>
            <div class="key-card-chips">
              <%= for {dc, j} <- Enum.with_index(group.key.diatonic_chords) do %>
                <span
                  class="key-card-chip"
                  style={chord_color(j, @chord_colors) |> then(&"background-color: #{&1};")}
                >
                  {Music.chord_label(dc.root, dc.quality)}
                </span>
              <% end %>
            </div>
            <div class="key-card-arrow">Ver tonalidad →</div>
          </div>
          <div class="multi-key-your-chords">
            <span class="multi-key-your-chords-label">Tus acordes:</span>
            <%= for chord <- group.chords do %>
              <%!-- Encontrar el índice del acorde en el input original para usar su color --%>
              <% chord_idx = Enum.find_index(@active_chords, &(&1 == chord)) %>
              <span
                class="key-card-chip"
                style={chord_color(chord_idx, @chord_colors) |> then(&"background-color: #{&1};")}
              >
                {Music.chord_label(chord.root, chord.quality)}
              </span>
            <% end %>
          </div>
        </div>
      <% end %>
    <% end %>
  </div>
</.async_result>
```

#### 3d. CSS — `priv/static/assets/css/app.css`

Nuevas clases:

```css
.multi-key-group {
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.multi-key-group:last-child {
  border-bottom: none;
}

.multi-key-group-label {
  display: block;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #9ca3af;
  margin-bottom: 0.5rem;
}

.multi-key-your-chords {
  margin-top: 0.5rem;
  padding-left: 0.5rem;
}

.multi-key-your-chords-label {
  font-size: 0.75rem;
  color: #6b7280;
  margin-right: 0.5rem;
}

.multi-key-unmatched {
  margin-top: 0.5rem;
  padding: 0.75rem;
  background: rgba(107, 114, 128, 0.08);
  border-radius: 0.5rem;
}

.multi-key-unmatched-label {
  font-size: 0.75rem;
  color: #6b7280;
  margin-right: 0.5rem;
}

.chord-chip--unmatched {
  opacity: 0.5;
  filter: grayscale(1);
}
```

### 4. Tests

#### 4a. `test/fretboard/music/scale_test.exs`

```
describe "suggest_multi_keys/1"
  - C major + F major + G major + D major + A major → 2 grupos (C major cubre C,F,G; G major cubre G,D,A)
    - Verificar que group 1 tiene key C major, chords [C, F, G]
    - Verificar que group 2 tiene key G major, chords [D, A] (G puede solaparse)
    - Verificar orden por cobertura descendente
  - 3 acordes incompatibles (C major + C# major + F# major) → [] (todos grupos de 1)
  - 3 acordes de C major + 2 acordes de B major → 2 grupos, ningún acorde sin tonalidad
  - C major + F major + G major + Bb major + D major → 2 grupos + 1 sin tonalidad (Bb?)
    - Verificar grupo "sin tonalidad" tiene key: nil
  - Cmaj7 + Fmaj7 + G7 + D7 + A7 → 2 grupos via 7th→triad matching
  - Lista vacía → []
  - 1 acorde → []
  - 2 acordes → [] (mínimo 3)
  - Estructura de cada grupo: key nil o %{tonic, scale_type, score, total, diatonic_chords}, chords lista
  - Máximo 3 grupos con key real
  - Solapamiento: G major aparece en ambos grupos cuando corresponde
```

#### 4b. `test/fretboard/music/music_test.exs`

- Facade `suggest_multi_keys/1` delega a `Scale.suggest_multi_keys/1`.

#### 4c. `test/fretboard_web/live/fretboard_live_test.exs`

- Con 3+ acordes sin tonalidad común → aparece sección multi-tonalidad.
- Con 2 acordes sin tonalidad común → mensaje "No se encontraron" (no multi-tonalidad).
- Con 3+ acordes con tonalidad común → no aparece sección multi-tonalidad.
- Click en "Ver tonalidad" de un grupo → sustituye acordes.
- Acordes sin tonalidad aparecen como chips grises.
- Todos grupos de 1 acorde → mensaje "No se encontraron" en lugar de multi-tonalidad.

---

## Flujo de decisión

```
handle_params (≥2 acordes)
  │
  ├─ suggest_keys(chords) → [resultados] ──→ UI: tarjetas de tonalidades (flujo actual)
  │
  └─ suggest_keys(chords) → []
       │
       ├─ length(chords) < 3 ──→ UI: "No se encontraron tonalidades compatibles"
       │
       └─ length(chords) ≥ 3
            │
            ├─ suggest_multi_keys(chords) → [] (todos grupos de 1)
            │    └─ UI: "No se encontraron tonalidades compatibles"
            │
            └─ suggest_multi_keys(chords) → [grupos]
                 └─ UI: "No hay una tonalidad común. Se encontraron N tonalidades:"
                      + bloques por grupo + acordes sin tonalidad
```

---

## TODO futuro

- **Agrupar tonalidades adicionales:** Colapsar las tonalidades restantes que no son las 3 principales bajo "N tonalidades adicionales" (similar al collapse de modos relativos del flujo single).
- **Detección de modulación con orden temporal:** Si en el futuro se soporta orden de acordes, detectar momento exacto de modulación entre grupos.
- **Prestados modales:** Distinguir un bIII o bVII prestado de una modulación real.