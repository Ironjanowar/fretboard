defmodule Fretboard.Music.PageCodec do
  @moduledoc """
  Instrument-aware page URL state. Piano selections are absolute pitches;
  fretted selections and tuning retain the legacy URL contract.
  """

  alias Fretboard.Music.{Instrument, URLCodec}

  @doc "Decodes page state, ignoring fields belonging to other instrument kinds."
  @spec decode_page_params(map()) :: map()
  def decode_page_params(%{"instrument" => "piano"} = params) do
    {chords, highlight} = URLCodec.decode_chord_params(params)

    %{
      instrument: :piano,
      tuning_state: nil,
      active_chords: chords,
      highlighted_chord: highlight,
      tab: URLCodec.decode_tab(params["tab"]),
      selection: decode_keys(params["keys"])
    }
  end

  def decode_page_params(params) do
    {instrument, tuning_state, chords, highlight} = URLCodec.decode_pitch_params(params)
    string_count = Instrument.instrument_strings(instrument)
    frets = get_in(Instrument.instrument(instrument) || %{}, [:frets]) || 24

    selection =
      params["marked"]
      |> URLCodec.decode_marked_map()
      |> Map.filter(fn {string, fret} ->
        string >= 0 and string < string_count and fret in 0..frets
      end)

    %{
      instrument: instrument,
      tuning_state: tuning_state,
      active_chords: chords,
      highlighted_chord: highlight,
      tab: URLCodec.decode_tab(params["tab"]),
      selection: selection
    }
  end

  @doc "Encodes page state with canonical piano keys and omitted default fields."
  @spec encode_page_params(map()) :: map()
  def encode_page_params(state) do
    state
    |> encode_instrument_params()
    |> maybe_put("tab", if(state.tab == :analyzer, do: "analyzer"))
  end

  defp encode_instrument_params(%{instrument: :piano} = state) do
    state.active_chords
    |> URLCodec.encode_chord_params(state.highlighted_chord)
    |> Map.put("instrument", "piano")
    |> maybe_put("keys", encode_keys(state.selection))
  end

  defp encode_instrument_params(state) do
    state.instrument
    |> URLCodec.encode_pitch_params(
      state.tuning_state,
      state.active_chords,
      state.highlighted_chord
    )
    |> maybe_put("marked", URLCodec.encode_marked_map(state.selection))
  end

  defp decode_keys(value) when is_binary(value) do
    value
    |> String.split(",")
    |> Enum.flat_map(fn token ->
      case Integer.parse(token) do
        {pitch, ""} -> [pitch]
        _ -> []
      end
    end)
    |> canonical_keys()
  end

  defp decode_keys(_), do: []

  defp encode_keys(selection) do
    case canonical_keys(selection) do
      [] -> nil
      keys -> Enum.join(keys, ",")
    end
  end

  defp canonical_keys(keys) do
    keys
    |> Enum.filter(&(is_integer(&1) and &1 in piano_range()))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp piano_range do
    Instrument.instrument(:piano)[:pitch_range] || 48..83
  end

  defp maybe_put(params, _key, nil), do: params
  defp maybe_put(params, key, value), do: Map.put(params, key, value)
end
