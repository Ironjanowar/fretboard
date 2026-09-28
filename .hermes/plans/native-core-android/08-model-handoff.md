# Model Selection and Implementation Handoff

## Recommendation as of 2026-09-28

Start with **DeepSeek V4.1 Flash**, using official API model ID `deepseek-flash`. The current official pricing page states that the old V4 Flash model is retired; requests to `deepseek-v4-flash` are served by V4.1 Flash at the Flash price. On that API, choosing the old name is therefore not a cheaper independent model choice.

Official source: <https://api-docs.deepseek.com/quick_start/pricing/>. Recheck immediately before implementation; third-party providers may have different model revisions and prices.

Per million billed tokens, USD:

| Token type | Off-peak | Peak |
|---|---:|---:|
| Input, cache hit | 0.003 | 0.006 |
| Input, cache miss | 0.15 | 0.30 |
| Output | 0.60 | 1.20 |

Official peak hours: 01:00–04:00 and 06:00–10:00 UTC, Monday–Friday; all other hours off-peak. No price/performance claim here assumes cache hits. Example calculated workload of 10 million uncached input tokens + 2 million output tokens costs **$2.70 off-peak or $5.40 peak** at these rates. This is arithmetic for a hypothetical workload, NOT an estimate of this project's total tokens or a price quote. Retries, paid tools/CI, reviews with another model, and any provider markup add cost; reasoning usage must be accounted for according to actual billing.

No local benchmark has established V4.1 Flash's quality on this project. Vendor benchmark scores are not proof of correct Rust FFI, musical semantics or usable Android UI. The value test is accepted work per total spend, not cheapest output token.

## P1 pilot and escalation

Measure one real vertical slice end to end:

- Frozen task brief; actual Rust calculation plus generated Kotlin binding, Compose action, native-library packaging and installed APK.
- Tokens/cost from provider usage, wall time, number of failed builds/retries, human corrections, reviewer defects, and whether phone acceptance passed.
- Include a semantic edge case and a native-loading test, not a hello-world screen with hard-coded output.
- A cheap model may implement narrow tasks successfully while still needing a stronger independent architecture/security reviewer. Model availability must be checked; never claim a different model was used when delegation inherited the current model.

Escalate when the same root issue survives two focused repair attempts, a change crosses agreed boundaries, native packaging becomes guesswork, or tests are being weakened to accommodate implementation. Reduce task scope or ask a stronger model for diagnosis; do not silently change architecture. Two retries is a workflow guardrail, not a quality benchmark.

## Orchestration roles

1. **Coordinator:** reads current task and contract, assigns exclusive files, resolves dependencies, runs reported checks itself, records phase ledger. Does not ask one agent to both declare requirements and self-certify them.
2. **Test writer:** writes one small contract slice, executes RED and reports the intended failure. Import/build failures count only when the planned task is API/bootstrap creation, not as proof of behavioral coverage.
3. **Implementer:** implements minimum production changes, runs focused GREEN then relevant regressions. Must not change expected outputs or delete tests without coordinator approval.
4. **Reviewer:** independently checks specification compliance and code quality, runs tests, inspects diff. Verifies domain/UI separation and real FFI use.
5. **Final quality reviewer:** at phase boundary checks cross-task integration, full suites, security/accessibility, artifact contents and disclosed limitations.
6. **User:** approves the actual installed APK before the next dependent phase.

Use fresh contexts per role. Parallelize only disjoint files and independent behavior; catalog schema, FFI transport types, Gradle root files, generated binding package and shared session reducer each have exactly one owner. Do not dispatch implementers for tests that have not produced verified RED.

## Small-task execution contract

Each task in the core/Android documents must be expanded to a task card before dispatch. One card should usually own a test plus a small implementation file or coherent pair—not an entire phase. Bootstrap/catalog import tasks can be larger mechanical steps but must validate their complete inventories.

```markdown
# Task <ID>: <one behavior>
Repository / branch / starting commit:
Phase and already-approved dependencies:
Read first: <specific plan section + existing sources>
Allowed files: <exact create/modify paths>
Do not edit: <neighbor files, lockfiles unless assigned, generated output>
Public API/types: <frozen signatures or contract IDs>
Inputs and outputs: <concrete fixtures, ordered results, error cases>
Acceptance: <test assertions and user-visible behavior>
RED command and expected reason:
GREEN command and expected result:
Regression commands:
Manual step if required:
Return: diff summary, real commands/output, blockers, changed files.
```

Run commands from the named repository. "Expected PASS" is a planned assertion, not a log. Never paste expected output into a report as if executed.

## Prompt for a test writer

```text
Implement only the tests for TASK_ID. Read the attached exact contract and baseline
fixtures. Do not create production behavior, weaken assertions, or invent oracle
values. Work only in ALLOWED_TEST_FILES. Run the precise test command. Show the
actual failure and explain why it proves the specified behavior is missing.
If prerequisites do not build, report that separately and stop. Return changed
paths and output, not claims that an APK works.
```

## Prompt for an implementer

```text
Implement TASK_ID in ALLOWED_PRODUCTION_FILES to satisfy the existing RED tests.
Use the approved core/session/wire contracts. No placeholder calculations, remote
fallback, hard-coded fixture lookups, generated-binding edits, or UI-side musical
logic. Keep functions short. Do not weaken tests or update golden outputs.
Run focused tests and listed regressions. If an API/tool version differs from the
plan, consult pinned official docs and report a contract amendment before changing
shared files. Return actual test output and remaining limitations.
```

## Prompt for a reviewer

```text
Independently review TASK_ID against the named plan sections and actual diff.
Check correct ownership, full negative cases, real native-library use, deterministic
ordering, integer bounds and error behavior. Run tests yourself. Look for tests
that prove mocks only when real integration is required. Report blockers with file
and line, then nonblocking improvements. Do not approve on implementation prose.
```

## Context packaging

Send the task card, relevant contract excerpts, exact file contents, frozen fixture subset, actual test error, and dependency versions. Do not repeatedly include the entire roadmap or every progression catalog entry for a UI task. Stable shared instructions may benefit caching, but never let cached context override changed source or task decisions.

Maintain a small `docs/implementation-ledger.md` in each new repository, authored by the coordinator: completed task IDs, commits, next dependency, approved deviations and current core/app pairing. Plans remain authoritative; a compressed summary cannot override them.

## Test and commit policy

- RED → minimal GREEN → refactor → focused regression → independent review → commit.
- Commit only the owned reviewed paths. Do not use `git add .` around generated APKs, secrets, fixture dumps or unrelated artifacts.
- Core changes land via core PR; publish candidate version; Android lock bump + UI changes land via Android PR. Merge requires user approval.
- No task may broaden scope to iOS, Rustler, WASM, audio, accounts, telemetry or Play Store.
- After each phase, stop for user validation even if another task is easy to start.

## Definition of model failure

A tool/install/network failure is not automatically a model failure; record infrastructure separately. A model failure includes invented API/version/output, silent semantic changes, fake FFI integration, claiming an untested device works, modifying expected fixtures to match incorrect implementation, or ignoring exclusive file ownership. Correct the root cause before further delegation.

## Handoff checklist

- [ ] Relevant architecture/defect decisions approved.
- [ ] Pinned oracle and current repository commits supplied.
- [ ] Exact files and test commands identified.
- [ ] No unresolved generated-signature assumptions.
- [ ] Agent model/provider explicitly known and recorded.
- [ ] Budget/usage logging enabled without exposing keys.
- [ ] Real review and APK approval gates still enforced.
