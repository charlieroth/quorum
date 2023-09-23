defmodule Quorum.Topology do
  use GenServer

  @type actor_server_lookup :: %{
          id: String.t(),
          voting_center: String.t()
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

  @spec get_actor_server(query :: actor_server_lookup()) :: String.t()
  def get_actor_server(%{id: id, voting_center: voting_center}) do
    GenServer.call(__MODULE__, {:get_actor_server, id, voting_center})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    dcs = Keyword.fetch!(args, :dcs)
    vc_dc_map = Keyword.fetch!(args, :vc_dc_map)
    dc_map = Enum.into(dcs, %{}, fn dc -> {dc, HashRing.new()} end)

    state = %{
      dcs: dcs,
      dc_map: dc_map,
      vc_dc_map: vc_dc_map
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:sync, nodes}, _from, state) do
    node_name_list = [Node.self() | nodes] |> Enum.map(&Quorum.parse_node/1)
    new_dc_map = Enum.into(state.dcs, %{}, fn dc -> {dc, HashRing.new()} end)

    new_dc_map =
      Enum.reduce(node_name_list, new_dc_map, fn {node_name, data_center}, acc ->
        Map.update!(acc, data_center, fn hr -> HashRing.add_node(hr, node_name) end)
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
  def handle_call({:get_actor_server, _id, _vc}, _from, state) do
    # TODO
    {:reply, state, state}
  end
end
