import Config

xdg_data_home = System.get_env("XDG_DATA_HOME") || "~/.local/share"

config :todo,
  db_folder: Path.expand(Path.join(xdg_data_home, "elixir-todo"))

# Override database folder during tests
if Config.config_env() == :test do
  config :todo, db_folder: Path.join(System.tmp_dir!(), "test-todo-elixir")
end
