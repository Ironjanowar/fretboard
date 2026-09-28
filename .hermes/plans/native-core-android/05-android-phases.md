# Native Android Phased Implementation Plan

> **For Hermes:** Execute only after approval, with separate test-writer, implementer, and independent reviewer contexts. Do not implement this document while authoring it.

**Goal:** Build and verify a full-offline-parity Android app through small, tests-first tasks, stopping at signed APK approval gates.

**Architecture:** A new Kotlin/Compose `:app` consumes a small `:engine` wrapper around a verified release AAR from the separate Rust repository. All canonical musical state, reducer transitions, codecs and musical presentation rules stay in Rust; Kotlin implements native presentation and platform integration.

**Tech Stack:** Android SDK/Gradle/Kotlin/Compose versions verified and pinned in P0; ViewModel/coroutines/DataStore; JVM tests with fake native bindings; Compose and actual AAR/native tests on Android.

---

## 1. Execution rules and repositories

- Plan location only: `/workspace/repos/fretboard/.hermes/plans/native-core-android/`. These documents do not authorize production changes to the existing web repository.
- Implementation root **R** = `/workspace/repos/fretboard-android`. Every relative path below is exact relative to R. Core root is `/workspace/repos/fretboard-core`; core tasks/files belong to `02-core-contract.md` and `04-core-phases.md`, not this file.
- Application ID and namespace: **`dev.ironjanowar.fretboard`**. Wrapper namespace: **`dev.ironjanowar.fretboard.engine`**. Exactly two Gradle modules initially: `:app` and `:engine`; do not turn each small Kotlin component into a Gradle module.
- App Kotlin source prefix **AP** = `app/src/main/kotlin/dev/ironjanowar/fretboard/`; wrapper prefix **EP** = `engine/src/main/kotlin/dev/ironjanowar/fretboard/engine/`.
- App JVM test prefix **AT** = `app/src/test/kotlin/dev/ironjanowar/fretboard/`; wrapper JVM prefix **ET** = `engine/src/test/kotlin/dev/ironjanowar/fretboard/engine/`.
- App instrumented test prefix **AI** = `app/src/androidTest/kotlin/dev/ironjanowar/fretboard/`; wrapper instrumented prefix **EI** = `engine/src/androidTest/kotlin/dev/ironjanowar/fretboard/engine/`.
- Prefix notation in task ownership expands literally to one exact file path. No wildcard authoring permission. The manifest below enumerates every intended authored/checked-in file and generated-output location; any additional file requires an explicit inventory update and reviewer approval.
- Musical structures named in tasks are conceptual until the P0 handshake. Do not invent UniFFI generated class/function/package names or build a parallel Kotlin implementation to work around a missing core operation.
- All copy, code comments, documentation, accessibility labels and test names are English. Stable wire IDs stay `guitar`, `bass_4`, `bass_5`, `ukelele`, `piano`.

### Mandatory cycle for every code task

Each task is a bounded behavior slice. Split its implementation into short substeps rather than treating its paragraph as one unreviewed coding assignment:

1. Independent test writer creates/extends the exact named test, asserts the behavior described below, and runs the exact target command. Save RED evidence: assertion failure, not toolchain/network failure. In a new project, missing symbol compilation proves only harness bootstrap; add a behavioral failure after introducing the smallest interface skeleton, before implementation.
2. A different implementer receives the failing tests and exact file ownership, implements the minimum, and reruns that target. No test weakening, ignored tests or fabricated expected data.
3. Refactor small functions/modules; rerun target plus affected module suite. Musical rules discovered here are sent to the core owner, not implemented locally.
4. Independent reviewer checks source parity and real tool output, then runs full phase verification. Commit only green work; inspect staged paths so no credentials, binaries or sibling edits enter the commit.
5. Run phase APK gate and stop for user approval. Fix feedback with new RED cases and repeat the same gate before dependent work.

Toolchain/discovery tasks cannot honestly have a behavioral RED before a harness exists; their explicit evidence checks replace TDD, not a fabricated test pass. P0 is a preparation gate, not an APK delivery; **P1 is the first APK** and P1–P7 each require installation/user approval.

## 2. Exact new-repository manifest

Files listed under a phase are created in that phase; later tasks may modify only files explicitly named by those tasks. Keep classes small and separate drawing, hit geometry, ViewModel orchestration, storage and native adapters. No monolithic Activity or catch-all `MusicUtils.kt`.

### P0 — repository/tooling/contract records

```text
.gitignore
AGENTS.md
README.md
CHANGELOG.md
docs/development.md
docs/toolchain.md
docs/contract-handshake.md
docs/parity-matrix.md
docs/release-signing.md
docs/phase-gates.md
core-release.lock.json
scripts/prepare_core.py
scripts/tests/test_prepare_core.py
scripts/verify_apk.py
scripts/tests/test_verify_apk.py
settings.gradle.kts
build.gradle.kts
gradle.properties
gradle/libs.versions.toml
gradle/verification-metadata.xml
```

The preparation lock is filled only from a real core Release. If that release does not yet exist, document the dependency and leave the **task incomplete** rather than committing plausible placeholder hashes. `gradle/verification-metadata.xml` is generated and independently reviewed against trusted dependency sources after toolchain selection, not manually fabricated. No dynamic dependency versions.

### P1 — project, wrapper, session smoke

```text
gradlew
gradlew.bat
gradle/wrapper/gradle-wrapper.jar
gradle/wrapper/gradle-wrapper.properties
app/build.gradle.kts
app/proguard-rules.pro
app/src/main/AndroidManifest.xml
app/src/main/res/values/strings.xml
app/src/main/res/values/themes.xml
app/src/main/res/drawable/ic_launcher_foreground.xml
app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml
app/src/main/res/xml/backup_rules.xml
app/src/main/res/xml/data_extraction_rules.xml
engine/build.gradle.kts
engine/consumer-rules.pro
engine/src/main/AndroidManifest.xml
```

