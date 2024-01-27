defmodule TodoTest do
  use ExUnit.Case

  test "creating a new Todo list initializes an empty map" do
    assert TodoList.new() == %{}
  end

  test "adding an entry to an empty Todo list" do
    date = ~D[2024-01-27]
    todo_list = TodoList.new()
    assert TodoList.add_entry(todo_list, date, "Hello world!") == %{date => ["Hello world!"]}
  end

  test "prepending an entry to existing date entries" do
    date = ~D[2024-01-27]
    todo_list = TodoList.new()
    todo_list = TodoList.add_entry(todo_list, date, "Hello world!")

    assert TodoList.add_entry(todo_list, date, "Another task") == %{
             date => ["Another task", "Hello world!"]
           }
  end

  test "retrieving titles for an existing date" do
    date = ~D[2024-01-27]
    todo_list = TodoList.add_entry(%{}, date, "Hello world!")
    assert TodoList.entries(todo_list, date) == ["Hello world!"]
  end

  test "retrieving titles for non-existing date returns an empty list" do
    assert TodoList.entries(%{}, ~D[2024-01-27]) == []
  end
end
