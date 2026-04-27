defmodule Elisnake.Application do
  @moduledoc """
  This is the entry point for the main application
  """
  # use Application
  require Logger

  # ----------------------------------------------------------------------------
  # Public APIs
  # ----------------------------------------------------------------------------

  def children() do
    [
      Elisnake.Storage.Game,
      Elisnake.GameSm.Sup,
      {Plug.Cowboy,
       scheme: :http,
       plug: {Elisnake.Router, []},
       options: [port: 4000, dispatch: dispatch()],
       otp_app: :http_server}
    ]
  end

  defp dispatch do
    [
      {:_,
       [
         {"/", :cowboy_static, {:priv_file, :nerves_grisp, "index.html"}},
         {"/websocket", Elisnake.Gateway.Websocket, []},
         {"/static/[...]", :cowboy_static, {:priv_dir, :nerves_grisp, "static"}},
         {:_, Plug.Cowboy.Handler, {Elisnake.Gateway.Router, []}}
       ]}
    ]
  end
end
