defmodule Quorum.Poll do
  use GenServer

  @enforce_keys [:key, :projections, :log]
  defstruct [:key, :projections, :log]

  def start_link(%Quorum.Message{type: :create_poll, data: data} = message) do
    GenServer.start_link(__MODULE__, message, name: Quorum.via(data.id))
  end

  @impl true
  def init(%Quorum.Message{type: :create_poll, data: data} = message) do
    {:ok,
     %Quorum.Poll{
       key: %{
         id: data.id,
         voting_center: data.voting_center
       },
       projections: %{},
       log: [message]
     }}
  end

  @impl true
  def handle_call(%Quorum.Message{type: :vote, data: _data} = message, _from, state) do
    {:reply, :ok, %Quorum.Poll{state | log: [message | state.log]}}
  end

  @impl true
  def handle_call(%Quorum.Message{type: :log}, _from, state) do
    {:reply, state.log, state}
  end

  @impl true
  def handle_call(message, _from, state) do
    IO.puts("[#{Node.self()}][Poll]: unknown message, #{inspect(message)}")
    {:reply, :noop, state}
  end
end
