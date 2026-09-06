defmodule Fretboard.Music.URLBoundaryTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music
  alias Fretboard.Music.URLCodec

  @invalid_values [[], ["Cmaj"], %{}, %{"nested" => ["Cmaj"]}, 42, false]

  for field <- ~w(tuning chords), value <- @invalid_values do
    test "#{field} rejects non-string #{inspect(value)} without discarding valid sibling fields" do
      field = unquote(field)
      value = unquote(Macro.escape(value))

      valid = %{
        "instrument" => "ukelele",
        "tuning" => "D,G,B,E",
        "chords" => "Cmaj,Amin",
        "highlight" => "Amin"
      }

      fallback = Map.delete(valid, field)
      malformed = Map.put(valid, field, value)

      assert Music.decode_pitch_params(malformed) == Music.decode_pitch_params(fallback)
      assert URLCodec.decode_params(malformed) == URLCodec.decode_params(fallback)
    end
  end

  for value <- @invalid_values do
    test "marked rejects non-string #{inspect(value)} as an empty selection" do
      value = unquote(Macro.escape(value))
      assert URLCodec.decode_marked(value) == []
      assert URLCodec.decode_marked_map(value) == %{}
    end
  end

  test "other scalar fields ignore nested values using their existing defaults" do
    for value <- @invalid_values do
      valid = %{
        "instrument" => "ukelele",
        "pitches" => "55,60,64,69",
        "reference" => "Low G",
        "chords" => "Cmaj,Amin",
        "highlight" => "Amin"
      }

      for field <- ~w(instrument highlight reference) do
        assert Music.decode_pitch_params(Map.put(valid, field, value)) ==
                 Music.decode_pitch_params(Map.delete(valid, field))
      end

      assert URLCodec.decode_tab(value) == :visualizer

      assert {:ukelele, %{pitches: [67, 60, 64, 69], reference: "Standard"}, _, _} =
               Music.decode_pitch_params(Map.put(valid, "pitches", value))
    end
  end

  test "authoritative exact pitches ignore even malformed legacy tuning" do
    for value <- @invalid_values do
      assert {:ukelele, %{pitches: [55, 60, 64, 69], reference: "Low G"}, [], nil} =
               Music.decode_pitch_params(%{
                 "instrument" => "ukelele",
                 "pitches" => "55,60,64,69",
                 "reference" => "Low G",
                 "tuning" => value
               })
    end
  end
end
