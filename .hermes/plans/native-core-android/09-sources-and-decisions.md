# Sources, Open Decisions, and Evidence Ledger

## Source hierarchy

1. User-approved decisions in [00-index](00-index.md).
2. Actual code/tests at frozen web commit `2daa8c665efa268942dda352691f39d78db42512` for current behavior.
3. Approved deviation records for deliberate changes from that baseline.
4. Official platform/tool documentation for integration mechanics and current provider prices.
5. README/AGENTS prose for intent, subject to reconciliation with current source.

`AGENTS.md` contains stale structure examples (`music/music.ex`, `tuning.ex`). Actual facade is `lib/fretboard/music.ex`; preset/tuning responsibilities live in `instrument.ex` and `pitch.ex`. README's 44 chord types is stale relative to source inspection. Do not reproduce these outdated descriptions in the new projects.

## Baseline source register

- `lib/fretboard/music.ex`: public web-facing music API.
- `lib/fretboard/music/note.ex`, `intervals.ex`, `pitch.ex`: pitch-class, label and absolute-height rules.
- `lib/fretboard/music/instrument.ex`: instrument IDs, string order, exact MIDI presets.
- `lib/fretboard/music/chord.ex`: quality/formula/label catalog, recognition and inversion rules.
- `lib/fretboard/music/scale.ex`: scale catalog, degree quality inference, key ranking and greedy multi-key coverage.
- `lib/fretboard/music/progression.ex`: progression catalog and resolution.
- `lib/fretboard/music/analyzer.ex`, `keyboard.ex`: pitch analysis and visualization memberships.
- `lib/fretboard/music/url_codec.ex`, `page_codec.ex`: legacy fretted and instrument-aware page contracts.
- `lib/fretboard_web/live/fretboard_live.ex`: transition rules, duplicate highlights, relative-mode grouping, async result lifecycle.
- `lib/fretboard_web/components/fretboard_svg.ex`, `piano_keyboard.ex`, `modals.ex`: visual order and selection behavior.
- `priv/static/assets/css/app.css`: actual baseline palette/styles.
- `test/fretboard/music/`, `test/fretboard/music_test.exs`, `test/fretboard_web/live/`: regression references; see verification matrix.

Freeze and record source commit before generating golden data. Updated upstream behavior requires an explicit oracle revision and review, not automatic fixture regeneration.

## Official references consulted during planning

Access date: 2026-09-28. URLs can change; capture version-specific references when locking tools.

- UniFFI overview and language support: <https://mozilla.github.io/uniffi-rs/latest/>. Generates bindings; explicitly does not solve distributing compiled libraries by itself.
- Kotlin/Gradle and JNA integration: <https://mozilla.github.io/uniffi-rs/latest/kotlin/gradle.html>. Some examples use older Gradle APIs; adapt to the pinned current AGP rather than blindly copying snippets. Select supported JNA version and Android AAR packaging in P1.
- Android native UI toolkit: <https://developer.android.com/jetpack>.
- Compose BOM and compiler distinction: <https://developer.android.com/develop/ui/compose/bom>. Compose BOM does not pin Kotlin/compiler. Kotlin 2.x Compose plugin tracks Kotlin; verify selected versions.
- APK generation and test-only build distinction: <https://developer.android.com/build/build-for-release>.
- Native page alignment: <https://developer.android.com/guide/practices/page-sizes>. Relevant to Rust/JNA native libraries even without Play Store distribution.
- Compose semantics: <https://developer.android.com/develop/ui/compose/accessibility/semantics>.
- Verified App Links: <https://developer.android.com/training/app-links/verify-applinks>. Requires host-served `/.well-known/assetlinks.json`; merely declaring an intent filter is insufficient.
- Future Elixir adapter, NOT current work: <https://github.com/rusterlium/rustler>.
- DeepSeek current model/pricing: <https://api-docs.deepseek.com/quick_start/pricing/>. Prefer current pricing page over older launch announcements if they disagree about retirement/routing.

## Decision gates discovered by source inspection

The user approved architecture/product scope, NOT the resolutions below. Keep these explicit in P0/affected phase review. Recommendations are not authorization to alter the web or oracle.

