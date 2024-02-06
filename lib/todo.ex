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