| Prefix | Exact suffixes (one file each) |
|---|---|
| AP | `FretboardApplication.kt`; `MainActivity.kt`; `di/AppContainer.kt`; `session/SessionViewModel.kt`; `session/SessionUiState.kt`; `session/SessionCoordinator.kt`; `ui/FretboardApp.kt`; `ui/MainScreen.kt`; `ui/FeatureAvailability.kt`; `ui/theme/Color.kt`; `ui/theme/Theme.kt`; `ui/theme/Type.kt`; `ui/common/ErrorBanner.kt` |
| EP | `api/EngineGateway.kt`; `api/EngineModels.kt`; `api/EngineFailure.kt`; `binding/NativeBindings.kt`; `binding/UniFfiBindings.kt`; `binding/BindingMapper.kt`; `runtime/DefaultEngineGateway.kt`; `runtime/EngineDispatchers.kt` |
| AT | `support/MainDispatcherRule.kt`; `support/FakeNativeBindings.kt`; `support/EngineFixtureFactory.kt`; `session/SessionViewModelTest.kt`; `session/SessionCoordinatorTest.kt` |
| ET | `support/FakeNativeBindings.kt`; `binding/BindingMapperTest.kt`; `runtime/DefaultEngineGatewayTest.kt` |
| AI | `support/ComposeTestHost.kt`; `ui/AppSmokeTest.kt`; `ui/FeatureAvailabilityTest.kt` |
| EI | `binding/RealBindingsSmokeTest.kt` |

Two tiny fake implementations in distinct test source sets are test doubles, not musical sources; neither computes any chord/pitch output. Prefer scripted transport fixtures over shared test-only modules. The Activity only forwards intents/lifecycle and hosts Compose; session orchestration belongs elsewhere.

### P2 — catalogs, visualizer, duplicate behavior

| Prefix | Exact suffixes |
|---|---|
| AP | `ui/controls/SessionControls.kt`; `ui/controls/InstrumentPicker.kt`; `ui/controls/ChordEditor.kt`; `ui/common/GroupedPicker.kt`; `ui/visualizer/VisualizerScreen.kt`; `ui/visualizer/ChordCards.kt`; `ui/surface/FretboardSurface.kt`; `ui/surface/FretboardGeometry.kt`; `ui/surface/SurfaceSemantics.kt` |
| AT | `ui/FretboardGeometryTest.kt`; `session/VisualizerTransitionsTest.kt` |
| AI | `ui/CatalogControlsTest.kt`; `ui/VisualizerParityTest.kt`; `ui/DuplicateChordUiTest.kt` |
| EI | `binding/CatalogNativeTest.kt`; `binding/VisualizerNativeTest.kt` |

### P3 — fretted analyzer and fixed-reference tuning

| Prefix | Exact suffixes |
|---|---|
| AP | `ui/tuning/TuningSheet.kt`; `ui/analyzer/AnalyzerScreen.kt`; `ui/analyzer/AnalysisCards.kt`; `ui/surface/SurfaceInput.kt`; `session/DraftCoordinator.kt` |
| AT | `session/TuningDraftTest.kt`; `session/FrettedAnalyzerTest.kt`; `ui/SurfaceInputTest.kt` |
| AI | `ui/TuningSheetTest.kt`; `ui/FrettedTouchTest.kt`; `ui/AnalysisCardsTest.kt` |
| EI | `binding/TuningNativeTest.kt`; `binding/AnalyzerNativeTest.kt` |

### P4 — full piano parity

| Prefix | Exact suffixes |
|---|---|
| AP | `ui/surface/PianoSurface.kt`; `ui/surface/PianoGeometry.kt` |
| AT | `ui/PianoGeometryTest.kt`; `session/PianoTransitionsTest.kt` |
| AI | `ui/PianoVisualizerTest.kt`; `ui/PianoAnalyzerTouchTest.kt`; `ui/InstrumentBoundaryTest.kt` |
| EI | `binding/PianoNativeTest.kt` |

### P5 — keys, progressions, asynchronous result lifecycle

| Prefix | Exact suffixes |
|---|---|
| AP | `ui/keys/KeySheet.kt`; `ui/keys/KeySuggestions.kt`; `ui/keys/MultiKeySuggestions.kt`; `ui/progressions/ProgressionSheet.kt`; `session/EvaluationCoordinator.kt`; `ui/common/LoadingState.kt` |
| AT | `session/KeyProgressionDraftTest.kt`; `session/EvaluationCoordinatorTest.kt` |
| AI | `ui/KeyProgressionUiTest.kt`; `ui/RelativeModesTest.kt`; `ui/MultiKeyMembershipTest.kt`; `ui/EvaluationStateUiTest.kt` |
| EI | `binding/KeysProgressionsNativeTest.kt` |

### P6 — last-session restore and legacy URL platform flows

```text
docs/sharing.md
app/src/main/res/values/share_config.xml
```

| Prefix | Exact suffixes |
|---|---|
| AP | `storage/SessionStore.kt`; `storage/DataStoreSessionStore.kt`; `storage/SessionSnapshotSerializer.kt`; `session/BootCoordinator.kt`; `links/IncomingIntentParser.kt`; `links/ImportCoordinator.kt`; `links/ShareLauncher.kt`; `links/ShareConfig.kt`; `ui/importing/ImportSheet.kt` |
| AT | `support/FakeSessionStore.kt`; `storage/SessionStoreTest.kt`; `session/BootCoordinatorTest.kt`; `links/IncomingIntentParserTest.kt`; `links/ImportCoordinatorTest.kt`; `links/ShareLauncherTest.kt` |
| AI | `lifecycle/RestoreLifecycleTest.kt`; `links/ImportIntentTest.kt`; `links/ShareIntentTest.kt`; `links/LegacyRoundTripTest.kt` |
| EI | `binding/CodecNativeTest.kt` |

### P7 — release and complete parity audit

```text
scripts/check_boundaries.py
scripts/tests/test_check_boundaries.py
scripts/check_release.py
scripts/tests/test_check_release.py
.github/workflows/android.yml
docs/release-checklist.md
app/src/androidTest/assets/parity/catalog.json
app/src/androidTest/assets/parity/visualizer.json
app/src/androidTest/assets/parity/tuning-analysis.json
app/src/androidTest/assets/parity/piano.json
app/src/androidTest/assets/parity/keys-progressions.json
app/src/androidTest/assets/parity/legacy-urls.json
app/src/androidTest/assets/parity/provenance.json
```

| Prefix | Exact suffixes |
|---|---|
| AT | `session/FullSessionRegressionTest.kt` |
| AI | `release/OfflineParityTest.kt`; `release/AccessibilityAuditTest.kt`; `release/UpgradeSmokeTest.kt`; `release/ReleaseNativeLoadingTest.kt` |

