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
    node = Node.self()
    node_name = node |> Quorum.to_quorum_node_name()
    [data_center, _, _] = node_name |> Quorum.split_quorum_node_name()

    state = %{
      node: node,
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
  def handle_call(%Quorum.Message{type: :create_poll, data: data} = message, _from, state) do
    nodes_in_other_availability_zone = state.node |> Quorum.nodes_in_other_availability_zone()

    # Can only create primary poll if there are nodes in other availability zone
    if not Enum.empty?(nodes_in_other_availability_zone) do
      # 1. Create poll in current node
      {:ok, poll_pid} = Quorum.PollSupervisor.call(message)
      # 2. Create same poll in same data center, different availability zone
      node = Enum.random(nodes_in_other_availability_zone)

      {:ok, poll_in_other_az_pid} =
        GenServer.call({Quorum.Mailroom, node}, %Quorum.Message{type: :replicate_poll, data: data})

      {:reply, [poll_pid, poll_in_other_az_pid], state}
    else
      {:reply, {:error, :replication_failed, "No nodes in other availability zone"}, state}
    end
  end

  @impl true
  def handle_call(%Quorum.Message{type: :replicate_poll, data: data} = _message, _from, state) do
    {:ok, poll_pid} = Quorum.PollSupervisor.call(%Quorum.Message{type: :create_poll, data: data})
    {:reply, {:ok, poll_pid}, state}
  end

  @impl true
  def handle_call(message, _from, state) do
    IO.puts("unsupported message: #{inspect(message)}")
    {:reply, message, state}
  end
end
