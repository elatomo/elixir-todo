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
  def new(), do: %{}

  def add_entry(todo_list, date, title) do
    Map.update(
      todo_list,
      date,
      [title],
      fn titles -> [title | titles] end
    )
  end

  def entries(todo_list, date) do
    Map.get(todo_list, date, [])
  end
end
