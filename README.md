# vagrant-rhel-boxes

RHEL Vagrant boxes built with [Red Hat Image Builder][rhdocs] (the
`image-builder` CLI, a Tech Preview tool that's Red Hat's officially
documented path for RHEL 10).

RHEL only — Rocky / Alma / Fedora / CentOS Stream are well-served
elsewhere (Bento, the distros' own orgs).

## Status

**Alpha**: `kraker/rhel-10` v20260416.0 is published on HCP Vagrant
Registry with `virtualbox` and `libvirt` providers. The libvirt
provider hasn't been smoke-tested locally yet — use at your own risk
or `vagrant box add` the libvirt box to verify it boots in your
environment first.

See [`PLAN.md`](PLAN.md) for the project's vision, scope, and roadmap.

## Quick start: consume the published box

```sh
# One-time: install the plugin that registers RHEL with your subscription
vagrant plugin install vagrant-registration

# Provide your Red Hat developer credentials
export RHSM_USERNAME="your-redhat-username"
export RHSM_PASSWORD="your-redhat-password"

# Bring up a VM
vagrant init kraker/rhel-10
vagrant up
vagrant ssh
```

The box ships **unregistered** — the [`vagrant-registration`][vr]
plugin hooks first boot to register against your own RHSM account
using either env vars (above) or `config.registration.*` settings in
the Vagrantfile. See [`examples/virtualbox/`](examples/virtualbox/)
or [`examples/libvirt/`](examples/libvirt/) for a minimal Vagrantfile
per provider.

[vr]: https://github.com/projectatomic/adb-vagrant-registration

Don't have a Red Hat developer account? Sign up free at
[developers.redhat.com](https://developers.redhat.com/).

## Build your own from the recipe

If you'd rather not depend on the published box — or want to customize
the blueprint — the repo IS the recipe. This is the path Red Hat
documents in [their Image Builder docs][rhdocs].

```sh
# Prerequisites (Fedora / RHEL family build host):
sudo dnf install image-builder osbuild osbuild-tools subscription-manager
sudo subscription-manager register --username <your-rh-username>

git clone https://github.com/kraker/vagrant-rhel-boxes
cd vagrant-rhel-boxes

# Build a box (libvirt or virtualbox)
./scripts/build.sh rhel-10.0 vagrant-libvirt
# or
./scripts/build.sh rhel-10.0 vagrant-virtualbox
```

The output `.box` file lands in `build/<version>-<provider>/`. You can
`vagrant box add` it directly or wrap it in your own Vagrantfile.

## How the project is laid out

```
blueprints/        # osbuild TOML blueprints (one per RHEL major version)
scripts/           # build.sh and helpers
examples/          # minimal Vagrantfile per provider for the published box
references/        # Red Hat docs the project is based on
PLAN.md            # vision, scope, decisions, lessons learned
```

[rhdocs]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/composing_a_customized_rhel_system_image/creating-vagrant-boxes-with-rhel-image-builder

## License

Apache-2.0 — see [`LICENSE`](LICENSE).
