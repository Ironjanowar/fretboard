# Plan: Extended Chord Identification in Analyzer

## Goal

Expand the chord analyzer to recognize 47 chord types (up from 14) and support
incomplete voicing matching, so that virtually any guitar chord can be identified.

## User's test chord

URL: `?marked=1-7,2-6,3-7,4-7` → notes E, G#, D, F# = intervals {0, 2, 4, 10} from E
→ **E9 without 5th** (dominant 9th, missing B)

## Decisions (from grill-me session)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Catalog size | 47 types (all from Oolimo + Wikipedia) |
| 2 | Incomplete voicings | 3rd match type with `:incomplete` flag |
| 3 | Result ordering | Exact → Incomplete → Partial |
| 4 | Compound interval names | Contextual: 7th presence rule |
| 5 | Quality groups | 8 groups by ascending complexity |
| 6 | Pitch-class collisions | Accept all, sort by root ascending |
| 7 | Inversions | Extend to 6 (4th/5th/6th for 9th/11th/13th) |
| 8 | URL labels | Compact standard (m9, maj9, 7b9, etc.) |
| 9 | Missing notes UI | Integrated, attenuated style in note list |
| 10 | identify/2 propagation | Untouched, flows naturally |
| 11 | Compound name rule | 7th presence determines simple vs compound |
| 12 | Incomplete limit | ≤ 2 missing notes |
| 13 | Inversion language | English (consistent with musical terminology) |
| 14 | Diatonic inference | Don't extend classify_7th |
| 15 | quality→triad mapping | By 3rd/5th base |
| 16 | Rename map | `@seventh_to_triad` → `@quality_to_triad` |
| 17 | Partial limit | Don't limit |
| 18 | Tests | TDD by groups |
| 19 | Code quality step | Sub-agent reviews modularity, readability, AGENTS.md compliance |

## New chord formulas (33 new, 47 total)

### 6ths
- `maj6`: [0, 4, 7, 9] — label "6"
- `min6`: [0, 3, 7, 9] — label "m6"

### Added tones
- `add9`: [0, 2, 4, 7] — label "add9"
- `m_add9`: [0, 2, 3, 7] — label "madd9"
- `maj6_9`: [0, 2, 4, 7, 9] — label "6/9"
- `min6_9`: [0, 2, 3, 7, 9] — label "m6/9"

### 9ths
- `9`: [0, 2, 4, 7, 10] — label "9"
- `maj9`: [0, 2, 4, 7, 11] — label "maj9"
- `min9`: [0, 2, 3, 7, 10] — label "m9"
- `7b9`: [0, 1, 4, 7, 10] — label "7b9"
- `7#9`: [0, 3, 4, 7, 10] — label "7#9"
- `9#5`: [0, 2, 4, 8, 10] — label "9#5"
- `9b5`: [0, 2, 4, 6, 10] — label "9b5"
- `7b5`: [0, 4, 6, 10] — label "7b5"

### 7th alterations
- `7sus4`: [0, 5, 7, 10] — label "7sus"
- `dim_maj7`: [0, 3, 6, 11] — label "dimMaj7"
- `maj7#11`: [0, 4, 6, 7, 11] — label "maj7#11"
- `7#11`: [0, 4, 6, 7, 10] — label "7#11"
- `7b13`: [0, 4, 7, 8, 10] — label "7b13"
- `7b9b13`: [0, 1, 4, 7, 8, 10] — label "7b9b13"

### 11ths
- `11`: [0, 2, 4, 5, 7, 10] — label "11"
- `maj11`: [0, 2, 4, 5, 7, 11] — label "maj11"
- `min11`: [0, 2, 3, 5, 7, 10] — label "m11"
- `m11b5`: [0, 2, 3, 5, 6, 10] — label "m11b5"

### 13ths
- `13`: [0, 2, 4, 5, 7, 9, 10] — label "13"
- `maj13`: [0, 2, 4, 5, 7, 9, 11] — label "maj13"
- `min13`: [0, 2, 3, 5, 7, 9, 10] — label "m13"
- `13b9`: [0, 1, 4, 5, 7, 9, 10] — label "13b9"

### Suspended extended
- `sus9`: [0, 2, 5, 7, 10] — label "sus9"
- `susb9`: [0, 1, 5, 7, 10] — label "susb9"
- `sus13`: [0, 5, 7, 9, 10] — label "sus13"

### Minor/dim variations
- `min7b13`: [0, 3, 7, 8, 10] — label "m7b13"
- `dim7b13`: [0, 3, 6, 8, 9] — label "dim7b13"

## Grouped qualities (8 groups)

1. **Triads**: major, minor, dim, aug, sus2, sus4
2. **Sixths**: maj6, min6, maj6_9, min6_9
3. **Added tones**: add9, m_add9
4. **Sevenths**: 7, maj7, min7, dim7, m7b5, min_maj7, aug_maj7, aug7, 7sus4, dim_maj7
5. **Ninths**: 9, maj9, min9, 7b9, 7#9, 9#5, 9b5, 7b5
6. **Elevenths**: 11, maj11, min11, m11b5, maj7#11, 7#11
7. **Thirteenths**: 13, maj13, min13, 13b9
8. **Suspended (extended)**: sus9, susb9, sus13, 7b13, 7b9b13, min7b13, dim7b13

