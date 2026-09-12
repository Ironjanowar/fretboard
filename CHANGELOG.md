# Changelog

All notable changes to this project are documented here. Entries are dated
with the date and time they were added — no version numbers.

## 2026-09-11 16:53 UTC

### Added
- Piano support with a fixed three-octave C3–B5 keyboard. The visualizer marks
  every visible occurrence of the selected chord notes using the existing
  color system.
- Piano analyzer with independently selectable keys, chord and interval
  identification, inversions, keyboard accessibility, and shareable URL state.

### Changed
- Instrument controls hide string tuning options when Piano is selected.
- Switching between piano and a string instrument clears analyzer selections
  that cannot be translated between keys and fretboard positions.

## 2026-09-09 10:47 UTC

### Added
- Multi-key suggestions: when no single key fits the selected chords, the
  app suggests up to three keys that together cover them, plus a group for
  chords that fit no suggested key.
- Full membership in multi-key cards: each suggested key now lists every
  selected chord that fits it, not only the chords exclusively assigned to
  it (e.g. for Dmin–Gmaj–Emaj–Fmaj, the C major card lists Dmin, Gmaj, Fmaj
  and the A harmonic minor card lists Dmin, Emaj, Fmaj).

### Changed
- The interface is now fully in English (labels, instructions, loading,
  empty and error states, accessibility copy). The instrument formerly
  displayed as "Ukelele" now reads "Ukulele". Stable URL values such as
  `instrument=ukelele` are unchanged, so existing links keep working.
- README rewritten for users of the app, with new screenshots.
- CHANGELOG started with this entry.

### Earlier (pre-changelog) work, for reference
- English-only convention documented in AGENTS.md.
- Chord analyzer: identify chords and intervals from notes clicked on the
  fretboard, including inversions, incomplete voicings, slash chords, and
  duplicate-chord grouping; analyzes real sounding pitches so reentrant
  tunings (high-G ukulele) and pitch crossings behave correctly.
- Key suggestions from selected chords with mode grouping, diatonic chord
  previews, and async loading.
- Chord progressions catalog (pop, jazz, blues, flamenco, modal, and more)
  applicable to any tonic.
- Instruments: guitar, 4- and 5-string bass, ukulele; per-string custom
  tunings with octave support, 9+ tuning presets per instrument.
- 44 chord types: triads, sevenths, sixths, added tones, ninths,
  elevenths, thirteenths, suspended and altered chords.
- 14 scale types from major/minor to modes and exotic scales.
- Shareable URLs encoding chords, marked analyzer notes, instrument, and
  tuning state.
- Mobile-friendly layout with native scrolling and a reconnection-safe
  LiveView heartbeat.