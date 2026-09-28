# Native Android Design Implementation Plan

> **For Hermes:** Implement only after approval, using separate test-writer, implementer, and independent reviewer contexts task by task. This document is a design, not authorization to implement.

**Goal:** Deliver the existing Fretboard experience fully offline in a native Android application, retaining its musical behavior, recognizable visual identity, and old URL compatibility.

**Architecture:** Kotlin/Jetpack Compose renders typed Rust-derived state through an Android engine wrapper. Rust owns musical rules, canonical session transitions, URL codecs, and musically meaningful presentation decisions; Android owns layout, input, OS integration, durable storage, and execution scheduling.

**Tech Stack:** Kotlin, Compose, Android lifecycle/ViewModel, coroutines, DataStore, Gradle Kotlin DSL; a versioned UniFFI-backed Android AAR supplied by the separate Rust core repository.

---

## 1. Scope, evidence, and unresolved decisions

The Android repository will be `/workspace/repos/fretboard-android`; the Rust repository will be `/workspace/repos/fretboard-core`. Both are new repositories, not directories copied into the web application. The application ID and application namespace are **`dev.ironjanowar.fretboard`**. The two Gradle modules are **`:app`** (Android application) and **`:engine`** (Android library wrapper). Do not add a WebView, a Kotlin music engine, an iOS client, a Rustler/web migration, accounts, a session library, a store, audio, a tuner, or new musical gestures.

Evidence inspected in the web repository at `2daa8c665efa268942dda352691f39d78db42512`, branch `plan/native-core-android`:

| Source relative to `/workspace/repos/fretboard` | Contract recovered |
|---|---|
| `lib/fretboard_web/live/fretboard_live.ex` | Every control/event, two tabs, draft defaults, asynchronous suggestions, duplicate identity colors/highlight, modal grouping |
| `lib/fretboard_web/components/fretboard_svg.ex` | Open position and frets 1–24, reversed physical strings, marker colors, overlap/highlight rules |
| `lib/fretboard_web/components/piano_keyboard.ex` | C3–B5, 36 keys, black-key offsets/z-order, accessible names, static visualizer versus analyzer |
| `lib/fretboard_web/components/modals.ex` | Tuning/key/progression selectors, previews, Apply/Cancel and fresh-open defaults |
| `lib/fretboard/music/instrument.ex`, `pitch.ex`, `url_codec.ex`, `page_codec.ex` | All five stable instrument IDs, absolute pitches, fixed reference, field-level fallback, canonical encoding |
| `test/fretboard_web/live/duplicate_chords_live_test.exs` | Occurrences retained, root-and-quality identity rather than pitch-set identity |
| `test/fretboard_web/live/pitch_tuning_test.exs`, `pitch_tuning_lifecycle_test.exs` | Low G versus high-G, Baritone, fixed Drop D reference, cancel/reopen and exact tuning retention |
| `test/fretboard_web/live/piano_analyzer_test.exs`, `piano_lifecycle_test.exs` | Individual pitches, inversions, octave handling, selection isolation and cross-kind reset |
| `test/fretboard_web/live/multi_key_full_membership_test.exs` | Every group's complete membership, not exclusive greedy coverage |
| `test/fretboard/music/page_codec_boundary_test.exs` | Bad positions rejected individually without losing valid siblings |

This inspection is not an executed native parity claim. Phase 0 must capture official tool compatibility, web fixtures, screenshots and open discrepancies. Other plan documents own Rust contract details; the names `EngineSession`, `Action`, and `evaluate` here are conceptual protocol terms, **not invented generated Kotlin symbols**. Freeze the binding names and types together in the P0 contract handshake.

Known blockers and proposals:

