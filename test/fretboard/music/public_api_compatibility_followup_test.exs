defmodule Fretboard.Music.PublicAPICompatibilityFollowupTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music
  alias Fretboard.Music.{Chord, URLCodec}

  # e69eafa's Music facade delegates these exact arities to URLCodec and
  # Chord, not to the new absolute-pitch state API. Keep the legacy shapes.
  @standard ~w(E A D G B E)
  @drop_d ~w(D A D G B E)
  @chords [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]

  test "encode_params/2 retains legacy tuning and chord serialization" do
    assert Music.encode_params(@standard, []) == %{}
    assert Music.encode_params(@drop_d, @chords) == URLCodec.encode_params(@drop_d, @chords)

    assert Music.encode_params(@drop_d, @chords) ==
             %{"tuning" => "D,A,D,G,B,E", "chords" => "Cmaj,Amin"}
  end

  test "encode_params/3 retains nil and selected chord highlights" do
    for highlight <- [nil, 0, 1] do
      assert Music.encode_params(@drop_d, @chords, highlight) ==
               URLCodec.encode_params(@drop_d, @chords, highlight)
    end
  end

  test "encode_params/4 retains instrument-specific legacy defaults" do
    for {instrument, tuning} <- [
          {:guitar, @standard},
          {:bass_4, ~w(E A D G)},
          {:bass_5, ~w(B E A D G)},
          {:ukelele, ~w(G C E A)},
          {:ukelele, ~w(D G B E)}
        ],
        highlight <- [nil, 1] do
      assert Music.encode_params(instrument, tuning, @chords, highlight) ==
               URLCodec.encode_params(instrument, tuning, @chords, highlight)
    end
  end

  test "decode_params/1 returns a legacy note list tuple, not pitch state" do
    assert Music.decode_params(%{}) == {:guitar, @standard, [], nil}

    for params <- [
          %{"tuning" => "D,A,D,G,B,E", "chords" => "Cmaj,Amin", "highlight" => "Amin"},
          %{"instrument" => "ukelele", "tuning" => "D,G,B,E"},
          %{"instrument" => "invalid", "tuning" => "H", "chords" => "bad"},
          %{"instrument" => "ukelele", "pitches" => "55,60,64,69", "reference" => "Low G"}
        ] do
      assert Music.decode_params(params) == URLCodec.decode_params(params)
      {_instrument, tuning, _chords, _highlight} = Music.decode_params(params)
      assert is_list(tuning)
      assert Enum.all?(tuning, &is_binary/1)
    end
  end

  test "analyze_notes/1 preserves bass-free Chord.identify results" do
    for notes <- [[], ~w(C), ~w(C E C), ~w(C E G), ~w(C E G B)] do
      assert Music.analyze_notes(notes) == Chord.identify(notes)
    end

    assert Music.analyze_notes(~w(C E C)) == []
    assert Enum.any?(Music.analyze_notes(~w(C E G)), &(&1.root == "C" and &1.quality == :major))
  end

  test "analyze_notes/2 preserves bass and inversion annotations" do
    for {notes, bass} <- [{[], "C"}, {~w(C E C), "E"}, {~w(C E G), "E"}, {~w(C E G B), "B"}] do
      assert Music.analyze_notes(notes, bass) == Chord.identify(notes, bass)
    end

    assert Enum.any?(Music.analyze_notes(~w(C E G), "E"), fn result ->
             result.root == "C" and result.quality == :major and result.bass == "E" and
               result.slash_label == "Cmaj/E"
           end)
  end
end
