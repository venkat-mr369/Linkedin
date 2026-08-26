
**real production scenario** and understand exactly **what happens without PgBouncer and with PgBouncer**.

### Our scenario (Knowledge Base Article Only)

we have:

* **1 PostgreSQL server**
* **3 databases**

  * `db1`
  * `db2`
  * `db3`
* Business applications generate **3000+ connections**

For example:

```text
                    PostgreSQL Server
                 ┌─────────────────────┐
                 │       db1           │
                 │       db2           │
                 │       db3           │
                 └─────────────────────┘

Applications
     │
     │ 3000+ connections
     ▼
PostgreSQL
```

The important question is:

> Should PostgreSQL directly handle all 3000+ client connections?

Usually, **this is not a good design**.

---

### 1. Without PgBouncer

Suppose you configure PostgreSQL:

```conf
max_connections = 3000
```

Now applications create connections directly:

```text
Application 1 ─────┐
Application 2 ─────┤
Application 3 ─────┤
                   │
     3000+         ▼
   connections ──> PostgreSQL
                   │
             ┌─────┴─────┐
             │ db1 db2 db3│
             └───────────┘
```

PostgreSQL generally uses a **separate backend process for each active connection**.

So imagine:

```text
3000 client connections
        ↓
3000 PostgreSQL backend processes/connections
```

This can create problems.

#### Problems without PgBouncer

##### 1. High memory usage

Every PostgreSQL connection consumes memory.

For example, if one connection effectively consumes:

```text
10 MB
```

Then:

```text
3000 × 10 MB = 30 GB
```

And actual memory usage can be higher depending on:

* `work_mem`
* connection overhead
* queries
* extensions
* application behavior

---

##### 2. Too many processes

You may see something like:

```text
postgres
postgres
postgres
postgres
postgres
...
3000 processes
```

This increases:

* CPU context switching
* memory pressure
* process management overhead

---

##### 3. Connection storms

Imagine your application server restarts.

Suddenly:

```text
500 application connections
        ↓
PostgreSQL

another 500
        ↓
PostgreSQL

another 500
        ↓
PostgreSQL
```

PostgreSQL must authenticate and create backend processes.

This can cause:

```text
High CPU
Slow response
Memory pressure
Connection errors
Database instability
```

---

### Example without PgBouncer

Let's say you have:

```text
Application Servers = 10

Each application server:
300 connections
```

Total:

```text
10 × 300 = 3000 connections
```

Architecture:

```text
                ┌──────────────┐
                │ App Server 1 │
                │ 300 conn     │
                └──────┬───────┘
                       │
                ┌──────▼───────┐
                │ App Server 2 │
                │ 300 conn     │
                └──────┬───────┘
                       │
                      ...
                       │
                       ▼

              PostgreSQL Server
              max_connections=3000

               ┌─────────────┐
               │ db1         │
               │ db2         │
               │ db3         │
               └─────────────┘
```

This is generally inefficient.

---

## 2. With PgBouncer

Now put PgBouncer between the applications and PostgreSQL.

```text
Applications
     │
     │
     ▼
┌─────────────────┐
│    PgBouncer    │
│ Connection Pool │
└────────┬────────┘
         │
         │ Only required
         │ database connections
         ▼
┌─────────────────┐
│   PostgreSQL    │
│                 │
│ db1 db2 db3     │
└─────────────────┘
```

Now your applications may still have:

```text
3000 client connections
```

But PostgreSQL does **not necessarily see 3000 connections**.

For example:

```text
3000 Client Connections
          │
          ▼
      PgBouncer
          │
          ├── 50 connections → db1
          │
          ├── 30 connections → db2
          │
          └── 20 connections → db3
                  │
                  ▼
             PostgreSQL

Total PostgreSQL connections = 100
```

So:

```text
Client connections = 3000

Actual PostgreSQL connections = 100
```

That is the main purpose of PgBouncer.

---

## How does PgBouncer achieve this?

Suppose 3000 users are connected.

Not all 3000 users are running queries at exactly the same moment.

Example:

```text
User 1   → Query running
User 2   → Idle
User 3   → Idle
User 4   → Query running
User 5   → Idle
...
```

Without PgBouncer:

```text
Every user keeps a PostgreSQL connection.
```

With PgBouncer:

```text
User 1 ──┐
User 2 ──┤
User 3 ──┤
User 4 ──┤
         ▼
     PgBouncer
         │
         │ Reuses available connections
         ▼
     PostgreSQL
```

When a client needs to execute a query, PgBouncer gives it an available PostgreSQL connection from the pool.

After the work is completed, the connection can be reused by another client.

---

## Connection pooling modes

PgBouncer has three important pooling modes.

### 1. Session pooling

```text
Client connects
       ↓
PgBouncer assigns PostgreSQL connection
       ↓
Client keeps it for entire session
       ↓
Client disconnects
       ↓
Connection returns to pool
```

Example:

```text
Client 1 ─────────────── PostgreSQL Connection 1

Client 2 ─────────────── PostgreSQL Connection 2
```

This is similar to a traditional connection.

