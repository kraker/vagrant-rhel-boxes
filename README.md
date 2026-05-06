# vagrant-rhel-boxes

Build and publish RHEL Vagrant boxes for libvirt and VirtualBox.

## Available Boxes

Published to [Vagrant Cloud under `kraker`][1].

* `kraker/rhel-10` — RHEL 10 base box (libvirt + virtualbox, x86_64)
* `kraker/rhel-9` — RHEL 9 base box (libvirt + virtualbox, x86_64)

[1]: https://app.vagrantup.com/kraker

## Install Prerequisites

Using a published box requires Vagrant, a virtualization provider, and
the [`vagrant-registration`][2] plugin to handle Red Hat Subscription
Manager register/unregister automatically on `vagrant up` /
`vagrant destroy`.

* [Install Vagrant](https://developer.hashicorp.com/vagrant/install)
* For the libvirt provider, install `libvirt-devel` and the
  [vagrant-libvirt plugin][3]. `libvirt-devel` requires the CodeReady
  Builder (CRB) repo to be enabled — see the
  [EPEL Quickstart](https://docs.fedoraproject.org/en-US/epel/#_quickstart)
  for the right command for your distro. Then:

```bash
dnf install libvirt-devel
vagrant plugin install vagrant-libvirt
```

* For the VirtualBox provider, [install VirtualBox][4].
* Install the registration plugin:

```bash
vagrant plugin install vagrant-registration
```

A Red Hat subscription is required for the guest. A free
[Red Hat Developer][5] account is sufficient for personal use.

[2]: https://github.com/projectatomic/adb-vagrant-registration
[3]: https://vagrant-libvirt.github.io/vagrant-libvirt/installation.html
[4]: https://www.virtualbox.org/wiki/Downloads
[5]: https://developers.redhat.com/

## Using a Box

Set your subscription credentials as env vars, then `vagrant up`. The
included `Vagrantfile` reads from `RHSM_*` env vars to authenticate with Red Hat
Subscription Manager.

```bash
# Activation key (recommended for automation):
export RHSM_ORG=...
export RHSM_ACTIVATIONKEY=...

# Or username/password (Red Hat Developer account):
export RHSM_USERNAME=...
export RHSM_PASSWORD=...

vagrant up --provider=libvirt   # or --provider=virtualbox
```

If neither pair of env vars is set, the VM still boots but without an attached
subscription which provides access to Red Hat's repositories.

## Building Boxes Locally

The project uses Red Hat's [`image-builder`][6] CLI driven by an
Ansible playbook to produce the boxes that get published. To run a
build yourself:

* [Install Git](https://git-scm.com/install/)
* [Install uv](https://docs.astral.sh/uv/getting-started/installation/)

```bash
git clone https://github.com/kraker/vagrant-rhel-boxes.git
cd vagrant-rhel-boxes
uv sync
uv run ansible-playbook build_box.yml -e distro=rhel-10.0 -e provider=libvirt
```

The resulting `.box` lands under `build/`. See `CLAUDE.md` for
architecture details and the CI publish flow.

[6]: https://osbuild.org/docs/user-guide/image-builder-cli/

## Roadmap

* Distros
  + [X] RHEL 10.x
  + [X] RHEL 9.x
* Architectures
  + [X] x86_64 / amd64
  + [ ] aarch64 / arm64 (needs a separate self-hosted runner)
* Release automation
  + [X] Vagrant Cloud publish on tag
  + [ ] Schedule monthly tagged releases
  + [ ] Smoke-test boxes in CI before publishing
  + [ ] Pin GitHub Actions to commit SHAs (supply-chain hardening for the self-hosted runner)
* [ ] VirtualBox guest additions
* [ ] Public-facing usage guide / write-up

### Someday/Maybe?

* Fedora support
* CentOS Stream support

## LICENSE

MIT

## Author

Written by Alex Kraker ([@kraker](https://github.com/kraker))
