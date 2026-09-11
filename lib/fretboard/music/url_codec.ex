defmodule Fretboard.Music.URLCodec do
  @moduledoc """
  Serializes and deserializes fretboard state to/from URL query parameters.

  Enables shareable URLs that restore instrument, tuning, and active chords.
  Query values are untrusted terms: non-string fields use their own defaults
  without discarding valid siblings. No input is converted into a new atom.
  """

  alias Fretboard.Music.{Chord, Instrument, Note, Pitch}

  @doc """
  Encodes exact MIDI pitches and the fixed editing reference. Defaults are
  omitted; legacy tuning names are retained for older clients. Non-standard
  references always include pitches, even when those pitches are Standard.
  """
  def encode_pitch_params(
        instrument,
        %{pitches: pitches, reference: reference},
        chords,
        highlight
      ) do
    params = encode_params(instrument, Enum.map(pitches, &Pitch.note_name/1), chords, highlight)

    if pitches == Instrument.instrument_standard_pitches(instrument) and reference == "Standard" do
      params
    else
      params
      |> Map.put("pitches", Enum.join(pitches, ","))
      |> maybe_put("reference", if(reference == "Standard", do: nil, else: reference))
    end
  end

  @doc """
  Decodes `{instrument, %{pitches: pitches, reference: name}, chords, highlight}`.

  A present `pitches` parameter is authoritative over `tuning`: it must be a
  comma-separated string of exactly the instrument's string count of MIDI
  integers (0..127). Invalid pitches reset both pitches and reference to
  Standard, never to conflicting legacy notes. Invalid references independently
  fall back to Standard and are checked against that instrument's catalog.
  With no `pitches`, legacy notes resolve nearest to Standard, ignoring reference
  and never inferring a preset from matching note names.
  """
  def decode_pitch_params(params) do
    instrument = decode_instrument(params["instrument"])
    {chords, highlight} = decode_chord_params(params)

    standard = %{
      pitches: Instrument.instrument_standard_pitches(instrument),
      reference: "Standard"
    }

    state = decode_pitch_state(params, instrument, standard)
    {instrument, state, chords, highlight}
  end

  defp decode_pitch_state(%{"pitches" => value} = params, instrument, standard) do
    case parse_pitches(value, Instrument.instrument_strings(instrument)) do
      {:ok, pitches} ->
        reference = params["reference"]

        reference =
          if reference in Instrument.instrument_preset_names(instrument),
            do: reference,
            else: "Standard"

        %{pitches: pitches, reference: reference}

      :error ->
        standard
    end
  end

  defp decode_pitch_state(params, instrument, standard) do
    tuning = decode_tuning(params["tuning"], instrument)
    %{standard | pitches: Pitch.string_pitches(standard.pitches, tuning)}
  end

  defp parse_pitches(value, count) when is_binary(value) do
    parsed = value |> String.split(",") |> Enum.map(&Integer.parse/1)

    if length(parsed) == count and Enum.all?(parsed, &valid_pitch?/1) do
      {:ok, Enum.map(parsed, &elem(&1, 0))}
    else
      :error
    end
  end

  defp parse_pitches(_, _), do: :error
  defp valid_pitch?({pitch, ""}) when pitch in 0..127, do: true
  defp valid_pitch?(_), do: false

  @labels_to_quality Map.new(Chord.available_qualities(), &{Chord.label(&1), &1})
  @valid_notes MapSet.new(Note.chromatic_scale())
  @instrument_to_string Map.new(Instrument.fretted_instruments(), fn {key, _label} ->
                          {key, Atom.to_string(key)}
                        end)
  @string_to_instrument Map.new(@instrument_to_string, fn {key, value} -> {value, key} end)

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
    chords
    |> encode_chord_params(highlighted_index)
    |> maybe_put_instrument(instrument)
    |> maybe_put("tuning", encode_tuning(instrument, tuning))
  end

  @doc "Encodes shared chord and highlight parameters, omitting empty defaults."
  @spec encode_chord_params([map()], non_neg_integer() | nil) :: map()
  def encode_chord_params(chords, highlighted_index) do
    %{}
    |> maybe_put("chords", encode_chords(chords))
    |> add_highlight_param(chords, highlighted_index)
  end

  @doc "Decodes shared chords and the index of a valid highlighted chord."
  @spec decode_chord_params(map()) :: {[map()], non_neg_integer() | nil}
  def decode_chord_params(params) do
    chords = decode_chords(params["chords"])
    {chords, find_highlighted_index(params["highlight"], chords)}
  end

  defp add_highlight_param(params, _chords, nil), do: params

  defp add_highlight_param(params, chords, highlighted_index) do
    chord = Enum.at(chords, highlighted_index)
    label = Chord.chord_label(chord.root, chord.quality)
    Map.put(params, "highlight", label)
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
  @spec decode_chords(term()) :: [map()]
  def decode_chords(value) when not is_binary(value), do: []
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
  @spec decode_tuning(term()) :: [String.t()]
  def decode_tuning(str) do
    decode_tuning(str, :guitar)
  end

  @doc """
  Decodes a comma-separated tuning string into a list of notes for the given instrument.

  Returns the instrument's standard tuning if input is nil or invalid.
  """
  @spec decode_tuning(term(), atom()) :: [String.t()]
  def decode_tuning(value, instrument) when not is_binary(value) do
    Instrument.instrument_standard_tuning(instrument)
  end

  def decode_tuning(str, instrument) do
    notes = String.split(str, ",", trim: true)

    if valid_tuning?(notes, Instrument.instrument_strings(instrument)) do
      notes
    else
      Instrument.instrument_standard_tuning(instrument)
    end
  end

  defp valid_tuning?(notes, expected_count) do
    length(notes) == expected_count and Enum.all?(notes, &MapSet.member?(@valid_notes, &1))
  end

  @doc """
  Decodes a full params map into `{instrument, tuning, active_chords, highlighted_index}`.
  """
  @spec decode_params(map()) :: {atom(), [String.t()], [map()], non_neg_integer() | nil}
  def decode_params(params) do
    instrument = decode_instrument(params["instrument"])
    tuning = decode_tuning(params["tuning"], instrument)
    {chords, highlighted_index} = decode_chord_params(params)
    {instrument, tuning, chords, highlighted_index}
  end

  @doc """
  Decodes the `tab` query param into an atom (`:visualizer` or `:analyzer`).

  Defaults to `:visualizer` when the param is missing or invalid.
  """
  @spec decode_tab(term()) :: :visualizer | :analyzer
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
  @spec decode_marked_map(term()) :: %{non_neg_integer() => non_neg_integer()}
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
    case parse_root_and_quality(str) do
      {root, quality} when not is_nil(quality) -> to_chord_if_valid(root, quality)
      _ -> []
    end
  end

  defp to_chord_if_valid(root, quality) do
    if MapSet.member?(@valid_notes, root) do
      [%{root: root, quality: quality}]
    else
      []
    end
  end

  defp parse_root_and_quality(<<root::binary-size(1), "#", rest::binary>>) do
    {root <> "#", quality_from_label(rest)}
  end

  defp parse_root_and_quality(<<root::binary-size(1), rest::binary>>) do
    {root, quality_from_label(rest)}
  end

  defp parse_root_and_quality(_), do: {nil, nil}

  defp quality_from_label(label), do: Map.get(@labels_to_quality, label)

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
  @spec decode_marked(term()) :: [{non_neg_integer(), non_neg_integer()}]
  def decode_marked(value) when not is_binary(value), do: []
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
