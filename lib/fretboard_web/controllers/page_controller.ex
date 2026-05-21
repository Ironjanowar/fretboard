defmodule FretboardWeb.PageController do
  use FretboardWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
