# Auditoría de Arquitectura — Fretboard Phoenix LiveView

**Proyecto:** Fretboard (visualizador de acordes/escalas para guitarra)
**Fecha:** 2 de agosto, 2026
**Auditor:** Hermes Agent (sub-agente)
**Repositorio:** `/workspace/repos/fretboard`

---

## Resumen Ejecutivo

Fretboard es un proyecto Phoenix LiveView bien estructurado que sigue un patrón facade claro. La separación de responsabilidades entre el dominio (`Fretboard.Music`) y la capa web (`FretboardWeb`) es correcta y respeta las reglas definidas en `AGENTS.md`. Las pruebas (378 tests) pasan sin fallos. El código es limpio y mayormente idiomático. Se identifican oportunidades de mejora en el tamaño del LiveView, duplicación de datos entre `Tuning` e `Instrument`, y sincronización manual de mapas en `URLCodec`.

**Puntuación global de salud arquitectónica: 7.5 / 10**

---

## 1. Límites de Módulos y Separación de Responsabilidades

### ✅ Good — La capa web usa exclusivamente el facade `Fretboard.Music`

**Severidad:** Good

Se verificó mediante búsqueda exhaustiva que `FretboardWeb` **nunca** referencia módulos internos (`Music.Note`, `Music.Chord`, `Music.Tuning`, `Music.Scale`, `Music.Instrument`, `Music.Progression`, `Music.URLCodec`) directamente. Todas las 27 referencias a `Music.*` en `lib/fretboard_web/live/fretboard_live.ex` utilizan `Fretboard.Music` (el facade).

```
# Búsqueda: Music.(Note|Chord|Tuning|Scale|Instrument|Progression|URLCodec) en lib/fretboard_web
# Resultado: 0 coincidencias ✅
```

**Referencias:** `lib/fretboard_web/live/fretboard_live.ex:12` (`alias Fretboard.Music`), todas las llamadas en líneas 41-880.

---

### ✅ Good — Los módulos de dominio no dependen de Phoenix/web

**Severidad:** Good

Ningún módulo bajo `lib/fretboard/music/` importa o hace alias a `Phoenix`, `Plug`, `LiveView`, o cualquier módulo web. Los módulos de dominio son puramente de lógica musical.

---

### ⚠️ Warning — El facade `Music` no expone `scale_notes/2`

**Severidad:** Suggestion

`Scale.scale_notes/2` es una función pública con `@doc` y `@spec`, pero **no está expuesta** a través del facade `Fretboard.Music`. Esto significa que si la capa web necesitara mostrar las notas de una escala, tendría que violar la regla de usar solo el facade, o se tendría que añadir la delegación. Actualmente solo se usa en tests.

**Archivo:** `lib/fretboard/music/scale.ex:96` (`def scale_notes`)
**Recomendación:** Añadir `def scale_notes(tonic, scale_type), do: Scale.scale_notes(tonic, scale_type)` al facade `Music`, o marcar `scale_notes/2` como privada si no se necesita externamente.

---

## 2. Organización del Código

### ✅ Good — Estructura de directorios coherente

**Severidad:** Good

```
lib/
├── fretboard/
│   ├── application.ex          # OTP
│   ├── fretboard.ex           # Módulo raíz (vacío)
│   └── music/
│       ├── music.ex           # Facade
│       ├── note.ex             # Notas cromáticas
│       ├── chord.ex            # Fórmulas de acordes
│       ├── scale.ex            # Escalas y acordes diatónicos
│       ├── tuning.ex           # Afinaciones (guitarra)
│       ├── instrument.ex       # Instrumentos multi-cuerda
│       ├── progression.ex      # Catálogo de progresiones
│       └── url_codec.ex        # Serialización URL
└── fretboard_web/
    ├── live/fretboard_live.ex  # LiveView principal
    ├── components/             # Componentes HEEx
    ├── controllers/            # Controladores
    ├── endpoint.ex, router.ex  # Infraestructura web
    └── telemetry.ex
```

La separación `fretboard/` (dominio) vs `fretboard_web/` (web) es clara y respeta las convenciones de Phoenix.

---

### ⚠️ Warning — `fretboard_live.ex` es un módulo monolítico (885 líneas)

**Severidad:** Warning

