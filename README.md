# RLM-jupyter

Multi-user JupyterHub deployment for a hands-on **[Recursive Language Models (RLM)](https://github.com/alexzhang13/rlm)** tutorial.

RLM is an inference paradigm that lets language models programmatically examine, decompose, and recursively call themselves over their input via a REPL environment — enabling near-infinite context handling through divide-and-conquer.

Clone this repo, add your API key, run one script, and your users can log in — no passwords, no accounts to provision.

## What's Inside

```
.
├── docker-compose.yml          # Orchestrates JupyterHub + single-user containers
├── hub/
│   ├── Dockerfile              # JupyterHub image (with DockerSpawner)
│   └── jupyterhub_config.py    # Hub config: auth, spawner, resource limits, API key passthrough
├── singleuser/
│   ├── Dockerfile              # Per-user notebook image
│   ├── requirements.txt        # rlms library + tutorial dependencies
│   └── notebooks/
│       └── Recursive_Language_Models_Tutorial.ipynb
├── setup.sh                    # One-command deploy
├── teardown.sh                 # Stop / purge
├── .env.example                # Resource limits + API key configuration
└── README.md
```

## Quick Start

### Prerequisites

- A Linux box with Docker and Docker Compose installed
- Sufficient RAM for your expected users (each user gets a configurable slice)
- An API key for at least one LLM provider (OpenAI, Anthropic, Portkey, etc.)

### Deploy

```bash
git clone <this-repo-url> && cd RLM-jupyter

# Configure your API key and resource limits
cp .env.example .env
# Edit .env — uncomment and set ONE of the API key options

./setup.sh
```

JupyterHub will be available at **http://your-host:8000**.

### Logging In

- Enter **any username** (e.g., your name)
- Leave the password field **blank** (or type anything)
- Click "Sign in"

Each user gets their own isolated Jupyter container with the RLM tutorial notebook pre-loaded and the API key available.

## Configuration

Edit `.env` to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `MEM_LIMIT` | `512M` | RAM per user container (`256M`, `1G`, `2G`, etc.) |
| `CPU_LIMIT` | `1.0` | CPU cores per user container (fractional OK: `0.5`) |
| `OPENAI_API_KEY` | — | OpenAI API key (set this OR one of the others) |
| `ANTHROPIC_API_KEY` | — | Anthropic API key |
| `PORTKEY_API_KEY` | — | Portkey router API key |
| `OPENROUTER_API_KEY` | — | OpenRouter API key |
| `VLLM_BASE_URL` | — | URL to a local vLLM instance |

### Sizing Guide

| Users | RAM per user | Total RAM needed |
|-------|-------------|-----------------|
| 10    | 512M        | ~6 GB (hub + 10 users) |
| 25    | 512M        | ~14 GB |
| 50    | 256M        | ~14 GB |
| 100   | 256M        | ~27 GB |

The hub itself uses ~500MB. Budget approximately `(users × MEM_LIMIT) + 1GB` for the host.

## The Tutorial Notebook

The included notebook covers the RLM library (`pip install rlms`) from [alexzhang13/rlm](https://github.com/alexzhang13/rlm):

1. **Setup** — auto-detects which API key is configured
2. **What is an RLM?** — the REPL loop, FINAL_VAR, context variables
3. **First Completion** — basic RLM call with verbose output
4. **REPL Loop Mechanics** — trajectory inspection, iteration analysis
5. **Recursive Sub-Calls** — `rlm_query()` with depth > 1
6. **Batched Queries** — `rlm_query_batched()` for parallel sub-calls
7. **Context Compaction** — automatic history summarization
8. **Custom Tools** — injecting functions and data into the REPL
9. **Logging** — trajectory capture and analysis
10. **Exercises** — context processing, recursive summarization, custom tools, error recovery

## Operations

```bash
# View hub logs
docker compose logs -f jupyterhub

# Stop everything (user data preserved)
./teardown.sh

# Stop everything AND delete all user data
./teardown.sh --purge

# Restart after config change
./teardown.sh && ./setup.sh

# See running user containers
docker ps --filter "name=jupyter-"
```

## Idle Culling

User servers that are idle for **1 hour** are automatically shut down to free resources. The idle culler checks every 5 minutes. Users can restart their server by logging in again — their work is persisted in Docker volumes.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host Machine                          │
│                                                          │
│  .env: OPENAI_API_KEY=sk-...  MEM_LIMIT=512M            │
│                                                          │
│  ┌──────────────────┐                                    │
│  │   JupyterHub     │ :8000                              │
│  │   (container)    │                                    │
│  │   DummyAuth      │  ← any username, no password       │
│  └────────┬─────────┘                                    │
│           │ DockerSpawner                                 │
│           │ (API keys passed to each container)           │
│           │                                              │
│  ┌────────┴─────────┐  ┌──────────────────┐              │
│  │  jupyter-alice   │  │  jupyter-bob     │  ...          │
│  │  rlms installed  │  │  rlms installed  │              │
│  │  API key set     │  │  API key set     │              │
│  │  512M RAM limit  │  │  512M RAM limit  │              │
│  └──────────────────┘  └──────────────────┘              │
│                                                          │
│  Docker volumes: jupyterhub-user-alice, etc.             │
└─────────────────────────────────────────────────────────┘
```

## Security Notes

- **API keys** are shared with all users via environment variables. In a classroom setting this is fine — for production, consider per-user keys.
- **No authentication** — anyone who can reach port 8000 can log in. Use a firewall or reverse proxy with auth for public-facing deployments.
- **REPL execution** — the RLM library executes code in the user's container. The Docker container provides isolation from the host.

## Troubleshooting

**Hub won't start**: Check `docker compose logs jupyterhub`. Common issue: Docker socket permissions.

**User container fails to spawn**: Verify the `rlm-singleuser:latest` image built successfully: `docker images | grep rlm-singleuser`.

**Notebook says "No API key found"**: Make sure you set an API key in `.env` and restarted: `./teardown.sh && ./setup.sh`.

**Out of memory**: Reduce `MEM_LIMIT` in `.env` or add swap.

**Port 8000 in use**: Change the port mapping in `docker-compose.yml` (e.g., `"9000:8000"`).

## References

- **RLM Paper:** Zhang, A.L., Kraska, T., & Khattab, O. (2025). *Recursive Language Models.* arXiv:2512.24601
- **RLM Repository:** [github.com/alexzhang13/rlm](https://github.com/alexzhang13/rlm)
- **RLM on PyPI:** `pip install rlms`

## License

See [LICENSE](LICENSE).
