# Plan: Bass Instrument Support

## Goal

Allow the user to switch the visible fretboard between guitar (6 strings), 4-string bass, and 5-string bass.

## Decisions (from grill-me session)

1. **Model:** Instrument type (`:guitar`, `:bass_4`, `:bass_5`) defining strings, standard tuning, presets, and frets.
2. **New module:** `Fretboard.Music.Instrument` — source of truth for instrument definitions.
3. **Bass 4 presets:** Standard (E,A,D,G), Drop D (D,A,D,G), Half Step Down (D#,G#,C#,F#).
4. **Bass 5 presets:** Standard (B,E,A,D,G), Half Step Down (A#,D#,G#,C#,F#), Drop A (A,E,A,D,G).
5. **Frets:** 24 for all instruments.
6. **UI:** Dropdown selector in the top controls bar.
7. **URL:** Explicit `instrument` param (backward compatible, defaults to `:guitar`).
8. **State:** Atom in LiveView assigns, string in URL (URLCodec handles conversion).
9. **Instrument change:** Reset tuning to the new instrument's standard, keep active chords.
10. **Tuning modal:** Adapts dynamically to the active instrument's string count.
11. **Music API:** New functions: `instruments/0`, `instrument/1`, `instrument_strings/1`, `instrument_standard_tuning/1`, `instrument_tuning_presets/1`, `instrument_preset_names/1`. Old functions (`tuning_presets/0`, `tuning_preset_names/0`) delegate to `:guitar`.
12. **Tests:** TDD with sub-agents (test → implement → review). Full coverage of Instrument, URLCodec (with 7 edge cases), Music facade, and LiveView.

## URLCodec edge cases to test

1. Invalid instrument value → defaults to `:guitar` with guitar standard tuning.
2. Tuning with wrong note count for instrument → falls back to instrument's standard.
3. Tuning with valid notes but invalid instrument → uses guitar, validates 6 notes.
4. `instrument=bass_4` without `tuning` → uses bass_4 standard (E,A,D,G).
5. `instrument=bass_5&tuning=B,E,A,D,G` → preserves correct tuning.
6. `encode_params` always includes `instrument` when not `:guitar`.
7. Backward compat: URL without `instrument` with 6-note tuning works as before.

## Files to create/modify

### New files
- `lib/fretboard/music/instrument.ex` — Instrument definitions module
- `test/fretboard/music/instrument_test.exs` — Tests for Instrument module

### Modified files
- `lib/fretboard/music.ex` — New facade functions + delegate old ones to `:guitar`
- `lib/fretboard/music/tuning.ex` — Extract guitar presets into Instrument (or keep as fallback)
- `lib/fretboard/music/url_codec.ex` — Encode/decode instrument, validate tuning by instrument
- `lib/fretboard_web/live/fretboard_live.ex` — Instrument selector, dynamic state, adaptive modal
- `test/fretboard/music_test.exs` — Tests for new facade functions
- `test/fretboard/music/url_codec_test.exs` — Edge case tests for instrument support
- `test/fretboard_web/live/fretboard_live_test.exs` — Tests for instrument switching

## Status: COMPLETE ✅

All 3 phases implemented and reviewed. 337 tests, 0 failures. `mix format` and `mix credo --strict` clean.

## Implementation order (TDD with sub-agents)

### Phase 1: Instrument module + Music facade
1. **Sub-agent 1 (Test Writer):** Write failing tests for `Instrument` module and new `Music` facade functions.
2. **Sub-agent 2 (Implementer):** Implement `Instrument` module and add facade functions to `Music`.
3. **Sub-agent 3 (Reviewer):** Review, run full test suite, check formatting.

### Phase 2: URLCodec changes
1. **Sub-agent 1 (Test Writer):** Write failing tests for instrument encode/decode in URLCodec (including all 7 edge cases).
2. **Sub-agent 2 (Implementer):** Implement instrument support in URLCodec.
3. **Sub-agent 3 (Reviewer):** Review, run full test suite, check formatting.

### Phase 3: LiveView changes
1. **Sub-agent 1 (Test Writer):** Write failing tests for instrument selector, dynamic rendering, and adaptive modal.
2. **Sub-agent 2 (Implementer):** Implement instrument selector, dynamic string_count, adaptive modal in LiveView.
3. **Sub-agent 3 (Reviewer):** Review, run full test suite, check formatting.

## Architecture notes

- `Instrument` is an internal module under `Fretboard.Music` — the web layer never calls it directly.
- `Music` facade exposes all instrument functions.
- `URLCodec` needs to know about instruments to validate tuning note counts.
- `fretboard_data/2` is already instrument-agnostic (maps over whatever tuning list it receives).
- The LiveView `@string_count` constant becomes dynamic, derived from the instrument.
- The tuning modal's `6..1//-1` loop becomes dynamic based on instrument string count.