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
git clone https://github.com/your-repo/flask-citus-app.git
cd flask-citus-app

# Build and start containers
docker-compose up -d

# Initialize database (after containers are up)
docker-compose exec web python init_db.py
```
