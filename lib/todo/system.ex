defmodule Todo.System do
  @moduledoc """
  To-do system supervisor.
  """

  use Supervisor

  def start_link do
    # Starts the supervisor with `Todo.System` as the callback module
    Supervisor.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    # Implements the required callback function
    Supervisor.init(
      [Todo.Database, Todo.Cache, Todo.Web],
      strategy: :one_for_one
    )
  end
end
