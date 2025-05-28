-- docker-entrypoint-initdb.d/init.sql
CREATE EXTENSION IF NOT EXISTS citus;
SELECT citus_set_coordinator_host('citus-master');
