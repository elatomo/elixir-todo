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
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    # Resolve and ensure the database folder
    xdg_data_home = System.get_env("XDG_DATA_HOME") || "~/.local/share"
    db_folder = Path.expand(Path.join(xdg_data_home, @folder_name))
    File.mkdir_p!(db_folder)

    # Init pool of workers
    workers =
      0..2
      |> Enum.map(fn x ->
        {:ok, worker} = Todo.DatabaseWorker.start(db_folder)
        {x, worker}
      end)
      |> Map.new()

    {:ok, %{db_folder: db_folder, workers: workers}}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    Todo.DatabaseWorker.store(choose_worker(state.workers, key), key, data)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    {:reply, Todo.DatabaseWorker.get(choose_worker(state.workers, key), key), state}
  end

  defp choose_worker(workers, key) do
    # Ensure we always choose the same worker for the same key to ensure per-key
    # synchronization at the database level. To do so, we use `:erlang.phash2/2`
    # to compute and normalize the key's hash within the range [0..2].
    workers[:erlang.phash2(key, 3)]
  end
end
