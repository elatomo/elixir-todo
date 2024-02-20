ExUnit.start()

# Override the custom database location to the tmp folder during tests and clean
# up once the suite is finished.
xdg_data_home = System.get_env("XDG_DATA_HOME")
tmp_xdg_data_home = Path.join(System.tmp_dir!(), "test-todo-elixir")
System.put_env("XDG_DATA_HOME", tmp_xdg_data_home)

ExUnit.after_suite(fn _result ->
  File.rm_rf!(tmp_xdg_data_home)
  # NOTE: If the variable was initially unset (set to :nil), we can't unset
  # it again using `put_env/2`; only `put_env/1` can handle it.
  System.put_env([{"XDG_DATA_HOME", xdg_data_home}])
end)
