defmodule Quorum.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Quorum.Registry},
      {
        Cluster.Supervisor,
        [
          [quorum: [strategy: Cluster.Strategy.LocalEpmd]],
          [name: Quorum.ClusterSupervisor]
        ]
      },
      {Quorum.PollSupervisor, []},
      {Quorum.Topology, dcs: ["MI", "IN", "OH", "IL"]},
      {Quorum.Mailroom, []}
    ]

    opts = [strategy: :one_for_one, name: Quorum.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
