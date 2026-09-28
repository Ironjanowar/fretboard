# 02 — Core baseline, state and wire contract

Status: implementation plan, not implementation approval. The source oracle is **Ironjanowar/fretboard at `2daa8c665efa268942dda352691f39d78db42512`**. This document describes observed source behavior separately from the proposed Rust interface. No Rust, Android, website deployment, Rustler, WASM or iOS implementation is authorized by creating this plan.

## 1. Authority and boundaries

Read sources: `lib/fretboard/music.ex`; `lib/fretboard/music/{note,pitch,intervals,instrument,chord,scale,progression,analyzer,keyboard,url_codec,page_codec}.ex`; `lib/fretboard_web/live/fretboard_live.ex`; boundary and duplicate-chord tests in `test/fretboard/music/page_codec_boundary_test.exs` and `test/fretboard_web/live/duplicate_chords_live_test.exs`. Source files, not stale API comments in AGENTS.md, define the baseline. Catalog counts below were checked by parsing the pinned source: 47 qualities, 15 scale types, 59 progression definitions. These are source-inspection results, not claims that Rust or the Elixir test suite ran.

`Ironjanowar/fretboard-core` owns a pure Rust crate `fretboard-core` under `crates/domain`, plus the separate UniFFI adapter `fretboard-mobile-ffi` under `crates/mobile-ffi`. `crates/bindgen` is the `uniffi-bindgen` executable. Android owns UI geometry, touch, focus, accessibility, lifecycle, storage, intents and file/network access. The pure engine has no Android, JNI, UniFFI, network, filesystem, clock, randomness, Phoenix, or rendering dependency. Music-derived grouping and identity belong in the core, not duplicate Kotlin algorithms.

New Rust state is a typed replacement for the observable **decode → transition → encode/decode → derive** behavior, not a translation of a LiveView socket. Existing web production remains unchanged. Golden oracle exports and explicit approved deviations arbitrate migration; do not fix suspected bugs while porting.

## 2. Primitive and instrument contract

- Pitch classes are indices 0–11 in `C C# D D# E F F# G G# A A# B` order; display is sharp-only. Domain note lookup also recognizes Db→C#, Eb→D#, Fb→E, Gb→F#, Ab→G#, Bb→A#, Cb→B. URL chord and tuning parsing accepts only the twelve sharp names, not flats. Do not make URL parsing more permissive implicitly.
- Absolute open-string pitches are MIDI integers 0–127 at the page URL boundary. Sounding fret pitches are open pitch + fret and may exceed 127; use a wider integer and do not clamp at 127. Piano selection is restricted to 48–83 inclusive, 36 keys. Physical string order is never sorted by pitch.
- `note_at` transposes modulo twelve; negative accidental transposition must produce the same circular indexing as Elixir `rem` plus `Enum.at` (Rust `%` alone on negative numbers is not equivalent).
- Simple intervals 0–11: Perfect Unison, Minor 2nd, Major 2nd, Minor 3rd, Major 3rd, Perfect 4th, Tritone, Perfect 5th, Augmented 5th, Major 6th, Minor 7th, Major 7th. Distinct absolute pitches separated by any positive multiple of twelve produce **Octave**; other compounds reduce to the simple interval.
- `TuningState` contains exact `pitches` and a fixed preset `reference`. Editing one note chooses the nearest pitch to that string's pitch in the **reference preset**, not the previous edited pitch. A six-semitone tie resolves downward. Preset selection replaces both pitches and reference. Detection compares exact pitches in catalog order and returns the first preset name or `Custom`; matching pitch classes alone does not detect a preset.

Instrument display order and identifiers: `guitar` / Guitar; `bass_4` / Bass (4-string); `bass_5` / Bass (5-string); `ukelele` / Ukulele; `piano` / Piano. Preserve the spelling `ukelele` on the wire. All fretted instruments have frets 0–24 inclusive. Piano has no tuning, strings or fretboard.

| Instrument | Presets in catalog order: name = MIDI pitches |
|---|---|
| guitar | Standard = 40,45,50,55,59,64; Drop D = 38,45,50,55,59,64; DADGAD = 38,45,50,55,57,62; Open G = 38,43,50,55,59,62; Open D = 38,45,50,54,57,62; Open E = 40,47,52,56,59,64; Half Step Down = 39,44,49,54,58,63; Full Step Down = 38,43,48,53,57,62; Drop C = 36,43,48,53,57,62 |
| bass_4 | Standard = 28,33,38,43; Drop D = 26,33,38,43; Half Step Down = 27,32,37,42 |
| bass_5 | Standard = 23,28,33,38,43; Half Step Down = 22,27,32,37,42; Drop A = 21,28,33,38,43 |
| ukelele | Standard = 67,60,64,69; Low G = 55,60,64,69; D tuning = 69,62,66,71; Baritone = 50,55,59,64; Half Step Down = 66,59,63,68 |
| piano | none; fixed absolute range 48–83 |

Legacy `standard_tuning`, `tuning_presets`, `tuning_preset_names` mean guitar. `instrument` lookup returns nil when unknown; fretted-only helpers are not safe piano entry points. New typed methods must report an error rather than reproduce a function-clause crash.

## 3. Chord catalog and semantics

Formula offsets are semitones in their returned note order, not voicing pitches. Public available-quality order is Elixir atom-name sorting; grouped display order is separately specified below. Display/wire label is **not** the identifier (`min9`→`m9`, `maj6_9`→`6/9`). A full label concatenates root and label without spaces.

