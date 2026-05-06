# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "kraker/rhel-10"
  config.vm.hostname = "rhel10"

  # vagrant-registration: register the guest with subscription-manager so dnf
  # can pull from RHEL BaseOS / AppStream. Credentials come from env vars —
  # never hardcode them in this file. Set ONE of:
  #
  #   RHSM_ORG + RHSM_ACTIVATIONKEY   (recommended for automation)
  #   RHSM_USERNAME + RHSM_PASSWORD   (interactive Red Hat Developer account)
  #
  # If neither is set, registration is skipped — the VM boots and SSH works,
  # but subscription-gated `dnf install` will fail until you register
  # manually inside the guest.

  # Suppress --auto-attach: RHEL 9+ uses Simple Content Access and
  # subscription-manager rejects the flag the plugin passes by default.
  config.registration.auto_attach = false

  if ENV['RHSM_ORG'] && ENV['RHSM_ACTIVATIONKEY']
    config.registration.org           = ENV['RHSM_ORG']
    config.registration.activationkey = ENV['RHSM_ACTIVATIONKEY']
  elsif ENV['RHSM_USERNAME'] && ENV['RHSM_PASSWORD']
    config.registration.username = ENV['RHSM_USERNAME']
    config.registration.password = ENV['RHSM_PASSWORD']
  else
    config.registration.skip = true
  end

  # Shared settings across providers
  cpus = 2
  memory = 2048

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = cpus
    libvirt.memory = memory
    libvirt.video_type = "virtio"
    # RHEL 10 host doesn't support cirrus; virtio is what's available.
  end

  config.vm.provider :virtualbox do |vb|
    vb.cpus = cpus
    vb.memory = memory
    # Headless by default; flip to true if you want the GUI window.
    vb.gui = false
  end

  # Disable the default synced folder — rsync/nfs/virtiofs adds setup friction
  # and most dev workflows don't need it. Re-enable explicitly if you do.
  config.vm.synced_folder ".", "/vagrant", disabled: true
end
