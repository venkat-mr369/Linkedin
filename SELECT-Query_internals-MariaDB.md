### MariaDB is different from MySQL because MariaDB supports multiple storage engines, while MySQL 8.x is mostly centered around InnoDB.

<img width="1024" height="1527" alt="ChatGPT Image Jun 15, 2026, 02_33_09 PM" src="https://github.com/user-attachments/assets/6447fef2-a362-419e-a55e-c8f6cea80696" />


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

### Interview Answer (One Line)

**MariaDB Query Flow:** Client → Parser → Optimizer → Execution Engine → Storage Engine API → (InnoDB/Aria/MyISAM/RocksDB/ColumnStore/Spider) → Cache Layer → Data Files → Result Set → Client.

The key difference from MySQL is that **MariaDB has a pluggable storage engine architecture with several actively used engines (InnoDB, Aria, MyISAM, RocksDB, ColumnStore, Spider), whereas MySQL 8.x primarily relies on InnoDB.**
