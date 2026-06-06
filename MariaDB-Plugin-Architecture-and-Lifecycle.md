### MySQL / MariaDB Plugin Architecture and Lifecycle

Database platforms such as MySQL and MariaDB are designed to be extensible. Instead of modifying the database source code, 
administrators can use plugins to add new capabilities such as authentication methods, audit logging, storage engines, replication technologies, 
password validation, encryption, and performance enhancements.

<img width="1237" height="1253" alt="mysqlmariadb arch" src="https://github.com/user-attachments/assets/e4386c19-a03a-4790-9441-a8c5e1993d17" />

### What is a Plugin?

A plugin is a dynamically loadable software module that extends the functionality of MySQL or MariaDB without recompiling the database server.

Examples:
• InnoDB Storage Engine
• Aria Storage Engine (MariaDB)
• Group Replication Plugin (MySQL)
• Galera Cluster Plugin (MariaDB)
• Audit Plugins
• Authentication Plugins
• Password Validation Plugins

Think of a plugin as an application installed inside the database server.

---

### Plugin Categories

#### 1. Storage Engine Plugins

Storage engines determine how data is physically stored and retrieved.

Examples:
• InnoDB (Default Transactional Engine)
• MyISAM
• Aria (MariaDB)
• Spider (MariaDB Distributed Engine)
• ColumnStore (MariaDB Analytics Engine)

Use Cases:
• OLTP Systems → InnoDB
• Analytics → ColumnStore
• Distributed Databases → Spider

---

#### 2. Authentication Plugins

Authentication plugins control how users log in to the database.

Examples:
• mysql_native_password
• caching_sha2_password
• ed25519
• unix_socket

Benefits:
• Stronger password security
• LDAP integration
• OS-level authentication

---

#### 3. Audit and Logging Plugins

These plugins track database activities.

Examples:
• MySQL Enterprise Audit
• MariaDB Server Audit

Captured Events:
• Logins
• Logouts
• DDL Statements
• DML Statements
• Privilege Changes

Useful for:
• Healthcare (EMR/EHR)
• Banking
• Pharmaceutical Companies (Example:- Pfizer, Novatis, Astazenica)

---

#### 4. Replication Plugins

Replication plugins provide high availability and disaster recovery.

MySQL:
• Group Replication
• Semi-Synchronous Replication

MariaDB:
• Galera Cluster
• Semi-Synchronous Replication

Benefits:
• Automatic failover
• Data redundancy
• High availability

---

#### 5. Password Validation Plugins

Enforce strong password policies.

Examples:
• validate_password
• simple_password_check

Rules:
• Minimum length
• Uppercase letters
• Lowercase letters
• Numbers
• Special characters

---

### Plugin Internal Architecture

The plugin architecture consists of four major components:

#### mysql.plugin Table

Stores information about installed plugins.

Purpose:
• Tracks installed plugins
• Loads plugins automatically after restart

---

#### Plugin Directory (plugin_dir)

Location where plugin libraries are stored.

Linux Example:

```text
/usr/lib64/mysql/plugin/
```

Files:

```text
validate_password.so
server_audit.so
auth_socket.so
```

---

#### Plugin Loader

Responsible for:

• Loading plugin libraries
• Registering plugins
• Initializing plugins

---

#### Active Plugins

Once loaded, plugins remain active in memory and provide services to the MySQL/MariaDB server.

---

### Plugin Lifecycle

#### Step 1: Install Plugin

Administrator installs plugin.

Example:

```sql
INSTALL PLUGIN validate_password
SONAME 'validate_password.so';
```

What Happens?

1. Plugin library located
2. Library loaded into memory
3. Plugin registered
4. Entry added into mysql.plugin

---

#### Step 2: Initialization

MySQL calls:

```text
plugin_init()
```

Responsibilities:

• Memory allocation
• Resource registration
• Internal setup

---

#### Step 3: Active State

Plugin becomes operational.

Examples:

Authentication Plugin:
• Validates users

Audit Plugin:
• Captures events

Replication Plugin:
• Synchronizes data

Storage Engine:
• Handles reads/writes

---

#### Step 4: Uninstall Plugin

Command:

```sql
UNINSTALL PLUGIN validate_password;
```

What Happens?

1. Stop plugin services
2. Release resources
3. Remove registration

---

#### Step 5: Cleanup

MySQL executes:

```text
plugin_deinit()
```

Responsibilities:

• Memory cleanup
• Close file handles
• Release resources

Plugin is then removed from memory.

---

### Useful Commands

#### Show Installed Plugins

```sql
SHOW PLUGINS;
```

---

#### Plugin Details

```sql
SELECT *
FROM INFORMATION_SCHEMA.PLUGINS;
```

---

#### Install Plugin

```sql
INSTALL PLUGIN plugin_name
SONAME 'plugin.so';
```

---

#### Remove Plugin

```sql
UNINSTALL PLUGIN plugin_name;
```

---

### MySQL vs MariaDB Plugin Comparison

#### Authentication

MySQL:
• caching_sha2_password

MariaDB:
• mysql_native_password
• ed25519
• unix_socket

---

#### Clustering

MySQL:
• Group Replication
• InnoDB Cluster

MariaDB:
• Galera Cluster

---

#### Audit

MySQL:
• Enterprise Audit (Commercial)

MariaDB:
• Server Audit (Community)

---

#### Additional Storage Engines

MySQL:
• InnoDB
• MyISAM

MariaDB:
• Aria
• Spider
• ColumnStore
• CONNECT

---

#### Proxy Layer

MySQL:
• MySQL Router

MariaDB:
• MaxScale

---

### Interview Questions

Q: What is a MySQL plugin?

A: A plugin is a loadable module that extends MySQL functionality without modifying the server source code.

Q: Where are plugins stored?

A: In the plugin_dir location as .so files on Linux or .dll files on Windows.

Q: Which table stores installed plugin information?

A: mysql.plugin

Q: Which command displays installed plugins?

A: SHOW PLUGINS;

Q: What are common plugin types?

A: Storage Engine, Authentication, Audit, Replication, Encryption, and Password Validation plugins.

Q: What is the difference between MySQL and MariaDB clustering plugins?

A: MySQL uses Group Replication/InnoDB Cluster, whereas MariaDB uses Galera Cluster.

---



