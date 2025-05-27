# Multi-Tenant Application with Flask and Citus

A scalable, secure multi-tenant application leveraging Flask and Citus (distributed PostgreSQL) for efficient tenant isolation, sharding, and horizontal scaling.

## Table of Contents

- [Multi-Tenancy Overview](#multi-tenancy-overview)
- [Database Design](#database-design)
  - [Schema Overview](#schema-overview)
  - [Sharding Strategy](#sharding-strategy)
- [System Architecture](#system-architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup Instructions](#setup-instructions)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)
- [Citus Monitoring Guide with Docker Access](#citus-monitoring-guide-with-docker-access)
- [Contributing](#contributing)
- [Development Guide](#development-guide)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

## Multi-Tenancy Overview


This application provides a robust multi-tenant architecture with secure data isolation using Citus' sharding capabilities. Key features include:

- **Tenant Isolation**: Data separation via `tenant_id` sharding key
- **Horizontal Scaling**: Citus distributes data across worker nodes
- **Colocation**: Optimized joins for `users` and `notes` tables
- **Security**: Encrypted credentials and tenant-specific constraints

## Database Design

### Schema Overview

<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/7d6351f9d5111082dd764f5b124b6e5fac649477/images/schema_Diagram.drawio.png?raw=true" alt="Schema Diagram">

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

<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/42581ae744685afd4a6c75ff86235272933f18d1/images/shardingstrategy.svg" height='700' width='700'>

- **Hash-Based Sharding**: Uses `tenant_id` (for `users`) and `user_id` (for `notes`) as distribution keys
- **Colocation**: `notes` table is colocated with `users` for efficient joins
- **Reference Tables**: `tenants` table is replicated across all nodes

## System Architecture
### Web App workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/42581ae744685afd4a6c75ff86235272933f18d1/images/shardingstrategy.svg" height='700' width='700'>

- The client browser sends a **Request** to the Web Server.
- The Web Server forwards the **Request for Page Generation** to the Application Server.
- The Application Server processes the request and generates a **Dynamically Generated Page**.
- The **Dynamically Generated Page** is sent back to the Web Server.
- The Web Server sends the **Response** (containing the dynamically generated page) to the client browser.

### Application Layer Workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/42581ae744685afd4a6c75ff86235272933f18d1/images/shardingstrategy.svg" height='700' width='700'>

  - The Flask Server receives a **Request** from the Web Browser, typically an HTTP request (e.g., GET or POST) initiated by a user action like accessing a URL or submitting a form.
  - The request is routed to the appropriate handler using **routes.py**, which defines URL routes and maps them to specific functions (e.g., mapping `/home` to a homepage function).
  - The mapped **Functions** (written in Python) are executed, performing tasks such as:
    - Processing user inputs (e.g., form data).
    - Executing application logic or computations.
    - Preparing data for rendering or further processing.
  - If a webpage needs to be rendered, the function uses **Templates** (HTML files with embedded Python code via a templating engine like Jinja2). The function passes data to the template, which is rendered into a dynamic webpage.
  - If a redirect is required (e.g., after form submission), the function uses **Redirects** to send the browser to a new route.
  - The Flask Server sends the rendered webpage or redirect response back to the Web Browser for display.
  
### Database layer workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/42581ae744685afd4a6c75ff86235272933f18d1/images/shardingstrategy.svg" height='700' width='700'>

  - The client sends an **HTTP POST** request to the Flask App (running on port `web:5000`) with the endpoint `/api/notes` and a payload containing the note content (`content`) and user ID (`userid`).
  - The Flask App processes the request and sends an **SQL INSERT** statement to the database (Citrus-master5432) to insert the note into the `notes` table with the provided `content` and `userid`.
  - The database (Citrus-master5432) executes the SQL INSERT operation, stores the note, and returns a **Query Result** containing the `note_id` of the newly created note to the Flask App.
  - Simultaneously, the Flask App sends a message to the Citrus-worker via a message broker (e.g., RabbitMQ or Redis) with the route `insert_to_shared` and the payload containing the `note_id` and `userid`.
  - The Citrus-worker processes the message, performs any additional tasks (e.g., sharing the note with other users or systems), and sends an **Acknowledgement** back to the Flask App to confirm the operation.
  - The Flask App finalizes the request by returning a **JSON** response to the client, indicating the note has been created (`note_created`).

### Deployment layer workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/42581ae744685afd4a6c75ff86235272933f18d1/images/shardingstrategy.svg" height='700' width='700'>

- The process begins with a browser sending an **http://localhost:5000** request to access the web application hosted on the Host Machine.
- The Host Machine runs a **Docker Service**, which is responsible for containerizing and managing the application's components.
- Docker deploys the **Frontend** (represented by `webapp`), which receives the HTTP request. The Frontend's role is to handle the user interface and client-side logic.
- The Frontend initiates an **API call** to the **Backend**, which is also containerized within Docker. This call requests data or operations to be performed.
- The Backend, deployed as a separate container, processes the API call by performing **API Operations**. It interacts with a **DB** (database) to handle **Data Operations**, such as retrieving or storing data.
- The Backend sends an **API response** back to the Frontend with the requested data or operation result.
- The Frontend then generates a **response** and sends it back to the browser, completing the request cycle.
- Docker's role is critical as it:
  - Provides containerization, ensuring the Frontend and Backend run in isolated environments with their dependencies.
  - Simplifies deployment by packaging the application and its environment into portable containers.
  - Enables scalability and consistency across different Host Machines by managing these containers efficiently.
    
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


## API Endpoints

| Method | Endpoint         | Description                           |
|--------|------------------|---------------------------------------|
| POST   | `/api/register`  | Register a new tenant or user         |
| POST   | `/api/login`     | Authenticate user and return session  |
| GET    | `/api/notes`     | Retrieve notes for authenticated user |
| POST   | `/api/notes`     | Create a new note for authenticated user |


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

## Development Guide

Follow these guidelines for contributing to the project:

- Adhere to **PEP 8** for Python code style
- Run existing programs before submitting changes

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
