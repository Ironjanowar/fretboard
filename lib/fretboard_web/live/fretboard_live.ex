defmodule FretboardWeb.FretboardLive do
  @moduledoc """
  Main LiveView for the fretboard visualizer.

  Renders an SVG fretboard with 24 frets and a configurable number of
  strings (6-string guitar, 4- or 5-string bass). Supports adding/removing
  chords, coloring notes by chord, and selecting tuning presets.
  """

  use FretboardWeb, :live_view

  import FretboardWeb.FretboardSVG, only: [fretboard_svg: 1]
  import FretboardWeb.Modals

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
    {instrument, tuning, active_chords, highlighted_chord} = Music.decode_params(params)
    fretboard = Music.fretboard_data(tuning, active_chords)
    string_count = Music.instrument_strings(instrument)

    {:ok,
     assign(socket,
       instrument: instrument,
       tuning: tuning,
       active_chords: active_chords,
       highlighted_chord: highlighted_chord,
       fretboard: fretboard,
       svg: svg_params(string_count),
       chord_form: %{"root" => "C", "quality" => "major"},
       chord_colors: @chord_colors,
       chromatic_notes: Note.chromatic_scale(),
       show_tuning_modal: false,
       modal_tuning: tuning,
       modal_preset: detect_preset(tuning, instrument),
       show_key_modal: false,
       key_tonic: "C",
       key_scale_type: :major,
       key_chord_mode: :triad,
       show_key_modes: false,
       show_progression_modal: false,
       progression_id: :pop_i_v_vi_iv,
       progression_tonic: "C",
       key_suggestions: AsyncResult.loading()
     )}
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
    {instrument, tuning, active_chords, highlighted_chord} = Music.decode_params(params)
    fretboard = Music.fretboard_data(tuning, active_chords)
    string_count = Music.instrument_strings(instrument)

    chords = active_chords

    {:noreply,
     socket
     |> assign(
       instrument: instrument,
       tuning: tuning,
       active_chords: active_chords,
       highlighted_chord: highlighted_chord,
       fretboard: fretboard,
       svg: svg_params(string_count),
       modal_tuning: tuning,
       modal_preset: detect_preset(tuning, instrument),
       show_key_modes: false
     )
     |> assign_async(:key_suggestions, fn ->
       if length(chords) >= 2 do
         {:ok, %{key_suggestions: Music.suggest_keys(chords)}}
       else
         {:ok, %{key_suggestions: []}}
       end
     end)}
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

    {:noreply,
     push_url_patch(
       socket,
       new_instrument,
       new_tuning,
       socket.assigns.active_chords,
       nil
     )}
  end

  @impl true
  def handle_event("apply_suggested_key", %{"tonic" => tonic, "scale_type" => scale_type}, socket) do
    mode = infer_chord_mode(socket.assigns.active_chords)
    active_chords = Music.diatonic_chords(tonic, String.to_existing_atom(scale_type), mode)

    {:noreply,
     push_url_patch(socket, socket.assigns.instrument, socket.assigns.tuning, active_chords, nil)}
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

  @impl true
  def handle_event("toggle_key_modes", _params, socket) do
    {:noreply, assign(socket, :show_key_modes, not socket.assigns.show_key_modes)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="main-container">
      <%!-- Controls: Tuning + Chord Selector --%>
      <div class="controls-wrapper">
        <div class="controls-row">
          <button
            type="button"
            phx-click="open_tuning_modal"
            class="btn btn-secondary"
          >
            🎸 Tuning
          </button>
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
        </div>
      </div>

      <%!-- SVG Fretboard --%>
      <.fretboard_svg
        svg={@svg}
        tuning={@tuning}
        fretboard={@fretboard}
        active_chords={@active_chords}
        chord_colors={@chord_colors}
        highlighted_chord={@highlighted_chord}
      />

      <%!-- Active chords chips --%>
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

      <%!-- Key Suggestions --%>
      <.async_result :let={key_suggestions} assign={@key_suggestions}>
        <:loading>
          <div :if={length(@active_chords) >= 2} class="key-suggestions-wrapper" id="key-suggestions">
            <label class="section-label" style="width:100%">Tonalidades compatibles</label>
            <p class="key-suggestions-loading">Calculando...</p>
          </div>
        </:loading>
        <:failed :let={_failure}>
          <div :if={length(@active_chords) >= 2} class="key-suggestions-wrapper" id="key-suggestions">
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
              <%= if group.collapsed? do %>
                <%!-- Grouped modal modes: show prominent as cards, others as expandable --%>
                <%= for s <- group.prominent do %>
                  <div
                    class="key-card"
                    phx-click="apply_suggested_key"
                    phx-value-tonic={s.tonic}
                    phx-value-scale_type={s.scale_type}
                  >
                    <div class="key-card-header">
                      <span class="key-card-title">
                        {Music.scale_label(s.scale_type)} {s.tonic}
                      </span>
                      <span class="key-card-score">{s.score}/{s.total}</span>
                    </div>
                    <div class="key-card-chips">
                      <%= for {dc, i} <- Enum.with_index(s.diatonic_chords) do %>
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
                <% end %>
                <%!-- Collapsed modes toggle --%>
                <div class="key-modes-row" style="width:100%">
                  <button
                    type="button"
                    class="key-modes-toggle"
                    phx-click="toggle_key_modes"
                  >
                    ▸ {length(group.others)} modos adicionales
                  </button>
                </div>
                <%= if @show_key_modes do %>
                  <div class="key-modes-expanded" style="width:100%">
                    <%= for s <- group.others do %>
                      <div
                        class="key-card"
                        phx-click="apply_suggested_key"
                        phx-value-tonic={s.tonic}
                        phx-value-scale_type={s.scale_type}
                      >
                        <div class="key-card-header">
                          <span class="key-card-title">
                            {Music.scale_label(s.scale_type)} {s.tonic}
                          </span>
                          <span class="key-card-score">{s.score}/{s.total}</span>
                        </div>
                        <div class="key-card-chips">
                          <%= for {dc, i} <- Enum.with_index(s.diatonic_chords) do %>
                            <span
                              class="key-card-chip"
                              style={
                                chord_color(i, @chord_colors) |> then(&"background-color: #{&1};")
                              }
                            >
                              {Music.chord_label(dc.root, dc.quality)}
                            </span>
                          <% end %>
                        </div>
                        <div class="key-card-arrow">Ver tonalidad →</div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              <% else %>
                <%!-- Single (non-modal) suggestion as card --%>
                <div
                  class="key-card"
                  phx-click="apply_suggested_key"
                  phx-value-tonic={group.item.tonic}
                  phx-value-scale_type={group.item.scale_type}
                >
                  <div class="key-card-header">
                    <span class="key-card-title">
                      {Music.scale_label(group.item.scale_type)} {group.item.tonic}
                    </span>
                    <span class={"key-card-score#{if group.item.score == group.item.total, do: "", else: " key-card-score--partial"}"}>
                      {group.item.score}/{group.item.total}
                    </span>
                  </div>
                  <div class="key-card-chips">
                    <%= for {dc, i} <- Enum.with_index(group.item.diatonic_chords) do %>
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
              <% end %>
            <% end %>
          <% end %>
        </div>
      </.async_result>

      <%!-- Tuning Modal --%>
      <.tuning_modal
        show={@show_tuning_modal}
        modal_preset={@modal_preset}
        instrument={@instrument}
        modal_tuning={@modal_tuning}
        string_count={@svg.string_count}
      />

      <%!-- Key Modal --%>
      <.key_modal
        show={@show_key_modal}
        key_tonic={@key_tonic}
        key_scale_type={@key_scale_type}
        key_chord_mode={@key_chord_mode}
        chord_colors={@chord_colors}
      />

      <%!-- Progression Modal --%>
      <.progression_modal
        show={@show_progression_modal}
        progression_id={@progression_id}
        progression_tonic={@progression_tonic}
        chord_colors={@chord_colors}
      />
    </div>
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

  defp push_url_patch(socket, instrument, tuning, active_chords, highlighted_chord) do
    params = Music.encode_params(instrument, tuning, active_chords, highlighted_chord)
    query = URI.encode_query(params)
    path = if query == "", do: "/", else: "/?#{query}"
    push_patch(socket, to: path)
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