| Stable quality identifier | Display/wire suffix | Formula |
|---|---|---|
| `major` | `maj` | `[0, 4, 7]` |
| `minor` | `min` | `[0, 3, 7]` |
| `dim` | `dim` | `[0, 3, 6]` |
| `aug` | `aug` | `[0, 4, 8]` |
| `sus2` | `sus2` | `[0, 2, 7]` |
| `sus4` | `sus4` | `[0, 5, 7]` |
| `7` | `7` | `[0, 4, 7, 10]` |
| `maj7` | `maj7` | `[0, 4, 7, 11]` |
| `min7` | `min7` | `[0, 3, 7, 10]` |
| `dim7` | `dim7` | `[0, 3, 6, 9]` |
| `m7b5` | `m7b5` | `[0, 3, 6, 10]` |
| `min_maj7` | `mMaj7` | `[0, 3, 7, 11]` |
| `aug_maj7` | `augMaj7` | `[0, 4, 8, 11]` |
| `aug7` | `aug7` | `[0, 4, 8, 10]` |
| `maj6` | `6` | `[0, 4, 7, 9]` |
| `min6` | `m6` | `[0, 3, 7, 9]` |
| `add9` | `add9` | `[0, 2, 4, 7]` |
| `m_add9` | `madd9` | `[0, 2, 3, 7]` |
| `maj6_9` | `6/9` | `[0, 2, 4, 7, 9]` |
| `min6_9` | `m6/9` | `[0, 2, 3, 7, 9]` |
| `9` | `9` | `[0, 2, 4, 7, 10]` |
| `maj9` | `maj9` | `[0, 2, 4, 7, 11]` |
| `min9` | `m9` | `[0, 2, 3, 7, 10]` |
| `7b9` | `7b9` | `[0, 1, 4, 7, 10]` |
| `7#9` | `7#9` | `[0, 3, 4, 7, 10]` |
| `9#5` | `9#5` | `[0, 2, 4, 8, 10]` |
| `9b5` | `9b5` | `[0, 2, 4, 6, 10]` |
| `7b5` | `7b5` | `[0, 4, 6, 10]` |
| `7sus4` | `7sus` | `[0, 5, 7, 10]` |
| `dim_maj7` | `dimMaj7` | `[0, 3, 6, 11]` |
| `maj7#11` | `maj7#11` | `[0, 4, 6, 7, 11]` |
| `7#11` | `7#11` | `[0, 4, 6, 7, 10]` |
| `7b13` | `7b13` | `[0, 4, 7, 8, 10]` |
| `7b9b13` | `7b9b13` | `[0, 1, 4, 7, 8, 10]` |
| `11` | `11` | `[0, 2, 4, 5, 7, 10]` |
| `maj11` | `maj11` | `[0, 2, 4, 5, 7, 11]` |
| `min11` | `m11` | `[0, 2, 3, 5, 7, 10]` |
| `m11b5` | `m11b5` | `[0, 2, 3, 5, 6, 10]` |
| `13` | `13` | `[0, 2, 4, 5, 7, 9, 10]` |
| `maj13` | `maj13` | `[0, 2, 4, 5, 7, 9, 11]` |
| `min13` | `m13` | `[0, 2, 3, 5, 7, 9, 10]` |
| `13b9` | `13b9` | `[0, 1, 4, 5, 7, 9, 10]` |
| `sus9` | `sus9` | `[0, 2, 5, 7, 10]` |
| `susb9` | `susb9` | `[0, 1, 5, 7, 10]` |
| `sus13` | `sus13` | `[0, 5, 7, 9, 10]` |
| `min7b13` | `m7b13` | `[0, 3, 7, 8, 10]` |
| `dim7b13` | `dim7b13` | `[0, 3, 6, 8, 9]` |

Display groups, with exact member order:

- Triads: major, minor, dim, aug, sus2, sus4.
- Sixths: maj6, min6, maj6_9, min6_9.
- Added tones: add9, m_add9.
- Sevenths: 7, maj7, min7, dim7, m7b5, min_maj7, aug_maj7, aug7, 7sus4, dim_maj7.
- Ninths: 9, maj9, min9, 7b9, 7#9, 9#5, 9b5, 7b5.
- Elevenths: 11, maj11, min11, m11b5, maj7#11, 7#11.
- Thirteenths: 13, maj13, min13, 13b9.
- Suspended (extended): sus9, susb9, sus13, 7b13, 7b9b13, min7b13, dim7b13.

Chord equality is **root plus quality**, not equal pitch set: C6 and Amin7 remain distinct. Ordered active lists retain repetitions from URLs and progressions. Manual Add suppresses an existing exact identity. Removal deletes one occurrence. Highlight is an identity group represented by the first matching occurrence after canonicalization; clicking any copy toggles the group. Removing a highlighted occurrence preserves highlighting while an equal copy remains.

Membership data has one row per physical string and 25 cells (`fret`, `note`, ordered chord labels); keyboard data preserves caller pitch order (`pitch`, `note`, ordered labels). Membership lists include repetitions in active order. The presentation deduplicates identity when deciding overlap: two copies of Cmaj alone are not an overlap. Color slots follow distinct identities' first appearance, cycling through eight slots. Palette belongs to Android: `#4FC3F7`, `#FF8A65`, `#81C784`, `#BA68C8`, `#FFD54F`, `#4DB6AC`, `#F06292`, `#7986CB`; baseline overlap is gray `#9E9E9E`.

### Interval labels and approval gate D01

Zero is `Root`. Offsets 4,7,10,11 always use simple names. A seventh means **10 or 11** occurs, not diminished seventh 9. With a seventh: 1→Flat 9th, 2→Major 9th, 5→Perfect 11th, 9→Major 13th; 3→Sharp 9th only if 4 also occurs, otherwise Minor 3rd. Offset 6→Augmented 11th if 7 occurs, otherwise Tritone. Offset 8→Minor 13th if 6 or 7 occurs, otherwise Augmented 5th, regardless of seventh presence.

Without a seventh labels retain formula order. With a seventh sort by `(rank, semitone)`: 0→rank0; 3/4→1; 6/7/8→2; 10/11→3; 1/2→4; 5→5; 9→6; **8 labeled Minor 13th overrides to rank6**. Sharp 9th at semitone3 still receives rank1; augmented11 at semitone6 still receives rank2.