## identify/1 algorithm changes

Current: exact (set equality) + partial (formula ⊂ input, coverage >= 3)

New: exact + incomplete + partial

### Match types
1. **Exact**: `coverage == input_size and formula_size == input_size` → `exact: true, incomplete: false`
2. **Incomplete**: `coverage == input_size and formula_size > input_size and (formula_size - input_size) <= 2` → `exact: false, incomplete: true`
3. **Partial**: `coverage >= 3 and formula_size < input_size` → `exact: false, incomplete: false`

### Sorting
1. Exact matches first, sorted by root pitch ascending
2. Incomplete matches next, sorted by missing count ascending, then root pitch ascending, then formula length ascending
3. Partial matches last, sorted by coverage descending, then root pitch ascending, then formula length ascending

### New fields in result map
- `:incomplete` (boolean) — true for incomplete voicings
- `:missing_intervals` ([String.t()]) — interval labels of missing notes (only for incomplete)

## interval_labels/1 changes

Contextual naming: if the formula contains a 7th interval (10 or 11),
intervals that appear *after* the 7th in the formula are named as compound:
- 2 → "Major 9th"
- 5 → "Perfect 11th"
- 9 → "Major 13th"
- 1 → "Minor 9th"
- 3 → "Sharp 9th" (or "Augmented 9th")
- 6 → "Sharp 11th" (or "Augmented 11th")
- 8 → "Flat 13th" (or "Minor 13th")

If no 7th in formula, all intervals use simple names (Major 2nd, etc.)

## identify/2 changes (inversions)

Extend `inversion` mapping:
- 0 → 0 (root position)
- 3, 4 → 1 (1st inversion)
- 7, 8 → 2 (2nd inversion)
- 10, 11 → 3 (3rd inversion)
- 2 → 4 (4th inversion — 9th in bass)
- 5 → 5 (5th inversion — 11th in bass)
- 9 → 6 (6th inversion — 13th in bass)

Inversion labels (English):
- 0 → "Root position"
- 1 → "1st inversion"
- 2 → "2nd inversion"
- 3 → "3rd inversion"
- 4 → "4th inversion"
- 5 → "5th inversion"
- 6 → "6th inversion"

## scale.ex changes

- Rename `@seventh_to_triad` to `@quality_to_triad`
- Add all 33 new qualities mapped to their triad base
- `@triad_qualities` stays the same
- `classify_7th/1` and `classify_intervals/1` — no changes

## url_codec.ex changes

- Extend `@labels_to_quality` with 33 new entries
- `extract_root_and_label/1` may need updates to parse longer labels

## UI changes (fretboard_live.ex)

### Badge
- Add `analysis-badge--incomplete` CSS class (distinct color, e.g. blue/gray)
- Show "incomplete" text for incomplete matches

### Notes display
- For incomplete matches: show all formula notes, but missing notes get
  `analysis-note-item--missing` CSS class (attenuated: opacity, strikethrough)
- Need to compute which notes are missing from the formula vs input

### CSS
- `.analysis-badge--incomplete` — blue/gray styling
- `.analysis-note-item--missing` — opacity 0.4, text-decoration: line-through

## Implementation order (TDD with sub-agents)

1. **Sub-agent 1 (Test Writer)**: Write failing tests for:
   - New chord formulas (one exact match test per new quality)
   - Incomplete matching algorithm
   - Contextual interval labels
   - Extended inversions
   - URL codec for new labels
   - quality_to_triad mapping
   Verify all fail with `mix test`

2. **Sub-agent 2 (Implementer)**: Implement the minimum code to pass all tests:
   - Expand `@formulas`, `@labels` in chord.ex
   - Add incomplete matching logic in `identify/1`
   - Add contextual `interval_labels/1`
   - Extend `identify/2` inversions
   - Update `grouped_qualities/0`
   - Rename + expand `@quality_to_triad` in scale.ex
   - Update `@labels_to_quality` in url_codec.ex
   - Update UI in fretboard_live.ex (badge, notes, inversions)
   - Add CSS classes
   Verify all pass with `mix test`

3. **Sub-agent 3 (Reviewer)**: Code quality review:
   - Modular, readable code per AGENTS.md
   - Short functions in small modules
   - No giant monoliths
   - `mix test`, `mix format --check-formatted`, `mix credo --strict`
   - Report issues and fix if needed

## Verification

The user's chord E-G#-D-F# (intervals {0,2,4,10} from E) should be identified as:
- E9 incomplete (missing: Perfect 5th / B) — badge "incomplete"
- Possibly E7 exact (no — E7 = {0,4,7,10}, D not in E7... wait, {0,2,4,10} ⊂ {0,2,4,7,10} = E9, missing 7=B)
- The first result should be E9 with "incomplete" badge