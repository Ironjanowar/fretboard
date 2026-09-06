defmodule FretboardWeb.ChangeStringValidationFollowupTest do
  use FretboardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @tag :valid_control
  test "valid edit retains Low G reference while displaying Custom", %{conn: conn} do
    {:ok, view, _} = live(conn, "/?instrument=ukelele&pitches=55,60,64,69&reference=Low+G")
    render_click(view, "open_tuning_modal")
    assert_valid_edit(view)
  end

  defp assert_valid_edit(view) do
    render_change(view, "change_string", %{"string" => "0", "note" => "D"})
    assert has_element?(view, "#string-select-0 option[value='D'][selected]")
    assert has_element?(view, "option[value='Custom'][selected]")
    render_click(view, "apply_tuning")
    query = assert_patch(view) |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
    assert query["pitches"] == "50,60,64,69"
    assert query["reference"] == "Low G"
  end

  for {label, params} <- [
        {"index equal to string count", %{"string" => "4", "note" => "D"}},
        {"index far outside range", %{"string" => "999", "note" => "D"}},
        {"negative index", %{"string" => "-1", "note" => "D"}},
        {"non-integer index", %{"string" => "abc", "note" => "D"}},
        {"partially numeric index", %{"string" => "0oops", "note" => "D"}},
        {"invalid note", %{"string" => "0", "note" => "H"}}
      ] do
    @params params
    test "change_string ignores #{label} and the view remains usable", %{conn: conn} do
      {:ok, view, _} =
        live(conn, "/?instrument=ukelele&pitches=55,60,64,69&reference=Low+G")

      render_click(view, "open_tuning_modal")
      before = render(view)

      render_change(view, "change_string", @params)

      # A no-op event leaves the rendered view byte-for-byte unchanged.
      assert render(view) == before

      # A real valid edit and apply must still work after the rejected event.
      assert_valid_edit(view)
    end
  end
end
