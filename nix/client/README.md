# 0infra/nix/client/

NixOS configuration for my client machines.

## Commands

Update process:

```
nix flake update --flake ~/0infra/nix/client
sudo nixos-rebuild dry-activate --flake ~/0infra/nix/client#paolumu
sudo nixos-rebuild switch --flake ~/0infra/nix/client#paolumu
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
