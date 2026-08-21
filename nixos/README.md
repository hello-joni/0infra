# 0nix

## Commands

Update process:

```
nix flake update --flake ~/0nix
sudo nixos-rebuild dry-activate --flake ~/0nix#paolumu
sudo nixos-rebuild switch --flake ~/0nix#paolumu
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
