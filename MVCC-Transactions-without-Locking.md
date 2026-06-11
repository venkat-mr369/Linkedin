### PostgreSQL  MVCC (Multi-Version Concurrency Control) 

--- Common Example with 3 Records

<img width="1536" height="1020" alt="PostgreSQL MVCC Transactions without Locking" src="https://github.com/user-attachments/assets/48b32d88-37dd-47ae-afe5-4bd07bc9fb2a" />


Suppose we have an Employee table:

| ID | Name  | Salary |
| -- | ----- | ------ |
| 1  | Ramya | 50000  |
| 2  | Sindu | 60000  |
| 3  | Jagan | 70000  |

---

### Step 1: Initial State

All rows are live.

| ID | Name  | Salary | xmin | xmax |
| -- | ----- | ------ | ---- | ---- |
| 1  | Ramya | 50000  | 100  | 0    |
| 2  | Sindu | 60000  | 100  | 0    |
| 3  | Jagan | 70000  | 100  | 0    |

Meaning:

```text
xmin = 100
→ Transaction 100 inserted the row

xmax = 0
→ Row is still active
```

---

## Transaction T1 Starts (Reader)

```sql
BEGIN;

SELECT * FROM emp;
```

T1 sees:

| ID | Name  | Salary |
| -- | ----- | ------ |
| 1  | Ramya | 50000  |
| 2  | Sindu | 60000  |
| 3  | Jagan | 70000  |

PostgreSQL takes a snapshot.

Think:

```text
Snapshot = Photo of table at this moment
```

---

## Transaction T2 Starts (Writer)

```sql
BEGIN;

UPDATE emp
SET salary=65000
WHERE id=2;
```

Many people think PostgreSQL updates the row.

Actually PostgreSQL does:

```text
OLD ROW -> Keep it
NEW ROW -> Create it
```

Table internally becomes:

| ID | Name  | Salary | xmin | xmax |
| -- | ----- | ------ | ---- | ---- |
| 2  | Sindu | 60000  | 100  | 200  |
| 2  | Sindu | 65000  | 200  | 0    |

Explanation:

Old Row:

```text
xmin=100
xmax=200

Transaction 200 updated this row
```

New Row:

```text
xmin=200
xmax=0

Created by transaction 200
```

---

### What Reader T1 Sees?

T1 started earlier.

```sql
SELECT * FROM emp;
```

Result:

| ID | Name  | Salary |
| -- | ----- | ------ |
| 1  | Ramya | 50000  |
| 2  | Sindu | 60000  |
| 3  | Jagan | 70000  |

T1 DOES NOT see:

```text
65000
```

Because its snapshot was taken before T2.

---

### What New Transaction T3 Sees?

After T2 commits:

```sql
COMMIT;
```

Now T3 starts.

```sql
SELECT * FROM emp;
```

Result:

| ID | Name  | Salary |
| -- | ----- | ------ |
| 1  | Ramya | 50000  |
| 2  | Sindu | 65000  |
| 3  | Jagan | 70000  |

New transaction sees new row version.

---

## Why No Locking?

In Oracle/MySQL SQL Server you may think:

```text
Reader wants row
Writer updating row
Reader waits
```

PostgreSQL MVCC says:

```text
Reader → old version
Writer → new version
```

Both work simultaneously.

---

## Visibility Rule Simplified

PostgreSQL asks:

```text
Can this transaction see this row version?
```

Example:

Old Row:

| ID | Salary | xmin | xmax |
| -- | ------ | ---- | ---- |
| 2  | 60000  | 100  | 200  |

New Row:

| ID | Salary | xmin | xmax |
| -- | ------ | ---- | ---- |
| 2  | 65000  | 200  | 0    |

For old transactions:

```text
Visible = Old Row
```

For new transactions:

```text
Visible = New Row
```

This is called Visibility Check.

---

## READ COMMITTED Example

Default isolation level.

Session 1:

```sql
BEGIN;

SELECT salary
FROM emp
WHERE id=2;
```

Output:

```text
60000
```

Session 2:

```sql
UPDATE emp
SET salary=65000
WHERE id=2;

COMMIT;
```

Session 1:

```sql
SELECT salary
FROM emp
WHERE id=2;
```

Output:

```text
65000
```

Why?

```text
Every statement gets a new snapshot.
```

---

## REPEATABLE READ Example

Session 1:

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT salary
FROM emp
WHERE id=2;
```

Output:

```text
60000
```

Session 2:

```sql
UPDATE emp
SET salary=65000
WHERE id=2;

COMMIT;
```

Session 1:

```sql
SELECT salary
FROM emp
WHERE id=2;
```

Output:

```text
60000
```

Still 60000.

Why?

```text
Same snapshot for entire transaction.
```

---

## Write Conflict Example

Row:

| ID | Salary |
| -- | ------ |
| 1  | 50000  |

Transaction 1:

```sql
UPDATE emp
SET salary=55000
WHERE id=1;
```

Transaction 2:

```sql
UPDATE emp
SET salary=60000
WHERE id=1;
```

Result:

```text
Transaction 2 waits.
```

Because:

```text
MVCC removes
READ vs WRITE conflict

MVCC does not remove
WRITE vs WRITE conflict
```

---

## Dead Tuples

After many updates:

Example:

```sql
UPDATE emp SET salary=51000;
UPDATE emp SET salary=52000;
UPDATE emp SET salary=53000;
UPDATE emp SET salary=54000;
```

Internally:

```text
50000  -> Dead
51000  -> Dead
52000  -> Dead
53000  -> Dead
54000  -> Live
```

PostgreSQL keeps old versions.

These old versions are called:

```text
Dead Tuples
```

---

## VACUUM

VACUUM removes dead tuples.

Before:

```text
50000 Dead
51000 Dead
52000 Dead
53000 Dead
54000 Live
```

After VACUUM:

```text
54000 Live
```

Old versions cleaned.

---

## Why pg_repack Is Needed?

Suppose table size:

```text
Actual Data = 20 GB
Dead Tuples = 80 GB
Table Size = 100 GB
```

VACUUM:

```text
Marks space reusable
```

But may not reduce file size.

pg_repack:

```text
Rebuilds table
Removes bloat
Shrinks size
```

Example:

```text
100 GB
↓
22 GB
```

---

### Interview Answer

**MVCC (Multi-Version Concurrency Control) allows PostgreSQL to maintain multiple versions of a row. Readers access old committed versions while writers create new versions, enabling readers and writers to work concurrently without read-write locking. Old versions become dead tuples and are cleaned by VACUUM.**
