defmodule Todo.ProcessRegistry do
  @moduledoc """
  To-do list process registry.
  """

  require Logger

  def start_link do
    Logger.debug("Starting process registry")
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    # Use child spec from `Registry` with the `:id` and `:start` fields modified
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
