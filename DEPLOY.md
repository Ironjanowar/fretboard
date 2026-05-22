# Deploying Fretboard

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+)
- Git

## Quick Start

```bash
git clone <your-repo-url>
cd fretboard
cp .env.example .env

# Generate a secret key and put it in .env:
mix phx.gen.secret
# → paste the output as SECRET_KEY_BASE in .env

# Build and run
bin/deploy.sh
```

The app will be available at `http://localhost:4000`.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `SECRET_KEY_BASE` | *(required)* | Phoenix secret key. Generate with `mix phx.gen.secret` |
| `PHX_HOST` | `localhost` | Hostname for URL generation |
| `PORT` | `4000` | HTTP port |

## Manual Build & Run

```bash
# Build the image
docker compose build

# Start in foreground
docker compose up

# Start in background
docker compose up -d
```

## Running Without Docker

```bash
# Install dependencies
mix deps.get --only prod
MIX_ENV=prod mix assets.deploy

# Build the release
MIX_ENV=prod mix release

# Run it
SECRET_KEY_BASE=$(mix phx.gen.secret) PHX_HOST=localhost PORT=4000 \
  _build/prod/rel/fretboard/bin/server
```

## SSL / HTTPS (Reverse Proxy)

The app runs plain HTTP. Put a reverse proxy in front for TLS.

### Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name fretboard.example.com;

    ssl_certificate     /etc/letsencrypt/live/fretboard.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fretboard.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Caddy

```
fretboard.example.com {
    reverse_proxy localhost:4000
}
```

After setting up a reverse proxy, uncomment the `force_ssl` block in `config/prod.exs` and rebuild.

## Useful Commands

```bash
# View logs
docker compose logs -f

# Restart
docker compose restart

# Stop
docker compose down

# Shell into the container
docker compose exec fretboard /bin/bash

# Remote IEx console
docker compose exec fretboard /app/bin/fretboard remote
```

## Troubleshooting

**"SECRET_KEY_BASE is not set"**
Make sure `.env` exists and contains a valid `SECRET_KEY_BASE`. Generate one with `mix phx.gen.secret`.

**Port already in use**
Change `PORT` in `.env` or stop the conflicting service.

**Assets not loading / 404 on CSS/JS**
The Docker build runs `mix assets.deploy` automatically. If you see stale assets, rebuild: `docker compose build --no-cache`.

**WebSocket errors in browser console**
Make sure your reverse proxy forwards WebSocket connections (the `Upgrade` and `Connection` headers).
