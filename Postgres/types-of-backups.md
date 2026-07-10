**"What backup types are available in PostgreSQL? When would you use each one?"**

The answer is divided into **Physical Backups** and **Logical Backups**.

---

## PostgreSQL Backup Types

```
PostgreSQL Backups
│
├── Physical Backup
│   ├── pg_basebackup
│   ├── File System Backup
│   ├── Continuous Archiving (WAL)
│   ├── PITR (Point-In-Time Recovery)
│   └── Storage Snapshot
│
└── Logical Backup
    ├── pg_dump
    ├── pg_dumpall
    ├── Table Backup
    ├── Schema Backup
    └── Data Only Backup
```

---

## 1. Physical Backup

A physical backup copies the actual PostgreSQL data files from disk.

It includes:

* Data files
* WAL files
* Indexes
* TOAST tables
* System catalogs
* Configuration (optional)

It is an exact copy of the database cluster.

```
Data Directory

PGDATA
│
├── base/
├── global/
├── pg_wal/
├── pg_tblspc/
├── pg_xact/
└── ...
```

---

## Advantages

* Very fast restore
* Supports PITR
* Suitable for large databases (TBs)
* Preserves everything

---

## Disadvantages

* Cannot restore individual tables
* PostgreSQL version must be compatible
* OS architecture should match

---

## Method 1: pg_basebackup

This is the recommended physical backup tool.

Example:

```bash
pg_basebackup \
-D /backup/basebackup \
-F p \
-X stream \
-P \
-U replicator
```

Options

```
-D    Destination

-F p  Plain format

-X stream

Copies WAL while taking backup

-P

Shows progress

-U

Replication user
```

---

Example output

```
waiting for checkpoint

305 GB copied

100%

Backup completed
```

---

Restore

Stop PostgreSQL

```bash
systemctl stop postgresql
```

Remove old data

```bash
rm -rf $PGDATA/*
```

Copy backup

```bash
cp -R /backup/basebackup/* $PGDATA
```

Start PostgreSQL

```bash
systemctl start postgresql
```

---

## Method 2: File System Backup

Stop PostgreSQL

```bash
systemctl stop postgresql
```

Copy data directory

```bash
cp -R $PGDATA /backup
```

Start PostgreSQL

```bash
systemctl start postgresql
```

This is called a **cold backup**.

---

## Method 3: Continuous WAL Archiving

Enable:

```conf
archive_mode = on

archive_command = 'cp %p /archive/%f'

wal_level = replica
```

Now every completed WAL file is archived.

```
WAL

00000001

↓

Archive Folder

↓

Recovery
```

---

## Point-In-Time Recovery (PITR)

Imagine:

```
09:00 Backup

↓

10:00 Insert

↓

11:00 Update

↓

12:00 Delete (Mistake)

↓

Need recovery to 11:55
```

PITR restores the database to any chosen time before the mistake.

Requirements

* Base backup
* WAL archive

Recovery example:

```conf
restore_command='cp /archive/%f %p'

recovery_target_time='2026-07-10 11:55:00'
```

Start PostgreSQL.

Database stops exactly at 11:55.

---

## Storage Snapshot

Cloud platforms support snapshots.

Examples

AWS

```
EBS Snapshot
```

Azure

```
Managed Disk Snapshot
```

GCP

```
Persistent Disk Snapshot
```

Very fast backup and restore.

---

## 2. Logical Backup

Logical backup exports SQL statements instead of copying data files.

Example:

```
CREATE TABLE

INSERT

ALTER

CREATE INDEX
```

Portable across versions.

---

## pg_dump

Backup one database.

Example

```bash
pg_dump -U postgres testdb > testdb.sql
```

Compressed format

```bash
pg_dump -Fc testdb -f testdb.dump
```

Restore

```bash
psql testdb < testdb.sql
```

or

```bash
pg_restore -d testdb testdb.dump
```

---

## pg_dump Formats

Plain SQL

```bash
pg_dump db > db.sql
```

Custom

```bash
pg_dump -Fc db > db.dump
```

Directory

```bash
pg_dump -Fd db
```

Tar

```bash
pg_dump -Ft db
```

---

## Parallel Backup

Directory format supports parallel jobs.

```bash
pg_dump \
-Fd \
-j 8 \
-f backup_dir mydb
```

Restore

```bash
pg_restore \
-j 8 \
-d mydb \
backup_dir
```

Very useful for large databases.

---

## pg_dumpall

Backs up the entire PostgreSQL cluster.

Includes

* All databases
* Roles
* Tablespaces
* Global objects

Example

```bash
pg_dumpall > cluster.sql
```

Restore

```bash
psql -f cluster.sql postgres
```

---

## Table-Level Backup

Backup only one table.

Example

```bash
pg_dump \
-t employees \
mydb \
> employees.sql
```

Restore

```bash
psql mydb < employees.sql
```

---

## Multiple Tables

```bash
pg_dump \
-t emp \
-t dept \
mydb > hr.sql
```

---

## Schema Backup

Only schema

```bash
pg_dump \
-s \
mydb > schema.sql
```

Output

```
CREATE TABLE

CREATE INDEX

CREATE VIEW
```

No data.

---

## Data Only Backup

```bash
pg_dump \
-a \
mydb > data.sql
```

Contains only INSERT/COPY statements.

---

## Schema Specific Backup

```bash
pg_dump \
-n hr \
mydb > hr.sql
```

---

## Exclude Table

```bash
pg_dump \
-T audit_log \
mydb > backup.sql
```

---

## Backup Specific Table with Data Only

```bash
pg_dump \
-t employees \
-a \
mydb > emp_data.sql
```

---

## Backup Specific Table Schema Only

```bash
pg_dump \
-t employees \
-s \
mydb > emp_schema.sql
```

---

## Common Interview Scenario

Suppose you have:

```
Database

finance

Tables

customers

accounts

transactions

audit_log
```

### Backup only `transactions`

```bash
pg_dump \
-t transactions \
finance > transactions.sql
```

### Backup only schema

```bash
pg_dump \
-s finance > finance_schema.sql
```

### Backup only data

```bash
pg_dump \
-a finance > finance_data.sql
```

### Exclude audit table

```bash
pg_dump \
-T audit_log finance > finance.sql
```

---

## Backup Verification

Check backup file:

```bash
ls -lh backup.dump
```

List objects in a custom backup:

```bash
pg_restore -l backup.dump
```

Verify SQL backup:

```bash
head backup.sql
```

You should see:

```sql
--
-- PostgreSQL database dump
--

CREATE TABLE employees (
    emp_id integer,
    name text
);
```

---

## Comparison Table

| Feature                 | Physical Backup | Logical Backup |
| ----------------------- | --------------- | -------------- |
| Backup Tool             | pg_basebackup   | pg_dump        |
| Includes Data Files     | ✅               | ❌           |
| Includes SQL            | ❌               | ✅           |
| Faster Restore          | ✅               | ❌           |
| Table-Level Restore     | ❌               | ✅           |
| PITR Support            | ✅               | ❌           |
| Cross-Version Migration | ❌               | ✅           |
| Large Databases         | ✅ Best          | ⚠️ Slower    |
| Selective Restore       | ❌               | ✅           |

---

### Real-Time Production Strategy

A common enterprise backup strategy is:

* **Weekly full physical backup** using `pg_basebackup`
* **Continuous WAL archiving** for Point-in-Time Recovery (PITR)
* **Daily logical backups** (`pg_dump`) for important databases or schema changes
* **Table-level logical backups** before major maintenance or deployments
* **Regular restore testing** in a non-production environment to verify backup integrity

