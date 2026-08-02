# Chord Progressions Feature — Implementation Plan

## Status: DESIGN APPROVED (V1 — full catalog)

## Goal

Add a "Progressions" feature to the Fretboard app. Users select a named progression
(e.g., "Pop Punk: I-V-vi-IV") and a key, and the app loads all chords of that progression
in order — just like the existing Key modal loads diatonic chords.

## Research Sources

- Wikipedia: List of chord progressions, Andalusian cadence, Coltrane changes
- oolimo.com: 12 progression lessons (I-IV-V, I-V-vi-IV, vi-IV-I-V, descending bass,
  minor 7th, sus chords, funky vamp, ii-V-I major, ii-V-I minor, ii-V-I altered, slash chords)
- Existing app code: Scale.diatonic_chords/2, Chord formulas, Key modal pattern

## Catalog — 36 progressions in 5 categories

All progressions use only the existing chord qualities:
major, minor, dim, aug, sus2, sus4, "7", maj7, min7, dim7, m7b5

### 1. Pop/Rock (11)

| ID | Name | Key Type | Degrees | Description |
|----|------|----------|---------|-------------|
| pop_punk | Pop Punk (Axis) | major | [1,5,6,4] | I-V-vi-IV. "Don't Stop Believin'", "Hey Soul Sister" |
| pop_variation | Pop Variation | major | [6,4,1,5] | vi-IV-I-V. "One Of Us", "Complicated" |
| doo_wop | 50s Doo-Wop | major | [1,6,4,5] | I-vi-IV-V. "Stand By Me", "Everyday" |
| pachelbel | Pachelbel's Canon | major | [1,5,6,3,4,1,4,5] | I-V-vi-iii-IV-I-IV-V |
| blues_rock | I-IV-V Rock | major | [1,4,5] | "Sweet Home Alabama", "Wild Thing" |
| folk_vamp | Folk Vamp | major | [1,4] | I-IV. "Born in the USA" |
| circle | Circle | major | [6,2,5,1] | vi-ii-V-I. Resolution by circle of fifths |
| montgomery_ward | Montgomery-Ward Bridge | major | [1,4,2,5] | I-IV-ii-V. Tin Pan Alley bridge |
| jazz_turnaround | Jazz Turnaround | major | [1,6,2,5] | I-vi-ii-V |
| descending_bass_ballad | Descending Bass Ballad | major | [1,5,6,4] | I-V-vi-IV (Oolimo: V/3rd → simplified to V) |
| minor_seventh_pop | Minor 7th Pop | major | [1,3,6,4] | I-iiim7-vi7-IV (Oolimo). Uses min7 qualities |

### 2. Blues (3)

| ID | Name | Key Type | Degrees | Description |
|----|------|----------|---------|-------------|
| twelve_bar_blues | 12-Bar Blues | major | [1,1,1,1,4,4,1,1,5,4,1,5] | Standard 12-bar blues form |
| eight_bar_blues | 8-Bar Blues | major | [1,5,4,4,1,5,1,5] | 8-bar variant |
| five_four_one | V-IV-I Turnaround | major | [5,4,1] | Rock resolution |

### 3. Jazz (8)

| ID | Name | Key Type | Degrees | Qualities override | Description |
|----|------|----------|---------|--------------------|-------------|
| two_five_one_major | ii-V-I (Major) | major | [2,5,1] | [min7,"7",maj7] | Fundamental jazz progression |
| two_five_one_minor | ii-V-I (Minor) | minor | [2,5,1] | [m7b5,"7",minor] | Minor ii-V-I |
| two_five_one_alt | ii-V-I Altered | major | [2,5,1] | [min7,"7",maj7] | With V7alt (simplified to V7) |
| rhythm_changes | Rhythm Changes (A) | major | [1,6,2,5] | [major,min7,min7,"7"] | I-vi-ii-V. Gershwin "I Got Rhythm" |
| backdoor | Backdoor | major | [4,7,1] | [minor,"7",major] | iv-♭VII7-I. Jazz "backdoor" resolution |
| tritone_sub | Tritone Substitution | major | [2,2,1] | [min7,"7",major] | ii-♭II7-I (♭II = tritone sub of V) |
| two_chord_vamp | IIm7-V7 Vamp | major | [2,5] | [min7,"7"] | Funky vamp (Santana) |
| sus_chords | Sus Chords | major | [2,2,5,5] | [minor,min7,sus4,major] | iim-iim7-Vsus4-V (Oolimo) |

