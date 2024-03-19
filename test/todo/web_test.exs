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
end
