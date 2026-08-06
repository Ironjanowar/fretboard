defmodule Fretboard.Music.URLCodecExtendedTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.URLCodec

  describe "encode/decode roundtrip for new qualities" do
    test "C6 (maj6)" do
      chord = %{root: "C", quality: :maj6}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C6"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm6 (min6)" do
      chord = %{root: "C", quality: :min6}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm6"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C6/9 (maj6_9)" do
      chord = %{root: "C", quality: :maj6_9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C6/9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm6/9 (min6_9)" do
      chord = %{root: "C", quality: :min6_9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm6/9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cadd9 (add9)" do
      chord = %{root: "C", quality: :add9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cadd9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cmadd9 (m_add9)" do
      chord = %{root: "C", quality: :m_add9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cmadd9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C9 (9)" do
      chord = %{root: "C", quality: :"9"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cmaj9 (maj9)" do
      chord = %{root: "C", quality: :maj9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cmaj9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm9 (min9)" do
      chord = %{root: "C", quality: :min9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7b9 (7b9)" do
      chord = %{root: "C", quality: :"7b9"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7b9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7#9 (7#9)" do
      chord = %{root: "C", quality: :"7#9"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7#9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C9#5 (9#5)" do
      chord = %{root: "C", quality: :"9#5"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C9#5"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C9b5 (9b5)" do
      chord = %{root: "C", quality: :"9b5"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C9b5"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7b5 (7b5)" do
      chord = %{root: "C", quality: :"7b5"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7b5"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7sus (7sus4)" do
      chord = %{root: "C", quality: :"7sus4"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7sus"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "CdimMaj7 (dim_maj7)" do
      chord = %{root: "C", quality: :dim_maj7}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "CdimMaj7"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cmaj7#11 (maj7#11)" do
      chord = %{root: "C", quality: :"maj7#11"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cmaj7#11"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7#11 (7#11)" do
      chord = %{root: "C", quality: :"7#11"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7#11"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7b13 (7b13)" do
      chord = %{root: "C", quality: :"7b13"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7b13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C7b9b13 (7b9b13)" do
      chord = %{root: "C", quality: :"7b9b13"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C7b9b13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C11 (11)" do
      chord = %{root: "C", quality: :"11"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C11"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cmaj11 (maj11)" do
      chord = %{root: "C", quality: :maj11}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cmaj11"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm11 (min11)" do
      chord = %{root: "C", quality: :min11}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm11"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm11b5 (m11b5)" do
      chord = %{root: "C", quality: :m11b5}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm11b5"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C13 (13)" do
      chord = %{root: "C", quality: :"13"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cmaj13 (maj13)" do
      chord = %{root: "C", quality: :maj13}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cmaj13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm13 (min13)" do
      chord = %{root: "C", quality: :min13}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "C13b9 (13b9)" do
      chord = %{root: "C", quality: :"13b9"}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "C13b9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Csus9 (sus9)" do
      chord = %{root: "C", quality: :sus9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Csus9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Csusb9 (susb9)" do
      chord = %{root: "C", quality: :susb9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Csusb9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Csus13 (sus13)" do
      chord = %{root: "C", quality: :sus13}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Csus13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cm7b13 (min7b13)" do
      chord = %{root: "C", quality: :min7b13}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cm7b13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "Cdim7b13 (dim7b13)" do
      chord = %{root: "C", quality: :dim7b13}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "Cdim7b13"
      assert URLCodec.decode_chords(encoded) == [chord]
    end
  end

  describe "decode_chords/1 specific cases" do
    test "decodes C9 as quality :" do
      assert URLCodec.decode_chords("C9") == [%{root: "C", quality: :"9"}]
    end

    test "decodes Cm9 as quality :min9" do
      assert URLCodec.decode_chords("Cm9") == [%{root: "C", quality: :min9}]
    end

    test "decodes Cmaj7#11 as quality :\"maj7#11\"" do
      assert URLCodec.decode_chords("Cmaj7#11") == [%{root: "C", quality: :"maj7#11"}]
    end

    test "decodes C6/9 as quality :maj6_9" do
      assert URLCodec.decode_chords("C6/9") == [%{root: "C", quality: :maj6_9}]
    end

    test "decodes C7sus as quality :\"7sus4\"" do
      assert URLCodec.decode_chords("C7sus") == [%{root: "C", quality: :"7sus4"}]
    end
  end

  describe "decode with sharp roots" do
    test "F#maj9 roundtrips" do
      chord = %{root: "F#", quality: :maj9}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "F#maj9"
      assert URLCodec.decode_chords(encoded) == [chord]
    end

    test "A#m11b5 roundtrips" do
      chord = %{root: "A#", quality: :m11b5}
      encoded = URLCodec.encode_chords([chord])
      assert encoded == "A#m11b5"
      assert URLCodec.decode_chords(encoded) == [chord]
    end
  end
end
