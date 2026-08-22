# 0infra/nixos/

NixOS configuration for my machines.

## Commands

Update process:

```
nix flake update --flake ~/0infra/nixos
sudo nixos-rebuild dry-activate --flake ~/0infra/nixos#paolumu
sudo nixos-rebuild switch --flake ~/0infra/nixos#paolumu
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
