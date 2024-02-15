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

    {:ok, %{db_folder: db_folder}}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    state.db_folder
    |> file_name(key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    data =
      case File.read(file_name(state.db_folder, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, state}
  end

  defp file_name(db_folder, key) do
    Path.join(db_folder, to_string(key))
  end
end
