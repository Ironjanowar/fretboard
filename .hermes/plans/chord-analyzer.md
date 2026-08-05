# Chord Analyzer — Plan de Implementación

## Resumen

Añadir un nuevo tab "Analyzer" al LiveView existente que permite al usuario pulsar
notas en el diapasón para construir un acorde y ver qué acordes posibles es.

## Decisiones de diseño (grill-me session)

- **Tab switching**: Toggle segmentado tipo iOS, primer elemento de la fila de controles
- **URL**: Notas marcadas como posiciones absolutas (string-fret), ej: `?m=0-3;2-2;1-0`
- **Tuning**: Compartido entre tabs, cambios limpian notas marcadas
- **Una nota por cuerda**: Al marcar, reemplaza la anterior en esa cuerda
- **Traste 0 clicable**: notas al aire válidas
- **Identificación**: Todas las interpretaciones, ordenadas por:
  1. Coincidencia exacta (fórmula = notas)
  2. Root más grave como desempate
  3. Parciales después (mínimo 3 notas coincidentes)
- **Deduplicación**: Por pitch class para análisis, mostrar duplicación en UI
- **Progresivo**: 0→hint, 1→nota, 2→intervalo, 3+→acordes
- **UI**: Color único para notas marcadas, lista vertical de tarjetas, botón Clear
- **Controles en Analyzer**: Solo toggle + Tuning + Instrumento (Key/Progressions/Add ocultos)
- **14 fórmulas existentes** en v1, arquitectura extensible

## Inspiración: oolimo.com/en/guitar-chords/analyze

- "Possible Chord Names" — lista de interpretaciones como botones
- "Warnings" — avisos de validez del acorde
- Descomposición visual: root, quality, extensiones, bass note
- Toggle Notes/Root para cambiar visualización del diapasón

## Arquitectura

### Capa de dominio (Fretboard.Music)

1. **`Chord.identify/1`** — función principal del analizador
   - Input: lista de notas (ej: `["C", "E", "G"]`)
   - Output: lista de interpretaciones `%{root, quality, exact?, inversion, notes, intervals}`
   - Algoritmo: para cada nota como root, calcular intervalos vs fórmulas conocidas
   - Ordenar: exactas primero, root más grave desempate, parciales después

2. **`Chord.identify/2`** con bass note — detecta inversiones
   - Input: lista de notas + nota más grave (bass)
   - Si bass != root → slash chord / inversión

3. **`Music.analyze_notes/1`** — facade para el LiveView
   - Deduplica pitch classes, llama a Chord.identify, formatea resultados

### Capa URL (Fretboard.Music.URLCodec)

4. **`URLCodec.encode_marked/1`** — serializa posiciones a `?m=0-3;2-2;1-0`
5. **`URLCodec.decode_marked/1`** — deserializa de string a lista de `{string, fret}`
6. **`URLCodec.encode_params`** extendido para incluir `tab` y `marked`

### Capa web (FretboardWeb)

7. **`FretboardLive`** — nuevo assign `:tab` (`:visualizer | :analyzer`)
8. **Eventos**: `toggle_tab`, `toggle_note` (string+fret), `clear_notes`
9. **Render**: conditional por tab, nuevo SVG interactivo en analyzer
10. **Resultados**: lista de tarjetas debajo del diapasón
11. **CSS**: estilos para toggle segmentado, tarjetas de análisis, notas marcadas

## Orden de implementación (TDD con subagents)

### Fase 1: Chord.identify/1 (dominio puro)
- Subagent 1: Tests para identify con acordes exactos (C major, A minor, G7, etc.)
- Subagent 2: Implementar identify
- Subagent 3: Review + test suite completo

### Fase 2: Detección de inversiones
- Subagent 1: Tests para identify con bass note (C/E, C/G, etc.)
- Subagent 2: Implementar inversiones
- Subagent 3: Review

### Fase 3: URLCodec para marked notes
- Subagent 1: Tests para encode/decode de posiciones
- Subagent 2: Implementar
- Subagent 3: Review

### Fase 4: LiveView — tab switching + toggle
- Subagent 1: Tests para evento toggle_tab, estado inicial
- Subagent 2: Implementar tab switching, render condicional
- Subagent 3: Review

### Fase 5: LiveView — fretboard interactivo
- Subagent 1: Tests para toggle_note, clear_notes, una nota por cuerda
- Subagent 2: Implementar SVG interactivo, eventos, render
- Subagent 3: Review

### Fase 6: LiveView — resultados del análisis
- Subagent 1: Tests para render de interpretaciones, estado vacío, intervalos
- Subagent 2: Implementar tarjetas de resultados, estados progresivos
- Subagent 3: Review

### Fase 7: CSS
- Subagent 1: N/A
- Subagent 2: Estilos para toggle, tarjetas, notas marcadas
- Subagent 3: Review visual + test suite
