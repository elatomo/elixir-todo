defmodule TodoDatabaseTest do
  use ExUnit.Case
  doctest Todo.Database

  setup do
    xdg_data_home = System.get_env("XDG_DATA_HOME")
    tmp_xdg_data_home = Path.join(System.tmp_dir!(), "test-todo-elixir")
    System.put_env("XDG_DATA_HOME", tmp_xdg_data_home)

    on_exit(fn ->
      File.rm_rf!(tmp_xdg_data_home)
      # NOTE: If the variable was initially unset (set to :nil), we can't unset
      # it again using `put_env/2`; only `put_env/1` can handle it.
      System.put_env([{"XDG_DATA_HOME", xdg_data_home}])
    end)
  end
end