Use when applications require session-level features.

---

### 2. Transaction pooling ⭐ Most commonly used

This is usually the most powerful mode for high-connection workloads.

```text
Client starts transaction
        ↓
PgBouncer gives PostgreSQL connection
        ↓
Transaction executes
        ↓
COMMIT
        ↓
Connection returned to pool
```

Then another client can use the same connection.

Example:

```text
Client 1
   │
   ├── BEGIN
   ├── SELECT
   ├── UPDATE
   └── COMMIT
          │
          ▼
 PostgreSQL Connection
          │
          ▼
 Returned to pool
          │
          ▼
 Client 2 uses same connection
```

For our **3000+ business connections**, this is often the preferred approach, provided the application is compatible with transaction pooling.

---

### 3. Statement pooling

Each individual SQL statement may use a different backend connection.

```text
SELECT → Connection A

UPDATE → Connection B

INSERT → Connection C
```

This is rarely the first choice for normal applications because it has more application compatibility limitations.

---

## our 3 database scenario

Suppose:

```text
PostgreSQL Server

db1 → 1500 application connections
db2 → 1000 application connections
db3 → 500 application connections
```

Total:

```text
3000 connections
```

With PgBouncer, you can configure pools separately.

For example:

```text
PgBouncer

db1 → pool size 50
db2 → pool size 30
db3 → pool size 20
```

Architecture:

```text
                         3000 Clients
                              │
                              ▼
                    ┌──────────────────┐
                    │    PgBouncer     │
                    │                  │
                    │ db1 Pool = 50    │
                    │ db2 Pool = 30    │
                    │ db3 Pool = 20    │
                    └─────────┬────────┘
                              │
                    Only 100 backend
                      connections
                              │
                              ▼
                    ┌──────────────────┐
                    │   PostgreSQL     │
                    │                  │
                    │ db1              │
                    │ db2              │
                    │ db3              │
                    └──────────────────┘
```

So PostgreSQL can be configured more reasonably, for example:

```conf
max_connections = 200
```

instead of:

```conf
max_connections = 3000
```

You should **not simply choose pool sizes based on 3000 users**. Pool sizing must consider CPU cores, workload type, query duration, and the total across all databases/users.

---

## Simple real-time example

Imagine a bank.

There are:

```text
3000 customers logged into the application.
```

But at any given moment:

```text
Only 100 customers are actively executing database transactions.
```

### Without PgBouncer

```text
3000 customers
      ↓
3000 PostgreSQL connections
```

### With PgBouncer

```text
3000 customers
      ↓
PgBouncer

100 reusable PostgreSQL connections
      ↓
PostgreSQL
```

The other clients wait briefly for an available connection when necessary.

---

## Important concept: PgBouncer does not magically make PostgreSQL handle unlimited work

This is very important.

If you have:

```text
3000 clients
```

and all 3000 are running expensive queries simultaneously, PgBouncer cannot solve the database performance problem.

Example:

```text
3000 × SELECT * FROM huge_table
```

PgBouncer will:

* limit and queue database connections
* protect PostgreSQL from connection overload
* reuse connections

But it will **not make expensive queries faster**.

You still need:

* proper indexing
* query tuning
* CPU
* memory
* I/O performance
* database monitoring

---

## Production architecture I would suggest

For your case:

```text
                         APPLICATION LAYER

       App Server 1        App Server 2        App Server 3
            │                   │                  │
            └──────────┬────────┴───────────┬──────┘
                       │                    │
                       ▼                    ▼

                  PgBouncer
              Connection Pooling

        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼

      db1 Pool       db2 Pool       db3 Pool
       50-100          30-75          20-50
        │              │              │
        └──────────────┼──────────────┘
                       ▼

                 PostgreSQL Server
```

A starting configuration might conceptually be:

```ini
[pgbouncer]

pool_mode = transaction

max_client_conn = 5000

default_pool_size = 50

reserve_pool_size = 10

reserve_pool_timeout = 5

max_db_connections = 200
```

But for **3 databases**, we should design the pool sizes carefully rather than using these numbers blindly.

---

## Before vs After

| Feature                      | Without PgBouncer               | With PgBouncer              |
| ---------------------------- | ------------------------------- | --------------------------- |
| Application connections      | 3000                            | 3000                        |
| PostgreSQL connections       | Potentially 3000                | Controlled, e.g. 100–300    |
| PostgreSQL memory            | High                            | Lower                       |
| Backend processes            | Very high                       | Controlled                  |
| Connection creation overhead | High                            | Reduced                     |
| Connection reuse             | No central pooling              | Yes                         |
| Connection storm protection  | Limited                         | Better                      |
| Queuing                      | PostgreSQL/application pressure | PgBouncer can queue clients |
| Scalability                  | More difficult                  | Better                      |

### The key architecture for your environment is:

```text
3000+ Business/Application Connections
                │
                ▼
           PgBouncer
                │
       Controlled Pool Size
                │
                ▼
        PostgreSQL Server
        ├── Database 1
        ├── Database 2
        └── Database 3
```

