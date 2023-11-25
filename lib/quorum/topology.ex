defmodule Quorum.Topology do
  use GenServer

  @type actor_server_key :: %{
          id: String.t(),
          vc: String.t()
        }

  @spec state() :: map()
  def state do
    GenServer.call(__MODULE__, :state)
  end

  @spec sync(nodes :: [node()]) :: map()
  def sync(nodes) do
    GenServer.call(__MODULE__, {:sync, nodes})
  end

  @spec get_dcs() :: [String.t()]
  def get_dcs do
    GenServer.call(__MODULE__, :get_dcs)
  end

  @spec get_dc_hash_ring(dc :: String.t()) :: HashRing.t()
  def get_dc_hash_ring(dc) do
    GenServer.call(__MODULE__, {:get_dc_hash_ring, dc})
  end

  @spec get_current() :: map()
  def get_current do
    GenServer.call(__MODULE__, :get_current)
  end

  @spec get_actor_server(key :: actor_server_key()) :: atom()
  def get_actor_server(%{id: id, vc: vc}) do
    GenServer.call(__MODULE__, {:get_actor_server, id, vc})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    dcs = Keyword.fetch!(args, :dcs)
    dc_map = Enum.into(dcs, %{}, fn dc -> {dc, HashRing.new()} end)
    state = %{dcs: dcs, dc_map: dc_map}
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:sync, nodes}, _from, state) do
    new_dc_map = Enum.into(state.dcs, %{}, fn dc -> {dc, HashRing.new()} end)

    new_dc_map =
      [Node.self() | nodes]
      |> Enum.map(&Quorum.to_quorum_node_name/1)
      |> Enum.reduce(new_dc_map, fn quorum_node_name, acc ->
        [dc, _, _] = quorum_node_name |> Quorum.split_quorum_node_name()
        Map.update!(acc, dc, &HashRing.add_node(&1, quorum_node_name))
      end)

    state = %{state | dc_map: new_dc_map}
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_dcs, _from, state) do
    {:reply, Map.get(state, :dcs), state}
  end

  @impl true
  def handle_call({:get_dc_hash_ring, dc}, _from, state) do
    {:reply, Map.get(state.dc_map, dc), state}
  end

  @impl true
  def handle_call(:get_current, _from, state) do
    {:reply, state.dc_map, state}
  end

  @impl true
  def handle_call({:get_actor_server, id, vc}, _from, state) do
    [dc, _, _] = vc |> Quorum.split_vc()
    dc_hash_ring = Map.get(state.dc_map, dc)
    dc_hash_ring_node = dc_hash_ring |> HashRing.key_to_node({id, vc})
    erlang_node_name = dc_hash_ring_node |> Quorum.to_erlang_node_name()

    {:reply, erlang_node_name, state}
  end
end
