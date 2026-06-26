### CockroachDB Data Movement Internals (3-Node Cluster)

🚀 **Understanding CockroachDB Data Movement Internals (3-Node Cluster)**

One of the most common interview questions for CockroachDB Database Engineers and SREs is:

**"How does CockroachDB move data internally across nodes?"**

Today, I explored the complete lifecycle of data movement inside a **3-node CockroachDB cluster**, from a client write request to Raft consensus, automatic replication, range splits, leaseholder transfers, and replica rebalancing.

### Key Concepts Covered

✅ Range-based data distribution

✅ Raft Consensus and Quorum

✅ Leaseholder Architecture

✅ Replica Placement

✅ Automatic Range Splitting

✅ Replica Rebalancing

✅ Leaseholder Transfer

✅ Node Failure & Recovery

✅ Automatic Data Rebalancing

### Sample SQL Commands

```sql
SHOW CLUSTER NODES;

SHOW RANGES FROM TABLE employees;

SHOW RANGES;

SHOW CLUSTER SETTINGS;
```

### Key Takeaways

• Data is automatically divided into **Ranges**.

• Each range has its own **Raft Group**.

• Every range has one **Leaseholder** responsible for coordinating writes.

• Writes are committed only after achieving a **quorum**, ensuring strong consistency.

• As data grows, CockroachDB automatically performs **range splits**.

• The cluster continuously rebalances replicas and leaseholders to optimize performance, availability, and fault tolerance.

Understanding these internals is essential for anyone working as a **CockroachDB DBA, Database Engineer, Database SRE, or Database Architect**.

I'm continuing to explore more distributed database internals and production scenarios. Stay tuned for upcoming deep dives!

#DatabaseEngineering #DatabaseArchitect #DBA #CockroachDB #DistributedDatabase #RaftConsensus #HighAvailability #DatabaseReplication #DatabaseInternals #CloudDatabase #SRE #DatabasePerformance #Scalability #DatabaseCommunity #TechLearning #DatabaseAdministration 🚀


### Cluster Architecture in Detail 

<img width="1514" height="1009" alt="cok" src="https://github.com/user-attachments/assets/14d7d6e0-a4d2-47dd-88e4-44dbbf382ba2" />


Assume a three-node cluster.

```
Node1 (Store1)
Node2 (Store1)
Node3 (Store1)
```

Replication Factor (RF)

```
3
```

Every range has

* 1 Leaseholder (Leader)
* 2 Followers

Every write must be acknowledged by a majority (Quorum).

```
RF = 3

Quorum = 2
```

---

# Step 1 Create Database

```sql
CREATE DATABASE company;
```

```
company
```

---

# Step 2 Create Table

```sql
USE company;

CREATE TABLE employees
(
    emp_id INT PRIMARY KEY,
    emp_name STRING,
    department STRING,
    salary DECIMAL
);
```

Initially

```
No data

No ranges split
```

---

# Step 3 Insert Data

```sql
INSERT INTO employees VALUES
(1,'John','IT',50000),
(2,'David','HR',45000),
(3,'Smith','Finance',60000);
```

Client

↓

Node1

↓

Leaseholder receives request

↓

Raft Log

↓

Followers receive

↓

Commit

↓

Client receives Success

---

# Internal Flow

```
Application

↓

Node1

↓

Leaseholder

↓

Raft Log

↓

Node2 Replica

↓

Node3 Replica

↓

Quorum Achieved

↓

Commit
```

---

# Step 4 Find Leaseholder

```sql
SHOW RANGES FROM TABLE employees;
```

Example

```
RangeID

Lease Holder

Replicas

1

Node1

Node1 Node2 Node3
```

Leaseholder receives all writes.

Followers only replicate.

---

# Step 5 Read Query

```sql
SELECT *
FROM employees
WHERE emp_id=2;
```

If leaseholder is Node1

```
Application

↓

Node1

↓

Reads locally

↓

Returns data
```

If locality allows follower reads

CockroachDB may serve reads from followers.

---

# Step 6 More Inserts

Insert 1 Million Rows

```sql
INSERT INTO employees
SELECT
generate_series,
'Employee',
'IT',
50000
FROM generate_series(4,1000000);
```

