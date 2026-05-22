defmodule Fretboard.Music.Scale do
  @moduledoc """
  Scale formulas and diatonic chord calculation.

  Defines scale types as semitone interval formulas and computes
  the notes and diatonic chords for a given tonic and scale type.
  """

  alias Fretboard.Music.Note

  @scale_types [
    :major,
    :minor,
    :harmonic_minor,
    :melodic_minor,
    :pentatonic_major,
    :pentatonic_minor,
    :blues,
    :dorian,
    :phrygian,
    :lydian,
    :mixolydian,
    :locrian,
    :phrygian_dominant,
    :whole_tone,
    :chromatic
  ]

  @scale_formulas %{
    major: [0, 2, 4, 5, 7, 9, 11],
    minor: [0, 2, 3, 5, 7, 8, 10],
    harmonic_minor: [0, 2, 3, 5, 7, 8, 11],
    melodic_minor: [0, 2, 3, 5, 7, 9, 11],
    pentatonic_major: [0, 2, 4, 7, 9],
    pentatonic_minor: [0, 3, 5, 7, 10],
    blues: [0, 3, 5, 6, 7, 10],
    dorian: [0, 2, 3, 5, 7, 9, 10],
    phrygian: [0, 1, 3, 5, 7, 8, 10],
    lydian: [0, 2, 4, 6, 7, 9, 11],
    mixolydian: [0, 2, 4, 5, 7, 9, 10],
    locrian: [0, 1, 3, 5, 6, 8, 10],
    phrygian_dominant: [0, 1, 4, 5, 7, 8, 10],
    whole_tone: [0, 2, 4, 6, 8, 10],
    chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  }

  @labels %{
    major: "Major",
    minor: "Minor",
    harmonic_minor: "Harmonic Minor",
    melodic_minor: "Melodic Minor",
    pentatonic_major: "Major Pentatonic",
    pentatonic_minor: "Minor Pentatonic",
    blues: "Blues",
    dorian: "Dorian",
    phrygian: "Phrygian",
    lydian: "Lydian",
    mixolydian: "Mixolydian",
    locrian: "Locrian",
    phrygian_dominant: "Phrygian Dominant",
    whole_tone: "Whole Tone",
    chromatic: "Chromatic"
  }

  @grouped_scale_types [
    {"Standard", [:major, :minor]},
    {"Minor Variants", [:harmonic_minor, :melodic_minor]},
    {"Pentatonic", [:pentatonic_major, :pentatonic_minor]},
    {"Blues", [:blues]},
    {"Modes", [:dorian, :phrygian, :lydian, :mixolydian, :locrian]},
    {"Exotic", [:phrygian_dominant, :whole_tone]},
    {"Other", [:chromatic]}
  ]

  @doc """
  Returns the list of available scale types.
  """
  @spec available_scale_types() :: [atom()]
  def available_scale_types, do: @scale_types

  @doc """
  Returns scale types organized in groups for UI display.
  """
  @spec grouped_scale_types() :: [{String.t(), [atom()]}]
  def grouped_scale_types, do: @grouped_scale_types

  @doc """
  Returns the notes of a scale given a tonic and scale type.

  ## Examples

      iex> Fretboard.Music.Scale.scale_notes("C", :major)
      ["C", "D", "E", "F", "G", "A", "B"]
  """
  @spec scale_notes(String.t(), atom()) :: [String.t()]
  def scale_notes(tonic, scale_type) do
    Map.fetch!(@scale_formulas, scale_type)
    |> Enum.map(&Note.note_at(tonic, &1))
  end

  @doc """
  Returns the diatonic chords for a key as maps with `:root` and `:quality`.

  ## Examples

      iex> Fretboard.Music.Scale.diatonic_chords("C", :major)
      [%{root: "C", quality: :major}, %{root: "D", quality: :minor}, %{root: "E", quality: :minor}, %{root: "F", quality: :major}, %{root: "G", quality: :major}, %{root: "A", quality: :minor}, %{root: "B", quality: :dim}]
  """
  @spec diatonic_chords(String.t(), atom()) :: [%{root: String.t(), quality: atom()}]
  def diatonic_chords(tonic, scale_type) do
    formula = Map.fetch!(@scale_formulas, scale_type)
    notes = Enum.map(formula, &Note.note_at(tonic, &1))
    semitone_set = MapSet.new(formula)

    Enum.zip(notes, formula)
    |> Enum.map(fn {note, root_semitone} ->
      quality = infer_quality(root_semitone, semitone_set)
      %{root: note, quality: quality}
    end)
  end

  @doc """
  Infers the chord quality for a scale degree by analyzing
  which intervals from that root exist within the scale.

  ## Examples

      iex> Fretboard.Music.Scale.infer_quality(0, MapSet.new([0, 2, 4, 5, 7, 9, 11]))
      :major
  """
  @spec infer_quality(integer(), MapSet.t()) :: atom()
  def infer_quality(root_semitone, scale_semitones) do
    intervals =
      scale_semitones
      |> Enum.map(fn s -> rem(s - root_semitone + 12, 12) end)
      |> MapSet.new()

    classify_intervals(intervals)
  end

  # Interval pattern matching for chord quality inference.
  # Priority: major > minor > dim > aug > sus2 > sus4 > partial 3rd > fallback
  @quality_rules [
    {[4, 7], :major},
    {[3, 7], :minor},
    {[3, 6], :dim},
    {[4, 8], :aug},
    {[2, 7], :sus2},
    {[5, 7], :sus4}
  ]

  defp classify_intervals(intervals) do
    case Enum.find(@quality_rules, fn {required, _} ->
           Enum.all?(required, &MapSet.member?(intervals, &1))
         end) do
      {_, quality} -> quality
      nil -> classify_partial(intervals)
    end
  end

  defp classify_partial(intervals) do
    cond do
      MapSet.member?(intervals, 4) -> :major
      MapSet.member?(intervals, 3) -> :minor
      true -> :major
    end
  end

  @doc """
  Returns the display label for a scale type.

  ## Examples

      iex> Fretboard.Music.Scale.scale_label(:major)
      "Major"
  """
  @spec scale_label(atom()) :: String.t()
  def scale_label(scale_type), do: Map.fetch!(@labels, scale_type)
end
