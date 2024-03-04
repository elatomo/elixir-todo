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

  use GenServer
  require Logger

  @pool_size 3
  @folder_name "elixir-todo"

  def start_link(_) do
    # Start the server and register the process locally
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
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

  defp choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  @impl GenServer
  def init(_) do
    Logger.debug("Starting to-do database")
    db_folder = ensure_db_folder()
    start_workers(db_folder)
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:choose_worker, key}, _, state) do
    # Ensure we always choose the same worker for the same key to ensure per-key
    # synchronization at the db level. To do so, we use `:erlang.phash2/2` to
    # compute and normalize the key's hash within the range.
    worker_key = :erlang.phash2(key, @pool_size) + 1
    {:reply, worker_key, state}
  end

  defp ensure_db_folder() do
    xdg_data_home = System.get_env("XDG_DATA_HOME") || "~/.local/share"
    db_folder = Path.expand(Path.join(xdg_data_home, @folder_name))
    File.mkdir_p!(db_folder)

    db_folder
  end

  defp start_workers(db_folder) do
    for id <- 1..@pool_size do
      {:ok, _} = Todo.DatabaseWorker.start_link({db_folder, id})
    end
  end
end
