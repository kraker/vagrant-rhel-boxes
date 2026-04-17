# Example Vagrantfiles

Each subdirectory is a self-contained, copy-pasteable Vagrantfile
showing one common way to consume `kraker/rhel-10`. Each example
includes its own README explaining what it demonstrates and any
non-obvious choices.

| Example | What it shows |
|---|---|
| [`single-vm/`](single-vm/) | Smallest possible Vagrantfile. One RHEL 10 VM, vagrant-registration via env vars. |
| [`dev-environment/`](dev-environment/) | Single VM tuned for development: more resources, synced folder, static private network IP. Suitable for VS Code Remote SSH. |

## Common prerequisites

All examples assume:

1. **Vagrant ≥ 2.4** with either VirtualBox or libvirt installed.
2. **The vagrant-registration plugin**:
   ```sh
   vagrant plugin install vagrant-registration
   ```
3. **Red Hat developer credentials** in your environment:
   ```sh
   export RHSM_USERNAME="your-redhat-username"
   export RHSM_PASSWORD="your-redhat-password"
   ```
   (Free account at [developers.redhat.com](https://developers.redhat.com/).)

## Why the registration step

`kraker/rhel-10` is published **unregistered** — the box itself isn't
attached to any RHSM subscription. The `vagrant-registration` plugin
hooks first boot to call `subscription-manager register` against your
own developer subscription, so the running VM has access to RHEL repos
for `dnf install`, errata, etc.

This is the same pattern the legacy `generic/rhel*` boxes used. It's
the standard way to distribute RHEL Vagrant boxes that don't ship
pre-registered (which Red Hat's subscription terms don't allow).