- **The production web host is unknown.** A repository URL is not the share host. Discover and confirm the canonical HTTPS origin and supported path in P0; never insert a guessed domain into a manifest or release. This blocks production URL-share origin configuration and verified App Links, not offline development, paste import, or `ACTION_SEND` text import. Any unresolved host at P6 is a release-gate blocker for full sharing parity.
- Proposed minSdk is 26, subject to P0 validation with chosen dependencies and core artifact. Select the latest stable supported target/compile SDK after checking current official Android/AGP/Kotlin/Compose documentation. No SDK or dependency versions are established by this plan.
- Device: OnePlus 13R, OxygenOS 16.0.10. Obtain `adb shell getprop ro.build.version.sdk`, `ro.product.cpu.abilist`, and build fingerprint; never infer API from the OEM version.
- Persistent distribution signer from the first installable phase APK; package never changes; each delivered APK increases `versionCode`. Provision secrets outside Git. Debug instrumentation packages are separate test artifacts, not replacements for the user's installed signed application.

## 2. Ownership and engine boundary

### Rust owns

Catalog order and English musical labels; chord qualities/formulas/interval associations; scale and progression catalogs and previews; standard and preset pitches; note editing against a fixed reference; exact identity/duplicate semantics; chord-color **slots** and semantic marker classifications; analyzer ordering, bass/inversion and missing-note associations; key ranking, relative grouping and complete multi-key membership; canonical reducer transitions; URL import/normalization/encoding; session schema migration and validation. These include rules currently located in the web LiveView rather than the Elixir music context. Their present location does not justify duplicating them in Kotlin.

Rust returns sufficient display data: ordered instrument metadata, string/key labels, canonical committed state, ordered occurrences, exact identities, semantic palette indices, note membership, typed analyzer variants, typed suggestion groups, applicability flags and preview content. Keyboard metadata includes key kind/order and accessible note-with-octave labels; Compose must not derive music from `pitch % 12`. Core does not know pixels, Android contexts, Compose colors, Intents, DataStore, or lifecycle.

### Android owns

`:engine` defines a small `NativeBindings` interface and the production `UniFfiBindings` adapter, exposing a platform-neutral `EngineGateway` to the app. Only the adapter imports generated AAR symbols. App-facing DTOs are transport/view projections, not independently validated or calculated musical models. `:app` never references generated symbols. Dependency direction is app → engine wrapper → pinned AAR.

JVM tests use a deterministic `FakeNativeBindings` with scripted responses, calls, delays, errors and late completions; a ViewModel test must not attempt to load an Android `.so` on the host JVM. Device/emulator instrumentation tests instantiate `UniFfiBindings` and execute the actual packaged Rust library. Both paths test the same `EngineGateway`; fake-only green is not a native acceptance gate.

### Artifact preparation

Core owns `crates/domain` (`fretboard-core`), `crates/mobile-ffi` (`fretboard-mobile-ffi`) and `crates/bindgen` (the `uniffi-bindgen` CLI). Android copies none of those sources, runs no Rust source build, and authors no generated binding stubs. Before Gradle resolves dependencies, `python3 scripts/prepare_core.py` downloads one pinned core GitHub Release AAR to ignored `vendor/fretboard-mobile.aar`, verifies SHA-256 against committed `core-release.lock.json`, checks release metadata/contract version/required ABIs, and atomically promotes the verified file. No `latest`, mutable branch, `mavenLocal`, sibling checkout dependency, or checksum learned from the downloaded binary itself.

The lock records repository, immutable release version/tag, asset filename, exact HTTPS release URL, SHA-256, protocol/schema version, generated-binding version, runtime dependency coordinates and required ABI set. Values must come from a real core release in P0/P1. The AAR contains generated Kotlin bytecode and the matching native libraries; generated source stays in core's build outputs. The wrapper explicitly declares the binding runtime dependency needed by the AAR (for example JNA if the selected UniFFI backend requires it); an AAR alone does not supply Maven transitive metadata. Verify actual backend packaging rather than assuming JNI filenames. Corrupt cached files and missing ABI/contract mismatch fail closed before compiling; offline builds work with an already verified cache. APK use itself never needs network access.

