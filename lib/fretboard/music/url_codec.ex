defmodule Fretboard.Music.URLCodec do
  @moduledoc """
  Serializes and deserializes fretboard state to/from URL query parameters.

  Enables shareable URLs that restore tuning and active chords.
  """

  alias Fretboard.Music.{Chord, Note, Tuning}

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
    "m7b5" => :m7b5
  }

  @valid_notes MapSet.new(Note.chromatic_scale())

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

  Returns `nil` if the tuning matches standard tuning.

  ## Examples

      iex> Fretboard.Music.URLCodec.encode_tuning(["D", "A", "D", "G", "B", "E"])
      "D,A,D,G,B,E"

      iex> Fretboard.Music.URLCodec.encode_tuning(["E", "A", "D", "G", "B", "E"])
      nil
  """
  @spec encode_tuning([String.t()]) :: String.t() | nil
  def encode_tuning(tuning) do
    if tuning == Tuning.standard(), do: nil, else: Enum.join(tuning, ",")
  end

  @doc """
  Encodes tuning and chords into a query params map.

  Only includes keys with non-nil, non-default values.
  """
  @spec encode_params([String.t()], [map()]) :: map()
  def encode_params(tuning, chords) do
    %{}
    |> maybe_put("chords", encode_chords(chords))
    |> maybe_put("tuning", encode_tuning(tuning))
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

  Returns standard tuning if input is nil or invalid.
  """
  @spec decode_tuning(String.t() | nil) :: [String.t()]
  def decode_tuning(nil), do: Tuning.standard()

  def decode_tuning(str) do
    notes = String.split(str, ",", trim: true)

    if length(notes) == 6 and Enum.all?(notes, &MapSet.member?(@valid_notes, &1)) do
      notes
    else
      Tuning.standard()
    end
  end

  @doc """
  Decodes a full params map into `{tuning, active_chords}`.
  """
  @spec decode_params(map()) :: {[String.t()], [map()]}
  def decode_params(params) do
    tuning = decode_tuning(params["tuning"])
    chords = decode_chords(params["chords"])
    {tuning, chords}
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
end
