defmodule Todo.Database do
  @moduledoc """
  Simple disk-based database.

  Uses disk-based persistence, encoding data into the Erlang external term
  format.

  ## Example

      iex> Todo.Database.start()
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

  @folder_name "elixir-todo"

  def start do
    # Start the server and register the process locally
    GenServer.start(__MODULE__, nil, name: __MODULE__)
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
    db_folder = ensure_db_folder()
    {:ok, start_workers(db_folder)}
  end

  @impl GenServer
  def handle_call({:choose_worker, key}, _, workers) do
    # Ensure we always choose the same worker for the same key to ensure per-key
    # synchronization at the db level. To do so, we use `:erlang.phash2/2` to
    # compute and normalize the key's hash within the range [0..2].
    worker_key = :erlang.phash2(key, 3)
    {:reply, workers[worker_key], workers}
  end

  defp ensure_db_folder() do
    xdg_data_home = System.get_env("XDG_DATA_HOME") || "~/.local/share"
    db_folder = Path.expand(Path.join(xdg_data_home, @folder_name))
    File.mkdir_p!(db_folder)

    db_folder
  end

  defp start_workers(db_folder) do
    for index <- 0..2, into: %{} do
      {:ok, pid} = Todo.DatabaseWorker.start(db_folder)
      {index, pid}
    end
  end
end
