defmodule Quorum.Mailroom do
  use GenServer

  def send(%Quorum.Message{type: :create_poll} = message) do
    GenServer.call(Quorum.Mailroom, message)
  end

  def send(%Quorum.Message{type: type}) do
    {:error, "Unknown message type: #{type}"}
  end

  def send(message) do
    {:error, "Unknown message type", message}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    :ok = :net_kernel.monitor_nodes(true)
    {node_name, data_center} = Node.self() |> Quorum.parse_node()

    state = %{
      node: Node.self(),
      node_name: node_name,
      data_center: data_center
    }

    {:ok, state, {:continue, :sync_topology}}
  end

  @impl true
  def handle_continue(:sync_topology, state) do
    IO.puts("[#{state.node}]: Syncing topology...")
    Quorum.Topology.sync(Node.list())
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    IO.puts("[#{state.node}]: #{node} joined, syncing topology...")
    Quorum.Topology.sync(Node.list())
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    IO.puts("[#{state.node}]: #{node} left, syncing topology...")
    Quorum.Topology.sync(Node.list())
    {:noreply, state}
  end

  @impl true
  def handle_call(%Quorum.Message{type: :create_poll, data: _data} = message, _from, state) do
    node =
      message.data
      |> Quorum.Topology.get_actor_server()
      |> Quorum.to_node()

    if state.node == node do
      result = Quorum.PollSupervisor.call(message)
      {:reply, result, state}
    else
      result = GenServer.call({Quorum.Mailroom, node}, message)
      {:reply, result, state}
    end
  end

  @impl true
  def handle_call(message, _from, state) do
    IO.puts("unsupported message: #{inspect(message)}")
    {:reply, message, state}
  end
end
