Multi-Tenant Flask-Citus Application
This is a scalable multi-tenant web application built with Flask and Citus (distributed PostgreSQL). It demonstrates proper sharding strategies, efficient schema design for tenant isolation, and optimized query patterns. The application supports user registration, login across tenants, and note management, with data distributed across Citus nodes for performance and scalability. SQLAlchemy is integrated for ORM-based database operations, and monitoring endpoints provide insights into shard activity.
Features

Multi-Tenancy: Isolated tenant data with unique constraints and foreign keys.
Sharding: Distributed tables (users, notes) and reference tables (tenants) using Citus.
User Management: Register and log in users across tenants without requiring tenant names during login.
Note Management: Create and view tenant-specific notes.
Monitoring: Debug endpoints for registrations and shard activity.
Dockerized Deployment: Runs Flask and Citus in Docker containers for easy setup.

Architecture Overview
The application consists of a Flask frontend and a Citus backend, deployed using Docker Compose. The system diagram illustrates the interaction between the Flask app, Citus database, and Docker containers. Key components:

Flask App: Handles HTTP requests, user authentication, and note management.
Citus Database: Stores tenant and user data, distributed across nodes for scalability.
Docker: Ensures consistent deployment with flask-citus-app-web-1 (Flask) and flask-citus-app-citus-master-1 (Citus).

See the System Diagram for a visual representation.
Prerequisites

Docker and Docker Compose
Python 3.9 (for development outside Docker)
PostgreSQL client (e.g., psql) for debugging
Git

Installation and Setup

Clone the Repository:
git clone https://github.com/your-repo/flask-citus-app.git
cd flask-citus-app


Set Environment Variables (optional):

Create a .flaskenv file or set environment variables:export FLASK_ENV=development
export SECRET_KEY=your-secret-key-here
export DATABASE_URL=postgresql://postgres:mysecretpassword@flask-citus-app-citus-master-1:5432/postgres




Build and Run Docker Containers:
docker-compose up -d --build


This starts the Flask app (flask-citus-app-web-1) and Citus database (flask-citus-app-citus-master-1).
The database is initialized via docker-entrypoint-initdb.d/init.sql and app/models.py.


Verify Setup:

Check container status:docker ps


Access the app at http://localhost:5000.



Usage

Register a Tenant and User:

Navigate to http://localhost:5000/register.
Enter:
Tenant Name: mytenant
Username: testuser
Email: test@example.com
Password: securepassword


On success, you’ll see “Registration successful! Please log in.”


Log In:

Go to http://localhost:5000/login.
Enter email and password (e.g., test@example.com, securepassword).
The app automatically selects the correct tenant.


Manage Notes:

After logging in, access http://localhost:5000/notes to add or view notes.
Notes are isolated to the user’s tenant.


Debugging:

View registrations: http://localhost:5000/debug/registrations (requires login).
Monitor shards: http://localhost:5000/debug/shards (requires login).



Database Schema and Sharding
The database is designed for multi-tenancy with Citus for scalability. See the Database Diagram for a visual representation.
Tables

shared.tenants:
Columns: id (PK), name (unique), created_at.
Type: Reference table (replicated across all nodes).
Purpose: Stores tenant metadata.


shared.users:
Columns: id, tenant_id (composite PK), username, email, password, created_at.
Type: Distributed table (sharded by tenant_id).
Constraints: UNIQUE (tenant_id, username), UNIQUE (tenant_id, email), FOREIGN KEY (tenant_id) REFERENCES shared.tenants(id).
Purpose: Stores user data, isolated by tenant.


notes:
Columns: id (PK), content, user_id, created_at, updated_at.
Type: Distributed table (sharded by user_id, colocated with users).
Constraint: FOREIGN KEY (user_id) REFERENCES shared.users(id).
Purpose: Stores user notes.



Sharding Strategy

Distribution:
shared.tenants: Replicated to all nodes for fast lookups.
shared.users: Sharded by tenant_id to isolate tenant data.
notes: Sharded by user_id and colocated with users for efficient joins.


Cross-Shard Queries:
Login queries scan all shards for email matches (optimized with indexes).
Tenant-specific queries (e.g., notes) are routed to single shards by Citus.


Tenant Isolation:
Unique constraints and foreign keys ensure data separation.
SQLAlchemy models enforce tenant context.



See the Sharding Diagram for details on data distribution.
SQLAlchemy Integration

SQLAlchemy models (Tenant, User, Note) define the schema with composite keys and relationships.
configure_distributed_tables in models.py creates and distributes tables using raw SQL.
Transactions are managed via db.session.commit() and db.session.rollback().

Monitoring and Debugging

Citus Views:
Check table distribution:SELECT * FROM pg_dist_partition;


View shards:SELECT * FROM pg_dist_shard;


Monitor queries:SELECT * FROM citus_stat_activity;




Debug Endpoint:
Access http://localhost:5000/debug/shards to view shard distribution and node health.


Logs:
Check Flask logs:docker logs flask-citus-app-web-1





Diagrams

System Diagram: Illustrates the Flask app, Citus database, and Docker container interactions.
Sharding Diagram: Shows how tenants, users, and notes are distributed across Citus nodes.
Database Diagram: Depicts the schema with tables, columns, and relationships.

Note: Diagrams are available in the repository’s docs/ folder (assumed; update path if different).
Contributing

Submit issues or pull requests via GitHub.
Follow PEP 8 for Python code and ensure tests pass.
Add tests in tests/ (to be implemented).

License
This project is licensed under the MIT License. See the LICENSE file for details.
Contact
For issues or questions, contact the maintainers via GitHub Issues or email (your-email@example.com).
Acknowledgments

Flask for the web framework.
Citus for distributed PostgreSQL.
SQLAlchemy for ORM integration.
Docker for containerized deployment.

