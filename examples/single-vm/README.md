# `single-vm/` — minimum viable RHEL 10 VM

The smallest Vagrantfile that brings up `kraker/rhel-10` and does the
registration dance. Useful as a starting point or for ad-hoc testing.

## What it does

- Boots one RHEL 10 VM (`rhel10` hostname) under VirtualBox with
  2 GB RAM and 2 vCPUs.
- Reads `RHSM_USERNAME` / `RHSM_PASSWORD` from your environment and
  feeds them to the `vagrant-registration` plugin, which registers
  the VM against your Red Hat developer subscription at first boot.
- Keeps the VM registered across `vagrant halt` / `vagrant up` cycles
  (only `vagrant destroy` unregisters it from RHSM).

## Why each piece is there

| Line | Why |
|---|---|
| `config.vm.box = "kraker/rhel-10"` | Pulls the published box from HCP Vagrant Registry. |
| `config.registration.username/password` | vagrant-registration needs RHSM creds to attach a subscription at first boot. Drawn from env vars to keep secrets out of source control. |
| `config.registration.unregister_on_halt = false` | Avoids churning your subscription entitlement count on every `vagrant halt`. The VM only unregisters on `vagrant destroy`. |
| `vb.memory / vb.cpus` | Modest defaults — bump these for real workloads. |

## Run it

```sh
export RHSM_USERNAME="your-redhat-username"
export RHSM_PASSWORD="your-redhat-password"
vagrant up
vagrant ssh
# inside the VM:
cat /etc/os-release      # confirm: Red Hat Enterprise Linux 10.0
sudo dnf check-update    # confirm subscription works
exit
vagrant destroy -f
```
