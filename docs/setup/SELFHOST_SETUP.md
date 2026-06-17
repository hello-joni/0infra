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

```bash
home-manager switch --flake ~/0config#selfhost -b backup
```

This installs Podman quadlets for each container declared in `modules/selfhost.nix` and starts them
as user systemd services. Verify:

```bash
systemctl --user status podman-actual.service
systemctl --user status podman-open-webui.service
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

Open `https://<hostname>.<tailnet>.ts.net:9443` in a browser. With `WEBUI_AUTH=False`, the interface
loads immediately without a login page.

OpenRouter is configured as an OpenAI-compatible connection:

1. Go to **Admin Settings** → **Connections** → **OpenAI**
2. Click **+ Add Connection**
3. Set **URL** to `https://openrouter.ai/api/v1`
4. Paste your OpenRouter **API Key**
5. Add model IDs to the **Model IDs (Filter)** allowlist (OpenRouter returns thousands of models;
   filtering prevents UI slowdown)
6. Click **Save**

The OpenRouter API key should be stored in the Proton Pass `machine-logins` vault as a Login item
with username `openrouter@<hostname>`.
