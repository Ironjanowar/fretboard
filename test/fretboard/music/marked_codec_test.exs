defmodule Fretboard.Music.MarkedCodecTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.URLCodec

  describe "encode_marked/1" do
    test "returns nil for empty list" do
      assert URLCodec.encode_marked([]) == nil
    end

    test "encodes a single string-fret pair" do
      assert URLCodec.encode_marked([{0, 3}]) == "0-3"
    end

    test "encodes multiple string-fret pairs" do
      assert URLCodec.encode_marked([{0, 3}, {2, 2}, {1, 0}]) == "0-3,2-2,1-0"
    end
  end

  describe "decode_marked/1" do
    test "returns [] for nil" do
      assert URLCodec.decode_marked(nil) == []
    end

    test "returns [] for empty string" do
      assert URLCodec.decode_marked("") == []
    end

    test "decodes a single pair" do
      assert URLCodec.decode_marked("0-3") == [{0, 3}]
    end

    test "decodes multiple pairs" do
      assert URLCodec.decode_marked("0-3,2-2,1-0") == [{0, 3}, {2, 2}, {1, 0}]
    end

    test "returns [] for a fully invalid string" do
      assert URLCodec.decode_marked("invalid") == []
    end

    test "skips invalid entries among valid ones" do
      assert URLCodec.decode_marked("0-3,invalid,2-2") == [{0, 3}, {2, 2}]
    end
  end

  describe "round-trip" do
    test "decode_marked(encode_marked(list)) returns the original list" do
      list = [{5, 12}, {3, 7}, {0, 0}]
      assert URLCodec.decode_marked(URLCodec.encode_marked(list)) == list
    end
  end
end
