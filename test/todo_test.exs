defmodule TodoListTest do
  use ExUnit.Case
  doctest TodoList

  test "creating with a list of entries" do
    entries = [
      %{date: ~D[2024-01-27], title: "Dentist"},
      %{date: ~D[2024-01-28], title: "Shopping"}
    ]

    assert TodoList.new(entries) == %TodoList{
             auto_id: 3,
             entries: %{
               1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
               2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"}
             }
           }
  end

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

defmodule TodoList.CsvImporterTest do
  use ExUnit.Case

  test "importing from a CSV file" do
    todo_list = TodoList.CsvImporter.import("#{__DIR__}/todos.csv")

    assert todo_list.entries == %{
             1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
             2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"},
             3 => %{id: 3, date: ~D[2024-01-27], title: "Movies"}
           }
  end
end
