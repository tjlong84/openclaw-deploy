# openclaw-deploy

Docker setup for a self-hosted [openclaw](https://openclaw.ai) gateway + LifeOS V2 backend/frontend, routed through a Cloudflare tunnel.

## Stack

| Service | Port (internal) | Description |
|---------|-----------------|-------------|
| openclaw-gateway | 18789 | OpenClaw WebSocket gateway (loopback) |
| v2-backend | 8788 | LifeOS V2 Fastify API (SQLite) |
| v2-frontend | 4174 | LifeOS V2 React frontend (SSR via Express) |
| cloudflared | — | Cloudflare tunnel (routes public domain → v2-frontend/v2-backend) |

All four processes run under **supervisord** inside a single Node 22 (Debian Bookworm) container.

---

## Prerequisites

- Docker + Docker Compose on the host
- A [Cloudflare tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) already created
- An openclaw account with at least one auth profile (OpenAI Codex OAuth or API key)

---

## Quick Start

### 1. Clone and create directories

```bash
git clone https://github.com/tjlong84/openclaw-deploy
cd openclaw-deploy
mkdir -p state/cloudflared/etc state/cloudflared/logs workspace supervisor
```

### 2. Set up Cloudflared credentials

```bash
# Copy and fill in the template
cp state-template/cloudflared/cloudflared.env.template state/cloudflared/cloudflared.env
cp state-template/cloudflared/etc/config.yml.template  state/cloudflared/etc/config.yml

# Edit both files — replace YOUR_TUNNEL_UUID, YOUR_DOMAIN, YOUR_CLOUDFLARE_TUNNEL_TOKEN
# Then copy your tunnel credentials JSON:
cp ~/.cloudflared/<tunnel-uuid>.json state/cloudflared/etc/
```

### 3. Copy supervisor configs

```bash
cp supervisor/*.conf supervisor/   # already in place if cloned
```

### 4. Build and start

```bash
docker build -t openclaw-fresh:local .
docker-compose up -d
```

### 5. Run openclaw onboarding (first time only)

```bash
docker exec -it openclaw-v2 openclaw configure
```

This sets up your auth profiles (OpenAI, Gemini, ZAI, etc.) inside the container.

---

## Directory Layout

```
openclaw-deploy/
├── Dockerfile                  # Node 22 + openclaw global + cloudflared + supervisor
├── supervisord.conf            # Baked into image via COPY
├── docker-compose.yml          # Volume mounts + port mapping
├── supervisor/                 # Mounted at /etc/supervisor/conf.d (hot-reloadable)
│   ├── openclaw-gateway.conf
│   ├── v2-backend.conf
│   ├── v2-frontend.conf
│   └── cloudflared.conf
├── state-template/             # Templates for personal state (not the real values)
│   └── cloudflared/
│       ├── cloudflared.env.template
│       └── etc/
│           ├── config.yml.template
│           └── TUNNEL_CREDENTIALS.md
└── state/                      # NOT in git — your personal state goes here
    ├── openclaw.json           # openclaw config (auth profiles, models, etc.)
    ├── agents/                 # Agent state + auth-profiles.json
    ├── cloudflared/
    │   ├── cloudflared.env     # Real tunnel token
    │   └── etc/
    │       ├── config.yml      # Real tunnel config
    │       └── <uuid>.json     # Tunnel credentials
    ├── credentials/            # Telegram etc.
    └── devices/
```

The `state/` directory is gitignored. Keep it in a private repo or encrypted backup separately.

---

## Workspace

The `workspace/` directory is mounted at `/home/node/clawd` inside the container. This is where:

- **LifeOS-OpenClaw-V2/** — V2 backend (Fastify) + frontend (React/Vite)
- **IDENTITY.md** — Agent identity/persona
- **docs/config/** — Agent config (SOUL.md, USER.md, HEARTBEAT.md, AGENTS.md)
- **docs/, decisions/, artifacts/, projects/, memory/** — Agent knowledge files

The workspace can be tracked in a separate git repo so the openclaw agent can commit and push its own files. See the [`clawd`](https://github.com/tjlong84/clawd) repo.

---

## Port Mapping

Host ports are configurable via environment variables (default values shown):

```bash
GATEWAY_HOST_PORT=18789   # openclaw gateway
BRIDGE_HOST_PORT=18790    # openclaw bridge
FRONTEND_HOST_PORT=4174   # V2 frontend
BACKEND_HOST_PORT=8788    # V2 backend API
```

Override at runtime: `GATEWAY_HOST_PORT=19000 docker-compose up -d`

---

## Upgrading openclaw

```bash
docker build --no-cache -t openclaw-fresh:local .
docker-compose up -d
```

The `npm install -g openclaw@latest` in the Dockerfile always pulls the latest stable.
