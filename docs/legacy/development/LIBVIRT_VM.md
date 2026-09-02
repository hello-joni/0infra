# Libvirt VM

A full virtual machine managed with libvirt. Uses a Debian cloud image plus a generated cloud-init
seed ISO to inject your SSH key on first boot, copy-on-write overlays for cheap throwaway sandboxes,
and `virsh` snapshots so reverting after a wedged experiment is one command.

VMs run rootless using user-mode networking (passt), so each VM gets its own isolated network with
the host as gateway. You can run several side-by-side, but they can't reach each other on a shared
subnet. If you need VM-to-VM connectivity, layer Tailscale or WireGuard inside the guests.

## 1. One-time host setup

Layer libvirt and friends on the Silverblue host:

```bash
sudo rpm-ostree install \
  qemu-kvm libvirt-client libvirt-daemon-driver-qemu \
  libvirt-daemon-driver-storage-core virt-install passt
sudo systemctl reboot
```

Sanity check:

```bash
virsh list --all
```

Should print an empty table.

## 2. Download the base image

Use the Debian `generic` cloud image, not `genericcloud`. The genericcloud variant ships a
stripped-down kernel that disables many device drivers, including the one needed to read the
cloud-init seed CD-ROM. cloud-init then silently fails to apply any of your configuration.

```bash
mkdir -p ~/.local/share/libvirt/images
curl -L -o ~/.local/share/libvirt/images/debian-12-generic.qcow2 \
  https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```

The base image is read-only and reusable across as many VMs as you want.

## 3. Write the cloud-init seed

The seed is a small ISO holding two YAML files (`user-data` and `meta-data`) that cloud-init reads
on first boot. `user-data` defines the VM's user account and SSH keys; `meta-data` carries an
`instance-id` that cloud-init's NoCloud datasource requires.

```bash
mkdir -p /tmp/sandbox-seed
```

```bash
bash -c 'cat > /tmp/sandbox-seed/user-data <<EOF
#cloud-config
users:
  - name: debian
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_ed25519.pub)
ssh_pwauth: true
password: test123
chpasswd: { expire: false }
EOF'
```

`ssh_pwauth` + `password` set up a console-login fallback so you can `virsh console` into the VM as
`debian` if SSH ever fails. Remove those lines if you don't want them.

```bash
bash -c 'cat > /tmp/sandbox-seed/meta-data <<EOF
instance-id: sandbox
local-hostname: sandbox
EOF'
```

Build the seed ISO:

```bash
xorriso -as mkisofs -output ~/.local/share/libvirt/images/sandbox-seed.iso \
  -volid cidata -joliet -rock /tmp/sandbox-seed/user-data /tmp/sandbox-seed/meta-data
```

## 4. Create the VM

Each VM gets its own copy-on-write overlay backed by the base. The `30G` is the cap the guest sees;
the overlay file is sparse, starts a few hundred KB on disk, and grows only as the guest writes
data.

```bash
qemu-img create -f qcow2 -F qcow2 \
  -b ~/.local/share/libvirt/images/debian-12-generic.qcow2 \
  ~/.local/share/libvirt/images/sandbox.qcow2 30G
```

`virt-install --import` builds the libvirt definition around the overlay and attaches the seed ISO
as a CD-ROM. The `portForward` maps a host port to the VM's SSH port; each running VM needs a unique
host port.

```bash
virt-install \
  --name sandbox \
  --os-variant debian12 \
  --memory 4096 --vcpus 4 \
  --disk path=$HOME/.local/share/libvirt/images/sandbox.qcow2 \
  --disk path=$HOME/.local/share/libvirt/images/sandbox-seed.iso,device=cdrom \
  --import \
  --network passt,portForward=2222:22 \
  --graphics none --noautoconsole
```

Wait ~30s for cloud-init, then SSH in:

```bash
ssh -p 2222 debian@127.0.0.1
```

If SSH isn't reachable, drop to the serial console (`virsh console sandbox`, exit with `Ctrl-]`) and
log in as `debian` with the password from your user-data.

## 5. Snapshots

```bash
# Saves a new snapshot of the VM as it is right now
# virsh snapshot-create-as <vm-name> <snapshot-name>
virsh snapshot-create-as sandbox clean

# Lists all snapshots taken of this VM
# virsh snapshot-list <vm-name>
virsh snapshot-list sandbox

# Rewinds the VM to a named snapshot, discarding everything after
# virsh snapshot-revert <vm-name> <snapshot-name>
virsh snapshot-revert sandbox clean

# Removes a saved snapshot (the VM itself is unaffected)
# virsh snapshot-delete <vm-name> <snapshot-name>
virsh snapshot-delete sandbox clean
```

Snapshots are internal to the qcow2 overlay, so they cost only the delta from the snapshot point.
Take one before any change you might want to undo wholesale.

## 6. Lifecycle

```bash
# Boots a stopped VM
# virsh start <vm-name>
virsh start sandbox

# Sends an ACPI shutdown signal so the guest exits cleanly
# virsh shutdown <vm-name>
virsh shutdown sandbox

# Force-stops the VM immediately (like pulling the power cord)
# virsh destroy <vm-name>
virsh destroy sandbox

# Attaches to the VM's serial console (exit with Ctrl-])
# virsh console <vm-name>
virsh console sandbox
```

## 7. Teardown

Delete one VM:

```bash
# Force-stops the VM if it's still running
# virsh destroy <vm-name>
virsh destroy sandbox

# Removes the VM's libvirt definition along with its overlay disk and snapshot metadata
# virsh undefine <vm-name> --remove-all-storage --snapshots-metadata
virsh undefine sandbox --remove-all-storage --snapshots-metadata

# Remove the seed ISO (libvirt's --remove-all-storage skips read-only disks)
rm ~/.local/share/libvirt/images/sandbox-seed.iso
```

Delete the base image too, only when no other overlay still backs onto it:

```bash
rm ~/.local/share/libvirt/images/debian-12-generic.qcow2
```
