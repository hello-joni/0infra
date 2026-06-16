# Selfhost Setup

Steps to layer self-hosted services onto a server already provisioned per
[SERVER_SETUP.md](./SERVER_SETUP.md). Currently hosts Actual Budget, SilverBullet, and LibreChat.
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
systemctl --user status podman-librechat-mongodb.service
systemctl --user status podman-librechat-api.service
```

The services listen on loopback ports inside the host and are not reachable from the public
internet:

- Actual: `127.0.0.1:5006`
- SilverBullet: `127.0.0.1:3000`
- LibreChat: `127.0.0.1:8080`

## 4. Expose via Tailscale Serve

Bind each container to the host's tailnet name with automatic HTTPS:

```bash
tailscale serve --bg --https=443 http://localhost:5006   # Actual
tailscale serve --bg --https=8443 http://localhost:3000  # SilverBullet
tailscale serve --bg --https=9443 http://localhost:8080  # LibreChat
```

Verify:

```bash
tailscale serve status
```

Services are now reachable from any device on the tailnet:

- Actual: `https://<hostname>.<tailnet>.ts.net`
- SilverBullet: `https://<hostname>.<tailnet>.ts.net:8443`
- LibreChat: `https://<hostname>.<tailnet>.ts.net:9443`

The `tailscale serve` config persists in `/var/lib/tailscale/` across reboots.

## 5. First-run

### Actual

Open `https://<hostname>.<tailnet>.ts.net` in a browser. Set the server password and create the
budget. Store the server password and the budget E2E password in the Proton Pass `machine-logins`
vault as Login items with username `actual-server@<hostname>` and `actual-budget@<hostname>`.

The budget E2E password is what encrypts the data at rest. Without it, no backup is recoverable.

### LibreChat

LibreChat settings are declarative in `modules/selfhost.nix`. The only non-Nix step is creating the
OpenRouter key file once.

```bash
echo "OPENROUTER_KEY=sk-or-v1-your-key-here" > ~/0selfhost/librechat/openrouter-key
chmod 600 ~/0selfhost/librechat/openrouter-key
```

Replace `sk-or-v1-your-key-here` with your OpenRouter API key. Store the key in Proton Pass as
`openrouter@<hostname>`.

```bash
systemctl --user restart podman-librechat-api.service
```

#### First login

Open `https://<hostname>.<tailnet>.ts.net:9443` and register an account. The first account created
is automatically an admin.

#### Verify a model responds

Select an OpenRouter model and send a message. A reply confirms the full path works. Two failure
modes have distinct causes:

- A `401 Missing Authentication header` means the key is not reaching OpenRouter. Check that
  `~/0selfhost/librechat/openrouter-key` contains `OPENROUTER_KEY=sk-or-...` and that the `apiKey`
  in `librechat.yaml` reads `${OPENROUTER_KEY}` with braces.
- A `404` or model-not-found means the slug is not a real OpenRouter model. The entries under
  `models.default` in `modules/selfhost.nix` must match exact slugs from `openrouter.ai/models`.
