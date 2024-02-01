defmodule TodoTest do
  use ExUnit.Case
  doctest TodoList

  test "updating an entry requires a map" do
    catch_error(TodoList.update_entry(TodoList.new(), "Not a map"))
  end

  test "updating an entry should not allow modification of its ID" do
    todo_list =
      TodoList.new()
      |> TodoList.add_entry(%{date: ~D[2024-01-27], title: "Dentist"})

    catch_error(TodoList.update_entry(todo_list, 1, &Map.put(&1, :id, 5)))
  end
end
