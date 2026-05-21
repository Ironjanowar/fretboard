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
      assert URLCodec.decode_params(%{}) == {["E", "A", "D", "G", "B", "E"], []}
    end

    test "decodes chords and tuning from params" do
      params = %{"chords" => "Cmaj,Amin", "tuning" => "D,A,D,G,B,E"}

      assert URLCodec.decode_params(params) == {
               ["D", "A", "D", "G", "B", "E"],
               [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]
             }
    end
  end

  describe "round-trip" do
    test "encode then decode produces same data" do
      chords = [
        %{root: "C", quality: :major},
        %{root: "A", quality: :minor},
        %{root: "F#", quality: :maj7}
      ]

      tuning = ["D", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords)
      {decoded_tuning, decoded_chords} = URLCodec.decode_params(params)

      assert decoded_tuning == tuning
      assert decoded_chords == chords
    end

    test "round-trip with standard tuning" do
      chords = [%{root: "G", quality: :"7"}]
      tuning = ["E", "A", "D", "G", "B", "E"]

      params = URLCodec.encode_params(tuning, chords)
      {decoded_tuning, decoded_chords} = URLCodec.decode_params(params)

      assert decoded_tuning == tuning
      assert decoded_chords == chords
    end
  end
end
