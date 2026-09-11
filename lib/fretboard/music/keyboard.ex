defmodule Fretboard.Music.Keyboard do
  @moduledoc """
  Musical keyboard data derived from absolute pitches and chord memberships.
  Layout geometry and presentation belong to the web layer.
  """

  alias Fretboard.Music.Pitch

  @doc """
  Builds one key per pitch in input order using a note-name membership lookup.
  Chord labels retain their active order, including on repeated octaves.
  """
  @spec data(Enumerable.t(), %{String.t() => [String.t()]}) :: [map()]
  def data(pitches, chord_lookup) do
    Enum.map(pitches, fn pitch ->
      note = Pitch.note_name(pitch)
      %{pitch: pitch, note: note, chords: Map.get(chord_lookup, note, [])}
    end)
  end
end
