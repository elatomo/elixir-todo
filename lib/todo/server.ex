defmodule Todo.Server do
  @moduledoc """
  To-do list server.

  Allows multiple clients to work on a single to-do list.

  ## Example

      iex> {:ok, server} = Todo.Server.start_link("My list")
      iex> Todo.Server.add_entry(server, %{date: ~D[2024-01-27], title: "Dentist"})
      iex> Todo.Server.add_entry(server, %{date: ~D[2024-01-28], title: "Shopping"})
      iex> Todo.Server.add_entry(server, %{date: ~D[2024-01-27], title: "Movies"})
      iex> Todo.Server.entries(server, ~D[2024-01-27])
      [
        %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
        %{id: 3, date: ~D[2024-01-27], title: "Movies"}
      ]
      iex> Todo.Server.update_entry(server, %{id: 1, date: ~D[2024-01-27], title: "Dentist!"})
      iex> Todo.Server.delete_entry(server, 3)
      iex> Todo.Server.entries(server, ~D[2024-01-27])
      [
        %{id: 1, date: ~D[2024-01-27], title: "Dentist!"},
      ]

  """
  use GenServer, restart: :temporary
  require Logger

  @expiry_idle_timeout :timer.seconds(30)

  def start_link(name) do
    # NOTE: Global registration is chatty and serialized (only one process at a
    # time may perform global registration). This approach becomes problematic
    # with increasing numbers of to-do lists or nodes in the cluster. We could
    # consider looking at third-party libraries, such as Syn or Swarm.
    GenServer.start_link(__MODULE__, name, name: global_name(name))
  end

  def add_entry(todo_server, new_entry) do
    GenServer.call(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def update_entry(todo_server, %{} = new_entry) do
    GenServer.call(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.call(todo_server, {:delete_entry, entry_id})
  end

  def whereis(name) do
    # `:global.whereis_name/1` provides good and stable performance by doing a
    # single lookup in a local ETS table without any cross-node communication.
    case :global.whereis_name({__MODULE__, name}) do
      :undefined -> nil
      pid -> pid
    end
  end

  @impl GenServer
  def init(name) do
    Logger.debug("Starting to-do server '#{name}'")
    # Prevent long-running initialization by resolving the database in a
    # `handle_continue/2` callback, which will be invoked immediately after
    # entering the loop.
    {:ok, {name, nil}, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    {:noreply, {name, todo_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:add_entry, new_entry}, _, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:reply, :ok, {name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:update_entry, new_entry}, _, {name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:reply, :ok, {name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:delete_entry, entry_id}, _, {name, todo_list}) do
    new_list = Todo.List.delete_entry(todo_list, entry_id)
    Todo.Database.store(name, new_list)
    {:reply, :ok, {name, new_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {name, todo_list}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    Logger.debug("Stopping to-do server '#{name}'")
    {:stop, :normal, {name, todo_list}}
  end

  defp global_name(name) do
    {:global, {__MODULE__, name}}
  end
end
