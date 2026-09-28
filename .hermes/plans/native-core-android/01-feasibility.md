# Feasibility and Architecture Decisions

## Verdict

**Viable, with a mandatory integration spike before committing to the full port.** The existing source has a clean music facade, mostly pure calculations, no database/account dependency, an explicit URL state model, and extensive domain tests. The difficult work is behavioral equivalence, native instrument interaction, reliable cross-language packaging, and lifecycle correctness—not access to a missing platform capability.

This is a rewrite of the presentation layer and a controlled port of the domain, not a Phoenix-to-APK conversion. Elixir source cannot simply be linked into Kotlin. Offline use eliminates a server-only wrapper as a solution.

## Options considered

| Option | Fit | Main cost / reason not selected |
|---|---|---|
| WebView/PWA wrapper | Reuses UI | Not the requested native/offline experiment; LiveView depends on server state |
| Kotlin Android + Swift iOS with separate domain implementations | Native and straightforward per platform | Would duplicate music rules in Kotlin, Swift, and temporarily Elixir |
| Shared Kotlin engine + native platform UIs | Technically plausible | Not selected; user specifically approved Rust engine experiment |
| Rust engine + Kotlin Compose / future SwiftUI | Selected | FFI, native ABI builds, artifact publishing and coordinated versioning |
| Rust UI toolkit for all platforms | Potential compiled cross-platform UI | Different experiment; sacrifices the chosen first-party native UI architecture |

Rust brings explicit domain types, memory safety in safe code, deterministic pure transformations, and reusable compiled logic. It does not guarantee the smallest APK: native binaries per ABI, UniFFI runtime dependencies, and Compose add size. Fretboard's domain is relatively modest; faster music calculations alone would not justify the integration overhead. Sharing one tested implementation is the principal architectural benefit.

## Repository ownership

```text
Ironjanowar/fretboard-core
  crates/domain/        pure music + canonical state + legacy wire semantics
  crates/mobile-ffi/    typed UniFFI facade, transport validation and errors
  crates/bindgen/       pinned binding-generation CLI
  android/             AAR packaging project, not an Android application
  oracle/              frozen baseline fixtures, provenance, approved deviations
  scripts/             reproducible export/build/check tooling
  .github/workflows/   native tests, Android packaging, immutable release assets

Ironjanowar/fretboard-android
  engine/              adapter around generated bindings; fakeable application port
  app/                 Compose UI, lifecycle, navigation, local state, Android intents
  vendor/              ignored verified AAR download; never edited/generated manually
  scripts/             artifact fetch, checks, APK evidence tooling
  .github/workflows/   checks, emulator tests and release APK generation

Ironjanowar/fretboard
  existing source      unchanged oracle at frozen commit
  .hermes/plans/native-core-android/  this planning package

Ironjanowar/fretboard-ios
  untouched            future native consumer, no current implementation tasks
```

Task documents are the definitive exact-file inventories. These top-level directories explain ownership, not a second implementation layout.

## Boundary rules

1. Domain receives data, not platform UI objects, contexts, sockets, or colors. Internally model valid instrument/session variants; validate at every external boundary.
2. Rust owns catalog truth, pitch arithmetic, tuning references, musical identity, analysis, key coverage, progression resolution, canonical session transitions, and URL parameter semantics.
3. Android owns rendering, geometry, theme, navigation/sheets, accessibility, URI origin checks, OS intents, filesystem persistence, and process lifecycle.
4. Distinguish state mutations from derived work. Serialize committed actions; discard stale asynchronous evaluations. Do not store multiple competing authoritative versions of musical state.
5. FFI transfers whole small request/result records, not one call per painted cell. Never call expensive analysis directly during Compose recomposition or on the main thread.
6. Domain is not built on UniFFI types. The mobile adapter maps domain types to generated transport records. FFI handles recoverable failures with typed errors, not panics.
7. No platform callback or persistent native engine object is needed for the first version. Pure functions avoid ownership/disposal complexity and help future WebAssembly integration.
8. API/ABI stability is not assumed across core versions. Generated Kotlin sources, native libraries, UniFFI generator and runtime dependencies travel together as a single AAR release; app tests enforce compatibility.
9. URL compatibility means equivalent decoded state and preserved public parameter semantics, not identical query parameter order. Store a separate versioned local session envelope instead of claiming legacy URLs have a schema version.
10. No generated binding hand-edits, dynamic downloading of executable libraries on-device, cross-repository floating branches, or copy-pasted catalogs in UI code.

