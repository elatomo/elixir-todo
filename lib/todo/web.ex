defmodule Todo.Web do
  use Plug.Router
  require Logger

  plug(:match)
  # JSON parser only if the content-type is application/json
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get("/status", do: send_resp(conn, 200, "ok"))

  get "/lists/:list/dates/:date/entries" do
    entries =
      list
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(Date.from_iso8601!(date))

    send_resp_json(conn, 200, entries)
  end

  post "/lists/:list/dates/:date/entries" do
    %{"title" => title} = conn.body_params

    list
    |> Todo.Cache.server_process()
    |> Todo.Server.add_entry(%{date: Date.from_iso8601!(date), title: title})

    send_resp_json(conn, 201, %{})
  end

  delete "/lists/:list/entries/:entry_id" do
    list
    |> Todo.Cache.server_process()
    |> Todo.Server.delete_entry(String.to_integer(entry_id))

    send_resp(conn, 204, "")
  end

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

  defp send_resp_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
