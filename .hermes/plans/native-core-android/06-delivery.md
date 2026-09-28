# Toolchains, Artifact Delivery, Signing, and CI

## P0: prerequisite discovery, not blind installation

Own these integration tasks separately from music/UI tasks. Commands below are future implementation verification commands unless explicitly called observations. Do not run a release workflow merely to validate this plan.

### D00 — inventory and lock compatible tools

**Files, core:** `rust-toolchain.toml`, `Cargo.toml`, `Cargo.lock`, `android/gradle/libs.versions.toml`, `android/gradle/wrapper/gradle-wrapper.properties`, `android/gradle/verification-metadata.xml`, `docs/toolchains.md`.

**Files, Android:** `gradle/libs.versions.toml`, `gradle/wrapper/gradle-wrapper.properties`, `gradle/verification-metadata.xml`, `docs/toolchains.md`.

1. Inventory `rustc --version`, `cargo --version`, `java -version`, `adb version`, `sdkmanager --list`, available disk and Android emulator/KVM support. Missing tools are blockers to builds, not missing application features.
2. Consult official Rust, Android Gradle Plugin, Kotlin/Compose compiler, Android SDK and UniFFI compatibility documents. Select stable mutually compatible versions. Provisional product floor: minSdk 26; verify Compose/runtime and NDK compatibility before accepting it. Choose compileSdk/targetSdk from supported stable SDK releases, not from OxygenOS branding.
3. Install tools using verified official distributions and record versions/checksums. Do not run unreviewed web scripts or globally change unrelated project toolchains. Accept Android SDK licenses interactively as required; do not fabricate acceptance.
4. Generate Gradle wrapper with Gradle tooling. Commit wrapper scripts, properties, and the genuine wrapper JAR; set distribution checksum. Never ask a text model to synthesize a JAR.
5. Pin Rust toolchain, Cargo dependencies/lock, UniFFI generator/runtime versions, cargo-ndk version, NDK revision, Java/Gradle/AGP/Kotlin/Compose versions, SDK packages and AndroidX dependencies. No `+`, `latest`, floating git branches, or unbounded version ranges in release builds.
6. On phone: `adb shell getprop ro.build.version.sdk`, `adb shell getprop ro.product.cpu.abilist`, `adb shell getprop ro.build.fingerprint`. Record actual output with sensitive identifiers excluded. If USB/wireless adb is unavailable, user installation is still possible but instrumented-device evidence remains separate.

**Acceptance:** committed compatibility ledger; clean tools smoke build; emulator runs or blocker explicitly recorded; supported phone ABI known; user agrees to minimum API if it affects device coverage. No full port until D00 and P1 pass.

### D01 — single coherent Android engine artifact

**Files, core:** `android/settings.gradle.kts`, `android/build.gradle.kts`, `android/gradle.properties`, `android/engine/build.gradle.kts`, `android/engine/src/main/AndroidManifest.xml`, `android/engine/consumer-rules.pro`, `scripts/build-android.sh`, `scripts/package-aar.sh`, `scripts/check-aar.py`, `scripts/tests/test_check_aar.py`, `.github/workflows/ci.yml`, `.github/workflows/release-android.yml`, `docs/android-artifact.md`.

**Generated, core:** `target/`, `android/engine/build/generated/`, `android/engine/build/outputs/aar/`, JNI input directories under `android/engine/build/`; keep generated bindings and binaries out of manually maintained source.

