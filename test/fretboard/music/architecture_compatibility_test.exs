defmodule Fretboard.Music.ArchitectureCompatibilityTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music
  alias Fretboard.Music.{Pitch, URLCodec}

  test "every catalog quality roundtrips with natural and sharp roots and highlight" do
    for quality <- Music.available_qualities(), root <- ["C", "F#"] do
      chords = [%{root: root, quality: quality}]
      state = Music.preset_tuning(:guitar, "Standard")
      params = Music.encode_pitch_params(:guitar, state, chords, 0)
      assert params["chords"] == Music.chord_label(root, quality)
      assert {:guitar, ^state, ^chords, 0} = Music.decode_pitch_params(params)
      assert URLCodec.decode_chords(params["chords"]) == chords
    end
  end

  test "every catalog instrument and preset survives the pitch URL wire format" do
    for {instrument, _label} <- Music.instruments(),
        name <- Music.instrument_preset_names(instrument) do
      state = Music.preset_tuning(instrument, name)
      params = Music.encode_pitch_params(instrument, state, [], nil)

      assert params["instrument"] ==
               if(instrument == :guitar, do: nil, else: Atom.to_string(instrument))

      assert {^instrument, ^state, [], nil} = Music.decode_pitch_params(params)
    end
  end

  test "empty and true unison retain their analyzer tuple contracts" do
    assert Music.analyzer_state(%{}, [40, 45]) == {:empty}
    assert Music.analyzer_state(%{0 => 5, 1 => 0}, [40, 45]) == {:single, "A"}
    assert Pitch.interval_label(45, 45) == "Perfect Unison"
  end

  test "octave doubling retains the Octave label without becoming a unison" do
    assert Pitch.interval_label(48, 60) == "Octave"

    assert Music.analyzer_state(%{0 => 0, 1 => 0, 2 => 0}, [48, 60, 72]) ==
             {:interval, "C", "C", "Octave"}
  end

  test "octave doubling of two pitch classes retains the simple interval" do
    assert Music.analyzer_state(%{0 => 0, 1 => 0, 2 => 0}, [60, 48, 55]) ==
             {:interval, "C", "G", "Perfect 5th"}
  end
end
