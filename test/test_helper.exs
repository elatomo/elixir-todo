ExUnit.start()

db_folder = Application.get_env(:todo, :db_folder)

if Path.dirname(db_folder) != System.tmp_dir() do
  raise("Database folder not in temp directory")
end

# Clean up once the suite is finished
ExUnit.after_suite(fn _result ->
  File.rm_rf!(db_folder)
end)
