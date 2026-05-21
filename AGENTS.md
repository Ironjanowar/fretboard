# AGENTS.md — Fretboard Development Guide

## Project Overview

**Fretboard** is a web app for visualizing chord notes across a guitar fretboard, built with Phoenix LiveView and SVG rendering.

**Repo:** <https://github.com/Ironjanowar/fretboard>

## Tech Stack

| Dep | Purpose | Version |
|---|---|---|
| Elixir | Language | 1.19.5 |
| Erlang/OTP | Runtime | 27 |
| Phoenix | Web framework | 1.8.7 |
| Phoenix LiveView | Real-time UI | 1.1.30 |
| Bandit | HTTP server | 1.11.1 |
| Jason | JSON encoding | 1.4.5 |

No Ecto — all state lives in the LiveView process.

## Project Structure

```
lib/
├── fretboard/
│   ├── application.ex       # OTP application
│   └── music/
│       ├── music.ex          # Public API facade (Fretboard.Music)
│       ├── note.ex           # 12 chromatic notes, note_at/2 calculation
│       ├── chord.ex          # Chord formulas, chord_notes/2
│       └── tuning.ex         # Standard + custom tunings
└── fretboard_web/
    ├── live/
    │   └── fretboard_live.ex # Main LiveView (state + SVG rendering)
    ├── components/           # HEEx components
    ├── controllers/          # Error handlers
    ├── endpoint.ex
    └── router.ex
test/
├── fretboard/
│   └── music/                # Unit tests for domain logic
└── fretboard_web/
    └── live/                 # LiveView tests
```

## Architecture Boundaries

- **`Fretboard.Music`** is the public API facade for all music domain logic
- **The web layer (`FretboardWeb`) calls only `Fretboard.Music`** — never `Music.Note`, `Music.Chord`, or `Music.Tuning` directly
- **`Music.Note`, `Music.Chord`, `Music.Tuning`** are internal modules — implementation details of the `Music` context
- Domain modules must not depend on Phoenix or any web concern

## Philosophy: Test-Driven Development (TDD)

**Tests first. Always.**

1. Write a failing test that describes the desired behavior
2. Write the minimum code to make it pass
3. Refactor with confidence — tests catch regressions

### Workflow with Sub-agents

All implementation **must** use sub-agents to keep the main session context clean:

1. **Sub-agent 1 (Test Writer):** Writes the failing test for the desired behavior. Verifies it fails with `mix test`. Reports back.
2. **Sub-agent 2 (Implementer):** Implements the minimum code to make the test pass. Runs `mix test` to verify. Reports back.
3. **Sub-agent 3 (Reviewer):** Reviews the code for quality, runs the full test suite (`mix test`), checks formatting (`mix format --check-formatted`), and verifies everything is clean.

Only after all three steps succeed does the code get committed.

## Commands

```bash
# Essentials
mix compile                    # Compile
mix test                       # Run all tests
mix test test/fretboard/       # Run domain tests only
mix test test/fretboard_web/   # Run web tests only
mix test path/to/test.exs:42   # Run specific test at line
mix format                     # Auto-format
mix format --check-formatted   # Format check (CI mode)
mix credo --strict             # Lint with strict mode
mix precommit                  # Full check: compile + format + test

# Running
mix phx.server                 # Start dev server
iex -S mix phx.server          # Start with IEx shell

# Dependencies
mix deps.get                   # Fetch deps
mix deps.compile               # Compile deps
```

## Elixir Coding Conventions

### Naming
- `snake_case` for functions, variables, modules (files)
- `PascalCase` for module names
- `SCREAMING_SNAKE_CASE` not used in Elixir — use module attributes (`@constant`)
- Descriptive names: `note_at(tuning, string, fret)` not `get(t, s, f)`
- Boolean functions end with `?`: `overlap?/1`

### Module Organization
- Module attributes and `use`/`import`/`alias` at the top
- Public functions before private functions
- Group related functions together
- `@doc` on all public functions
- `@moduledoc` at the top of every module

### Pattern Matching
- Prefer pattern matching over conditionals
- Use guard clauses to narrow function heads
- Destructure in function arguments when practical

### Error Handling
- Use tagged tuples: `{:ok, result}` / `{:error, reason}`
- Use `with` for chaining operations that can fail
- Let it crash for truly unexpected errors — OTP will recover
- No silent error swallowing

### Pipes
- Use `|>` for data transformation pipelines
- First argument should be the data being transformed
- Each step in a pipeline should do one thing

## Testing Approach

| Layer | Strategy |
|-------|----------|
| Music.Note | Note calculation, chromatic scale, wraparound at 12 semitones |
| Music.Chord | Formula application, all qualities produce correct notes |
| Music.Tuning | Standard tuning values, custom tuning construction |
| Music (facade) | `fretboard_data/2` returns correct structure, chord highlighting, overlaps |
| LiveView | Mount assigns correct defaults, events update state, SVG renders |

### Testing Principles

- **One assertion concept per test**
- **Descriptive test names**: `test "note_at returns F for standard E string at fret 1"`
- **No test interdependence** — each test sets up its own state
- **Use `describe` blocks** to group related tests

### Test Naming Convention

```elixir
describe "note_at/2" do
  test "returns the open string note at fret 0" do
    ...
  end

  test "wraps around after 12 frets" do
    ...
  end
end
```

## Formatting

Use default `mix format` settings. No custom `.formatter.exs` overrides unless necessary.

Run `mix format --check-formatted` before every commit.

## Git Workflow

- **Commit messages**: imperative mood, concise (`Add chord formula calculation`, not `Added stuff`)
- **One logical change per commit** — don't mix refactoring with feature work
- **Run `mix test` and `mix format --check-formatted` before committing**
- **Don't commit broken tests** — if a test is WIP, use `@tag :skip`

## Boundaries

### ✅ Always
- Write tests before implementing (TDD)
- Use sub-agents for implementation (test → implement → review)
- Run `mix test`, `mix format`, and `mix credo --strict` before pushing
- Document public APIs with `@doc`
- Keep domain logic in `Fretboard.Music`, web logic in `FretboardWeb`
- Call only the `Fretboard.Music` facade from the web layer

### ⚠️ Ask First
- Adding new dependencies to `mix.exs`
- Changing the public API of `Fretboard.Music`
- Structural changes to the LiveView state

### 🚫 Never
- Call internal `Music.*` modules from `FretboardWeb`
- Skip tests for "trivial" changes
- Commit code that doesn't compile or has failing tests
- Add Ecto or database concerns (v1 is stateless)
