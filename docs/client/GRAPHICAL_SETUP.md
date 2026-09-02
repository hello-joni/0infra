# First-Time Setup

Use NixOS GNOME graphical installer.

At the partitions step, choose "manual partition".

Create 2 partitions:

- 1024 MiB partition
  - filesystem: fat32
  - mountpoint: /boot
  - label: ESP
  - checkbox: "boot" flag only
- remainder of disk
  - filesystem: btrfs with encryption
  - mountpoint: /
  - label: root
  - checkbox: none

When booted, run:

```
nix-shell -p git
git clone https://github.com/hello-joni/0infra ~/0infra
cd ~/0infra/nix/client
cp /etc/nixos/hardware-configuration.nix ~/0infra/nix/client/nixos
git add .
sudo nixos-rebuild switch --flake ~/0infra/nix/client#paolumu
```

Other steps:

- LibreWolf
- Syncthing
- Zed/Kagi
- Tailscale
- ssh keys

```
ssh-keygen -t ed25519 -C "comment"
```
