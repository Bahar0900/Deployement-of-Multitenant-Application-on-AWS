# Multi-Tenant Application with Flask and Citus

A scalable, secure multi-tenant application leveraging Flask and Citus (distributed PostgreSQL) for efficient tenant isolation, sharding, and horizontal scaling.

## Table of Contents

- [Multi-Tenancy Overview](#multi-tenancy-overview)
- [System Architecture](#system-architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup Instructions](#setup-instructions)
- [Database Design](#database-design)
  - [Schema Overview](#schema-overview)
  - [Sharding Strategy](#sharding-strategy)
- [API Endpoints](#api-endpoints)
- [Development Guide](#development-guide)
- [Troubleshooting](#troubleshooting)
- [Citus Monitoring Guide with Docker Access](#citus-monitoring-guide-with-docker-access)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

## Multi-Tenancy Overview

<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/7d6351f9d5111082dd764f5b124b6e5fac649477/images/schema_Diagram.drawio.png?raw=true" alt="Schema Diagram">

This application provides a robust multi-tenant architecture with secure data isolation using Citus' sharding capabilities. Key features include:

- **Tenant Isolation**: Data separation via `tenant_id` sharding key
- **Horizontal Scaling**: Citus distributes data across worker nodes
- **Colocation**: Optimized joins for `users` and `notes` tables
- **Security**: Encrypted credentials and tenant-specific constraints

## System Architecture

<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/46f1babb921d39c11d9432bf975f07320ef963d8/images/systemarchitecture.JPG" alt="System Architecture">

### Components

- **Flask Application**: Stateless REST API for tenant and user management
- **Citus Cluster**: Distributed PostgreSQL with one coordinator and multiple worker nodes
- **Docker**: Containerized environment for consistent deployment
- **SQLAlchemy**: ORM with Citus extensions for seamless database interactions

## Getting Started

### Prerequisites

- Docker 20.10+
- Docker Compose 1.29+
- Python 3.9+
- Git

### Setup Instructions

1. **Clone the Repository**:

    ```bash
    git clone https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus.git
    cd MultiTenant-Application-with-Flask-and-Citus
    ```

2. **Configure Environment Variables**:

    Create a `.env` file in the project root:

    ```properties
    DATABASE_URL=postgresql://postgres:password@citus_master:5432/your_database_name
    FLASK_ENV=development
    SECRET_KEY=your-secure-flask-key
    ```

3. **Start Docker Containers**:

    ```bash
    docker-compose up -d
    ```

4. **Initialize Database Schema**:

    The `docker-entrypoint-initdb.d/init.sql` script automatically sets up the schema on container startup.

5. **Verify Services**:

    - Flask API: [http://localhost:5000](http://localhost:5000)
    - Citus cluster health: See [Citus Monitoring Guide](#citus-monitoring-guide-with-docker-access)

## Database Design

### Schema Overview

<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/Capture.JPG" alt="Table Diagram">

The database consists of three main tables:

- **shared.tenants** (Reference Table):
  - Columns: `id`, `name`, `created_at`
  - Replicated across all nodes for fast access
- **shared.users** (Distributed Table):
  - Columns: `id`, `tenant_id`, `username`, `email`, `password`, `created_at`
  - Sharded by `tenant_id` with unique constraints per tenant
- **notes** (Distributed Table):
  - Columns: `id`, `content`, `user_id`, `created_at`, `updated_at`
  - Sharded by `user_id`, colocated with `users`

### Sharding Strategy

<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/sharding_strategy.png" alt="Sharding Strategy">

- **Hash-Based Sharding**: Uses `tenant_id` (for `users`) and `user_id` (for `notes`) as distribution keys
- **Colocation**: `notes` table is colocated with `users` for efficient joins
- **Reference Tables**: `tenants` table is replicated across all nodes

## API Endpoints

| Method | Endpoint         | Description                           |
|--------|------------------|---------------------------------------|
| POST   | `/api/register`  | Register a new tenant or user         |
| POST   | `/api/login`     | Authenticate user and return session  |
| GET    | `/api/notes`     | Retrieve notes for authenticated user |
| POST   | `/api/notes`     | Create a new note for authenticated user |

## Development Guide

Follow these guidelines for contributing to the project:

- Adhere to **PEP 8** for Python code style
- Write tests under the `tests/` directory (to be implemented)
- Run existing tests before submitting changes

## Troubleshooting

- **Database Connection Issues**:

    ```bash
    docker-compose exec citus_master psql -U postgres -d your_database_name -c "SELECT 1"
    ```

- **Check Container Logs**:

    ```bash
    docker-compose logs citus_master
    ```

- **Reset Containers and Data**:

    ```bash
    docker-compose down -v
    docker-compose up -d
    ```

## Citus Monitoring Guide with Docker Access

This guide explains how to monitor your **Citus database cluster** from within Docker containers. We'll start by accessing the relevant Docker container, then run SQL queries to track shard activity and performance.

### 🐳 Step 1: View Running Docker Containers

List all running containers:

```bash
docker ps
```

### 📦 Step 2: Access the Citus Master Container

Identify the container name for your **Citus master**, then enter its shell:

```bash
docker exec -it <container_name> bash
```

Replace `<container_name>` with your actual container ID or name (e.g., `citus_master`).

### 🐘 Step 3: Connect to PostgreSQL Inside Container

Run the following command inside the container to access PostgreSQL:

```bash
psql -U postgres -d your_database_name
```

Replace `your_database_name` with your actual database name.

### 📡 Step 4: Monitor Shard Activity & Cluster Health

Once inside PostgreSQL, use the following SQL commands:

- **🔍 1. List Distributed Tables**

    ```sql
    SELECT * FROM citus_tables;
    ```

- **📊 2. View Shard Placements**

    See shard distribution across the cluster:

    ```sql
    SELECT * FROM pg_dist_shard;
    ```

    Check where shards are placed:

    ```sql
    SELECT * FROM pg_dist_placement;
    ```

- **📦 3. Get Shard Sizes**

    ```sql
    SELECT * FROM citus_stat_shards;
    ```

- **🔁 4. Monitor Active Queries**

    ```sql
    SELECT * FROM pg_stat_activity WHERE datname = 'your_database_name';
    ```

- **🔗 5. Check Worker Node Status**

    ```sql
    SELECT * FROM pg_dist_node;
    ```

- **🧠 6. Colocation & Distribution Strategy**

    ```sql
    SELECT logicalrelid, colocationid, distribution_column 
    FROM pg_dist_partition;
    ```

- **📈 7. Track Query Performance (Optional)**

    Enable `pg_stat_statements` to view slow or heavy queries:

    ```sql
    SELECT query, calls, total_time, rows 
    FROM pg_stat_statements 
    ORDER BY total_time DESC 
    LIMIT 10;
    ```

## Contributing

Contributions are welcome! Please:

- Submit issues or pull requests via [GitHub Issues](https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/issues)
- Follow **PEP 8** guidelines
- Ensure all tests pass

## License

MIT License. See the [LICENSE](./LICENSE) file for details.

## Contact

- GitHub: [Bahar0900](https://github.com/Bahar0900)
- Email: `sagormdsagorchowdhury@gmail.com`

## Acknowledgments

- **Flask**: Lightweight web framework
- **Citus**: Distributed PostgreSQL extension
- **SQLAlchemy**: ORM for database interactions
- **Docker**: Containerization platform
