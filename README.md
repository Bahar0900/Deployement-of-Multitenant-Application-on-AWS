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
<ul>
    <li><strong>shared.tenants</strong> (Reference Table)</li>
    <li><strong>shared.users</strong> (Distributed Table)</li>
    <li><strong>notes</strong> (Distributed Table)</li>
</ul>

<h3 id="sharding-strategy">Sharding Strategy</h3>
<img src="https://github.com/Bahar0900/MultiTenant-Application-with-Flask-and-Citus/blob/fbf28c4219c481460b2c33b7f48ee8f8f3c404cc/images/sharding_strategy.png" alt="Sharding Strategy">
<ul>
    <li><strong>Hash-Based Sharding</strong></li>
    <li><strong>Colocation</strong></li>
    <li><strong>Reference Tables</strong></li>
</ul>

<h2 id="citus-monitoring">Citus Monitoring Guide with Docker Access</h2>
<p>Run the following commands to monitor the Citus cluster:</p>
<pre><code>docker exec -it citus_master psql -U postgres -d your_database_name</code></pre>
<pre><code>SELECT * FROM citus_tables;</code></pre>
<pre><code>SELECT * FROM pg_dist_node;</code></pre>
<pre><code>SELECT * FROM pg_stat_activity;</code></pre>

<h2 id="api-endpoints">API Endpoints</h2>
<ul>
    <li><code>POST /tenants</code> - Create a new tenant</li>
    <li><code>POST /users</code> - Create a user under a tenant</li>
    <li><code>POST /notes</code> - Add note for a user</li>
    <li><code>GET /notes?user_id=</code> - Fetch notes by user</li>
</ul>

<h2 id="development-guide">Development Guide</h2>
<ul>
    <li>Use <code>.env</code> for local config</li>
    <li>Check Docker logs via <code>docker-compose logs -f</code></li>
    <li>Lint code with <code>flake8</code></li>
    <li>Test with <code>pytest</code></li>
</ul>

<h2 id="troubleshooting">Troubleshooting</h2>
<ul>
    <li>If Citus nodes don't connect, verify network setup in <code>docker-compose.yml</code></li>
    <li>Ensure database initialization via logs</li>
    <li>Use <code>pg_isready</code> to check DB readiness</li>
</ul>

<h2 id="contributing">Contributing</h2>
<ul>
    <li>Fork this repo</li>
    <li>Create your feature branch (<code>git checkout -b feature/foo</code>)</li>
    <li>Commit your changes (<code>git commit -am 'Add foo'</code>)</li>
    <li>Push to the branch (<code>git push origin feature/foo</code>)</li>
    <li>Create a new Pull Request</li>
</ul>

<h2 id="license">License</h2>
<p>This project is licensed under the MIT License - see the <a href="LICENSE">LICENSE</a> file for details.</p>

<h2 id="contact">Contact</h2>
<p>Created by <a href="https://github.com/Bahar0900">Bahar0900</a> - feel free to reach out!</p>

<h2 id="acknowledgments">Acknowledgments</h2>
<ul>
    <li><a href="https://docs.citusdata.com">Citus Documentation</a></li>
    <li><a href="https://flask.palletsprojects.com/">Flask</a></li>
    <li><a href="https://www.postgresql.org/">PostgreSQL</a></li>
    <li><a href="https://www.docker.com/">Docker</a></li>
</ul>
