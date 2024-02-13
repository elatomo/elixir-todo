defmodule TodoCacheTest do
  use ExUnit.Case

  test "starts a new server if not found in the cache" do
    {:ok, cache} = Todo.Cache.start()
    server_1 = Todo.Cache.server_process(cache, "list 1")
    assert server_1 == Todo.Cache.server_process(cache, "list 1")
    assert server_1 != Todo.Cache.server_process(cache, "list 2")
  end
end
