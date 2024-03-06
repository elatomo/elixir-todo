defmodule TodoCacheTest do
  use ExUnit.Case

  test "starts a new server if not found in the cache" do
    Todo.ProcessRegistry.start_link()
    {:ok, _} = Todo.Cache.start_link([])
    server_1 = Todo.Cache.server_process("list 1")
    assert server_1 == Todo.Cache.server_process("list 1")
    assert server_1 != Todo.Cache.server_process("list 2")
  end
end
