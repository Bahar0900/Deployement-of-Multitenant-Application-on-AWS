<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Multi-Tenant Application with Flask and Citus</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            margin-top: 30px;
            border-bottom: 1px solid #ecf0f1;
            padding-bottom: 5px;
        }
        pre {
            background: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            font-family: 'Courier New', Courier, monospace;
        }
        img {
            max-width: 100%;
            height: auto;
            margin: 10px 0;
        }
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        ul {
            list-style-type: disc;
            margin-left: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .emoji {
            margin-right: 5px;
        }
    </style>
</head>
<body>
    <h1>Multi-Tenant Application with Flask and Citus</h1>
    <p>A scalable, secure multi-tenant application leveraging Flask and Citus (distributed PostgreSQL) for efficient tenant isolation, sharding, and horizontal scaling.</p>

    <h2>Table of Contents</h2>
    <ul>
        <li><a href="#multi-tenancy-overview">Multi-Tenancy Overview</a></li>
        <li><a href="#system-architecture">System Architecture</a></li>
        <li><a href="#getting-started">Getting Started</a>
            <ul>
                <li><a href="#prerequisites">Prerequisites</a></li>
                <li><a href="#setup-instructions">Setup Instructions</a></li>
            </ul>
        </li>
        <li><a href="#database-design">Database Design</a>
            <ul>
                <li><a href="#schema-overview">Schema Overview</a></li>
                <li><a href="#sharding-strategy">Sharding Strategy</a></li>
            </ul>
        </li>
        <li><a href="#citus-monitoring">Citus Monitoring Guide with Docker Access</a></li>
        <li><a href="#api-endpoints">API Endpoints</a></li>
        <li><a href="#development-guide">Development Guide</a></li>
        <li><a href="#troubleshooting">Troubleshooting</a></li>
        <li><a href="#contributing">Contributing</a></li>
        <li><a href="#license">License</a></li>
        <li><a href="#contact">Contact</a></li>
        <li><a href="#acknowledgments">Acknowledgments</a></li>
    </ul>

    <h2 id="multi-tenancy-overview">Multi-Tenancy Overview</h2>
    <img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/7d6351f9d5111082dd764f5b124b6e5fac649477/images/schema_Diagram.drawio.png?raw=true" alt="Schema Diagram">
    <p>This application provides a robust multi-tenant architecture with secure data isolation using Citus' sharding capabilities. Key features include:</p>
    <ul>
        <li><strong>Tenant Isolation</strong>: Data separation via <code>tenant_id</code> sharding key</li>
        <li><strong>Horizontal Scaling</strong>: Citus distributes data across worker nodes</li>
        <li><strong>Colocation</strong>: Optimized joins for <code>users</code> and <code>notes</code> tables</li>
        <li><strong>Security</strong>: Encrypted credentials and tenant-specific constraints</li>
    </ul>

    <h2 id="system-architecture">System Architecture</h2>
    <img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/46f1babb921d39c11d9432bf975f07320ef963d8/images/systemarchitecture.JPG" alt="System Architecture">
    <h3>Components</h3>
    <ul>
        <li><strong>Flask Application</strong>: Stateless REST API for tenant and user management</li>
        <li><strong>Citus Cluster</strong>: Distributed PostgreSQL with one coordinator and multiple worker nodes</li>
        <li><strong>Docker</strong>: Containerized environment for consistent deployment</li>
        <li><strong>SQLAlchemy</strong>: ORM with Citus extensions for seamless database interactions</li>
    </ul>

    <h2 id="getting-started">Getting Started</h2>
    <h3 id="prerequisites">Prerequisites</h3>
    <ul>
        <li>Docker 20.10+</li>
        <li>Docker Compose 1.29+</li>
        <li>Python 3.9+</li>
        <li>Git</li>
    </ul>

    <h3 id="setup-instructions">Setup Instructions</h3>
    <ol>
        <li><strong>Clone the Repository</strong>:
            <pre><code>git clone https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus.git
cd MultiTenant-Application-with-Flask-and-Citus</code></pre>
        </li>
        <li><strong>Configure Environment Variables</strong>:
            <p>Create a <code>.env</code> file in the project root:</p>
            <pre><code>DATABASE_URL=postgresql://postgres:password@citus_master:5432/your_database_name
FLASK_ENV=development
SECRET_KEY=your-secure-flask-key</code></pre>
        </li>
        <li><strong>Start Docker Containers</strong>:
            <pre><code>docker-compose up -d</code></pre>
        </li>
        <li><strong>Initialize Database Schema</strong>:
            <p>The <code>docker-entrypoint-initdb.d/init.sql</code> script automatically sets up the schema on container startup.</p>
        </li>
        <li><strong>Verify Services</strong>:
            <ul>
                <li>Flask API: <a href="http://localhost:5000">http://localhost:5000</a></li>
                <li>Citus cluster health: See <a href="#citus-monitoring">Citus Monitoring Guide</a></li>
            </ul>
        </li>
    </ol>

    <h2 id="database-design">Database Design</h2>
    <h3 id="schema-overview">Schema Overview</h3>
    <img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/Capture.JPG" alt="Table Diagram">
    <p>The database consists of three main tables:</p>
    <ul>
        <li><strong>shared.tenants</strong> (Reference Table):
            <ul>
                <li>Columns: <code>id</code>, <code>name</code>, <code>created_at</code></li>
                <li>Replicated across all nodes for fast access</li>
            </ul>
        </li>
        <li><strong>shared.users</strong> (Distributed Table):
            <ul>
                <li>Columns: <code>id</code>, <code>tenant_id</code>, <code>username</code>, <code>email</code>, <code>password</code>, <code>created_at</code></li>
                <li>Sharded by <code>tenant_id</code> with unique constraints per tenant</li>
            </ul>
        </li>
        <li><strong>notes</strong> (Distributed Table):
            <ul>
                <li>Columns: <code>id</code>, <code>content</code>, <code>user_id</code>, <code>created_at</code>, <code>updated_at</code></li>
                <li>Sharded by <code>user_id</code>, colocated with <code>users</code></li>
            </ul>
        </li>
    </ul>

    <h3 id="sharding-strategy">Sharding Strategy</h3>
    <img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/sharding_strategy.png" alt="Sharding Strategy">
    <ul>
        <li><strong>Hash-Based Sharding</strong>: Uses <code>tenant_id</code> (for <code>users</code>) and <code>user_id</code> (for <code>notes</code>) as distribution keys</li>
        <li><strong>Colocation</strong>: <code>notes</code> table is colocated with <code>users</code> for efficient joins</li>
        <li><strong>Reference Tables</strong>: <code>tenants</code> table is replicated across all nodes</li>
    </ul>

    <h2 id="citus-monitoring">Citus Monitoring Guide with Docker Access</h2>
    <p>This guide explains how to monitor your <strong>Citus database cluster</strong> from within Docker containers. We'll start by accessing the relevant Docker container, then run SQL queries to track shard activity and performance.</p>
    <h3><span class="emoji">🐳</span> Step 1: View Running Docker Containers</h3>
    <p>List all running containers:</p>
    <pre><code>docker ps</code></pre>
    <h3><span class="emoji">📦</span> Step 2: Access the Citus Master Container</h3>
    <p>Identify the container name for your <strong>Citus master</strong>, then enter its shell:</p>
    <pre><code>docker exec -it &lt;container_name&gt; bash</code></pre>
    <p>Replace <code>&lt;container_name&gt;</code> with your actual container ID or name (e.g., <code>citus_master</code>).</p>
    <h3><span class="emoji">🐘</span> Step 3: Connect to PostgreSQL Inside Container</h3>
    <p>Run the following command inside the container to access PostgreSQL:</p>
    <pre><code>psql -U postgres -d your_database_name</code></pre>
    <p>Replace <code>your_database_name</code> with your actual database name.</p>
    <h3><span class="emoji">📡</span> Step 4: Monitor Shard Activity & Cluster Health</h3>
    <p>Once inside PostgreSQL, use the following SQL commands:</p>
    <ul>
        <li><strong><span class="emoji">🔍</span> List Distributed Tables</strong>:
            <pre><code>SELECT * FROM citus_tables;</code></pre>
        </li>
        <li><strong><span class="emoji">📊</span> View Shard Placements</strong>:
            <p>See shard distribution across the cluster:</p>
            <pre><code>SELECT * FROM pg_dist_shard;</code></pre>
            <p>Check where shards are placed:</p>
            <pre><code>SELECT * FROM pg_dist_placement;</code></pre>
        </li>
        <li><strong><span class="emoji">📦</span> Get Shard Sizes</strong>:
            <pre><code>SELECT * FROM citus_stat_shards;</code></pre>
        </li>
        <li><strong><span class="emoji">🔁</span> Monitor Active Queries</strong>:
            <pre><code>SELECT * FROM pg_stat_activity WHERE datname = 'your_database_name';</code></pre>
        </li>
        <li><strong><span class="emoji">🔗</span> Check Worker Node Status</strong>:
            <pre><code>SELECT * FROM pg_dist_node;</code></pre>
        </li>
        <li><strong><span class="emoji">🧠</span> Colocation & Distribution Strategy</strong>:
            <pre><code>SELECT logicalrelid, colocationid, distribution_column 
FROM pg_dist_partition;</code></pre>
        </li>
        <li><strong><span class="emoji">📈</span> Track Query Performance (Optional)</strong>:
            <p>Enable <code>pg_stat_statements</code> to view slow or heavy queries:</p>
            <pre><code>SELECT query, calls, total_time, rows 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;</code></pre>
        </li>
    </ul>

    <h2 id="api-endpoints">API Endpoints</h2>
    <table>
        <tr>
            <th>Method</th>
            <th>Endpoint</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>POST</td>
            <td><code>/api/register</code></td>
            <td>Register a new tenant or user</td>
        </tr>
        <tr>
            <td>POST</td>
            <td><code>/api/login</code></td>
            <td>Authenticate user and return session</td>
        </tr>
        <tr>
            <td>GET</td>
            <td><code>/api/notes</code></td>
            <td>Retrieve notes for authenticated user</td>
        </tr>
        <tr>
            <td>POST</td>
            <td><code>/api/notes</code></td>
            <td>Create a new note for authenticated user</td>
        </tr>
    </table>

    <h2 id="development-guide">Development Guide</h2>
    <p>Follow these guidelines for contributing to the project:</p>
    <ul>
        <li>Adhere to <strong>PEP 8</strong> for Python code style</li>
        <li>Write tests under the <code>tests/</code> directory (to be implemented)</li>
        <li>Run existing tests before submitting changes</li>
    </ul>

    <h2 id="troubleshooting">Troubleshooting</h2>
    <ul>
        <li><strong>Database Connection Issues</strong>:
            <pre><code>docker-compose exec citus_master psql -U postgres -d your_database_name -c "SELECT 1"</code></pre>
        </li>
        <li><strong>Check Container Logs</strong>:
            <pre><code>docker-compose logs citus_master</code></pre>
        </li>
        <li><strong>Reset Containers and Data</strong>:
            <pre><code>docker-compose down -v
docker-compose up -d</code></pre>
        </li>
    </ul>

    <h2 id="contributing">Contributing</h2>
    <p>Contributions are welcome! Please:</p>
    <ul>
        <li>Submit issues or pull requests via <a href="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/issues">GitHub Issues</a></li>
        <li>Follow <strong>PEP 8</strong> guidelines</li>
        <li>Ensure all tests pass</li>
    </ul>

    <h2 id="license">License</h2>
    <p>MIT License. See the <a href="./LICENSE">LICENSE</a> file for details.</p>

    <h2 id="contact">Contact</h2>
    <ul>
        <li>GitHub: <a href="https://github.com/Bahar0900">Bahar0900</a></li>
        <li>Email: <code>sagormdsagorchowdhury@example.com</code></li>
    </ul>

    <h2 id="acknowledgments">Acknowledgments</h2>
    <ul>
        <li><strong>Flask</strong>: Lightweight web framework</li>
        <li><strong>Citus</strong>: Distributed PostgreSQL extension</li>
        <li><strong>SQLAlchemy</strong>: ORM for database interactions</li>
        <li><strong>Docker</strong>: Containerization platform</li>
    </ul>
</body>
</html>

