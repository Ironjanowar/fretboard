# Verification and Acceptance Matrix

## Evidence rules

This document specifies tests to implement and run. Checkboxes are intentionally empty. Source-reading findings are not test execution; host Rust tests are not Android native-loading tests; emulator success is not OnePlus approval. Each gate ledger must distinguish those layers.

Create `docs/validation/phase-P<N>.md` in `fretboard-android` for each phase. Record core/app commits, artifact checksums, toolchain, device/API/ABI, commands and exit codes, reports/screenshots, known failures, user approval reference, and next-phase authorization. Never store passwords, device serials or private keystores in evidence.

## Per-phase gates

| Phase | Automated gate | Exact manual artifact / behavior | Stop rule |
|---|---|---|---|
| P0 | Toolchain smoke, source/fixture schema checks, contract review | Approve toolchain ledger, signing custody, package ID, oracle provenance | No full implementation if setup or contract unresolved |
| P1 | Real Rust host test; generated bindings compile; native loading on emulator; packaging/signature checks | Install APK, enable airplane mode, press UI action and obtain real Rust-computed chord/notes; relaunch | Stop if simulated output, missing ABI, or binding issue |
| P2 | Catalog/golden tests; visualizer and duplicate occurrence UI tests | Compare/highlight/remove chords, all instrument visualizers, horizontal scroll, landscape | No analyzer phase until visualizer approved |
| P3 | Tuning reference and analysis golden tests; draft/cancel and fretted selection UI tests | Low G vs Standard, fixed-reference edits, one selection/string, bass inversions, clear notes | No piano phase until pitch semantics approved |
| P4 | Piano all-key geometry/input tests, lifecycle transitions and no-op same instrument | All 36 keys, black/white edges, octaves, switching to/from fretted instruments | No key/progression phase until selection isolation approved |
| P5 | Single/multi-key ranking and progression catalog fixtures, relative-group tests | Apply keys and repeated progressions, overlapping memberships, rapid chord changes | Stop on stale results or reordered catalog |
| P6 | URI hostile inputs and round-trip tests, saved-session migration and process recreation | Copy/paste/import/share, web round-trip, cold/warm imports, force-stop and restore, update | No release audit until state safety is proven |
| P7 | Full suites, lint, dependency/secret/security checks, artifact download verification | TalkBack, fonts, insets, offline, performance measurements, same-signer upgrade | No final acceptance with unapproved blockers |

Each APK phase is: core RED → GREEN → core review → candidate AAR → Android RED → GREEN → independent review → release candidate APK → real-device user approval. A phase may contain multiple short vertical tasks. Do not finish all test-writer tasks across the whole roadmap before any implementation.

## Cross-platform oracle matrix

Paths below refer to existing web repository tests. New Rust counterparts and fixture paths are enumerated in the core task document.

| Contract | Baseline anchors |
|---|---|
| Notes, formula/label catalog | `test/fretboard/music/note_test.exs`, `chord_test.exs`, `chord_extended_formulas_test.exs`, `chord_label_extended_test.exs` |
| Interval association and extensions | `test/fretboard/music/chord_interval_labels_test.exs`, plus discrepancy decision for `notes_with_intervals` |
| Exact/incomplete/partial results and inversions | `test/fretboard/music/chord_identify_test.exs`, `chord_identify_incomplete_test.exs`, `chord_identify_extended_inversion_test.exs` |
| Instrument/preset catalog | `test/fretboard/music/instrument_test.exs`, `pitch_state_test.exs` |
| Sounding height and duplicate octaves | `test/fretboard/music/analyzer_state_followup_test.exs`, `piano_analysis_test.exs`, `test/fretboard_web/live/absolute_pitch_analysis_test.exs` |
| Key scoring/coverage | `test/fretboard/music/scale_test.exs`, `multi_key_full_membership_test.exs`, `chord_mode_test.exs` |
| Progression metadata/order | `test/fretboard/music/progression_test.exs` |
| Legacy/new URL field fallback | `test/fretboard/music/url_codec_test.exs`, `url_boundary_test.exs`, `page_codec_boundary_test.exs`, `piano_url_test.exs` |
| Duplicate identity and occurrence removal | `test/fretboard_web/live/duplicate_chords_live_test.exs` |
| Draft tuning and instrument changes | `test/fretboard_web/live/pitch_tuning_lifecycle_test.exs`, `change_string_validation_followup_test.exs`, `piano_lifecycle_test.exs` |
| Analyzer independence and stale work | `test/fretboard_web/live/analyzer_refresh_test.exs`, `derived_state_test.exs` |
| Piano touch target intent / semantics | `test/fretboard_web/live/piano_visualizer_test.exs`, `piano_analyzer_test.exs` |

Golden fixture generator must exercise actual Elixir functions at the frozen commit. It must not implement a second oracle by translating algorithms into Python. Include catalog counts/identifiers, source SHA, runtime version and deterministic output ordering. Separate legacy-observed fixtures from approved-corrected fixtures; never update expected values merely to make Rust tests green.

