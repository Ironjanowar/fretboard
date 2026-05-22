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

## Running Without Docker (Native Release)

This works on any system with Elixir/Erlang installed (Linux, FreeBSD, macOS).

### 1. Clone and build

```bash
git clone https://github.com/Ironjanowar/fretboard.git
cd fretboard

export MIX_ENV=prod
mix deps.get --only prod
mix compile
mix assets.deploy
mix release
```

The release will be at `_build/prod/rel/fretboard/`.

### 2. Configure environment variables

Generate a secret key (run once, save the output):

```bash
mix phx.gen.secret
```

Set these before running:

| Variable | Required | Default | Description |
|---|---|---|---|
| `SECRET_KEY_BASE` | **Yes** | — | 64+ char secret. Generate with `mix phx.gen.secret` |
| `PHX_HOST` | No | `localhost` | Public hostname (e.g. `fretboard.example.com`) |
| `PORT` | No | `4000` | HTTP port to listen on |
| `PHX_SERVER` | **Yes** | — | Set to `true` to start the web server |

### 3. Run the release

```bash
export SECRET_KEY_BASE="your-generated-secret-here"
export PHX_HOST="fretboard.example.com"
export PORT=4000
export PHX_SERVER=true

# Start in foreground
_build/prod/rel/fretboard/bin/server

# Or start as daemon (background)
_build/prod/rel/fretboard/bin/fretboard start
```

### 4. Manage the running release

```bash
# Check if running
_build/prod/rel/fretboard/bin/fretboard pid

# Attach remote IEx console
_build/prod/rel/fretboard/bin/fretboard remote

# Stop gracefully
_build/prod/rel/fretboard/bin/fretboard stop

# Restart
_build/prod/rel/fretboard/bin/fretboard restart
```

### 5. Update to a new version

```bash
cd /path/to/fretboard
git pull

export MIX_ENV=prod
mix deps.get --only prod
mix compile
mix assets.deploy
mix release

_build/prod/rel/fretboard/bin/fretboard restart
```

### 6. Run as a system service (optional)

#### FreeBSD rc.d

Create `/usr/local/etc/rc.d/fretboard`:

```sh
#!/bin/sh

# PROVIDE: fretboard
# REQUIRE: NETWORKING
# KEYWORD: shutdown

. /etc/rc.subr

name="fretboard"
rcvar="fretboard_enable"

load_rc_config $name

: ${fretboard_enable:="NO"}
: ${fretboard_dir:="/opt/fretboard"}
: ${fretboard_user:="www"}
: ${fretboard_secret_key_base:=""}
: ${fretboard_host:="localhost"}
: ${fretboard_port:="4000"}

command="${fretboard_dir}/_build/prod/rel/fretboard/bin/fretboard"

start_cmd="fretboard_start"
stop_cmd="fretboard_stop"
status_cmd="fretboard_status"

fretboard_start() {
    echo "Starting ${name}."
    su -m ${fretboard_user} -c "\
        SECRET_KEY_BASE='${fretboard_secret_key_base}' \
        PHX_HOST='${fretboard_host}' \
        PORT='${fretboard_port}' \
        PHX_SERVER=true \
        ${command} start"
}

fretboard_stop() {
    echo "Stopping ${name}."
    su -m ${fretboard_user} -c "${command} stop"
}

fretboard_status() {
    su -m ${fretboard_user} -c "${command} pid" \
        && echo "${name} is running." \
        || echo "${name} is not running."
}

run_rc_command "$1"
```

Then enable in `/etc/rc.conf`:

```
fretboard_enable="YES"
fretboard_secret_key_base="your-secret-here"
fretboard_host="fretboard.example.com"
fretboard_port="4000"
```

Make executable and start:

```bash
chmod +x /usr/local/etc/rc.d/fretboard
service fretboard start
```

#### Linux systemd

Create `/etc/systemd/system/fretboard.service`:

```ini
[Unit]
Description=Fretboard Visualizer
After=network.target

[Service]
Type=exec
User=fretboard
Group=fretboard
WorkingDirectory=/opt/fretboard
Environment=SECRET_KEY_BASE=your-secret-here
Environment=PHX_HOST=fretboard.example.com
Environment=PORT=4000
Environment=PHX_SERVER=true
ExecStart=/opt/fretboard/_build/prod/rel/fretboard/bin/server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Then enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable fretboard
sudo systemctl start fretboard
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

After setting up a reverse proxy with SSL:

1. Uncomment the `force_ssl` block in `config/prod.exs`
2. Set `PHX_HOST` to your domain
3. Rebuild the release or Docker image

> **Important:** The `Upgrade` and `Connection` proxy headers are required for LiveView WebSockets to work.

## Useful Commands

### Docker

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

### Native release

```bash
# Check status
_build/prod/rel/fretboard/bin/fretboard pid

# Remote IEx console
_build/prod/rel/fretboard/bin/fretboard remote

# Stop / restart
_build/prod/rel/fretboard/bin/fretboard stop
_build/prod/rel/fretboard/bin/fretboard restart
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
