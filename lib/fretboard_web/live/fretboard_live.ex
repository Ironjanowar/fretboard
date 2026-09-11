defmodule FretboardWeb.FretboardLive do
  @moduledoc """
  Main LiveView for the chord visualizer.

  Renders a fretboard SVG for fretted instruments (guitar, bass, ukulele)
  or a fixed piano keyboard for the piano instrument, with a configurable
  tuning for strings and chord-note coloring shared by both. Supports
  adding/removing chords and highlighting, plus an interactive note
  analyzer tab for fretted instruments.
  """

  use FretboardWeb, :live_view

  import FretboardWeb.FretboardSVG, only: [fretboard_svg: 1, analyzer_fretboard_svg: 1]
  import FretboardWeb.PianoKeyboard, only: [piano_keyboard: 1]
  import FretboardWeb.Modals
  import Phoenix.LiveView.JS, only: [toggle: 1]

  alias Fretboard.Music
  alias Phoenix.LiveView.AsyncResult

  @fret_count 24
  @marker_frets [3, 5, 7, 9, 12, 15, 17, 19, 21, 24]
  @double_marker_frets MapSet.new([12, 24])

  # SVG layout constants
  @left_margin 60
  @top_margin 40
  @fret_width 50
  @string_spacing 20

  @chord_colors [
    "#4FC3F7",
    "#FF8A65",
    "#81C784",
    "#BA68C8",
    "#FFD54F",
    "#4DB6AC",
    "#F06292",
    "#7986CB"
  ]

  # The 7 diatonic modes that share the same note set (e.g. C major = A minor = D dorian …).
  # Used by `group_key_suggestions/1` to collapse relative modes in the UI.
  @modal_modes MapSet.new([:major, :minor, :dorian, :phrygian, :lydian, :mixolydian, :locrian])

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       %{
         chord_form: %{"root" => "C", "quality" => "major"},
         chord_colors: @chord_colors,
         show_tuning_modal: false,
         show_key_modal: false,
         key_tonic: "C",
         key_scale_type: :major,
         key_chord_mode: :triad,
         show_key_modes: false,
         show_progression_modal: false,
         progression_id: :pop_i_v_vi_iv,
         progression_tonic: "C",
         key_suggestions: AsyncResult.loading(),
         multi_key_suggestions: AsyncResult.loading()
       }
     )}
  end

  defp decode_socket_state(params, previous) do
    page = Music.decode_page_params(params)

    case page do
      %{instrument: :piano} -> piano_state(page, previous)
      %{instrument: instrument} -> fretted_state(page, instrument, previous)
    end
  end

  # Piano state: a fixed keyboard with no tuning, no fretboard data, and no
  # analysis until the phase-3 analyzer interaction lands.
  defp piano_state(page, _previous) do
    %{
      instrument: :piano,
      tuning: [],
      tuning_state: nil,
      active_chords: page.active_chords,
      active_chord_colors: active_chord_colors(page.active_chords),
      highlighted_chord: page.highlighted_chord,
      fretboard: [],
      keyboard_keys: Music.keyboard_data(piano_range(), page.active_chords),
      svg: nil,
      modal_tuning_state: nil,
      tab: page.tab,
      marked_notes: %{},
      selected_keys: page.selection,
      analysis: nil
    }
  end

  # Fretted state: derived exactly as before, from the page contract.
  defp fretted_state(page, instrument, previous) do
    tuning_state = page.tuning_state
    tuning = Music.tuning_notes(tuning_state)
    active_chords = page.active_chords

    fretboard =
      if tuning == previous[:tuning] and active_chords == previous[:active_chords],
        do: previous.fretboard,
        else: Music.fretboard_data(tuning, active_chords)

    marked_notes = page.selection
    string_count = Music.instrument_strings(instrument)

    analysis =
      cond do
        page.tab != :analyzer ->
          nil

        previous[:tab] == :analyzer and marked_notes == previous[:marked_notes] and
            tuning_state.pitches == get_in(previous, [:tuning_state, :pitches]) ->
          previous.analysis

        true ->
          Music.analyzer_state(marked_notes, tuning_state.pitches)
      end

    %{
      instrument: instrument,
      tuning: tuning,
      tuning_state: tuning_state,
      active_chords: active_chords,
      active_chord_colors: active_chord_colors(active_chords),
      highlighted_chord: page.highlighted_chord,
      fretboard: fretboard,
      keyboard_keys: [],
      svg: svg_params(string_count),
      modal_tuning_state: tuning_state,
      tab: page.tab,
      marked_notes: marked_notes,
      selected_keys: [],
      analysis: analysis
    }
  end

  defp piano_range, do: Music.instrument(:piano)[:pitch_range]

  defp svg_params(string_count) do
    fb_w = @left_margin + (@fret_count + 1) * @fret_width
    fb_h = @top_margin + (string_count + 1) * @string_spacing

    %{
      left_margin: @left_margin,
      top_margin: @top_margin,
      fret_width: @fret_width,
      string_spacing: @string_spacing,
      fret_count: @fret_count,
      string_count: string_count,
      width: fb_w,
      height: fb_h,
      marker_frets: @marker_frets,
      double_marker_frets: @double_marker_frets
    }
  end

  @impl true
  def handle_params(params, _uri, socket) do
    state = decode_socket_state(params, socket.assigns)
    chords_changed? = socket.assigns[:active_chords] != state.active_chords
    socket = assign(socket, Map.put(state, :show_key_modes, false))

    socket =
      if chords_changed?,
        do: assign_key_suggestions(socket, state.active_chords),
        else: socket

    {:noreply, socket}
  end

  defp assign_key_suggestions(socket, chords) do
    assign_async(socket, [:key_suggestions, :multi_key_suggestions], fn ->
      if length(chords) >= 2 do
        suggestions = Music.suggest_keys(chords)
        multi = multi_key_suggestions(suggestions, chords)
        {:ok, %{key_suggestions: suggestions, multi_key_suggestions: multi}}
      else
        {:ok, %{key_suggestions: [], multi_key_suggestions: []}}
      end
    end)
  end

  defp multi_key_suggestions(suggestions, chords) do
    if suggestions == [] and length(chords) >= 3 do
      Music.suggest_multi_keys(chords)
    else
      []
    end
  end

  @impl true
  def handle_event("validate_chord", %{"chord" => params}, socket) do
    {:noreply, assign(socket, chord_form: params)}
  end

  @impl true
  def handle_event("add_chord", %{"chord" => %{"root" => root, "quality" => quality}}, socket) do
    chord = %{root: root, quality: String.to_existing_atom(quality)}

    if Enum.any?(socket.assigns.active_chords, &(&1 == chord)) do
      {:noreply, socket}
    else
      active_chords = socket.assigns.active_chords ++ [chord]
      {:noreply, push_page_patch(socket, active_chords: active_chords)}
    end
  end

  @impl true
  def handle_event("remove_chord", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    active_chords = List.delete_at(socket.assigns.active_chords, index)
    highlighted_chord = remaining_highlight(socket.assigns, active_chords)

    {:noreply,
     push_page_patch(socket,
       active_chords: active_chords,
       highlighted_chord: highlighted_chord
     )}
  end

  @impl true
  def handle_event("open_tuning_modal", _params, socket) do
    if socket.assigns.instrument == :piano do
      # Pianos have no tuning; the event is ignored entirely.
      {:noreply, socket}
    else
      {:noreply,
       assign(socket,
         show_tuning_modal: true,
         modal_tuning_state: socket.assigns.tuning_state
       )}
    end
  end

  @impl true
  def handle_event("close_tuning_modal", _params, socket) do
    {:noreply, assign(socket, show_tuning_modal: false)}
  end

  @impl true
  def handle_event("select_preset", %{"preset" => preset_name}, socket) do
    if socket.assigns.instrument == :piano do
      {:noreply, socket}
    else
      case Music.preset_tuning(socket.assigns.instrument, preset_name) do
        %{pitches: _} = state ->
          {:noreply, assign(socket, modal_tuning_state: state)}

        nil ->
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("change_string", %{"string" => string_str, "note" => note}, socket) do
    if socket.assigns.instrument == :piano do
      {:noreply, socket}
    else
      string_count = Music.instrument_strings(socket.assigns.instrument)

      with {string_idx, ""} <- Integer.parse(string_str),
           true <- string_idx in 0..(string_count - 1),
           true <- note in Music.chromatic_scale() do
        state =
          Music.change_tuning_note(
            socket.assigns.instrument,
            socket.assigns.modal_tuning_state,
            string_idx,
            note
          )

        {:noreply, assign(socket, modal_tuning_state: state)}
      else
        _invalid -> {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("apply_tuning", _params, socket) do
    if socket.assigns.instrument == :piano do
      {:noreply, socket}
    else
      tuning = socket.assigns.modal_tuning_state

      {:noreply,
       socket
       |> assign(show_tuning_modal: false)
       |> push_page_patch(tuning_state: tuning)}
    end
  end

  @impl true
  def handle_event("open_key_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_key_modal: true,
       key_tonic: "C",
       key_scale_type: :major,
       key_chord_mode: :triad
     )}
  end

  @impl true
  def handle_event("close_key_modal", _params, socket) do
    {:noreply, assign(socket, show_key_modal: false)}
  end

  @impl true
  def handle_event(
        "update_key",
        %{"key" => %{"tonic" => tonic, "scale_type" => scale_type} = key_params},
        socket
      ) do
    chord_mode =
      key_params
      |> Map.get("chord_mode", "triad")
      |> String.to_existing_atom()

    {:noreply,
     assign(socket,
       key_tonic: tonic,
       key_scale_type: String.to_existing_atom(scale_type),
       key_chord_mode: chord_mode
     )}
  end

  @impl true
  def handle_event("apply_key", _params, socket) do
    active_chords =
      Music.diatonic_chords(
        socket.assigns.key_tonic,
        socket.assigns.key_scale_type,
        socket.assigns.key_chord_mode
      )

    {:noreply,
     socket
     |> assign(show_key_modal: false)
     |> push_page_patch(active_chords: active_chords, highlighted_chord: nil)}
  end

  @impl true
  def handle_event("open_progression_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_progression_modal: true,
       progression_id: :pop_i_v_vi_iv,
       progression_tonic: "C"
     )}
  end

  @impl true
  def handle_event("close_progression_modal", _params, socket) do
    {:noreply, assign(socket, show_progression_modal: false)}
  end

  @impl true
  def handle_event(
        "update_progression",
        %{"progression" => %{"id" => id, "tonic" => tonic}},
        socket
      ) do
    {:noreply,
     assign(socket, progression_id: String.to_existing_atom(id), progression_tonic: tonic)}
  end

  @impl true
  def handle_event("apply_progression", _params, socket) do
    active_chords =
      Music.progression_chords(socket.assigns.progression_tonic, socket.assigns.progression_id)

    {:noreply,
     socket
     |> assign(show_progression_modal: false)
     |> push_page_patch(active_chords: active_chords, highlighted_chord: nil)}
  end

  @impl true
  def handle_event("highlight_chord", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    highlighted_chord = toggled_highlight(socket.assigns, index)

    {:noreply, push_page_patch(socket, highlighted_chord: highlighted_chord)}
  end

  @impl true
  def handle_event("change_instrument", %{"instrument" => instrument_str}, socket) do
    new_instrument = String.to_existing_atom(instrument_str)

    if new_instrument == socket.assigns.instrument do
      {:noreply, socket}
    else
      selection = switch_selection(socket.assigns, new_instrument)

      {:noreply,
       push_page_patch(socket,
         instrument: new_instrument,
         tuning_state: standard_tuning(new_instrument),
         selection: selection,
         highlighted_chord: nil
       )}
    end
  end

  @impl true
  def handle_event("apply_suggested_key", %{"tonic" => tonic, "scale_type" => scale_type}, socket) do
    mode = Music.infer_chord_mode(socket.assigns.active_chords)
    active_chords = Music.diatonic_chords(tonic, String.to_existing_atom(scale_type), mode)

    {:noreply, push_page_patch(socket, active_chords: active_chords, highlighted_chord: nil)}
  end

  @impl true
  def handle_event("toggle_key_modes", _params, socket) do
    {:noreply, assign(socket, :show_key_modes, not socket.assigns.show_key_modes)}
  end

  @impl true
  def handle_event("toggle_tab", %{"tab" => tab_str}, socket) do
    target_tab = Music.decode_tab(tab_str)

    if target_tab == socket.assigns.tab do
      {:noreply, socket}
    else
      {:noreply, push_page_patch(socket, tab: target_tab)}
    end
  end

  @impl true
  def handle_event("toggle_note", %{"string" => string_str, "fret" => fret_str}, socket) do
    string = String.to_integer(string_str)
    fret = String.to_integer(fret_str)

    current = Map.get(socket.assigns.marked_notes, string)

    new_marked =
      if current == fret do
        # Same position marked → toggle off
        Map.delete(socket.assigns.marked_notes, string)
      else
        # Either no note on this string, or a different fret → set/replace
        Map.put(socket.assigns.marked_notes, string, fret)
      end

    {:noreply, push_page_patch(socket, selection: new_marked)}
  end

  @impl true
  def handle_event("clear_notes", _params, socket) do
    {:noreply, push_page_patch(socket, selection: %{})}
  end

  @impl true
  def handle_event("clear_all_chords", _params, socket) do
    {:noreply, push_page_patch(socket, active_chords: [], highlighted_chord: nil)}
  end

  # Switching between string instruments keeps marked positions valid for
  # the new string count (existing behavior); crossing the piano boundary
  # clears the selection entirely - piano keys and string positions are
  # never converted into each other.
  defp switch_selection(%{instrument: :piano}, _fretted_instrument), do: %{}

  defp switch_selection(_fretted_assigns, :piano), do: []

  defp switch_selection(%{marked_notes: marked}, new_instrument),
    do: Music.filter_marked_notes(marked, Music.instrument_strings(new_instrument))

  defp standard_tuning(:piano), do: nil
  defp standard_tuning(instrument), do: Music.preset_tuning(instrument, "Standard")

  @impl true
  def render(assigns) do
    ~H"""
    <div class="main-container">
      <.controls_bar {assigns} />

      <%= if @tab == :visualizer do %>
        <.visualizer_tab {assigns} />
      <% else %>
        <.analyzer_tab {assigns} />
      <% end %>

      <.modals {assigns} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Controls bar (tab toggle, tuning, instrument, visualizer-only controls)
  # ---------------------------------------------------------------------------

  attr :tab, :atom, required: true
  attr :instrument, :atom, required: true
  attr :chord_form, :map, required: true

  defp controls_bar(assigns) do
    ~H"""
    <div class="controls-wrapper">
      <div class="controls-row">
        <%!-- Segmented tab toggle (FIRST element) --%>
        <div class="tab-toggle" id="tab-toggle">
          <button
            type="button"
            class={"tab-toggle-btn#{if @tab == :visualizer, do: " tab-toggle-btn--active", else: ""}"}
            phx-click="toggle_tab"
            phx-value-tab="visualizer"
          >
            Visualizer
          </button>
          <button
            type="button"
            class={"tab-toggle-btn#{if @tab == :analyzer, do: " tab-toggle-btn--active", else: ""}"}
            phx-click="toggle_tab"
            phx-value-tab="analyzer"
          >
            Analyzer
          </button>
        </div>

        <button
          :if={@instrument != :piano}
          type="button"
          phx-click="open_tuning_modal"
          class="btn btn-secondary"
        >
          🎸 Tuning
        </button>

        <%!-- 'More' chevron: client-side toggle for secondary controls (mobile only) --%>
        <button
          type="button"
          class="controls-more-btn"
          phx-click={toggle(to: "#controls-secondary", display: "flex")}
          aria-label="Toggle more controls"
        >
          ⋯ More
        </button>
      </div>

      <div id="controls-secondary" class="controls-secondary">
        <form phx-change="change_instrument" id="instrument-form">
          <select
            id="instrument-select"
            name="instrument"
            class="form-select"
          >
            <%= for {value, label} <- Music.instruments() do %>
              <option value={value} selected={@instrument == value}>
                {label}
              </option>
            <% end %>
          </select>
        </form>

        <.visualizer_controls :if={@tab == :visualizer} chord_form={@chord_form} />
      </div>
    </div>
    """
  end

  attr :chord_form, :map, required: true

  defp visualizer_controls(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="open_key_modal"
      class="btn btn-secondary"
    >
      🎵 Key
    </button>
    <button
      type="button"
      phx-click="open_progression_modal"
      class="btn btn-secondary"
    >
      🎼 Progressions
    </button>
    <form
      id="chord-form"
      phx-change="validate_chord"
      phx-submit="add_chord"
      class="form-inline"
    >
      <select
        id="root-select"
        name="chord[root]"
        class="form-select"
      >
        <%= for note <- Music.chromatic_scale() do %>
          <option value={note} selected={@chord_form["root"] == note}>{note}</option>
        <% end %>
      </select>
      <select
        id="quality-select"
        name="chord[quality]"
        class="form-select"
      >
        <%= for {group, qualities} <- Music.grouped_qualities() do %>
          <optgroup label={group}>
            <%= for q <- qualities do %>
              <option value={q} selected={@chord_form["quality"] == Atom.to_string(q)}>
                {Music.chord_label(q)}
              </option>
            <% end %>
          </optgroup>
        <% end %>
      </select>
      <button
        type="submit"
        class="btn btn-primary"
      >
        Add
      </button>
    </form>
    """
  end

  # ---------------------------------------------------------------------------
  # Visualizer tab
  # ---------------------------------------------------------------------------

  attr :instrument, :atom, required: true
  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :fretboard, :list, required: true
  attr :keyboard_keys, :list, required: true
  attr :active_chords, :list, required: true
  attr :active_chord_colors, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil
  attr :key_suggestions, :any, required: true
  attr :multi_key_suggestions, :any, required: true
  attr :show_key_modes, :boolean, required: true

  defp visualizer_tab(assigns) do
    ~H"""
    <%!-- Visualizer: keyboard for piano, fretboard with chord notes otherwise --%>
    <.piano_keyboard
      :if={@instrument == :piano}
      keys={@keyboard_keys}
      active_chords={@active_chords}
      chord_colors={@active_chord_colors}
      highlighted_chord={@highlighted_chord}
    />
    <.fretboard_svg
      :if={@instrument != :piano}
      svg={@svg}
      tuning={@tuning}
      fretboard={@fretboard}
      active_chords={@active_chords}
      chord_colors={@active_chord_colors}
      highlighted_chord={@highlighted_chord}
    />

    <%!-- Clear button (only shown when there are active chords) --%>
    <div :if={length(@active_chords) > 0} class="analyzer-results">
      <button type="button" class="btn-clear" phx-click="clear_all_chords">
        ✕ Clear chords
      </button>
    </div>

    <.chord_chips
      active_chords={@active_chords}
      chord_colors={@active_chord_colors}
      highlighted_chord={@highlighted_chord}
    />

    <.key_suggestions_section
      active_chords={@active_chords}
      key_suggestions={@key_suggestions}
      chord_colors={@chord_colors}
      show_key_modes={@show_key_modes}
    />

    <.multi_key_suggestions_section
      active_chords={@active_chords}
      multi_key_suggestions={@multi_key_suggestions}
      chord_colors={@chord_colors}
    />
    """
  end

  # ---------------------------------------------------------------------------
  # Chord chips
  # ---------------------------------------------------------------------------

  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil

  defp chord_chips(assigns) do
    ~H"""
    <div class="chords-wrapper">
      <%= for {chord, i} <- Enum.with_index(@active_chords) do %>
        <div
          class={"chord-chip#{if highlighted_chord?(chord, @active_chords, @highlighted_chord), do: " chord-chip--highlighted", else: ""}"}
          style={"background-color: #{chord_color(i, @chord_colors)}"}
          phx-click="highlight_chord"
          phx-value-index={i}
        >
          <div class="chord-chip-header">
            <span class="chord-chip-title">{Music.chord_label(chord.root, chord.quality)}</span>
            <button
              type="button"
              phx-click="remove_chord"
              phx-value-index={i}
              class="chord-chip-remove"
            >
              ×
            </button>
          </div>
          <div class="chord-chip-intervals">
            <%= for {note, interval} <- Music.notes_with_intervals(chord.root, chord.quality) do %>
              <div>{note} - {interval}</div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Key suggestions section
  # ---------------------------------------------------------------------------

  attr :active_chords, :list, required: true
  attr :key_suggestions, :any, required: true
  attr :chord_colors, :list, required: true
  attr :show_key_modes, :boolean, required: true

  defp key_suggestions_section(assigns) do
    ~H"""
    <.async_result :let={key_suggestions} assign={@key_suggestions}>
      <:loading>
        <div
          :if={length(@active_chords) >= 2}
          class="key-suggestions-wrapper"
          id="key-suggestions"
        >
          <label class="section-label" style="width:100%">Compatible keys</label>
          <p class="key-suggestions-loading">Calculating...</p>
        </div>
      </:loading>
      <:failed :let={_failure}>
        <div
          :if={length(@active_chords) >= 2}
          class="key-suggestions-wrapper"
          id="key-suggestions"
        >
          <label class="section-label" style="width:100%">Compatible keys</label>
          <p class="text-muted">Error calculating keys.</p>
        </div>
      </:failed>
      <div
        :if={length(@active_chords) >= 2}
        class="key-suggestions-wrapper"
        id="key-suggestions"
      >
        <label class="section-label" style="width:100%">Compatible keys</label>

        <%= if key_suggestions == [] do %>
          <p class="text-muted">
            No compatible keys found for these chords.
          </p>
        <% else %>
          <%= for group <- group_key_suggestions(key_suggestions) do %>
            <.key_suggestion_group
              group={group}
              chord_colors={@chord_colors}
              show_key_modes={@show_key_modes}
            />
          <% end %>
        <% end %>
      </div>
    </.async_result>
    """
  end

  attr :group, :map, required: true
  attr :chord_colors, :list, required: true
  attr :show_key_modes, :boolean, required: true

  defp key_suggestion_group(assigns) do
    ~H"""
    <%= if @group.collapsed? do %>
      <.collapsed_mode_group
        group={@group}
        chord_colors={@chord_colors}
        show_key_modes={@show_key_modes}
      />
    <% else %>
      <.single_mode_card
        item={@group.item}
        chord_colors={@chord_colors}
      />
    <% end %>
    """
  end

  attr :group, :map, required: true
  attr :chord_colors, :list, required: true
  attr :show_key_modes, :boolean, required: true

  defp collapsed_mode_group(assigns) do
    ~H"""
    <%!-- Grouped modal modes: show prominent as cards, others as expandable --%>
    <%= for s <- @group.prominent do %>
      <.key_card suggestion={s} chord_colors={@chord_colors} />
    <% end %>
    <%!-- Collapsed modes toggle --%>
    <div class="key-modes-row" style="width:100%">
      <button
        type="button"
        class="key-modes-toggle"
        phx-click="toggle_key_modes"
      >
        ▸ {length(@group.others)} additional modes
      </button>
    </div>
    <.expanded_modes
      :if={@show_key_modes}
      others={@group.others}
      chord_colors={@chord_colors}
    />
    """
  end

  attr :others, :list, required: true
  attr :chord_colors, :list, required: true

  defp expanded_modes(assigns) do
    ~H"""
    <div class="key-modes-expanded" style="width:100%">
      <%= for s <- @others do %>
        <.key_card suggestion={s} chord_colors={@chord_colors} />
      <% end %>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :chord_colors, :list, required: true

  defp single_mode_card(assigns) do
    ~H"""
    <%!-- Single (non-modal) suggestion as card --%>
    <div
      class="key-card"
      phx-click="apply_suggested_key"
      phx-value-tonic={@item.tonic}
      phx-value-scale_type={@item.scale_type}
    >
      <div class="key-card-header">
        <span class="key-card-title">
          {Music.scale_label(@item.scale_type)} {@item.tonic}
        </span>
        <span class={"key-card-score#{if @item.score == @item.total, do: "", else: " key-card-score--partial"}"}>
          {@item.score}/{@item.total}
        </span>
      </div>
      <div class="key-card-chips">
        <%= for {dc, i} <- Enum.with_index(@item.diatonic_chords) do %>
          <span
            class="key-card-chip"
            style={chord_color(i, @chord_colors) |> then(&"background-color: #{&1};")}
          >
            {Music.chord_label(dc.root, dc.quality)}
          </span>
        <% end %>
      </div>
      <div class="key-card-arrow">View key →</div>
    </div>
    """
  end

  attr :suggestion, :map, required: true
  attr :chord_colors, :list, required: true

  defp key_card(assigns) do
    ~H"""
    <div
      class="key-card"
      phx-click="apply_suggested_key"
      phx-value-tonic={@suggestion.tonic}
      phx-value-scale_type={@suggestion.scale_type}
    >
      <div class="key-card-header">
        <span class="key-card-title">
          {Music.scale_label(@suggestion.scale_type)} {@suggestion.tonic}
        </span>
        <span class="key-card-score">{@suggestion.score}/{@suggestion.total}</span>
      </div>
      <div class="key-card-chips">
        <%= for {dc, i} <- Enum.with_index(@suggestion.diatonic_chords) do %>
          <span
            class="key-card-chip"
            style={chord_color(i, @chord_colors) |> then(&"background-color: #{&1};")}
          >
            {Music.chord_label(dc.root, dc.quality)}
          </span>
        <% end %>
      </div>
      <div class="key-card-arrow">View key →</div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Multi-key suggestions section
  # ---------------------------------------------------------------------------

  attr :active_chords, :list, required: true
  attr :multi_key_suggestions, :any, required: true
  attr :chord_colors, :list, required: true

  defp multi_key_suggestions_section(assigns) do
    ~H"""
    <%!-- Multi-Key Suggestions (only when no single key found) --%>
    <.async_result :let={multi_key_suggestions} assign={@multi_key_suggestions}>
      <:loading>
        <div :if={length(@active_chords) >= 3} class="key-suggestions-wrapper">
          <p class="key-suggestions-loading">Analyzing keys...</p>
        </div>
      </:loading>
      <:failed>
        <div :if={length(@active_chords) >= 3} class="key-suggestions-wrapper">
          <p class="text-muted">Error calculating keys.</p>
        </div>
      </:failed>
      <div
        :if={multi_key_suggestions != [] and length(@active_chords) >= 3}
        class="key-suggestions-wrapper"
        id="multi-key-suggestions"
      >
        <label class="section-label" style="width:100%">
          No common key. {length(Enum.filter(multi_key_suggestions, &(&1.key != nil)))} keys found:
        </label>

        <%= for {group, i} <- Enum.with_index(multi_key_suggestions) do %>
          <.multi_key_group
            group={group}
            index={i}
            active_chords={@active_chords}
            chord_colors={@chord_colors}
          />
        <% end %>
      </div>
    </.async_result>
    """
  end

  attr :group, :map, required: true
  attr :index, :integer, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true

  defp multi_key_group(assigns) do
    ~H"""
    <%= if @group.key == nil do %>
      <.unmatched_chords group={@group} />
    <% else %>
      <.tonal_group
        group={@group}
        index={@index}
        active_chords={@active_chords}
        chord_colors={@chord_colors}
      />
    <% end %>
    """
  end

  attr :group, :map, required: true

  defp unmatched_chords(assigns) do
    ~H"""
    <%!-- Unmatched chords --%>
    <div class="multi-key-unmatched">
      <span class="multi-key-unmatched-label">Chords without a compatible key:</span>
      <%= for chord <- @group.chords do %>
        <span class="chord-chip chord-chip--unmatched">
          {Music.chord_label(chord.root, chord.quality)}
        </span>
      <% end %>
    </div>
    """
  end

  attr :group, :map, required: true
  attr :index, :integer, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true

  defp tonal_group(assigns) do
    ~H"""
    <%!-- Tonal group --%>
    <div class="multi-key-group">
      <span class="multi-key-group-label">Key {@index + 1}</span>
      <.key_card
        suggestion={@group.key}
        chord_colors={@chord_colors}
      />
      <div class="multi-key-your-chords">
        <span class="multi-key-your-chords-label">Your chords:</span>
        <%= for chord <- @group.chords do %>
          <.your_chord_chip
            chord={chord}
            active_chords={@active_chords}
            chord_colors={@chord_colors}
          />
        <% end %>
      </div>
    </div>
    """
  end

  attr :chord, :map, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true

  defp your_chord_chip(assigns) do
    ~H"""
    <% chord_idx = Enum.find_index(@active_chords, &(&1 == @chord)) %>
    <span
      class="key-card-chip"
      style={your_chord_style(chord_idx, @chord_colors)}
    >
      {Music.chord_label(@chord.root, @chord.quality)}
    </span>
    """
  end

  defp your_chord_style(nil, _chord_colors), do: "background-color: #6b7280;"

  defp your_chord_style(chord_idx, chord_colors) do
    chord_color(chord_idx, chord_colors) |> then(&"background-color: #{&1};")
  end

  # ---------------------------------------------------------------------------
  # Analyzer tab
  # ---------------------------------------------------------------------------

  attr :instrument, :atom, required: true
  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :marked_notes, :map, required: true
  attr :analysis, :any, default: nil

  defp analyzer_tab(assigns) do
    ~H"""
    <div :if={@instrument == :piano} class="analyzer-empty" id="piano-analyzer-pending">
      Piano analyzer is coming in the next update
    </div>

    <%= if @instrument != :piano do %>
      <%!-- Analyzer tab: interactive fretboard + analysis results --%>
      <.analyzer_fretboard_svg
        svg={@svg}
        tuning={@tuning}
        marked_notes={@marked_notes}
      />

      <%!-- Clear button (only shown when there are marked notes) --%>
      <div :if={map_size(@marked_notes) > 0} class="analyzer-results">
        <button
          type="button"
          class="btn-clear"
          phx-click="clear_notes"
        >
          ✕ Clear notes
        </button>
      </div>

      <%!-- Analysis results --%>
      <.analyzer_results analysis={@analysis} />
    <% end %>
    """
  end

  # ---------------------------------------------------------------------------
  # Modals (rendered in both tabs, shown only when toggled)
  # ---------------------------------------------------------------------------

  attr :show_tuning_modal, :boolean, required: true
  attr :modal_tuning_state, :map, required: true
  attr :instrument, :atom, required: true
  attr :svg, :map, required: true
  attr :show_key_modal, :boolean, required: true
  attr :key_tonic, :string, required: true
  attr :key_scale_type, :atom, required: true
  attr :key_chord_mode, :atom, required: true
  attr :chord_colors, :list, required: true
  attr :show_progression_modal, :boolean, required: true
  attr :progression_id, :atom, required: true
  attr :progression_tonic, :string, required: true

  defp modals(assigns) do
    ~H"""
    <%!-- Tuning Modal (visible in both tabs; pianos have no tuning) --%>
    <.tuning_modal
      :if={@instrument != :piano}
      show={@show_tuning_modal}
      modal_tuning_state={@modal_tuning_state}
      instrument={@instrument}
      string_count={@svg.string_count}
    />

    <%!-- Key Modal (visualizer-only, but rendered for both — only shown when toggled) --%>
    <.key_modal
      show={@show_key_modal}
      key_tonic={@key_tonic}
      key_scale_type={@key_scale_type}
      key_chord_mode={@key_chord_mode}
      chord_colors={@chord_colors}
    />

    <%!-- Progression Modal (visualizer-only, but rendered for both — only shown when toggled) --%>
    <.progression_modal
      show={@show_progression_modal}
      progression_id={@progression_id}
      progression_tonic={@progression_tonic}
      chord_colors={@chord_colors}
    />
    """
  end

  # ---------------------------------------------------------------------------
  # Analyzer results component
  # ---------------------------------------------------------------------------

  attr :analysis, :any, default: nil

  defp analyzer_results(assigns) do
    ~H"""
    <div class="analyzer-results" id={"analyzer-results-#{analysis_key(@analysis)}"}>
      <.analysis_state analysis={@analysis} />
    </div>
    """
  end

  attr :analysis, :any, required: true

  defp analysis_state(%{analysis: a} = assigns) when a in [nil, {:empty}] do
    ~H"""
    <div class="analyzer-empty">
      Click notes on the fretboard to identify a chord
    </div>
    """
  end

  defp analysis_state(%{analysis: {:single, _note}} = assigns) do
    ~H"""
    <div class="analyzer-single-note">
      Note: {@analysis |> elem(1)}
    </div>
    """
  end

  defp analysis_state(%{analysis: {:interval, _note_a, _note_b, _label}} = assigns) do
    ~H"""
    <div class="analyzer-interval">
      Interval: {@analysis |> elem(1)}-{@analysis |> elem(2)} ({@analysis |> elem(3)})
    </div>
    """
  end

  defp analysis_state(%{analysis: {:chords, _notes, _bass, interpretations}} = assigns)
       when interpretations == [] do
    ~H"""
    <div class="analyzer-empty">
      No chord found for these notes.
    </div>
    """
  end

  defp analysis_state(%{analysis: {:chords, _notes, _bass, _interpretations}} = assigns) do
    ~H"""
    <%= for interp <- @analysis |> elem(3) do %>
      <.analysis_card interp={interp} />
    <% end %>
    """
  end

  attr :interp, :map, required: true

  defp analysis_card(assigns) do
    ~H"""
    <div class="analysis-card">
      <div class="analysis-card-header">
        <span class="analysis-card-title">{@interp.slash_label}</span>
        <span class={"analysis-card-badge #{badge_class(@interp)}"}>
          {badge_text(@interp)}
        </span>
      </div>
      <div class="analysis-card-notes">
        <%= for {note, interval} <- note_interval_pairs(@interp) do %>
          <span class={"analysis-note-item#{if missing?(@interp, interval), do: " analysis-note-item--missing", else: ""}"}>
            <strong>{note}</strong>
          </span>
        <% end %>
      </div>
      <div class="analysis-card-intervals">
        <%= for interval <- @interp.intervals do %>
          <span>{interval}</span>
        <% end %>
      </div>
      <div :if={@interp.inversion != nil} class="analysis-card-inversion">
        {inversion_label(@interp.inversion)}
      </div>
      <div class="analysis-card-bass">
        <strong>Bass:</strong> {@interp.bass}
      </div>
    </div>
    """
  end

  defp badge_class(%{exact: true}), do: "analysis-badge--exact"
  defp badge_class(%{incomplete: true}), do: "analysis-badge--incomplete"
  defp badge_class(_), do: "analysis-badge--partial"

  defp badge_text(%{exact: true}), do: "exact"
  defp badge_text(%{incomplete: true}), do: "incomplete"
  defp badge_text(_), do: "partial"

  defp note_interval_pairs(%{notes: notes, intervals: intervals}) do
    Enum.zip(notes, intervals)
  end

  defp missing?(%{incomplete: true, missing_intervals: missing}, interval) do
    interval in missing
  end

  defp missing?(_, _interval), do: false

  # Generates a unique key per analysis state so LiveView replaces
  # the entire container (old ID removed, new ID added) instead of
  # trying to diff incompatible HTML structures.
  defp analysis_key({:empty}), do: "empty"
  defp analysis_key({:single, note}), do: "single-#{note}"
  defp analysis_key({:interval, a, b, _}), do: "interval-#{a}-#{b}"
  defp analysis_key({:chords, notes, _, _}), do: "chords-#{Enum.join(notes, "-")}"
  defp analysis_key(nil), do: "nil"

  defp active_chord_colors(chords) do
    {colors, _by_chord} =
      Enum.map_reduce(chords, %{}, fn chord, by_chord ->
        case Map.fetch(by_chord, chord) do
          {:ok, color} ->
            {color, by_chord}

          :error ->
            color = chord_color(map_size(by_chord), @chord_colors)
            {color, Map.put(by_chord, chord, color)}
        end
      end)

    colors
  end

  defp highlighted_chord?(_chord, _active_chords, nil), do: false

  defp highlighted_chord?(chord, active_chords, highlighted_index) do
    chord == Enum.at(active_chords, highlighted_index)
  end

  defp toggled_highlight(%{highlighted_chord: nil}, index), do: index

  defp toggled_highlight(assigns, index) do
    clicked_chord = Enum.at(assigns.active_chords, index)
    highlighted_chord = Enum.at(assigns.active_chords, assigns.highlighted_chord)

    if clicked_chord == highlighted_chord, do: nil, else: index
  end

  defp remaining_highlight(%{highlighted_chord: nil}, _active_chords), do: nil

  defp remaining_highlight(assigns, active_chords) do
    highlighted_chord = Enum.at(assigns.active_chords, assigns.highlighted_chord)
    Enum.find_index(active_chords, &(&1 == highlighted_chord))
  end

  defp inversion_label(0), do: "Root position"
  defp inversion_label(1), do: "1st inversion"
  defp inversion_label(2), do: "2nd inversion"
  defp inversion_label(3), do: "3rd inversion"
  defp inversion_label(4), do: "4th inversion"
  defp inversion_label(5), do: "5th inversion"
  defp inversion_label(6), do: "6th inversion"

  # Builds the canonical instrument-aware page state from the socket assigns
  # merged with the given overrides, and pushes the patch. `handle_params`
  # remains the only place that re-derives state from the URL.
  defp push_page_patch(socket, overrides) do
    state = %{
      instrument: Keyword.get(overrides, :instrument, socket.assigns.instrument),
      tuning_state:
        Keyword.get_lazy(overrides, :tuning_state, fn -> socket.assigns.tuning_state end),
      active_chords: Keyword.get(overrides, :active_chords, socket.assigns.active_chords),
      highlighted_chord:
        Keyword.get(overrides, :highlighted_chord, socket.assigns.highlighted_chord),
      tab: Keyword.get(overrides, :tab, socket.assigns.tab),
      selection: Keyword.get_lazy(overrides, :selection, fn -> page_selection(socket.assigns) end)
    }

    params = Music.encode_page_params(state)
    query = URI.encode_query(params)
    path = if query == "", do: "/", else: "/?#{query}"

    push_patch(socket, to: path)
  end

  # The URL-backed selection: marked string positions for fretted
  # instruments, selected absolute pitches for piano.
  defp page_selection(%{instrument: :piano, selected_keys: keys}), do: keys
  defp page_selection(%{marked_notes: marked}), do: marked

  @doc """
  Groups flat key suggestions into display rows for the UI.

  Relative modes (the 7 diatonic modes that share the same note set) are
  collapsed: the major and relative minor are shown prominently while the
  remaining 5 modes are summarized as "N additional modes". Non-modal
  scales (pentatonic, blues, harmonic_minor, …) are shown individually.

  Only suggestions at the maximum score are grouped; when no suggestion
  reaches a perfect score the top 3 are shown individually without grouping.
  """
  @spec group_key_suggestions([map()]) :: [map()]
  def group_key_suggestions([]), do: []

  def group_key_suggestions(suggestions) do
    max_score = hd(suggestions).score
    top = Enum.filter(suggestions, &(&1.score == max_score))
    rest = Enum.filter(suggestions, &(&1.score < max_score))

    if max_score == hd(suggestions).total do
      grouped = group_modal_modes(top)
      non_modal = Enum.filter(top, &(not MapSet.member?(@modal_modes, &1.scale_type)))
      grouped_rows = Enum.map(grouped, &build_grouped_row/1)
      non_modal_rows = Enum.map(non_modal, &build_single_row/1)
      grouped_rows ++ non_modal_rows ++ single_rows(rest)
    else
      single_rows(Enum.take(suggestions, 3))
    end
  end

  defp single_rows(suggestions) do
    Enum.map(suggestions, &build_single_row/1)
  end

  defp build_single_row(s) do
    %{collapsed?: false, item: s}
  end

  defp build_grouped_row(group) do
    %{collapsed?: true, prominent: group.prominent, others: group.others}
  end

  # Groups suggestions at the same score whose scale notes form the same set.
  # Returns a list of `%{prominent: [...], others: [...]}`. `prominent` holds
  # the :major and :minor entries (in that priority order); `others` holds the
  # remaining 5 modal modes. Non-modal scales are left ungrouped by this pass.
  defp group_modal_modes(top) do
    # Partition into modal (diatonic) and non-modal scales.
    {modal, _non_modal} = Enum.split_with(top, &MapSet.member?(@modal_modes, &1.scale_type))

    # Group modal modes by their note set.
    groups =
      Enum.group_by(modal, fn s ->
        MapSet.new(Music.scale_notes(s.tonic, s.scale_type))
      end)

    # Only note-sets that contain all 7 diatonic modes get collapsed.
    groups
    |> Enum.map(fn {_notes, members} -> members end)
    |> Enum.filter(fn members -> length(members) == 7 end)
    |> Enum.map(&extract_prominent/1)
  end

  # Splits a group of 7 relative modes into prominent [:major, :minor] and the
  # remaining 5 modes. Falls back to showing only the available prominent
  # entries and treats the rest as "others".
  defp extract_prominent(members) do
    major = Enum.find(members, &(&1.scale_type == :major))
    minor = Enum.find(members, &(&1.scale_type == :minor))
    prominent = Enum.reject([major, minor], &is_nil/1)

    prominent_types = MapSet.new(prominent, & &1.scale_type)
    others = Enum.reject(members, &MapSet.member?(prominent_types, &1.scale_type))

    %{prominent: prominent, others: others}
  end
end
