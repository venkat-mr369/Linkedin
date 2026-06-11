**MySQL Group Replication Architecture (Single Primary Mode)** 

<img width="800" height="521" alt="1779946115693" src="https://github.com/user-attachments/assets/daace550-d0b8-4bef-80a0-2d9a168b6a8f" />


---

## 1. Applications

This is where users connect.

Examples:

* Java Application
* Python Application
* .NET Application
* Web Application
* Mobile App

Example:

```sql
INSERT INTO orders VALUES(101,'Laptop');
```

The application sends the query to MySQL Router.

---

## 2. MySQL Router

Think of MySQL Router as a **Traffic Police**.

Responsibilities:

* Read/Write Split
* Routing
* Automatic Failover

### Write Query

```sql
INSERT INTO emp VALUES(1001,'Ramya');
```

Router sends it only to:

```text
Primary Server 1
```

### Read Query

```sql
SELECT * FROM emp;
```

Router can send it to:

```text
Secondary Server 2
Secondary Server 3
```

This reduces load on Primary.

---

## 3. Primary Server (Server 1)

This is the leader node.

Responsibilities:

* Accepts all writes
* Generates transactions
* Participates in certification process
* Replicates transactions to all members

Example:

```sql
UPDATE emp
SET salary=50000
WHERE emp_id=1001;
```

Write occurs on Primary.

---

## 4. Secondary Server (Server 2)

Replica node.

Responsibilities:

* Receives transactions
* Applies transactions
* Can serve read traffic
* Participates in voting

Example:

```sql
SELECT * FROM emp;
```

Can be routed here.

---

## 5. Secondary Server (Server 3)

Same role as Server 2.

Responsibilities:

* Receive replicated changes
* Read operations
* Participate in cluster voting

---

## 6. Group Replication Layer

This is the most important part.

Group Replication uses:

```text
Paxos-Based Consensus
```

Purpose:

* Maintain consistency
* Prevent split brain
* Elect new primary

Every transaction must be approved by majority nodes.

---

### Example

Suppose:

```sql
INSERT INTO emp VALUES(1005,'Jagan');
```

Primary creates transaction.

Before commit:

```text
Primary
   ↓
Secondary 2
   ↓
Secondary 3
```

All members verify transaction.

Only then COMMIT succeeds.

---

## 7. Paxos (Consensus Protocol)

Paxos is a voting mechanism.

Purpose:

* Cluster agreement
* Primary election
* Transaction certification

---

### Example

Three Servers:

```text
Server1
Server2
Server3
```

Minimum majority:

```text
2 out of 3
```

If Server1 crashes:

```text
Server2 + Server3
```

Still have majority.

Cluster continues running.

---

## 8. Binary Log (Binlog)

Shown below every server.

Stores:

```sql
INSERT
UPDATE
DELETE
DDL
```

Example:

```sql
CREATE TABLE emp(
id INT
);
```

Stored in Binlog.

---

### Why Binlog?

Used for:

* Replication
* Recovery
* Point-in-Time Recovery (PITR)
* Auditing

---

## 9. MySQL Shell

Administrative tool.

Command-line interface.

Responsibilities:

### Deployment

Create cluster.

Example:

```javascript
dba.createCluster('prodCluster')
```

---

### Administration

Add new node.

Example:

```javascript
cluster.addInstance('root@server4')
```

---

### Monitoring

Check cluster status.

Example:

```javascript
cluster.status()
```

---

### Cluster Management

Switch primary.

Example:

```javascript
cluster.setPrimaryInstance()
```

---

## Write Flow (Important Interview Question)

Application executes:

```sql
INSERT INTO emp VALUES(1001,'Ramya');
```

Flow:

```text
Application
    ↓
MySQL Router
    ↓
Primary Server
    ↓
Certification
    ↓
Secondary 2
    ↓
Secondary 3
    ↓
Majority Approval
    ↓
Commit
```

---

## Read Flow

Application executes:

```sql
SELECT * FROM emp;
```

Flow:

```text
Application
    ↓
MySQL Router
    ↓
Secondary Server
    ↓
Result
```

No need to hit Primary.

---

## Failover Scenario

Current Primary:

```text
Server1
```

Server1 crashes.

Cluster detects failure.

Remaining:

```text
Server2
Server3
```

Election occurs.

New Primary:

```text
Server2
```

MySQL Router automatically redirects writes.

Application continues without changes.

---

## Interview One-Line Answer

**MySQL Group Replication is a native MySQL high-availability solution where multiple MySQL servers form a cluster, transactions are certified using Paxos-based consensus, MySQL Router provides read/write splitting and failover, and MySQL Shell is used for cluster administration.**
