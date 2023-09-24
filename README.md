# Quorum

`Quorum` is an experiment in building a distributed system whose
functionality serves the purpose as a backing network for a voting system
for elections in the United States at all levels of government.

`Quorum` is built with Elixir and the BEAM VM; designed for scalability,
fault-tolerance and distribution.

## Motivations and Philosophy

It is my long held belief that the software system used for elections in
the United States should be built in the public domain, distributed,
fault-tolerant and should impose a system of accountability between
neighboring cities, states to both reveal and protect from bad actors.

On the surface, `Quorum` aims to provide a real-time voting system
that third-parties and/or citizens can integrate with. This would allow
anyone to view the results of an election in real-time and verify the
final result.

Under the hood, `Quorum` is a distributed system whose compute and storage
is geographically distributed. This ensures that if an asteriod hits a data
center while an election is on-going or finished the results of an election
are stored on more than one data center and the election can continue without
any down time.

Ideally each state has multiple data centers, each capable of running multiple
`Quorum` nodes. With some additional work, there could be a possibility for
citizens to run a node and participate in upholding the results of an
election; this would most likely be a read-only node due to various security
concerns. By each state running multiple `Quorum` nodes, they now have a shared
responsibility for the technical integrity of their states and/or their
countrys election results. This is a forcing function for all governments in
United States to become technically competent about their voting systems;
not just a few private actors that may or may not be publically searchable.
