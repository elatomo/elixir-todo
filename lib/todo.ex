defmodule TodoServer do
  @moduledoc """
  Todo list server.

  ## Example

  iex> todo_server = TodoServer.start()
  iex> TodoServer.add_entry(todo_server, %{date: ~D[2024-01-27], title: "Dentist"})
  iex> TodoServer.add_entry(todo_server, %{date: ~D[2024-01-28], title: "Shopping"})
  iex> TodoServer.add_entry(todo_server, %{date: ~D[2024-01-27], title: "Movies"})
  iex> TodoServer.entries(todo_server, ~D[2024-01-27])
  [
  %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
  %{id: 3, date: ~D[2024-01-27], title: "Movies"}
  ]
  iex> TodoServer.update_entry(todo_server, %{id: 1, date: ~D[2024-01-27], title: "Dentist!"})
  iex> TodoServer.delete_entry(todo_server, 3)
  iex> TodoServer.entries(todo_server, ~D[2024-01-27])
  [
  %{id: 1, date: ~D[2024-01-27], title: "Dentist!"},
  ]

  """

  def init do
    TodoList.new()
  end

  def start do
    ServerProcess.start(TodoServer)
  end

  def add_entry(todo_server, new_entry) do
    ServerProcess.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    ServerProcess.call(todo_server, {:entries, date})
  end

  def update_entry(todo_server, %{} = new_entry) do
    ServerProcess.cast(todo_server, {:update_entry, new_entry})
  end

  def delete_entry(todo_server, entry_id) do
    ServerProcess.cast(todo_server, {:delete_entry, entry_id})
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, new_entry}, todo_list) do
    TodoList.update_entry(todo_list, new_entry)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  def handle_call({:entries, date}, todo_list) do
    {TodoList.entries(todo_list, date), todo_list}
  end
end

defmodule ServerProcess do
  @moduledoc """
  Custom implementation of a generic server process.
  """
  require Logger

  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, current_state)
        loop(callback_module, new_state)

      unknown_message ->
        Logger.error("Received unknown message: #{inspect(unknown_message)}")
        loop(callback_module, current_state)
    end
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} -> response
    after
      5000 -> {:error, :timeout}
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end
end

defmodule TodoList do
  @moduledoc """
  Todo list implementation.

  ## Example

  iex> todo_list = TodoList.new() |>
  ...>   TodoList.add_entry(%{date: ~D[2024-01-27], title: "Dentist"}) |>
  ...>   TodoList.add_entry(%{date: ~D[2024-01-28], title: "Shopping"}) |>
  ...>   TodoList.add_entry(%{date: ~D[2024-01-27], title: "Movies"})
  iex> TodoList.entries(todo_list, ~D[2024-01-27])
  [
    %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
    %{id: 3, date: ~D[2024-01-27], title: "Movies"}
  ]
  iex> TodoList.entries(todo_list, ~D[2024-01-29])
  []
  iex> TodoList.update_entry(todo_list, %{id: 1, date: ~D[2024-01-27], title: "Dentist!"})
  %TodoList{
    auto_id: 4,
    entries: %{
      1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist!"},
      2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"},
      3 => %{id: 3, date: ~D[2024-01-27], title: "Movies"}
    }
  }
  iex> TodoList.delete_entry(todo_list, 1)
  %TodoList{
    auto_id: 4,
    entries: %{
      2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"},
      3 => %{id: 3, date: ~D[2024-01-27], title: "Movies"}
    }
  }

  """

  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      fn entry, todo_list_acc ->
        add_entry(todo_list_acc, entry)
      end
    )
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)
    %TodoList{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.map(fn {_, entry} -> entry end)
    |> Enum.filter(fn entry -> entry.date == date end)
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(todo_list, entry_id, update_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        # Returns the unchanged list
        todo_list

      {:ok, old_entry} ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = update_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, entry_id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    %TodoList{todo_list | entries: Map.delete(todo_list.entries, entry_id)}
  end
end

defmodule TodoList.CsvImporter do
  def import(file_path) do
    File.stream!(file_path)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Stream.map(&String.split(&1, ","))
    |> Stream.map(fn [date_string, title] ->
      %{
        date: Date.from_iso8601!(date_string),
        title: title
      }
    end)
    |> TodoList.new()
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end
