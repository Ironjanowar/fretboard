# Async Key Suggestions

## Problem
Computing `Music.suggest_keys/1` in `handle_params` blocks the LiveView process, causing visible lag when adding/removing chords (especially removing, which triggers a full URL patch + recompute).

## Solution
Use `assign_async/3` from Phoenix LiveView 1.1.30 to compute key suggestions asynchronously. The UI shows a loading state while the computation runs in a Task, then renders the results when ready.

## Changes

### 1. fretboard_live.ex — handle_params

Replace synchronous computation:
```elixir
key_suggestions = if length(active_chords) >= 2, do: Music.suggest_keys(active_chords), else: []
```

With async:
```elixir
socket
|> assign_async(:key_suggestions, fn ->
  chords = active_chords  # capture before entering Task
  if length(chords) >= 2 do
    {:ok, %{key_suggestions: Music.suggest_keys(chords)}}
  else
    {:ok, %{key_suggestions: []}}
  end
end)
```

IMPORTANT: Do NOT pass `socket` into the async function — capture `active_chords` as a local variable first (per LiveView docs anti-pattern warning).

### 2. fretboard_live.ex — mount

Initialize `key_suggestions` as `AsyncResult.loading()`:
```elixir
alias Phoenix.LiveView.AsyncResult
key_suggestions: AsyncResult.loading()
```

### 3. fretboard_live.ex — render

The `@key_suggestions` assign is now an `AsyncResult` struct, not a plain list. Update the template:

- `@key_suggestions.loading` → show a small spinner/loading indicator
- `@key_suggestions.ok?` → access `@key_suggestions.result` which is the actual list
- `@key_suggestions.failed` → show error state (unlikely but should handle)

Use `<.async_result>` component or manual conditionals:
```heex
<.async_result :let={key_suggestions} assign={@key_suggestions}>
  <:loading>
    <div class="key-suggestions-wrapper">
      <label class="section-label" style="width:100%">Tonalidades compatibles</label>
      <p class="text-muted">Calculando...</p>
    </div>
  </:loading>
  <:failed :let={_failure}>
    <div class="key-suggestions-wrapper">
      <label class="section-label" style="width:100%">Tonalidades compatibles</label>
      <p class="text-muted">Error al calcular tonalidades.</p>
    </div>
  </:failed>
  <%!-- existing rendering logic, but using key_suggestions variable --%>
</.async_result>
```

### 4. fretboard_live.ex — group_key_suggestions

`group_key_suggestions/1` currently receives the flat list. Now it needs to receive `@key_suggestions.result` (the list inside the AsyncResult). The function itself doesn't change — just the caller passes `key_suggestions.result` instead of `key_suggestions`.

### 5. show_key_modes reset

Currently `show_key_modes: false` is set in handle_params. This is fine — it resets when chords change. The async result will also be reset (loading → ok) on each handle_params.

### 6. CSS

Add a simple loading indicator style:
```css
.key-suggestions-loading {
  color: #6b7280;
  font-size: 0.875rem;
  padding: 0.5rem 0;
}
```

### 7. Tests

Update existing tests:
- Tests that check `@key_suggestions` directly need to account for AsyncResult wrapper
- In LiveView tests, the async operation may need `render_async` or just waiting for the result
- Actually, in LiveView tests the async task runs synchronously in test mode (Task.async → Task.await), so `@key_suggestions` should resolve immediately. Verify this.
- If tests break because of AsyncResult, update assertions to use the result field.

## Files to modify
- lib/fretboard_web/live/fretboard_live.ex
- priv/static/assets/css/app.css
- test/fretboard_web/live/fretboard_live_test.exs

## Notes
- `assign_async` only starts the task when the socket is connected (not in test mount). In tests, LiveView runs synchronously so async results should be available immediately.
- Do NOT pass socket into the async function (anti-pattern). Capture needed values as locals.
- The `AsyncResult` struct has fields: `loading` (boolean), `ok?` (boolean), `failed` (boolean), `result` (the value or nil).