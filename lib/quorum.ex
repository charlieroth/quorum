defmodule Quorum do
  @moduledoc false

  alias Quorum.{PollSupervisor, Message, Mailroom}

  def add_node(node_name, dc) do
    GenServer.multi_call(Mailroom, {:add_node, node_name, dc})
  end

  @spec add_poll(poll_id :: String.t()) ::
          :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def add_poll(poll_id), do: PollSupervisor.add_poll(poll_id)

  @spec remove_poll(poll_id :: pid()) :: :ok | {:error, :not_found}
  def remove_poll(poll_id), do: PollSupervisor.remove_poll(poll_id)

  def vote(poll_pid, %Message{} = message) do
    GenServer.call(poll_pid, {:vote, message})
  end

  def via(id), do: {:via, Registry, {Quorum.Registry, id}}

  @spec parse_node(atom) :: {String.t(), String.t()}
  def parse_node(node) do
    [data_center, availability_zone, node_number] =
      node |> Atom.to_string() |> String.split("@") |> Enum.at(0) |> String.split("_")

    data_center = String.upcase(data_center)
    node_name = "#{data_center}-#{String.upcase(availability_zone)}-#{String.upcase(node_number)}"
    {node_name, data_center}
  end
end
