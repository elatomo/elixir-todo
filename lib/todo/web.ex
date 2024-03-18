defmodule Todo.Web do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  get "/status" do
    send_resp(conn, 200, "ok")
  end

  def child_spec(_arg) do
    Logger.debug("Starting web server")

    Bandit.child_spec(
      scheme: :http,
      plug: __MODULE__
    )
  end
end