Parity JSON is copied test data from approved core differential fixtures with original web commit, core release/checksum and capture command recorded in `provenance.json`; do not synthesize expected native output. Earlier phase tests can use the same approved fixture cases in `EngineFixtureFactory.kt` until the complete audit asset set is imported. Fixture data is not duplicated musical implementation. Device-specific screenshots/logs are ignored evidence, not source.

### Generated/local outputs — never model-authored

| Path under R | Producer and policy |
|---|---|
| `vendor/fretboard-mobile.aar` | `scripts/prepare_core.py`, verified pinned GitHub Release; ignore entire `vendor/` |
| `vendor/core-release-metadata.json` | Preparation script writes verified metadata for inspected AAR; ignored |
| `.gradle/`, `app/build/`, `engine/build/` | Gradle/AGP/Compose/test output; ignored. Generated AAR bindings are already compiled into the dependency, no authored `src/generated` |
| `local.properties` | Local SDK configuration; ignored |
| `artifacts/` | Signed phase APK copies, SHA-256 reports, install logs, screenshots, review/gate evidence; ignored |
| `app/build/outputs/apk/release/app-release.apk` | AGP signed installable release APK, actual path checked before packaging evidence |
| `app/build/outputs/androidTest/`, `engine/build/outputs/androidTest/` | Instrumentation APKs, generated |
| `app/build/reports/`, `engine/build/reports/` | Lint/test reports, generated |
| `app/build/outputs/mapping/release/` | R8 mappings for P7 minified release, retain securely with artifact |

The wrapper scripts/JAR/properties are tooling-generated **and checked in**, unlike build outputs. Generate with official Gradle tooling after verifying its distribution checksum, using the verified version from `docs/toolchain.md`: `gradle wrapper --gradle-version "$VERIFIED_GRADLE_VERSION" --distribution-type bin`. Never write a dummy JAR or fetch wrapper binaries from an arbitrary snippet. Ensure distribution SHA-256 is pinned in wrapper properties and independently verify wrapper provenance.

## 3. Command vocabulary and hard gates

Commands below run in R unless they explicitly `cd` elsewhere. `APP_ID=dev.ironjanowar.fretboard` is not a configurable alternate package. Tools/SDK paths and release signing are established in P0; examples do not contain passwords or key paths.

**JVM targets:** for each task's named AT class, run `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.<relative.package>.<Class>`; for ET use `./gradlew :engine:testDebugUnitTest --tests dev.ironjanowar.fretboard.engine.<relative.package>.<Class>`. Exact invocations are also supplied per task below. Use test-only fakes; no `.so` loads.

**Instrumented targets:** `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.<relative.package>.<Class>`; wrapper tests use `:engine:connectedDebugAndroidTest` and wrapper package. These require a connected compatible emulator/device. A missing device is a blocker, never a skipped pass.

**Every P1–P7 automatic gate:**

```bash
python3 -m unittest discover -s scripts/tests -v
python3 scripts/prepare_core.py --offline
./gradlew :engine:testDebugUnitTest :app:testDebugUnitTest :engine:lintDebug :app:lintDebug
./gradlew :engine:connectedDebugAndroidTest :app:connectedDebugAndroidTest
./gradlew :app:assembleRelease
python3 scripts/verify_apk.py --apk app/build/outputs/apk/release/app-release.apk --lock core-release.lock.json
```

Scripts and Gradle options here are **to be implemented and tested** in the specified tasks, not claimed to exist. P0 seeds only available tests. The APK checker verifies package, signer fingerprint versus secured expected fingerprint, monotonic versionCode versus prior delivery metadata, required ABI/shared library contents, SDK policy, artifact SHA-256 and absence of accidentally bundled debug-only/test code. Signer comparison is against trusted delivery metadata, not merely two fields read from the same APK. Native smoke must still run; listing `.so` files is insufficient.

Independent reviewer then inspects the APK/checker report and source diff. Deliver the actual signed APK, its checksum, core lock identity, versionCode, automated logs and short manual checklist. Do not deliver only an AAB or instructions to build.

**Every P1–P7 device gate:**

```bash
adb devices -l
adb shell getprop ro.build.version.sdk
adb shell getprop ro.product.cpu.abilist
adb install -r app/build/outputs/apk/release/app-release.apk
adb shell am start -n dev.ironjanowar.fretboard/.MainActivity
adb shell dumpsys package dev.ironjanowar.fretboard
```

Verify installed package/version and real Rust response on the OnePlus; also allow the user to install the delivered APK using Android's normal installer. Test offline with airplane mode and app network access absent. Update install must retain data once P6 persistence exists; never uninstall/clear data to disguise a failed upgrade. Stable signer begins at P1, not at final release. Record explicit user approval in `docs/phase-gates.md` before starting the next phase.

## 4. P0 — discovery, toolchain and contract preparation

### A00 — freeze observable parity and unblock decisions

**Depends on:** approved scope; core P0 owner available. **Files:** create `AGENTS.md`, `README.md`, `CHANGELOG.md`, `docs/development.md`, `docs/toolchain.md`, `docs/contract-handshake.md`, `docs/parity-matrix.md`, `docs/release-signing.md`, `docs/phase-gates.md`.

Read the actual sources/tests listed in `03-android-design.md`, not README alone. Run the web baseline without edits:

```bash
cd /workspace/repos/fretboard
mix test test/fretboard/music test/fretboard_web/live
mix format --check-formatted
```

