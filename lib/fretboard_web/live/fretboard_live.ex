defmodule FretboardWeb.FretboardLive do
  @moduledoc """
  Main LiveView for the fretboard visualizer.

  Renders an SVG fretboard with 24 frets and a configurable number of
  strings (6-string guitar, 4- or 5-string bass). Supports adding/removing
  chords, coloring notes by chord, and selecting tuning presets.
  """

  use FretboardWeb, :live_view

  import FretboardWeb.FretboardSVG, only: [fretboard_svg: 1, analyzer_fretboard_svg: 1]
  import FretboardWeb.Modals
  import Phoenix.LiveView.JS, only: [toggle: 1]

  alias Fretboard.Music
  alias Fretboard.Music.Note
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
  def mount(params, _session, socket) do
    state = decode_socket_state(params)

    {:ok,
     assign(
       socket,
       Map.merge(state, %{
         chord_form: %{"root" => "C", "quality" => "major"},
         chord_colors: @chord_colors,
         chromatic_notes: Note.chromatic_scale(),
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
       })
     )}
  end

  defp decode_socket_state(params) do
    {instrument, tuning, active_chords, highlighted_chord} = Music.decode_params(params)
    fretboard = Music.fretboard_data(tuning, active_chords)
    string_count = Music.instrument_strings(instrument)
    tab = Music.decode_tab(params["tab"])

    marked_notes =
      params["marked"]
      |> Music.decode_marked()
      |> Music.filter_marked_notes(string_count)

    analysis = if tab == :analyzer, do: analyzer_state(marked_notes, tuning), else: nil

    %{
      instrument: instrument,
      tuning: tuning,
      active_chords: active_chords,
      highlighted_chord: highlighted_chord,
      fretboard: fretboard,
      svg: svg_params(string_count),
      modal_tuning: tuning,
      modal_preset: detect_preset(tuning, instrument),
      tab: tab,
      marked_notes: marked_notes,
      analysis: analysis
    }
  end

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
    state = decode_socket_state(params)
    chords = state.active_chords

    {:noreply,
     socket
     |> assign(Map.put(state, :show_key_modes, false))
     |> assign_async(:key_suggestions, fn ->
       if length(chords) >= 2 do
         suggestions = Music.suggest_keys(chords)
         multi = multi_key_suggestions(suggestions, chords)
         {:ok, %{key_suggestions: suggestions, multi_key_suggestions: multi}}
       else
         {:ok, %{key_suggestions: [], multi_key_suggestions: []}}
       end
     end)}
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

      {:noreply,
       push_url_patch(
         socket,
         socket.assigns.instrument,
         socket.assigns.tuning,
         active_chords,
         socket.assigns.highlighted_chord
       )}
    end
  end

  @impl true
  def handle_event("remove_chord", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    active_chords = List.delete_at(socket.assigns.active_chords, index)

    highlighted_chord =
      cond do
        socket.assigns.highlighted_chord == nil ->
          nil

        socket.assigns.highlighted_chord == index ->
          nil

        socket.assigns.highlighted_chord > index ->
          socket.assigns.highlighted_chord - 1

        true ->
          socket.assigns.highlighted_chord
      end

    {:noreply,
     push_url_patch(
       socket,
       socket.assigns.instrument,
       socket.assigns.tuning,
       active_chords,
       highlighted_chord
     )}
  end

  @impl true
  def handle_event("open_tuning_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_tuning_modal: true,
       modal_tuning: socket.assigns.tuning,
       modal_preset: detect_preset(socket.assigns.tuning, socket.assigns.instrument)
     )}
  end

  @impl true
  def handle_event("close_tuning_modal", _params, socket) do
    {:noreply, assign(socket, show_tuning_modal: false)}
  end

  @impl true
  def handle_event("select_preset", %{"preset" => preset_name}, socket) do
    presets = Music.instrument_tuning_presets(socket.assigns.instrument)

    case Enum.find(presets, fn {name, _} -> name == preset_name end) do
      {_name, notes} ->
        {:noreply, assign(socket, modal_tuning: notes, modal_preset: preset_name)}

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_string", %{"string" => string_str, "note" => note}, socket) do
    string_idx = String.to_integer(string_str)
    modal_tuning = List.replace_at(socket.assigns.modal_tuning, string_idx, note)

    {:noreply,
     assign(socket,
       modal_tuning: modal_tuning,
       modal_preset: detect_preset(modal_tuning, socket.assigns.instrument)
     )}
  end

  @impl true
  def handle_event("apply_tuning", _params, socket) do
    tuning = socket.assigns.modal_tuning

    {:noreply,
     socket
     |> assign(show_tuning_modal: false)
     |> push_url_patch(
       socket.assigns.instrument,
       tuning,
       socket.assigns.active_chords,
       socket.assigns.highlighted_chord
     )}
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
     |> push_url_patch(socket.assigns.instrument, socket.assigns.tuning, active_chords, nil)}
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
     |> push_url_patch(socket.assigns.instrument, socket.assigns.tuning, active_chords, nil)}
  end

  @impl true
  def handle_event("highlight_chord", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    highlighted_chord =
      if socket.assigns.highlighted_chord == index,
        do: nil,
        else: index

    {:noreply,
     push_url_patch(
       socket,
       socket.assigns.instrument,
       socket.assigns.tuning,
       socket.assigns.active_chords,
       highlighted_chord
     )}
  end

  @impl true
  def handle_event("change_instrument", %{"instrument" => instrument_str}, socket) do
    new_instrument = String.to_existing_atom(instrument_str)
    new_tuning = Music.instrument_standard_tuning(new_instrument)
    new_string_count = Music.instrument_strings(new_instrument)
    filtered_marked = Music.filter_marked_notes(socket.assigns.marked_notes, new_string_count)

    {:noreply,
     push_analyzer_patch(
       socket,
       new_instrument,
       new_tuning,
       socket.assigns.active_chords,
       nil,
       socket.assigns.tab,
       filtered_marked
     )}
  end

  @impl true
  def handle_event("apply_suggested_key", %{"tonic" => tonic, "scale_type" => scale_type}, socket) do
    mode = infer_chord_mode(socket.assigns.active_chords)
    active_chords = Music.diatonic_chords(tonic, String.to_existing_atom(scale_type), mode)

    {:noreply,
     push_url_patch(socket, socket.assigns.instrument, socket.assigns.tuning, active_chords, nil)}
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
      # Preserve marked notes across tab switches so the analyzer state
      # survives round-trips through the visualizer (encoded in the URL).
      marked_notes = socket.assigns.marked_notes

      {:noreply,
       push_analyzer_patch(
         socket,
         socket.assigns.instrument,
         socket.assigns.tuning,
         socket.assigns.active_chords,
         socket.assigns.highlighted_chord,
         target_tab,
         marked_notes
       )}
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

    # Pre-compute analysis here so the re-render triggered by push_patch
    # already has the updated value. handle_params will re-compute it
    # too, but the immediate re-render needs it now.
    new_analysis = analyzer_state(new_marked, socket.assigns.tuning)

    {:noreply,
     socket
     |> assign(marked_notes: new_marked, analysis: new_analysis)
     |> push_analyzer_patch(
       socket.assigns.instrument,
       socket.assigns.tuning,
       socket.assigns.active_chords,
       socket.assigns.highlighted_chord,
       socket.assigns.tab,
       new_marked
     )}
  end

  @impl true
  def handle_event("clear_notes", _params, socket) do
    {:noreply,
     socket
     |> assign(marked_notes: %{}, analysis: {:empty})
     |> push_analyzer_patch(
       socket.assigns.instrument,
       socket.assigns.tuning,
       socket.assigns.active_chords,
       socket.assigns.highlighted_chord,
       socket.assigns.tab,
       %{}
     )}
  end

  @impl true
  def handle_event("clear_all_chords", _params, socket) do
    socket =
      socket
      |> assign(active_chords: [], highlighted_chord: nil)

    {:noreply,
     push_url_patch(
       socket,
       socket.assigns.instrument,
       socket.assigns.tuning,
       [],
       nil
     )}
  end

  @doc """
  Quick-jump handler: adjusts the fretboard viewport to show 12 frets
  starting at the requested fret position. Pushes a `set_viewport` event
  to the client-side FretboardPanZoom hook.
  """
  @impl true
  def handle_event("jump_to", %{"fret" => fret_str}, socket) do
    fret = String.to_integer(fret_str)
    {:noreply, push_event(socket, "set_viewport", %{start_fret: fret})}
  end

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

  defp infer_chord_mode(active_chords) do
    seventh_qualities =
      MapSet.new([:"7", :maj7, :min7, :dim7, :m7b5, :min_maj7, :aug_maj7, :aug7])

    if Enum.any?(active_chords, &MapSet.member?(seventh_qualities, &1.quality)) do
      :seventh
    else
      :triad
    end
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
        <%= for note <- Note.chromatic_scale() do %>
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
  # Quick-jump anchor bar (mobile only — visibility controlled by CSS)
  # ---------------------------------------------------------------------------

  defp quick_jump_bar(assigns) do
    ~H"""
    <div class="quick-jump-bar">
      <button type="button" class="quick-jump-btn" phx-click="jump_to" phx-value-fret="0">
        Open
      </button>
      <button type="button" class="quick-jump-btn" phx-click="jump_to" phx-value-fret="5">
        5th
      </button>
      <button type="button" class="quick-jump-btn" phx-click="jump_to" phx-value-fret="12">
        12th
      </button>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Visualizer tab
  # ---------------------------------------------------------------------------

  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :fretboard, :list, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil
  attr :key_suggestions, :any, required: true
  attr :multi_key_suggestions, :any, required: true
  attr :show_key_modes, :boolean, required: true

  defp visualizer_tab(assigns) do
    ~H"""
    <%!-- Visualizer: standard fretboard with chord notes --%>
    <.fretboard_svg
      svg={@svg}
      tuning={@tuning}
      fretboard={@fretboard}
      active_chords={@active_chords}
      chord_colors={@chord_colors}
      highlighted_chord={@highlighted_chord}
    />

    <%!-- Quick-jump anchors (mobile only, shown via CSS) --%>
    <.quick_jump_bar />

    <%!-- Clear button (only shown when there are active chords) --%>
    <div :if={length(@active_chords) > 0} class="analyzer-results">
      <button type="button" class="btn-clear" phx-click="clear_all_chords">
        ✕ Clear chords
      </button>
    </div>

    <.chord_chips
      active_chords={@active_chords}
      chord_colors={@chord_colors}
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
          class={"chord-chip#{if @highlighted_chord == i, do: " chord-chip--highlighted", else: ""}"}
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
          <label class="section-label" style="width:100%">Tonalidades compatibles</label>
          <p class="key-suggestions-loading">Calculando...</p>
        </div>
      </:loading>
      <:failed :let={_failure}>
        <div
          :if={length(@active_chords) >= 2}
          class="key-suggestions-wrapper"
          id="key-suggestions"
        >
          <label class="section-label" style="width:100%">Tonalidades compatibles</label>
          <p class="text-muted">Error al calcular tonalidades.</p>
        </div>
      </:failed>
      <div
        :if={length(@active_chords) >= 2}
        class="key-suggestions-wrapper"
        id="key-suggestions"
      >
        <label class="section-label" style="width:100%">Tonalidades compatibles</label>

        <%= if key_suggestions == [] do %>
          <p class="text-muted">
            No se encontraron tonalidades compatibles con estos acordes.
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
        ▸ {length(@group.others)} modos adicionales
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
      <div class="key-card-arrow">Ver tonalidad →</div>
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
      <div class="key-card-arrow">Ver tonalidad →</div>
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
          <p class="key-suggestions-loading">Analizando tonalidades...</p>
        </div>
      </:loading>
      <:failed>
        <div :if={length(@active_chords) >= 3} class="key-suggestions-wrapper">
          <p class="text-muted">Error al calcular tonalidades.</p>
        </div>
      </:failed>
      <div
        :if={multi_key_suggestions != [] and length(@active_chords) >= 3}
        class="key-suggestions-wrapper"
        id="multi-key-suggestions"
      >
        <label class="section-label" style="width:100%">
          No hay una tonalidad común. Se encontraron {length(
            Enum.filter(multi_key_suggestions, &(&1.key != nil))
          )} tonalidades:
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
      <span class="multi-key-unmatched-label">Acordes sin tonalidad compatible:</span>
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
      <span class="multi-key-group-label">Tonalidad {@index + 1}</span>
      <.key_card
        suggestion={@group.key}
        chord_colors={@chord_colors}
      />
      <div class="multi-key-your-chords">
        <span class="multi-key-your-chords-label">Tus acordes:</span>
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

  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :marked_notes, :map, required: true
  attr :analysis, :any, default: nil

  defp analyzer_tab(assigns) do
    ~H"""
    <%!-- Analyzer tab: interactive fretboard + analysis results --%>
    <.analyzer_fretboard_svg
      svg={@svg}
      tuning={@tuning}
      marked_notes={@marked_notes}
    />

    <%!-- Quick-jump anchors (mobile only, shown via CSS) --%>
    <.quick_jump_bar />

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
    """
  end

  # ---------------------------------------------------------------------------
  # Modals (rendered in both tabs, shown only when toggled)
  # ---------------------------------------------------------------------------

  attr :show_tuning_modal, :boolean, required: true
  attr :modal_preset, :string, required: true
  attr :instrument, :atom, required: true
  attr :modal_tuning, :list, required: true
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
    <%!-- Tuning Modal (visible in both tabs) --%>
    <.tuning_modal
      show={@show_tuning_modal}
      modal_preset={@modal_preset}
      instrument={@instrument}
      modal_tuning={@modal_tuning}
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

  @doc """
  Detects which preset matches a given tuning for a given instrument, or returns "Custom".
  """
  @spec detect_preset([String.t()], atom()) :: String.t()
  def detect_preset(tuning, instrument) do
    case Enum.find(Music.instrument_tuning_presets(instrument), fn {_name, notes} ->
           notes == tuning
         end) do
      {name, _notes} -> name
      nil -> "Custom"
    end
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

  defp analysis_state(%{analysis: {:empty}} = assigns) do
    ~H"""
    <div class="analyzer-empty">
      Pulsa notas en el diapasón para identificar un acorde
    </div>
    """
  end

  defp analysis_state(%{analysis: nil} = assigns) do
    ~H"""
    <div class="analyzer-empty">
      Pulsa notas en el diapasón para identificar un acorde
    </div>
    """
  end

  defp analysis_state(%{analysis: {:single, _note}} = assigns) do
    ~H"""
    <div class="analyzer-single-note">
      Nota: {@analysis |> elem(1)}
    </div>
    """
  end

  defp analysis_state(%{analysis: {:interval, _note_a, _note_b, _label}} = assigns) do
    ~H"""
    <div class="analyzer-interval">
      Intervalo: {@analysis |> elem(1)}-{@analysis |> elem(2)} ({@analysis |> elem(3)})
    </div>
    """
  end

  defp analysis_state(%{analysis: {:chords, _notes, _bass, interpretations}} = assigns)
       when interpretations == [] do
    ~H"""
    <div class="analyzer-empty">
      No se encontró un acorde para estas notas.
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

  @doc """
  Computes the analysis state from the marked notes and tuning.

  Returns one of:
    - `{:empty}` — no notes marked
    - `{:single, note}` — one note marked
    - `{:interval, note_a, note_b, label}` — two notes marked
    - `{:chords, notes, bass, interpretations}` — three or more notes marked
  """
  @spec analyzer_state(map(), [String.t()]) ::
          {:empty}
          | {:single, String.t()}
          | {:interval, String.t(), String.t(), String.t()}
          | {:chords, [String.t()], String.t(), [map()]}
  def analyzer_state(marked_notes, tuning) do
    positions =
      marked_notes
      |> Enum.sort_by(fn {string, _fret} -> string end, :desc)
      |> Enum.map(fn {string, fret} ->
        open_note = Enum.at(tuning, string)
        note = Music.note_at(open_note, fret)
        {string, fret, note}
      end)

    # Deduplicate by pitch class — multiple marked positions that
    # produce the same note name count as one unique pitch class.
    unique_notes =
      positions
      |> Enum.map(&elem(&1, 2))
      |> Enum.uniq_by(&Music.note_index/1)

    case unique_notes do
      [] ->
        {:empty}

      [note] ->
        {:single, note}

      [note_a, note_b] ->
        label = interval_label(note_a, note_b)
        {:interval, note_a, note_b, label}

      _ ->
        # Three or more unique pitch classes — sort positions by pitch
        # (lowest first) so the first is the bass.
        sorted = Enum.sort_by(positions, fn {string, fret, _note} -> {string, fret} end, :desc)
        notes = Enum.map(sorted, &elem(&1, 2))
        bass = hd(notes)
        interpretations = Music.analyze_notes(notes, bass)
        {:chords, notes, bass, interpretations}
    end
  end

  @doc """
  Returns the interval name between two notes (e.g. "Major 3rd").
  """
  @spec interval_label(String.t(), String.t()) :: String.t()
  def interval_label(note_a, note_b) do
    idx_a = Music.note_index(note_a)
    idx_b = Music.note_index(note_b)
    semitones = rem(idx_b - idx_a + 12, 12)
    interval_name(semitones)
  end

  @interval_names %{
    0 => "Perfect Unison",
    1 => "Minor 2nd",
    2 => "Major 2nd",
    3 => "Minor 3rd",
    4 => "Major 3rd",
    5 => "Perfect 4th",
    6 => "Tritone",
    7 => "Perfect 5th",
    8 => "Augmented 5th",
    9 => "Major 6th",
    10 => "Minor 7th",
    11 => "Major 7th"
  }

  defp interval_name(semitones), do: Map.fetch!(@interval_names, semitones)

  defp inversion_label(0), do: "Root position"
  defp inversion_label(1), do: "1st inversion"
  defp inversion_label(2), do: "2nd inversion"
  defp inversion_label(3), do: "3rd inversion"
  defp inversion_label(4), do: "4th inversion"
  defp inversion_label(5), do: "5th inversion"
  defp inversion_label(6), do: "6th inversion"

  defp push_url_patch(socket, instrument, tuning, active_chords, highlighted_chord) do
    push_analyzer_patch(
      socket,
      instrument,
      tuning,
      active_chords,
      highlighted_chord,
      socket.assigns.tab,
      socket.assigns.marked_notes
    )
  end

  # Pushes a URL patch that includes the `tab` and `marked` params in addition
  # to the standard instrument/tuning/chords/highlight params. The `tab` param
  # is only included when it is not the default (`:visualizer`); the `marked`
  # param is only included when there are marked notes.
  defp push_analyzer_patch(
         socket,
         instrument,
         tuning,
         active_chords,
         highlighted_chord,
         tab,
         marked_notes
       ) do
    path =
      build_patch_path(
        instrument,
        tuning,
        active_chords,
        highlighted_chord,
        tab: tab,
        marked: marked_notes
      )

    push_patch(socket, to: path)
  end

  defp build_patch_path(instrument, tuning, active_chords, highlighted_chord, opts) do
    tab = Keyword.get(opts, :tab, :visualizer)
    marked = Keyword.get(opts, :marked, %{})

    params =
      instrument
      |> Music.encode_params(tuning, active_chords, highlighted_chord)
      |> maybe_put_tab(tab)
      |> maybe_put_marked(marked)

    query = URI.encode_query(params)
    if query == "", do: "/", else: "/?#{query}"
  end

  defp maybe_put_tab(params, :visualizer), do: params
  defp maybe_put_tab(params, :analyzer), do: Map.put(params, "tab", "analyzer")

  defp maybe_put_marked(params, marked) when map_size(marked) == 0, do: params

  defp maybe_put_marked(params, marked) do
    case Music.encode_marked(marked) do
      nil -> params
      encoded -> Map.put(params, "marked", encoded)
    end
  end

  @doc """
  Groups flat key suggestions into display rows for the UI.

  Relative modes (the 7 diatonic modes that share the same note set) are
  collapsed: the major and relative minor are shown prominently while the
  remaining 5 modes are summarized as "N modos adicionales". Non-modal
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
