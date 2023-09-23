defmodule Quorum.PollSupervisor do
  use DynamicSupervisor

  alias Quorum.Poll

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec add_poll(poll_id :: String.t()) ::
          :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def add_poll(poll_id) do
    child_spec = {Poll, poll_id}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @spec remove_poll(poll_id :: pid()) :: :ok | {:error, :not_found}
  def remove_poll(poll_id) do
    DynamicSupervisor.terminate_child(__MODULE__, poll_id)
  end

  def polls() do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_polls() do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
