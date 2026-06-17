### What Happens Internally When MySQL Executes a Insert & Update Statement? 

---- 
For **INSERT** and **UPDATE** in MySQL (InnoDB), the flow is different from SELECT because MySQL must maintain **ACID properties**, 
generate **Undo Logs**, **Redo Logs**, and eventually write changes to disk.

<img width="1536" height="1020" alt="mysql-insert-update" src="https://github.com/user-attachments/assets/2e04f02e-85c8-490a-9be5-2bac2b99c31e" />


---

## INSERT Flow

Example:

```sql
INSERT INTO emp(emp_id,name,salary) VALUES(101,'Ramya',50000);
```

### Internal Flow

```text
Client
   ↓
Connection Manager
   ↓
SQL Parser
   ↓
Preprocessor
   ↓
Optimizer
   ↓
Execution Engine
   ↓
InnoDB Storage Engine
   ↓
Check Constraints
   ↓
Acquire Required Locks
   ↓
Generate Undo Log
   ↓
Insert Row into Buffer Pool
   ↓
Generate Redo Log
   ↓
Commit
   ↓
Flush Redo Log to ib_logfile
   ↓
Acknowledge Success
   ↓
Client
```

### What Happens Internally?

#### 1. Undo Log Generated

Before modifying data, InnoDB creates an Undo Record.

Purpose:

* Rollback support
* MVCC Consistent Reads

#### 2. Data Written to Buffer Pool

```text
Memory (Buffer Pool)
     ↓
Modified Page
```

Data is initially changed in memory, not directly in the data file.

#### 3. Redo Log Generated

```text
Redo Log Buffer
      ↓
ib_redo files
```

Purpose:

* Crash Recovery
* Durability

#### 4. Commit

```sql
COMMIT;
```

At commit time:

```text
Redo Log Buffer
      ↓
Redo Log Files
```

If MySQL crashes after commit, Redo Logs can recover committed transactions.

#### 5. Background Flush

Later:

```text
Dirty Pages
      ↓
.ibd Data Files
```

A background thread writes modified pages to disk.

---

## UPDATE Flow

Example:

```sql
UPDATE emp
SET salary=70000
WHERE name='Ramya';
```

---

### Internal Flow

```text
Client
   ↓
Connection Manager
   ↓
Parser
   ↓
Preprocessor
   ↓
Optimizer
   ↓
Locate Rows
   ↓
InnoDB Engine
   ↓
Row Lock
   ↓
Create Undo Log
   ↓
Modify Buffer Pool Page
   ↓
Create Redo Log
   ↓
Commit
   ↓
Flush Redo Log
   ↓
Return Success
```

---

## UPDATE Detailed Example

Current Row:

```text
emp_id = 101
name   = Ramya
salary = 50000
```

Query:

```sql
UPDATE emp SET salary=70000 WHERE emp_id=101;
```

### Step 1: Locate Row

Using:

```text
Primary Key Index
or
Secondary Index
```

### Step 2: Lock Row

```text
Exclusive Lock (X Lock)
```

Other transactions cannot modify the row.

### Step 3: Create Undo Record

```text
Before Image

salary = 50000
```

Stored in Undo Segment.

### Step 4: Modify Buffer Pool

```text
Before: 50000
After : 70000
```

Page becomes Dirty Page.

### Step 5: Generate Redo Record

```text
Change Salary
50000 → 70000
```

Stored in Redo Log Buffer.

### Step 6: Commit

Redo Log flushed to disk.

### Step 7: Background Flush

Dirty Page eventually written to:

```text
emp.ibd
```

---

## INSERT Architecture

```text
Client
   ↓
Parser
   ↓
Optimizer
   ↓
InnoDB
   ↓
Undo Log
   ↓
Buffer Pool
   ↓
Redo Log Buffer
   ↓
Redo Log File
   ↓
Commit
   ↓
Dirty Page
   ↓
.ibd File
```

---

## UPDATE Architecture

```text
Client
   ↓
Parser
   ↓
Optimizer
   ↓
Find Row
   ↓
Row Lock
   ↓
Undo Log
   ↓
Buffer Pool Update
   ↓
Redo Log
   ↓
Commit
   ↓
Dirty Page
   ↓
.ibd File
```

### Interview One-Line Answer

**INSERT/UPDATE flow in MySQL InnoDB:** Client → Parser → Optimizer → InnoDB → Row Lock → Undo Log → Buffer Pool Modification → Redo Log Generation → Commit → Redo Log Flush → Background Flush of Dirty Pages to `.ibd` files.
