#!/bin/bash

set -e

# Wait for master to be ready
until pg_isready -h citus-master -U postgres; do
  echo "Waiting for citus-master..."
  sleep 2
done

# Wait for worker to be ready
until pg_isready -h citus-worker -U postgres; do
  echo "Waiting for citus-worker..."
  sleep 2
done

#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
  SELECT citus_set_coordinator_host('citus-master');
  SELECT citus_add_node('citus-worker', 5432);
EOSQL
