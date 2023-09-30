# Quorum Project Milestones

## Topology Synchronization

### Status

Done

### Description

The Topology is synchronized between all nodes in the cluster. This is done by
via a combination of `libcluster` and message passing between nodes via the
`Quorum.Mailroom` module.

## Poll Creation

### Status

Done (may need revision later)

### Description

A poll can be created by any node in the cluster. This is done by receiving
a `%Quorum.Message{type: :create_poll, data: %{...}}` message in the `Quorum.Mailroom`
module. This will then be passed to the `Quorum.PollSupervisor` module where
a new `Quorum.Poll` process will be spawned. The `Quorum.Poll` process will
then be registered with the `Quorum.Registry` module.

## Poll Creation Replication

### Status

In Progress

### Description

Poll replication is the first major feature of the Quorum project. This is
where a Poll is replicated to other nodes in the cluster. In order for the
Quorum system to service requests for a Poll, it must be created in the
DC that receives the requests and then replicated to the following places:

- The same DC but in a different AZ
- 3 other DCs in the cluster. The AZ is irrelevant at this point in my
  understanding. This protocol can be changed later if needed.

Therefore a total of 5 replicas will exist for a single Poll. A detail of
the consensus protocol of the Quorum system is that at least 3 replicas
must be available and service messages for a Poll to be "in consensus".

### Replication Scenarios

The following scenarios will be implemented in order so that the implementation
can be carefully interated upon and verified.

#### Single Poll Replica

- Poll creation, no replication

#### 2 Poll Replicas

- Poll creation
- Replication in same DC, different AZ

#### 3 Poll Replicas

- Poll creation
- Replication in same DC, different AZ
- Replication in different DC

#### 4/5 Poll Replicas

- Poll creation
- Replication in same DC, different AZ
- Replication in 3 different DCs