**D01 BLOCKS analyzer/chip parity acceptance:** `Chord.notes_with_intervals/2` zips formula-order notes with independently reordered labels. The LiveView analyzer repeats that zip and decides missing-note styling by label. For C9 source expressions produce notes C,D,E,G,A# paired with Root,Major 3rd,Perfect 5th,Minor 7th,Major 9th, respectively. This is a source-derived mismatch, not a correct music mapping. Export both raw arrays and actual zipped pairs. Do not silently “fix” either list or mark pitches using a corrected mapping without approval. Present the user two outcomes: preserve baseline rendering for v1; or approve semitone-linked note/label/missing metadata as a documented native deviation. Keep raw baseline fixtures immutable in either case. Android may not independently resolve this choice.

## 4. Analyzer contract

Sort sounding pitches ascending, retain the lowest occurrence of each class. Empty→Empty. One class with one unique absolute pitch→Single(note), even if that pitch was repeated. One class at distinct heights→Interval(note,note,Octave). Two classes→Interval(lowest pitch of first class, lowest pitch of second class, simple interval); extra octaves do not change class representatives. At least three classes→Chords(notes in representative-height order,bass lowest class,interpretations). Fretted analysis is a selection-to-pitches adapter; piano uses the same analyzer. Active visualizer chords and highlight never affect analysis.

Identification tries every chromatic root and every formula. Let I be unique input class count, F formula size, C intersection size. Actual predicates:

1. Exact if C=I and F=I.
2. Incomplete if C=I and F>I and F−I≤2 (root can be missing).
3. Partial if C≥3 and F<I. **The code does not require C=F**; the docstring's “strict subset” wording is not an extra predicate (D02).
4. Otherwise no result; fewer than three unique classes returns no interpretations.

Each result has root, quality, exact, incomplete, notes (formula order), intervals (label order), missing_intervals. Only incomplete results have missing labels, in missing-formula order. Missing-priority weights: 7→0,5→1,2/9→2,3/4→3,10/11→4,1/6→5,8→6,root/other→9; sum weights.

Sort keys are exactly `(0,0,0,rootIndex,0)` for exact, `(1,missingCount,missingPrioritySum,rootIndex,formulaLen)` for incomplete, `(2,0,-coverage,rootIndex,formulaLen)` for partial. There is no quality tie-breaker. Formula enumeration comes from `Map.to_list` over a 47-entry Elixir map, not `available_qualities`. **D03:** capture its effective tie order using complete oracle results on the pinned OTP; never substitute Rust HashMap order, enum declaration order, or alphabetical quality sorting. If repeated exports differ, stop and obtain approval for an explicit deterministic tie-break. A generated explicit legacy formula-rank table may be used after verifying ties on the captured runtime.

Bass annotation preserves result order. If bass interval is a formula member: 0→inversion0; 3/4→1; 7/8→2; 10/11→3; 2→4; 5→5; 9→6; 1/6→none. Otherwise none. Slash label appends `/bass` only for nonzero, non-null inversion; a non-chord bass is not appended. Contextual names do not alter these inversion rules. D04: surprising diminished/altered inversion behavior is a compatibility decision, not permission to reinterpret theory.

## 5. Scales, keys and progression resolution

Scale order is the table order. Notes follow formula order from tonic. Labels and grouping are preserved in exported catalog metadata (e.g. `pentatonic_major` displays Major Pentatonic).

| Scale identifier | Formula |
|---|---|
| `major` | `[0, 2, 4, 5, 7, 9, 11]` |
| `minor` | `[0, 2, 3, 5, 7, 8, 10]` |
| `harmonic_minor` | `[0, 2, 3, 5, 7, 8, 11]` |
| `melodic_minor` | `[0, 2, 3, 5, 7, 9, 11]` |
| `pentatonic_major` | `[0, 2, 4, 7, 9]` |
| `pentatonic_minor` | `[0, 3, 5, 7, 10]` |
| `blues` | `[0, 3, 5, 6, 7, 10]` |
| `dorian` | `[0, 2, 3, 5, 7, 9, 10]` |
| `phrygian` | `[0, 1, 3, 5, 7, 8, 10]` |
| `lydian` | `[0, 2, 4, 6, 7, 9, 11]` |
| `mixolydian` | `[0, 2, 4, 5, 7, 9, 10]` |
| `locrian` | `[0, 1, 3, 5, 6, 8, 10]` |
| `phrygian_dominant` | `[0, 1, 4, 5, 7, 8, 10]` |
| `whole_tone` | `[0, 2, 4, 6, 8, 10]` |
| `chromatic` | `[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]` |

Scale display groups: Standard [major,minor]; Minor Variants [harmonic_minor,melodic_minor]; Pentatonic [pentatonic_major,pentatonic_minor]; Blues [blues]; Modes [dorian,phrygian,lydian,mixolydian,locrian]; Exotic [phrygian_dominant,whole_tone]; Other [chromatic].

Diatonic chords classify intervals available above **every** scale degree; they do not simply stack thirds by scale index. First matching triad rule wins: required 4/7→major; 3/7→minor; 3/6→dim; 4/8→aug; 2/7→sus2; 5/7→sus4. Fallback: contains4→major, else contains3→minor, else major. Seventh priority: 3/6/9 excluding7→dim7; 3/6/10 excluding7→m7b5; 3/7/10→min7; 4/7/10→7; 4/7/11→maj7; 3/7/11→min_maj7; 4/8/11→aug_maj7; 4/8/10→aug7; otherwise triad fallback. Exclusions matter in dense scales. No “music theory improvement” is implicit.

Single-key suggestions enumerate twelve tonics and all scales except chromatic. Every input chord's full note set must fit the scale. Score counts input occurrences whose root and **triad-base quality** match the candidate's diatonic triad. Total is input occurrence count. Sort by descending score, then **lexical tonic string**, then lexical scale identifier; not chromatic tonic order. Empty input at the raw domain API yields all candidates with score/total zero; the page suppresses suggestions unless at least two active chords.

Triad-base map: six triads map to themselves. Major: maj7,7,maj6,maj6_9,add9,9,maj9,7b9,7#9,maj7#11,7#11,7b13,7b9b13,11,maj11,13,maj13,13b9. Minor: min7,min_maj7,min6,min6_9,m_add9,min9,min11,min13,min7b13. Dim: dim7,m7b5,dim_maj7,9b5,7b5,m11b5,dim7b13. Aug: aug_maj7,aug7,9#5. Sus2: sus9,susb9. Sus4: 7sus4,sus13. Preserve these mappings even where the name or actual third might suggest another answer (D05).

