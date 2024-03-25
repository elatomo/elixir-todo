defmodule Todo.Cache do
  @moduledoc """
  To-do list server cache.

  Maintains a collection of to-do servers and is responsible for their creation
  and discovery.
  """

  use DynamicSupervisor
  require Logger

  def start_link(_) do
    Logger.debug("Starting to-do cache")
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(todo_list_name) do
    Todo.Server.whereis(todo_list_name) || new_process(todo_list_name)
  end

  defp new_process(todo_list_name) do
    case start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_child(todo_list_name) do
    DynamicSupervisor.start_child(__MODULE__, {Todo.Server, todo_list_name})
  end
end
