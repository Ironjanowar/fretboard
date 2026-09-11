defmodule Fretboard.Music.PianoURLTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music

  @chords [%{root: "C", quality: :major}, %{root: "A", quality: :minor}]

  describe "decode_page_params/1 for piano" do
    test "recognizes piano without manufacturing tuning or string selection" do
      assert Music.decode_page_params(%{"instrument" => "piano"}) == %{
               instrument: :piano,
               tuning_state: nil,
               active_chords: [],
               highlighted_chord: nil,
               tab: :visualizer,
               selection: []
             }
    end

    test "sorts and deduplicates complete integer keys within C3 through B5" do
      params = %{
        "instrument" => "piano",
        "keys" => "83,60,48,60,47,84,-1,128,61junk,62.0,6e1,,C4, 63,64 "
      }

      assert Music.decode_page_params(params).selection == [48, 60, 83]
    end

    test "non-string keys become empty without discarding valid siblings" do
      for value <- [nil, [], ["60"], %{}, %{"nested" => "60"}, 60, false] do
        params = piano_params() |> Map.put("keys", value)

        assert Music.decode_page_params(params) == piano_state([])
      end
    end

    test "invalid key tokens do not discard valid chords, tab or highlight" do
      params = piano_params() |> Map.put("keys", "nope,47,84,60x")

      assert Music.decode_page_params(params) == piano_state([])
    end

    test "ignores fretted-only fields even when they contain valid or malformed values" do
      for irrelevant <- [
            %{
              "tuning" => "D,A,D,G,B,E",
              "pitches" => "38,45,50,55,59,64",
              "reference" => "Drop D",
              "marked" => "0-3,1-5"
            },
            %{"tuning" => [], "pitches" => %{}, "reference" => false, "marked" => 42}
          ] do
        assert Music.decode_page_params(Map.merge(piano_params(), irrelevant)) ==
                 piano_state([48, 60, 83])
      end
    end

    test "retains legacy sibling defaults and skips invalid chords" do
      params = %{
        "instrument" => "piano",
        "keys" => "60",
        "chords" => "bogus,Cmaj,Amin",
        "highlight" => "Amin",
        "tab" => "unknown"
      }

      assert Music.decode_page_params(params) == %{
               piano_state([60])
               | tab: :visualizer
             }

      assert Music.decode_page_params(Map.put(params, "highlight", "Dmaj")).highlighted_chord ==
               nil
    end
  end

  describe "encode_page_params/1 for piano" do
    test "emits canonical keys and no fretted-only parameters" do
      state = piano_state([83, 60, 48, 60, 47, 84])

      assert Music.encode_page_params(state) == piano_params()
    end

    test "omits empty keys and default sibling fields" do
      state = %{
        piano_state([])
        | active_chords: [],
          highlighted_chord: nil,
          tab: :visualizer
      }

      assert Music.encode_page_params(state) == %{"instrument" => "piano"}
    end

    test "piano selection and sibling fields survive the URL wire format in either tab" do
      for tab <- [:analyzer, :visualizer] do
        state = %{piano_state([48, 60, 83]) | tab: tab}

        decoded =
          state
          |> Music.encode_page_params()
          |> URI.encode_query()
          |> URI.decode_query()
          |> Music.decode_page_params()

        assert decoded == state
      end
    end
  end

  describe "fretted compatibility" do
    test "legacy pitch decoder keeps piano URLs on the safe guitar fallback" do
      params = piano_params()
      fallback = Map.put(params, "instrument", "guitar")

      assert Music.decode_pitch_params(params) == Music.decode_pitch_params(fallback)

      assert {:guitar, %{pitches: [40, 45, 50, 55, 59, 64], reference: "Standard"}, @chords, 1} =
               Music.decode_pitch_params(params)
    end

    test "default page state retains guitar defaults and empty marked selection" do
      assert Music.decode_page_params(%{}) == %{
               instrument: :guitar,
               tuning_state: Music.preset_tuning(:guitar, "Standard"),
               active_chords: [],
               highlighted_chord: nil,
               tab: :visualizer,
               selection: %{}
             }

      state = Music.decode_page_params(%{})
      assert Music.encode_page_params(state) == %{}
    end

    test "fretted page decoding reuses exact pitches and ignores piano keys" do
      params = %{
        "instrument" => "ukelele",
        "pitches" => "55,60,64,69",
        "reference" => "Low G",
        "tuning" => "D,G,B,E",
        "chords" => "Cmaj,Amin",
        "highlight" => "Amin",
        "tab" => "analyzer",
        "marked" => "2-3,0-5,0-2,bad",
        "keys" => "48,60,83"
      }

      assert Music.decode_page_params(params) == %{
               instrument: :ukelele,
               tuning_state: %{pitches: [55, 60, 64, 69], reference: "Low G"},
               active_chords: @chords,
               highlighted_chord: 1,
               tab: :analyzer,
               selection: %{0 => 2, 2 => 3}
             }

      assert Music.decode_page_params(params) ==
               Music.decode_page_params(Map.put(params, "keys", %{"nested" => [60]}))
    end

    test "legacy tuning and invalid authoritative pitches retain their existing semantics" do
      for tuning_params <- [
            %{"tuning" => "D,A,D,G,B,E", "reference" => "Drop D"},
            %{"tuning" => "D,A,D,G,B,E", "pitches" => "bad", "reference" => "Drop D"}
          ] do
        params = Map.merge(tuning_params, %{"marked" => "0-3", "keys" => "60"})
        {instrument, tuning_state, chords, highlight} = Music.decode_pitch_params(params)

        assert Music.decode_page_params(params) == %{
                 instrument: instrument,
                 tuning_state: tuning_state,
                 active_chords: chords,
                 highlighted_chord: highlight,
                 tab: :visualizer,
                 selection: %{0 => 3}
               }
      end
    end

    test "fretted encoding preserves the legacy codec and roundtrips through a URL" do
      for {instrument, preset} <- [{:guitar, "Drop D"}, {:ukelele, "Low G"}] do
        tuning_state = Music.preset_tuning(instrument, preset)

        state = %{
          instrument: instrument,
          tuning_state: tuning_state,
          active_chords: @chords,
          highlighted_chord: 1,
          tab: :analyzer,
          selection: %{0 => 2, 2 => 3}
        }

        expected =
          instrument
          |> Music.encode_pitch_params(tuning_state, @chords, 1)
          |> Map.merge(%{"tab" => "analyzer", "marked" => "0-2,2-3"})

        encoded = Music.encode_page_params(state)
        assert encoded == expected
        refute Map.has_key?(encoded, "keys")

        assert encoded |> URI.encode_query() |> URI.decode_query() |> Music.decode_page_params() ==
                 state
      end
    end

    test "unknown instrument and tab strings fall back without creating input atoms" do
      unknown = "piano_url_unknown_#{System.unique_integer([:positive])}"
      assert_raise ArgumentError, fn -> String.to_existing_atom(unknown) end

      state =
        Music.decode_page_params(%{
          "instrument" => unknown,
          "tab" => unknown,
          "keys" => unknown,
          "chords" => "Cmaj,#{unknown}",
          "highlight" => unknown
        })

      assert state.instrument == :guitar
      assert state.tab == :visualizer
      assert state.active_chords == [%{root: "C", quality: :major}]
      assert state.highlighted_chord == nil
      assert state.selection == %{}
      assert_raise ArgumentError, fn -> String.to_existing_atom(unknown) end
    end
  end

  defp piano_params do
    %{
      "instrument" => "piano",
      "keys" => "48,60,83",
      "chords" => "Cmaj,Amin",
      "highlight" => "Amin",
      "tab" => "analyzer"
    }
  end

  defp piano_state(selection) do
    %{
      instrument: :piano,
      tuning_state: nil,
      active_chords: @chords,
      highlighted_chord: 1,
      tab: :analyzer,
      selection: selection
    }
  end
end
