defmodule FretboardWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :fretboard

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_fretboard_key",
    signing_salt: "OEqBErZ+",
    same_site: "Lax"
  ]

  @base_path Application.compile_env(:fretboard, :base_path, "/")

  socket "#{@base_path}/live" |> String.replace("//", "/"),
         Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static files from "priv/static" directory.
  plug Plug.Static,
    at: @base_path,
    from: :fretboard,
    gzip: not code_reloading?,
    only: FretboardWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug FretboardWeb.Router
end
