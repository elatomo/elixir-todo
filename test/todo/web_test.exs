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

  describe "add to-do list entry for a specific date" do
    test "creates the entry and returns a 201 status" do
      # NOTE: Cleaning up the database after running the entire test suite
      # causes "id" values to autoincrement if the same list name is used across
      # tests. This discrepancy results in different outcomes when running
      # individual tests versus the entire suite. Employing unique list names
      # for each test resolves this.
      list_name = "Bob's list II"
      date = ~D[2024-01-27]

      url = "/lists/#{list_name}/dates/#{Date.to_iso8601(date)}/entries"

      conn =
        :post
        |> conn(url, Jason.encode!(%{title: "Test entry"}))
        |> put_req_header("content-type", "application/json")
        |> Todo.Web.call(@opts)

      assert conn.status == 201

      entries =
        list_name
        |> Todo.Cache.server_process()
        |> Todo.Server.entries(date)

      assert entries == [%{id: 1, date: date, title: "Test entry"}]
    end
  end

  describe "delete a to-do list entry" do
    test "delete the entry and returns a 204 status" do
      list_name = "Bob's list III"
      date = ~D[2024-01-27]
      entry_id = 1

      server = Todo.Cache.server_process(list_name)
      Todo.Server.add_entry(server, %{date: date, title: "Dentist"})

      # Sanity check
      assert length(Todo.Server.entries(server, date)) == 1

      conn =
        :delete
        |> conn("/lists/#{list_name}/entries/#{entry_id}")
        |> put_req_header("content-type", "application/json")
        |> Todo.Web.call(@opts)

      assert conn.status == 204
      assert Todo.Server.entries(server, date) == []
    end
  end

  test "unmatched routes return a 404" do
    conn = conn(:get, "/unknown") |> Todo.Web.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
