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
  def mount(_params, _session, socket) do
    tuning = Music.standard_tuning()
    active_chords = []
    fretboard = Music.fretboard_data(tuning, active_chords)

    {:ok,
     assign(socket,
       tuning: tuning,
       active_chords: active_chords,
       fretboard: fretboard,
       svg: svg_params(),
       chord_form: %{"root" => "C", "quality" => "major"},
       chord_colors: @chord_colors,
       chromatic_notes: @chromatic_notes
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
      fretboard = Music.fretboard_data(socket.assigns.tuning, active_chords)
      {:noreply, assign(socket, active_chords: active_chords, fretboard: fretboard)}
    end
  end

  @impl true
  def handle_event("remove_chord", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    active_chords = List.delete_at(socket.assigns.active_chords, index)
    fretboard = Music.fretboard_data(socket.assigns.tuning, active_chords)
    {:noreply, assign(socket, active_chords: active_chords, fretboard: fretboard)}
  end

  @impl true
  def handle_event("cycle_tuning", %{"string" => string_str}, socket) do
    string_idx = String.to_integer(string_str)
    current_note = Enum.at(socket.assigns.tuning, string_idx)
    current_pos = Enum.find_index(@chromatic_notes, &(&1 == current_note))
    next_note = Enum.at(@chromatic_notes, rem(current_pos + 1, 12))
    tuning = List.replace_at(socket.assigns.tuning, string_idx, next_note)
    fretboard = Music.fretboard_data(tuning, socket.assigns.active_chords)
    {:noreply, assign(socket, tuning: tuning, fretboard: fretboard)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-6 p-6">
      <%!-- Chord Selector --%>
      <div class="w-full max-w-7xl">
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
            <%= for q <- Music.available_qualities() do %>
              <option value={q} selected={@chord_form["quality"] == Atom.to_string(q)}>{q}</option>
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

          <%!-- Strings --%>
          <%= for s <- 0..(@svg.string_count - 1) do %>
            <line
              class="string-line"
              x1={@svg.left_margin}
              y1={@svg.top_margin + s * @svg.string_spacing}
              x2={@svg.left_margin + (@svg.fret_count + 1) * @svg.fret_width}
              y2={@svg.top_margin + s * @svg.string_spacing}
              stroke="#E0E0E0"
              stroke-width={1.5 + (5 - s) * 0.3}
            />
          <% end %>

          <%!-- Tuning labels (clickable) --%>
          <%= for {note, s} <- Enum.with_index(@tuning) do %>
            <text
              class="tuning-label"
              x={@svg.left_margin - 15}
              y={@svg.top_margin + s * @svg.string_spacing + 5}
              fill="#FAFAFA"
              font-size="14"
              font-weight="bold"
              text-anchor="end"
              style="cursor: pointer;"
              phx-click="cycle_tuning"
              phx-value-string={s}
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

          <%!-- Note circles (only when chords are active) --%>
          <%= if @active_chords != [] do %>
            <%= for {string_data, s} <- Enum.with_index(@fretboard) do %>
              <%= for pos <- string_data do %>
                <%= if pos.chords != [] do %>
                  <circle
                    class="note-circle"
                    cx={note_cx(pos.fret, @svg)}
                    cy={@svg.top_margin + s * @svg.string_spacing}
                    r="8"
                    fill={note_fill(pos.chords, @active_chords, @chord_colors)}
                  >
                    <%= if length(pos.chords) > 1 do %>
                      <title>{Enum.join(pos.chords, ", ")}</title>
                    <% end %>
                  </circle>
                  <text
                    x={note_cx(pos.fret, @svg)}
                    y={@svg.top_margin + s * @svg.string_spacing + 4}
                    fill="#1a1a1a"
                    font-size="9"
                    font-weight="bold"
                    text-anchor="middle"
                  >
                    {pos.note}
                  </text>
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
            {chord.root} {chord.quality}
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
        "#{c.root} #{c.quality}" == chord_label
      end)

    if index, do: Enum.at(colors, rem(index, length(colors))), else: @overlap_color
  end

  def note_fill(_, _, _), do: @overlap_color
end
