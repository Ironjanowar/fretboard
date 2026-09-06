defmodule FretboardWeb.LiveSocketConfigTest do
  use ExUnit.Case, async: true

  test "configures the LiveSocket heartbeat interval to 20 seconds" do
    app_js = File.read!("assets/js/app.js")

    [_, options] =
      Regex.run(~r/new LiveSocket\("\/live", Socket, \{(.*?)^\}\)/ms, app_js)

    assert options =~ ~r/^\s*heartbeatIntervalMs:\s*20_000,\s*$/m
  end
end
