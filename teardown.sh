#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Teardown script — stop JupyterHub and optionally remove user data volumes
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect compose command
if docker compose version &>/dev/null 2>&1; then
    COMPOSE="docker compose"
else
    COMPOSE="docker-compose"
fi

echo "Stopping JupyterHub..."
$COMPOSE down

if [[ "${1:-}" == "--purge" ]]; then
    echo "Removing all user data volumes..."
    $COMPOSE down -v
    # Remove per-user Docker volumes created by DockerSpawner
    docker volume ls -q | grep '^jupyterhub-user-' | xargs -r docker volume rm
    echo "All user data has been removed."
else
    echo "User data volumes have been preserved."
    echo "Run '$0 --purge' to remove all user data."
fi

echo "Done."
