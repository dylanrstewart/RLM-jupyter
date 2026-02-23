"""JupyterHub configuration for multi-user RLM tutorial deployment."""

import os

c = get_config()  # noqa: F821

# ---------------------------------------------------------------------------
# Authentication — no password required
# ---------------------------------------------------------------------------
c.JupyterHub.authenticator_class = "dummy"
# DummyAuthenticator: any username, any (or blank) password
c.DummyAuthenticator.password = ""

# ---------------------------------------------------------------------------
# Spawner — Docker containers, one per user
# ---------------------------------------------------------------------------
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

notebook_image = os.environ.get("DOCKER_NOTEBOOK_IMAGE", "rlm-singleuser:latest")
c.DockerSpawner.image = notebook_image

notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

c.DockerSpawner.volumes = {
    "jupyterhub-user-{username}": notebook_dir,
}

network_name = os.environ.get("DOCKER_NETWORK_NAME", "rlm-jupyter_default")
c.DockerSpawner.network_name = network_name
c.JupyterHub.hub_connect_ip = "jupyterhub"

c.DockerSpawner.remove = True  # remove containers when they stop

# ---------------------------------------------------------------------------
# Pass LLM API keys into user containers
# ---------------------------------------------------------------------------
env_vars_to_pass = [
    "OPENAI_API_KEY",
    "OPENAI_MODEL",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_MODEL",
    "PORTKEY_API_KEY",
    "PORTKEY_MODEL",
    "OPENROUTER_API_KEY",
    "VLLM_BASE_URL",
]
c.DockerSpawner.environment = {
    k: os.environ[k] for k in env_vars_to_pass if os.environ.get(k)
}

# ---------------------------------------------------------------------------
# Resource limits per user
# ---------------------------------------------------------------------------
mem_limit = os.environ.get("MEM_LIMIT", "512M")
cpu_limit = float(os.environ.get("CPU_LIMIT", "1.0"))

c.DockerSpawner.mem_limit = mem_limit
c.DockerSpawner.cpu_limit = cpu_limit

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
c.JupyterHub.ip = "0.0.0.0"
c.JupyterHub.port = 8000

# ---------------------------------------------------------------------------
# Idle culling — shut down idle servers to free resources
# ---------------------------------------------------------------------------
c.JupyterHub.services = [
    {
        "name": "idle-culler",
        "command": [
            "python3",
            "-m",
            "jupyterhub_idle_culler",
            "--timeout=3600",
            "--max-age=0",
            "--cull-every=300",
        ],
    }
]
c.JupyterHub.load_roles = [
    {
        "name": "idle-culler",
        "scopes": [
            "list:users",
            "read:users:activity",
            "read:servers",
            "delete:servers",
        ],
        "services": ["idle-culler"],
    }
]
