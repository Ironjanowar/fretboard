# Native Fretboard Core and Android Implementation Plan

> **For Hermes:** Execute one approved task at a time through independent test-writer, implementer, reviewer, and final quality-review agents. Load the available Fretboard development and TDD skills; do not assume an unavailable orchestration skill exists.

**Goal:** Deliver a fully offline, native Android Fretboard application backed by a reusable Rust music engine, with full functional parity to the existing web application and installable APK checkpoints.

**Architecture:** Keep the existing Elixir web application unchanged as a migration oracle. Implement a platform-independent Rust domain library, expose a narrow typed UniFFI boundary, and consume its versioned Android AAR from a Kotlin/Jetpack Compose application. Future SwiftUI and web consumers are architectural constraints, not deliverables of this plan.

**Tech Stack:** Rust, Cargo, UniFFI, Android NDK, Kotlin, Jetpack Compose, Gradle Kotlin DSL, AndroidX lifecycle/state persistence, GitHub Actions and Releases. Exact compatible versions are locked during P0; none is asserted as tested by this planning exercise.

---

## Status and evidence

- Planning date: 2026-09-28.
- Baseline web repository: `Ironjanowar/fretboard`.
- Baseline commit: `2daa8c665efa268942dda352691f39d78db42512` (merge of piano support).
- Plan branch: `plan/native-core-android`, created from remote `main`.
- New repositories confirmed accessible and initially empty: `Ironjanowar/fretboard-core`, `Ironjanowar/fretboard-android`.
- `Ironjanowar/fretboard-ios` exists by user confirmation; do not write to it under this plan.
- This delivery contains documentation only. No Rust engine, Android project, APK, signing key, or release has been created.
- Source inspection is evidence of feasibility, not evidence of native performance, APK size, binding compatibility, or device behavior. P1 must establish those with execution.
- The current sandbox did not expose Cargo/Rust, Java, adb, or sdkmanager on PATH. Project-pinned Elixir/OTP versions were missing. Bootstrap is a real prerequisite, not a completed step.

## Reading order

1. [Feasibility, decisions, and repository ownership](01-feasibility.md)
2. [Domain, session, FFI, and wire contracts](02-core-contract.md)
3. [Native Android UX and state design](03-android-design.md)
4. [Core tasks and exact file inventory](04-core-phases.md)
5. [Android tasks and exact file inventory](05-android-phases.md)
6. [Build, artifacts, signing, CI, and release procedure](06-delivery.md)
7. [Acceptance matrix and hard phase gates](07-validation.md)
8. [DeepSeek handoff, task execution, cost, and escalation](08-model-handoff.md)
9. [Source register, unresolved decisions, and evidence ledger](09-sources-and-decisions.md)

Paths in task documents belong to the explicitly named target repository, NOT to this web repository. Generated files have a generator and a verification step, not hand-written contents.

## Approved product contract

| Decision | Approved outcome |
|---|---|
| Platforms now | Rust core and Android only |
| Native interface | Kotlin + Jetpack Compose, not a WebView or shared UI framework |
| Engine | Shared Rust; no Android/Phoenix dependencies in domain crate |
| Offline | All music calculations and catalogs work in airplane mode |
| Feature scope | Full existing web parity, delivered incrementally |
| UX | Adapted native mobile layout, same visual identity and musical semantics |
| Language | English app, tests, comments, and project documentation |
| Session | Restore latest committed session; no named-session library |
| Sharing | Import/export existing web URLs; no account or calculation server |
| Test hardware | OnePlus 13R, OxygenOS 16.0.10; read Android API/ABI with adb rather than infer from skin version |
| Distribution | Signed APK per approved phase via GitHub Releases; no Play Store |
| Gate | Automated tests + independent review + real-device approval before dependent phase |
| Coding model | Start with DeepSeek V4.1 Flash, validate it with the P1 pilot |
| Current deliverable | Plan documents only on a new branch of the web repository |

## Phase dependency graph

```text
P0  Reproducible tools, oracle, contract handshake, signing custody
 ↓
P1  Real Compose → UniFFI → Rust vertical slice; offline APK on phone
 ↓
P2  Catalogs, chords, all-instrument visualizer, duplicate identity
 ↓
P3  Tuning drafts and fretted analyzer
 ↓
P4  Piano analyzer and instrument-boundary behavior
 ↓
P5  Scales, relative-key presentation, multi-key coverage, progressions
 ↓
P6  Compatible URL import/share, durable session and Android lifecycle
 ↓
P7  Full acceptance, security/accessibility/performance and release audit
```

P0 establishes contracts/fixtures even when features are implemented later. P1 includes a minimal build/release pipeline. P6 adds the final lifecycle/link behaviors; it must not postpone baseline lifecycle safety or the session repository seam until then. Every phase after P0 produces an installable candidate; P0 has a document/tooling approval gate, not a fictitious APK. Before an APK is approved, later features remain explicitly unavailable rather than invoking incomplete engines.

For each phase, core changes are reviewed and versioned first; Android pins that exact artifact; the combined APK is reviewed and tested. Do not interpret the two repository task lists as permission to implement all of core before the first Android experiment.

## Definition of done

- Required catalogs and domain outputs match the frozen oracle, except explicitly approved, individually tested deviations.
- All UI transitions in the Android design have native tests and user-visible parity.
- All supported calculations work without network access; no INTERNET permission is needed for music, sharing, or local imports.
- APK includes required native libraries, installs normally without adb-only restrictions, and updates the previous APK without losing the session.
- Last committed state restores after rotation, process recreation, force-stop/relaunch, and upgrade; drafts never accidentally commit.
- Share URLs survive percent-encoding and can restore corresponding state in the unchanged baseline web app.
- Accessibility includes instrument cells, selected states, labels with octaves where relevant, and non-color-only feedback.
- Release evidence records source commits, core version/checksum, toolchain locks, signer fingerprint, device/API/ABI, test results, known limitations, and user approval.
- No iOS code, web engine migration, server API, account system, audio playback, tuner, analytics, cloud sync, or app-store work is smuggled into this scope.

## Planning limitations and explicit stops

This is a detailed work specification, not a claim that the future generated API or toolchain already builds. P0 records exact versions from official compatibility information; P1 proves the generated binding signature and packaging. A failure of that spike is a stop-and-replan point, not permission to replace Rust with invented outputs or a remote service.

Three unresolved deployment facts must be obtained before dependent tasks: actual public web origin for share URLs, persistent signing-key custody, and repository visibility/artifact download authorization. These do not prevent planning. No placeholder hostname, test signing identity, or secret may silently become a production default.

Known web defects and ambiguous ordering are listed in the contract/decision register. The implementer must request a decision when reaching them, not silently preserve or fix them.

## Estimates

The phase graph is an ordering and acceptance contract, not an elapsed-time promise. AI retries, NDK setup, artifact packaging, and user review dominate uncertainty. Record actual P0/P1 duration, tokens, retries, APK size, and latency before forecasting the remaining work. Do not budget by a model's advertised benchmark alone.