Multi-key: fewer than three occurrences→[]. Normalize flat roots to sharps here (the single-key score path does not normalize input root equality in the same way). Build candidates in chromatic-tonic order × scale order excluding chromatic. Each stores all covered input indices and a diatonic score over **all** those indices. Greedily select up to three candidates maximizing `(newlyCoveredCount, fullDiatonicScore, -groupedScalePriority)`; equal keys retain the first enumerated candidate. Stop when all covered or no new coverage. If all chosen groups' **exclusive newly covered** counts are one, return []; otherwise each returned group lists its **full membership**, including overlaps and duplicates, ordered by original input index. Sort groups by descending full membership length, stable on greedy order; append unmatched original occurrences as key=null. Do not confuse exclusive assignment with displayed membership.

Page grouping (currently in LiveView, to move to pure `key_groups.rs`): when best score is imperfect, show first three suggestions as single cards. With a perfect best score, partition maximum-score suggestions into modal/non-modal; collapse only groups containing all seven modes with equal note sets. Prominent order is major then minor; other modes retain suggestion order. Append top non-modal cards then all lower-scoring cards. **D06:** baseline drops incomplete modal groups in this branch and enumerates grouped MapSet keys without an explicit row tie-break. Capture and escalate any case where native order or membership differs; do not silently add missing cards or reorder rows.

Applying a suggested key infers seventh mode only if active qualities include one of 7,maj7,min7,dim7,m7b5,min_maj7,aug_maj7,aug7. Extended chords and other suspended/seventh-like qualities do not activate it. Key application uses explicit requested triad/seventh mode; progression application uses its own data and replaces the active list, retaining repeats and clearing highlight.

### Complete progression identity/resolution inventory

Each definition also carries **category, genre, description, example_key, notable_songs**; export every value verbatim, including original proper nouns and flat example keys. Do not reduce catalog parity to the table alone or invent/correct song claims. Category order is Famous / Classic, Curious / Interesting, Exotic / World, Jazz / Sophisticated; definitions and IDs retain source order within each category.

Degree notation below is `degree/accidental/quality`; `nil` means infer. Resolve degree against the progression's own scale's **triad** chords, shift root by accidental, then take explicit quality if supplied; otherwise unchanged diatonic quality for zero accidental, major for accidental −1 on degrees 2/3/6/7, otherwise the diatonic quality. No extra flattening in minor or phrygian-dominant scales. Unknown progression lookup/label returns nil; resolution of an unknown ID currently fails and is a typed error in the proposed API.

