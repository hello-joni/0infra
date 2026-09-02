# Openterface Mini-KVM on Silverblue

Steps to get the Openterface KVM-over-USB device working with the openterfaceQT app on a Silverblue
laptop. The app is a Flatpak (`com.openterface.openterfaceQT`) declared in
[`modules/graphical.nix`](../../modules/graphical.nix); the permissions below are system-level and
applied by hand.

## 1. Serial access (keyboard and mouse)

Add yourself to `dialout` so the app can open `/dev/ttyACM0`. A plain `usermod` is not enough on
Silverblue, see [SILVERBLUE_GROUPS.md](./SILVERBLUE_GROUPS.md):

```bash
grep -qE '^dialout:' /etc/group || grep -E '^dialout:' /usr/lib/group | sudo tee -a /etc/group
sudo usermod -aG dialout $USER
```

Reboot, then confirm with `groups`.

## 2. HID and USB access (firmware updates)

Add udev `uaccess` rules so your session can reach the HID and USB interfaces, needed for firmware
updates and the serial-reset tool:

```bash
sudo tee /etc/udev/rules.d/51-openterface.rules >/dev/null <<'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="534d", ATTRS{idProduct}=="2109", TAG+="uaccess"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="534d", ATTRS{idProduct}=="2109", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="345f", ATTRS{idProduct}=="2109", TAG+="uaccess"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="345f", ATTRS{idProduct}=="2109", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="345f", ATTRS{idProduct}=="2132", TAG+="uaccess"
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="345f", ATTRS{idProduct}=="2132", TAG+="uaccess"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", TAG+="uaccess"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="fe0c", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="fe0c", TAG+="uaccess"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Unplug and replug the device so the ACL applies.

## Skip these

- `make ; sudo make install` (driver build). The kernel's `cdc_acm`/`ch341` already drive the
  device; the app's "Driver Installed" stays red on Fedora and can be ignored.
- The `video` group. Capture works through the session ACL.

## Verify

```bash
groups                       # dialout present
getfacl -p /dev/ttyACM0      # expect a user:<you>:rw- line
```

In the app, the Environment Helper (Advanced menu) shows Serial, HID, and Video green; only "Driver
Installed" stays red.

## References

- [SILVERBLUE_GROUPS.md](./SILVERBLUE_GROUPS.md) - the Silverblue group workaround
- [openterfaceQT on Flathub](https://flathub.org/apps/com.openterface.openterfaceQT)
