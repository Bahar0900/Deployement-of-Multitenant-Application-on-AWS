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

<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/42581ae744685afd4a6c75ff86235272933f18d1/images/shardingstrategy.svg" height='500' width='500'>

- **Hash-Based Sharding**: Uses `tenant_id` (for `users`) and `user_id` (for `notes`) as distribution keys
- **Colocation**: `notes` table is colocated with `users` for efficient joins
- **Reference Tables**: `tenants` table is replicated across all nodes

## System Architecture
### Web App workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/f3469419da650db07fd38e63153da013a94c58cb/images/completesystem.drawio.svg" >

- The client browser sends a **Request** to the Web Server.
- The Web Server forwards the **Request for Page Generation** to the Application Server.
- The Application Server processes the request and generates a **Dynamically Generated Page**.
- The **Dynamically Generated Page** is sent back to the Web Server.
- The Web Server sends the **Response** (containing the dynamically generated page) to the client browser.

### Application Layer Workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/1b01446f3c9f228d32efec17e7b0253e42cbc0d5/images/flaskserver.drawio%20(1).svg">

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
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/7232ecb1d0cce22f2cac0ea912147c6d50b26639/images/citus.drawio%20(1).svg">

  - The client sends an **HTTP POST** request to the Flask App (running on port `web:5000`) with the endpoint `/api/notes` and a payload containing the note content (`content`) and user ID (`userid`).
  - The Flask App processes the request and sends an **SQL INSERT** statement to the database (Citrus-master5432) to insert the note into the `notes` table with the provided `content` and `userid`.
  - The database (Citrus-master5432) executes the SQL INSERT operation, stores the note, and returns a **Query Result** containing the `note_id` of the newly created note to the Flask App.
  - Simultaneously, the Flask App sends a message to the Citrus-worker via a message broker (e.g., RabbitMQ or Redis) with the route `insert_to_shared` and the payload containing the `note_id` and `userid`.
  - The Citrus-worker processes the message, performs any additional tasks (e.g., sharing the note with other users or systems), and sends an **Acknowledgement** back to the Flask App to confirm the operation.
  - The Flask App finalizes the request by returning a **JSON** response to the client, indicating the note has been created (`note_created`).

### Deployment layer workflow
<img src="https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus/blob/9984a80c0cf7b017b51366f2e5d33538deecf860/images/docker.drawio.svg">

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

- **Docker** 20.10+ (required for containerized services)
- **Docker Compose** 1.29+ (for managing multi-container setup)
- **Python** 3.9+ (for running Flask application)
- **Git** (for cloning the repository)
- **curl** (for testing API endpoints)
- **psql** (optional, for manual database interaction)

Ensure these tools are installed on your system before proceeding. You can verify Docker and Docker Compose versions with:

```bash
docker --version
docker-compose --version
```

### Setup Instructions

1. **Clone the Repository**:

   Clone the project repository and navigate into the project directory:

   ```bash
   git clone https://github.com/poridhioss/MultiTenant-Application-with-Flask-and-Citus.git
   cd MultiTenant-Application-with-Flask-and-Citus
   ```

2. **Configure Environment Variables**:

   Create a `.env` file in the project root to configure the application and database settings:

   ```bash
   touch .env
   ```

   Add the following environment variables to the `.env` file:

   ```properties
   DATABASE_URL=postgresql://postgres:password@citus_master:5432/tenant_db
   FLASK_ENV=development
   SECRET_KEY=your-secure-flask-key
   ```

   - `DATABASE_URL`: Connection string for the Citus database (adjust `password` and `tenant_db` as needed).
   - `FLASK_ENV`: Set to `development` for debugging; use `production` in a live environment.
   - `SECRET_KEY`: A secure key for Flask session management (generate a random string).

3. **Start Docker Containers**:

   Launch the Citus cluster, Flask application, and worker services using Docker Compose:

   ``bash
   docker-compose up -d
   ``

   This command starts:
   - `citus_master`: The Citus coordinator node.
   - `citus_worker`: Worker nodes for distributed data storage.
   - `web`: The Flask application running on port 5000.

