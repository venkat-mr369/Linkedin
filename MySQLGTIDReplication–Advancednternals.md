### MySQL GTID Replication – Advanced Internals 

This architecture demonstrates how **GTID (Global Transaction Identifier)** simplifies replication, failover, auto-positioning, cascading replicas, and multi-threaded replication in enterprise environments.

<img width="1536" height="1012" alt="gtid-internals-advanced" src="https://github.com/user-attachments/assets/14d9fe26-1cd7-4fe2-8d80-337016ead46c" />

---

### What is GTID?

GTID = Global Transaction Identifier

Format:

```text
Server_UUID:Transaction_ID
```

Example:

```text
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa:1001
```

Meaning:

* Server UUID = Transaction origin server
* 1001 = Unique transaction number

Every committed transaction receives a unique GTID.

---

### Example Topology

```text
Application
      |
      v
+----------------+
| Primary1       |
| Source Server  |
+----------------+
      |
      v
+----------------+
| Replica1       |
+----------------+
      |
      v
+----------------+
| Replica2       |
| Cascading Rep  |
+----------------+
```

---

### Step-by-Step GTID Transaction Flow

#### Step 1 – Application Commits Transaction

Example:

```sql
INSERT INTO customers VALUES (101,'Ramya');
```

Client sends COMMIT.

---

#### Step 2 – GTID Generated

Primary generates:

```text
aaaaaaaa:1
```

Next transaction:

```text
aaaaaaaa:2
```

and so on.

---

#### Step 3 – Transaction Written to InnoDB

Data stored in:

```text
InnoDB Buffer Pool
Redo Logs
Undo Logs
```

Transaction commits locally on Primary.

---

#### Step 4 – GTID Written to Binary Log

Binary Log:

```text
GTID aaaaaaaa:1
INSERT ...

GTID aaaaaaaa:2
UPDATE ...

GTID aaaaaaaa:3
DELETE ...
```

---

#### Step 5 – GTID Added to GTID_EXECUTED

Primary:

```text
GTID_EXECUTED

aaaaaaaa:1-10
```

Meaning:

Transactions 1 through 10 completed.

---

### Replica Internal Working

#### IO Thread

Responsibilities:

1. Connects to Primary
2. Reads Binlog Events
3. Downloads Transactions
4. Stores in Relay Logs

```text
Primary Binlog
      |
      v
IO Thread
      |
      v
Relay Log
```

---

#### SQL Thread

Responsibilities:

1. Reads Relay Log
2. Applies Transactions
3. Updates GTID_EXECUTED

```text
Relay Log
      |
      v
SQL Thread
      |
      v
InnoDB
```

---

### Relay Log Example

```text
GTID aaaaaaaa:1
GTID aaaaaaaa:2
GTID aaaaaaaa:3
...
GTID aaaaaaaa:10
```

SQL Thread replays transactions sequentially.

---

### GTID Auto Position

Old Replication:

```sql
CHANGE MASTER TO
MASTER_LOG_FILE='mysql-bin.001',
MASTER_LOG_POS=1200;
```

Manual tracking required.

---

GTID Replication:

```sql
CHANGE REPLICATION SOURCE TO SOURCE_AUTO_POSITION=1;
```

Replica automatically identifies missing transactions.

No file.

No position.

No manual calculations.

---

### Real Bank Example

Suppose:

```text
Primary:
GTID_EXECUTED = 1-100
```

Replica crashes after:

```text
GTID_EXECUTED = 1-97
```

When Replica returns:

Primary compares:

```text
Primary = 1-100
Replica = 1-97
```

Missing:

```text
98
99
100
```

Only missing transactions are transferred.

This significantly reduces recovery time.

---

### Banking Example

#### Credit Card Processing

```text
Primary
Transaction #5001
Customer swipes card
Amount ₹10,000
```

GTID:

```text
bankuuid:5001
```

Replica receives exactly the same transaction.

No duplicates.

No missing transactions.

Audit compliance maintained.

---

### Pharmaceutical Example (Pfizer / Sanofi / Takeda)

EHR / Clinical Database

Doctor updates patient record:

```sql
UPDATE patient
SET dosage='50mg'
WHERE patient_id=1001;
```

GTID:

```text
pharmauuid:10001
```

Every replica receives the exact transaction.

Benefits:

* Regulatory compliance
* Audit traceability
* Disaster recovery
* Data consistency

---

### Retail Example

E-commerce platform:

```text
Order #10001
Inventory reduced
Payment completed
Shipment created
```

Transactions:

```text
retailuuid:101
retailuuid:102
retailuuid:103
```

GTID ensures all replicas receive identical transactions.

No overselling.

No inventory mismatch.

---

## Cascading Replication

Instead of all replicas connecting to Primary:

```text
Primary
   |
Replica1
   |
Replica2
```

Replica2 receives data from Replica1.

Benefits:

* Reduces Primary workload
* Saves network bandwidth
* Useful for DR sites

Common in:

* Banks
* Telecom
* Global Retail Companies

---

## Multi-Threaded Replication (MTS)

Traditional:

```text
1 SQL Thread
```

Applies transactions one-by-one.

---

MTS:

```text
Coordinator
     |
 ------------------
 |   |   |   |
W1  W2  W3  W4
```

Multiple worker threads apply transactions simultaneously.

Example:

```text
Transaction A
Transaction B
Transaction C
Transaction D
```

Can run in parallel if independent.

---

### Benefits of MTS

* Faster replication
* Reduced lag
* Better CPU utilization
* Faster failover readiness

---

### Example

Without MTS:

```text
1000 transactions
1 SQL Thread
15 minutes
```

With MTS:

```text
1000 transactions
8 Worker Threads
2-3 minutes
```

---

### Failover Scenario

Primary Server Fails

```text
Primary1
   X
```

Promote Replica1:

```sql
STOP REPLICA;
RESET REPLICA ALL;
SET GLOBAL read_only=OFF;
```

Replica1 becomes new Primary.

Replica2 points to Replica1.

Because of GTID:

```text
No file position changes
No manual calculations
No data loss
```

---

### GTID_PURGED

Suppose:

```text
GTID_EXECUTED = 1-1000
```

Older binlogs removed:

```text
GTID_PURGED = 1-500
```

Current binlogs contain:

```text
501-1000
```

MySQL still remembers that transactions 1-500 existed.

Important during backup restoration and replica provisioning.

---

### Interview Questions

Q: What is GTID?

A: GTID (Global Transaction Identifier) uniquely identifies every transaction using UUID:Sequence_Number.

Q: What is the benefit of GTID?

A: Automatic failover, auto-positioning, easier replica rebuild, and transaction tracking.

Q: What thread reads binlogs from Primary?

A: IO Thread.

Q: What thread applies transactions?

A: SQL Thread or Worker Threads in MTS.

Q: What is Cascading Replication?

A: A replica receives transactions from another replica instead of directly from the Primary.

Q: What is MTS?

A: Multi-Threaded Replication uses multiple worker threads to apply transactions in parallel and reduce replication lag.

Q: What is GTID_PURGED?

A: GTIDs whose binlogs were deleted but whose transaction history is still retained by MySQL.

---




