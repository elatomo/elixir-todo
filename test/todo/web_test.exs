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

  test "unmatched routes return a 404" do
    conn = conn(:get, "/unknown") |> Todo.Web.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
