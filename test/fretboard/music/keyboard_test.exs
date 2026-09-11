defmodule Fretboard.Music.KeyboardTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music

  describe "piano metadata" do
    test "describes a fixed C3 through B5 keyboard without fabricated strings or tuning" do
      assert %{name: "Piano", kind: :keyboard, pitch_range: 48..83} =
               piano = Music.instrument(:piano)

      for field <- [:strings, :frets, :standard_tuning, :standard_pitches] do
        assert Map.get(piano, field) in [nil, []]
      end

      assert Map.get(piano, :pitch_presets, []) == []
      assert Map.get(piano, :presets, []) == []
    end

    test "includes piano in the catalog but keeps the existing fretted selector separate" do
      fretted = [
        {:guitar, "Guitar"},
        {:bass_4, "Bass (4-string)"},
        {:bass_5, "Bass (5-string)"},
        {:ukelele, "Ukulele"}
      ]

      assert {:piano, "Piano"} in Music.instruments()
      assert Music.fretted_instruments() == fretted
      assert Enum.reject(Music.instruments(), fn {key, _label} -> key == :piano end) == fretted
    end

    test "marks existing instrument metadata as fretted while preserving string counts" do
      for {instrument, strings} <- [guitar: 6, bass_4: 4, bass_5: 5, ukelele: 4] do
        assert %{kind: :fretted, strings: ^strings, frets: 24} = Music.instrument(instrument)
      end
    end

    test "offers no piano tuning presets or fabricated Standard tuning" do
      assert Music.instrument_pitch_presets(:piano) == []
      assert Music.instrument_tuning_presets(:piano) == []
      assert Music.instrument_preset_names(:piano) == []
      assert Music.preset_tuning(:piano, "Standard") == nil
    end
  end

  describe "keyboard_data/2" do
    test "returns every pitch in chromatic order with no memberships when chords are empty" do
      data = Music.keyboard_data(48..83, [])
      chromatic = ~w(C C# D D# E F F# G G# A A# B)

      assert Enum.map(data, & &1.pitch) == Enum.to_list(48..83)
      assert Enum.map(data, & &1.note) == List.duplicate(chromatic, 3) |> List.flatten()
      assert Enum.all?(data, &(&1.chords == []))
      assert hd(data) == %{pitch: 48, note: "C", chords: []}
      assert List.last(data) == %{pitch: 83, note: "B", chords: []}
    end

    test "marks every occurrence of C major and leaves all other pitches inactive" do
      data = Music.keyboard_data(48..83, [%{root: "C", quality: :major}])

      assert data |> Enum.filter(&(&1.chords == ["Cmaj"])) |> Enum.map(& &1.pitch) ==
               [48, 52, 55, 60, 64, 67, 72, 76, 79]

      assert Enum.all?(data, fn key ->
               key.chords == if(key.note in ["C", "E", "G"], do: ["Cmaj"], else: [])
             end)
    end

    test "preserves shared chord labels in active order consistently with fretboard data" do
      chords = [%{root: "A", quality: :minor}, %{root: "C", quality: :major}]
      data = Music.keyboard_data(48..83, chords)
      [frets] = Music.fretboard_data(["C"], chords)
      memberships = Map.new(frets, &{&1.note, &1.chords})

      assert Enum.all?(data, &(&1.chords == Map.fetch!(memberships, &1.note)))

      for key <- Enum.filter(data, &(&1.note in ["C", "E"])) do
        assert key.chords == ["Amin", "Cmaj"]
      end
    end
  end
end
