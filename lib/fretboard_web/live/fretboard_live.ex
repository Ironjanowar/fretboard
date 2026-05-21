defmodule FretboardWeb.FretboardLive do
  @moduledoc """
  Main LiveView for the fretboard visualizer.

  Renders an SVG guitar fretboard with 24 frets and 6 strings.
  Supports adding/removing chords, coloring notes by chord,
  and clickable tuning labels.
  """

  use FretboardWeb, :live_view

  alias Fretboard.Music

  @fret_count 24
  @string_count 6
  @marker_frets [3, 5, 7, 9, 12, 15, 17, 19, 21, 24]
  @double_marker_frets MapSet.new([12, 24])

  # SVG layout constants
  @left_margin 60
  @top_margin 40
  @fret_width 50
  @string_spacing 20

  @chromatic_notes ~w(C C# D D# E F F# G G# A A# B)

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

  @overlap_color "#9E9E9E"

  @impl true
  def mount(params, _session, socket) do
    {tuning, active_chords} = Music.decode_params(params)
    fretboard = Music.fretboard_data(tuning, active_chords)

    {:ok,
     assign(socket,
       tuning: tuning,
       active_chords: active_chords,
       fretboard: fretboard,
       svg: svg_params(),
       chord_form: %{"root" => "C", "quality" => "major"},
       chord_colors: @chord_colors,
       chromatic_notes: @chromatic_notes,
       show_tuning_modal: false,
       modal_tuning: tuning,
       modal_preset: detect_preset(tuning)
     )}
  end

  defp svg_params do
    fb_w = @left_margin + (@fret_count + 1) * @fret_width
    fb_h = @top_margin + (@string_count + 1) * @string_spacing

    %{
      left_margin: @left_margin,
      top_margin: @top_margin,
      fret_width: @fret_width,
      string_spacing: @string_spacing,
      fret_count: @fret_count,
      string_count: @string_count,
      width: fb_w,
      height: fb_h,
      marker_frets: @marker_frets,
      double_marker_frets: @double_marker_frets
    }
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {tuning, active_chords} = Music.decode_params(params)
    fretboard = Music.fretboard_data(tuning, active_chords)

    {:noreply,
     assign(socket,
       tuning: tuning,
       active_chords: active_chords,
       fretboard: fretboard,
       modal_tuning: tuning,
       modal_preset: detect_preset(tuning)
     )}
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
      {:noreply, push_url_patch(socket, socket.assigns.tuning, active_chords)}
    end
  end

  @impl true
  def handle_event("remove_chord", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    active_chords = List.delete_at(socket.assigns.active_chords, index)
    {:noreply, push_url_patch(socket, socket.assigns.tuning, active_chords)}
  end

  @impl true
  def handle_event("open_tuning_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_tuning_modal: true,
       modal_tuning: socket.assigns.tuning,
       modal_preset: detect_preset(socket.assigns.tuning)
     )}
  end

  @impl true
  def handle_event("close_tuning_modal", _params, socket) do
    {:noreply, assign(socket, show_tuning_modal: false)}
  end

  @impl true
  def handle_event("select_preset", %{"preset" => preset_name}, socket) do
    presets = Music.tuning_presets()

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
     assign(socket, modal_tuning: modal_tuning, modal_preset: detect_preset(modal_tuning))}
  end

  @impl true
  def handle_event("apply_tuning", _params, socket) do
    tuning = socket.assigns.modal_tuning

    {:noreply,
     socket
     |> assign(show_tuning_modal: false)
     |> push_url_patch(tuning, socket.assigns.active_chords)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-6 p-6">
      <%!-- Controls: Tuning + Chord Selector --%>
      <div class="w-full max-w-7xl">
        <div class="flex items-center gap-3">
          <button
            type="button"
            phx-click="open_tuning_modal"
            class="bg-gray-700 hover:bg-gray-600 text-white font-bold px-4 py-2 rounded"
          >
            🎸 Tuning
          </button>
          <form
            id="chord-form"
            phx-change="validate_chord"
            phx-submit="add_chord"
            class="flex items-center gap-3"
          >
            <select
              id="root-select"
              name="chord[root]"
              class="bg-gray-800 text-white border border-gray-600 rounded px-3 py-2"
            >
              <%= for note <- @chromatic_notes do %>
                <option value={note} selected={@chord_form["root"] == note}>{note}</option>
              <% end %>
            </select>
            <select
              id="quality-select"
              name="chord[quality]"
              class="bg-gray-800 text-white border border-gray-600 rounded px-3 py-2"
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
              class="bg-blue-600 hover:bg-blue-700 text-white font-bold px-4 py-2 rounded"
            >
              Add
            </button>
          </form>
        </div>
      </div>

      <%!-- SVG Fretboard --%>
      <div class="w-full max-w-7xl overflow-x-auto" id="fretboard">
        <svg
          viewBox={"0 0 #{@svg.width} #{@svg.height}"}
          class="w-full"
          style="min-width: 900px;"
        >
          <%!-- Fretboard background --%>
          <rect
            x={@svg.left_margin}
            y={@svg.top_margin}
            width={@svg.fret_count * @svg.fret_width + @svg.fret_width}
            height={(@svg.string_count - 1) * @svg.string_spacing}
            fill="#3E2723"
            rx="2"
          />

          <%!-- Nut (fret 0) --%>
          <line
            class="nut-line"
            x1={@svg.left_margin}
            y1={@svg.top_margin - 2}
            x2={@svg.left_margin}
            y2={@svg.top_margin + (@svg.string_count - 1) * @svg.string_spacing + 2}
            stroke="#FAFAFA"
            stroke-width="5"
          />

          <%!-- Fret lines --%>
          <%= for fret <- 0..@svg.fret_count do %>
            <line
              class="fret-line"
              x1={@svg.left_margin + fret * @svg.fret_width}
              y1={@svg.top_margin}
              x2={@svg.left_margin + fret * @svg.fret_width}
              y2={@svg.top_margin + (@svg.string_count - 1) * @svg.string_spacing}
              stroke="#9E9E9E"
              stroke-width="1"
            />
          <% end %>

          <%!-- Fret markers --%>
          <%= for fret <- @svg.marker_frets do %>
            <%= if MapSet.member?(@svg.double_marker_frets, fret) do %>
              <circle
                class="fret-marker"
                cx={@svg.left_margin + (fret - 1) * @svg.fret_width + div(@svg.fret_width, 2)}
                cy={@svg.top_margin + @svg.string_spacing * 1}
                r="4"
                fill="#BDBDBD"
              />
              <circle
                class="fret-marker"
                cx={@svg.left_margin + (fret - 1) * @svg.fret_width + div(@svg.fret_width, 2)}
                cy={@svg.top_margin + @svg.string_spacing * 3}
                r="4"
                fill="#BDBDBD"
              />
            <% else %>
              <circle
                class="fret-marker"
                cx={@svg.left_margin + (fret - 1) * @svg.fret_width + div(@svg.fret_width, 2)}
                cy={@svg.top_margin + div((@svg.string_count - 1) * @svg.string_spacing, 2)}
                r="4"
                fill="#BDBDBD"
              />
            <% end %>
          <% end %>

          <%!-- Strings (reversed: high E at top, low E at bottom) --%>
          <%= for s <- 0..(@svg.string_count - 1) do %>
            <% _string_idx = @svg.string_count - 1 - s %>
            <line
              class="string-line"
              x1={@svg.left_margin}
              y1={@svg.top_margin + s * @svg.string_spacing}
              x2={@svg.left_margin + (@svg.fret_count + 1) * @svg.fret_width}
              y2={@svg.top_margin + s * @svg.string_spacing}
              stroke="#E0E0E0"
              stroke-width={1.5 + s * 0.3}
            />
          <% end %>

          <%!-- Tuning labels (informational only, reversed: high E at top, low E at bottom) --%>
          <%= for {note, string_idx} <- Enum.with_index(@tuning) do %>
            <% visual_row = @svg.string_count - 1 - string_idx %>
            <text
              class="tuning-label"
              x={@svg.left_margin - 15}
              y={@svg.top_margin + visual_row * @svg.string_spacing + 5}
              fill="#FAFAFA"
              font-size="14"
              font-weight="bold"
              text-anchor="end"
            >
              {note}
            </text>
          <% end %>

          <%!-- Fret numbers --%>
          <%= for fret <- 1..@svg.fret_count do %>
            <text
              x={@svg.left_margin + (fret - 1) * @svg.fret_width + div(@svg.fret_width, 2)}
              y={@svg.top_margin - 10}
              fill="#9E9E9E"
              font-size="10"
              text-anchor="middle"
            >
              {fret}
            </text>
          <% end %>

          <%!-- Note circles (only when chords are active, reversed string order) --%>
          <%= if @active_chords != [] do %>
            <%= for {string_data, string_idx} <- Enum.with_index(@fretboard) do %>
              <% visual_row = @svg.string_count - 1 - string_idx %>
              <%= for pos <- string_data do %>
                <%= if pos.chords != [] do %>
                  <g style="cursor: pointer;">
                    <%= if length(pos.chords) > 1 do %>
                      <title>{Enum.join(pos.chords, ", ")}</title>
                    <% end %>
                    <circle
                      class="note-circle"
                      cx={note_cx(pos.fret, @svg)}
                      cy={@svg.top_margin + visual_row * @svg.string_spacing}
                      r="8"
                      fill={note_fill(pos.chords, @active_chords, @chord_colors)}
                    />
                    <text
                      x={note_cx(pos.fret, @svg)}
                      y={@svg.top_margin + visual_row * @svg.string_spacing + 4}
                      fill="#1a1a1a"
                      font-size="9"
                      font-weight="bold"
                      text-anchor="middle"
                      style="pointer-events: none;"
                    >
                      {pos.note}
                    </text>
                  </g>
                <% end %>
              <% end %>
            <% end %>
          <% end %>
        </svg>
      </div>

      <%!-- Active chords chips --%>
      <div class="w-full max-w-7xl flex flex-wrap gap-2">
        <%= for {chord, i} <- Enum.with_index(@active_chords) do %>
          <span
            class="chord-chip inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm font-semibold text-gray-900"
            style={"background-color: #{Enum.at(@chord_colors, rem(i, length(@chord_colors)))}"}
          >
            {Music.chord_label(chord.root, chord.quality)}
            <button
              type="button"
              phx-click="remove_chord"
              phx-value-index={i}
              class="ml-1 text-gray-700 hover:text-black font-bold"
            >
              ×
            </button>
          </span>
        <% end %>
      </div>

      <%!-- Tuning Modal --%>
      <%= if @show_tuning_modal do %>
        <div
          id="tuning-modal"
          class="tuning-modal fixed inset-0 z-50 flex items-center justify-center"
        >
          <div class="absolute inset-0 bg-black bg-opacity-60" phx-click="close_tuning_modal"></div>
          <div class="relative bg-gray-900 border border-gray-700 rounded-lg p-6 w-96 max-w-full">
            <h2 class="text-white text-xl font-bold mb-4">Tuning</h2>

            <%!-- Preset Dropdown --%>
            <form phx-change="select_preset" class="mb-4">
              <label class="text-gray-400 text-sm block mb-1">Preset</label>
              <select
                id={"preset-select-#{@modal_preset}"}
                class="preset-select w-full bg-gray-800 text-white border border-gray-600 rounded px-3 py-2"
                name="preset"
              >
                <%= for name <- Music.tuning_preset_names() do %>
                  <option value={name} selected={@modal_preset == name}>{name}</option>
                <% end %>
                <option value="Custom" selected={@modal_preset == "Custom"}>Custom</option>
              </select>
            </form>

            <%!-- Individual String Dropdowns (String 6 to String 1, top to bottom) --%>
            <div class="space-y-2 mb-6">
              <%= for string_num <- 6..1//-1 do %>
                <% string_idx = string_num - 1 %>
                <% current_note = Enum.at(@modal_tuning, string_idx) %>
                <form phx-change="change_string" class="flex items-center gap-3">
                  <label class="text-gray-400 text-sm w-16">String {string_num}</label>
                  <input type="hidden" name="string" value={string_idx} />
                  <select
                    id={"string-select-#{string_idx}-#{current_note}"}
                    class="string-select flex-1 bg-gray-800 text-white border border-gray-600 rounded px-3 py-2"
                    name="note"
                  >
                    <%= for note <- @chromatic_notes do %>
                      <option value={note} selected={note == current_note}>
                        {note}
                      </option>
                    <% end %>
                  </select>
                </form>
              <% end %>
            </div>

            <%!-- Buttons --%>
            <div class="flex justify-end gap-3">
              <button
                type="button"
                phx-click="close_tuning_modal"
                class="px-4 py-2 rounded text-gray-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="button"
                phx-click="apply_tuning"
                class="bg-blue-600 hover:bg-blue-700 text-white font-bold px-4 py-2 rounded"
              >
                Apply
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Computes the SVG x-coordinate for a note at a given fret.
  """
  @spec note_cx(non_neg_integer(), map()) :: non_neg_integer()
  def note_cx(0, svg), do: svg.left_margin

  def note_cx(fret, svg),
    do: svg.left_margin + (fret - 1) * svg.fret_width + div(svg.fret_width, 2)

  @doc """
  Determines the fill color for a note based on which chords it belongs to.

  Single chord notes get that chord's color. Overlapping notes get neutral gray.
  """
  @spec note_fill([String.t()], [map()], [String.t()]) :: String.t()
  def note_fill(chords, _active_chords, _colors) when length(chords) > 1, do: @overlap_color

  def note_fill([chord_label], active_chords, colors) do
    index =
      Enum.find_index(active_chords, fn c ->
        Music.chord_label(c.root, c.quality) == chord_label
      end)

    if index, do: Enum.at(colors, rem(index, length(colors))), else: @overlap_color
  end

  def note_fill(_, _, _), do: @overlap_color

  @doc """
  Detects which preset matches a given tuning, or returns "Custom".
  """
  @spec detect_preset([String.t()]) :: String.t()
  def detect_preset(tuning) do
    case Enum.find(Music.tuning_presets(), fn {_name, notes} -> notes == tuning end) do
      {name, _notes} -> name
      nil -> "Custom"
    end
  end

  defp push_url_patch(socket, tuning, active_chords) do
    params = Music.encode_params(tuning, active_chords)
    query = URI.encode_query(params)
    path = if query == "", do: "/", else: "/?#{query}"
    push_patch(socket, to: path)
  end
end
