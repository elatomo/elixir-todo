defmodule TodoList do
  @moduledoc """
  Todo list implementation.

  ## Example

  iex> todo_list = TodoList.new() |>
  ...>   TodoList.add_entry(%{date: ~D[2024-01-27], title: "Dentist"}) |>
  ...>   TodoList.add_entry(%{date: ~D[2024-01-28], title: "Shopping"}) |>
  ...>   TodoList.add_entry(%{date: ~D[2024-01-27], title: "Movies"})
  iex> TodoList.entries(todo_list, ~D[2024-01-27])
  [%{id: 1, date: ~D[2024-01-27], title: "Dentist"}, %{id: 3, date: ~D[2024-01-27], title: "Movies"}]
  iex> TodoList.entries(todo_list, ~D[2024-01-29])
  []

  """

  defstruct auto_id: 1, entries: %{}

  def new(), do: %TodoList{}

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
end
