# vagrant-rhel-boxes

Automate building RHEL Vagrant boxes.

## Prerequisites

1. HashiCorp Vagrant
2. CodeReady Builder (CRB) & EPEL

### vagrant-libvirt

vagrant-libvirt needs libvirt-devel:

```bash
subscription-manager repos --enable codeready-builder-for-rhel-10-$(arch)-rpms
dnf install libvirt-devel
```

Install vagrant-libvirt plugin:

```bash
vagrant plugin install vagrant-libvirt
```

## Setup OSBuild Server

```bash
ansible-navigator run infra.osbuild.osbuild_setup_server
```

## Notes

* Consider using [myllynen.rhel-image](https://github.com/myllynen/rhel-image)
  role. Note that it just seems to be a wrapper for `composer-cli`.
