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

## Decisiones de diseño (v1)

### Mástil
- **24 trastes**, fijo (no configurable en v1)
- **Traste 0** (cuerdas al aire) incluido como columna especial a la izquierda (cejuela/nut)
- **6 cuerdas**, afinación estándar por defecto (E A D G B E)
- **Desktop first** — no responsive en v1

### Notas
- **Solo nombre de nota** (C, D, E...), sin octava en v1
- Octava como toggle futuro
- **Notación con sostenidos (#)** — C, C#, D, D#, E, F, F#, G, G#, A, A#, B

### Acordes
- **Modelo calculado por fórmulas de intervalos** — mayor = [0, 4, 7], menor = [0, 3, 7]
- Se añaden tipos de acorde agregando fórmulas, no hardcodeando notas
- **v1:** solo acordes mayores y menores
- **Selector:** raíz (C, D, E...) + calidad (mayor, menor)
- **Multi-acorde:** puedes seleccionar varios acordes a la vez
- **Color por acorde** — cada acorde tiene un color asignado
- **Notas solapadas** (pertenecen a 2+ acordes) se muestran en **color neutro** + tooltip/click para ver a qué acordes pertenecen

### Afinación
- **Labels clickables** a la izquierda del mástil — cada cuerda muestra su nota actual, click para cambiar
- **Presets de afinación** (Standard, Drop D, DADGAD...) como mejora futura

### Layout de la página
```
┌─────────────────────────────────────────┐
│  Controles: Preset afinación + Selector │
│  de acordes (raíz + calidad)            │
├─────────────────────────────────────────┤
│                                         │
│            MÁSTIL (24 trastes)          │
│                                         │
├─────────────────────────────────────────┤
│  Acordes activos (chips con color + X)  │
│  [C maj ×] [Am ×] [G maj ×] ...        │
└─────────────────────────────────────────┘
```

### Persistencia
- Sin persistencia en v1 — estado vive en el proceso LiveView
- **Query params** (estado en URL para compartir) como mejora futura

## Evolución futura

- Toggle de octava en las notas
- Presets de afinación
- Estado en query params (URLs compartibles)
- Acordes complejos (7ª, maj7, min7, dim, aug, sus2, sus4, etc.)
- Escalas (mayor, menor, pentatónica, modos, etc.)
- Intervalos (tónica, 3ª, 5ª...)
- Posiciones de acorde (diagramas tipo "chord box")
- Sonido al hacer click en una nota
- Responsive / mobile
- Notación enarmónica contextual (bemoles según acorde/escala)

## Estructura del proyecto

```
fretboard-viz/
├── IDEAS.md              ← este archivo
├── CONTEXT.md            ← glosario del dominio
├── docs/adr/             ← decisiones arquitectónicas
└── fretboard/            ← proyecto Phoenix
    ├── lib/
    │   ├── fretboard/          ← lógica de dominio (notas, acordes, afinación)
    │   └── fretboard_web/      ← LiveView, templates, componentes SVG
    ├── assets/
    ├── config/
    ├── test/
    └── mix.exs
```

## Estado

- [x] Documentar la idea
- [x] Sesión de Grill with Docs — decisiones base
- [x] Generar proyecto Phoenix (sin Ecto)
- [ ] Implementar lógica de notas y acordes (Elixir)
- [ ] Implementar mástil SVG (HEEx)
- [ ] Selector de acordes (raíz + calidad)
- [ ] Afinación configurable (labels clickables)
- [ ] Multi-acorde con colores
- [ ] Tooltip/click en notas solapadas