1. Test `check-aar.py` on tiny synthetic ZIP fixtures: reject missing ABI, duplicate unexpected `.so`, absent binding classes, and metadata/version mismatch. Synthetic packaging fixtures are tests, never passed off as a working engine.
2. Build actual Rust `fretboard-mobile-ffi` as `cdylib` for `aarch64-linux-android` and `x86_64-linux-android`. Set NDK minimum API consistently with app minSdk. Add `arm64-v8a` for phone and `x86_64` for emulator; do not claim 32-bit support.
3. Generate Kotlin bindings using the same pinned UniFFI version and built-library metadata; use the committed `uniffi.toml` package configuration. Generate on a host-supported metadata build where needed, never execute an Android `.so` on Linux host.
4. Compile generated bindings into one AAR containing `jni/arm64-v8a/` and `jni/x86_64/` libraries. Include consumer shrinker rules. The wrapper and native libs must be one coordinated build.
5. UniFFI's Kotlin runtime dependency (commonly JNA) is NOT magically embedded by a bare local AAR. Record the exact runtime coordinates/version in artifact metadata; declare them explicitly in the consumer engine module or distribute verified Maven metadata. This plan chooses explicit consumer dependencies and a single local AAR.
6. Build with current NDK/linker support for 16 KB page-size devices; verify both ELF segment alignment and APK packaging alignment. A successful 4 KB emulator run is insufficient evidence. Test a 16 KB environment when available, or report the release limitation without claiming support.
7. Run host domain tests, native smoke tests on emulator, and the real-device P1 smoke. Inspect the AAR and APK, not just a Cargo success message.
8. Release asset name: `fretboard-engine-<version>.aar`. Publish alongside `artifact-manifest.json` and `SHA256SUMS`; metadata records source SHA, tool versions, UniFFI runtime dependency, API/schema version, ABIs/minSdk, and licenses. Never overwrite an existing version's bytes.

Build script interfaces to implement and test:

```sh
# From fretboard-core; scripts do not exist until their planned task is implemented.
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
./scripts/build-android.sh
./scripts/package-aar.sh --version "$CORE_VERSION"
python3 scripts/check-aar.py --aar "dist/fretboard-engine-$CORE_VERSION.aar" --manifest dist/artifact-manifest.json
```

Expected result: nonzero on any error; real AAR with both ABI libraries and generated classes; manifest matches contents. Exact internal cargo-ndk/bindgen invocation is pinned and exercised in P1, then captured in these scripts.

### D02 — verified Android consumption

**Files, Android:** `engine/core-artifact.lock.json`, `scripts/fetch-core.py`, `scripts/tests/test_fetch_core.py`, `engine/build.gradle.kts`, `.gitignore`, `docs/core-updates.md`.

Proposed lock contract (schema, not fabricated values): `version`, `sourceCommit`, `assetUrl`, `sha256`, `uniffiVersion`, `runtimeDependencies`, `minSdk`, `abis`, `schemaVersion`. Resolve real values from the core release before committing. An unfilled lock must fail closed.

1. Test bad checksum, missing asset, version mismatch, interrupted download, and path traversal/unsafe destination. Download to temporary path, verify bytes, atomically promote into ignored `vendor/`.
2. Implement explicit preparation command; Gradle fails with an actionable missing-artifact message rather than silently fetching a floating engine.
3. Public release assets can be fetched without a token. If private, use an existing scoped GitHub credential/CI secret via supported API; never embed credentials in the lock or URL. Repository visibility is discovered in P0.
4. Configure Gradle `engine` module to expose generated types only through its own adapter. Ordinary app JVM tests fake the engine port; Android instrumentation tests call actual native libraries.
5. Package exact runtime dependency from the lock; fail if Gradle resolves a conflicting version. Add dependency verification and review licenses.
6. For a core update: publish core candidate → update lock via Android PR → regenerate/check adapter API → run unit/instrumented/real-device regression → approve. Never merge an engine version bump just because download succeeded.

```sh
python3 -m unittest discover -s scripts/tests
python3 scripts/fetch-core.py --lock engine/core-artifact.lock.json
./gradlew --no-daemon :engine:testDebugUnitTest :app:testDebugUnitTest :app:lintDebug :app:assembleDebug
./gradlew --no-daemon :app:connectedDebugAndroidTest
```

## D03 — persistent signing from the first shared APK

**Files, Android:** `app/build.gradle.kts`, `.gitignore`, `docs/signing.md`, `scripts/verify-apk.sh`, `scripts/release-evidence.py`, `.github/workflows/release.yml`.