## 3. Native layout and visual identity

One Activity and one main screen; no navigation graph for fictional pages. Use a dark Compose theme with the web chord palette, brown fretboard `#3E2723`, pale strings/nut, neutral overlap `#9E9E9E`, and clear English labels. Do not claim unmatched screenshot-derived background/font values: P0 captures actual rendered web colors, spacing and typography before freezing Android tokens. Use native scalable text and system insets, not a desktop pixel layout squeezed onto a phone.

Portrait hierarchy:

1. Compact title/application bar: “Fretboard”, current instrument selector, Share and More actions. More contains “Import URL”; secondary actions can wrap, never become inaccessible.
2. Two equally prominent segmented tabs: **Visualizer** and **Analyzer**. Tuning action for the four fretted instruments in either tab; no disabled ghost tuning control on piano.
3. Visualizer only: Key, Progressions, root picker, grouped quality picker, Add. At narrow widths, root/quality/Add occupy their own wrapping row. Pickers preserve catalog order and group headings and scroll when necessary.
4. Horizontally scrollable fretboard or piano surface. Never scale touchable positions below the geometry below merely to fit all notes. Surface scrolling is independent of the screen's vertical content scroll.
5. Visualizer: Clear chords (only when nonempty), ordered wrapping/scrolling chord cards, compatible-key results and multi-key results. Card contents include chord label plus note–interval pairs, a highlight target and a separate Remove target.
6. Analyzer: Clear notes (only when selected), instruction/single note/interval/results. Visualizer chords and highlight are retained but hidden; they never color analyzer selections.
7. Modal bottom sheets for Tuning, Key, Progressions and Import. Expanded sheets are vertically scrollable, keep Apply/Cancel reachable with IME/font scaling, and have a labelled dismiss control. On a wide window, use a constrained centered dialog or sheet rather than stretching fields to the full width.

Landscape/large windows may place controls and results beside the musical surface when both panes meet minimum widths. State and control order do not change. Support rotation and multi-window without resetting the session; avoid mandatory orientation locks.

Visualizer surfaces are informative, not selection controls. Analyzer surfaces expose one explicit toggle per position. Android copy changes “Click” to “Tap”; musical labels/identifiers remain compatible. “Ukulele” is the visible label and **`ukelele`** remains the wire ID.

## 4. Canonical state and transition table

Keep three layers separate:

- **Committed engine session:** instrument, tuning pitches/reference or absent for piano, ordered chord occurrences, highlighted identity/index projection, tab and kind-specific selection. Canonical snapshot/schema comes from Rust.
- **Engine draft/derived state:** tuning draft with immutable preset reference; key/progression previews; analysis and suggestions. Draft musical updates run through Rust. Drafts never enter last-session persistence or shared URLs until Apply.
- **Android presentation state:** sheet visibility, scroll offsets, focus, expanded additional modes, busy/error banners and generation tokens. A rotation may retain the currently open draft through its ViewModel; a real process restart restores committed state only and closes drafts. Android Back dismisses a sheet first, otherwise delegates to system; it does not invent a browser history stack.

Every accepted committed action receives a new revision from the serialized reducer, renders its canonical state and schedules persistence. Invalid actions return a typed no-op/error without partially changing the state. An unchanged action must not trigger a save or unnecessary key calculation. Unless stated below, preserve every other committed field.

