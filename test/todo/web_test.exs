defmodule Todo.WebTest do
  use ExUnit.Case
  use Plug.Test

  @opts Todo.Web.init([])

  describe "get status" do
    test "renders ok message" do
      conn = conn(:get, "/status") |> Todo.Web.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end
  end

  describe "get to-do list entries for a specific date" do
    test "renders list of entries" do
      list_name = "Bob's list"
      date = ~D[2024-01-27]

      list_name
      |> Todo.Cache.server_process()
      |> Todo.Server.add_entry(%{date: date, title: "Dentist"})

      url = "/lists/#{list_name}/dates/#{Date.to_iso8601(date)}/entries"
      conn = conn(:get, url) |> Todo.Web.call(@opts)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == [
               %{"id" => 1, "date" => "2024-01-27", "title" => "Dentist"}
             ]
    end
  end

  test "unmatched routes return a 404" do
    conn = conn(:get, "/unknown") |> Todo.Web.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
