# Multi-Tenant Application with Flask and Citus

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/flask-2.0+-green.svg)](https://flask.palletsprojects.com/)

A scalable multi-tenant application demonstrating distributed PostgreSQL (Citus) integration with proper sharding strategies, tenant isolation, and optimized query patterns.

## 📌 Features

- **Multi-tenancy Architecture**: Secure tenant isolation at database level
- **Horizontal Scaling**: Distributed PostgreSQL using Citus extension
- **Efficient Sharding**: 
  - Tenants distributed across worker nodes
  - Colocated related tables (users ↔ notes)
- **Modern Stack**:
  - Flask web framework
  - SQLAlchemy ORM with Citus extensions
  - Docker containerization

## 📂 Project Structure
 ``` .flaskenv
  │   config.py
  │   docker-compose.yml
  │   Dockerfile
  │   requirements.txt
  │   wait-for-db.sh
  │
  ├───app
  │   │   extensions.py
  │   │   models.py
  │   │   routes.py
  │   │   utils.py
  │   │   **init**.py
  │   │
  │   ├───static
  │   │   └───css
  │   │           style.css
  │   │
  │   ├───templates
  │   │       base.html
  │   │       dashboard.html
  │   │       login.html
  │   │       notes.html
  │   │       register.html
  │   │
  │   └───**pycache**
  │           extensions.cpython-39.pyc
  │           models.cpython-39.pyc
  │           routes.cpython-39.pyc
  │           **init**.cpython-39.pyc
  │
  ├───docker-entrypoint-initdb.d
  │       init.sql
  │
  └───**pycache**
          config.cpython-39.pyc
```

## 🛠️ Installation

### Prerequisites
- Docker 20.10+
- Docker Compose 1.29+
- Python 3.9+

### Setup
```bash
# Clone repository
git clone [https://github.com/your-repo/flask-citus-app.git](https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus.git)
cd flask-citus-app

# Build and start containers
docker-compose up -d

```
##  Database Architecture

### Schema Diagram
<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/7d6351f9d5111082dd764f5b124b6e5fac649477/images/schema_Diagram.drawio.png?raw=true" alt="Schema Diagram" width="600" /> 
*Figure 1: Visual representation of our schema diagram*

### Sharding Strategy
<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/sharding_strategy.png" alt="Schema Diagram" width="600" height="400"/> 
- *Figure 2: Visual representation of our sharding distribution strategy*

- **Hashing Strategy**: Citus employs(by default) a hash-based sharding strategy for distributed tables (`users`, `notes`). The sharding key (`tenant_id` for `users`, `user_id` for `notes`) is hashed using a consistent hashing algorithm to assign data to shards, which are distributed across the Citus cluster’s worker nodes. This ensures even data distribution and scalability. The `notes` table is colocated with `users` on the same shards for efficient joins, while `tenants` is replicated across all nodes as a reference table.

### Table Distribution
![Table Diagram](https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/Capture.JPG)  
*Figure 3: Reference and shard key table*

#### shared.tenants (Reference Table)
- **Columns**:
  - `id`: Primary key
  - `name`: Unique identifier
  - `created_at`: Timestamp
- **Type**: Reference table (replicated to all nodes)
- **Purpose**: Central repository for tenant metadata

#### shared.users (Distributed Table)
- **Columns**:
  - `id`: User identifier
  - `tenant_id`: Composite primary key component
  - `username`: Unique within tenant
  - `email`: Unique within tenant  
  - `password`: Encrypted credential
  - `created_at`: Timestamp
- **Type**: Distributed (sharded by tenant_id)
- **Constraints**:
  - Unique username per tenant
  - Unique email per tenant
  - References shared.tenants.id
- **Purpose**: Tenant-isolated user storage

#### notes (Colocated Table)
- **Columns**:
  - `id`: Primary key
  - `content`: Note text
  - `user_id`: References shared.users.id
  - `created_at`: Timestamp
  - `updated_at`: Modification timestamp
- **Type**: Distributed (sharded by user_id)
- **Colocation**: Physically grouped with user data
- **Purpose**: User-generated content storage

## 🌐 System Architecture

### System Diagram
<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/46f1babb921d39c11d9432bf975f07320ef963d8/images/systemarchitecture.JPG" alt="Schema Diagram" width="900" height="600"/>
*Figure 4: Visual representation of our system architecture*

- **Web Layer**: Flask application (stateless)
- **Data Layer**: Citus cluster (1 coordinator + N workers)
- **Isolation**: Tenant separation via sharding key

## 🚀 Citus Monitoring Guide with Docker Access

This guide explains how to monitor your **Citus database cluster** from within Docker containers. We'll start by accessing the relevant Docker container, then run SQL queries to track shard activity and performance.

---

### 🐳 Step 1: View Running Docker Containers

List all running containers:

```bash
docker ps
```

---

### 📦 Step 2: Access the Citus Master Container

Identify the container name for your **Citus master**, then enter its shell:

```bash
docker exec -it <container_name> bash
```

Replace `<container_name>` with your actual container ID or name (e.g., `citus_master`).

---

### 🐘 Step 3: Connect to PostgreSQL Inside Container

Run the following command inside the container to access PostgreSQL:

```bash
psql -U postgres -d your_database_name
```

Replace `your_database_name` with your actual database name.

---

### 📡 Step 4: Monitor Shard Activity & Cluster Health

Once inside PostgreSQL, use the following SQL commands:

---

### 🔍 1. List Distributed Tables

```sql
SELECT * FROM citus_tables;
```

---

### 📊 2. View Shard Placements

See shard distribution across the cluster:

```sql
SELECT * FROM pg_dist_shard;
```

Check where shards are placed:

```sql
SELECT * FROM pg_dist_placement;
```

---

### 📦 3. Get Shard Sizes

```sql
SELECT * FROM citus_stat_shards;
```

---

### 🔁 4. Monitor Active Queries

```sql
SELECT * FROM pg_stat_activity WHERE datname = 'your_database_name';
```

---

### 🔗 5. Check Worker Node Status

```sql
SELECT * FROM pg_dist_node;
```

---

### 🧠 6. Colocation & Distribution Strategy

```sql
SELECT logicalrelid, colocationid, distribution_column 
FROM pg_dist_partition;
```

---

### 📈 7. Track Query Performance (Optional)

Enable `pg_stat_statements` to view slow or heavy queries:

```sql
SELECT query, calls, total_time, rows 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;
```




## Contributing

- Submit issues or pull requests via [GitHub Issues](https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/issues).
- Follow **PEP 8** guidelines for Python code style.
- Ensure all existing and new tests pass before submitting.
- Add new tests under the `tests/` directory *(to be implemented)*.

## License

This project is licensed under the **MIT License**.  
See the [LICENSE](./LICENSE) file for details.

## Contact

For any issues, suggestions, or questions, please contact the maintainers via:

- GitHub: [Bahar0900](https://github.com/Bahar0900)
- Email: `sagormdsagorchowdhury@example.com`

## Acknowledgments

- **Flask** – for the lightweight web framework  
- **Citus** – for distributed PostgreSQL support  
- **SQLAlchemy** – for seamless ORM integration  
- **Docker** – for containerized development and deployment
