# Server setup

How to set up a Hetzner server with NixOS using `nixos-anywhere` and Tailscale SSH.

## Prerequisites

- A new Debian Hetzner server in `opentofu/` with no configured SSH key
  - The server's IPv4 address
  - The server's temporary root password (emailed by Hetzner)
- A machine configuration in `nix/server/`

## Setup steps

### Password change

SSH into the server and log in with the emailed password.

```bash
ssh root@<ipv4>
```

When prompted, set a new password. This password will be cleared when NixOS is installed.

### Install

From `nix/server/`, run the installer:

```bash
SSHPASS='<password>' nix run github:nix-community/nixos-anywhere -- \
  --flake ~/0infra/nix/server#<machine> \
  --target-host root@<ipv4> \
  --env-password
```

Wait for the install to finish and the machine to reboot.

### First login + Tailscale

Open the Hetzner console for the server. Log in as:

```
login: root
password: rootpasswd
```

Join the tailnet:

```bash
tailscale up --ssh
```

Open the printed authentication URL and approve the new tailnet addition. Exit the Hetzner console.

### Change Passwords

SSH from another device on the tailnet to change passwords.

```bash
ssh root@<machine>
passwd
passwd joni
```

## Notes

- To recover from a failed install, rebuild the server to `debian-13` from the Hetzner console. Hetzner will email a new root password.
  - Will need to run `ssh-keygen -R <ipv4>` to clear bad known_hosts entry
  - May also need to delete the machine from Tailscale console: [https://console.tailscale.com/admin/machines]
