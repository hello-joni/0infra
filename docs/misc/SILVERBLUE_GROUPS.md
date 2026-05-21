# Adding a User to a Group on Silverblue

`sudo usermod -aG <group> $USER` alone usually does nothing on Silverblue. The command exits
successfully, but the membership never takes effect.

## Why

rpm-ostree splits the group database across two files. Image-managed system groups live in
`/usr/lib/group`, part of the immutable `/usr` tree, while `/etc/group` holds machine-local entries
and is minimal on a fresh install. NSS merges both at lookup time, so `getent group <group>` and the
kernel's permission checks see the group no matter which file defines it.

`usermod` reads and writes `/etc/group` directly. When a group exists only in `/usr/lib/group`,
there is no line in `/etc/group` for `usermod` to append your user to, so the edit has no effect.
`wheel` is the exception that works out of the box: rpm-ostree pre-populates it into `/etc/group` at
compose time (via its `etc-group-members` setting).

## How

Copy the group's entry from `/usr/lib/group` into `/etc/group` first, then add yourself:

```bash
grep -E '^<group>:' /usr/lib/group | sudo tee -a /etc/group
sudo usermod -aG <group> $USER
```

Log out and back in, or reboot, for the new membership to apply. Confirm with `groups` or `id`.

## References

- [Unable to add user to group](https://docs.fedoraproject.org/en-US/fedora-silverblue/troubleshooting/#_unable_to_add_user_to_group) -
  official Fedora Silverblue workaround
- [usermod -a -G fails (rpm-ostree #29)](https://github.com/coreos/rpm-ostree/issues/29) - origin of
  the split group database and the `etc-group-members` mechanism