El LiveView principal tiene **885 líneas**. La función `render/1` sola ocupa aproximadamente **500 líneas** (líneas 316-821), conteniendo:
- Renderizado SVG del diapasón (~200 líneas)
- Chips de acordes activos (~30 líneas)
- Modal de afinación (~75 líneas)
- Modal de tonalidad/key (~85 líneas)
- Modal de progresiones (~85 líneas)

Además, el módulo mezcla:
- **Lógica de estado** (13 `handle_event/3` + `mount/3` + `handle_params/3`)
- **Lógica de vista** (`note_cx/2`, `note_fill/4`, `detect_preset/2`, `svg_params/1`)
- **Template HTML** (todo el `render/1`)

**Archivos:** `lib/fretboard_web/live/fretboard_live.ex:1-885`
**Recomendación:**
1. Extraer los modales a componentes `LiveComponent` separados (`TuningModal`, `KeyModal`, `ProgressionModal`).
2. Mover las funciones helper de renderizado (`note_cx/2`, `note_fill/4`) a un módulo `FretboardWeb.FretboardSVG` o a un componente funcional.
3. Considerar extraer la gestión de eventos a un módulo separado o usar `live_component` para encapsular estado de modales.

---

### ✅ Good — `progression.ex` es grande (1199 líneas) pero es 90% datos

**Severidad:** Good

Aunque `progression.ex` tiene 1199 líneas, ~1089 son definiciones de datos (el catálogo `@progressions`). El código funcional real son ~110 líneas al final del archivo. Esto es aceptable para un catálogo de datos.

---

## 3. Grafo de Dependencias

### ✅ Good — Dirección de dependencias limpia, sin ciclos

**Severidad:** Good

```
FretboardWeb (LiveView, Router, Endpoint)
    ↓
Fretboard.Music (facade)
    ↓
├── Note        (sin dependencias)
├── Chord       → Note
├── Scale       → Note
├── Tuning      (sin dependencias)
├── Instrument  (sin dependencias)
├── Progression → Note, Scale
└── URLCodec    → Chord, Instrument, Note
```

- **No hay dependencias circulares.**
- **No hay dependencias web → dominio directo** (todo pasa por el facade).
- La dirección es consistente: web → facade → módulos internos.

---

### ⚠️ Warning — Sincronización manual entre `URLCodec` y módulos de dominio

**Severidad:** Warning

`URLCodec` mantiene mapas de conversión que deben sincronizarse manualmente con `Chord` y `Instrument`:

1. **`@labels_to_quality`** (`url_codec.ex:10-22`): duplica los labels de `Chord.@labels`. Si se añade un nuevo tipo de acorde a `Chord`, no se podrá codificar/decodificar en URLs hasta que se actualice este mapa.

2. **`@instrument_to_string` / `@string_to_instrument`** (`url_codec.ex:26-36`): duplica las claves de `Instrument`. Si se añade un nuevo instrumento, no funcionará en URLs.

**Recomendación:** Derivar estos mapas automáticamente desde `Chord` e `Instrument`:
```elixir
@labels_to_quality Chord.available_qualities()
  |> Enum.map(&{Chord.label(&1), &1})
  |> Map.new()
```

---

## 4. Diseño del LiveView

### ⚠️ Warning — Duplicación de lógica entre `mount/3` y `handle_params/3`

**Severidad:** Warning

Las funciones `mount/3` (líneas 40-66) y `handle_params/3` (líneas 87-103) contienen lógica casi idéntica:

```elixir
# mount/3 (líneas 41-43)
{instrument, tuning, active_chords, highlighted_chord} = Music.decode_params(params)
fretboard = Music.fretboard_data(tuning, active_chords)
string_count = Music.instrument_strings(instrument)

# handle_params/3 (líneas 88-90) — idéntico
{instrument, tuning, active_chords, highlighted_chord} = Music.decode_params(params)
fretboard = Music.fretboard_data(tuning, active_chords)
string_count = Music.instrument_strings(instrument)
```

**Recomendación:** Extraer a una función privada `apply_params/2` que construya los assigns comunes:
```elixir
defp apply_params(socket, params) do
  {instrument, tuning, active_chords, highlighted_chord} = Music.decode_params(params)
  fretboard = Music.fretboard_data(tuning, active_chords)
  # ... assign común
end
```

