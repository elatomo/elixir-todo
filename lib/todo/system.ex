defmodule Todo.System do
  @moduledoc """
  To-do system supervisor.
  """

  def start_link do
    Supervisor.start_link([Todo.Cache], strategy: :one_for_one)
  end
end
