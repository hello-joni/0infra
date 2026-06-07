# Swap and hibernate on Silverblue

Replaces Silverblue's default zram with zswap over a hibernation-sized swapfile. Assumes an atomic
Fedora variant on btrfs. Run snippets in `bash`/`sh`, not fish.
Background: https://chrisdown.name/2026/03/24/zswap-vs-zram-when-to-use-what.html

## 0. Preflight

```bash
cat /sys/power/state    # must contain "disk"
mokutil --sb-state      # if Secure Boot is on, lockdown can block hibernate
```

## 1. Disable zram

```bash
sudo swapoff /dev/zram0
sudo systemctl stop systemd-zram-setup@zram0.service
sudo systemctl mask systemd-zram-setup@zram0.service
```

## 2. Create the swapfile

Sized to RAM + 2 GB rounded up to a multiple of 4, on its own subvolume so it is never snapshotted.

```bash
ram_gib=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
swap_gib=$(( (ram_gib + 2 + 3) / 4 * 4 ))

sudo btrfs subvolume create /var/swap
sudo btrfs filesystem mkswapfile --size ${swap_gib}g /var/swap/swapfile
sudo swapon /var/swap/swapfile

echo '/var/swap/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```

## 3. Enable zswap and resume (one reboot)

UUID comes from `/sysroot` (on atomic, `/` is a composefs overlay with no UUID).

```bash
root_uuid=$(findmnt -no UUID /sysroot)
offset=$(sudo btrfs inspect-internal map-swapfile -r /var/swap/swapfile)

sudo rpm-ostree kargs \
  --append-if-missing=zswap.enabled=1 \
  --append-if-missing=zswap.compressor=zstd \
  --append-if-missing=resume=UUID=${root_uuid} \
  --append-if-missing=resume_offset=${offset}
```

Reboot to apply. Encrypted roots resume through the existing `rd.luks.uuid=` karg.

## 4. Set swappiness

100 suits SSD + zswap. Fedora's `tuned` profile overrides `sysctl.d`, so set it through a tuned
drop-in:

```bash
base=$(tuned-adm active | awk -F': ' '{print $2}')
sudo mkdir -p /etc/tuned/profiles/laptop-swap
sudo tee /etc/tuned/profiles/laptop-swap/tuned.conf >/dev/null <<EOF
[main]
include=${base}

[sysctl]
vm.swappiness=100
EOF
sudo tuned-adm profile laptop-swap
```

## 5. Triggering hibernate

`systemctl hibernate`, or Super+Shift+H.
```
