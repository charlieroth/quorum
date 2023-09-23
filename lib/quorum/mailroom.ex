defmodule Quorum.Mailroom do
  use GenServer

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
end