| ID | Name | Scale | Ordered degree specifications |
|---|---|---|---|
| `pop_i_v_vi_iv` | Pop: I-V-vi-IV | `major` | `1/0/nil; 5/0/nil; 6/0/nil; 4/0/nil` |
| `classic_i_iv_v` | Classic: I-IV-V | `major` | `1/0/nil; 4/0/nil; 5/0/nil` |
| `blues_12_bar` | Blues: 12-Bar (I-IV-V) | `major` | `1/0/nil; 1/0/nil; 1/0/nil; 1/0/nil; 4/0/nil; 4/0/nil; 1/0/nil; 1/0/nil; 5/0/nil; 4/0/nil; 1/0/nil; 1/0/nil` |
| `jazz_ii_v_i` | Jazz: ii-V-I | `major` | `2/0/min7; 5/0/7; 1/0/maj7` |
| `fifties_i_vi_iv_v` | 50s: I-vi-IV-V | `major` | `1/0/nil; 6/0/nil; 4/0/nil; 5/0/nil` |
| `pachelbel_canon` | Classical: Pachelbel (I-V-vi-iii-IV-I-IV-V) | `major` | `1/0/nil; 5/0/nil; 6/0/nil; 3/0/nil; 4/0/nil; 1/0/nil; 4/0/nil; 5/0/nil` |
| `pop_vi_iv_i_v` | Pop: vi-IV-I-V | `major` | `6/0/nil; 4/0/nil; 1/0/nil; 5/0/nil` |
| `rock_i_bvii_iv` | Rock: I-bVII-IV | `major` | `1/0/nil; 7/-1/nil; 4/0/nil` |
| `folk_i_iv` | Folk: I-IV | `major` | `1/0/nil; 4/0/nil` |
| `minor_pop_i_vi_iii_vii` | Pop: i-VI-III-VII | `minor` | `1/0/nil; 6/0/nil; 3/0/nil; 7/0/nil` |
| `minor_pop_i_bvi_biii_bvii` | Pop: i-bVI-bIII-bVII | `minor` | `1/0/nil; 6/0/nil; 3/0/nil; 7/0/nil` |
| `canon_rock` | Rock: V-i-VI-IV (Canon Rock) | `minor` | `5/0/major; 1/0/nil; 6/0/nil; 4/0/nil` |
| `modal_interchange_i_iv` | Modal Interchange: I-iv | `major` | `1/0/nil; 4/0/minor` |
| `creep_progression` | Modal Interchange: I-III-IV-iv (Creep) | `major` | `1/0/nil; 3/0/major; 4/0/nil; 4/0/minor` |
| `chromatic_mediant_i_biii` | Chromatic Mediant: I-bIII | `major` | `1/0/nil; 3/-1/major` |
| `chromatic_mediant_i_bvi` | Chromatic Mediant: I-bVI | `major` | `1/0/nil; 6/-1/major` |
| `chromatic_mediant_i_iii` | Chromatic Mediant: I-III | `major` | `1/0/nil; 3/0/major` |
| `neapolitan_i_bii_v_i` | Classical: Neapolitan (i-bII-V-i) | `minor` | `1/0/nil; 2/-1/major; 5/0/7; 1/0/nil` |
| `descending_chromatic_bass` | Chromatic: Descending Bass (I-i7-IV-iv6-I) | `major` | `1/0/nil; 1/0/min7; 4/0/nil; 4/0/min7; 1/0/nil` |
| `line_cliche_i_bvii_bvi_v` | Chromatic: Line Cliche (i-bVII-bVI-V) | `minor` | `1/0/nil; 7/0/nil; 6/0/nil; 5/0/major` |
| `omnipotent_progression` | Classical: Omnipotent (I-VII-iv-iv°-III-II-I) | `major` | `1/0/nil; 7/-1/major; 4/0/minor; 4/0/dim; 3/0/major; 2/0/major; 1/0/nil` |
| `ascending_bass_i_ii_iii_iv` | Pop: Ascending (I-ii-iii-IV) | `major` | `1/0/nil; 2/0/nil; 3/0/nil; 4/0/nil` |
| `chromatic_walkdown_i_bvii_vi_bvii_i` | Rock: Chromatic Walkdown (I-bVII-VI-bVII-I) | `major` | `1/0/nil; 7/-1/nil; 6/0/nil; 7/-1/nil; 1/0/nil` |
| `andalusian_cadence` | Flamenco: Andalusian Cadence (i-bVII-bVI-V) | `minor` | `1/0/nil; 7/0/nil; 6/0/nil; 5/0/major` |
| `flamenco_phrygian_dominant` | Flamenco: Phrygian Dominant (I-bII-bIII-bII) | `phrygian_dominant` | `1/0/nil; 2/0/major; 3/-1/major; 2/0/major` |
| `harmonic_minor_i_iv_v` | Harmonic Minor: i-iv-V | `minor` | `1/0/nil; 4/0/minor; 5/0/7` |
| `byzantine_double_harmonic` | Exotic: Byzantine / Double Harmonic (I-bII-I) | `major` | `1/0/nil; 2/-1/major; 1/0/nil` |
| `hungarian_minor` | Exotic: Hungarian Minor (i-bII-iv) | `minor` | `1/0/nil; 2/-1/major; 4/0/minor` |
| `japanese_hirajoshi` | World: Japanese / Hirajoshi (I-bII-V-bVI) | `major` | `1/0/nil; 2/-1/nil; 5/0/nil; 6/-1/nil` |
| `middle_eastern_hijaz` | World: Hijaz / Makam (I-bII-bIII-iv) | `phrygian_dominant` | `1/0/nil; 2/0/major; 3/-1/major; 4/0/minor` |
| `klezmer_freygish` | World: Klezmer / Freygish (I-bII-III-VII) | `phrygian_dominant` | `1/0/nil; 2/0/major; 3/-1/major; 7/0/major` |
| `dorian_vamp_i_iv` | Modal: Dorian Vamp (i-IV) | `minor` | `1/0/min7; 4/0/7` |
| `dorian_aeolian_i_bvii_iv` | Modal: Dorian-Aeolian (i-bVII-IV) | `minor` | `1/0/nil; 7/0/nil; 4/0/nil` |
| `lydian_i_ii` | Modal: Lydian (I-II) | `major` | `1/0/nil; 2/0/major` |
| `whole_tone` | Modal: Whole Tone (I-II-III) | `major` | `1/0/aug; 2/0/aug; 3/0/aug` |
| `mixolydian_bvi_i_bvii_bvi_bvii` | Modal: Mixolydian bVI (I-bVII-bVI-bVII) | `major` | `1/0/nil; 7/-1/nil; 6/-1/nil; 7/-1/nil` |
| `phrygian_vamp_i_bii_i` | Modal: Phrygian (i-bII-i) | `minor` | `1/0/nil; 2/-1/major; 1/0/nil` |
| `spanish_phrygian_i_bii_iii` | Modal: Spanish Phrygian (i-bII-III) | `minor` | `1/0/nil; 2/-1/major; 3/0/major` |
| `blues_dominant_i7_iv7_v7` | Blues: Dominant 7th (I7-IV7-V7) | `major` | `1/0/7; 4/0/7; 5/0/7` |
| `minor_blues_i7_iv7_v7` | Blues: Minor Blues (i7-iv7-V7) | `minor` | `1/0/min7; 4/0/min7; 5/0/7` |
| `rhythm_changes_a` | Jazz: Rhythm Changes A (I-vi-ii-V) | `major` | `1/0/7; 6/0/min7; 2/0/min7; 5/0/7` |
| `rhythm_changes_b` | Jazz: Rhythm Changes B (III7-VI7-II7-V7) | `major` | `3/0/7; 6/0/7; 2/0/min7; 5/0/7` |
| `coltrane_changes` | Jazz: Coltrane Changes (Giant Steps) | `major` | `1/0/maj7; 5/-1/7; 3/1/maj7; 5/0/7; 1/0/maj7` |
| `coltrane_sub_ii_v_i` | Jazz: Coltrane Sub (ii-V-I with major third substitution) | `major` | `2/0/min7; 5/0/7; 1/0/maj7` |
| `backdoor_progression` | Jazz: Backdoor (iv-bVII7-I) | `major` | `4/0/min7; 7/-1/7; 1/0/maj7` |
| `jazz_turnaround` | Jazz: Turnaround (I-vi-ii-V) | `major` | `1/0/maj7; 6/0/min7; 2/0/min7; 5/0/7` |
| `minor_ii_v_i` | Jazz: Minor ii-V-i | `minor` | `2/0/m7b5; 5/0/7; 1/0/min7` |
| `tritone_sub_ii_bii_i` | Jazz: Tritone Substitution (ii-bII7-I) | `major` | `2/0/min7; 2/-1/7; 1/0/maj7` |
| `secondary_dominant` | Jazz: Secondary Dominant (I-V/ii-ii-V-I) | `major` | `1/0/maj7; 5/1/7; 2/0/min7; 5/0/7; 1/0/maj7` |
| `bird_blues` | Jazz: Bird Blues | `major` | `1/0/maj7; 6/0/min7; 2/0/min7; 5/0/7; 1/0/7; 4/0/7; 1/0/maj7; 6/0/min7; 2/0/min7; 5/0/7; 1/0/maj7; 5/0/7` |
| `modal_jazz_vamp` | Jazz: Modal Vamp (i-iv) | `minor` | `1/0/min7; 4/0/7` |
| `extended_ii_v_chain` | Jazz: Extended Chain (iii-vi-ii-V-I) | `major` | `3/0/min7; 6/0/min7; 2/0/min7; 5/0/7; 1/0/maj7` |
| `iv_minor_substitution` | Jazz: IV-iv-I (Minor Subdominant) | `major` | `4/0/maj7; 4/0/min7; 1/0/maj7` |
| `plagal_cadence` | Classical: Plagal (IV-I) | `major` | `4/0/nil; 1/0/nil` |
| `deceptive_cadence` | Classical: Deceptive (V-vi) | `major` | `5/0/7; 6/0/minor` |
| `minor_plagal` | Classical: Minor Plagal (iv-I) | `major` | `4/0/minor; 1/0/nil` |
| `jazz_blues_form` | Jazz: Jazz Blues | `major` | `1/0/7; 4/0/7; 1/0/7; 6/0/min7; 2/0/min7; 5/0/7; 1/0/7` |
| `bossa_nova_ii_v_i` | Jazz: Bossa Nova (ii-V-I) | `major` | `2/0/min7; 5/0/7; 1/0/maj7` |
| `aaba_form` | Jazz: AABA Form | `major` | `1/0/maj7; 6/0/min7; 2/0/min7; 5/0/7; 1/0/maj7; 6/0/min7; 2/0/min7; 5/0/7; 3/0/7; 6/0/7; 2/0/min7; 5/0/7; 1/0/maj7; 6/0/min7; 2/0/min7; 5/0/7` |

