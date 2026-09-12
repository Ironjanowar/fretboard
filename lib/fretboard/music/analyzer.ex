defmodule Fretboard.Music.Analyzer do
  @moduledoc """
  Interval and chord analysis of absolute sounding pitches.

  `analyze_pitches/1` is instrument-independent: any selection that can
  be expressed as absolute pitches (piano keys, synthesizer notes)
  analyzes the same way. `analyzer_state/2` adapts marked fretboard
  positions — each marked note is its string's open pitch plus the
  fret — instead of trusting string order. Two consequences:

    * the bass of a shape is its lowest sounding pitch, so reentrant
      tunings (standard high-G ukulele) and real pitch crossings work;
    * two notes sharing a pitch class an octave apart are reported as
      an Octave instead of collapsing into a single note.
  """

  alias Fretboard.Music.{Chord, Pitch}

  @doc """
  Computes the analysis state for the marked positions.

  `marked_notes` maps string index to fret; `string_pitches` lists
  each string's open absolute pitch, ordered like the tuning list.
  Sounding pitches are sorted low to high, so:

    * `{:empty}` — nothing marked
    * `{:single, note}` — one unique sounding pitch
    * `{:interval, note_low, note_high, label}` — two pitch classes, ordered
      by the lowest height of each class; or one class at distinct heights
      (Octave)
    * `{:chords, notes, bass, interpretations}` — three or more pitch classes,
      with `bass` being the note name of the lowest sounding pitch
  """
  @spec analyzer_state(%{non_neg_integer() => non_neg_integer()}, [integer()]) ::
          {:empty}
          | {:single, String.t()}
          | {:interval, String.t(), String.t(), String.t()}
          | {:chords, [String.t()], String.t(), [map()]}
  def analyzer_state(marked_notes, string_pitches) do
    marked_notes
    |> Enum.map(fn {string, fret} -> Enum.at(string_pitches, string) + fret end)
    |> analyze_pitches()
  end

  @doc """
  Computes the analysis state from absolute sounding pitches.

  Input order and repeated pitches do not affect the result. Returns the
  same analysis tuples as `analyzer_state/2`, with the lowest pitch as bass.
  """
  @spec analyze_pitches([integer()]) ::
          {:empty}
          | {:single, String.t()}
          | {:interval, String.t(), String.t(), String.t()}
          | {:chords, [String.t()], String.t(), [map()]}
  def analyze_pitches(pitches) do
    pitches = Enum.sort(pitches)

    # Sorting before deduplication retains the lowest height of each class.
    classes = Enum.uniq_by(pitches, &Pitch.note_name/1)

    case classes do
      [] ->
        {:empty}

      [pitch] ->
        if Enum.uniq(pitches) == [pitch] do
          {:single, Pitch.note_name(pitch)}
        else
          {:interval, Pitch.note_name(pitch), Pitch.note_name(pitch),
           Pitch.interval_label(pitch, List.last(pitches))}
        end

      [low, high] ->
        {:interval, Pitch.note_name(low), Pitch.note_name(high), Pitch.interval_label(low, high)}

      _ ->
        bass = Pitch.note_name(hd(classes))
        notes = Enum.map(classes, &Pitch.note_name/1)
        {:chords, notes, bass, Chord.identify(notes, bass)}
    end
  end
end