## Future reuse, without scope creep

### iOS

UniFFI supports Swift generation. The pure domain and mobile adapter should avoid Android assumptions. A future project will need Apple targets, XCFramework/Swift packaging, Xcode/macOS CI, SwiftUI views, signing and device validation. None of those deliverables is implied by building an Android AAR today. Do not claim iOS build readiness without an Apple build.

### Existing web

A future Rustler adapter can keep `Fretboard.Music` as the public Elixir facade and preserve LiveView. NIFs run within the BEAM process: bounded computation, dirty schedulers where appropriate, panic/error handling and crash risk need review. It is not an automatic risk-free swap.

Alternatively, a WebAssembly adapter can run the same domain in the browser. Full web offline support additionally requires replacing LiveView's server-owned interaction/state path and offline asset handling. WASM alone does not solve that.

Keep URL and music semantics platform-independent now, but do not implement Rustler, WASM, or a speculative universal rendering layer.

## Data ownership and identity

- Active chord occurrences are an ordered list; duplicate occurrences can come from URLs and progressions.
- Musical identity is root + quality, not equivalent pitch sets. Colors and grouped highlighting use identity; removal uses occurrence.
- Notes have pitch classes; tuning/analysis also require absolute pitches. Do not discard octave information to simplify a type.
- Ukulele wire ID remains `ukelele`. Standard high-G is reentrant; physical string order is never sorted by pitch.
- Exact preset pitches and an editing-reference name form a tuning state. The reference does not drift after each edit.
- Presentation colors belong to Android; domain can return identity/membership, never palette indexes chosen from arbitrary occurrences.

## Risk register

| Risk | Mitigation / stop condition |
|---|---|
| UniFFI, NDK, Gradle/JNA mismatch | P1 generated bindings + real ABI loading on phone/emulator; no further port until passing |
| Current undocumented behavior differs from musical intuition | Frozen oracle and discrepancy decision log; no silent corrections |
| Rust iteration order changes ranked results | Explicit ordered catalogs and tie-break fixtures; never HashMap iteration as public ordering |
| One native bug crashes app | Safe Rust default, narrow FFI, no unwinding contract reliance, boundary tests and bounded inputs |
| Stale suggestions overwrite current state | Request revision on results, cancellation plus revision check |
| Giant chords/URLs consume CPU or memory | Proposed transport limits reviewed against oracle corpus; reject oversized whole envelope without erasing last session |
| Instrument surface inaccessible | Compose semantics per actionable cell; separate selected/missing indicators; real TalkBack checks |
| Signing identity changes between APKs | Persist one release identity from P1, verify fingerprint and update install |
| Multi-repo drift | Version + checksum lock, coherent AAR, smoke test then compatibility matrix per release |
| Cheap model creates plausible scaffolding without functionality | RED evidence, real GREEN, independent review, small owned tasks and stop-on-blocker instructions |
| Phone/emulator unavailable | Record incomplete gate, do not label release validated; user approval remains required |
| Scope grows into audio/lessons/library | Keep explicit non-goals; separate future request and plan |

## Repository policy

Use feature branches and PRs in each target repository; merge only with approval. Empty repositories require a one-time default-branch bootstrap in P0 after implementation is authorized—do not push scaffolding while only planning. Read each repo's real default branch rather than assuming its name once initialized. The plan delivery itself targets only the web repo.

Permissions found on the existing credential were already sufficient for metadata access and reported ADMIN on the new core/Android repos. This plan does not require administration rights, expand credentials, change branch protections, or expose secrets. Future release automation should use least-privilege per-job permissions.
