## Important PostgreSQL extensions for DBAs and developers. It provides **cryptographic functions** inside PostgreSQL, 
allowing you to encrypt, decrypt, hash, generate random bytes, and create UUIDs (in newer PostgreSQL versions, UUID generation is typically handled by 
built-in functions rather than `pgcrypto`).

---

## What is pgcrypto?

`pgcrypto` is a PostgreSQL extension that adds cryptographic functions to the database.

Without `pgcrypto`, PostgreSQL cannot perform operations such as:

* Encrypting sensitive columns
* Decrypting encrypted values
* Hashing passwords
* Generating secure random bytes
* Creating message digests (SHA-256, SHA-512, etc.)

It is widely used in banking, healthcare, insurance, fintech, and government applications.
<img width="1536" height="995" alt="ChatGPT Image Jul 8, 2026, 06_51_40 PM" src="https://github.com/user-attachments/assets/fa827bb2-7a42-4295-b77f-6a31813e32e2" />

---

## Why do we need pgcrypto?

Imagine you have a customer table.

Without encryption:

| Customer | Credit Card      |
| -------- | ---------------- |
| Ram      | 4111903611116564 |
| Sita     | 5555987655554004 |

Anyone with SELECT permission can read the card numbers.

```sql
SELECT * FROM customers;
```

Output:

```
Ram    4111111111111111
Sita   5555555555554444
```

This is a major security risk.

---

With `pgcrypto`, the values are stored in encrypted form.

```
Ram
\x3f8abf90cd8...

Sita
\x8fe74da44ab...
```

Even if someone accesses the database files or executes a query, they cannot read the actual card numbers without the encryption key.

---

## When should we use pgcrypto?

Typical use cases include:

* Credit card numbers
* Aadhaar numbers
* PAN numbers
* Passport numbers
* Social Security Numbers
* API keys
* Secret tokens
* Medical records
* Salary information
* Customer PII (Personally Identifiable Information)

---

## From which PostgreSQL version is pgcrypto available?

`pgcrypto` has been available for many years as part of PostgreSQL's contributed extensions.

It is supported in all modern PostgreSQL releases, including:

* PostgreSQL 9.6
* PostgreSQL 10
* PostgreSQL 11
* PostgreSQL 12
* PostgreSQL 13
* PostgreSQL 14
* PostgreSQL 15
* PostgreSQL 16
* PostgreSQL 17
* PostgreSQL 18

---

# How to check whether it is installed?

```sql
SELECT * FROM pg_extension;
```

If you see:

```
pgcrypto
```

then it is installed.

---

## Check whether it is available

```sql
SELECT * FROM pg_available_extensions WHERE name='pgcrypto';
```

---

# How to install pgcrypto

You need superuser privileges.

```sql
CREATE EXTENSION pgcrypto;
```

Verify:

```sql
SELECT extname FROM pg_extension;
```

Output:

```
pgcrypto
```

---

## Main Functions

## 1. digest()

Creates a hash.

```sql
SELECT digest('hello','sha256');
```

Returns binary output.

To display as hexadecimal:

```sql
SELECT encode(
       digest('hello','sha256'),
       'hex');
```

Output:

```
2cf24dba5fb0...
```

---

## 2. crypt()

Hashes passwords.

```sql
SELECT crypt(
'password123',
gen_salt('bf'));
```

Output:

```
$2a$06$....
```

---

Password verification:

```sql
SELECT crypt(
'password123',
stored_password)
=
stored_password;
```

Returns

```
true
```

---

## 3. gen_salt()

Generates a secure random salt.

```sql
SELECT gen_salt('bf');
```

Example:

```
$2a$06$...
```

---

## 4. encrypt()

Encrypts binary data.

```sql
SELECT encrypt(
'hello'::bytea,
'1234567890123456',
'aes');
```

---

## 5. decrypt()

Decrypts encrypted binary data.

```sql
SELECT decrypt(
encrypted_value,
'1234567890123456',
'aes');
```

---

## 6. pgp_sym_encrypt()

Encrypts text using a password.

This is the most commonly used function for application data.