| Input | Transition and preservation |
|---|---|
| Fresh start without saved data/import | Guitar, Standard pitches/reference, Visualizer, no chords/highlight/selection; Add draft C major |
| Choose same tab/instrument | No-op; preserve tuning, selections, drafts as applicable; no spurious revision |
| Choose different tab | Preserve instrument, tuning, chord list/highlight and analyzer selection; show appropriate surface; recompute analysis on entering Analyzer |
| Change fretted instrument | Close tuning draft; reset target instrument's Standard pitches/reference; retain only marked positions valid for target string count/frets; preserve ordered chords and current tab; clear highlight |
| Fretted ↔ piano | Close tuning draft; clear selection entirely (never translate string positions to pitches); set target Standard or no tuning; retain chords/tab; clear highlight |
| Change Add root/quality | Draft-only update; no session write or suggestions refresh |
| Add | Append iff exact root + quality is absent; manual exact duplicate is a no-op; same pitch set with another identity is allowed; keep existing highlight |
| Import/progression repeated chords | Keep every occurrence, order and duplicates; no global de-duplication |
| Tap chord card | Highlight every copy with the same exact identity; tap any highlighted copy to clear; different identity changes highlight |
| Remove occurrence | Remove only tapped index/occurrence, not identity group; retain highlighted identity while any copy remains and select its first remaining occurrence; otherwise clear |
| Clear chords | Empty list and highlight; preserve tuning/tab/marked positions or keys |
| Open Tuning | Snapshot current committed pitches and fixed reference into a fresh draft; piano request is a no-op |
| Select tuning preset | Replace draft pitches AND reference with the selected preset; invalid/“Custom” selection does not invent a preset |
| Change string note | Validate physical index and catalog note via Rust; resolve nearest pitch against that string's fixed reference preset, not its last edit; a six-semitone tie resolves downward; update draft only |
| Apply tuning | Atomically commit draft pitches/reference, close sheet; preserve marked positions and chord state; recalculate derived notes/bass/intervals even when visible note names are unchanged |
| Cancel/dismiss tuning | Discard both edited pitches and preset reference; reopen from committed values |
| Open Key | Always fresh C / major / triad; show Rust preview |
| Update Key | Tonic/scale/triad-or-seventh draft and preview only |
| Apply Key | Replace entire chord list by current preview, clear highlight, close sheet; preserve tuning/tab/selection |
| Open Progressions | Always fresh C / `pop_i_v_vi_iv`; show grouped catalog and Rust preview |
| Update Progression | ID/tonic draft and preview only |
| Apply Progression | Replace entire list, including repeated occurrences, clear highlight and close; preserve tuning/tab/selection |
| Cancel/dismiss Key/Progressions | No committed changes; next open resets to defaults, not abandoned draft |
| Apply suggested key | Rust infers triad/seventh mode from current list and replaces chords with suggested key's diatonic chords; clear highlight; preserve other state |
| Expand additional modes | Presentation-only toggle shared across relative groups as on web; no snapshot write; collapse on next committed page-equivalent state change |
| Tap fretted analyzer cell | One selected fret per physical string: same position toggles off; different fret replaces that string; preserve other strings |
| Tap piano analyzer key | Toggle only exact absolute pitch; same pitch class in another octave is independent; out-of-range/malformed/wrong-surface actions cannot mutate state |
| Clear notes | Empty active kind's selection only; retain chords and highlight |
| Accepted URL import | One atomic canonical session replacement; dismiss obsolete sheets, invalidate old calculations and persist the accepted result |
| Rejected full import or reducer error | Keep last valid state AND persisted snapshot; expose actionable English error; never silently reset to defaults |
| Share | Encode committed state through Rust; launch Android text chooser; no mutation or draft leak |

On any committed replacement while a sheet is open, invalidate its source revision. Do not apply a stale draft to a different instrument or imported session. Dismiss it with an explanation if its basis is obsolete. Draft Apply is serialized with committed actions; Cancel invalidates its draft token before a late preview can render.

### Fixed-reference examples to pin

- Guitar Drop D selects open pitches `[38,45,50,55,59,64]` and reference `Drop D`. Editing first string to E and then G# resolves to **32**, not 44. Applying and reopening retains that reference. At fret 12 versus open A, the analyzer reports `Interval: G#-A (Minor 2nd)`.
- Ukulele Standard `[67,60,64,69]` and Low G `[55,60,64,69]` have identical displayed note names but different bass/inversion results. Do not detect presets by note names. All open Standard strings have bass C; Low G has bass G.
- Baritone `[50,55,59,64]` is an absolute-pitch preset, not notes re-resolved nearest to Standard. “Custom” is derived from exact pitches, not a stored reference name.

