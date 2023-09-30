defmodule Quorum do
  @moduledoc false

  def create_poll(vc, question \\ "", options \\ []) do
    Quorum.Mailroom.send(%Quorum.Message{
      type: :create_poll,
      data: %{id: random_id(), voting_center: vc, question: question, options: options}
    })
  end

  def random_id(length \\ 12) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64(padding: false)
  end

  def via(id), do: {:via, Registry, {Quorum.Registry, id}}

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