| ID | Issue | Recommendation | Required before |
|---|---|---|---|
| DEC-01 | `notes_with_intervals` zips notes and separately ordered labels; C9 can associate the wrong interval with a note | Compute each tone's pitch/interval/missing status together in Rust, keep observed legacy fixture separately, obtain approval for corrected native behavior | Chord detail/analysis acceptance P2/P3 |
| DEC-02 | Missing-note CSS class lacks visible styling in inspected stylesheet | Native explicit missing indicator, not color alone; approve expected screenshots | Incomplete-analysis UI P3 |
| DEC-03 | Multi-key card color uses occurrence index while chips use unique identity | Use one native identity-based palette policy everywhere; record deliberate web divergence | P5 |
| DEC-04 | Equal recognition sort keys inherit Elixir map enumeration order | Export exact observed ordering; define explicit stable rank compatible with pinned oracle or approve a deterministic tie-break deviation | Recognition P3 |
| DEC-05 | Current partial-match implementation does not require every candidate formula tone to be present | Preserve observed matching unless user explicitly approves algorithm correction; document terminology | Recognition P3 |
| DEC-06 | Baseline accepts potentially unbounded URL/chord list lengths | Add envelope/resource limits with visible rejection and no silent truncation; choose concrete caps after corpus review and approval | Public FFI/import boundaries |
| DEC-07 | Public deployed web origin absent from tracked docs; only localhost/example values found | Discover authorized deployment setting or ask user. Require exact approved HTTPS origin/path for release sharing. Do not ship an example hostname | Share release P6 |
| DEC-08 | Persistent release key custodian/secure storage not chosen | User-controlled backed-up key; approved CI secret setup only when implementing | P1 shared APK |
| DEC-09 | Repositories may be public/private; cross-repo artifact auth differs | Discover visibility, use least-privilege build-only credential if private; no on-device token | Artifact fetch P1 |
| DEC-10 | Minimum supported Android and exact dependency tuple not yet proven | Propose minSdk 26, arm64 phone + x86_64 emulator; lock compatible stable versions after actual smoke | P0/P1 |
| DEC-11 | Automatic verified web links require website file change, outside current scope | Ship explicit paste and ACTION_SEND import now; make verified App Links a separate authorized web/deployment change | P6 documentation |

A dependent feature may not be declared complete with its blocking decision unresolved. The plan itself is deliverable with these genuine future approval gates; it must not invent the user's answers.

## Future declaration files to create in new repos

- `AGENTS.md`: English-only, pure-domain boundaries, TDD roles, small functions/modules, generated-code prohibition, exact verified commands and PR approval rules.
- `docs/implementation-ledger.md`: completed tasks, version pairing, pending gates.
- Core `docs/decisions.md`: decision ID, baseline observation, approved result, approver reference, test/fixture path, compatibility consequence.
- Android `docs/validation/phase-P<N>.md`: actual automated/manual evidence, not copied expected outputs.
- Toolchain ledgers specified in delivery document.

## Planning evidence and limitations

- Parent inspected actual git branch/status/default ref and created the plan branch from remote `main`.
- Metadata reads confirmed both new core/Android repos accessible and empty. No source was pushed to those repositories in this planning task.
- Source-reading agents inspected domain, LiveView, components and tests. One agent reported domain test execution under newer installed Elixir/OTP; this is not certification under the repo's pinned runtime and is not native validation. Do not present it as the full project's baseline test pass.
- Parent directly verified source `notes_with_intervals` zip and PageCodec instrument/selection boundaries. Runtime behavior still needs frozen fixture exports during implementation.
- Official pricing and tool documentation were retrieved directly; cost example arithmetic was calculated with a tool.
- Current plan is subject to a separate consistency/path/link review before commit. Record actual outcome in PR rather than marking this statement as a completed check.

## Cleanup policy

Do not delete this plan after the first phase. It is the cross-repository implementation reference until the whole experiment is accepted. At final feature cleanup, follow the user's repository convention for removing the entire `.hermes/plans/` directory only when that cleanup is authorized; approved contracts and enduring developer documentation must already live in the relevant new repositories. Git history/PR preserves this planning artifact.
