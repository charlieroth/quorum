defmodule Quorum do
  @moduledoc false

  def create_poll(vc, question \\ "", options \\ []) do
    Quorum.Mailroom.send(%Quorum.Message{
      type: :create_poll,
      data: %{
        key: %{id: random_id(), vc: vc},
        question: question,
        options: options
      }
    })
  end

  @spec random_id(len :: integer()) :: String.t()
  def random_id(len \\ 12) do
    :crypto.strong_rand_bytes(len) |> Base.url_encode64(padding: false)
  end

  def via(id) do
    IO.inspect(id, label: "via received id")
    {:via, Registry, {Quorum.Registry, id}}
  end

  @doc """
  Returns a list of node where the Poll will be or are replicated at
  that are not in the same data center as the primary replica.
  """
  @spec get_replication_nodes(topology :: map(), key :: %{id: String.t(), vc: String.t()}) :: [
          atom()
        ]
  def get_replication_nodes(topology, %{id: id, vc: vc} = _key) do
    [primary_dc, _, _] = Quorum.split_vc(vc)

    topology
    |> Enum.filter(fn {dc, _dc_hr} -> dc != primary_dc end)
    |> Enum.map(fn {_dc, dc_hr} ->
      case HashRing.key_to_node(dc_hr, {id, vc}) do
        {:error, {:invalid_ring, :no_nodes}} ->
          nil

        node ->
          node |> Quorum.to_erlang_node_name()
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end

  def split_vc(vc) when is_binary(vc) do
    vc |> String.split("-")
  end

  @spec nodes_in_other_availability_zone(node :: atom()) :: [atom()]
  def nodes_in_other_availability_zone(node) when is_atom(node) do
    [dc, az, _num] = node |> Quorum.split_erlang_node_name() |> Enum.map(&String.upcase/1)

    dc
    |> Quorum.Topology.get_dc_hash_ring()
    |> HashRing.nodes()
    |> Enum.map(&split_quorum_node_name/1)
    |> Enum.filter(fn [_, node_az, _] -> node_az != az end)
    |> Enum.map(&Enum.join(&1, "-"))
    |> Enum.map(&to_erlang_node_name/1)
  end

  @spec to_quorum_node_name(node :: atom()) :: String.t()
  def to_quorum_node_name(node) when is_atom(node) do
    node
    |> split_erlang_node_name()
    |> Enum.map(&String.upcase/1)
    |> Enum.join("-")
  end

  @spec split_erlang_node_name(node :: atom()) :: [String.t()]
  def split_erlang_node_name(node) when is_atom(node) do
    node |> Atom.to_string() |> String.split("@") |> Enum.at(0) |> String.split("_")
  end

  @spec to_erlang_node_name(String.t()) :: atom()
  def to_erlang_node_name(node) when is_binary(node) do
    [dc, az, num] =
      node
      |> split_quorum_node_name()
      |> Enum.map(&String.downcase/1)

    "#{dc}_#{az}_#{num}@localhost" |> String.to_atom()
  end

  @spec split_quorum_node_name(node :: String.t()) :: [String.t()]
  def split_quorum_node_name(node) when is_binary(node) do
    node |> String.split("-")
  end
end
