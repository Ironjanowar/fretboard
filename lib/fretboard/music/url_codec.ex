defmodule Fretboard.Music.URLCodec do
  @moduledoc """
  Serializes and deserializes fretboard state to/from URL query parameters.

  Enables shareable URLs that restore instrument, tuning, and active chords.
  """

  alias Fretboard.Music.{Chord, Instrument, Note}

  @labels_to_quality %{
    "maj" => :major,
    "min" => :minor,
    "dim" => :dim,
    "aug" => :aug,
    "sus2" => :sus2,
    "sus4" => :sus4,
    "7" => :"7",
    "maj7" => :maj7,
    "min7" => :min7,
    "dim7" => :dim7,
    "m7b5" => :m7b5,
    "mMaj7" => :min_maj7,
    "augMaj7" => :aug_maj7,
    "aug7" => :aug7,
    "6" => :maj6,
    "m6" => :min6,
    "add9" => :add9,
    "madd9" => :m_add9,
    "6/9" => :maj6_9,
    "m6/9" => :min6_9,
    "9" => :"9",
    "maj9" => :maj9,
    "m9" => :min9,
    "7b9" => :"7b9",
    "7#9" => :"7#9",
    "9#5" => :"9#5",
    "9b5" => :"9b5",
    "7b5" => :"7b5",
    "7sus" => :"7sus4",
    "dimMaj7" => :dim_maj7,
    "maj7#11" => :"maj7#11",
    "7#11" => :"7#11",
    "7b13" => :"7b13",
    "7b9b13" => :"7b9b13",
    "11" => :"11",
    "maj11" => :maj11,
    "m11" => :min11,
    "m11b5" => :m11b5,
    "13" => :"13",
    "maj13" => :maj13,
    "m13" => :min13,
    "13b9" => :"13b9",
    "sus9" => :sus9,
    "susb9" => :susb9,
    "sus13" => :sus13,
    "m7b13" => :min7b13,
    "dim7b13" => :dim7b13
  }

  @valid_notes MapSet.new(Note.chromatic_scale())

  @instrument_to_string %{
    guitar: "guitar",
    bass_4: "bass_4",
    bass_5: "bass_5"
  }

  @string_to_instrument %{
    "guitar" => :guitar,
    "bass_4" => :bass_4,
    "bass_5" => :bass_5
  }

  @doc """
  Encodes a list of active chords into a comma-separated string.

  Returns `nil` if the list is empty.

  ## Examples

      iex> Fretboard.Music.URLCodec.encode_chords([%{root: "C", quality: :major}])
      "Cmaj"

      iex> Fretboard.Music.URLCodec.encode_chords([])
      nil
  """
  @spec encode_chords([map()]) :: String.t() | nil
  def encode_chords([]), do: nil

  def encode_chords(chords) do
    chords
    |> Enum.map_join(",", fn %{root: root, quality: quality} ->
      Chord.chord_label(root, quality)
    end)
  end

  @doc """
  Encodes a tuning into a comma-separated string.

  Returns `nil` if the tuning matches standard guitar tuning.

  ## Examples

      iex> Fretboard.Music.URLCodec.encode_tuning(["D", "A", "D", "G", "B", "E"])
      "D,A,D,G,B,E"

      iex> Fretboard.Music.URLCodec.encode_tuning(["E", "A", "D", "G", "B", "E"])
      nil
  """
  @spec encode_tuning([String.t()]) :: String.t() | nil
  def encode_tuning(tuning) do
    encode_tuning(:guitar, tuning)
  end

  @doc """
  Encodes a tuning for the given instrument into a comma-separated string.

  Returns `nil` if the tuning matches the instrument's standard tuning.
  """
  @spec encode_tuning(atom(), [String.t()]) :: String.t() | nil
  def encode_tuning(instrument, tuning) do
    standard = Instrument.instrument_standard_tuning(instrument)

    if tuning == standard, do: nil, else: Enum.join(tuning, ",")
  end

  @doc """
  Encodes tuning and chords into a query params map.

  Only includes keys with non-nil, non-default values.
  """
  @spec encode_params([String.t()], [map()]) :: map()
  def encode_params(tuning, chords) do
    encode_params(:guitar, tuning, chords)
  end

  @doc """
  Encodes tuning, chords, and an optional highlighted chord index into a query params map.

  When called with a list as the first argument, defaults the instrument to `:guitar`.
  When called with an instrument atom as the first argument, includes the "instrument"
  key in the params when the instrument is not `:guitar`.
  """
  @spec encode_params([String.t()], [map()], non_neg_integer() | nil) :: map()
  def encode_params(tuning, chords, highlighted_index) when is_list(tuning) do
    encode_params(:guitar, tuning, chords, highlighted_index)
  end

  @spec encode_params(atom(), [String.t()], [map()]) :: map()
  def encode_params(instrument, tuning, chords) when is_atom(instrument) do
    encode_params(instrument, tuning, chords, nil)
  end

  @doc """
  Encodes instrument, tuning, chords, and a highlighted chord index into a query params map.

  Includes the "instrument" key when the instrument is not `:guitar`.
  """
  @spec encode_params(atom(), [String.t()], [map()], non_neg_integer() | nil) :: map()
  def encode_params(instrument, tuning, chords, highlighted_index) do
    params =
      %{}
      |> maybe_put_instrument(instrument)
      |> maybe_put("chords", encode_chords(chords))
      |> maybe_put("tuning", encode_tuning(instrument, tuning))

    if highlighted_index != nil do
      chord = Enum.at(chords, highlighted_index)
      label = Chord.chord_label(chord.root, chord.quality)
      Map.put(params, "highlight", label)
    else
      params
    end
  end

  @doc """
  Decodes a comma-separated chords string into a list of chord maps.

  Invalid or unrecognizable chords are silently skipped.

  ## Examples

      iex> Fretboard.Music.URLCodec.decode_chords("Cmaj,Amin")
      [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]

      iex> Fretboard.Music.URLCodec.decode_chords(nil)
      []
  """
  @spec decode_chords(String.t() | nil) :: [map()]
  def decode_chords(nil), do: []
  def decode_chords(""), do: []

  def decode_chords(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.flat_map(&parse_chord/1)
  end

  @doc """
  Decodes a comma-separated tuning string into a list of notes.

  Returns standard guitar tuning if input is nil or invalid.
  """
  @spec decode_tuning(String.t() | nil) :: [String.t()]
  def decode_tuning(str) do
    decode_tuning(str, :guitar)
  end

  @doc """
  Decodes a comma-separated tuning string into a list of notes for the given instrument.

  Returns the instrument's standard tuning if input is nil or invalid.
  """
  @spec decode_tuning(String.t() | nil, atom()) :: [String.t()]
  def decode_tuning(nil, instrument) do
    Instrument.instrument_standard_tuning(instrument)
  end

  def decode_tuning(str, instrument) do
    notes = String.split(str, ",", trim: true)
    expected_count = Instrument.instrument_strings(instrument)

    if length(notes) == expected_count and Enum.all?(notes, &MapSet.member?(@valid_notes, &1)) do
      notes
    else
      Instrument.instrument_standard_tuning(instrument)
    end
  end

  @doc """
  Decodes a full params map into `{instrument, tuning, active_chords, highlighted_index}`.
  """
  @spec decode_params(map()) :: {atom(), [String.t()], [map()], non_neg_integer() | nil}
  def decode_params(params) do
    instrument = decode_instrument(params["instrument"])
    tuning = decode_tuning(params["tuning"], instrument)
    chords = decode_chords(params["chords"])
    highlighted_index = find_highlighted_index(params["highlight"], chords)
    {instrument, tuning, chords, highlighted_index}
  end

  @doc """
  Decodes the `tab` query param into an atom (`:visualizer` or `:analyzer`).

  Defaults to `:visualizer` when the param is missing or invalid.
  """
  @spec decode_tab(String.t() | nil) :: :visualizer | :analyzer
  def decode_tab(nil), do: :visualizer
  def decode_tab(""), do: :visualizer

  def decode_tab(str) when str in ~w(visualizer analyzer) do
    String.to_existing_atom(str)
  end

  def decode_tab(_), do: :visualizer

  @doc """
  Decodes the `marked` query param into a map of `string_index => fret`.

  Returns an empty map when the param is missing or invalid.
  """
  @spec decode_marked_map(String.t() | nil) :: %{non_neg_integer() => non_neg_integer()}
  def decode_marked_map(nil), do: %{}
  def decode_marked_map(""), do: %{}

  def decode_marked_map(str) do
    str
    |> decode_marked()
    |> Map.new(fn {string, fret} -> {string, fret} end)
  end

  @doc """
  Encodes a `marked` map (`string_index => fret`) into the comma-separated
  string format used in the URL. Returns `nil` for an empty map.
  """
  @spec encode_marked_map(%{non_neg_integer() => non_neg_integer()}) :: String.t() | nil
  def encode_marked_map(map) when map == %{}, do: nil

  def encode_marked_map(map) do
    map
    |> Enum.sort_by(fn {string, _fret} -> string end)
    |> Enum.map_join(",", fn {string, fret} -> "#{string}-#{fret}" end)
  end

  defp find_highlighted_index(nil, _chords), do: nil

  defp find_highlighted_index(label, chords) do
    Enum.find_index(chords, fn %{root: root, quality: quality} ->
      Chord.chord_label(root, quality) == label
    end)
  end

  defp decode_instrument(nil), do: :guitar

  defp decode_instrument(str) do
    Map.get(@string_to_instrument, str, :guitar)
  end

  defp maybe_put_instrument(map, :guitar), do: map

  defp maybe_put_instrument(map, instrument) do
    Map.put(map, "instrument", Map.fetch!(@instrument_to_string, instrument))
  end

  defp parse_chord(str) do
    case extract_root_and_label(str) do
      {root, quality} when not is_nil(quality) ->
        if MapSet.member?(@valid_notes, root), do: [%{root: root, quality: quality}], else: []

      _ ->
        []
    end
  end

  defp extract_root_and_label(str) do
    # Try root with sharp first (2 chars), then single char
    cond do
      String.length(str) > 1 and String.at(str, 1) == "#" ->
        root = String.slice(str, 0, 2)
        label = String.slice(str, 2, String.length(str))
        {root, @labels_to_quality[label]}

      String.length(str) >= 1 ->
        root = String.at(str, 0)
        label = String.slice(str, 1, String.length(str))
        {root, @labels_to_quality[label]}

      true ->
        {nil, nil}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @doc """
  Encodes a list of {string, fret} tuples into a comma-separated string.
  Returns nil for an empty list.
  """
  @spec encode_marked([{non_neg_integer(), non_neg_integer()}]) :: String.t() | nil
  def encode_marked([]), do: nil

  def encode_marked(positions) do
    positions
    |> Enum.map_join(",", fn {string, fret} -> "#{string}-#{fret}" end)
  end

  @doc """
  Decodes a comma-separated string of string-fret pairs into a list of {string, fret} tuples.
  Returns [] for nil or empty string. Silently skips invalid entries.
  """
  @spec decode_marked(String.t() | nil) :: [{non_neg_integer(), non_neg_integer()}]
  def decode_marked(nil), do: []
  def decode_marked(""), do: []

  def decode_marked(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.flat_map(&parse_marked_pair/1)
  end

  defp parse_marked_pair(pair) do
    case String.split(pair, "-", parts: 2) do
      [s, f] -> parse_marked_integers(s, f)
      _ -> []
    end
  end

  defp parse_marked_integers(s, f) do
    with {string, ""} <- Integer.parse(s),
         {fret, ""} <- Integer.parse(f) do
      [{string, fret}]
    else
      _ -> []
    end
  end
end
