# Core Implementation Phases and File Ownership

**Planning only.** Every future file below belongs to **`Ironjanowar/fretboard-core`**, expected checkout `/workspace/repos/fretboard-core` after verifying its remote. None belongs in the web application. No commands below are claimed to have run. Expected outcomes are future acceptance assertions, not fabricated execution output. Read `02-core-contract.md`, `06-delivery.md`, and `07-validation.md` first.

Discrepancy IDs in `02-core-contract.md` are local: write `Contract.D01` etc. Delivery task IDs in `06-delivery.md` are separately `Delivery.D00` etc. Unresolved discrepancies require user approval before the affected feature is accepted. P0 has a contract/tooling gate, **no APK**. P1 is the first real installable APK. Do not complete the entire core before attempting Android integration.

## 1. Workspace and ownership

Exactly three Cargo members:

- `crates/domain`: package **fretboard-core**, library **fretboard_core**, portable `rlib`. Musical rules, catalogs, normalization, state/action/evaluation, URL and snapshot schemas. No UniFFI, Android, JNI, network, filesystem, Phoenix or rendering dependency.
- `crates/mobile-ffi`: package **fretboard-mobile-ffi**, library **fretboard_mobile_ffi**, `cdylib` and `rlib` (host adapter tests). Depends on domain and pinned UniFFI runtime. Use proc-macro metadata/scaffolding; no UDL, handwritten JNI or parallel manual Kotlin bindings.
- `crates/bindgen`: package **fretboard-bindgen**, binary **uniffi-bindgen**, delegates to the matching pinned UniFFI CLI. Not another domain crate.

One designated integration owner controls shared Cargo manifests, `lib.rs` exports, adapter DTO/API files, scripts and release wiring. Test-writer owns a task's tests first; implementer receives its source allowlist only after verified RED; independent reviewer reports findings and requests an explicit correction handoff. Never give concurrent write ownership of one file to two agents. Keep parsing, validation, transitions and derivation in small separate functions. No monolithic reducer/serializer with all musical algorithms embedded.

### Complete authored-file manifest

