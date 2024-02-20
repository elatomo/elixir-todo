defmodule Todo.Cache do
  @moduledoc """
  Todo list server cache.
  """

  use GenServer

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(cache, todo_list_name) do
    GenServer.call(cache, {:server_process, todo_list_name})
  end

  @impl GenServer
  def init(_) do
    # Ensure the database process is started
    Todo.Database.start()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Todo.Server.start(todo_list_name)
        {:reply, new_server, Map.put(todo_servers, todo_list_name, new_server)}
    end
  end
end
