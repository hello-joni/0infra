# LibreChat setup

Two manual steps remain after `nixos-rebuild switch`. The activation script creates all other state.

## 1. Set the API keys

```bash
ssh joni@<host>
nano ~/.local/share/librechat/librechat.env
```

Replace the `CHANGE_ME` with the OpenRouter and Kagi API keys. Then restart the container:

```bash
podman restart librechat
```

## 2. Create the account

Open `https://vespoid.spotted-elevator.ts.net` from a tailnet device. Click Register and create the account. The first account becomes admin.
