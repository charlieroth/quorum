defmodule Quorum.Mailroom do
  use GenServer

  require Logger

  alias Quorum.Topology

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
    nodes = Quorum.Topology.get_current() |> Quorum.get_replication_nodes(data.key)

    with true <- length(nodes) < 3,
         :ok <- Quorum.PollSupervisor.call(message) |> did_create_poll?(),
         :ok <- nodes |> replicate_poll(data) |> did_replicate_poll?() do
      local_actor_server = data.key |> Topology.get_actor_server()
      {:reply, {:ok, :replication_succeeded, [local_actor_server | nodes]}, state}
    else
      false ->
        {:reply, {:error, :replication_failed, "Not enough nodes to replicate to"}, state}

      {:error, reason} ->
        # TODO: Tear down "orphaned" Poll processes
        # if contains_failures do
        #   successful_replications = Enum.filter(replication_results, fn {:ok, _} -> true end)
        #   Enum.each(successful_replications, fn {:ok, poll_pid} ->
        #     key = GenServer.call(poll_pid, {:get_key})
        #     Quorum.PollSupervisor.call(%Quorum.Message{type: :remove_poll, data: %{key: key}})
        #   end)
        # else
        #   {:reply, {:ok, replication_results}, state}
        # end
        Logger.error("Failed to replicate poll: #{inspect(reason)}")
        {:reply, {:error, :replication_failed, reason}, state}
    end
  end

  @impl true
  def handle_call(%Quorum.Message{type: :replicate_poll, data: data} = _message, _from, state) do
    creation_result = Quorum.PollSupervisor.call(%Quorum.Message{type: :create_poll, data: data})
    {:reply, creation_result, state}
  end

  @impl true
  def handle_call(message, _from, state) do
    IO.puts("unsupported message: #{inspect(message)}")
    {:reply, message, state}
  end

  defp replicate_poll(nodes, data) do
    Enum.map(nodes, fn node ->
      GenServer.call({Quorum.Mailroom, node}, %Quorum.Message{type: :replicate_poll, data: data})
    end)
  end

  defp did_create_poll?({:ok, _poll_pid}), do: :ok
  defp did_create_poll?({:error, _}), do: {:error, :creation_failed}
  defp did_create_poll?(_), do: {:error, :creation_failed}

  defp did_replicate_poll?(replication_results) do
    if Enum.any?(replication_results, fn
         {:error, _} -> true
         {:ok, _} -> false
       end) do
      {:error, :replication_failed}
    else
      :ok
    end
  end
end
