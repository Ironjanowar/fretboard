defmodule Fretboard.Music.PitchStateTest do
  use ExUnit.Case, async: true
  alias Fretboard.Music.{Instrument, Pitch, URLCodec}

  test "nearest pitches use explicit fixed references and resolve tritone ties downward" do
    assert Pitch.string_pitches([38, 45], ["G#", "D#"]) == [32, 39]
    assert Pitch.string_pitches([67, 60], ["G", "B"]) == [67, 59]
    assert Pitch.string_pitches([38], ["C"]) == [36]
  end

  test "catalog stores actual preset heights, deriving legacy note names" do
    assert Instrument.instrument_pitch_presets(:ukelele) == [
             {"Standard", [67, 60, 64, 69]},
             {"Low G", [55, 60, 64, 69]},
             {"D tuning", [69, 62, 66, 71]},
             {"Baritone", [50, 55, 59, 64]},
             {"Half Step Down", [66, 59, 63, 68]}
           ]

    for {instrument, _} <- Instrument.instruments(),
        {name, pitches} <- Instrument.instrument_pitch_presets(instrument) do
      assert length(pitches) == Instrument.instrument_strings(instrument)

      assert {name, Enum.map(pitches, &Pitch.note_name/1)} in Instrument.instrument_tuning_presets(
               instrument
             )
    end
  end

  test "pitch state codec preserves exact pitches and a custom fixed reference" do
    state = %{pitches: [44, 45, 50, 55, 59, 64], reference: "Drop D"}
    params = URLCodec.encode_pitch_params(:guitar, state, [], nil)
    assert params["pitches"] == "44,45,50,55,59,64"
    assert params["reference"] == "Drop D"
    assert {:guitar, ^state, [], nil} = URLCodec.decode_pitch_params(params)

    assert URLCodec.encode_pitch_params(
             :guitar,
             %{pitches: [40, 45, 50, 55, 59, 64], reference: "Standard"},
             [],
             nil
           ) == %{}
  end

  test "numeric pitches override legacy note names and default reference is Standard" do
    params = %{"instrument" => "ukelele", "pitches" => "55,60,64,69", "tuning" => "D,G,B,E"}

    assert {:ukelele, %{pitches: [55, 60, 64, 69], reference: "Standard"}, [], nil} =
             URLCodec.decode_pitch_params(params)

    assert {:ukelele, %{pitches: [62, 55, 59, 64], reference: "Standard"}, [], nil} =
             URLCodec.decode_pitch_params(%{
               "instrument" => "ukelele",
               "tuning" => "D,G,B,E",
               "reference" => "Baritone"
             })
  end

  test "invalid numeric parameters fall back safely to Standard, not conflicting legacy notes" do
    for value <- [
          nil,
          [],
          ["55", "60", "64", "69"],
          %{},
          55,
          "",
          "55,60,64",
          "55,60,64,69,72",
          "-1,60,64,69",
          "128,60,64,69",
          "55.0,60,64,69",
          "55,60,no,69",
          "55,,64,69"
        ] do
      params = %{
        "instrument" => "ukelele",
        "pitches" => value,
        "tuning" => "D,G,B,E",
        "reference" => "Low G"
      }

      assert {:ukelele, %{pitches: [67, 60, 64, 69], reference: "Standard"}, [], nil} =
               URLCodec.decode_pitch_params(params)
    end
  end

  test "reference is allowlisted per instrument without converting input to atoms" do
    for value <- [nil, "invalid preset", "Drop D", [], %{}, 12] do
      assert {:ukelele, %{pitches: [55, 60, 64, 69], reference: "Standard"}, [], nil} =
               URLCodec.decode_pitch_params(%{
                 "instrument" => "ukelele",
                 "pitches" => "55,60,64,69",
                 "reference" => value
               })
    end

    assert {:ukelele, %{pitches: [0, 127, 64, 69], reference: "Low G"}, [], nil} =
             URLCodec.decode_pitch_params(%{
               "instrument" => "ukelele",
               "pitches" => "0,127,64,69",
               "reference" => "Low G"
             })
  end
end
