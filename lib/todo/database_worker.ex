defmodule Todo.DatabaseWorker do
  @moduledoc """
  Database worker.

  Performs read/write operations on the database.
  """

  use GenServer
  require Logger

  def start_link(db_folder) do
    GenServer.start_link(__MODULE__, db_folder)
  end

  def store(worker_id, key, data) do
    GenServer.call(worker_id, {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(worker_id, {:get, key})
  end

  @impl GenServer
  def init(db_folder) do
    Logger.debug("Starting to-do database worker")
    {:ok, db_folder}
  end

  @impl GenServer
  def handle_call({:store, key, data}, _, db_folder) do
    db_folder
    |> file_name(key)
    |> File.write!(:erlang.term_to_binary(data))

    {:reply, :ok, db_folder}
  end

  @impl GenServer
  def handle_call({:get, key}, _, db_folder) do
    data =
      case File.read(file_name(db_folder, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, db_folder}
  end

  defp file_name(db_folder, key) do
    Path.join(db_folder, to_string(key))
  end
end
