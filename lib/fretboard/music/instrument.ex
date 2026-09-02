defmodule Fretboard.Music.Instrument do
  @moduledoc """
  Instrument definitions for the fretboard.

  Provides metadata for supported instruments (guitar, 4-string bass,
  5-string bass) including string count, standard tuning, tuning presets,
  and fret count.
  """

  @guitar_presets [
    {"Standard", ["E", "A", "D", "G", "B", "E"]},
    {"Drop D", ["D", "A", "D", "G", "B", "E"]},
    {"DADGAD", ["D", "A", "D", "G", "A", "D"]},
    {"Open G", ["D", "G", "D", "G", "B", "D"]},
    {"Open D", ["D", "A", "D", "F#", "A", "D"]},
    {"Open E", ["E", "B", "E", "G#", "B", "E"]},
    {"Half Step Down", ["D#", "G#", "C#", "F#", "A#", "D#"]},
    {"Full Step Down", ["D", "G", "C", "F", "A", "D"]},
    {"Drop C", ["C", "G", "C", "F", "A", "D"]}
  ]

  @bass_4_presets [
    {"Standard", ["E", "A", "D", "G"]},
    {"Drop D", ["D", "A", "D", "G"]},
    {"Half Step Down", ["D#", "G#", "C#", "F#"]}
  ]

  @bass_5_presets [
    {"Standard", ["B", "E", "A", "D", "G"]},
    {"Half Step Down", ["A#", "D#", "G#", "C#", "F#"]},
    {"Drop A", ["A", "E", "A", "D", "G"]}
  ]

  @ukelele_presets [
    {"Standard", ["G", "C", "E", "A"]},
    {"D tuning", ["A", "D", "F#", "B"]},
    {"Baritone", ["D", "G", "B", "E"]},
    {"Half Step Down", ["F#", "B", "D#", "G#"]}
  ]

  @instruments %{
    guitar: %{
      name: "Guitar",
      strings: 6,
      standard_tuning: ["E", "A", "D", "G", "B", "E"],
      presets: @guitar_presets,
      frets: 24
    },
    bass_4: %{
      name: "Bass (4-string)",
      strings: 4,
      standard_tuning: ["E", "A", "D", "G"],
      presets: @bass_4_presets,
      frets: 24
    },
    bass_5: %{
      name: "Bass (5-string)",
      strings: 5,
      standard_tuning: ["B", "E", "A", "D", "G"],
      presets: @bass_5_presets,
      frets: 24
    },
    ukelele: %{
      name: "Ukelele",
      strings: 4,
      standard_tuning: ["G", "C", "E", "A"],
      presets: @ukelele_presets,
      frets: 24
    }
  }

  @type instrument_key :: :guitar | :bass_4 | :bass_5 | :ukelele
  @type preset :: {String.t(), [String.t()]}

  @instrument_keys [:guitar, :bass_4, :bass_5, :ukelele]

  @doc """
  Returns a list of `{key, label}` tuples for all supported instruments.
  """
  @spec instruments() :: [{atom(), String.t()}]
  def instruments do
    [
      {:guitar, "Guitar"},
      {:bass_4, "Bass (4-string)"},
      {:bass_5, "Bass (5-string)"},
      {:ukelele, "Ukelele"}
    ]
  end

  @doc """
  Returns the full instrument definition map for the given instrument key.

  The map contains `:name`, `:strings`, `:standard_tuning`, `:presets`, and
  `:frets`. Returns `nil` for unknown instruments.
  """
  @spec instrument(instrument_key() | atom()) :: map() | nil
  def instrument(key) when key in @instrument_keys do
    Map.get(@instruments, key)
  end

  def instrument(_key), do: nil

  @doc """
  Returns the number of strings for the given instrument.
  """
  @spec instrument_strings(instrument_key()) :: pos_integer()
  def instrument_strings(key) when key in @instrument_keys do
    instrument(key).strings
  end

  @doc """
  Returns the standard tuning (list of note names, low to high) for the
  given instrument.
  """
  @spec instrument_standard_tuning(instrument_key()) :: [String.t()]
  def instrument_standard_tuning(key) when key in @instrument_keys do
    instrument(key).standard_tuning
  end

  @doc """
  Returns the list of tuning presets for the given instrument.

  Each preset is a tuple of `{name, notes}`.
  """
  @spec instrument_tuning_presets(instrument_key()) :: [preset()]
  def instrument_tuning_presets(key) when key in @instrument_keys do
    instrument(key).presets
  end

  @doc """
  Returns just the names of all tuning presets for the given instrument.
  """
  @spec instrument_preset_names(instrument_key()) :: [String.t()]
  def instrument_preset_names(key) when key in @instrument_keys do
    key
    |> instrument_tuning_presets()
    |> Enum.map(&elem(&1, 0))
  end
end