---

### ⚠️ Warning — Lógica de negocio mezclada en funciones de vista

**Severidad:** Suggestion

`note_fill/4` (líneas 839-864) contiene lógica de negocio (determinar qué color corresponde a un acorde resaltado, buscar índices de acordes, comparar labels) dentro de una función que técnicamente es un helper de renderizado del LiveView.

```elixir
# fretboard_live.ex:840-850
def note_fill(chords, active_chords, colors, highlighted_chord)
    when is_integer(highlighted_chord) do
  highlighted = Enum.at(active_chords, highlighted_chord)
  highlighted_label = Music.chord_label(highlighted.root, highlighted.quality)
  if highlighted_label in chords do
    Enum.at(colors, rem(highlighted_chord, length(colors)))
  else
    @overlap_color
  end
end
```

**Recomendación:** Esta lógica debería vivir en el dominio (o al menos en un módulo de presentación separado), no en el LiveView. Considerar mover `note_fill/4` y `note_cx/2` a un módulo `FretboardWeb.FretboardSVG`.

---

### ✅ Good — Gestión de estado vía URL params (compartible, navegable)

**Severidad:** Good

El estado se gestiona mediante URL query params (`push_patch` con `Music.encode_params/4`). Esto permite:
- URLs compartibles
- Botones atrás/adelante del navegador funcionan
- `handle_params/3` es la fuente de verdad para el estado derivado

Es un patrón excelente para una aplicación stateless.

---

## 5. Diseño OTP/Application

### ✅ Good — `application.ex` correcto y estándar

**Severidad:** Good

```elixir
# application.ex:10-18
children = [
  FretboardWeb.Telemetry,
  {DNSCluster, query: ...},
  {Phoenix.PubSub, name: Fretboard.PubSub},
  FretboardWeb.Endpoint
]
opts = [strategy: :one_for_one, name: Fretboard.Supervisor]
```

- Árbol de supervisión apropiado para una app Phoenix stateless.
- Estrategia `one_for_one` correcta (cada hijo es independiente).
- `config_change/3` implementado correctamente.

---

### 💡 Suggestion — PubSub configurado pero no utilizado

**Severidad:** Suggestion

`Phoenix.PubSub` está configurado (`Fretboard.PubSub`) pero no se usa en ningún lugar del código (no hay `broadcast`, `subscribe`, o `PubSub` en el codebase). Esto es correcto para una app stateless de un solo LiveView, pero podría eliminarse si no hay planes de usarlo, o documentarse como preparación para funcionalidades futuras.

**Archivo:** `lib/fretboard/application.ex:13`

---

## 6. Extensibilidad

### ✅ Good — Diseño data-driven, abierto a extensión

**Severidad:** Good

- **Añadir tipos de acordes:** Añadir entrada a `@formulas` y `@labels` en `Chord.ex` + actualizar `@labels_to_quality` en `URLCodec`. Fácil.
- **Añadir escalas:** Añadir a `@scale_types`, `@scale_formulas`, `@labels`, `@grouped_scale_types` en `Scale.ex`. Fácil.
- **Añadir instrumentos:** Añadir entrada a `@instruments` en `Instrument.ex` + actualizar guards y mapas en `URLCodec`. Moderado.
- **Añadir progresiones:** Añadir entrada a `@progressions` en `Progression.ex`. Muy fácil — solo datos.

---

### ⚠️ Warning — Guards explícitos limitan extensibilidad de instrumentos

**Severidad:** Warning

`Instrument.ex` usa guards explícitos en cada función:

```elixir
# instrument.ex:76, 86, 95, 105, 113
def instrument(key) when key in [:guitar, :bass_4, :bass_5] do
def instrument_strings(key) when key in [:guitar, :bass_4, :bass_5] do
def instrument_standard_tuning(key) when key in [:guitar, :bass_4, :bass_5] do
```

Añadir un nuevo instrumento requiere actualizar **todos** los guards, además del mapa `@instruments`. Si se olvida uno, se obtiene un error en runtime (FunctionClauseError).

**Recomendación:** Derivar los valores válidos del mapa `@instruments`:
```elixir
@valid_keys Map.keys(@instruments)
def instrument(key) when key in @valid_keys, do: Map.get(@instruments, key)
def instrument(_), do: nil
```

