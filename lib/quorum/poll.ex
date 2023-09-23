defmodule Quorum.Poll do
  use GenServer

  alias Quorum.Message

  def vote(poll_id, %Message{} = vote) do
    poll_id
    |> Quorum.via()
    |> GenServer.call({:vote, vote})
  end

  def log(poll_id) do
    poll_id
    |> Quorum.via()
    |> GenServer.call(:log)
  end

  def start_link(poll_id) do
    GenServer.start_link(__MODULE__, poll_id, name: Quorum.via(poll_id))
  end

  @impl true
  def init(poll_id) do
    state = %{
      poll_id: poll_id,
      log: []
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:vote, vote}, _from, state) do
    {:reply, :ok, %{state | log: [vote | state.log]}}
  end

  @impl true
  def handle_call(:log, _from, state) do
    {:reply, state.log, state}
  end
end
