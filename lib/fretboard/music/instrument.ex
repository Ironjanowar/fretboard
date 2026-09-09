defmodule Fretboard.Music.Instrument do
  @moduledoc """
  Instrument metadata and tuning presets. MIDI pitches are the single source
  of tuning data; legacy note-name APIs are derived from this catalog.
  String order is physical, not pitch order (ukulele Standard is high-G).
  """

  alias Fretboard.Music.Pitch

  @instruments %{
    guitar: %{
      name: "Guitar",
      strings: 6,
      frets: 24,
      pitch_presets: [
        {"Standard", [40, 45, 50, 55, 59, 64]},
        {"Drop D", [38, 45, 50, 55, 59, 64]},
        {"DADGAD", [38, 45, 50, 55, 57, 62]},
        {"Open G", [38, 43, 50, 55, 59, 62]},
        {"Open D", [38, 45, 50, 54, 57, 62]},
        {"Open E", [40, 47, 52, 56, 59, 64]},
        {"Half Step Down", [39, 44, 49, 54, 58, 63]},
        {"Full Step Down", [38, 43, 48, 53, 57, 62]},
        {"Drop C", [36, 43, 48, 53, 57, 62]}
      ]
    },
    bass_4: %{
      name: "Bass (4-string)",
      strings: 4,
      frets: 24,
      pitch_presets: [
        {"Standard", [28, 33, 38, 43]},
        {"Drop D", [26, 33, 38, 43]},
        {"Half Step Down", [27, 32, 37, 42]}
      ]
    },
    bass_5: %{
      name: "Bass (5-string)",
      strings: 5,
      frets: 24,
      pitch_presets: [
        {"Standard", [23, 28, 33, 38, 43]},
        {"Half Step Down", [22, 27, 32, 37, 42]},
        {"Drop A", [21, 28, 33, 38, 43]}
      ]
    },
    ukelele: %{
      name: "Ukulele",
      strings: 4,
      frets: 24,
      pitch_presets: [
        {"Standard", [67, 60, 64, 69]},
        {"Low G", [55, 60, 64, 69]},
        {"D tuning", [69, 62, 66, 71]},
        {"Baritone", [50, 55, 59, 64]},
        {"Half Step Down", [66, 59, 63, 68]}
      ]
    }
  }
  @instrument_keys [:guitar, :bass_4, :bass_5, :ukelele]
  @type instrument_key :: :guitar | :bass_4 | :bass_5 | :ukelele
  @type preset :: {String.t(), [String.t()]}

  @doc "Returns supported instrument keys and labels in display order."
  @spec instruments() :: [{instrument_key(), String.t()}]
  def instruments, do: Enum.map(@instrument_keys, &{&1, @instruments[&1].name})

  @doc "Returns instrument metadata, including derived legacy tuning fields, or nil."
  @spec instrument(atom()) :: map() | nil
  def instrument(key) when key in @instrument_keys do
    Map.merge(@instruments[key], %{
      standard_pitches: instrument_standard_pitches(key),
      standard_tuning: instrument_standard_tuning(key),
      presets: instrument_tuning_presets(key)
    })
  end

  def instrument(_key), do: nil

  @doc "Returns the instrument string count."
  @spec instrument_strings(instrument_key()) :: pos_integer()
  def instrument_strings(key) when key in @instrument_keys, do: @instruments[key].strings

  @doc "Returns the standard note names in physical string order."
  @spec instrument_standard_tuning(instrument_key()) :: [String.t()]
  def instrument_standard_tuning(key),
    do: Enum.map(instrument_standard_pitches(key), &Pitch.note_name/1)

  @doc "Returns the standard absolute open-string MIDI pitches."
  @spec instrument_standard_pitches(instrument_key()) :: [integer()]
  def instrument_standard_pitches(key), do: preset_pitches(key, "Standard")

  @doc "Returns all named MIDI pitch presets."
  @spec instrument_pitch_presets(instrument_key()) :: [{String.t(), [integer()]}]
  def instrument_pitch_presets(key) when key in @instrument_keys,
    do: @instruments[key].pitch_presets

  @doc "Returns a named preset's pitches, or nil for an unknown name."
  @spec preset_pitches(instrument_key(), String.t()) :: [integer()] | nil
  def preset_pitches(key, name) do
    case List.keyfind(instrument_pitch_presets(key), name, 0) do
      {_, pitches} -> pitches
      nil -> nil
    end
  end

  @doc "Returns legacy named note lists derived from the MIDI catalog."
  @spec instrument_tuning_presets(instrument_key()) :: [preset()]
  def instrument_tuning_presets(key) do
    Enum.map(instrument_pitch_presets(key), fn {name, pitches} ->
      {name, Enum.map(pitches, &Pitch.note_name/1)}
    end)
  end

  @doc "Returns preset names in display order."
  @spec instrument_preset_names(instrument_key()) :: [String.t()]
  def instrument_preset_names(key), do: Enum.map(instrument_pitch_presets(key), &elem(&1, 0))
end