Table becomes large.

CockroachDB automatically splits ranges.

---

# Before Split

```
Range1

1-1000000
```

---

# After Split

```
Range1

1-250000

Range2

250001-500000

Range3

500001-750000

Range4

750001-1000000
```

Each range

Has

Own

Leaseholder

Raft Group

Replicas

---

# View Ranges

```sql
SHOW RANGES FROM TABLE employees;
```

Example

```
RangeID

Leaseholder

Replicas

1

Node1

Node1 Node2 Node3

2

Node2

Node1 Node2 Node3

3

Node3

Node1 Node2 Node3

4

Node2

Node1 Node2 Node3
```

Notice

Leaseholders are distributed.

This avoids hotspotting.

---

# Range Rebalancing

Suppose

Node1

Disk

95%

Node2

30%

Node3

25%

CockroachDB decides

Move Range2

From

Node1

↓

Node3

Automatically.

---

Before

```
Range2

Node1

Node2

Node3
```

After

```
Range2

Node2

Node3

Node3
```

Replica copied

↓

Validated

↓

Old replica removed

No downtime.

---

# SQL to View Distribution

```sql
SHOW RANGES FROM TABLE employees;
```

---

# Leaseholder Transfer

Suppose

Most users are in Asia.

Leaseholder

Currently

US region.

CockroachDB moves Leaseholder

Near clients.

Example

```
Before

Leaseholder

Node1 (US)
```

↓

```
After

Leaseholder

Node3 (Singapore)
```

Reads

Become faster.

Writes

Lower latency.

---

# Manual Lease Transfer

```sql
ALTER RANGE default
RELOCATE LEASE
TO 3;
```

Example only.

Production generally lets CockroachDB decide.

---

# Replica Rebalancing

Imagine

Node2 crashes.

Cluster

Before

```
Node1

Range1

Range2

Range3

Node2

Range1

Range2

Range3

Node3

Range1

Range2

Range3
```

Node2 fails.

Remaining

```
Node1

Node3
```

Replication Factor

Drops

3

↓

2

CockroachDB notices.

Automatically creates

New replica

When replacement node joins.

---

# Node Recovery

New

Node4 joins.

CockroachDB copies

Ranges

Automatically.

```
Node1

Range1

↓

Node4

Range1
```

Repeated

Until balanced.

---

# Quorum Example

RF

3

Need

2 votes.

Write

↓

Node1

↓

Node2

ACK

↓

Commit

Node3 may still be catching up.

Write succeeds.

---

If

Only Node1 alive

Need

2

Only

1

Available

Write fails.

To protect consistency.

---

# Check Cluster Nodes

```sql
SHOW CLUSTER NODES;
```

---

# Check Ranges

```sql
SHOW RANGES FROM TABLE employees;
```

---

# Check Replication

```sql
SHOW RANGES;
```

---

# Cluster Settings

```sql
SHOW CLUSTER SETTINGS;
```

---

# Hot Ranges

```sql
SELECT *
FROM crdb_internal.kv_store_status;
```

---

# Node Status

```sql
SELECT *
FROM crdb_internal.gossip_nodes;
```

---

# Raft Status

```sql
SELECT *
FROM crdb_internal.ranges;
```

---

### Production Scenario

Users suddenly complain that writes are slow.

Investigation:

1. Check hot ranges.
2. Identify the leaseholder.
3. Verify Raft quorum health.
4. Check node CPU, memory, and disk.
5. Check network latency between nodes.
6. Verify replication is healthy.
7. Look for range imbalance or hotspotting.
8. Allow or trigger rebalancing if needed.

---

### Key Interview Points

* Data is divided into **Ranges** (approximately 512 MiB by default, though this can vary by version and workload).
* Each range forms an independent **Raft group**.
* Every range has **one leaseholder** that coordinates writes.
* Writes require a **quorum** before they commit.
* Reads are typically served by the leaseholder, with follower reads available in supported scenarios.
* CockroachDB automatically performs **range splits**, **replica rebalancing**, and **leaseholder transfers**.
* Node failures do **not** cause data loss if a quorum remains available.
* Automatic rebalancing helps maintain **high availability**, **fault tolerance**, and **load distribution**.