D07: catalog prose is not an alternative algorithm. Examples include `rhythm_changes_b` naming II7 but specifying min7 on degree2, `descending_chromatic_bass` naming iv6 but specifying min7, and “modal” progressions backed by major/minor plus explicit qualities. Preserve source records for review; correction requires explicit approval, new deviation fixtures and release notes, never a quiet edit in ported data.

## 6. Current page state and transitions

Defaults: guitar Standard with reference Standard; no chords; no highlight; Visualizer; empty fretted selection. Durable page fields are instrument, tuning_state (nil for piano), active_chords, highlighted_chord, tab, selection. Derived fields include tuning note names, cells/keys, colors, analysis and suggestions. They are recomputed, not persisted.

| Transition | Observable baseline |
|---|---|
| Add chord | Append only if exact identity absent; keep selection, tuning, tab and highlight |
| Remove occurrence | Delete that index only; find first remaining occurrence of old highlighted identity or clear |
| Toggle highlight | Toggle clicked identity, canonical representative first occurrence; no pitch-set grouping |
| Clear chords | Clear active list and highlight, not selection |
| Change instrument | Same instrument no-op; otherwise reset to new Standard/nil tuning, clear highlight, keep chords/tab; fretted→fretted retains positions whose indices fit; crossing piano boundary clears selection; close tuning draft |
| Change tab | Keep tuning, chords, highlight and selection; same tab no-op; analysis is absent on Visualizer |
| Toggle fretted position | Same fret on same string removes; different fret replaces that string's position; other strings untouched |
| Toggle piano pitch | Only in piano Analyzer; toggle absolute pitch and canonicalize ascending unique list |
| Clear selection | Clear only active instrument selection |
| Tuning draft | Open copies committed tuning; selecting preset or editing string affects draft only; Apply commits and closes; Close discards on next open. Unrelated committed-page recalculation resets draft from committed tuning in web |
| Apply key / progression / suggestion | Replace chords, clear highlight; keep instrument, tuning, tab and selection |

UI-only transient fields: modal visibility, chord-form root/quality (initial C/major), key preview tonic/scale/mode (C/major/triad reset on opening), progression preview (pop_i_v_vi_iv/C reset on opening), expanded key modes (reset on page recalculation), scroll/zoom/focus and asynchronous loading flags. Android manages these; the pure core provides preview computations and tuning draft math without persisting modal visibility. Do not restore uncommitted tuning as the last session.

## 7. Existing URL contract (page-level authoritative boundary)

Root route `/`, query values decoded before music parsing. Preserve percent-encoded `#`, `/`, commas and spaces: `C%239` is C#9; raw `#` starts a fragment and is not a chord sharp. `URI.encode_query` uses form-style percent encoding. Test semantic maps separately from byte order. Canonical native encoder proposes keys sorted lexically and uppercase percent escapes, space→`+`; approval is required if byte-for-byte legacy ordering is relied on (D08). Unknown query keys are ignored by the baseline.

| Field | Decode and encode contract |
|---|---|
| instrument | Exact `piano` handled by PageCodec; otherwise recognized fretted ID, invalid/missing→guitar. Omit guitar; emit other IDs. Legacy URLCodec by itself does **not** recognize piano |
| chords | Comma-separated root + **label suffix**, skip empty/invalid tokens individually; preserve valid order and duplicates. No whitespace trimming. Non-string→[]. Omit when empty |
| highlight | Exact full label of an active chord; first occurrence wins; unknown/missing/nonmatching→none. Encode label, not index; omit none |
| tuning | Fretted legacy sharp note list; split comma dropping empty tokens; exact string count and all valid notes required, else instrument Standard. Omit if notes equal Standard |
| pitches | Presence is authoritative, even if empty/non-string/invalid. Split comma **without** dropping empty tokens; every token must fully parse as an integer in 0–127, exact string count. Invalid→Standard pitches and Standard reference; never fall back to conflicting tuning |
| reference | Only used with valid explicit pitches; must be a preset name for the decoded instrument, otherwise Standard. Without pitches ignore reference; resolve legacy tuning nearest to Standard, not a detected preset |
| tab | Exact analyzer/visualizer, else visualizer. Encode only analyzer |
| marked | Comma-separated `string-fret`; split first hyphen; both parts must fully parse as integers. Skip malformed tokens. Last valid parsed duplicate string wins **before** page filtering; then keep string≥0 and <count, fret in0–24. Encode ascending string index; omit empty |
| keys | Piano only. Split commas, keep fully parsed integer tokens in48–83, unique and ascending; skip invalid siblings. Non-string→[]. Encode ascending unique pitches, omit empty |

