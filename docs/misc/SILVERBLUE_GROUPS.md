# Adding a User to a Group on Silverblue

On Silverblue, `sudo usermod -aG <group> $USER` alone usually doesn't work. Two things get in the
way: the group is often missing from `/etc/group`, and the change only applies after a reboot.

## Why

rpm-ostree splits the group database across two files. Image-managed system groups live in
`/usr/lib/group`, part of the immutable `/usr` tree, while `/etc/group` holds machine-local entries
and is minimal on a fresh install. NSS merges both at lookup time, so `getent group <group>` and the
kernel's permission checks see the group no matter which file defines it.

`usermod` reads and writes `/etc/group` directly, never `/usr/lib/group`. When a group exists only
in `/usr/lib/group`, there is no line in `/etc/group` for `usermod` to add you to, so the edit has
no effect. `wheel` is the exception that works out of the box: rpm-ostree pre-populates it into
`/etc/group` at compose time (via its `etc-group-members` setting).

## How

Copy the group's entry into `/etc/group` if it isn't already there, then add yourself:

```bash
grep -qE '^<group>:' /etc/group || grep -E '^<group>:' /usr/lib/group | sudo tee -a /etc/group
sudo usermod -aG <group> $USER
```

The `grep -q` guard keeps this idempotent: it copies the line only when missing, so re-running
never appends a duplicate. (Duplicate lines make `usermod` refuse with `Multiple entries named
'<group>'`. Delete the extra line if that happens.)

Then **reboot**. Logging out and back in is not enough: the `systemd --user` instance survives a
GNOME logout and keeps the group set it started with, and the terminals it launches inherit that
stale set. Supplementary groups are fixed at session start, so a reboot is the reliable way to pick
up the change. Confirm with `groups`.

## References

- [Unable to add user to group](https://docs.fedoraproject.org/en-US/fedora-silverblue/troubleshooting/#_unable_to_add_user_to_group) -
  official Fedora Silverblue workaround
- [usermod -a -G fails (rpm-ostree #29)](https://github.com/coreos/rpm-ostree/issues/29) - origin of
  the split group database and the `etc-group-members` mechanism