## 5. Identity, palette and analysis presentation

Palette slots, cycling in this exact order: `#4FC3F7`, `#FF8A65`, `#81C784`, `#BA68C8`, `#FFD54F`, `#4DB6AC`, `#F06292`, `#7986CB`. Rust assigns active colors by **unique identity in first-appearance order**, then supplies each occurrence's slot. Kotlin maps slots to theme colors only.

`Cmaj,Cmaj,Amin` renders cyan, cyan, orange. `C6,Amin7,C6` is three occurrences of two identities even though those identities have equal pitch sets. An unhighlighted note belonging only to repeated copies remains its identity color; gray overlap means more than one different chord identity. With a highlighted identity, all its notes use its color; other active notes become gray. Empty positions have no visualizer marker. Removal can reassign palette slots as first-appearance ordering changes; do not introduce permanent color IDs. Key/progression previews use ordered slot coloring as the web does; multi-key membership color projection must be pinned in core fixtures rather than independently “fixed” in Kotlin (the web currently indexes the base palette by first occurrence there).

Analyzer selected markers are cyan independently of saved visualizer chords. Rust supplies typed Empty, Single, Interval, and ChordInterpretations results, including no-match. Cards retain order and show slash label, `exact`/`incomplete`/`partial`, notes, intervals, inversion if present and Bass. Missing-note indications require both visible style and spoken “missing”; do not rely solely on color. Do not zip independently ordered note and interval arrays in Android: request typed note–interval–missing associations from core.

**Parity discrepancy to resolve in P0:** the current web card helper zips notes/intervals, which can mislabel missing extension tones. The relative grouping helper also filters modal sets not containing all seven modes. Record fixtures and agree with core whether such outputs are reachable and whether to preserve or correct them; do not silently ship an Android-only musical correction. Confirm every catalog quality/scale/progression, not only major/minor examples.

### Compatible keys / relative groups

Compute only when the ordered active chord input changes, with fewer than two chords producing no section. The Rust result reproduces the current ranking and grouped display:

- Perfect top-score results: collapse only complete seven-mode equal-pitch-set families (`major`, `minor`, `dorian`, `phrygian`, `lydian`, `mixolydian`, `locrian`); major then relative minor prominent, remaining five under “5 additional modes”. Non-modal perfect results remain individual; lower-ranked results remain individual in existing order.
- When the maximum score is not perfect, show only the first three suggestions individually. Kotlin does not re-score, group, truncate or sort.
- When no single-key suggestions exist and there are at least three chords, ask Rust for multi-key coverage. Display full membership in every group, overlapping membership allowed; unmatched chords have their own labelled area. For `Dmin,Gmaj,Emaj,Fmaj`, the C Major group lists Dmin/Gmaj/Fmaj and A Harmonic Minor lists Dmin/Emaj/Fmaj.
- Show Calculating/Analyzing while current requests are pending; failure is distinct from empty. Offer Retry for transient engine/evaluation failures without changing musical state.

## 6. Touch geometry, hit testing and accessibility

Use explicit geometry objects shared by drawing, pointer hit tests and semantic bounds; pixel-to-dp conversion occurs once. Never attach giant overlapping invisible click targets or a separate coordinate formula to accessibility.

