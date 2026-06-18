# Selfhost Setup

Steps to layer self-hosted services onto a server already provisioned per
[SERVER_SETUP.md](./SERVER_SETUP.md). Currently hosts Actual Budget, SilverBullet, and Open WebUI.
Access is Tailscale-only via `tailscale serve` with automatic HTTPS.

## 1. Prerequisites

A Rocky Linux server with the `server` profile already activated (Tailscale up, Syncthing running,
0everything synced). The `selfhost` profile is a superset of `server`, so the same machine just
swaps profiles.

## 2. Enable user lingering

User systemd services need lingering enabled to start at boot without a login session:

```bash
sudo loginctl enable-linger jhen
```

## 3. Switch to the selfhost profile

Before switching, create the Open WebUI secret file. It holds the OpenRouter key and a stable
session key, and it stays out of this repo because the repo is public. Paste the block, then paste
the OpenRouter key at the prompt:

```bash
(
read -rsp 'OpenRouter API key: ' OPENAI_KEY; echo
umask 077
cat > ~/0selfhost/open-webui-secret.env <<EOF
OPENAI_API_KEYS=$OPENAI_KEY
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
EOF
)
```

The subshell buffers the whole block before running, so the prompt reads your key instead of the next
line, and `umask 077` writes the file as 600. Keep `WEBUI_SECRET_KEY` stable, because Open WebUI uses
it to encrypt stored credentials, so rotating it invalidates them.

```bash
home-manager switch --flake ~/0config#selfhost -b backup
```

This installs Podman quadlets for each container declared in `modules/selfhost.nix` and starts them
as user systemd services. Verify:

```bash
systemctl --user status podman-actual.service
systemctl --user status podman-open-webui.service
systemctl --user status podman-mcpo.service
```

The services listen on loopback ports inside the host and are not reachable from the public
internet:

- Actual: `127.0.0.1:5006`
- SilverBullet: `127.0.0.1:3000`
- Open WebUI: `127.0.0.1:8080`

## 4. Expose via Tailscale Serve

Bind each container to the host's tailnet name with automatic HTTPS:

```bash
tailscale serve --bg --https=443 http://localhost:5006   # Actual
tailscale serve --bg --https=8443 http://localhost:3000  # SilverBullet
tailscale serve --bg --https=9443 http://localhost:8080  # Open WebUI
```

Verify:

```bash
tailscale serve status
```

Services are now reachable from any device on the tailnet:

- Actual: `https://<hostname>.<tailnet>.ts.net`
- SilverBullet: `https://<hostname>.<tailnet>.ts.net:8443`
- Open WebUI: `https://<hostname>.<tailnet>.ts.net:9443`

The `tailscale serve` config persists in `/var/lib/tailscale/` across reboots.

## 5. First-run

### Actual

Open `https://<hostname>.<tailnet>.ts.net` in a browser. Set the server password and create the
budget. Store the server password and the budget E2E password in the Proton Pass `machine-logins`
vault as Login items with username `actual-server@<hostname>` and `actual-budget@<hostname>`.

The budget E2E password is what encrypts the data at rest. Without it, no backup is recoverable.

### Open WebUI

Open `https://<hostname>.<tailnet>.ts.net:9443` in a browser. With `WEBUI_AUTH=False` the interface
loads without a login page.

The OpenRouter connection, native tool calling, the mcpo filesystem tool, and the default model are
all set through the environment in `modules/selfhost.nix`, so none of them is configured in the UI.
`ENABLE_PERSISTENT_CONFIG=False` makes that file authoritative, so a setting changed in the UI does
not survive a restart.

The one setting with no environment handle is the system prompt. Set it once under Settings, then
General. It only needs to tell the model to read `/0llm/AGENTS.md` and treat `/0llm` as its context,
so it does not change when that guidance changes.

Store the OpenRouter API key in the Proton Pass `machine-logins` vault as a Login item with username
`openrouter@<hostname>`.
