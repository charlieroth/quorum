defmodule Quorum.PollSupervisor do
  use DynamicSupervisor

  def call(%Quorum.Message{type: :create_poll} = message) do
    child_spec = {Quorum.Poll, message}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def call(%Quorum.Message{type: :remove_poll, data: %{key: %{id: id}}}) do
    DynamicSupervisor.terminate_child(__MODULE__, id)
  end

  def call(message) do
    IO.puts("[#{Node.self()}][PollSupervisor]: unknown message, #{inspect(message)}")
    :noop
  end

  def polls() do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_polls() do
    DynamicSupervisor.count_children(__MODULE__)
  end

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