**Fretted surface:** horizontal scroll, 25 columns including open position and frets 1–24; each cell at least 48dp wide × 48dp high in Analyzer, with a distinct 48dp open column to avoid the web's tightly adjacent nut/fret-1 targets. Strings are reversed visually: physical index 0 (e.g. guitar low E) is bottom, highest physical index top; tuning editor remains physical order, String N through String 1. This is not pitch sorting (high-G ukulele is re-entrant). Mark fret numbers and markers 3/5/7/9/12/15/17/19/21/24; 12 and 24 are double markers, placed within the actual string area. Nut/wood/strings preserve identity, not web pixel constants. Edge cells are not clipped by scroll padding. Selection targets are whole cells, not small note circles. Half-open rectangle boundaries give deterministic ownership; outside bounds does nothing. No note action on scroll drag, cancellation, long press or second pointer.

**Piano:** fixed pitches 48–83, 21 white and 15 black keys. Preserve physical order and black-on-white drawing/hit priority. Source proportions are white 36×160, black 20×100, black left offsets relative to lower natural white key C# .62, D# .81, F# .58, G# .71, A# .86. Native proposal: uniformly enlarge those proportions enough that black width is at least 48dp and scroll horizontally instead of fit-to-width. Freeze the comfortable density at P4 manual gate; do not distort musical black-key offsets to fake touch width. Core supplies key kind and lower-white anchor metadata, Android supplies geometric scale/offset rules. White semantic hit regions exclude black overlays; drawing and hit tests agree. At black-key edges the frontmost black region wins; at the white lower part the white key wins. Do not let Compose's automatic touch expansion route an adjacent white key over a black key. All keys stay independently reachable via TalkBack even offscreen (bring into view on focus).

Pointer contract for both: one primary-pointer down/up within touch slop activates exactly one target, on up; scroll exceeding slop cancels the pending tap, pointer cancellation cancels it, and additional pointers cause no multi-note gesture. Do not implement glissando, drag-to-select, pinch zoom, sound, repeat-on-hold or double-tap behavior. Native horizontal/vertical scroll and accessibility actions are navigation, not new musical gestures. Keyboard Enter/Space and TalkBack activate the same action exactly once; unrelated keys are ignored.

Compose semantics: analyzer cells/keys expose role Button, selected state, unique label and onClick; fret labels include instrument string number, fret/open and core-supplied note, piano labels include octave (`C#4`). Visualizers expose a non-actionable summary plus readable note membership, not toggles. Card highlight and Remove are separate focusable nodes (Remove never bubbles into highlight). Sheet titles/headings, dropdown labels, current selection, errors and loading indicators are announced; return focus to the opener on dismissal. Touch targets at least 48dp, text scales through large accessibility settings without hiding Apply/Cancel, contrast checked against actual palette, and state never conveyed solely by color. Stable test tags encode opaque occurrence keys or current string/fret/pitch, not translated labels.

## 7. Execution, cancellation and lifecycle

Process all reducer actions through one session actor/serialized queue on a worker dispatcher. Rendering reads immutable `StateFlow`; no native work on the main thread. A revision and request token identify every evaluation. Use immutable evaluation snapshots or an independent native evaluation handle; do not concurrently mutate one FFI session handle from calculation jobs.

Separate revision from dependency keys: key suggestions depend on ordered chord identities/occurrences, analysis on instrument/exact tuning/selection/tab, previews on draft ID and version. Cancel superseded coroutines and native work if the agreed FFI supports cooperative cancellation. **Coroutine cancellation does not prove synchronous native work stopped.** A completion is accepted only if its session identity, dependency key, revision policy and generation token still match; otherwise drop it, including failures. Release handles in `finally`, await/drain in-flight access before closing a session, and never reuse a disposed handle. A late A result after B must not flash A or persist it. Tokens also cover import, process restoration and dismissed drafts.

Persistence saves only the current successful committed snapshot, serialized and atomically replaced through DataStore on IO. Saves are ordered; older completion cannot overwrite newer state. Flush each accepted revision through the store pipeline instead of relying only on Activity `onStop`. Saving is observable; errors warn that changes are not yet saved and retain the previous disk record. Do not represent an unwritten snapshot as durable. One snapshot is not a session library; no history database is needed.

