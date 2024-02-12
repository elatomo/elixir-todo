defmodule Todo.Server do
  @moduledoc """
  Todo list server.

  ## Example

  iex> {:ok, todo_server} = Todo.Server.start()
  iex> Todo.Server.add_entry(todo_server, %{date: ~D[2024-01-27], title: "Dentist"})
  iex> Todo.Server.add_entry(todo_server, %{date: ~D[2024-01-28], title: "Shopping"})
  iex> Todo.Server.add_entry(todo_server, %{date: ~D[2024-01-27], title: "Movies"})
  iex> Todo.Server.entries(todo_server, ~D[2024-01-27])
  [
    %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
    %{id: 3, date: ~D[2024-01-27], title: "Movies"}
  ]
  iex> Todo.Server.update_entry(todo_server, %{id: 1, date: ~D[2024-01-27], title: "Dentist!"})
  iex> Todo.Server.delete_entry(todo_server, 3)
  iex> Todo.Server.entries(todo_server, ~D[2024-01-27])
  [
    %{id: 1, date: ~D[2024-01-27], title: "Dentist!"},
  ]

  """
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil)
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
  def init(_) do
    {:ok, Todo.List.new()}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, todo_list) do
    {:noreply, Todo.List.add_entry(todo_list, new_entry)}
  end

  @impl GenServer
  def handle_cast({:update_entry, new_entry}, todo_list) do
    {:noreply, Todo.List.update_entry(todo_list, new_entry)}
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, todo_list) do
    {:noreply, Todo.List.delete_entry(todo_list, entry_id)}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, todo_list) do
    {:reply, Todo.List.entries(todo_list, date), todo_list}
  end
end
