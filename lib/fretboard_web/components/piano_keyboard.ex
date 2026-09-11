defmodule FretboardWeb.PianoKeyboard do
  @moduledoc """
  SVG piano keyboard component for the fixed C3-B5 range.

  Renders one key per pitch with physically correct black-key offsets and
  overlays chord-note markers using the same palette, overlap, and highlight
  conventions as the fretboard note circles. Visible note labels appear only
  on active keys; every key carries an accessible name via its SVG title.
  """

  use FretboardWeb, :html

  alias FretboardWeb.FretboardSVG

  @first_pitch 48

  # Layout geometry in SVG units.
  @white_key_width 36
  @black_key_width 20
  @white_key_height 160
  @black_key_height 100
  @white_key_count 21
  @svg_width @white_key_count * @white_key_width

  # Black pitch classes (C#, D#, F#, G#, A#) and each black key's left
  # offset as a fraction of the white key width, measured from the left
  # edge of its lower natural key: G# sits centered while C#/F# shift
  # left and D#/A# shift right, matching a real keyboard.
  @black_pitch_classes [1, 3, 6, 8, 10]
  @black_offsets %{1 => 0.62, 3 => 0.81, 6 => 0.58, 8 => 0.71, 10 => 0.86}

  attr :keys, :list, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil

  @doc """
  Renders the fixed C3-B5 keyboard with chord-note markers on active keys.
  """
  def piano_keyboard(assigns) do
    assigns =
      assigns
      |> assign(:white_keys, Enum.reject(assigns.keys, &black?(&1.pitch)))
      |> assign(:black_keys, Enum.filter(assigns.keys, &black?(&1.pitch)))
      |> assign(:view_box, "0 0 #{@svg_width} #{@white_key_height}")

    ~H"""
    <div
      class="piano-wrapper"
      id="piano-keyboard"
      role="img"
      aria-label="Piano keyboard from C3 to B5"
    >
      <svg viewBox={@view_box} class="piano-svg" style="min-width: 900px;">
        <%!-- White keys first so the black keys paint (and hit-test) on top. --%>
        <.piano_key
          :for={key_data <- @white_keys}
          key_data={key_data}
          active_chords={@active_chords}
          chord_colors={@chord_colors}
          highlighted_chord={@highlighted_chord}
        />
        <.piano_key
          :for={key_data <- @black_keys}
          key_data={key_data}
          active_chords={@active_chords}
          chord_colors={@chord_colors}
          highlighted_chord={@highlighted_chord}
        />
      </svg>
    </div>
    """
  end

  attr :keys, :list, required: true
  attr :selected_keys, :list, required: true

  @doc """
  Renders the fixed C3-B5 keyboard as accessible analyzer controls.
  """
  def piano_analyzer(assigns) do
    assigns =
      assigns
      |> assign(:white_keys, Enum.reject(assigns.keys, &black?(&1.pitch)))
      |> assign(:black_keys, Enum.filter(assigns.keys, &black?(&1.pitch)))
      |> assign(:selected, MapSet.new(assigns.selected_keys))
      |> assign(:view_box, "0 0 #{@svg_width} #{@white_key_height}")

    ~H"""
    <div
      class="piano-wrapper piano-wrapper--interactive"
      id="piano-analyzer"
      role="group"
      aria-label="Piano analyzer keyboard from C3 to B5"
    >
      <svg viewBox={@view_box} class="piano-svg" style="min-width: 900px;">
        <.analyzer_key
          :for={key_data <- @white_keys}
          key_data={key_data}
          selected={MapSet.member?(@selected, key_data.pitch)}
        />
        <.analyzer_key
          :for={key_data <- @black_keys}
          key_data={key_data}
          selected={MapSet.member?(@selected, key_data.pitch)}
        />
      </svg>
    </div>
    """
  end

  attr :key_data, :map, required: true
  attr :active_chords, :list, required: true
  attr :chord_colors, :list, required: true
  attr :highlighted_chord, :any, default: nil

  defp piano_key(assigns) do
    pitch = assigns.key_data.pitch

    assigns =
      assigns
      |> assign(:key_class, "piano-key piano-key--#{key_color(pitch)}")
      |> assign(:x, key_x(pitch))
      |> assign(:width, key_width(pitch))
      |> assign(:height, key_height(pitch))
      |> assign(:key_name, key_name(assigns.key_data))

    ~H"""
    <g class={@key_class} data-pitch={@key_data.pitch}>
      <title>{@key_name}</title>
      <rect class="piano-key-rect" x={@x} y="0" width={@width} height={@height} rx="2" />
      <.key_marker
        :if={@key_data.chords != []}
        key_data={@key_data}
        active_chords={@active_chords}
        chord_colors={@chord_colors}
        highlighted_chord={@highlighted_chord}
      />
    </g>
    """
  end

  attr :key_data, :map, required: true
  attr :selected, :boolean, required: true

  defp analyzer_key(assigns) do
    pitch = assigns.key_data.pitch
    selected_class = if assigns.selected, do: " piano-key--selected", else: ""

    assigns =
      assigns
      |> assign(:key_class, "piano-key piano-key--#{key_color(pitch)}#{selected_class}")
      |> assign(:x, key_x(pitch))
      |> assign(:width, key_width(pitch))
      |> assign(:height, key_height(pitch))
      |> assign(:cx, key_x(pitch) + div(key_width(pitch), 2))
      |> assign(:cy, marker_cy(pitch))
      |> assign(:key_name, key_name(assigns.key_data))

    ~H"""
    <g
      id={"piano-analyzer-key-#{@key_data.pitch}"}
      class={@key_class}
      data-pitch={@key_data.pitch}
      role="button"
      tabindex="0"
      aria-label={@key_name}
      aria-pressed={to_string(@selected)}
      phx-hook="PianoKey"
      phx-click="toggle_piano_key"
      phx-keydown="toggle_piano_key"
      phx-value-pitch={@key_data.pitch}
    >
      <rect class="piano-key-rect" x={@x} y="0" width={@width} height={@height} rx="2" />
      <circle
        :if={@selected}
        class="piano-key-marker"
        cx={@cx}
        cy={@cy}
        r="10"
        fill="#4FC3F7"
      />
      <text
        :if={@selected}
        class="piano-note-label"
        x={@cx}
        y={@cy + 4}
      >
        {@key_data.note}
      </text>
    </g>
    """
  end

  defp key_marker(assigns) do
    key = assigns.key_data

    fill =
      FretboardSVG.note_fill(
        key.chords,
        assigns.active_chords,
        assigns.chord_colors,
        assigns.highlighted_chord
      )

    assigns =
      assigns
      |> assign(:fill, fill)
      |> assign(:cx, key_x(key.pitch) + div(key_width(key.pitch), 2))
      |> assign(:cy, marker_cy(key.pitch))
      |> assign(:note, key.note)

    ~H"""
    <circle class="piano-key-marker" cx={@cx} cy={@cy} r="10" fill={@fill} />
    <text
      class="piano-note-label"
      x={@cx}
      y={@cy + 4}
      fill="#1a1a1a"
      font-size="11"
      font-weight="bold"
      text-anchor="middle"
      style="pointer-events: none;"
    >
      {@note}
    </text>
    """
  end

  # ---------------------------------------------------------------------------
  # Geometry helpers
  # ---------------------------------------------------------------------------

  defp black?(pitch), do: rem(pitch, 12) in @black_pitch_classes

  defp key_color(pitch), do: if(black?(pitch), do: "black", else: "white")

  defp key_width(pitch), do: if(black?(pitch), do: @black_key_width, else: @white_key_width)

  defp key_height(pitch), do: if(black?(pitch), do: @black_key_height, else: @white_key_height)

  defp key_x(pitch) when rem(pitch, 12) in @black_pitch_classes do
    left_white = whites_before(pitch - 1)
    offset = Map.fetch!(@black_offsets, rem(pitch, 12))
    (left_white + offset) * @white_key_width
  end

  defp key_x(pitch), do: whites_before(pitch) * @white_key_width

  # Number of white keys strictly left of the key for `pitch` within the
  # fixed range starting at C3 (@first_pitch).
  defp whites_before(pitch) when pitch <= @first_pitch, do: 0

  defp whites_before(pitch) do
    Enum.count(@first_pitch..(pitch - 1), fn candidate -> not black?(candidate) end)
  end

  defp marker_cy(pitch) when rem(pitch, 12) in @black_pitch_classes,
    do: @black_key_height - 22

  defp marker_cy(_pitch), do: @white_key_height - 26

  defp key_name(%{pitch: pitch, note: note}), do: "#{note}#{div(pitch, 12) - 1}"
end
