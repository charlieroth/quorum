# Quorum

`Quorum` is an experiment in building a distributed system whose
functionality serves the purpose as a backing network for a voting system
for government elections.

`Quorum` is built with Elixir on the BEAM; designed for scalability,
fault-tolerance and distribution.

The architecture of the `Quorum` system is heavily influenced by the
[Waterpark Project](https://www.youtube.com/watch?v=pQ0CvjAJXz4). The
Waterpark Project is an incredibly inspiring implementation of a
distributed system that serviced hospitals and people all over the
United States in what is likely the biggest stress test on the
United States medical infrastructure has ever faced. This was all
done with Elixir and zero down-time, proving that distributed systems
can and should be built to service some of the most critical
information exchange systems for a large group of people.

## Motivations and Philosophy

It is my long held belief that the software system used for elections
should be built in the public domain, distributed, fault-tolerant and
should impose a system of accountability between neighboring cities,
states to both reveal and protect from bad actors.

On the surface, `Quorum` aims to provide a real-time voting system
that third-parties and/or private citizens can integrate with. This
would allow anyone to view the results of an election in real-time
and verify the final result.

Under the hood, `Quorum` is a distributed system whose compute and storage
is geographically distributed. This ensures that if an asteriod hits a data
center while an election is on-going or already finished, the results of an
election are not compromised.

Ideally each living district has multiple data centers, each capable of
running multiple `Quorum` nodes. With some additional work, there could
be a possibility for citizens to run a node and participate in upholding
the results of an election; this would most likely be a read-only node
due to various security concerns. By each state running multiple `Quorum`
nodes, they now have a shared responsibility for the technical integrity
of their states and/or their country's election results. This is a forcing
function for all governments in these living districts to become technically
competent about their voting systems; not just a few private actors that
may or may not be publically knowable.