Boot precedence: newest explicit incoming import > last valid saved snapshot > Rust defaults. Load last-known-good baseline first or stage it while import validates, disable session interaction during unresolved boot arbitration, and never let a slow restore overwrite a newer intent. A rejected cold-start import falls back to the restored session (or defaults if none), with error; rejected warm import leaves the current session untouched. Rotation keeps the ViewModel/session; process death reconstructs from committed snapshot. Snapshot schema migrations happen in Rust. Corrupt/unsupported saved data yields a visible recoverable warning and defaults without overwriting the original unreadable record until the user makes a valid change; avoid crash loops.

## 8. URL import, sharing and trust boundary

Support paste into Import URL and `ACTION_SEND` with `text/plain`/`EXTRA_TEXT` independently of verified App Links. Do not scrape clipboard on launch. A single explicit candidate URL or relative `/?...` accepted by the core envelope contract can be imported; ambiguous multiple URLs require choosing/pasting one, not guessing. Never fetch imported content or execute its scheme. Both cold Activity launch and `onNewIntent` feed one coordinator; saved delivery tokens prevent accidental replay on recreation without preventing a later deliberate re-import of the same text.

Envelope validation is distinct from existing field compatibility:

- Reject full envelopes for unsupported scheme, invalid structural encoding, disallowed configured path/origin under the chosen route policy, oversize input/resource limits, wrong payload kind or unsupported snapshot/protocol version. Exact limits and repeated-query-key handling must be frozen with core/Phoenix fixtures in P0, not improvised in the app. Reject leaves the last canonical state and disk snapshot unchanged; error is user-visible and does not log the full URL.
- A successfully parsed legacy query follows the existing codec's tolerant field rules. Unknown instrument → guitar; bad/missing tab → visualizer; invalid chord tokens skipped while valid ordered duplicates survive; invalid highlight → none. Non-string values use field defaults, not rejection of valid sibling fields.
- Present invalid `pitches` resets both pitches and reference to target Standard and never falls back to conflicting `tuning`; valid pitches with bad reference retain pitches and use Standard reference. No `pitches` means legacy notes resolve near Standard and ignore `reference`, even when note names match another preset.
- Bad/out-of-range marked positions are filtered individually; duplicate string entries follow current map last-entry semantics before final bounds filtering. Piano keys filter to 48–83, deduplicate and sort; piano ignores tuning/marked fields, fretted kinds ignore `keys`. Unknown fields do not become application settings.
- Canonical encoding omits default fields, retains `ukelele`, exact custom pitches/fixed reference, duplicate chord occurrences and identity highlight, and uses proper query percent-encoding (especially `#`, plus and spaces). Never hand-concatenate fields in Kotlin.

Rust supplies canonical query/path; Android appends the confirmed, validated HTTPS base origin from non-secret build configuration and sends `ACTION_SEND` with `Intent.createChooser`. Copy link uses the same canonical output. Do not share an Android-only snapshot format when an old web URL is requested. Test every emitted URL against the existing web decoder, including empty/default URL.

Verified `ACTION_VIEW` App Links are optional after confirmed domain ownership, exact manifest host/path, website `assetlinks.json` and the persistent signing certificate fingerprint are available. Website changes are an external owner prerequisite, **not web migration implementation** in this plan. Never use wildcard-host filters or claim auto-open works without verification. Without association, paste/import and incoming shared text still work; clicking a link can remain in the browser. Production host absence must be reported explicitly rather than shipping an invented share URL.

## 9. Design acceptance

`05-android-phases.md` is the exact Android file/task/test inventory. Each phase requires RED evidence, green tests including relevant real bindings, independent review, a signed installable APK, and explicit user approval on the OnePlus before starting the next phase. Temporary feature placeholders are labelled English and tested; final P7 permits none. Native implementation may not quietly narrow the catalog or collapse octave-distinct state. Any untested discrepancy is a blocker, not a claim of parity.
