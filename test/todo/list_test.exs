defmodule Todo.ListTest do
  use ExUnit.Case
  doctest Todo.List

  test "creating with a list of entries" do
    entries = [
      %{date: ~D[2024-01-27], title: "Dentist"},
      %{date: ~D[2024-01-28], title: "Shopping"}
    ]

    assert Todo.List.new(entries) == %Todo.List{
             auto_id: 3,
             entries: %{
               1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
               2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"}
             }
           }
  end

  test "updating an entry requires a map" do
    catch_error(Todo.List.update_entry(Todo.List.new(), "Not a map"))
  end

  test "updating an entry should not allow modification of its ID" do
    todo_list =
      Todo.List.new()
      |> Todo.List.add_entry(%{date: ~D[2024-01-27], title: "Dentist"})

    catch_error(Todo.List.update_entry(todo_list, 1, &Map.put(&1, :id, 5)))
  end

  test "implements `Collectable` protocol" do
    entries = [
      %{date: ~D[2024-01-27], title: "Dentist"},
      %{date: ~D[2024-01-28], title: "Shopping"},
      %{date: ~D[2024-01-27], title: "Movies"}
    ]

    todo_list = Enum.into(entries, Todo.List.new(), & &1)

    assert todo_list.entries == %{
             1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
             2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"},
             3 => %{id: 3, date: ~D[2024-01-27], title: "Movies"}
           }
  end
end

defmodule TodoListCsvImporterTest do
  use ExUnit.Case

  test "importing from a CSV file" do
    todo_list = Todo.List.CsvImporter.import("#{__DIR__}/todos.csv")

    assert todo_list.entries == %{
             1 => %{id: 1, date: ~D[2024-01-27], title: "Dentist"},
             2 => %{id: 2, date: ~D[2024-01-28], title: "Shopping"},
             3 => %{id: 3, date: ~D[2024-01-27], title: "Movies"}
           }
  end
end