### 4. Curious/Modal (7)

| ID | Name | Key Type | Degrees | Accidentals | Description |
|----|------|----------|---------|-------------|-------------|
| mixolydian_rock | Mixolydian Rock | major | [1,7,4] | [0,-1,0] | I-♭VII-IV. Creedence, AC/DC |
| chromatic_descending | Chromatic Descending 5-6 | major | [1,5,7,4] | [0,0,-1,0] | I-V-♭VII-IV |
| flat_six_seven_one | ♭VI-♭VII-I | major | [6,7,1] | [-1,-1,0] | Phrygian rock resolution |
| modal_interchange | Modal Interchange i-♭VI | minor | [1,6] | [0,0] | i-♭VI. Borrowed chord |
| chromatic_mediant | Chromatic Mediant | major | [1,3] | [0,-1] | I-♭III. Cinematic |
| neapolitan | Neapolitan | major | [1,2,1] | [0,-1,0] | I-♭II-I |
| parallel_minor_oscillation | Parallel Minor Oscillation | major | [1,7,6,7] | [0,-1,-1,-1] | I-♭VII-♭VI-♭VII |

### 5. Exotic/World (7)

| ID | Name | Key Type | Degrees | Accidentals | Description |
|----|------|----------|---------|-------------|-------------|
| andalusian | Andalusian Cadence | minor | [1,7,6,5] | [0,0,0,0] | i-♭VII-♭VI-V. Flamenco |
| folia | Folia | minor | [1,7,1,5,3,7,1,5] | [0,0,0,0,0,0,0,0] | Most ancient Western progression |
| passamezzo_antico | Passamezzo Antico | minor | [1,7,1,5] | [0,0,0,0] | Renaissance |
| passamezzo_moderno | Passamezzo Moderno | major | [1,4,1,5] | [0,0,0,0] | Baroque |
| romanesca | Romanesca | major | [3,7,1,5] | [0,0,0,0] | Italian classical |
| phrygian_vamp | Phrygian Dominant Vamp | minor | [1,2,1] | [0,0,0] | i-♭II-i. Phrygian dominant |
| harmonic_minor | Harmonic Minor i-iv-♭VII | minor | [1,4,7] | [0,0,0] | Harmonic minor progression |

## Data Model

Each progression is stored as a map:

```elixir
%{
  id: :pop_punk,
  name: "Pop Punk (Axis)",
  category: "Pop/Rock",
  key_type: :major,           # :major or :minor — determines diatonic base
  degrees: [1, 5, 6, 4],     # scale degrees (1-7)
  accidentals: [0, 0, 0, 0], # semitone offset per degree (0 = natural, -1 = flat, +1 = sharp)
  qualities: nil,             # nil = use diatonic quality; or explicit list of quality atoms
  description: "I-V-vi-IV. \"Don't Stop Believin'\", \"Hey Soul Sister\""
}
```

### Degree → Chord resolution

1. **Diatonic degrees (accidental = 0)**: Use `Scale.diatonic_chords(tonic, key_type)`
   to get the chord root and quality for each degree.

2. **Altered degrees (accidental ≠ 0)**: Calculate root as
   `Note.note_at(tonic, scale_semitone + accidental)` and assign quality:
   - ♭II → :major (Neapolitan)
   - ♭III → :major
   - ♭VI → :major
   - ♭VII → :major
   - V in minor → :"7" (dominant 7th, standard practice)

