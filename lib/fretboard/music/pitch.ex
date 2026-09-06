defmodule Fretboard.Music.Pitch do
  @moduledoc """
  Absolute-pitch helpers for the fretboard.

  Pitches are MIDI note numbers (middle C = C4 = 60), so every fretted
  note sounds at its string's open pitch plus the fret. Displayed note
  names are always derived from pitches, never kept as an independent
  state.
  """

  alias Fretboard.Music.{Intervals, Note}

  @doc """
  Returns the displayed note name of an absolute pitch.

  ## Examples

      iex> Fretboard.Music.Pitch.note_name(60)
      "C"

      iex> Fretboard.Music.Pitch.note_name(40)
      "E"
  """
  @spec note_name(integer()) :: String.t()
  def note_name(pitch), do: Enum.at(Note.chromatic_scale(), rem(pitch, 12))

  @doc """
  Returns the simple interval name between two pitches.

  The name is the simple interval between them regardless of the
  octaves spanned, so C3 to E4 (16 semitones) is still a Major 3rd.
  Two different pitches sharing a pitch class (one or more octaves
  apart) are reported as an Octave instead of collapsing into a
  single note.
  """
  @spec interval_label(integer(), integer()) :: String.t()
  def interval_label(pitch_a, pitch_b) do
    semitones = abs(pitch_b - pitch_a)

    cond do
      semitones == 0 -> "Perfect Unison"
      rem(semitones, 12) == 0 -> "Octave"
      true -> Intervals.name(rem(semitones, 12))
    end
  end

  @doc """
  Resolves note names nearest to an explicit list of fixed reference pitches.

  References and notes have matching string order and length. This pure
  calculation does not look up instruments or infer presets. A ±6 semitone
  tie resolves downward.
  """
  @spec string_pitches([integer()], [String.t()]) :: [integer()]
  def string_pitches(references, tuning) when is_list(references) do
    Enum.zip_with(references, tuning, fn reference, note ->
      closest_pitch(Note.note_index(note), reference)
    end)
  end

  # The pitch with the given pitch class closest to the reference
  # pitch. Candidates are listed in ascending order, so a ±6 semitone
  # tie deterministically resolves to the lower pitch.
  defp closest_pitch(pitch_class, reference) do
    base = reference - rem(reference, 12) + pitch_class

    Enum.min_by([base - 12, base, base + 12], &abs(&1 - reference))
  end
end
