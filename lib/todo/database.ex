defmodule Todo.Database do
  @moduledoc """
  Simple disk-based database, encoding data into the Erlang external term
  format.

  Manages a pool of workers to handle database requests.

  ## Example

      iex> Todo.ProcessRegistry.start_link()
      iex> Todo.Database.start_link([])
      iex> Todo.Database.get("new_db")
      nil
      iex> todo_list = Todo.List.new() |>
      ...>   Todo.List.add_entry(%{date: ~D[2024-01-27], title: "Dentist"})
      iex> Todo.Database.store("new_db", todo_list)
      iex> Todo.Database.get("new_db")
      %Todo.List{
        auto_id: 2,
        entries: %{
          1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist"}
        }
      }

  """

  use Supervisor
  require Logger

  @pool_size 3
  @folder_name "elixir-todo"

  def start_link(_) do
    Logger.debug("Starting to-do database")
    db_folder = ensure_db_folder()
    Supervisor.start_link(__MODULE__, db_folder, name: __MODULE__)
  end

  @impl true
  def init(db_folder) do
    workers = Enum.map(1..@pool_size, &worker_spec(&1, db_folder))
    Supervisor.init(workers, strategy: :one_for_one)
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  defp worker_spec(worker_id, db_folder) do
    Supervisor.child_spec(
      {Todo.DatabaseWorker, {db_folder, worker_id}},
      id: worker_id
    )
  end

  defp choose_worker(key) do
    # Ensure we always choose the same worker for the same key to ensure per-key
    # synchronization at the db level. To do so, we use `:erlang.phash2/2` to
    # compute and normalize the key's hash within the range.
    :erlang.phash2(key, @pool_size) + 1
  end

  defp ensure_db_folder() do
    xdg_data_home = System.get_env("XDG_DATA_HOME") || "~/.local/share"
    db_folder = Path.expand(Path.join(xdg_data_home, @folder_name))
    File.mkdir_p!(db_folder)

    db_folder
  end
end
