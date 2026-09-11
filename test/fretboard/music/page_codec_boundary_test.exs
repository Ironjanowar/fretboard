defmodule Fretboard.Music.PageCodecBoundaryTest do
  use ExUnit.Case, async: true

  alias Fretboard.Music.PageCodec

  test "fretted page selection rejects negative and out-of-range positions" do
    params = %{
      "instrument" => "ukelele",
      "marked" => "0--1,1-25,4-3,2-24,3-0,0-99,-1-2"
    }

    assert PageCodec.decode_page_params(params).selection == %{2 => 24, 3 => 0}
  end

  test "fretted page selection rejects a negative fret without dropping valid siblings" do
    assert PageCodec.decode_page_params(%{"marked" => "0--1,1-0"}).selection == %{1 => 0}
  end
end