---

## 7. Código Muerto / Módulos No Utilizados

### ⚠️ Warning — Módulo `Tuning` parcialmente obsoleto, duplicado con `Instrument`

**Severidad:** Warning

El módulo `Tuning` (`lib/fretboard/music/tuning.ex`) define presets de guitarra que **están duplicados** en `Instrument.ex` (`@guitar_presets`). Del facade `Music`, solo se usa `Tuning.standard()` (línea 15), que también está disponible vía `Music.instrument_standard_tuning(:guitar)`.

| Función de `Tuning` | Usada en producción | Usada en tests |
|---|---|---|
| `standard/0` | ✅ (via `Music.standard_tuning/0`) | ✅ |
| `presets/0` | ❌ | ✅ |
| `preset_names/0` | ❌ | ✅ |
| `note_for_string/2` | ❌ | ✅ |

`Music.standard_tuning/0`, `Music.tuning_presets/0`, y `Music.tuning_preset_names/0` son wrappers de compatibilidad hacia atrás que solo se usan en tests.

**Recomendación:** Considerar deprecar `Tuning` y redirigir todo a `Instrument`, o consolidar la afinación como responsabilidad de `Instrument` únicamente.

---

### ⚠️ Warning — Módulo `Fretboard` raíz vacío

**Severidad:** Suggestion

`lib/fretboard.ex` es un módulo vacío con solo `@moduledoc`. No se referencia en ningún lugar. Es boilerplate generado por Phoenix que podría eliminarse.

**Archivo:** `lib/fretboard.ex:1-9`

---

### ⚠️ Warning — Funciones del facade no utilizadas en la capa web

**Severidad:** Suggestion

Las siguientes funciones expuestas en `Fretboard.Music` **no se usan en la capa web** (solo en tests):

| Función | Línea en `music.ex` | Uso real |
|---|---|---|
| `standard_tuning/0` | 15 | Solo tests |
| `tuning_presets/0` | 21 | Solo tests (compatibilidad) |
| `tuning_preset_names/0` | 27 | Solo tests (compatibilidad) |
| `instrument/1` | 40 | Solo tests |
| `progression_label/1` | 148 | Solo tests |
| `available_qualities/0` | 70 | No usado (se usa `grouped_qualities/0`) |
| `available_scale_types/0` | 112 | No usado (se usa `grouped_scale_types/0`) |
| `available_progressions/0` | 130 | No usado (se usa `grouped_progressions/0`) |

**Recomendación:** Evaluar si estas funciones son parte intencional de la API pública (para consumo futuro o externo) o si son código muerto. Las de compatibilidad (`tuning_presets/0`, `tuning_preset_names/0`) podrían deprecarse.

---

### ⚠️ Warning — `Progression.categories/0` no se usa fuera de su módulo

**Severidad:** Suggestion

`Progression.categories/0` (línea 1118) no se llama desde ningún lugar fuera de `progression.ex` (ni siquiera en tests). `Progression.grouped_progressions/0` usa `@progression_categories` directamente.

---

## 8. Consistencia de Nomenclatura

### ✅ Good — Nomenclatura mayormente consistente

**Severidad:** Good

- `snake_case` en funciones y variables: ✅ consistente
- `PascalCase` en módulos: ✅ consistente
- Funciones booleanas con `?`: No aplica (no hay funciones booleanas)
- `@moduledoc` en todos los módulos: ✅ (excepto `application.ex` que usa `@moduledoc false`, que es estándar)
- `@doc` en funciones públicas: ✅ consistente en módulos de dominio

---

### ⚠️ Warning — Sobrecarga de nombre `chord_label/1` vs `chord_label/2`

**Severidad:** Suggestion

`Chord.chord_label/1` (línea 81) devuelve el label corto de la calidad (`"maj"`), mientras que `Chord.chord_label/2` (línea 95) devuelve `"#{root}#{label}"` (`"Cmaj"`). La sobrecarga aridad/diferencia semántica puede confundir.

**Recomendación:** Renombrar `chord_label/1` a `quality_label/1` para clarificar que devuelve solo el label de la calidad.

---

### ⚠️ Warning — Nombre `note_cx/2` no es autoexplicativo

**Severidad:** Suggestion