## Mandatory regression scenarios

### Musical identity and catalog

- Exact root+quality duplicate addition is rejected; equivalent pitch sets with different identities remain distinct.
- Imported/progression duplicates persist in order; removing one occurrence preserves highlighted identity when another remains.
- Duplicate identities share colors and do not by themselves become gray overlap.
- Actual source catalog, not stale README counts, defines qualities/scales/progressions.
- `ukelele` survives serialization while UI says Ukulele.

### Absolute pitches

- Standard ukulele `[67,60,64,69]` differs from Low G `[55,60,64,69]` despite identical note names.
- Selecting the nearest pitch is anchored to preset reference, including downward tritone ties, not to last edited pitch.
- Fretted open pitches in 0..127 plus frets up to 24 are evaluated using a sufficiently wide signed integer, not clamped to 127.
- `[60,60,60]` is one note; `[84,60,72,60]` is an octave result.
- Lowest sounding pitch determines bass, independent of physical string order.

### UI state

- Clear chords preserves analyzer notes; clear notes preserves chords/highlight.
- Tuning sheet cancel/system Back/backdrop discards draft; reopening copies committed state.
- Same-instrument action is a no-op; fretted-to-fretted keeps only in-range string selections; piano boundary clears selection.
- Visualization surface is not interactive analysis; Analyzer selections are independent of saved chord memberships.
- Partial feature phases use honest disabled controls/labels; never substitute guitar state for unimplemented piano state.
- Results for old chord revisions cannot replace current suggestions. Test queued/out-of-order results, not just immediate fake responses.

### Wire format

- `#` percent encoding, `6/9` suffix slash, `Low G` spaces and duplicate chords all survive import/export.
- `highlight` is an identity label, never an index in public URL.
- Invalid authoritative `pitches` resets to Standard, not conflicting legacy `tuning`.
- Invalid known fields use baseline field-local defaults; unsupported URI origin/path/scheme and oversized envelopes are rejected before state mutation.
- Piano ignores tuning/marked; fretted ignores keys. Signed complete integer tokens accepted as baseline allows, trailing junk/whitespace not silently normalized.
- Existing URL→core decode→core encode→existing web decode produces equivalent canonical state. Query order need not match.
- App origin allowlist never accepts arbitrary lookalike suffix hosts, credentials in URL, javascript/file schemes, or executable import payloads.

## Device interaction acceptance

- All instrument controls have practical touch targets; if dense fret cells cannot fit, use horizontal viewport/scrolling rather than shrinking below usable size.
- Tapping black keys never selects underlying whites. Instrument layout coordinate conversion accounts for density, scroll and padding.
- A drag that turns into a scroll does not commit a tap. No accidental glissando/multi-touch feature is introduced.
- TalkBack announces selected states, instrument context and piano octave; selected/missing/overlap information is not communicated solely by color.
- Large font settings, portrait/landscape, system bars/cutouts, keyboard, bottom sheets, Android Back and activity recreation do not clip required actions or lose committed state.
- Phone test uses exact downloaded signed candidate APK. Screenshots alone are not evidence of interaction correctness.

## Proposed performance budgets, to calibrate in P1

These are acceptance targets, NOT measured results: no synchronous engine calls on the main thread; ordinary selection should visibly respond without perceptible lag; instrument scrolling should avoid persistent frame jank. P1 records release-build cold-start time, APK download/installed size, warm FFI round-trip, worst representative analyzer/key-suggestion duration and memory. P5 repeats worst-case catalog workloads and P7 checks regressions.

Do not invent a hard millisecond guarantee before the device baseline. If latency prevents fluid input, profile domain work, transfer sizes and recomputation before caching. Every cache must have a semantic key and invalidation tests. Do not sacrifice ranked-result correctness for speed without approval.

## Security and persistence

- Boundary/property tests for random malformed queries, large values, invalid enum variants, integer overflow, unsupported state schema and corrupt local payloads.
- Proposed input caps must be enumerated and approved in P0; no hidden truncation of valid chord occurrences.
- Atomic saved-session replacement; crash before commit preserves previous valid snapshot.
- Explicit import takes precedence over background restore, including a cold launch; stale restore cannot overwrite a newly accepted link.
- No network needed after installation; no AI provider key or inference calls embedded in the mobile app. DeepSeek is a development tool only.
- Dependency license inventory, no unsafe deserialization of executable types, no production logging of full imported URLs by default.

## Final report template

```text
Phase / candidate:
Core commit + artifact version + SHA256:
Android commit + APK SHA256 + versionCode:
Signer fingerprint:
Tests actually run (commands, environment, exit codes):
Skipped/blocked tests and reason:
Phone model / Android API / ABI / OxygenOS:
Manual scenarios and evidence:
Known deviations and approved decision IDs:
User approval reference:
Next phase allowed: yes/no
```

An empty item is unresolved, not an implicit pass.
