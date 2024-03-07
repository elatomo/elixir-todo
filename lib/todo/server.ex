defmodule Todo.Server do
  @moduledoc """
  To-do list server.

  Allows multiple clients to work on a single to-do list.

  ## Example

      iex> Todo.ProcessRegistry.start_link()
      iex> Todo.Database.start_link([])
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

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def update_entry(todo_server, %{} = new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
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
    {:noreply, {name, todo_list}}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_cast({:update_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    new_list = Todo.List.delete_entry(todo_list, entry_id)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {name, todo_list}}
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
