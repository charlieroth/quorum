# Waterpark Project Nodes

[Link](https://www.youtube.com/watch?v=pQ0CvjAJXz4)

## Introduction

Data comes in

Data can be routed through the system and out to another system unchanged or
data can be transformed from one format to another. More data can be generated
from the activity inside Waterpark which can also be routed out to another 
system.

All together, Waterpark is a integration enginer, streaming system, distributed
database, content delivery network, FaaS platform, complex event processor,
queue and cache.

## High Level

4 Data Centers; FL, TN, TX and UT. Each with 8 Nodes.

2 availability zones A and B.

Therefore, 8 Nodes per data center.

Labeled A1, A2, A3, A4, B1, B2, B3, B4.

```bash
-------------------------------------------------------------------------------------
Florida   || FL-A-1 | FL-A-2 | FL-A-3 | FL-A-4 | FL-B-1 | FL-B-2 | FL-B-3 | FL-B-4 ||
-------------------------------------------------------------------------------------
Tennessee || TN-A-1 | TN-A-2 | TN-A-3 | TN-A-4 | TN-B-1 | TN-B-2 | TN-B-3 | TN-B-4 ||
-------------------------------------------------------------------------------------
Texas     || TX-A-1 | TX-A-2 | TX-A-3 | TX-A-4 | TX-B-1 | TX-B-2 | TX-B-3 | TX-B-4 ||
-------------------------------------------------------------------------------------
Utah      || UT-A-1 | UT-A-2 | UT-A-3 | UT-A-4 | UT-B-1 | UT-B-2 | UT-B-3 | UT-B-4 ||
-------------------------------------------------------------------------------------
```

Every Process is a Patient Actor, which is:

- Worker
- Storage
- All are peers, no master
- Only difference is the node name

## Process Pairs

Idea from Tandem computers that was baked into the Erlang language. This lead
to the idea of process linking and supervision trees.

### Creation of a Process Pair

Process spins up in data center in `FL-A-1`; this is the writer replica.

A read-replica Process is spun up `FL-B-1`.

3 more read-replicas Processes are spun up in the other data centers; `TN-A-1`, `TX-B-2`, `UT-A-1`.

Total of 5 Processes representing a Patient Actor in the cluster. Meaning their will
be 5 copies of every message we receive for a given Patient Actor.

Before "acking" a client message, the system must gaurentee that the message was
written to 3 of the 5 replicas; the writer and 2 of the read-replicas. This
gaurentees that the message is written to at least 2 data centers.

If a writer Process goes down, it is restarted and state is restored from the
nearest best read-replica.

## Server HashRings

How do we know where these processes live? `HashRing`.

[bitwalker/libring](https://github.com/bitwalker/libring)

A Data Center is represented by a `HashRing`

```elixir
iex> hr = HashRing.new() |> HashRing.add_nodes([
  "FL-A-1", "FL-A-2", "FL-A-3", "FL-A-4",
  "FL-B-1", "FL-B-2", "FL-B-3", "FL-B-4"
])
```

A Patient Actor process is assigned to a node in the `HashRing`

```elixir
iex> hr |> HashRing.key_to_node("actor-key-1001")
"FL-B-3"
```

This means that key `"actor-key-1001"` will always map to `"s7"` unless the
number of nodes in the `HashRing` changes

## Topology

```elixir
iex> Topology.get_dcs()
["FL", "TN", "TX", "UT"]
```

```elixir
iex> Topology.get_dc_hash_ring("TN")
#Ring<["TN-A-1", "TN-A-2", "TN-A-3", "TN-A-4", "TN-B-1", ...]>
```

```elixir
iex> Topology.get_current()
%{
  "TN" => #Ring<["TN-A-1", "TN-A-2", "TN-A-3", "TN-A-4", "TN-B-1", ...]>}, 
  "FL" => #Ring<["FL-A-1", "FL-A-2", "FL-A-3", "FL-A-4", "FL-B-1", ...]>},
  ...
}
```

```elixir
iex> Topology.get_actor_server(%{id: "1001", facility: "HOSPX"})
"TN-B-2"
```

This approach to a cluster's `Topology` means:

- Maintain consensus through just the `Topology` data structure
- Use that to route messages to the proper local Process registry
- Don't need a global registry

## Mailroom

To extend location transparency from the actor level to the node's server
level, a `Mailroom` is used.

A message comes into the system via a node, `FL`

Any Node can receive any message

No one on the outside knows about the cluster, `HashRing`s, registries, etc.

Each node has a `Mailroom`

The `Mailroom` knows the `Topology`

Incoming messages are routed through the `Mailroom` to the appropriate Patient
Actor

If the Patient Actor is remote, the `Mailroom` routes the message to the remote
node's `Mailroom`

If the `Topology` changes in-flight, the `Mailroom` will re-route to the
correct `Mailroom`

The local `Mailroom` then delivers the message to the correct Patient Actor

The `Mailroom` provides:

- Nice seam for testing
- Place to bundle data
- Spot to compress data
- Way to hide icky bits `:rpc`
- A path to distribution replacments

## Patient Actor

Every Patient Actor has a key

Every Patient Actor is registered (by key) on its node's `Registry`

Every Patient Actor is supervised

Commands are delivered to a Patient Actor via the `Mailroom`

If the Patient Actor is not running when a command is delivered it will be
started

If the `Topology` has changed and a Patient Actor's key no longer maps to
its current node, it will migrate to the correct node

Every Patient Actor has one read-only follower process (Process Pair)
at each data center

A Patient Actor processes commands and emits events

Before a Patient Actor commits an event to its event log, two of its four
read-only followers must acknowledge receipt of the event

When a Patient Actor starts it will ask (via the `Mailroom`) if its four
read-only followers have state. If they do, the Patient Actor will recover
from the "best" reader

Each Patient Actor's state contains its key, an event store, and a `Map` for
event handler plugins to store projections

## Deployments

Changes are deployed with the following techniques:

- Erlang OTP Releases
- Hot-code loading (sharp and powerful tool)
- Dark launches
- Universal Server and Plugins

### Event Handler Plugins

Builds on the idea of Joe Armstrong's [Universal Server](https://joearms.github.io/published/2013-11-21-My-favorite-erlang-program.html)

This allowed a Patient Actor to be a "Universal Server" that could be extended and changed
dynamically at runtime with zero downtime

This also makes Hot-code loading safer

A Patient Actor can be thought of as a `Map` with a set of Event Handler plugins

```elixir
%{
  key: %{id: "1001", facility: "HOSPX"},
  projections: %{...},
  event_store: [...],
}
```

```elixir
defmodule SomeEventHandler do
  @spec handle(
    key :: map(), 
    projections :: projections(), 
    msg :: Message.t(), 
    history :: [Message.t()]
  ) :: {:ok, projections(), side_effects()}
  def handle(key, projections, msg, history) do
    # ...
  end
end
```

This `handle/4` function is a pure function that allows for Property Based
Testing which allows for a high degree of confidence in the correctness of
message processing
