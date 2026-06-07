# Swap and hibernate on Silverblue

Replaces Fedora's default zram swap with zswap over a disk-backed swapfile, sized for hibernation.

Silverblue ships zram (a compressed swap device in RAM) plus `systemd-oomd`. zram gives no graceful
degradation under pressure and can't back hibernation. This swaps it for zswap, which compresses hot
pages in RAM and tiers cold pages out to a swapfile on the SSD. `systemd-oomd` stays as is.
Background: https://chrisdown.name/2026/03/24/zswap-vs-zram-when-to-use-what.html

Assumes Fedora Silverblue (or another atomic variant) on a btrfs root. Works with or without LUKS;
if root is encrypted the swapfile inherits that encryption. Every per-machine value (RAM size,
filesystem UUID, swap offset) is derived by the commands below, so this applies to any such machine.

Run the snippets in `bash` or `sh`. They use POSIX shell syntax (variables, `$(...)`, heredocs) that
does not work in fish; if fish is your shell, run `sh` first.

## 0. Preflight

```bash
cat /sys/power/state            # must contain "disk", or the kernel can't hibernate
mokutil --sb-state              # Secure Boot state
```

If Secure Boot is enabled, kernel lockdown may block hibernation. If `systemctl hibernate` later
fails citing lockdown, either disable Secure Boot in firmware or set up signed hibernation.

## 1. Disable zram

```bash
sudo swapoff /dev/zram0
sudo systemctl stop systemd-zram-setup@zram0.service
sudo systemctl mask systemd-zram-setup@zram0.service   # stays off across reboots and ostree updates
```

## 2. Create the swapfile

Hibernation needs swap at least the size of RAM. This computes full RAM plus a 2 GB buffer, rounded
up to the next multiple of 4 GB (e.g. 16 GB RAM gives 20 GB, 32 GB gives 36 GB). The swapfile goes on
its own btrfs subvolume so it is never snapshotted; `mkswapfile` handles the NOCOW and
no-compression requirements btrfs swapfiles have.

```bash
ram_gib=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
swap_gib=$(( (ram_gib + 2 + 3) / 4 * 4 ))   # RAM + 2G buffer, rounded up to a multiple of 4

sudo btrfs subvolume create /var/swap
sudo btrfs filesystem mkswapfile --size ${swap_gib}g /var/swap/swapfile
sudo swapon /var/swap/swapfile
echo "created ${swap_gib}G swapfile"
```

Enable it on every boot by appending it to `/etc/fstab`:

```bash
echo '/var/swap/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```

## 3. Enable zswap and the resume target (one reboot)

These derive the root filesystem UUID and the swapfile's on-disk offset (btrfs needs its own tool for
the offset, `filefrag` is wrong here), then append all kargs in one command so the deployment only
rebuilds once. Modern kernels default to the good zswap allocator (zsmalloc), so only the compressor
needs setting. The UUID comes from `/sysroot`; on an atomic system `/` is a composefs overlay with no
UUID of its own.

```bash
root_uuid=$(findmnt -no UUID /sysroot)
offset=$(sudo btrfs inspect-internal map-swapfile -r /var/swap/swapfile)

sudo rpm-ostree kargs \
  --append-if-missing=zswap.enabled=1 \
  --append-if-missing=zswap.compressor=zstd \
  --append-if-missing=resume=UUID=${root_uuid} \
  --append-if-missing=resume_offset=${offset}
```

Reboot to apply. If root is on LUKS, resume needs the initramfs to unlock it first; Fedora adds
`rd.luks.uuid=` automatically on encrypted installs. Confirm it is present (encrypted machines only):

```bash
rpm-ostree kargs | grep -o 'rd.luks.uuid=[^ ]*'
```

## 4. Set swappiness

On an SSD with zswap, reclaiming anonymous and file pages costs about the same, so swappiness should
be near 100 (full equality) rather than the kernel's cautious default. Fedora's `tuned` profile sets
this value, so a plain `sysctl.d` drop-in would be overridden. Set it through a `tuned` drop-in that
inherits the currently active profile:

```bash
base=$(tuned-adm active | awk -F': ' '{print $2}')   # capture before switching
sudo mkdir -p /etc/tuned/profiles/laptop-swap
sudo tee /etc/tuned/profiles/laptop-swap/tuned.conf >/dev/null <<EOF
[main]
include=${base}

[sysctl]
vm.swappiness=100
EOF
sudo tuned-adm profile laptop-swap
```

If the active base is `throughput-performance`, note that it is a server profile that disables CPU
power saving and is a poor fit for a laptop; `balanced` is better for battery. Switching base is a
separate decision, so edit the `include=` line if you want to change it.

## 5. Add Hibernate to the GNOME menu

GNOME has no hibernate entry by default. Install the Extension Manager and the Hibernate Status
Button extension:

```bash
flatpak install flathub com.mattjakeman.ExtensionManager
```

Open Extension Manager, search the Browse tab for "Hibernate Status Button", install it. Hibernate
then appears in the top-right system menu.

Optional, suspend-then-hibernate: most modern laptops only support s2idle (light sleep that slowly
drains the battery), not deep S3. Suspend-then-hibernate sleeps lightly first, then hibernates after
a delay, capping the drain:

```bash
sudo mkdir -p /etc/systemd/sleep.conf.d
printf '[Sleep]\nHibernateDelaySec=3600\n' | sudo tee /etc/systemd/sleep.conf.d/10-delay.conf
```

GNOME manages the lid switch itself, so closing the lid still does a plain suspend. The reliable
levers are the extension's Hibernate button, `systemctl suspend-then-hibernate`, or binding the
power key in `/etc/systemd/logind.conf.d/`.

## Verify

```bash
swapon --show                              # lists /var/swap/swapfile, no zram
cat /sys/module/zswap/parameters/enabled   # Y
cat /proc/sys/vm/swappiness                # 100
sudo systemctl hibernate                   # should power off, then restore session on next power-on
```

## Hardware notes

- Confirm sleep state: `cat /sys/power/mem_sleep`. If it reads `[s2idle]` with no `deep`, the machine
  has no S3 and suspend-then-hibernate is worth setting up (see step 5).
- Screen artifacts or a misbehaving cursor after resume are usually panel self-refresh. Add a karg:
  `i915.enable_psr=0` on Intel, `amdgpu.dcdebugmask=0x10` on AMD.
- Some SSDs are unstable resuming from s2idle. If you hit lockups after suspend, prefer hibernate
  over leaving the machine suspended.
- If `systemctl hibernate` fails, check for an SELinux denial with `sudo ausearch -m AVC -ts recent`
  and build a local policy with `audit2allow` if one shows up.