Piano ignores tuning/pitches/reference/marked and emits none of them. Fretted pages ignore keys. Selections may exist in Visualizer URLs and remain on returning to Analyzer. Low-level `decode_marked` does not range-check, and `filter_marked_notes` only checks `<string_count`; the complete page codec imposes the safe bounds. Do not conflate their contracts. A later syntactically valid but out-of-range duplicate marked value can erase an earlier valid value after filtering; fixtures must cover this ordering.

Exact-pitch encoding first emits legacy tuning if its **note names** differ from Standard. It additionally emits pitches whenever exact pitches differ from Standard **or reference is non-Standard**, and emits reference only when non-Standard. Thus an octave-shifted Standard pitch-class tuning needs pitches but no tuning; Standard pitches anchored to Low G still need pitches and reference.

Elixir integer parsing accepts a sign and leading zeros but demands no trailing text; whitespace and fractional forms are not silently trimmed. Test `+60`, `060`, `60x`, whitespace, empty, duplicate fields, nested/list values from Plug query parsing and malformed percent escapes. **D09:** transport parsing is not defined by a `map()` codec alone. Capture actual Plug GET behavior for duplicate scalar keys and bracket/nested parameters; preserve field-local fallback rather than rejecting valid siblings. Invalid whole URL syntax/unsupported origin is an import error, not an excuse to reinterpret malformed values. Origin allowlist and length/resource limits must be approved in P0, because no such native transport limit is specified by the musical source.

## 8. Proposed typed Rust surface (not existing Elixir API)

Public entry points operate on owned values, no global mutable session or hidden cache. All IDs have validated constructors and stable string conversions matching the tables; no platform enum ordinal is a wire identifier. `QualityId`, `ScaleId`, `ProgressionId`, `PresetName`, `NoteName` below are validated domain types, not arbitrary unchecked strings. FFI maps them to generated records/enums or checked strings in one adapter.

```rust
pub struct PitchClass(u8);       // validated 0..=11
pub struct OpenPitch(u8);        // 0..=127
pub struct SoundingPitch(u16);   // permits open+24
pub struct StringIndex(u8);
pub struct Fret(u8);             // 0..=24
pub enum InstrumentId { Guitar, Bass4, Bass5, Ukelele, Piano }
pub enum Tab { Visualizer, Analyzer }
pub enum ChordMode { Triad, Seventh }
pub struct ChordSpec { pub root: PitchClass, pub quality: QualityId }
pub struct TuningState { pub pitches: Vec<OpenPitch>, pub reference: PresetName }
pub struct Position { pub string: StringIndex, pub fret: Fret }
pub enum InstrumentState {
    Fretted { instrument: InstrumentId, tuning: TuningState,
              selected: Vec<Position> }, // unique, ascending physical string
    Piano { selected: Vec<OpenPitch> },  // unique ascending, restricted48..83
}
pub struct PageState {
    pub instrument: InstrumentState,
    pub chords: Vec<ChordSpec>,          // occurrences, not a set
    pub highlight: Option<ChordSpec>,    // identity must occur in chords
    pub tab: Tab,
}
pub enum Action {
    SetInstrument(InstrumentId), SetTab(Tab), AddChord(ChordSpec),
    RemoveChord { occurrence: u32 }, ToggleHighlight { occurrence: u32 },
    ClearChords, TogglePosition(Position), TogglePianoKey(OpenPitch), ClearSelection,
    CommitTuning(TuningState), ApplyKey { tonic: PitchClass, scale: ScaleId, mode: ChordMode },
    ApplyProgression { tonic: PitchClass, progression: ProgressionId },
    ApplySuggestedKey { tonic: PitchClass, scale: ScaleId },
}
pub fn default_state() -> PageState;
pub fn validate_state(state: &PageState) -> Result<(), CoreError>;
pub fn reduce(state: &PageState, action: Action) -> Result<PageState, CoreError>;
pub fn evaluate(state: &PageState) -> Result<Evaluation, CoreError>;
pub fn dispatch(state: &PageState, action: Action) -> Result<EvaluatedState, CoreError>;
pub fn catalogs() -> Catalogs;
pub fn chord_details(chord: &ChordSpec) -> ChordDetails;
pub fn scale_notes(tonic: PitchClass, scale: ScaleId) -> Vec<PitchClass>;
pub fn diatonic_chords(tonic: PitchClass, scale: ScaleId, mode: ChordMode) -> Vec<ChordSpec>;
pub fn progression_chords(tonic: PitchClass, id: ProgressionId) -> Vec<ChordSpec>;
pub fn analyze_pitches(pitches: &[SoundingPitch]) -> Analysis;
pub fn identify(notes: &[PitchClass], bass: Option<PitchClass>) -> Vec<Interpretation>;
pub fn suggest_keys(chords: &[ChordSpec]) -> Vec<KeySuggestion>;
pub fn suggest_multi_keys(chords: &[ChordSpec]) -> Vec<KeyGroup>;
pub fn preset_tuning(instrument: InstrumentId, name: &PresetName) -> Result<TuningState, CoreError>;
pub fn edit_tuning_note(instrument: InstrumentId, draft: &TuningState,
                        string: StringIndex, note: PitchClass) -> Result<TuningState, CoreError>;
pub fn detect_preset(instrument: InstrumentId, pitches: &[OpenPitch]) -> Result<String, CoreError>;
pub fn decode_page_params(params: &RawParams) -> DecodeReport;
pub fn encode_page_params(state: &PageState) -> Result<Vec<QueryPair>, CoreError>;
pub fn import_url(url: &str, policy: &UrlPolicy) -> Result<DecodeReport, CoreError>;
pub fn share_url(state: &PageState, base: &ShareBase) -> Result<String, CoreError>;
pub fn encode_snapshot(state: &PageState) -> Result<String, CoreError>;
pub fn decode_snapshot(json: &str) -> Result<PageState, CoreError>;
```