- Proposed stable application ID: `dev.ironjanowar.fretboard`; confirm before P1 signing and never change to fix an update problem.
- Use a dedicated persistent experiment release key, not a newly generated ephemeral CI debug key. Generate/store it through an approved secure local workflow. Never put private key material/passwords in chat, plan, git, build log or release artifact.
- Resolve key custody and backup with user in P0. Configure CI secrets/environment approval separately; PRs from untrusted forks must not receive signing secrets. No automatic secret creation in this planning task.
- Release builds may read signing inputs from environment/secure files; missing secret means build/release failure, not fallback to a different signer.
- Assign monotonically increasing `versionCode` for EVERY APK distributed, including corrected candidates in the same phase. Human-readable `versionName` includes phase/candidate; record in release evidence.
- Build signed release APKs with `assembleRelease`, not Android Studio Run's potentially adb-only `testOnly` APK. Verify with the installed build-tools `apksigner verify --verbose --print-certs`, APK manifest inspection, and `zipalign` checks appropriate to 16 KB native libraries.
- Before release, scan packaged permissions: no INTERNET, storage-wide, microphone or account permissions unless a separately approved feature requires them. Clipboard paste/share and ACTION_SEND do not require these permissions.
- Test update by installing P1 candidate, changing session, then `adb install -r <next.apk>` and opening it. Same package + same signing certificate + increasing code + schema migration must hold. Never ask the user to uninstall as the normal update procedure.
- Prevent debug backup/analytics leakage. Decide Android auto-backup explicitly; default this experiment to `android:allowBackup="false"` to avoid unexpected cloud copies of sessions. Store only canonical state, not clipboard history.

## D04 — CI stages and artifact verification

### Core CI

- PR: format, lint, unit/golden/property tests, dependency/license checks, FFI generation compile, AAR inspection; expensive emulator jobs can use changed-path conditions only if required integration coverage remains.
- Tag/release: rebuild from reviewed commit, run checks, publish immutable candidate assets. A tag alone never proves approval.
- Grant `contents: read` normally; `contents: write` only in the approved release job. Pin third-party Actions to reviewed commit SHAs and keep update automation explicit.

### Android CI

- PR: artifact-lock validation, script tests, JVM tests, lint, dependency verification, debug APK, emulator instrumentation including real Rust loading. No release secrets.
- Approved release: protected/manual workflow builds signed APK from exact reviewed commit. Attach test evidence, APK, checksum, signer fingerprint (public), core lock and license notices. No keystore.
- Start GitHub Releases as prerelease candidates. Manual phone approval promotes documentation/status; do not label a candidate stable before approval.

### Verify after publishing

1. Read exact release by tag through GitHub API/CLI.
2. Verify target commit and expected asset names.
3. Download the published AAR/APK to a clean temporary directory, recompute checksum and verify it equals the local attested artifact.
4. Verify APK signer and install downloaded APK, not merely the local pre-upload copy.
5. Record URLs, asset IDs and evidence in phase ledger. A successful upload response alone is not a completed release.

## D05 — rollback and failure paths

- Core: restore last known good lock in Android and rebuild with a higher app versionCode. Never replace bytes behind an existing release tag.
- Android: distribute previous known-good code as a new higher-version candidate with the same signing key; do not rely on downgrade installation.
- Session: schema read migration occurs before replacement; corrupt/unsupported saved data yields an explicit recovery path and default in-memory session, retaining a bounded recovery copy where appropriate. A failed external import must not overwrite a valid persisted session.
- Lost signing key: stop releases and tell user; a new key usually requires reinstall for sideloaded apps and may lose local data. This is why P0 key backup is mandatory.
- Missing CI minutes/emulator/SDK/network: record blocked gate; do not replace real tool output with plausible logs.

## P7 delivery checklist

- [ ] Core artifact immutable and verified after download.
- [ ] Android lock references actual approved core release.
- [ ] All required tests run on clean checkout.
- [ ] APK signer/manifest/ABIs/page alignment inspected.
- [ ] Same-key upgrade preserves session.
- [ ] Phone airplane-mode acceptance complete.
- [ ] All known deviations and unsupported environments disclosed.
- [ ] User has approved the exact APK checksum/phase.
