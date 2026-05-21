# Fretboard Visualizer 🎸

## Concepto

Web app que muestra un **mástil de guitarra en horizontal** donde puedes visualizar notas de acordes.

## Stack técnico

- **Erlang/OTP:** 27
- **Elixir:** 1.19.5
- **Phoenix:** 1.8.7
- **LiveView:** 1.1.30
- **Sin Ecto** — sin base de datos, estado solo en LiveView
- **Renderizado del mástil:** SVG (nativo en templates HEEx, sin JS adicional)

## Decisiones de diseño (v1) ✅

### Mástil
- **24 trastes**, fijo
- **Traste 0** (cuerdas al aire) incluido como columna especial a la izquierda (cejuela/nut)
- **6 cuerdas**, afinación estándar por defecto (E A D G B E)
- **Orden visual:** cuerda 1 (aguda, high E) arriba, cuerda 6 (grave, low E) abajo — perspectiva del guitarrista
- **Desktop first** — no responsive

### Notas
- **Solo nombre de nota** (C, D, E...), sin octava
- **Notación con sostenidos (#)** — C, C#, D, D#, E, F, F#, G, G#, A, A#, B

### Acordes (v1)
- **Modelo calculado por fórmulas de intervalos** — mayor = [0, 4, 7], menor = [0, 3, 7]
- **Selector:** raíz (C, D, E...) + calidad (mayor, menor)
- **Multi-acorde:** puedes seleccionar varios acordes a la vez
- **Color por acorde** — cada acorde tiene un color asignado
- **Notas solapadas** en **color neutro** + tooltip hover con los acordes que contienen esa nota

### Afinación (v1)
- Labels informativos a la izquierda del mástil (no clickables)

### Layout de la página
```
┌─────────────────────────────────────────┐
│  Controles: Tuning button + Selector    │
│  de acordes (raíz + calidad)            │
├─────────────────────────────────────────┤
│                                         │
│            MÁSTIL (24 trastes)          │
│                                         │
├─────────────────────────────────────────┤
│  Acordes activos (chips con color + X)  │
│  [Cmaj ×] [Amin ×] [G7 ×] ...          │
└─────────────────────────────────────────┘
```

### Persistencia
- Sin persistencia — estado vive en el proceso LiveView

## Decisiones de diseño (v2)

### Acordes complejos
- **Triadas adicionales:** dim [0,3,6], aug [0,4,8], sus2 [0,2,7], sus4 [0,5,7]
- **Séptimas:** 7 [0,4,7,10], maj7 [0,4,7,11], min7 [0,3,7,10], dim7 [0,3,6,9], m7b5 [0,3,6,10]
- **Selector agrupado** con optgroups: "Triads" y "Sevenths"
- **Labels cortos** en chips: maj, min, dim, aug, sus2, sus4, 7, maj7, min7, dim7, m7b5
- Los grupos son un concepto de UI, no de dominio

### Afinación — Modal con presets
- Botón "Tuning" en controles abre un **modal**
- **Dropdown de presets:**
  - Standard: E A D G B E
  - Drop D: D A D G B E
  - DADGAD: D A D G A D
  - Open G: D G D G B D
  - Open D: D A D F# A D
  - Open E: E B E G# B E
  - Half Step Down: Eb Ab Db Gb Bb Eb
  - Full Step Down: D G C F A D
  - Drop C: C G C F A D
- **6 dropdowns individuales** debajo del preset para ajuste fino por cuerda
- Botón **Apply** para confirmar y cerrar
- Los labels del mástil son **solo informativos** (no clickables)
- Seleccionar preset rellena los 6 dropdowns; luego puedes editar individualmente

### Query params (URLs compartibles)
- **Acordes:** `?chords=Cmaj,Amin,E7` — siempre presentes si hay acordes activos
- **Afinación:** `&tuning=D,A,D,G,B,E` — solo si difiere del estándar
- Notas con # se URL-encodean automáticamente (F# → F%23)
- Al cargar la página con params, se restaura el estado completo

## Evolución futura

- Toggle de octava en las notas
- Acordes de extensión (9ª, 11ª, 13ª)
- Escalas (mayor, menor, pentatónica, modos, etc.)
- Intervalos (tónica, 3ª, 5ª...)
- Posiciones de acorde (diagramas tipo "chord box")
- Sonido al hacer click en una nota
- Responsive / mobile
- Notación enarmónica contextual (bemoles según acorde/escala)

## Estructura del proyecto

```
fretboard/
├── IDEAS.md              ← este archivo
├── CONTEXT.md            ← glosario del dominio
├── AGENTS.md             ← guía de desarrollo
├── lib/
│   ├── fretboard/
│   │   └── music/        ← lógica de dominio (notas, acordes, afinación)
│   └── fretboard_web/
│       └── live/         ← LiveView, SVG, interactividad
├── assets/
├── config/
├── test/
└── mix.exs
```

## Estado

### V1 ✅
- [x] Documentar la idea
- [x] Sesión de Grill with Docs — decisiones base
- [x] Generar proyecto Phoenix (sin Ecto)
- [x] Lógica de notas y acordes (Music.Note, Music.Chord, Music.Tuning)
- [x] Music facade (API pública)
- [x] Mástil SVG (cuerdas, trastes, nut, markers)
- [x] Selector de acordes (raíz + calidad)
- [x] Multi-acorde con colores
- [x] Tooltip en notas solapadas
- [x] Orden correcto de cuerdas (grave abajo)
- [x] Credo strict + pre-commit hook

### V2
- [ ] Acordes complejos (triadas + séptimas)
- [ ] Selector agrupado con optgroups
- [ ] Modal de afinación con presets
- [ ] Query params (URLs compartibles)