Typed state invariant rejects `Fretted { instrument: Piano }`, wrong pitch count, foreign preset reference, duplicate strings, bad index/range and highlight absent from chords. Constructors/deserialization validate; a public record alone is not proof. `reduce` is atomic: errors leave caller state unchanged. Wrong-kind user gestures are no-ops where the web ignores them; malformed indices are typed errors, never panics or negative-index deletion. This safety difference is explicit (D10), not a musical rule change. `dispatch` = reduce then evaluate; normalization must match page round-trip semantics without reparsing text at every tap. Tuning draft operations live outside PageState; callers commit only on Apply.

### Returned records (complete field obligations)

- `Catalogs`: ordered instruments (ID, English label, kind, fret count/string count or pitch range, ordered named pitch presets); quality entries (ID,label,formula,interval labels), quality groups, scale entries (ID,label,formula), scale groups, full progression entries/groups. Formula-rank metadata is internal compatibility data, not a UI sort instruction.
- `ChordDetails`: chord identity, full label, formula-order notes, independently ordered interval labels, legacy zipped note/interval pairs. Any semitone-linked corrected `tones` result is gated by D01, not assumed. Include no contradictory missing-note mapping before that decision.
- `Interpretation`: chord identity, exact flag, incomplete flag, formula-order notes, interval labels, missing interval labels, optional bass, optional inversion0–6, optional slash label (present for bass-aware calls). Internal sort metadata stays private. Derived match kind = Exact/Incomplete/Partial.
- `Analysis`: tagged Empty; Single{note}; Interval{low_note,high_note,label}; Chords{notes,bass,interpretations}. `Evaluation.analysis` is optional and absent on Visualizer; empty analysis on Analyzer is distinct from “not computed”.
- `FretCell`: string index, fret, pitch class, sounding pitch, ordered membership occurrence indices and labels. `KeyboardKey`: absolute pitch, pitch class, ordered membership occurrence indices and labels. Domain rows preserve physical order; rendering can reverse vertical layout but not relabel indices.
- `ChordOccurrence`: occurrence index, identity, label, color slot, highlighted boolean. `Evaluation`: occurrences; typed `Surface` (Fretboard{rows}/Keyboard{keys}); optional analysis; raw key suggestions; display key rows; multi-key groups; detected tuning preset optional. Empty inactive surface is not a fallback guitar board.
- `KeySuggestion`: tonic,scale,score,total,diatonic chords. `KeyGroup`: optional key, ordered original occurrence indices and chords (full membership); unmatched key=null. `KeyRow`: Single{suggestion} or Collapsed{prominent,others} as baseline grouping above.
- `EvaluatedState`: normalized PageState and Evaluation. Derived output uses no random IDs; occurrence indices refer to the accompanying state, not a stale previous evaluation.
- `RawParams`: string keys with `RawValue = Text(String) | NonText`; NonText captures nested/list/nil boundary cases without requiring arbitrary Elixir terms over FFI. `DecodeReport`: normalized state plus ordered field diagnostics (ignored/reset fields); diagnostics are new observability, not changes to permissive baseline normalization. `QueryPair`: name/value text; no duplicates on encode.
- `CoreError`: stable code plus optional field name, never a raw stack trace: InvalidState, UnknownIdentifier, OutOfRange, InvalidAction, InvalidUrl, UnsupportedOrigin, InputTooLarge, InvalidSnapshot, UnsupportedSchemaVersion. Concrete limit policy is a P0 decision; no invented numeric limit in this contract. Corrupt or future snapshot must not silently overwrite stored data.

Typed UniFFI entry points mirror `default_state`, `catalogs`, `evaluate`, `dispatch`, URL/snapshot methods, and preview/tuning helpers using adapter DTOs. Strings represent encoded URLs/snapshots only, **not a giant JSON execute API** for ordinary UI actions. Kotlin cannot implement fallback music rules. Adapter conversion and error tests must prove typed enum/list/nullable/integer parity. One single Rust call returns state and its matching derived output; Android serializes updates and discards stale asynchronous evaluation results.

## 9. Persistence and wire versioning (new native contract)

Legacy web URLs have no version field; continue reading/writing them. They are the sharing format, not the entire native storage schema. Proposed last-session snapshot is JSON `{"schema_version":1,"page":...}` with stable textual IDs, ordered chords, optional identity highlight, tagged fretted/piano state, integer pitches, reference, tab and ordered selection. No colors, results, modal drafts, timestamps or platform objects. Snapshot serialization tests pin exact schema field names before implementation; unknown future version is rejected with preserved original bytes for recovery.

Restoration precedence: a valid explicit incoming import/intent wins over saved committed snapshot; otherwise saved valid supported snapshot; otherwise defaults. Invalid incoming input reports an English error and keeps the existing/restored valid session, not a blank reset. Field-local malformed URL values still use the documented baseline defaults. Android performs atomic storage after successful committed transitions; the core only encodes/validates values. Rotation and process-death restoration must not replay an already-consumed incoming URL over newer state. No runtime network is required. Share base/origin is supplied by a validated configuration discovered from the website, not invented in Rust. Verified Android App Links would require website association changes and are outside the no-web-change plan; manual paste/import and share sheet are required regardless.

## 10. Approval and parity ledger

D01 zipped intervals/missing styling; D02 partial predicate versus docs; D03 formula-map tie order; D04 inversion mapping; D05 unusual triad-base scoring and flat-root asymmetry; D06 modal grouping/order/dropped partial groups; D07 progression prose/data inconsistencies; D08 exact query-byte canonicalization; D09 transport behavior and import limits/origin policy; D10 safer typed rejection of malformed actions. All are review gates. Capture current baseline first. A user-approved deviation is recorded with input, old result, proposed result, reason, affected phase and regression fixture. A discrepancy is never resolved by regenerating golden expectations from the Rust port. Other discoveries join this ledger, not hidden “cleanup”.

See `04-core-phases.md` for source oracle export, exclusive file ownership, tests-first work packages and the paired Android APK approval gates.
