# 0infra non-nixos-hm

Nix Home Manager configuration for my machines that don't run NixOS.

## Activation

```bash
home-manager switch --flake ~/0infra/non-nixos-hm#laptop
home-manager switch --flake ~/0infra/non-nixos-hm#server
home-manager switch --flake ~/0infra/non-nixos-hm#phone
home-manager switch --flake ~/0infra/non-nixos-hm#work
```

## Maintenance

### Nix

Updating Nix (run switch command after):

```bash
nix flake update --flake ~/0infra/non-nixos-hm
```

Garbage collecting Nix store:

```bash
nix-collect-garbage -d
```

### OS-Specific

Updating Fedora Silverblue packages:

```bash
rpm-ostree upgrade
systemctl reboot
```

Updating Fedora packages:

```bash
sudo dnf upgrade
```

Updating Debian packages:

```bash
sudo apt update && sudo apt upgrade
```
