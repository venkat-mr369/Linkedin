#### MariaDB is different from MySQL because MariaDB supports multiple storage engines, while MySQL 8.x is mostly centered around InnoDB.

### Learning Article: What Happens Internally When MariaDB Executes a Simple Query?

Most DBAs & Database Engineers know that MariaDB originated from MySQL, but internally MariaDB offers several storage engine choices beyond InnoDB. Understanding the query execution flow helps in performance tuning, troubleshooting, and architecture design.

Let's take a simple query:

```sql
SELECT * FROM emp WHERE name = 'Kishor';
```

### Step 1: Client Connection

The application connects to MariaDB through port 3306.

MariaDB:

* Authenticates the user
* Creates a connection thread
* Allocates session resources

### Step 2: SQL Parser

The parser validates the SQL syntax.

Checks include:

* SQL grammar validation
* Statement structure verification
* Basic syntax checking

If a syntax error is found, execution stops immediately.

### Step 3: Preprocessor

MariaDB verifies database objects referenced in the query.

Examples:

* Does the `emp` table exist?
* Does the `name` column exist?
* Does the user have the required privileges?

### Step 4: MariaDB Optimizer

The Cost-Based Optimizer evaluates multiple execution plans and selects the most efficient one.

The optimizer determines:

* Which index to use
* Whether to use Index Scan or Full Table Scan
* Join methods (for multi-table queries)
* Lowest cost execution path

### Step 5: Execution Engine

The execution engine follows the plan selected by the optimizer and interacts with the storage engine layer.

### Step 6: Storage Engine API Layer

This is where MariaDB becomes unique.

Instead of relying primarily on a single engine, MariaDB can execute the query through different storage engines:

* InnoDB
* Aria
* MyISAM
* RocksDB
* ColumnStore
* Spider
* Others

The flow after this point depends on the storage engine used by the table.

---

### If EMP Uses InnoDB

```text
Optimizer
   ↓
B+ Tree Index Search
   ↓
Find 'Kishor'
   ↓
Primary Key Lookup
   ↓
Clustered Index Read
   ↓
Return Row
```

Features:

* ACID compliant
* Transactions
* MVCC
* Row-level locking

---

### If EMP Uses MyISAM

```text
Optimizer
   ↓
Index Lookup (.MYI)
   ↓
Find Pointer
   ↓
Read Data File (.MYD)
   ↓
Return Row
```

Features:

* Fast reads
* Table-level locking
* No transactions

---

### If EMP Uses Aria

```text
Optimizer
   ↓
Page Cache
   ↓
Aria Index (.MAI)
   ↓
Aria Data File (.MAD)
   ↓
Return Row
```

Features:

* Crash-safe
* Commonly used for internal temporary tables

---

### If EMP Uses RocksDB

```text
Optimizer
   ↓
MemTable
   ↓
Block Cache
   ↓
SST Files
   ↓
Return Row
```

Features:

* LSM Tree architecture
* Efficient write-heavy workloads
* Compression support

---

### If EMP Uses ColumnStore

```text
Optimizer
   ↓
Column Index Lookup
   ↓
Read Required Columns
   ↓
Decompress Data
   ↓
Return Row
```

Features:

* Analytical workloads
* Data warehouse use cases
* Columnar storage

---

### If EMP Uses Spider

```text
Optimizer
   ↓
Send Query to Remote Node
   ↓
Remote Execution
   ↓
Receive Result
   ↓
Return Row
```

Features:

* Sharding
* Federated architecture
* Distributed query execution

---

### Simplified MariaDB Query Flow

```text
Client
   ↓
Connection Manager
   ↓
SQL Parser
   ↓
Preprocessor
   ↓
MariaDB Optimizer
   ↓
Execution Engine
   ↓
Storage Engine API
   ↓
(InnoDB / Aria / MyISAM / RocksDB / ColumnStore / Spider)
   ↓
Cache Layer
   ↓
Data Files
   ↓
Result Set
   ↓
Client
```

### Key Takeaway

A simple `SELECT` statement may appear straightforward, but MariaDB performs authentication, parsing, validation, optimization, storage engine selection, cache lookups, index navigation, data retrieval, and result generation before returning the data.

The biggest architectural advantage of MariaDB is its **pluggable storage engine ecosystem**, allowing organizations to choose the engine that best fits their workload—whether it's transactional processing with InnoDB, analytics with ColumnStore, write-intensive workloads with RocksDB, or distributed databases with Spider.


For the query:

```sql
SELECT * FROM emp WHERE name='Kishor';
```

### MariaDB Internal Flow

```text
Client Application
        │
        ▼
MariaDB Listener (3306)
        │
        ▼
Connection Thread
(Authentication)
        │
        ▼
SQL Parser
(Syntax Check)
        │
        ▼
Preprocessor
(Table/Column Validation)
        │
        ▼
MariaDB Optimizer
(Cost Based Optimizer)
        │
        ▼
Execution Engine
        │
        ▼
Storage Engine API Layer
        │
        ├──────────────► InnoDB
        │                    │
        │                    ▼
        │              Buffer Pool
        │                    │
        │                    ▼
        │              Data Files
        │
        ├──────────────► Aria
        │                    │
        │                    ▼
        │              Page Cache
        │                    │
        │                    ▼
        │              .MAI / .MAD Files
        │
        ├──────────────► MyISAM
        │                    │
        │                    ▼
        │              Key Cache
        │                    │
        │                    ▼
        │              .MYI / .MYD Files
        │
        ├──────────────► ColumnStore
        │                    │
        │                    ▼
        │              Columnar Storage
        │
        ├──────────────► Spider
        │                    │
        │                    ▼
        │              Remote MariaDB Nodes
        │
        └──────────────► RocksDB
                             │
                             ▼
                       LSM Tree Storage
                             │
                             ▼
                          SST Files
        │
        ▼
Matching Rows
        │
        ▼
Result Set
        │
        ▼
     Client
```

---

### If EMP uses InnoDB

```text
Optimizer
   │
   ▼
Use idx_name
   │
   ▼
B+ Tree Search
   │
   ▼
Find "Kishor"
   │
   ▼
Primary Key Lookup
   │
   ▼
Clustered Index Read
   │
   ▼
Return Row
```

---

### If EMP uses MyISAM

```text
Optimizer
   │
   ▼
Use idx_name
   │
   ▼
B+ Tree Search
   │
   ▼
Find Pointer
   │
   ▼
Read Data File (.MYD)
   │
   ▼
Return Row
```

---

### If EMP uses Aria

```text
Optimizer
   │
   ▼
Use Index
   │
   ▼
Page Cache
   │
   ▼
Read .MAI/.MAD Files
   │
   ▼
Return Row
```

---

### If EMP uses RocksDB

```text
Optimizer
   │
   ▼
RocksDB Engine
   │
   ▼
MemTable
   │
   ▼
Block Cache
   │
   ▼
SST Files
   │
   ▼
Return Row
```

---
<img width="1024" height="1392" alt="mariadb-flow" src="https://github.com/user-attachments/assets/ce75ba89-54e8-4729-8195-7974877baae7" />


### Interview Answer (One Line)

**MariaDB Query Flow:** Client → Parser → Optimizer → Execution Engine → Storage Engine API → (InnoDB/Aria/MyISAM/RocksDB/ColumnStore/Spider) → Cache Layer → Data Files → Result Set → Client.

The key difference from MySQL is that **MariaDB has a pluggable storage engine architecture with several actively used engines (InnoDB, Aria, MyISAM, RocksDB, ColumnStore, Spider), whereas MySQL 8.x primarily relies on InnoDB.**
