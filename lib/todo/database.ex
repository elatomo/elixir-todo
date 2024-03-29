defmodule Todo.Database do
  @moduledoc """
  Simple disk-based database, encoding data into the Erlang external term
  format.

  Manages a pool of workers to handle database requests.

  ## Example

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

  require Logger

  @pool_size 3

  def child_spec(_) do
    Logger.debug("Starting to-do database")
    db_folder = ensure_db_folder()

    :poolboy.child_spec(
      __MODULE__,
      # Pool configuration
      [
        name: {:local, __MODULE__},
        worker_module: Todo.DatabaseWorker,
        size: @pool_size
      ],
      # Worker arguments
      [db_folder]
    )
  end

  def store(key, data) do
    {_results, bad_nodes} =
      :rpc.multicall(__MODULE__, :store_local, [key, data], :timer.seconds(5))

    Enum.each(bad_nodes, &Logger.error("Store failed on node #{&1}"))
  end

  def store_local(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end

  defp ensure_db_folder() do
    # Node name is used to determine the database folder
    [name_prefix, _] = "#{node()}" |> String.split("@")
    db_folder = Application.get_env(:todo, :db_folder) |> Path.join(name_prefix)
    File.mkdir_p!(db_folder)

    db_folder
  end
end
