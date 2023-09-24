defmodule Quorum do
  @moduledoc false

  def via(id), do: {:via, Registry, {Quorum.Registry, id}}

  @spec parse_node(atom) :: {String.t(), String.t()}
  def parse_node(node) do
    [data_center, availability_zone, node_number] =
      node |> Atom.to_string() |> String.split("@") |> Enum.at(0) |> String.split("_")

    data_center = String.upcase(data_center)
    node_name = "#{data_center}-#{String.upcase(availability_zone)}-#{String.upcase(node_number)}"
    {node_name, data_center}
  end

  @spec to_node(String.t()) :: atom()
  def to_node(node_name) do
    [data_center, availability_zone, node_number] = node_name |> String.split("-")

    "#{data_center}_#{availability_zone}_#{node_number}@localhost"
    |> String.downcase()
    |> String.to_atom()
  end

  @spec extract_data_center(String.t()) :: String.t()
  def extract_data_center(voting_center) do
    voting_center |> String.split("-") |> Enum.at(0)
  end

  def create_poll(vc, question \\ "", options \\ []) do
    Quorum.Mailroom.send(%Quorum.Message{
      type: :create_poll,
      data: %{id: random_id(), voting_center: vc, question: question, options: options}
    })
  end

  def random_id(length \\ 12) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64(padding: false)
  end
end