All paths relative to **fretboard-core/**. The following is the complete planned source inventory, not files created by this planning exercise. Tasks may modify their listed existing files. Integration edits are serialized through C00's owner.

| Owner | Exact authored paths |
|---|---|
| C00 integration | `Cargo.toml`; `rust-toolchain.toml`; `.gitignore`; `README.md`; `AGENTS.md`; `docs/development.md`; `docs/toolchains.md`; `docs/contracts.md`; `docs/decisions.md`; `docs/validation.md`; `crates/domain/Cargo.toml`; `crates/domain/src/lib.rs`; `crates/mobile-ffi/Cargo.toml`; `crates/mobile-ffi/src/lib.rs`; `crates/bindgen/Cargo.toml`; `crates/bindgen/src/main.rs` |
| C01 oracle | `tools/oracle/README.md`; `tools/oracle/export.exs`; `tools/oracle/catalog.exs`; `tools/oracle/cases.exs`; `tools/oracle/normalize.exs`; `tools/oracle/page_events_test.exs`; `tools/oracle/check_export.py`; `tools/oracle/test_check_export.py`; `scripts/export-oracle.sh`; `fixtures/oracle/README.md` |
| C02 state | `crates/domain/src/types.rs`; `crates/domain/src/error.rs`; `crates/domain/src/state.rs`; `crates/domain/tests/state_contract.rs`; `crates/domain/tests/common/mod.rs`; `fixtures/contract/snapshot-v1.json`; `fixtures/contract/api-v1.json` |
| C03 primitives | `crates/domain/src/note.rs`; `crates/domain/src/interval.rs`; `crates/domain/tests/primitives.rs` |
| C04 initial FFI | `crates/mobile-ffi/src/api.rs`; `crates/mobile-ffi/src/dto.rs`; `crates/mobile-ffi/src/convert.rs`; `crates/mobile-ffi/uniffi.toml`; `crates/mobile-ffi/tests/contract.rs` |
| C05 artifact (same owner as Delivery.D01) | `android/settings.gradle.kts`; `android/build.gradle.kts`; `android/gradle.properties`; `android/gradle/libs.versions.toml`; `android/engine/build.gradle.kts`; `android/engine/src/main/AndroidManifest.xml`; `android/engine/consumer-rules.pro`; `scripts/build-android.sh`; `scripts/package-aar.sh`; `scripts/check-aar.py`; `scripts/tests/test_check_aar.py`; `.github/workflows/ci.yml`; `.github/workflows/release-android.yml`; `docs/android-artifact.md` |
| C06 chords | `crates/domain/src/chord.rs`; `crates/domain/src/chord_catalog.rs`; `crates/domain/tests/chord_catalog.rs` |
| C07 instruments | `crates/domain/src/instrument.rs`; `crates/domain/src/instrument_catalog.rs`; `crates/domain/tests/instrument_catalog.rs` |
| C08 early map codec | `crates/domain/src/codec/mod.rs`; `crates/domain/src/codec/params.rs`; `crates/domain/src/codec/chords.rs`; `crates/domain/src/codec/tuning.rs`; `crates/domain/src/codec/selection.rs`; `crates/domain/tests/page_params.rs` |
| C09 identity | `crates/domain/src/reducer.rs`; `crates/domain/tests/reducer_identity.rs` |
| C10 visualization | `crates/domain/src/evaluate.rs`; `crates/domain/src/membership.rs`; `crates/domain/src/keyboard.rs`; `crates/domain/tests/visualizer.rs` |
| C11 tuning | `crates/domain/src/pitch.rs`; `crates/domain/tests/tuning.rs` |
| C12 identification | `crates/domain/src/identify.rs`; `crates/domain/src/chord_intervals.rs`; `crates/domain/tests/identify.rs` |
| C13 analysis | `crates/domain/src/analyzer.rs`; `crates/domain/tests/analyzer.rs`; `crates/domain/tests/reducer_fretted.rs` |
| C14 piano | `crates/domain/tests/reducer_piano.rs`; `crates/domain/tests/piano.rs`; serialized changes to `reducer.rs`, `keyboard.rs`, `evaluate.rs` |
| C15 scales | `crates/domain/src/scale.rs`; `crates/domain/src/scale_catalog.rs`; `crates/domain/tests/scales.rs` |
| C16 single keys | `crates/domain/src/keys.rs`; `crates/domain/src/key_groups.rs`; `crates/domain/tests/keys.rs`; `crates/domain/tests/key_groups.rs` |
| C17 multi-key | `crates/domain/src/multi_keys.rs`; `crates/domain/tests/multi_keys.rs` |
| C18 progressions | `crates/domain/src/progression.rs`; `crates/domain/src/progression_catalog.rs`; `crates/domain/tests/progressions.rs`; `crates/domain/tests/reducer_keys.rs` |
| C19 URL envelope | `crates/domain/src/codec/url.rs`; `crates/domain/tests/url_envelope.rs` |
| C20 snapshots | `crates/domain/src/snapshot.rs`; `crates/domain/tests/snapshot.rs`; `fixtures/contract/snapshot-future.json`; `fixtures/contract/snapshot-corrupt.txt` |
| C21 complete FFI | `crates/mobile-ffi/tests/parity.rs`; serialized changes to C04 adapter files |
| C22 audit | `crates/domain/tests/properties.rs`; `crates/domain/tests/golden_matrix.rs`; `scripts/verify-fixtures.py`; `scripts/tests/test_verify_fixtures.py`; `deny.toml`; `docs/licenses.md`; `docs/release-checklist.md` |

Catalog modules are authored from reviewed Elixir exports, not generated from Rust results at test runtime. No duplicated mobile catalog. P1 implements the minimal major-chord path in the eventual C06 modules through an explicit handoff; do not create a disposable second demo engine or Kotlin music constants.

### Generated and committed — not hand-authored binary content

- `Cargo.lock`, generated by Cargo and committed; subsequent builds use `--locked`.
- `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar`, `android/gradle/wrapper/gradle-wrapper.properties`, generated with the pinned Gradle distribution; commit the genuine JAR and distribution checksum.
- `android/gradle/verification-metadata.xml`, generated and reviewed with Gradle dependency verification.
- Elixir-generated frozen exports: `fixtures/oracle/manifest.json`, `fixtures/oracle/catalogs.json`, `fixtures/oracle/chords.jsonl`, `fixtures/oracle/identify.jsonl`, `fixtures/oracle/analyzer.jsonl`, `fixtures/oracle/tunings.jsonl`, `fixtures/oracle/surfaces.jsonl`, `fixtures/oracle/scales.jsonl`, `fixtures/oracle/keys.jsonl`, `fixtures/oracle/multi-keys.jsonl`, `fixtures/oracle/progressions.jsonl`, `fixtures/oracle/page-params.jsonl`, `fixtures/oracle/query-transport.jsonl`, `fixtures/oracle/page-events.jsonl`, `fixtures/oracle/key-groups.jsonl`.
- `fixtures/contract/approved-deviations.json`, **authored only with actual approval references**: decision ID, baseline case ID, old/native output, reason and approved phase. An empty approval list is valid; unresolved failures must not be converted into exclusions.

### Generated and ignored output roots

`target/`; `android/.gradle/`; `android/local.properties`; `android/build/`; `android/engine/build/`; `dist/`.

Required outputs within these roots:

- `android/engine/build/generated/uniffi/`: generated Kotlin package `dev.ironjanowar.fretboard.core` configured by `crates/mobile-ffi/uniffi.toml`, confirmed during the P0 handshake.
- `android/engine/build/generated/jniLibs/arm64-v8a/libfretboard_mobile_ffi.so` and `android/engine/build/generated/jniLibs/x86_64/libfretboard_mobile_ffi.so`.
- `android/engine/build/outputs/aar/engine-release.aar`, versioned as `dist/fretboard-engine-<version>.aar`.
- `dist/artifact-manifest.json`, `dist/SHA256SUMS`, `dist/licenses/`, `dist/oracle-run-a/`, `dist/oracle-run-b/`, `dist/roundtrip-inputs.jsonl`, `dist/roundtrip-results.jsonl`, `dist/validation/`.

The AAR contains generated Kotlin **bytecode**, consumer shrinker rules and both native libraries. Generated bindings remain build outputs, not handwritten source copied into Android. A bare local AAR does not bring Maven transitive dependencies: record exact UniFFI Kotlin runtime coordinates/version (commonly JNA); Android declares and locks these explicitly. Delivery.D01 owns the coordinated artifact pipeline; Android pins immutable version+SHA-256 into ignored `vendor/`, with no runtime download and no GitHub Packages dependency.

## 2. Source oracle procedure — actual pinned Elixir, no production changes

C01 must obtain real baseline output before rewriting music. Source pin: **`2daa8c665efa268942dda352691f39d78db42512`**. Current main, a dirty worktree or a later “fixed” commit is not equivalent provenance. This procedure is a future implementation task; it was not run while writing this plan.

### 2.1 Isolated source preparation

`scripts/export-oracle.sh` accepts `--source`, `--commit`, `--out`, optional `--roundtrip-inputs`; checks the commit against the approved pin; verifies the git object; exports `git archive` into a new temporary directory outside repositories. It never modifies original web `lib/`, `test/`, `mix.exs`, `mix.lock`, assets, branch or deployment. Dependencies/build outputs exist only in scratch. Bootstrap requires explicit toolchain approval. The web server is not started or switched.

Illustrative commands to implement with checked exits and cleanup:

```sh
CORE=/workspace/repos/fretboard-core
WEB=/workspace/repos/fretboard
BASE=2daa8c665efa268942dda352691f39d78db42512
ORACLE=$(mktemp -d /workspace/fretboard-oracle.XXXXXX)
git -C "$WEB" cat-file -e "$BASE^{commit}"
git -C "$WEB" archive "$BASE" | tar -x -C "$ORACLE"
# Activate approved oracle Elixir/OTP before entering scratch.
cd "$ORACLE"
MIX_ENV=test mix deps.get --check-locked
MIX_ENV=test mix compile --warnings-as-errors
ORACLE_SOURCE_SHA="$BASE" ORACLE_OUT="$CORE/dist/oracle-run-a" \
  MIX_ENV=test mix run --no-start "$CORE/tools/oracle/export.exs"
ORACLE_SOURCE_SHA="$BASE" ORACLE_OUT="$CORE/dist/oracle-run-a" \
  MIX_ENV=test mix test "$CORE/tools/oracle/page_events_test.exs" --seed 0
```

Verify `--check-locked` support with the pinned Mix version in C00. If unavailable, use resolution plus explicit before/after `mix.lock` byte comparison and fail on changes, not an unreviewed lock update. Normal `mix run` application boot has previously hung in this environment; use **`--no-start`** for domain export. LiveViewTest requires test application startup; bound execution with a timeout, diagnose failures, and never substitute synthetic results. Explicitly load scratch `test/support/conn_case.ex` if test compilation configuration does not load it. This offline export does not assume a running Tidewave service.

Before/after source guard: `git -C "$WEB" diff --exit-code -- lib test mix.exs mix.lock assets`; record existing changes without reverting them. Source authority is archived git objects. `export.exs` loads sibling exporter files via `Code.require_file` and calls actual `Fretboard.Music` APIs; internal `Chord.formula`, `Chord.interval_labels`, `Progression.all` may supply catalog metadata absent from facade. List internal calls in provenance. Do not translate algorithms into Python and call that the oracle.

### 2.2 Fixture schema and coverage

JSONL record: `case_id`, `operation`, typed `input`, normalized `output`, optional `baseline_source_function`. Manifest: source commit, source-file hashes, Elixir/OTP versions, exporter git SHA or explicit working-diff hash, fixture schema version, deterministic case seed, exact ordered filenames, byte SHA-256 and record counts. Execution time is separate run evidence, not nondeterministic golden payload.

`normalize.exs` converts atoms to stable strings, tagged tuples to named variants, map keys to canonical JSON ordering and numeric selection maps to ordered positions. **All meaningful lists retain original order**, especially interpretations/suggestions. Expected exceptions for deliberately invalid low-level calls are tagged separately from page-compatible valid cases.

| Output | Inputs and actual oracle calls |
|---|---|
| catalogs.json | All five instruments/presets; available/display qualities/scales/progressions; formulas/labels/metadata; assert unique counts47/15/59 |
| chords.jsonl | All12 sharp roots × all47 qualities; notes, full labels, interval labels, actual zipped pairs; flat aliases and all-quality chord-mode inference |
| identify.jsonl | Every twelve-bit pitch-class subset with at least3 classes, no bass; full-formula cases with every member bass; missing1/missing2 and foreign bass; compare **entire ordered result arrays** |
| analyzer.jsonl | Empty, repeated pitch, distinct octaves, two classes with extra octaves, pitch permutations, real fretted crossings and reentrant ukulele |
| tunings.jsonl | Every preset/string/chromatic edit; multi-edit fixed-reference sequences; exact detection; Standard/Low G/Baritone |
| surfaces.jsonl | Each instrument, representative presets and duplicate/highlight lists; every fret and all36 piano keys; actual facade output plus source presentation semantics |
| scales.jsonl | Every tonic × all15 scales × both chord modes, actual notes and diatonic chords |
| keys.jsonl | Empty/single raw API; exact, extended, duplicate, flat-root, no-compatible, lexical-order and tie cases |
| multi-keys.jsonl | Under3, all-singleton, duplicate indices, overlapping full membership, unmatched, max3 and tie cases; include Dmin,Gmaj,Emaj,Fmaj |
| progressions.jsonl | Every sharp tonic × all59 IDs and all stored example_key values including Bb; all metadata/order/repetitions |
| page-params.jsonl | Full02 field-local matrix: wrong types, invalid authoritative pitches, conflicting tuning/reference, signs, duplicate marked overwrite-before-filter, wrong-kind fields; decode/re-encode/re-decode |
| query-transport.jsonl | Actual Plug parsing and route GET for repeated scalar keys, nested/bracket values, percent escapes, plus, fragments, unknown keys; distinguish transport errors |
| page-events.jsonl | Actual LiveViewTest events and canonical patches/semantic DOM: duplicate/highlight/remove, instrument/tab/clear, tuning draft apply/cancel, key/progression application |
| key-groups.jsonl | Actual public `FretboardWeb.FretboardLive.group_key_suggestions/1`, complete-seven-mode, imperfect top3, incomplete modal groups and tied row order |

Measure fixture size before freezing. If exhaustive identification requires sharding, revise the explicit manifest with review; do not quietly reduce coverage. `cases.exs` defines inputs only; no hand-computed expected results. Event oracle uses `live`, `form`, `element`, `render_click`, patch observation and supported async-completion helper, never a new handwritten reducer. Capture stable labels/order/membership/selected/missing classes, not incidental HTML whitespace. Finalize the manifest only after domain and page-event exporters finish.

Formula ordering hazard: identification enumerates a47-entry Elixir map, not alphabetically sorted qualities or textual declaration order. Export complete ordered identification results first. If an explicit legacy rank table is needed, `catalog.exs` may parse the pinned source AST, extract only the literal `@formulas` map, and reconstruct/evaluate that allowlisted literal **in exporter memory**, never change source. Verify reconstructed enumeration against actual identification ties. No arbitrary source/URL evaluation. If equivalence cannot be demonstrated, Contract.D03 remains blocked; do not pretend textual order is the answer.

### 2.3 Repeatability and freeze

```sh
# Future commands from fretboard-core after exporter exists.
python3 -m unittest discover -s tools/oracle -p 'test_*.py'
./scripts/export-oracle.sh --source /workspace/repos/fretboard \
  --commit 2daa8c665efa268942dda352691f39d78db42512 --out dist/oracle-run-a
./scripts/export-oracle.sh --source /workspace/repos/fretboard \
  --commit 2daa8c665efa268942dda352691f39d78db42512 --out dist/oracle-run-b
python3 tools/oracle/check_export.py --left dist/oracle-run-a --right dist/oracle-run-b
```

Expected: unique case IDs, correct counts/hashes, no missing files, byte-identical normalized payloads. Runtime/source/exporter must match; timestamps do not excuse output ordering differences. Differences block freeze and go to user, not an extra result sort. Copy reviewed Elixir-generated files into `fixtures/oracle/` in a dedicated commit. Ordinary CI reads immutable fixtures without requiring Elixir; regeneration is an explicit source/runtime-pinned review task. Never regenerate expectations from Rust to obtain green tests.

## 3. Tests-first execution discipline

Each C task is a separate test-writer → verified RED → minimal implementation → GREEN → independent review cycle. Multiple named test targets within a task are separate small subcycles, not one large unreviewed port. An initial missing-API compile error may be recorded, but observe a behavior assertion failing before accepting algorithm implementation. Missing tool/dependency/path or corrupt fixture is **blocked setup**, not RED evidence.

After bootstrap, common verification from `/workspace/repos/fretboard-core`:

```sh
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
python3 -m unittest discover -s scripts/tests
```

For every named target below, first run is expected to fail on the absent named behavior; after implementation it must pass that behavior and all preceding tests. No numeric test result/timing is claimed here. Shared exports/adapters are changed serially by integration owner. Pending phase features must return a documented capability/unavailable error and render honest English placeholders in Android; never return a fake successful empty analysis.

### P0 — prerequisites, oracle and typed contract (no APK)

**C00 — freeze tooling and repo/protocol boundaries.** Dependencies: explicit implementation authorization and Delivery.D00. Own C00 files and generated-lock handoff. Inspect official Rust/UniFFI/Android compatibility documents and select exact versions, not guesses. Confirm three-member workspace, pure dependency direction, binding runtime/generator match, real repository visibility, origin discovery and proposed limits. Signing-key custody belongs to delivery/Android, not Rust secrets. Define API/schema/capabilities with Android before generated symbols are assumed. Commands: inventory from06, `cargo metadata --no-deps --format-version 1`, initial `cargo check --workspace --locked`. Expected: workspace smoke compiles after approved bootstrap; full music is not required.

**C01 — exporter and real fixture freeze.** Depends C00 and actual pinned Elixir/OTP. First test `check_export.py` against wrong source SHA, stale hash, missing file, duplicate case ID, dropped catalog item and changed list order. Tiny synthetic structural fixtures are checker unit tests, not oracle output. Run procedure2 twice and record provenance/discrepancies. Expected: reviewed real exports. If Elixir cannot run, stop; source-inspired JSON is not an acceptable replacement.

**C02 — typed state and schema handshake.** Depends C00/C01. First `cargo test -p fretboard-core --locked --test state_contract`: default guitar, ordered duplicate chords, kind-specific selection, exact tuning/reference, invalid pitch count/reference/highlight/range and immutable failure. Implement validated types/defaults. `snapshot-v1.json` is an explicitly authored schema example, not an Elixir-derived snapshot. Freeze exact field names and FFI-compatible enums/lists/nullable types. Sounding pitch is wide enough for open127+fret24. Expected: agreed contract, not yet proof of Kotlin generation.

**P0 gate:** user approves toolchain, provenance, protocol/resource policy and signing custody. List unresolved discrepancies with blocked task IDs. No APK or native performance claims.

### P1 — real minimal vertical slice

**C03 — major chord through actual Rust math.** Depends C02. `cargo test -p fretboard-core --locked --test primitives` first: note lookup/aliases, wraparound/downward transposition and major formula notes. Implement note/interval and minimal major chord support in eventual C06 modules via handoff. UI will request C major and a second root to demonstrate computation, not a stored response. Full catalog remains explicitly pending.

**C04 — first typed UniFFI binding.** Depends C03. `cargo test -p fretboard-mobile-ffi --locked --test contract`: defaults, enum conversion, list order, null highlight, invalid ranges and typed errors. Implement supported P1 API in final adapter files; no JSON execute blob. Example Linux-host generation command to verify against selected UniFFI release:

```sh
cargo build -p fretboard-mobile-ffi --locked
cargo run -p fretboard-bindgen --bin uniffi-bindgen --locked -- generate \
  --library target/debug/libfretboard_mobile_ffi.so --language kotlin \
  --config crates/mobile-ffi/uniffi.toml \
  --out-dir android/engine/build/generated/uniffi
```

Confirm exact CLI syntax from pinned tool help and real execution. Never invent generated Kotlin if library metadata fails. Host DTO tests are not native Android loading proof.

**C05 — single versioned AAR and early release pipeline.** Depends C04; same owner as Delivery.D01, not a competing implementation. First `python3 -m unittest discover -s scripts/tests -p 'test_check_aar.py'`: reject missing ABI/binding classes, metadata mismatch and unexpected libraries. Implement build/package/check scripts specified in `06-delivery.md`. Build aarch64-linux-android and x86_64-linux-android, generate from host-supported library metadata, compile Kotlin and assemble one AAR. Never execute Android `.so` on Linux host. Declare/clean Gradle generated inputs to avoid mixed versions. Inspect native16KB alignment and archive contents. Record runtime dependencies explicitly. Publish only reviewed immutable candidate; read back exact release and redownload/hash artifacts.

**P1 paired Android gate:** actual Compose → generated UniFFI → Rust calculation, emulator x86_64 and OnePlus13R arm64, airplane mode, real API/ABI evidence, persistent signing and installable APK. User approves that APK before P2. Kotlin mock/fake response cannot pass.

### P2 — all catalogs and instrument visualizers

**C06 — all47 chord qualities.** Depends P1 approval/C01. `cargo test -p fretboard-core --locked --test chord_catalog`: every ID/label/formula/group/root output and chord-mode inference. Implement catalog/chord helpers. Contextual chip labels require the `chord_intervals.rs` subpart of C12 early via explicit handoff. **Contract.D01 must be decided before P2 chip acceptance**, not postponed until analyzer. Keep observed raw arrays/zipped pairs and approved deviation fixtures distinct.

**C07 — instrument/preset catalog.** Depends P1; independent test-writing possible from C06. `cargo test -p fretboard-core --locked --test instrument_catalog`: all presets, physical order, fixed piano range/no tuning, unknown lookup and guitar legacy aliases. Implement catalog/accessors. Expected five stable IDs including `ukelele`, complete preset metadata, no tuning analysis required yet.

**C08 — foundational decoded-map codec early.** Depends C06/C07. `cargo test -p fretboard-core --locked --test page_params`: label vs ID suffix, duplicate preservation, first highlight, wrong-kind fields, authoritative invalid pitches, ignored reference without pitches, last-marked overwrite-before-filter, signed integers. Implement **all current page fields**, including piano selection and exact tuning, before UI interactions ship. Needed for parity fixtures and state normalization; postponing this to P6 creates a dependency cycle. Nearest-Standard helper comes from C11's smallest subpart via handoff, never a duplicate codec algorithm. Full URL transport/origin/percent parsing remains C19. Expected decoded-map roundtrip idempotence and correct omission rules.

**C09 — identity reducer.** Depends C08. `cargo test -p fretboard-core --locked --test reducer_identity`: Add duplicate no-op, C6 versus Amin7, imported repeats, remove one occurrence, highlighted surviving copy, clear chords preserving selection. Implement atomic reducer branches with checked indices and exact identity. Expected observable page-event equivalence without reparsing text every tap.

**C10 — pure visualizer evaluation.** Depends C09. `cargo test -p fretboard-core --locked --test visualizer`: all frets0–24/physical strings, all36 piano keys, ordered memberships, unique identity color slots, overlap/highlight semantic classes, key kind/anchor and note-octave labels. Implement evaluate/membership/keyboard. No pixels/Android colors. Integration owner adds typed adapter endpoints, tests and candidate version. Expected all instrument visualizers; unsupported analyzer visibly pending, never fabricated.

**P2 paired APK gate:** complete quality selector, all instrument visualizers, agreed chip interval behavior, duplicate highlight/remove, horizontal scroll/landscape/rotation. User approves before P3.

### P3 — absolute tuning and fretted analyzer

**C11 — fixed-reference pitch editing.** Depends P2/C07; nearest-reference subpart may already serve C08. `cargo test -p fretboard-core --locked --test tuning`: every preset/string/note, downward tritone tie, Drop D E→G# fixed anchor, Standard versus Low G, Baritone, exact preset detection and bad state rejection. Implement pure pitch/edit helpers and commit validation. Draft calculation never mutates committed state; Android tests Apply/Cancel/dismiss.

**C12 — full ordered identification.** Depends C06/C01 and decisions Contract.D01–D04. `cargo test -p fretboard-core --locked --test identify`. Split RED cycles: exact/ties; incomplete/missing priorities; actual partial predicate; bass/slash/inversion; agreed note/interval/missing associations. Reuse early contextual-label subpart. Implement identify with explicit legacy tie order, never HashMap iteration. Compare full ordered results, not sets or first match. Expected baseline equality or explicitly approved deviations only.

**C13 — absolute analyzer and fretted transitions.** Depends C11/C12. Separate runs `cargo test -p fretboard-core --locked --test analyzer` then `--test reducer_fretted`. Test empty/single/octave/two-class/chord variants, repeats/permutations, reentrant and crossing bass, one-fret-per-string toggles, clear-selection independence, tuning commits preserving marks, fretted→fretted filtering/reset. Implement analyzer then hand off reducer/evaluate integration. Expected analysis absent on Visualizer, independent of stored visualizer chords on Analyzer.

**P3 paired APK gate:** all four fretted analyzers; tuning Apply/Cancel/reopen; Low G versus Standard; fixed-reference edits; bass/inversions and missing-note policy. User approves before P4.

### P4 — piano analyzer and instrument boundaries

**C14 — exact-pitch selection and metadata closure.** Depends P3/C08/C10. Separate `cargo test -p fretboard-core --locked --test piano` and `--test reducer_piano`. Every36 keys, independent octaves, canonical selection, lowest pitch bass, inversions, wrong-kind/tab no-op, invalid range, same-instrument no-op, fretted↔piano reset, chords/tab retained and highlight cleared. Update reducer/evaluate/keyboard via their owner. Reuse one analyzer; no piano-specific chord algorithm. Map-level URL state already exists from C08.

**P4 paired APK gate:** all36 touch/accessibility/keyboard keys, black/white edge hit tests, scrolling cancellation, octaves and cross-kind clear/reset. Geometry is Android-owned; core supplies music/key metadata. User approves before P5.

### P5 — keys, grouping and all progressions

**C15 — fifteen scales and inferred diatonic chords.** Depends C06/C12. `cargo test -p fretboard-core --locked --test scales`: complete labels/formulas/groups, every tonic, both modes, prioritized classifier/exclusions/fallback on dense/non-heptatonic scales. Implement actual baseline inference, not generic stacked thirds. Expected exact oracle notes/chords.

**C16 — single-key scoring then grouped rows.** Depends C15, Contract.D05/D06 decisions. Separate `cargo test -p fretboard-core --locked --test keys` then `--test key_groups`. Containment, full triad-base map, duplicate scores, lexical tonic/scale ties, raw empty behavior versus page≥2 gate, flat-root asymmetry; then perfect seven-mode grouping, imperfect top3 and incomplete modal-group behavior. Implement keys/key_groups. Kotlin must not re-score/group/sort. Integration owner gates multi-key computation on no single keys and at least3 active chords.

**C17 — greedy multi-key with full displayed membership.** Depends C16. `cargo test -p fretboard-core --locked --test multi_keys`: full overlap, duplicate indices, max3/unmatched/all-singleton/tie behavior. Separate greedy exclusive assignment from full output membership. Dmin,Gmaj,Emaj,Fmaj must include Dmin/Gmaj/Fmaj in C Major and Dmin/Emaj/Fmaj in A Harmonic Minor, with overall order from oracle. Candidate score uses all covered occurrences, not only newly covered.

**C18 — all59 progressions and apply actions.** Depends C15/C16/C17 and Contract.D07 decision. Separate `cargo test -p fretboard-core --locked --test progressions` then `--test reducer_keys`. Compare complete metadata, all12 tonics plus stored example keys, accidentals and ordered repeats. Apply key uses chosen mode; suggestion uses only the explicit eight-quality mode list; progression retains duplicates; all replace chords/clear highlight/preserve tuning/tab/selection. Implement modules and serialized reducer/FFI previews. Expected no partial catalog hidden as completion.

**P5 paired APK gate:** all key/progression groups/previews, Apply/Cancel, repeated progressions, relative-mode expansion, full multi-key membership and rapid-changes stale-result protection. User approves before P6.

### P6 — full URL envelope, session schema and complete adapter

**C19 — URL import/share transport.** Depends C08/P5 and confirmed origin/resource-limit policy. Unknown public host blocks production sharing, not local fixture tests. `cargo test -p fretboard-core --locked --test url_envelope`: sharp/hash, suffix6/9, plus/spaces, actual Plug duplicate/nested fields, malformed escapes, unsupported schemes/path/origin, credentials/lookalike host, caps and no fetching. Implement transport separate from map normalization. Use validated supplied ShareBase; no guessed hostname. Compare canonical state, not query key order (07 allows different query ordering).

Hand off C22's `golden_matrix.rs` early to add ignored test `export_web_roundtrips`, writing actual Rust-encoded URLs/expected state to an environment-selected ignored file. Verify through unchanged Elixir:

```sh
ROUNDTRIP_OUT=dist/roundtrip-inputs.jsonl \
  cargo test -p fretboard-core --locked --test golden_matrix export_web_roundtrips -- --ignored
./scripts/export-oracle.sh --source /workspace/repos/fretboard \
  --commit 2daa8c665efa268942dda352691f39d78db42512 \
  --out dist/roundtrip-results.jsonl --roundtrip-inputs dist/roundtrip-inputs.jsonl
python3 tools/oracle/check_export.py --roundtrips dist/roundtrip-results.jsonl
```

C01 defines/test-drives `--roundtrip-inputs` mode: unlike full export's output-directory argument, `--out` here is a result file. Compare each actual web-decoded normalized page to supplied expected state; no production test/source edits.

**C20 — pure snapshot serialization.** Depends C02/C19. `cargo test -p fretboard-core --locked --test snapshot`: schema1 all kinds/tunings/highlights/duplicates, stable output, corrupt/truncated/wrong type/unknown ID, future schema rejected without destroying original bytes, explicit migration registry. No native v0 exists yet: do not invent old-schema migration success. If an earlier APK persisted an experimental schema, capture that real format and add migration before upgrade. Implement snapshot only; Android owns atomic DataStore writes/boot arbitration. No draft/modal/derived values persisted.

**C21 — complete typed mobile parity.** Depends C19/C20 and previous music tasks. `cargo test -p fretboard-mobile-ffi --locked --test parity`: every adapter operation against domain fixtures, checked types/errors/options, stable IDs, order and every action variant. Complete C04 DTO conversions/API/capabilities. No unsupported action may fake success. Regenerate Kotlin, compile, execute Android real-native integration and package fresh coordinated AAR. No giant JSON operation dispatcher or Kotlin music fallback.

**P6 paired APK gate:** confirmed-origin share, manual paste/incoming text, unchanged-web roundtrip, cold/warm precedence, force-stop/process recreation/rotation, same-signer update, invalid-import preservation. Runtime stays offline; paste/share does not require website App Links changes. User approves before P7.

### P7 — parity, artifact and release audit

**C22 — property/golden/security closure.** Depends P6. `properties.rs`: validated-state invariant through action sequences, transposition, pitch permutation invariance, codec canonical idempotence, snapshot roundtrip, malformed no-panic and caps without partial update. `golden_matrix.rs`: every frozen case consumed by its proper comparison, explicit low-level unsupported-surface exceptions only, approved deviations individually cited. Fixture checker validates hash/provenance/counts/IDs and approval ledger. Python checker tests first reject tampering/stale source/reordered lists. `deny.toml` configures reviewed dependency/license policy; record licenses.

Future commands: common checks plus `cargo test -p fretboard-core --locked --test properties`; `cargo test -p fretboard-core --locked --test golden_matrix`; `python3 scripts/verify-fixtures.py fixtures/oracle`; `cargo deny check`; Delivery.D01 AAR build/inspect/redownload. `cargo tree -p fretboard-core` must show no Android/UniFFI/JNI/Phoenix dependency leakage. Record actual performance/size/memory, not speculative guarantees. No Rustler, WASM or iOS implementation gets added as a portability check.

**P7 paired APK gate:** exact published/redownloaded AAR and signed APK; explicit locked runtime dependencies; both ABIs; 16KB evidence or disclosed limitation; full accessibility/offline/security/lifecycle review and same-key increasing-version update. User approves exact APK checksum. Unrun checks cannot be marked green.

## 4. Dependencies, early helper handoffs and stops

```text
C00 → C01 → C02 → C03 → C04 → C05 → [P1 APK approval]
 → C06 + C07 → C08 → C09 → C10 → [P2 APK approval]
 → C11 → C12 → C13 → [P3 APK approval]
 → C14 → [P4 APK approval]
 → C15 → C16 → C17 → C18 → [P5 APK approval]
 → C19 → C20 → C21 → [P6 APK approval]
 → C22 → [P7 APK approval]
```

Independent test-writing on disjoint files is permitted after prerequisite gates, not shared source modification. Explicit early subparts prevent later-phase dependency cycles:

- C03 uses minimal final chord modules from C06 via ownership handoff.
- C06 needs contextual labels from C12 for P2 chips; Contract.D01 is therefore a P2 gate.
- C08 needs C11 nearest-reference pitch resolution for legacy tuning.
- C10 provides keyboard metadata before C14 interactive piano behavior.
- C19 needs the small C22 roundtrip-export test harness.
- P1 C05 is the real release pipeline, reused at later gates, not deferred until P7.

P0 exports all baseline fixtures but does not authorize all algorithms to be implemented at once. Each early subpart is tested independently and ownership transferred explicitly. Subsequent task extends the existing module, not a duplicate helper. Domain pure API architecture is complete at P0; supported-capability flags prevent temporary implementation incompleteness from looking like legitimate empty musical results.

Core→Android handoff includes reviewed commit/tag, actual AAR asset URL/version/hash, manifest/runtime dependencies/ABIs/minSdk/API/schema versions, generated API diff, supported capabilities, real host/FFI/package evidence and remaining blockers/decision references. Android pins those actual values and returns real integration evidence. Source-copy recipes or floating branches are not handoffs.

Stop on oracle discrepancy, unsupported toolchain, unavailable dependency, disputed file ownership or undecided product behavior. Record blocker and obtain the exact decision. Never weaken tests, generate golden expectations from Rust, fabricate native output or modify web production to make parity easier.
