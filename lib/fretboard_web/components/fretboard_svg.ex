defmodule FretboardWeb.FretboardSVG do
  @moduledoc """
  SVG fretboard rendering component.

  Renders the guitar/bass fretboard with fret lines, markers, strings,
  tuning labels, and note circles for active chords.
  """

  use FretboardWeb, :html

  alias Fretboard.Music

  @overlap_color "#9E9E9E"

  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :fretboard, :list, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil

  def fretboard_svg(assigns) do
    ~H"""
    <div
      class="fretboard-wrapper"
      id="fretboard"
      phx-hook="FretboardPanZoom"
      data-initial-view-box={"0 0 #{@svg.width} #{@svg.height}"}
      style="touch-action: none; overflow: hidden;"
    >
      <svg class="fretboard-svg">
        <.fretboard_background svg={@svg} />
        <.fret_lines svg={@svg} />
        <.fret_markers svg={@svg} />
        <.string_lines svg={@svg} />
        <.tuning_labels svg={@svg} tuning={@tuning} />
        <.fret_numbers svg={@svg} />
        <.note_circles
          svg={@svg}
          fretboard={@fretboard}
          active_chords={@active_chords}
          chord_colors={@chord_colors}
          highlighted_chord={@highlighted_chord}
        />
      </svg>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Analyzer fretboard: ALL positions are clickable, marked ones are visible.
  # ---------------------------------------------------------------------------

  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :marked_notes, :map, required: true

  def analyzer_fretboard_svg(assigns) do
    ~H"""
    <div
      class="fretboard-wrapper"
      id="analyzer-fretboard"
      phx-hook="FretboardPanZoom"
      data-initial-view-box={"0 0 #{@svg.width} #{@svg.height}"}
      style="touch-action: none; overflow: hidden;"
    >
      <svg class="fretboard-svg">
        <.fretboard_background svg={@svg} />
        <.fret_lines svg={@svg} />
        <.fret_markers svg={@svg} />
        <.string_lines svg={@svg} />
        <.tuning_labels svg={@svg} tuning={@tuning} />
        <.fret_numbers svg={@svg} />
        <.analyzer_positions svg={@svg} tuning={@tuning} marked_notes={@marked_notes} />
      </svg>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Shared scaffolding components
  # ---------------------------------------------------------------------------

  attr :svg, :map, required: true

  defp fretboard_background(assigns) do
    ~H"""
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
    """
  end

  attr :svg, :map, required: true

  defp fret_lines(assigns) do
    ~H"""
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
    """
  end

  attr :svg, :map, required: true

  defp fret_markers(assigns) do
    ~H"""
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
    """
  end

  attr :svg, :map, required: true

  defp string_lines(assigns) do
    ~H"""
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
    """
  end

  attr :svg, :map, required: true
  attr :tuning, :list, required: true

  defp tuning_labels(assigns) do
    ~H"""
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
    """
  end

  attr :svg, :map, required: true

  defp fret_numbers(assigns) do
    ~H"""
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
    """
  end

  # ---------------------------------------------------------------------------
  # Note circles (visualizer)
  # ---------------------------------------------------------------------------

  attr :svg, :map, required: true
  attr :fretboard, :list, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil

  defp note_circles(assigns) do
    ~H"""
    <%!-- Note circles (reversed string order). The inner loops produce
         nothing when the fretboard or active chords are empty, so no
         outer guard is needed. --%>
    <%= for {string_data, string_idx} <- Enum.with_index(@fretboard) do %>
      <% visual_row = @svg.string_count - 1 - string_idx %>
      <%= for pos <- string_data do %>
        <.note_circle
          :if={pos.chords != []}
          pos={pos}
          svg={@svg}
          visual_row={visual_row}
          active_chords={@active_chords}
          chord_colors={@chord_colors}
          highlighted_chord={@highlighted_chord}
        />
      <% end %>
    <% end %>
    """
  end

  attr :pos, :map, required: true
  attr :svg, :map, required: true
  attr :visual_row, :integer, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil

  defp note_circle(assigns) do
    ~H"""
    <g style="cursor: pointer;">
      <title :if={length(@pos.chords) > 1}>{Enum.join(@pos.chords, ", ")}</title>
      <circle
        class="note-circle"
        cx={note_cx(@pos.fret, @svg)}
        cy={@svg.top_margin + @visual_row * @svg.string_spacing}
        r="8"
        fill={note_fill(@pos.chords, @active_chords, @chord_colors, @highlighted_chord)}
      />
      <text
        x={note_cx(@pos.fret, @svg)}
        y={@svg.top_margin + @visual_row * @svg.string_spacing + 4}
        fill="#1a1a1a"
        font-size="9"
        font-weight="bold"
        text-anchor="middle"
        style="pointer-events: none;"
      >
        {@pos.note}
      </text>
    </g>
    """
  end

  # ---------------------------------------------------------------------------
  # Analyzer interactive positions
  # ---------------------------------------------------------------------------

  attr :svg, :map, required: true
  attr :tuning, :list, required: true
  attr :marked_notes, :map, required: true

  defp analyzer_positions(assigns) do
    ~H"""
    <%!-- Interactive positions: ALL string/fret intersections are clickable --%>
    <%= for {open_note, string_idx} <- Enum.with_index(@tuning) do %>
      <% visual_row = @svg.string_count - 1 - string_idx %>
      <%= for fret <- 0..@svg.fret_count do %>
        <.analyzer_position
          svg={@svg}
          open_note={open_note}
          string_idx={string_idx}
          visual_row={visual_row}
          fret={fret}
          is_marked={Map.get(@marked_notes, string_idx) == fret}
        />
      <% end %>
    <% end %>
    """
  end

  attr :svg, :map, required: true
  attr :open_note, :string, required: true
  attr :string_idx, :integer, required: true
  attr :visual_row, :integer, required: true
  attr :fret, :integer, required: true
  attr :is_marked, :boolean, required: true

  defp analyzer_position(assigns) do
    ~H"""
    <% note = Music.note_at(@open_note, @fret) %>
    <g phx-click="toggle_note" phx-value-string={@string_idx} phx-value-fret={@fret}>
      <%= if @is_marked do %>
        <circle
          class="analyzer-note-circle"
          cx={note_cx(@fret, @svg)}
          cy={@svg.top_margin + @visual_row * @svg.string_spacing}
          r="8"
        />
        <text
          class="analyzer-note-text"
          x={note_cx(@fret, @svg)}
          y={@svg.top_margin + @visual_row * @svg.string_spacing + 3}
        >
          {note}
        </text>
      <% else %>
        <circle
          class="analyzer-position"
          cx={note_cx(@fret, @svg)}
          cy={@svg.top_margin + @visual_row * @svg.string_spacing}
          r="9"
          fill="#4FC3F7"
        />
      <% end %>
    </g>
    """
  end

  # ---------------------------------------------------------------------------
  # Coordinate helpers
  # ---------------------------------------------------------------------------

  @doc """
  Computes the SVG x-coordinate for a note at a given fret.
  """
  @spec note_cx(non_neg_integer(), map()) :: non_neg_integer()
  def note_cx(0, svg), do: svg.left_margin

  def note_cx(fret, svg),
    do: svg.left_margin + (fret - 1) * svg.fret_width + div(svg.fret_width, 2)

  # ---------------------------------------------------------------------------
  # Fill color helpers
  # ---------------------------------------------------------------------------

  @doc """
  Determines the fill color for a note based on which chords it belongs to.

  When a chord is highlighted, its notes render in that chord's color.
  All other notes render in gray. When no chord is highlighted,
  single chord notes get that chord's color, overlapping notes get neutral gray.
  """
  @spec note_fill([String.t()], [map()], [String.t()], non_neg_integer() | nil) :: String.t()
  def note_fill(chords, active_chords, colors, highlighted_chord)
      when is_integer(highlighted_chord) do
    highlighted = Enum.at(active_chords, highlighted_chord)
    highlighted_label = Music.chord_label(highlighted.root, highlighted.quality)

    fill_for_highlighted(chords, colors, highlighted_chord, highlighted_label)
  end

  def note_fill(chords, _active_chords, _colors, nil) when length(chords) > 1,
    do: @overlap_color

  def note_fill([chord_label], active_chords, colors, nil) do
    index =
      Enum.find_index(active_chords, fn c ->
        Music.chord_label(c.root, c.quality) == chord_label
      end)

    fill_for_index(index, colors)
  end

  def note_fill(_, _, _, nil), do: @overlap_color

  defp fill_for_highlighted(chords, colors, highlighted_chord, highlighted_label) do
    if highlighted_label in chords do
      Enum.at(colors, rem(highlighted_chord, length(colors)))
    else
      @overlap_color
    end
  end

  defp fill_for_index(nil, _colors), do: @overlap_color

  defp fill_for_index(index, colors), do: Enum.at(colors, rem(index, length(colors)))
end
