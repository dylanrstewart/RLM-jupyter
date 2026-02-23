#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# RLM-jupyter setup script
# Builds images and starts JupyterHub for multi-user tutorial sessions.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Colours for output
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
info "Running pre-flight checks..."

if ! command -v docker &>/dev/null; then
    error "Docker is not installed. Please install Docker first."
    echo "  https://docs.docker.com/engine/install/"
    exit 1
fi

if ! docker info &>/dev/null; then
    error "Docker daemon is not running or current user lacks permissions."
    echo "  Try: sudo systemctl start docker"
    echo "  Or add yourself to the docker group: sudo usermod -aG docker \$USER"
    exit 1
fi

if ! command -v docker compose &>/dev/null && ! command -v docker-compose &>/dev/null; then
    error "Docker Compose is not available."
    echo "  Install the Docker Compose plugin: https://docs.docker.com/compose/install/"
    exit 1
fi

# Detect compose command
if docker compose version &>/dev/null; then
    COMPOSE="docker compose"
else
    COMPOSE="docker-compose"
fi

info "Docker and Docker Compose detected."

# ---------------------------------------------------------------------------
# Create .env from example if it doesn't exist
# ---------------------------------------------------------------------------
if [ ! -f .env ]; then
    info "Creating .env from .env.example ..."
    cp .env.example .env
    info ".env created. Edit it to customize memory/CPU limits per user."
else
    info ".env already exists, keeping current values."
fi

# Source the .env for display
set -a
source .env
set +a

info "Configuration:"
info "  MEM_LIMIT  = ${MEM_LIMIT:-512M}  (RAM per user)"
info "  CPU_LIMIT  = ${CPU_LIMIT:-1.0}   (CPU cores per user)"

# ---------------------------------------------------------------------------
# Build images
# ---------------------------------------------------------------------------
info "Building the single-user notebook image (this may take a few minutes)..."
$COMPOSE build singleuser-build

# Tag it so DockerSpawner can find it
info "Building the JupyterHub image..."
$COMPOSE build jupyterhub

# ---------------------------------------------------------------------------
# Start JupyterHub
# ---------------------------------------------------------------------------
info "Starting JupyterHub..."
$COMPOSE up -d jupyterhub

echo ""
info "========================================="
info " JupyterHub is starting up!"
info " URL:  http://localhost:8000"
info ""
info " Authentication: NONE (any username, blank password)"
info " Each user gets: ${MEM_LIMIT:-512M} RAM, ${CPU_LIMIT:-1.0} CPU"
info "========================================="
echo ""
info "View logs:    $COMPOSE logs -f jupyterhub"
info "Stop:         $COMPOSE down"
info "Stop + clean: $COMPOSE down -v"
