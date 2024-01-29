defmodule TodoList do
  @moduledoc """
  Todo list implementation.

  ## Example

  iex> todo_list = TodoList.new() |>
  ...>   TodoList.add_entry(~D[2024-01-27], "Dentist") |>
  ...>   TodoList.add_entry(~D[2024-01-28], "Shopping") |>
  ...>   TodoList.add_entry(~D[2024-01-27], "Movies")
  iex> TodoList.entries(todo_list, ~D[2024-01-27])
  ["Movies", "Dentist"]
  iex> TodoList.entries(todo_list, ~D[2024-01-29])
  []

  """
  def new(), do: MultiDict.new()

  def add_entry(todo_list, date, title) do
    MultiDict.add(todo_list, date, title)
  end

  def entries(todo_list, date) do
    MultiDict.get(todo_list, date)
  end
end

defmodule MultiDict do
  def new(), do: %{}

  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Map.get(dict, key, [])
  end
end
