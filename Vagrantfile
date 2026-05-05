# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "kraker/rhel-10.0"
  config.vm.hostname = "rhel10"

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