3. **Explicit qualities (qualities ≠ nil)**: Use the provided quality list directly,
   root calculated from degree + accidental.

## Architecture

### New module: `Fretboard.Music.Progression`

```
lib/fretboard/music/progression.ex
```

Public API:
- `available_progressions() :: [atom()]` — all progression IDs
- `grouped_progressions() :: [{String.t(), [atom()]}]` — categories for optgroup
- `progression(atom()) :: map()` — full progression data
- `progression_label(atom()) :: String.t()` — display name
- `progression_chords(String.t(), atom()) :: [%{root, quality}]` — resolve to chords

### Facade: `Fretboard.Music`

Add delegation functions:
- `progression_chords(tonic, progression_id)`
- `grouped_progressions()`
- `progression_label(id)`

### LiveView: `FretboardWeb.FretboardLive`

Add:
- New button "🎼 Progressions" next to "🎵 Key"
- New modal `show_progression_modal` (follows Key modal pattern)
- Modal state: `progression_id`, `progression_tonic`
- Events: `open_progression_modal`, `close_progression_modal`,
  `update_progression`, `apply_progression`
- `apply_progression` calls `Music.progression_chords(tonic, id)` and
  pushes URL patch with the resulting chords (same as `apply_key`)

### URL encoding

No change needed — progressions expand to individual chords in the URL,
same as keys do. The URL shows `?chords=Cmaj,G7,Am,F` which is what
the progression produces.

## TDD Implementation Steps (per AGENTS.md)

### Step 1: Progression module — data + catalog

**Test Writer**: Write tests for `Progression.available_progressions/0`,
`Progression.grouped_progressions/0`, `Progression.progression/1`,
`Progression.progression_label/1`.

**Implementer**: Implement the module with the catalog.

**Reviewer**: Verify all tests pass, formatting clean.

### Step 2: Progression chord resolution

**Test Writer**: Write tests for `Progression.progression_chords/2`:
- Diatonic-only progression (pop_punk in C → [Cmaj, Gmaj, Amin, Fmaj])
- Altered degree progression (andalusian in A → [Amin, Gmaj, Fmaj, E7])
- Explicit qualities progression (two_five_one_major in C → [Dmin7, G7, Cmaj7])

**Implementer**: Implement chord resolution logic.

**Reviewer**: Verify, including edge cases.

### Step 3: Facade delegation

**Test Writer**: Write tests for `Music.progression_chords/2`,
`Music.grouped_progressions/0`, `Music.progression_label/1`.

**Implementer**: Add delegation to `Music` facade.

**Reviewer**: Verify.

### Step 4: LiveView — Progressions button + modal

**Test Writer**: Write LiveView tests:
- Progressions button renders
- Modal hidden by default, opens on click
- Modal shows progression categories (optgroups)
- Modal shows tonic selector
- Modal shows preview chips
- Applying progression replaces active chords
- Canceling doesn't change chords

**Implementer**: Add button, modal, events, state.

**Reviewer**: Full test suite, formatting, credo.

## Files to create/modify

| File | Action |
|------|--------|
| `lib/fretboard/music/progression.ex` | **CREATE** — Progression module |
| `lib/fretboard/music.ex` | **MODIFY** — Add delegation functions |
| `lib/fretboard_web/live/fretboard_live.ex` | **MODIFY** — Add button, modal, events |
| `test/fretboard/music/progression_test.exs` | **CREATE** — Unit tests |
| `test/fretboard/music_test.exs` | **MODIFY** — Add facade tests |
| `test/fretboard_web/live/fretboard_live_test.exs` | **MODIFY** — Add LiveView tests |

## What does NOT change

- SVG fretboard rendering
- Chord chips rendering
- Highlighting system
- Instrument/tuning system
- URL codec (progressions expand to chords)
- Chord module (no new qualities needed for V1)
- Scale module (progressions use existing scale types)