defmodule Fretboard.Music.ChordModeTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music

  test "inference preserves the existing classification for the entire catalog" do
    sevenths = [:"7", :maj7, :min7, :dim7, :m7b5, :min_maj7, :aug_maj7, :aug7]

    assert Music.infer_chord_mode([]) == :triad

    for quality <- Music.available_qualities() do
      expected = if quality in sevenths, do: :seventh, else: :triad
      assert Music.infer_chord_mode([%{root: "C", quality: quality}]) == expected

      assert Music.infer_chord_mode([
               %{root: "D", quality: :major},
               %{root: "C", quality: quality}
             ]) == expected
    end
  end
end
