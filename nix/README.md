# 0infra/nix/

NixOS configurations for all my machines.

## Commands

Update process:

```
nix flake update --flake ~/0infra/nix
sudo nixos-rebuild dry-activate --flake ~/0infra/nix#paolumu
sudo nixos-rebuild switch --flake ~/0infra/nix#paolumu
```

Update a server:

```bash
nixos-rebuild switch --flake ~/0infra/nix#vespoid --target-host root@vespoid
```

Generate ssh key:

```
ssh-keygen -t ed25519
```

Fresh checkout of 0nix:

```
direnv allow
pre-commit install -c .pre-commit-config.yaml
```