Capture exit status and failures honestly; if environment blocks execution, record it and resolve before fixture freeze. Query official Android/Gradle/Kotlin/Compose/UniFFI compatibility documentation, verify available JDK/SDK tools, obtain actual device API/ABIs, and pin selected stable versions. Confirm minSdk proposal 26 against supported runtime dependencies. Record tested SDK/device matrix and chosen ABI set (at least the real phone's supported architecture, and emulator architecture used for tests). Confirm 16KB-page compatibility requirements for the chosen SDK/device/toolchain and AAR.

Freeze EngineSession/Action/reduce/evaluate typed contracts, snapshot schema, draft semantics, catalog view data, semantic color slots, relative grouping, error taxonomy, envelope limits, repeated-query-key semantics, cancellation/thread safety and generated-package names with core. Contract must cover musical rules currently in LiveView; missing operations block dependent tasks.

Discover the actual production web URL with repository/deployment owner evidence. If unavailable, mark **SHARE_ORIGIN unresolved** in `docs/contract-handshake.md` and `docs/phase-gates.md`: no guessed host, no manifest App Links yet. Paste and incoming shared text remain feasible. Resolve missing-note pairing and incomplete relative-mode-group discrepancies with fixtures/core; no silent correction. Document persistent signing and backup custody without secrets. Record a user-approved signer fingerprint and initial versionCode policy in delivery metadata.

**Acceptance:** parity matrix maps every web event/catalog/codec family to core fixture and Android task; official tool sources and actual adb evidence recorded; unresolved blockers have owner and dependent phase. P0 approval permits P1 scaffolding, not a claim of full native readiness.

### A01 — tests-first pinned AAR preparation

**Depends on:** A00, published core smoke AAR with exact Release version and SHA-256. **Files:** create `core-release.lock.json`, `.gitignore`, `scripts/prepare_core.py`, `scripts/tests/test_prepare_core.py`.

**RED/GREEN command:** `python3 -m unittest discover -s scripts/tests -p test_prepare_core.py -v`.

Tests use local test HTTP fixtures/injected downloader, not invented real release responses: verified download atomically installs; same verified cache supports `--offline`; cache tampering fails; wrong SHA, missing ABI, incompatible protocol, changed asset, interrupted download and HTTP failure leave prior good file intact; missing artifact offline produces actionable failure; URL cannot point at mutable `latest`. Validate exact lock fields and reject missing/placeholder values. Implement download with HTTPS, bounded timeout/size, temporary file and digest check before rename. App build consumes ignored `vendor/`, never sibling core sources. Ignore secrets/local SDK/build/evidence paths. Run real `python3 scripts/prepare_core.py`, inspect actual AAR contents and metadata, then rerun offline. Core packaging defects go back to core owner.

### A02 — tests-first delivery verifier and build contract

**Depends on:** A00/A01. **Files:** create `scripts/verify_apk.py`, `scripts/tests/test_verify_apk.py`, `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/libs.versions.toml`; generate/review `gradle/verification-metadata.xml`; update `docs/toolchain.md`.

**RED/GREEN command:** `python3 -m unittest discover -s scripts/tests -p test_verify_apk.py -v`.

Test wrong package, unknown/different signer, non-increasing versionCode, wrong SDK policy, missing native ABI, malformed APK and checksum evidence. Inject official tool outputs only in test doubles; run real tools against real P1 APK later. Build contract declares only `:app`/`:engine`, explicit repositories/versions, dependency verification and real binding runtime dependencies from the AAR. Do not resolve an AAR until preparation has verified it; fail with a preparation command when absent. Signing is loaded from secure external configuration and fails closed when required secrets are unavailable.

**P0 exit:** independent review and user approval of contract/tools/signing plan. Core Release availability and confirmed generated API are hard P1 blockers. Production share host can remain documented as a P6 blocker; no auto-link promise.

## 5. P1 — first real Compose → Rust APK

### A03 — bootstrap official project and test harness

**Depends on:** P0 approval. **Files:** all P1 non-Kotlin build/resource/manifest/wrapper files; AP `FretboardApplication.kt`, `MainActivity.kt`, `di/AppContainer.kt`, `ui/FretboardApp.kt`, `ui/MainScreen.kt`, `ui/FeatureAvailability.kt`, `ui/theme/Color.kt`, `ui/theme/Theme.kt`, `ui/theme/Type.kt`, `ui/common/ErrorBanner.kt`; AT `support/MainDispatcherRule.kt`; AI `support/ComposeTestHost.kt`, `ui/AppSmokeTest.kt`, `ui/FeatureAvailabilityTest.kt`.

Generate wrapper through official tooling, then write smoke Compose tests before real content. **Command:** `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.AppSmokeTest`.

Assert app label/package, English startup/loading/error state, first actual core response displayed, and no network permission requirement. Initial placeholder can fail the real-result assertion. `FeatureAvailabilityTest` pins temporary staged behavior: catalog-advertised unfinished surfaces render explicit “Not available in this phase” rather than the wrong instrument's UI. No fake production catalogs or hardcoded successful native response. Use explicit manifest exported flags, launcher action, SDK values from P0 and backup exclusion for last-session/private state. Set persistent release signing from this first APK.

### A04 — isolate native bindings and prove actual loading

**Depends on:** A03 and core smoke contract. **Files:** all P1 EP files; ET `support/FakeNativeBindings.kt`, `binding/BindingMapperTest.kt`, `runtime/DefaultEngineGatewayTest.kt`; EI `binding/RealBindingsSmokeTest.kt`.

**RED/GREEN commands:**

```bash
./gradlew :engine:testDebugUnitTest --tests dev.ironjanowar.fretboard.engine.binding.BindingMapperTest --tests dev.ironjanowar.fretboard.engine.runtime.DefaultEngineGatewayTest
./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.RealBindingsSmokeTest
```

Assert DTO mapping preserves order/duplicates/types; gateway delegates without musical calculation; typed domain error versus load/protocol failure is distinct; native call runs off main; handles close exactly once after outstanding work; fake JVM path does not load native libraries. Real test checks contract version, opens a real default session, requests a catalog/known C-major result through the actual generated binding, reduces one action, exports a snapshot and closes. Wrong-ABI/missing-runtime errors must fail, not be converted to default music. Record actual backend loader/runtime requirements in handshake and ProGuard consumer rules.

### A05 — serialized ViewModel session state

**Depends on:** A04. **Files:** AP `session/SessionViewModel.kt`, `session/SessionUiState.kt`, `session/SessionCoordinator.kt`; AT `support/FakeNativeBindings.kt`, `support/EngineFixtureFactory.kt`, `session/SessionViewModelTest.kt`, `session/SessionCoordinatorTest.kt`; modify AP `di/AppContainer.kt`, `ui/MainScreen.kt`.

**RED/GREEN command:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.SessionViewModelTest --tests dev.ironjanowar.fretboard.session.SessionCoordinatorTest`.

Fake scripted startup success/failure and concurrent actions assert one serialized reducer, immutable UI snapshots, last valid state on rejected action, no parallel use/disposal of native handle, no invented fallback success, main thread stays free. Rotation keeps ViewModel; process recreation currently starts default until P6 and is explicitly not yet persistence parity. Wire the screen to real gateway, not the fake test graph.

**P1 gate:** all automatic/device gates; actual core label/action changes on phone in airplane mode; persistent-signed APK installs normally. User sees intentionally minimal UI. Check logcat for loader/runtime faults. Stop for approval before full UI.

## 6. P2 — all catalogs and fretted visualizer

### A06 — catalog-driven controls and mode visibility

**Depends on:** P1 approval; core catalog/session contract ready. **Files:** AP `ui/controls/SessionControls.kt`, `ui/controls/InstrumentPicker.kt`, `ui/controls/ChordEditor.kt`, `ui/common/GroupedPicker.kt`; AI `ui/CatalogControlsTest.kt`; EI `binding/CatalogNativeTest.kt`; modify AP `ui/MainScreen.kt`, `ui/FeatureAvailability.kt` and AI `ui/FeatureAvailabilityTest.kt`.

**Commands:** `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.CatalogControlsTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.CatalogNativeTest`.

Assert exactly five stable instrument IDs in catalog order; visible Ukulele retains `ukelele`; all quality groups/labels supplied by engine appear, no hand-curated subset. Visualizer-only Add/Key/Progressions; tuning absent for piano. Not-yet-built Piano and Analyzer show explicit placeholders. Flip only fretted Visualizer's staging tests in this phase. Same-instrument selection is a no-op.

### A07 — fretted drawing and readable geometry

**Depends on:** A06. **Files:** AP `ui/surface/FretboardSurface.kt`, `ui/surface/FretboardGeometry.kt`, `ui/surface/SurfaceSemantics.kt`, `ui/visualizer/VisualizerScreen.kt`; AT `ui/FretboardGeometryTest.kt`; AI `ui/VisualizerParityTest.kt`; EI `binding/VisualizerNativeTest.kt`; modify AP `ui/MainScreen.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.ui.FretboardGeometryTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.VisualizerParityTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.VisualizerNativeTest`.

Assert 25 positions per string, string counts 6/4/5/4, reversed physical rows, open column distinct from fret 1, bounds at fret 24, double markers inside short instruments, deterministic density/scroll mapping. Visualizer is non-actionable and selected analyzer state does not leak into its markers. Engine supplies note membership/slot; test cyan single-identity, gray distinct-identity overlap, highlighted identity color and gray others against real bindings. Test large font/landscape drawing without clipped last fret.

### A08 — occurrence cards, duplicate colors and transitions

**Depends on:** A07. **Files:** AP `ui/visualizer/ChordCards.kt`; AT `session/VisualizerTransitionsTest.kt`; AI `ui/DuplicateChordUiTest.kt`; modify AP `session/SessionCoordinator.kt`, `ui/visualizer/VisualizerScreen.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.VisualizerTransitionsTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.DuplicateChordUiTest`.

Use engine-imported fixture state even though user URL UI arrives P6. `Cmaj,Cmaj,Amin` cards are cyan/cyan/orange; duplicate notes not gray solely due to repeated occurrence. `C6,Amin7,C6` highlights both C6 copies, not Amin7; tapping either highlighted copy clears both. Remove only one occurrence; highlight survives remaining copy and clears on last removal. Manual Add prevents exact duplicate but allows equal-pitch-set identity. Remove action never triggers card highlight; clear chords preserves selected notes/tuning; slots recompute by first appearance. Assert all note–interval pairs render, not title only.

**P2 gate:** add/remove/highlight/clear multiple extended qualities on all four fretted instruments; scroll to open/fret 24; rotate and check color identity/card readability. Piano/analyzer placeholders are explicit and catalog retained. Automated native tests plus signed APK/user approval required.

## 7. P3 — fretted analyzer and tuning drafts

### A09 — fixed-reference tuning draft lifecycle

**Depends on:** P2 approval; core tuning draft operations. **Files:** AP `session/DraftCoordinator.kt`, `ui/tuning/TuningSheet.kt`; AT `session/TuningDraftTest.kt`; AI `ui/TuningSheetTest.kt`; EI `binding/TuningNativeTest.kt`; modify AP `session/SessionCoordinator.kt`, `ui/MainScreen.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.TuningDraftTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.TuningSheetTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.TuningNativeTest`.

Assert preset catalog exactness, physical String N→1 editor order, draft isolation, Apply atomicity, Cancel/back/outside dismiss dropping both pitches/reference, same-instrument no-op, instrument change dismissing draft, invalid string/note rejection, piano tuning no-op. Real binding regression: Drop D → E → G# first string resolves 32, reference remains Drop D after Apply/reopen; Standard versus Low G same names/different bass; Baritone exact pitches; nearest tie downward. Never implement nearest-pitch calculation in DraftCoordinator. Stale draft Apply cannot target a replaced session.

### A10 — tap routing for fretted analyzer

**Depends on:** A09. **Files:** AP `ui/surface/SurfaceInput.kt`; AT `ui/SurfaceInputTest.kt`, `session/FrettedAnalyzerTest.kt`; AI `ui/FrettedTouchTest.kt`; modify AP `ui/surface/FretboardSurface.kt`, `ui/surface/SurfaceSemantics.kt`, `session/SessionCoordinator.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.ui.SurfaceInputTest --tests dev.ironjanowar.fretboard.session.FrettedAnalyzerTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.FrettedTouchTest`.

Assert 48dp-or-larger disjoint targets, first/last cells/strings, density/scroll offset, half-open boundary ownership, outside no-op, one action on pointer up, scroll/cancel/multiple-pointer no activation, keyboard Enter/Space once, TalkBack selected labels. One fret per string; same toggles off and different replaces. Tab change retains selection; fretted instrument change filters invalid strings and resets tuning/highlight; stale events cannot mutate piano. Do actual pointer input tests, not only `performClick` semantics.

### A11 — typed analyzer results and missing-note semantics

**Depends on:** A10. **Files:** AP `ui/analyzer/AnalyzerScreen.kt`, `ui/analyzer/AnalysisCards.kt`; AI `ui/AnalysisCardsTest.kt`; EI `binding/AnalyzerNativeTest.kt`; modify AP `ui/MainScreen.kt`, `ui/FeatureAvailability.kt` and AI `ui/FeatureAvailabilityTest.kt`.

**Commands:** `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.AnalysisCardsTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.AnalyzerNativeTest`.

Assert Empty instruction, Single, Interval, Octave, Chords and no-match; transition multi-card → interval → empty removes stale cards. Pin bass by lowest absolute pitch, slash labels/inversion, exact/incomplete/partial, sorted result order, extended labels and actual missing-tone associations including C9. An interval with octave doubling remains interval; all same pitch class in distinct octaves reports Octave. Clear notes retains chords/highlight; tuning Apply recomputes despite unchanged note names. Render missing association supplied by core, no parallel-array zip. Flip fretted analyzer staging test.

**P3 gate:** manually mark open/fret-24 cells, replace/toggle/clear; high-G/Low G and Drop D sequence; cancel/reopen edits; scroll without selection; TalkBack/large text and rotation. Signed APK/user approval, no unresolved missing-note discrepancy.

## 8. P4 — piano visualizer and analyzer

### A12 — keyboard geometry and static visualizer

**Depends on:** P3 approval; core keyboard view data. **Files:** AP `ui/surface/PianoGeometry.kt`, `ui/surface/PianoSurface.kt`; AT `ui/PianoGeometryTest.kt`; AI `ui/PianoVisualizerTest.kt`; EI `binding/PianoNativeTest.kt`; modify AP `ui/visualizer/VisualizerScreen.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.ui.PianoGeometryTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.PianoVisualizerTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.PianoNativeTest`.

Assert pitches 48–83 exactly once, 21 white/15 black, C3/B5 limits, correct engine key-kind/anchor metadata, web proportional black offsets and paint order, scaled black width at least 48dp. White body below black maps white, black overlap maps black; boundary deterministic. Static visualizer labels active notes and exposes no toggle; saved analyzer keys never color it. Reuse semantic palette projection, not a piano-specific music/color algorithm.

### A13 — absolute-pitch activation and lifecycle

**Depends on:** A12. **Files:** AT `session/PianoTransitionsTest.kt`; AI `ui/PianoAnalyzerTouchTest.kt`, `ui/InstrumentBoundaryTest.kt`; modify AP `ui/surface/PianoSurface.kt`, `ui/surface/SurfaceSemantics.kt`, `ui/analyzer/AnalyzerScreen.kt`, `ui/FeatureAvailability.kt`, `session/SessionCoordinator.kt`; modify AI `ui/FeatureAvailabilityTest.kt` and EI `binding/PianoNativeTest.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.PianoTransitionsTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.PianoAnalyzerTouchTest,dev.ironjanowar.fretboard.ui.InstrumentBoundaryTest`.

Run real pointer tests for every key and representative black edges; keyboard/TalkBack toggles exactly once; duplicate pitch classes in octaves independent; no tap on scrolling. `60,72` → Octave; `60,64,67` → Cmaj/Bass C; `64,67,72` → Cmaj/E/Bass E/1st inversion. Clearing/changing tab preserves visualizer state; same instrument no-op; each fretted↔piano transition clears incompatible selection even in Visualizer, preserves chords/tab and clears highlight; no tuning on piano. Flip all piano staging tests. Use both actual bindings and scripted UI snapshots.

**P4 gate:** user sweeps all 36 keys, black/white boundaries, C3/B5 scroll reach, rotate, TalkBack, selection/tab/instrument resets; no sound or glissando. Agree comfortable keyboard size without shrinking black hit width. Signed APK/user approval.

## 9. P5 — keys, progressions and cancellation

### A14 — key/progression drafts and replacement actions

**Depends on:** P4 approval; core full key/progression protocol. **Files:** AP `ui/keys/KeySheet.kt`, `ui/progressions/ProgressionSheet.kt`; AT `session/KeyProgressionDraftTest.kt`; AI `ui/KeyProgressionUiTest.kt`; EI `binding/KeysProgressionsNativeTest.kt`; modify AP `session/DraftCoordinator.kt`, `ui/MainScreen.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.KeyProgressionDraftTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.KeyProgressionUiTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.KeysProgressionsNativeTest`.

Assert fresh Key C/major/triad and Progression C/`pop_i_v_vi_iv`; every grouped catalog entry reachable; preview changes only draft; triad and seventh exact preview; Cancel leaves session untouched and next open resets; Apply replaces rather than appends, clears highlight, preserves selection/tab/tuning and repeats progression chords. Applying suggested key uses Rust-inferred chord mode, not the sheet's previous mode.

### A15 — suggestion grouping and full membership rendering

**Depends on:** A14. **Files:** AP `ui/keys/KeySuggestions.kt`, `ui/keys/MultiKeySuggestions.kt`, `ui/common/LoadingState.kt`; AI `ui/RelativeModesTest.kt`, `ui/MultiKeyMembershipTest.kt`; modify AP `ui/visualizer/VisualizerScreen.kt`.

**Commands:** `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.RelativeModesTest,dev.ironjanowar.fretboard.ui.MultiKeyMembershipTest`.

Assert <2 chords hides section; perfect seven-mode group shows major/minor then five expandable modes; non-modal cards remain independent; partial best results show core's first three only; score/total/order preserved. Expansion shared across groups and reset after committed changes. `Dmin,Gmaj,Emaj,Fmaj`: C Major lists Dmin/Gmaj/Fmaj, A Harmonic Minor lists Dmin/Emaj/Fmaj; neither omits common members. Unmatched group visible when core returns it; membership colors follow frozen web fixture policy. Android performs no grouping/coverage calculation.

### A16 — asynchronous evaluation, cancellation and stale-result rejection

**Depends on:** A15. **Files:** AP `session/EvaluationCoordinator.kt`; AT `session/EvaluationCoordinatorTest.kt`; AI `ui/EvaluationStateUiTest.kt`; modify AP `session/SessionCoordinator.kt`, `session/SessionViewModel.kt`, `session/DraftCoordinator.kt`, `ui/keys/KeySuggestions.kt`, `ui/keys/MultiKeySuggestions.kt`, `ui/analyzer/AnalyzerScreen.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.EvaluationCoordinatorTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.ui.EvaluationStateUiTest`.

Use virtual-time fake returning B before A even after cancellation. Assert old success AND old failure cannot replace current results; clearing chords while busy leaves no stale panel; session replacement/disposal/draft dismiss invalidates tokens; native non-cooperative work finishing late is ignored and handles disposed safely. Only chord-input change recalculates keys; tab/highlight/layout change does not. Analysis key includes exact tuning/selection/instrument; preview key includes draft generation. Pending/loading, empty, failure and Retry distinct. Main thread unaffected. Real native instrumentation checks repeated calls/close lifecycle through `KeysProgressionsNativeTest`; cancellation support must match contract, never infer synchronous native interruption from `Job.cancel()`.

**P5 gate:** rapid Add/remove/clear, tab/instrument changes while calculating, preview Cancel, full relative modes, overlapping multi-key cards and progression duplicates. Wait for stale tasks to finish and confirm UI stays current. Signed APK/user approval.

## 10. P6 — durable last session, import and share

### A17 — atomic last-session storage

**Depends on:** P5 approval; core snapshot version/migration contract. **Files:** AP `storage/SessionStore.kt`, `storage/DataStoreSessionStore.kt`, `storage/SessionSnapshotSerializer.kt`; AT `support/FakeSessionStore.kt`, `storage/SessionStoreTest.kt`; modify AP `session/SessionCoordinator.kt`, `di/AppContainer.kt`.

**Command:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.storage.SessionStoreTest`.

Test successful accepted revision stored atomically, older write cannot overwrite newer, failed write leaves prior valid bytes, drafts/derived results not saved, typed snapshot migration delegated to Rust, corrupt/unsupported saved data does not create crash loop or silently erase the original. Store opaque engine snapshot plus minimal container schema/revision, not a second musical serializer. IO dispatcher and deterministic temp DataStore in tests. Persistence after each accepted action; no lifecycle-only save dependency. Surface durable-write failure without rolling back working musical state.

### A18 — startup arbitration and real lifecycle

**Depends on:** A17. **Files:** AP `session/BootCoordinator.kt`; AT `session/BootCoordinatorTest.kt`; AI `lifecycle/RestoreLifecycleTest.kt`; modify AP `session/SessionViewModel.kt`, `session/SessionCoordinator.kt`, `di/AppContainer.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.BootCoordinatorTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.lifecycle.RestoreLifecycleTest`.

Assert incoming validated candidate > saved snapshot > defaults; rejected incoming cold import restores baseline with error; warm rejection keeps current; slow store read cannot overwrite newer intent; controls disabled until initial arbitration resolves; latest explicit delivery wins. Rotation retains draft/scroll presentation, process restoration keeps committed state only. `ActivityScenario.recreate()` is rotation/recreation coverage, **not proof of process death**. Manual gate force-stops the real signed app after save acknowledgement, relaunches, and compares instrument/tuning/reference/chords/duplicates/highlight/tab/selection; add host adb-driven evidence to gate record. Corrupt snapshot fixture shows recoverable warning and safe default without destructive immediate rewrite.

### A19 — untrusted legacy URL import and Intent routing

**Depends on:** A18; core envelope and tolerant codec fixtures. **Files:** AP `links/IncomingIntentParser.kt`, `links/ImportCoordinator.kt`, `ui/importing/ImportSheet.kt`; AT `links/IncomingIntentParserTest.kt`, `links/ImportCoordinatorTest.kt`; AI `links/ImportIntentTest.kt`; EI `binding/CodecNativeTest.kt`; modify AP `MainActivity.kt`, `ui/MainScreen.kt`, `session/BootCoordinator.kt`; modify `app/src/main/AndroidManifest.xml`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.links.IncomingIntentParserTest --tests dev.ironjanowar.fretboard.links.ImportCoordinatorTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.links.ImportIntentTest`; `./gradlew :engine:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.engine.binding.CodecNativeTest`.

Support explicit paste and `ACTION_SEND` text, cold start and `onNewIntent`; no clipboard scraping or network fetch. Test unsupported scheme/path/envelope, size limits, invalid encoding, multiple candidates, wrong MIME, missing extras and duplicate lifecycle delivery. Full envelope rejection preserves all canonical fields/disk state; successful tolerant import defaults/filters only malformed fields, retaining valid siblings according to old codec. Native cases: invalid pitches authoritative over conflicting tuning; bad reference retains valid pitches; legacy note-only ignores reference; piano keys sorted/deduped/bounded; marked siblings filtered; unknown kind/tab defaults; duplicate chords/highlight retained; `ukelele` exact. New-session import invalidates old calculations/drafts. Add SEND filter only, no guessed ACTION_VIEW origin.

### A20 — confirmed-origin share and old-web round trips

**Depends on:** A19; **confirmed canonical web origin/path is mandatory here**. **Files:** AP `links/ShareLauncher.kt`, `links/ShareConfig.kt`; AT `links/ShareLauncherTest.kt`; AI `links/ShareIntentTest.kt`, `links/LegacyRoundTripTest.kt`; create `app/src/main/res/values/share_config.xml`, `docs/sharing.md`; modify AP `ui/MainScreen.kt`, `di/AppContainer.kt`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.links.ShareLauncherTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.links.ShareIntentTest,dev.ironjanowar.fretboard.links.LegacyRoundTripTest`.

Test ACTION_SEND/text/plain/EXTRA_TEXT chooser and copy link carry Rust canonical URL only; no modal draft, tokens or Android snapshot JSON leaks. Defaults omitted, `#` percent-encoded, plus/space reference compatibility, ordered duplicates and highlight survive. URLs imported from and emitted to the actual web decoder round-trip on all five instruments. Native fixture tests assert query values, not a guessed host. Inspect resulting full URL against confirmed HTTPS origin/path. If host unresolved, do not invent it, disable sharing with explicit explanation in interim APK and keep A20/P6 gate incomplete; paste and SEND import continue working.

### A21 — App Links decision and complete lifecycle integration

**Depends on:** A20. **Files:** modify `docs/sharing.md`, `docs/phase-gates.md`, `app/src/main/AndroidManifest.xml`, AP `links/IncomingIntentParser.kt`, AI `links/ImportIntentTest.kt`, `lifecycle/RestoreLifecycleTest.kt`.

Only enable verified HTTPS `ACTION_VIEW` after domain owner provides `assetlinks.json` for persistent certificate/application ID; website publishing is an external prerequisite, not code to implement here. If unavailable, explicitly defer verified association without blocking paste/SEND/share parity. Add no wildcard host filters. Tests cover chosen configuration and ACTION_VIEW only if configured. Run exact relevant instrumentation commands from A18/A19. Where enabled, verify with `adb shell pm get-app-links dev.ironjanowar.fretboard` and a real URL open; report actual verified status rather than manifest presence. Reinstallation with another signer must never be the test shortcut.

**P6 gate:** seed nondefault Low G and piano states separately, share/open in browser/import again, force-stop/relaunch, rotate, reject malformed envelope without losing current state, import partially malformed compatible fields, cold/warm SEND, cancel draft then restart, airplane-mode everything. Upgrade the previously installed signed phase APK in place and retain state. User approval required; no unresolved production share origin.

## 11. P7 — complete offline release audit

### A22 — boundary and release guardrails

**Depends on:** P6 approval. **Files:** create `scripts/check_boundaries.py`, `scripts/tests/test_check_boundaries.py`, `scripts/check_release.py`, `scripts/tests/test_check_release.py`, `.github/workflows/android.yml`, `docs/release-checklist.md`; modify `app/build.gradle.kts`, `app/proguard-rules.pro`, `engine/consumer-rules.pro`, `docs/development.md`.

**Commands:** `python3 -m unittest discover -s scripts/tests -p 'test_check_*.py' -v`; `python3 scripts/check_boundaries.py`; `python3 scripts/check_release.py`.

RED cases detect app imports of generated bindings, Kotlin music calculation/catalog tables, sibling Rust source dependencies, mutable release pins, committed vendor binaries/secrets, unfinished feature flags/placeholders, wrong package and missing required test assets. Static rule checks are guardrails plus review, not proof that arbitrary Kotlin cannot contain musical logic. CI performs fresh preparation, strict dependency verification, JVM/lint, emulator native/Compose tests and release smoke on the selected ABI/SDK matrix. CI signing secrets only from trusted protected configuration; pull requests do not get secrets. Enable release shrinking only after real native binding loading is tested; keep required runtime/FFI rules narrowly justified.

### A23 — frozen full-parity fixture replay

**Depends on:** A22 and approved core differential corpus. **Files:** six parity JSON assets and `provenance.json` from manifest; AT `session/FullSessionRegressionTest.kt`; AI `release/OfflineParityTest.kt`; modify AT `support/EngineFixtureFactory.kt`, EI native test files where new fixture coverage is needed, and `docs/parity-matrix.md`.

**Commands:** `./gradlew :app:testDebugUnitTest --tests dev.ironjanowar.fretboard.session.FullSessionRegressionTest`; `./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=dev.ironjanowar.fretboard.release.OfflineParityTest`.

Replay every frozen catalog entry and web event family, extended/incomplete chord result ordering, tuning reference, duplicated identity/color, relative grouping, multi-key membership, all five instruments and legacy codec acceptance/rejection. Expected data provenance references actual web capture and approved core release; no generated expected-equals-actual tests. Assert coverage matrix has no unmapped rows, no stage placeholders, no unapproved discrepancy, and no network access required. Include long action sequences with interleaved import, drafts, clears and instrument/tab switches; every asserted musical result comes from independent approved fixtures, not FakeNativeBindings calculation.

### A24 — release-native, accessibility and upgrade tests

**Depends on:** A23. **Files:** AI `release/AccessibilityAuditTest.kt`, `release/UpgradeSmokeTest.kt`, `release/ReleaseNativeLoadingTest.kt`; modify `app/build.gradle.kts`, `engine/build.gradle.kts`, `docs/release-checklist.md`.

Build files support explicit instrumentation `testBuildType` selection so the real signed/minified release can be tested, not just debug:

```bash
./gradlew :app:assembleRelease
./gradlew :app:connectedReleaseAndroidTest :engine:connectedReleaseAndroidTest -PtestBuildType=release
```

Assert minified native loader and bindings work on actual device/emulator ABIs; target API/16KB-page requirements checked on appropriate environment; strict offline behavior, no accidental network/audio/account permissions. Accessibility test checks labels, selected state, separate remove/highlight, focus return, large text, landscape and reachable black keys/open/fret-24 cells. Supplement semantics with actual TalkBack and pointer manual use. `UpgradeSmokeTest` compares seeded durable state after installation of newer same-signer APK; host/manual sequence installs previous APK, seeds/save-acknowledges, `adb install -r` current APK and verifies all fields. Never assert an instrumentation-only recreation proves install/upgrade/process death.

### A25 — clean-checkout reproducibility and final delivery

**Depends on:** A24. **Files:** update `README.md`, `CHANGELOG.md`, `docs/development.md`, `docs/phase-gates.md`, `docs/release-checklist.md`, `core-release.lock.json` only if an explicitly approved core release upgrade is required (then repeat impacted gates).

From a clean checkout with no sibling core sources, run preparation online, verify exact release/hash, build; then preparation offline and build with cached dependencies. Run all scripts, unit/lint, real binding/Compose instrumentation and signed release checks. Compare pinned inputs, package/version/signer/ABI and parity results; byte-for-byte APK reproducibility is not claimed without measured evidence. Export actual APK/checksum/core lock/tool versions/review results and secure R8 mapping. README remains user-oriented; setup/architecture belongs in development docs. No unapproved web/iOS implementation, source copying, new feature gestures or data/library features.

**P7 final gate:** full OnePlus offline checklist, all instruments/modes/presets/quality/scale/progression catalogs, duplicates, analyzer bass/inversions/incomplete notes, relative/multi-key cards, restore/share/import, process death, upgrade and accessibility; install via normal package installer too. Record actual API/build fingerprint, signer continuity and versionCode increase. Independent reviewer and user both approve. Only then call full Android parity complete.

## 12. Stop conditions and handoff

Stop and report, rather than inventing working output, when: core AAR not published/checksum unknown; generated contract missing required view data; host unknown at share gate; tool/SDK incompatibility; native loader/ABI/page-size fault; signing identity lost; baseline fixtures disagree; full import rejection mutates state; stale result becomes current; or any manual phase approval is absent. Fix through the responsible core/platform task and rerun the phase.

No implementation was performed while writing this plan. The requested deliverable for this planning turn is these Markdown documents; the commands above are future acceptance procedures, not test results.
