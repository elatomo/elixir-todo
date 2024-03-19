defmodule Todo.Web do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  get("/status", do: send_resp(conn, 200, "ok"))

  # Fallback handler when there is no match
  match(_, do: send_resp(conn, 404, "Not Found"))

  def child_spec(_arg) do
    http_port = Application.get_env(:todo, :http_port)
    Logger.debug("Starting web server on port #{http_port}")

    Bandit.child_spec(
      scheme: :http,
      plug: __MODULE__,
      port: http_port
    )
  end
end