`note_cx/2` en `fretboard_live.ex:827` usa jerga SVG (`cx` = coordenada X del centro). No es autoexplicativo fuera del contexto SVG.

**Recomendación:** Renombrar a `note_x_position/2` o `note_center_x/2`.

---

### ⚠️ Warning — Inconsistencia `Tuning` vs `Instrument`

**Severidad:** Suggestion

`Tuning` define presets de guitarra; `Instrument` también define presets de guitarra (entre otros instrumentos). La responsabilidad de "afinaciones" está dividida entre dos módulos sin una relación clara. `Tuning` parece ser el módulo original y `Instrument` la evolución multi-instrumento.

---

## Resultados de Credo

```
mix credo --strict
Checking 36 source files ...

[W] ↗ Using `length/1` is expensive, prefer comparing against an empty list.
      test/fretboard/music_test.exs:268:14 #(Fretboard.MusicTest)

1 warning (exit code 16)
```

**Severidad:** Suggestion
**Único hallazgo:** Uso de `length/1` en un test donde se podría usar `!= []` o `Enum.any?/1`.
**Recomendación:** Cambiar `assert length(progressions) > 0` por `assert progressions != []` o `refute progressions == []`.

---

## Resumen de Hallazgos por Severidad

| Severidad | Cantidad | Hallazgos clave |
|---|---|---|
| **Critical** | 0 | — |
| **Warning** | 8 | LiveView monolítico (885 líneas), duplicación mount/handle_params, sincronización manual URLCodec, Tuning obsoleto/duplicado, guards explícitos en Instrument |
| **Suggestion** | 7 | PubSub no usado, módulo Fretboard vacío, funciones del facade no utilizadas en web, sobrecarga chord_label, nombre note_cx, warning de Credo, scale_notes no expuesto |
| **Good** | 7 | Boundary web→facade limpio, dominio sin deps web, estructura de directorios coherente, grafo sin ciclos, estado via URL params, application.ex correcto, diseño data-driven extensible |

---

## Puntuación Global de Salud Arquitectónica

### **7.5 / 10**

**Justificación:**

| Criterio | Puntuación | Comentario |
|---|---|---|
| Separación de responsabilidades | 9/10 | Boundary web→facade impecable, dominio puro |
| Organización del código | 7/10 | Estructura correcta, pero LiveView es monolítico (885 líneas) |
| Grafo de dependencias | 8/10 | Sin ciclos, dirección limpia; penalizado por sync manual en URLCodec |
| Diseño LiveView | 6/10 | Estado via URL es excelente, pero render+eventos+helpers en un solo archivo |
| Diseño OTP | 8/10 | Estándar correcto, PubSub sin usar |
| Extensibilidad | 8/10 | Data-driven y fácil de extender; guards explícitos y sync manual restan puntos |
| Código muerto | 6/10 | Tuning duplicado/obsoleto, varias funciones del facade sin uso en web |
| Nomenclatura | 8/10 | Generalmente consistente, algunas sobrecargas y nombres poco claros |

**Fortalezas principales:**
- Arquitectura facade estrictamente respetada y verificada
- Dominio libre de dependencias web
- Estado gestionado vía URLs (compartible, navegable)
- Catálogo de progresiones muy completo (1199 líneas, 50+ progresiones)
- 378 tests pasando, cobertura amplia
- Credo casi limpio (1 warning en tests)

**Debilidades principales:**
- LiveView monolítico que mezcla estado, eventos, lógica de vista y template
- Duplicación de datos entre `Tuning` e `Instrument`
- Sincronización manual de mapas en `URLCodec` con `Chord` e `Instrument`
- Código muerto/legacy (`Tuning`, wrappers de compatibilidad, funciones no expuestas)
- Guards explícitos que limitan extensibilidad

**Recomendaciones prioritarias:**
1. **Refactorizar `fretboard_live.ex`** — extraer modales a LiveComponents, helpers SVG a módulo separado
2. **Consolidar `Tuning` en `Instrument`** — eliminar duplicación de presets
3. **Derivar mapas de `URLCodec` desde `Chord`/`Instrument`** — eliminar sync manual
4. **Extraer lógica común de `mount`/`handle_params`** — DRY
5. **Auditar y limpiar funciones no usadas** del facade