#!/bin/bash
set -e

# ──────────────────────── CONFIG ────────────────────────
# Use default IPs unless overridden
MASTER_HOST="${MASTER_HOST:-10.0.4.55}"    # Coordinator (master) private IP or DNS
WORKER_HOST="${WORKER_HOST:-10.0.5.243}"     # Worker private IP or DNS

PGUSER="${PGUSER:-postgres}"
PGPASSWORD="${PGPASSWORD:-mysecretpassword}"  # Matches what you used in Docker Compose

export PGPASSWORD

echo "Coordinator : $MASTER_HOST"
echo "Worker      : $WORKER_HOST"

# ────────── 1. Wait until Postgres is ready on both nodes ──────────
until pg_isready -h "$MASTER_HOST" -U "$PGUSER" >/dev/null 2>&1 ; do
  echo "Waiting for coordinator ($MASTER_HOST)…"
  sleep 2
done

until pg_isready -h "$WORKER_HOST" -U "$PGUSER" >/dev/null 2>&1 ; do
  echo "Waiting for worker ($WORKER_HOST)…"
  sleep 2
done

# ────────── 2. Check if Citus extension exists ──────────
echo "Checking Citus on coordinator…"
psql -h "$MASTER_HOST" -U "$PGUSER" -c "SELECT citus_version();"

echo "Checking Citus on worker…"
psql -h "$WORKER_HOST" -U "$PGUSER" -c "SELECT citus_version();"

# ────────── 3. Register the worker to the coordinator ──────────
echo "Setting up Citus cluster…"
psql -v ON_ERROR_STOP=1 -h "$MASTER_HOST" -U "$PGUSER" <<-EOSQL
  SELECT citus_set_coordinator_host('$MASTER_HOST');

  -- Insert worker, skip if already added
  INSERT INTO pg_dist_node (groupid, nodename, nodeport)
  VALUES (0, '$WORKER_HOST', 5432)
  ON CONFLICT (nodename, nodeport) DO NOTHING;

  SELECT * FROM citus_get_active_worker_nodes();
EOSQL

echo "✔︎ Cluster setup complete!"
