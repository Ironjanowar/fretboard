defmodule Fretboard.Music.URLCodecTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.URLCodec

  describe "encode_chords/1" do
    test "returns nil for empty list" do
      assert URLCodec.encode_chords([]) == nil
    end

    test "encodes single chord" do
      assert URLCodec.encode_chords([%{root: "C", quality: :major}]) == "Cmaj"
    end

    test "encodes multiple chords" do
      chords = [
        %{root: "C", quality: :major},
        %{root: "A", quality: :minor},
        %{root: "G", quality: :"7"}
      ]

      assert URLCodec.encode_chords(chords) == "Cmaj,Amin,G7"
    end

    test "encodes chords with sharps" do
      chords = [
        %{root: "C#", quality: :minor},
        %{root: "F#", quality: :maj7}
      ]

      assert URLCodec.encode_chords(chords) == "C#min,F#maj7"
    end

    test "encodes all quality types" do
      qualities = [:major, :minor, :dim, :aug, :sus2, :sus4, :"7", :maj7, :min7, :dim7, :m7b5]
      expected = "Cmaj,Cmin,Cdim,Caug,Csus2,Csus4,C7,Cmaj7,Cmin7,Cdim7,Cm7b5"

      chords = Enum.map(qualities, &%{root: "C", quality: &1})
      assert URLCodec.encode_chords(chords) == expected
    end
  end

  describe "encode_tuning/1" do
    test "returns nil for standard tuning" do
      assert URLCodec.encode_tuning(["E", "A", "D", "G", "B", "E"]) == nil
    end

    test "encodes custom tuning" do
      assert URLCodec.encode_tuning(["D", "A", "D", "G", "B", "E"]) == "D,A,D,G,B,E"
    end
  end

  describe "encode_params/2" do
    test "returns empty map when standard tuning and no chords" do
      assert URLCodec.encode_params(["E", "A", "D", "G", "B", "E"], []) == %{}
    end

    test "includes only chords when standard tuning" do
      chords = [%{root: "C", quality: :major}]

      assert URLCodec.encode_params(["E", "A", "D", "G", "B", "E"], chords) == %{
               "chords" => "Cmaj"
             }
    end

    test "includes both when custom tuning and chords" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["D", "A", "D", "G", "B", "E"]

      assert URLCodec.encode_params(tuning, chords) == %{
               "chords" => "Cmaj",
               "tuning" => "D,A,D,G,B,E"
             }
    end
  end

  describe "decode_chords/1" do
    test "returns empty list for nil" do
      assert URLCodec.decode_chords(nil) == []
    end

    test "returns empty list for empty string" do
      assert URLCodec.decode_chords("") == []
    end

    test "decodes valid chords string" do
      assert URLCodec.decode_chords("Cmaj,Amin,G7") == [
               %{root: "C", quality: :major},
               %{root: "A", quality: :minor},
               %{root: "G", quality: :"7"}
             ]
    end

    test "decodes chords with sharps" do
      assert URLCodec.decode_chords("C#min,F#maj7") == [
               %{root: "C#", quality: :minor},
               %{root: "F#", quality: :maj7}
             ]
    end

    test "silently skips invalid chords" do
      assert URLCodec.decode_chords("Cmaj,GARBAGE,Amin") == [
               %{root: "C", quality: :major},
               %{root: "A", quality: :minor}
             ]
    end

    test "silently skips chords with invalid root" do
      assert URLCodec.decode_chords("Xmaj,Cmaj") == [
               %{root: "C", quality: :major}
             ]
    end
  end

  describe "decode_tuning/1" do
    test "returns standard tuning for nil" do
      assert URLCodec.decode_tuning(nil) == ["E", "A", "D", "G", "B", "E"]
    end

    test "decodes custom tuning" do
      assert URLCodec.decode_tuning("D,A,D,G,B,E") == ["D", "A", "D", "G", "B", "E"]
    end

    test "returns standard tuning for invalid input (wrong count)" do
      assert URLCodec.decode_tuning("D,A,D") == ["E", "A", "D", "G", "B", "E"]
    end
  end

  describe "decode_params/1" do
    test "returns defaults for empty params" do
      assert URLCodec.decode_params(%{}) == {:guitar, ["E", "A", "D", "G", "B", "E"], [], nil}
    end

    test "decodes chords and tuning from params" do
      params = %{"chords" => "Cmaj,Amin", "tuning" => "D,A,D,G,B,E"}

      assert URLCodec.decode_params(params) == {
               :guitar,
               ["D", "A", "D", "G", "B", "E"],
               [%{root: "C", quality: :major}, %{root: "A", quality: :minor}],
               nil
             }
    end
  end

  describe "encode_params/3 with highlighted_index" do
    test "returns same result as encode_params/2 when highlighted_index is nil" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      result_two = URLCodec.encode_params(tuning, chords)
      result_three = URLCodec.encode_params(tuning, chords, nil)

      assert result_three == result_two
    end

    test "includes highlight key when highlighted_index is provided" do
      chords = [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      result = URLCodec.encode_params(tuning, chords, 0)

      assert result["highlight"] == "Cmaj"
    end

    test "highlight encodes the label of the chord at the given index" do
      chords = [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      result = URLCodec.encode_params(tuning, chords, 1)

      assert result["highlight"] == "Amin"
    end

    test "encode_params/3 includes highlight alongside chords and tuning" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["D", "A", "D", "G", "B", "E"]

      result = URLCodec.encode_params(tuning, chords, 0)

      assert result["chords"] == "Cmaj"
      assert result["tuning"] == "D,A,D,G,B,E"
      assert result["highlight"] == "Cmaj"
    end

    test "encode_params/2 backward compatibility still works" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      result = URLCodec.encode_params(tuning, chords)

      assert result == %{"chords" => "Cmaj"}
      refute Map.has_key?(result, "highlight")
    end
  end

  describe "decode_params/1 with highlight" do
    test "returns four-element tuple with highlighted_index when highlight param present" do
      params = %{"chords" => "Cmaj,Amin", "highlight" => "Cmaj"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["E", "A", "D", "G", "B", "E"],
                [%{root: "C", quality: :major}, %{root: "A", quality: :minor}], 0}
    end

    test "returns highlighted_index matching second chord" do
      params = %{"chords" => "Cmaj,Amin", "highlight" => "Amin"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["E", "A", "D", "G", "B", "E"],
                [%{root: "C", quality: :major}, %{root: "A", quality: :minor}], 1}
    end

    test "returns nil for highlighted_index when no highlight param" do
      params = %{"chords" => "Cmaj"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["E", "A", "D", "G", "B", "E"], [%{root: "C", quality: :major}], nil}
    end

    test "returns nil for highlighted_index with empty params" do
      assert URLCodec.decode_params(%{}) == {:guitar, ["E", "A", "D", "G", "B", "E"], [], nil}
    end

    test "returns nil for highlighted_index when highlight label does not match any chord" do
      params = %{"chords" => "Cmaj,Amin", "highlight" => "G7"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["E", "A", "D", "G", "B", "E"],
                [%{root: "C", quality: :major}, %{root: "A", quality: :minor}], nil}
    end

    test "backward compat: existing usage still compiles" do
      # Existing callers that pattern match on {tuning, chords, highlight} should still
      # be supported if they don't care about instrument. This test just
      # verifies decode_params runs; callers will need to update their
      # pattern matches when the feature is implemented.
      params = %{"chords" => "Cmaj"}

      result = URLCodec.decode_params(params)

      # The result is now a 4-tuple
      assert tuple_size(result) == 4
    end

    test "decodes highlight with tuning param present" do
      params = %{"chords" => "Cmaj", "tuning" => "D,A,D,G,B,E", "highlight" => "Cmaj"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["D", "A", "D", "G", "B", "E"], [%{root: "C", quality: :major}], 0}
    end
  end

  describe "round-trip with highlight" do
    test "encode then decode produces same data without highlight" do
      chords = [
        %{root: "C", quality: :major},
        %{root: "A", quality: :minor},
        %{root: "F#", quality: :maj7}
      ]

      tuning = ["D", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords)
      {_, decoded_tuning, decoded_chords, highlighted_index} = URLCodec.decode_params(params)

      assert decoded_tuning == tuning
      assert decoded_chords == chords
      assert highlighted_index == nil
    end

    test "round-trip with standard tuning and no highlight" do
      chords = [%{root: "G", quality: :"7"}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords)
      {_, decoded_tuning, decoded_chords, highlighted_index} = URLCodec.decode_params(params)

      assert decoded_tuning == tuning
      assert decoded_chords == chords
      assert highlighted_index == nil
    end

    test "round-trip preserves highlighted_index" do
      chords = [
        %{root: "C", quality: :major},
        %{root: "A", quality: :minor}
      ]

      tuning = ["E", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords, 1)
      {_, decoded_tuning, decoded_chords, highlighted_index} = URLCodec.decode_params(params)

      assert decoded_tuning == tuning
      assert decoded_chords == chords
      assert highlighted_index == 1
    end

    test "round-trip with highlight and custom tuning" do
      chords = [%{root: "D", quality: :minor}]
      tuning = ["D", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords, 0)
      {_, decoded_tuning, decoded_chords, highlighted_index} = URLCodec.decode_params(params)

      assert decoded_tuning == tuning
      assert decoded_chords == chords
      assert highlighted_index == 0
    end

    test "round-trip with nil highlighted_index produces no highlight param" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords, nil)

      refute Map.has_key?(params, "highlight")

      {_, _, _, highlighted_index} = URLCodec.decode_params(params)
      assert highlighted_index == nil
    end
  end

  describe "encode_tuning/2" do
    test "returns nil for guitar standard tuning" do
      assert URLCodec.encode_tuning(:guitar, ["E", "A", "D", "G", "B", "E"]) == nil
    end

    test "returns nil for bass_4 standard tuning" do
      assert URLCodec.encode_tuning(:bass_4, ["E", "A", "D", "G"]) == nil
    end

    test "returns nil for bass_5 standard tuning" do
      assert URLCodec.encode_tuning(:bass_5, ["B", "E", "A", "D", "G"]) == nil
    end

    test "encodes custom bass_4 tuning" do
      assert URLCodec.encode_tuning(:bass_4, ["D", "A", "D", "G"]) == "D,A,D,G"
    end

    test "encodes custom bass_5 tuning" do
      assert URLCodec.encode_tuning(:bass_5, ["A", "E", "A", "D", "G"]) == "A,E,A,D,G"
    end
  end

  describe "decode_tuning/2" do
    test "returns guitar standard tuning for nil" do
      assert URLCodec.decode_tuning(nil, :guitar) == ["E", "A", "D", "G", "B", "E"]
    end

    test "returns bass_4 standard tuning for nil" do
      assert URLCodec.decode_tuning(nil, :bass_4) == ["E", "A", "D", "G"]
    end

    test "returns bass_5 standard tuning for nil" do
      assert URLCodec.decode_tuning(nil, :bass_5) == ["B", "E", "A", "D", "G"]
    end

    test "decodes valid 4-note tuning for bass_4" do
      assert URLCodec.decode_tuning("E,A,D,G", :bass_4) == ["E", "A", "D", "G"]
    end

    test "decodes valid 5-note tuning for bass_5" do
      assert URLCodec.decode_tuning("B,E,A,D,G", :bass_5) == ["B", "E", "A", "D", "G"]
    end

    test "falls back to bass_4 standard when tuning has wrong note count (6 notes)" do
      assert URLCodec.decode_tuning("E,A,D,G,B,E", :bass_4) == ["E", "A", "D", "G"]
    end

    test "falls back to bass_4 standard when tuning has wrong note count (3 notes)" do
      assert URLCodec.decode_tuning("D,A,D", :bass_4) == ["E", "A", "D", "G"]
    end
  end

  describe "encode_params/3 with instrument" do
    test "returns empty map for guitar with standard tuning and no chords" do
      assert URLCodec.encode_params(:guitar, ["E", "A", "D", "G", "B", "E"], []) == %{}
    end

    test "includes instrument key for bass_4 even with standard tuning" do
      assert URLCodec.encode_params(:bass_4, ["E", "A", "D", "G"], []) == %{
               "instrument" => "bass_4"
             }
    end

    test "includes instrument, tuning, and chords for bass_4 with custom tuning" do
      chords = [%{root: "C", quality: :major}]

      assert URLCodec.encode_params(:bass_4, ["D", "A", "D", "G"], chords) == %{
               "instrument" => "bass_4",
               "tuning" => "D,A,D,G",
               "chords" => "Cmaj"
             }
    end

    test "includes instrument key for bass_5 with standard tuning" do
      assert URLCodec.encode_params(:bass_5, ["B", "E", "A", "D", "G"], []) == %{
               "instrument" => "bass_5"
             }
    end
  end

  describe "encode_params/4 with instrument and highlight" do
    test "does not include instrument key for guitar (backward compat)" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      result = URLCodec.encode_params(:guitar, tuning, chords, 0)

      refute Map.has_key?(result, "instrument")
      assert result["highlight"] == "Cmaj"
    end

    test "includes instrument key for bass_4" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["E", "A", "D", "G"]

      result = URLCodec.encode_params(:bass_4, tuning, chords, 0)

      assert result["instrument"] == "bass_4"
      assert result["highlight"] == "Cmaj"
    end
  end

  describe "decode_params/1 with instrument" do
    test "returns guitar defaults for empty params" do
      assert URLCodec.decode_params(%{}) == {:guitar, ["E", "A", "D", "G", "B", "E"], [], nil}
    end

    test "decodes bass_4 with standard tuning when instrument present" do
      assert URLCodec.decode_params(%{"instrument" => "bass_4"}) ==
               {:bass_4, ["E", "A", "D", "G"], [], nil}
    end

    test "decodes bass_5 with standard tuning when instrument present" do
      assert URLCodec.decode_params(%{"instrument" => "bass_5"}) ==
               {:bass_5, ["B", "E", "A", "D", "G"], [], nil}
    end

    test "invalid instrument defaults to guitar with guitar standard" do
      assert URLCodec.decode_params(%{"instrument" => "ukulele"}) ==
               {:guitar, ["E", "A", "D", "G", "B", "E"], [], nil}
    end

    test "bass_4 without tuning uses bass_4 standard" do
      assert URLCodec.decode_params(%{"instrument" => "bass_4"}) ==
               {:bass_4, ["E", "A", "D", "G"], [], nil}
    end

    test "bass_5 with correct tuning preserves tuning" do
      assert URLCodec.decode_params(%{"instrument" => "bass_5", "tuning" => "B,E,A,D,G"}) ==
               {:bass_5, ["B", "E", "A", "D", "G"], [], nil}
    end

    test "bass_4 with wrong note count falls back to bass_4 standard" do
      assert URLCodec.decode_params(%{"instrument" => "bass_4", "tuning" => "E,A,D,G,B,E"}) ==
               {:bass_4, ["E", "A", "D", "G"], [], nil}
    end

    test "backward compat: URL without instrument with 6-note tuning works as before" do
      params = %{"tuning" => "D,A,D,G,B,E"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["D", "A", "D", "G", "B", "E"], [], nil}
    end

    test "decodes bass_4 with chords" do
      params = %{"instrument" => "bass_4", "chords" => "Cmaj"}

      assert URLCodec.decode_params(params) ==
               {:bass_4, ["E", "A", "D", "G"], [%{root: "C", quality: :major}], nil}
    end

    test "highlight still works with instrument" do
      params = %{"instrument" => "bass_4", "chords" => "Cmaj,Amin", "highlight" => "Cmaj"}

      assert URLCodec.decode_params(params) ==
               {:bass_4, ["E", "A", "D", "G"],
                [%{root: "C", quality: :major}, %{root: "A", quality: :minor}], 0}
    end

    test "invalid instrument with valid 6-note tuning uses guitar" do
      params = %{"instrument" => "ukulele", "tuning" => "D,A,D,G,B,E"}

      assert URLCodec.decode_params(params) ==
               {:guitar, ["D", "A", "D", "G", "B", "E"], [], nil}
    end
  end

  describe "round-trip with instrument" do
    test "encode bass_4 with custom tuning, decode back to same instrument, tuning, chords" do
      chords = [%{root: "C", quality: :major}]
      tuning = ["D", "A", "D", "G"]

      params = URLCodec.encode_params(:bass_4, tuning, chords)

      {instrument, decoded_tuning, decoded_chords, _highlighted_index} =
        URLCodec.decode_params(params)

      assert instrument == :bass_4
      assert decoded_tuning == tuning
      assert decoded_chords == chords
    end

    test "encode bass_5 with standard tuning, decode back with instrument key present" do
      chords = []
      tuning = ["B", "E", "A", "D", "G"]

      params = URLCodec.encode_params(:bass_5, tuning, chords)
      assert Map.has_key?(params, "instrument")

      {instrument, decoded_tuning, decoded_chords, _highlighted_index} =
        URLCodec.decode_params(params)

      assert instrument == :bass_5
      assert decoded_tuning == tuning
      assert decoded_chords == chords
    end

    test "encode guitar with standard tuning, decode back without instrument key (backward compat)" do
      chords = [%{root: "G", quality: :"7"}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(:guitar, tuning, chords)
      refute Map.has_key?(params, "instrument")

      {instrument, decoded_tuning, decoded_chords, _highlighted_index} =
        URLCodec.decode_params(params)

      assert instrument == :guitar
      assert decoded_tuning == tuning
      assert decoded_chords == chords
    end

    test "round-trip bass_4 with highlight preserves all fields" do
      chords = [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]
      tuning = ["D", "A", "D", "G"]

      params = URLCodec.encode_params(:bass_4, tuning, chords, 1)

      {instrument, decoded_tuning, decoded_chords, highlighted_index} =
        URLCodec.decode_params(params)

      assert instrument == :bass_4
      assert decoded_tuning == tuning
      assert decoded_chords == chords
      assert highlighted_index == 1
    end
  end
end
