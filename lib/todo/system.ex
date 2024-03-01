defmodule Todo.System do
  @moduledoc """
  To-do system supervisor.
  """

  use Supervisor

  def start_link do
    # Starts the supervisor with `Todo.System` as the callback module
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    # Impements the required callback function
    Supervisor.init([Todo.Database, Todo.Cache], strategy: :one_for_one)
  end
end