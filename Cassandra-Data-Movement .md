### Cassandra Data Movement (Production Example - Customer Table)

<img width="1533" height="1024" alt="cass" src="https://github.com/user-attachments/assets/b0f618fb-68eb-4341-9858-c289cb4f8afd" />


Assume a production e-commerce application.

## Cluster Design

### Data Center

```sql
DC1
 ├── Node1
 ├── Node2
 ├── Node3
 ├── Node4
 ├── Node5
 └── Node6
```

### Keyspace (Production)

```sql
CREATE KEYSPACE ecommerce
WITH replication = {
  'class':'NetworkTopologyStrategy',
  'DC1':3
};
```

**Why NetworkTopologyStrategy?**

* Production standard
* Multi-DC support
* Rack aware
* Fault tolerant

---

# Customer Table

```sql
CREATE TABLE ecommerce.customers (
    customer_id UUID,
    customer_name TEXT,
    email TEXT,
    city TEXT,
    created_date TIMESTAMP,
    PRIMARY KEY(customer_id)
);
```

---

# Data Placement

Suppose:

```sql
INSERT INTO customers
(customer_id,customer_name,email,city)
VALUES
(
11111111-1111-1111-1111-111111111111,
'Venkat',
'venkat@gmail.com',
'Hyderabad'
);
```

Partition Hash:

```text
Token = 456789
```

Based on ring ownership:

```text
Node2 = Primary Replica
Node3 = Replica 2
Node4 = Replica 3
```

RF=3

Data Stored:

```text
Node2  ✓
Node3  ✓
Node4  ✓

Node1  X
Node5  X
Node6  X
```

---

# Write Flow (All Nodes UP)

Client:

```sql
INSERT INTO customers
(customer_id,customer_name,email,city)
VALUES
(
11111111-1111-1111-1111-111111111111,
'Venkat',
'venkat@gmail.com',
'Hyderabad'
);
```

Connection:

```text
Client
  |
  v
Node1 (Coordinator)
```

Coordinator Calculates:

```text
Replicas:

Node2
Node3
Node4
```

Flow:

```text
Client
  |
  v
Coordinator(Node1)
   |
   +-------> Node2
   |
   +-------> Node3
   |
   +-------> Node4
```

Each Replica:

```text
1. Commit Log
2. Memtable
3. ACK
```

---

# Consistency Level QUORUM

Write:

```sql
CONSISTENCY QUORUM;

INSERT INTO customers ...
```

RF=3

Formula:

```text
QUORUM = RF/2 +1

3/2 +1

= 2
```

Need:

```text
2 ACKs
```

Example:

```text
Node2 ACK ✓
Node3 ACK ✓
Node4 ACK Pending
```

Client gets success.

```text
SUCCESS
```

---

# Node4 Down Scenario

During write:

```text
Node4 DOWN
```

Flow:

```text
Client
  |
  v
Coordinator(Node1)
   |
   +----> Node2 ACK
   |
   +----> Node3 ACK
   |
   +----> Node4 DOWN
```

Coordinator creates Hint:

```text
Hint:
CustomerID=1111
Operation=INSERT
Target=Node4
```

Stored in:

```text
system.hints
```

---

# Hinted Handoff

After Node4 comes back:

```text
Node4 UP
```

Coordinator:

```text
Reads Hint
```

Replay:

```text
Node1
  |
  +-----> Node4
```

Node4 writes:

```text
Commit Log
Memtable
ACK
```

Hint deleted.

Now:

```text
Node2 ✓
Node3 ✓
Node4 ✓
```

All replicas synchronized.

---

# Read Flow

Query:

```sql
SELECT *
FROM customers
WHERE customer_id=
11111111-1111-1111-1111-111111111111;
```

Coordinator:

```text
Node5
```

Node5 contacts:

```text
Node2
Node3
Node4
```

CL=QUORUM

Need:

```text
2 responses
```

Example:

```text
Node2 Response
Node3 Response
```

Result returned.

---

# Read Repair Example

Suppose:

```text
Node2 -> Hyderabad
Node3 -> Hyderabad
Node4 -> NULL
```

Coordinator detects mismatch.

Background:

```text
Node2
  |
  +-----> Node4
```

or

```text
Node3
  |
  +-----> Node4
```

Node4 repaired.

This is called:

```text
Read Repair
```

---

# Repair Operation

Hints expired after 3 hours.

Node4 down for:

```text
2 days
```

Hints lost.

Run:

```bash
nodetool repair ecommerce customers
```

Data streamed:

```text
Node2 ---> Node4
Node3 ---> Node4
```

This is Anti-Entropy Repair.

---

# Production Interview Answer

**Q: How does data move between Cassandra nodes?**

**Answer:**

> In Cassandra, data is replicated asynchronously among replica nodes. During a write, the coordinator sends mutations to all replicas based on the replication factor. Client acknowledgment depends on the configured consistency level such as QUORUM or ALL. If a replica is unavailable, the coordinator stores a hint and later replays it through Hinted Handoff. Long-term consistency is maintained using Read Repair and Anti-Entropy Repair (nodetool repair). NetworkTopologyStrategy with RF=3 is typically used in production environments.
