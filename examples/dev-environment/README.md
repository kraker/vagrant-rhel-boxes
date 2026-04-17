# `dev-environment/` — RHEL 10 dev VM for Remote SSH workflows

A single RHEL 10 VM sized and wired for development work over SSH.
The intended workflow is to connect from VS Code (or JetBrains Gateway,
or `nvim` over SSH, etc.) to the VM and edit files on the synced
project mount.

## What it does

- Boots one RHEL 10 VM (`rhel10-dev`) with **4 GB RAM and 4 vCPUs**.
- Configures a **static private network IP** at `192.168.56.50` so
  your `~/.ssh/config` doesn't need to chase changing ports.
- Mounts the directory containing the Vagrantfile to
  `/home/vagrant/project` on the VM via **rsync** synced folder.
- Registers with RHSM at first boot (same as `single-vm/`).

## Why each piece is there

| Line | Why |
|---|---|
| `private_network ip:` | A stable IP makes adding the VM to `~/.ssh/config` a one-time setup; no need to re-run `vagrant ssh-config` after each restart. |
| `synced_folder type: "rsync"` | Files you edit on the VM (via Remote SSH) sync back to the host. rsync is portable across providers; vboxsf works only with VirtualBox. |
| `rsync__exclude` | Avoids syncing the `.git/` and `.vagrant/` directories — fine to live only on the host. |
| `vb.memory = "4096"`, `vb.cpus = 4` | Comfortable for compilation, language servers, multi-tab editing. Bump higher for heavier workloads (e.g., container builds). |

## Recommended workflow

In one terminal:

```sh
export RHSM_USERNAME="your-redhat-username"
export RHSM_PASSWORD="your-redhat-password"
vagrant up
vagrant ssh-config >> ~/.ssh/config   # one-time
```

Now in VS Code: `Remote-SSH: Connect to Host...` → pick `default` (or
rename in your ssh config to something like `rhel10-dev`). Open the
folder `/home/vagrant/project`.

Optional, in another terminal — keep file changes flowing from host to
VM as you edit:

```sh
vagrant rsync-auto
```

When done:

```sh
vagrant destroy -f
```