```sql
SELECT pgp_sym_encrypt(
'4111111111111111',
'mySecretKey');
```

Output:

```
Binary encrypted data
```

---

## 7. pgp_sym_decrypt()

Decrypts encrypted values.

```sql
SELECT pgp_sym_decrypt(
encrypted_column,
'mySecretKey');
```

Returns

```
4111111111111111
```

---

## Real Banking Example

Create a table.

```sql
CREATE TABLE customer_cards
(
    customer_id INT,
    customer_name TEXT,
    credit_card BYTEA
);
```

---

Insert encrypted data.

```sql
INSERT INTO customer_cards
VALUES
(
1,
'Ram',
pgp_sym_encrypt(
'4111903611116564',
'BankKey123')
);
```

---

See stored data.

```sql
SELECT * FROM customer_cards;
```

Output:

```
1

Ram

\xc30ffea81ab...
```

Notice that the card number is unreadable.

---

Retrieve the original value.

```sql
SELECT
customer_name,
pgp_sym_decrypt(
credit_card,
'BankKey123')
AS credit_card
FROM customer_cards;
```

Output:

| Customer | Credit Card      |
| -------- | ---------------- |
| Ram      | 4111111111111111 |

---

## Multiple Customers Example

```sql
INSERT INTO customer_cards
VALUES
(
2,
'Sita',
pgp_sym_encrypt(
'5555555555554444',
'BankKey123')
);

INSERT INTO customer_cards
VALUES
(
3,
'John',
pgp_sym_encrypt(
'4000123412341234',
'BankKey123')
);
```

Retrieve:

```sql
SELECT
customer_name,
pgp_sym_decrypt(
credit_card,
'BankKey123')
FROM customer_cards;
```

---

## Wrong Key Example

```sql
SELECT
pgp_sym_decrypt(
credit_card,
'WrongKey')
FROM customer_cards;
```

Output:

```
ERROR:

Wrong key or corrupt data
```

---

## Real Enterprise Architecture

```
Application
     │
     │ Customer enters credit card
     ▼
Application encrypts (or calls pgp_sym_encrypt)
     │
     ▼
PostgreSQL (pgcrypto)
     │
Encrypted BYTEA
     │
     ▼
Disk Backup / WAL / Replication
```

Even if someone steals the database files or backups, the encrypted data cannot be read without the correct key.

---

## Best Practices

* **Do not hard-code encryption keys** in SQL statements or application source code.
* Store encryption keys in a secure secrets manager such as HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, or Google Secret Manager.
* Use strong, unique keys and rotate them periodically.
* Encrypt only sensitive columns rather than every column, to reduce CPU overhead.
* Restrict decryption permissions so only authorized roles or application services can access plaintext.
* Test backup, restore, and key rotation procedures as part of disaster recovery.

---

## Interview Questions

**1. What is `pgcrypto`?**
A PostgreSQL extension that provides cryptographic functions such as encryption, decryption, hashing, and random data generation.

**2. Why use `pgcrypto` instead of storing plaintext?**
It protects sensitive information (for example, credit card numbers and personal identifiers) from unauthorized access, including if database files or backups are exposed.

**3. What is the difference between hashing and encryption?**

* **Hashing** (for example, `crypt()` or `digest()`) is one-way and is used for passwords or integrity checks.
* **Encryption** (for example, `pgp_sym_encrypt()`) is reversible with the correct key and is used when the original value must be retrieved.

**4. Which function is commonly used to encrypt sensitive text?**
`pgp_sym_encrypt()`.

**5. Which function decrypts encrypted data?**
`pgp_sym_decrypt()`.

**6. What happens if the wrong key is used for decryption?**
PostgreSQL raises an error indicating the key is incorrect or the data is corrupt.

**7. Does `pgcrypto` encrypt the entire database?**
No. It provides column-level cryptographic functions. Full-database or storage-level encryption is handled by operating systems, disk encryption, or external technologies, not by `pgcrypto`.

For PostgreSQL DBAs, `pgcrypto` is considered the standard choice when an application requires **column-level encryption of sensitive data** while still allowing authorized users or applications to decrypt it when needed.