4. **Initialize Database Schema**:

   The repository includes a `docker-entrypoint-initdb.d/init.sql` script that automatically sets up the schema and Citus distribution on container startup. This script:
   - Creates the `tenant_db` database.
   - Sets up tables (e.g., `notes`) with a `tenant_id` column for multi-tenancy.
   - Distributes tables across the Citus cluster using `create_distributed_table`.

   To manually verify the schema, connect to the Citus master node:

   ```bash
   docker-compose exec citus_master psql -U postgres -d tenant_db -c "\dt"
   ```

   This lists the tables in the `tenant_db` database. You should see tables like `notes` with a `tenant_id` column.

5. **Set Up Citus Worker Nodes**:

   The Citus cluster requires worker nodes to be registered with the master node. The `docker-compose.yml` file likely includes a script to handle this, but you can manually verify or add workers:

   ```bash
   docker-compose exec citus_master psql -U postgres -d tenant_db -c "SELECT * FROM master_add_node('citus_worker', 5432);"
   ```

   This ensures the worker node is added to the Citus cluster for data distribution.

6. **Verify Services**:

   Check that all services are running correctly:
   - **Flask API**: Access the Flask application at [http://localhost:5000](http://localhost:5000). You should see a welcome message or the application's homepage.
   - **Citus Cluster Health**: Verify the Citus cluster by checking the node status:

   ```bash
   docker-compose exec citus_master psql -U postgres -d tenant_db -c "SELECT * FROM citus_get_active_worker_nodes();"
   ```

   This should list the active worker nodes in the Citus cluster.

7. **Test API Endpoints with curl**:

   Use `curl` to test the API endpoints and ensure the application is functioning as expected.

   - **Register a new tenant or user**:

   ```bash
   curl -X POST http://localhost:5000/api/register \
   -H "Content-Type: application/json" \
   -d '{"username": "testuser", "password": "testpass", "tenant_id": 1}'
   ```

   Expected response: A JSON object with the user ID and a success message, e.g., `{"user_id": 1, "message": "User registered successfully"}`.

   - **Login to authenticate a user**:

   ```bash
   curl -X POST http://localhost:5000/api/login \
   -H "Content-Type: application/json" \
   -d '{"username": "testuser", "password": "testpass"}'
   ```

   Expected response: A JSON object with a session token, e.g., `{"token": "your-session-token"}`. Save this token for authenticated requests.

   - **Create a new note for the authenticated user**:

   ```bash
   curl -X POST http://localhost:5000/api/notes \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer your-session-token" \
   -d '{"content": "This is a test note", "tenant_id": 1}'
   ```

   Expected response: A JSON object with the note ID, e.g., `{"note_id": 1, "message": "Note created successfully"}`.

   - **Retrieve notes for the authenticated user**:

   ```bash
   curl -X GET http://localhost:5000/api/notes \
   -H "Authorization: Bearer your-session-token"
   ```

   Expected response: A JSON array of notes, e.g., `[{"note_id": 1, "content": "This is a test note", "tenant_id": 1}]`.

## API Endpoints

| Method | Endpoint         | Description                           |
|--------|------------------|---------------------------------------|
| POST   | `/api/register`  | Register a new tenant or user         |
| POST   | `/api/login`     | Authenticate user and return session  |
| GET    | `/api/notes`     | Retrieve notes for authenticated user |
| POST   | `/api/notes`     | Create a new note for authenticated user |

## Troubleshooting

- **Database Connection Issues**:

   Test the database connection to ensure the Citus master node is accessible:

   ```bash
   docker-compose exec citus_master psql -U postgres -d tenant_db -c "SELECT 1"
   ```

   If this fails, check the database logs or ensure the `DATABASE_URL` in the `.env` file is correct.

- **Check Container Logs**:

   View logs for debugging issues with specific services:

   ```bash
   docker-compose logs citus_master
   docker-compose logs web
   ```

- **Reset Containers and Data**:

   If something goes wrong, reset the containers and volumes to start fresh:

   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

- **Verify Citus Distribution**:

   Ensure tables are properly distributed across the Citus cluster:

   ```bash
   docker-compose exec citus_master psql -U postgres -d tenant_db -c "SELECT * FROM citus_tables;"
   ```

   This lists distributed tables and their properties.

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
