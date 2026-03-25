Vagrant.configure("2") do |config|

  # bento/ubuntu-24.04 has both x86_64 and ARM64 variants (works on Apple Silicon)
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "hive-analysis"

  config.vm.network "forwarded_port", guest: 9200, host: 9200, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5601, host: 5601, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5044, host: 5044, host_ip: "127.0.0.1"

  config.vm.synced_folder "..", "/home/vagrant/hive", type: "rsync",
    rsync__exclude: [
      ".git/",
      "phase4a/phase4a-elk/esdata/",
      "phase4c/phase4c-enrichment/venv/"
    ]

  # VirtualBox (default — macOS Intel, Windows, Linux)
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "hive-analysis"
    vb.memory = 5120
    vb.cpus   = 2
    vb.gui    = false
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  # VMware Fusion / Workstation (better on Apple Silicon)
  # vagrant plugin install vagrant-vmware-desktop
  config.vm.provider "vmware_desktop" do |vmw|
    vmw.vmx["displayName"] = "hive-analysis"
    vmw.vmx["memsize"]     = "5120"
    vmw.vmx["numvcpus"]    = "2"
    vmw.gui = false
  end

  # Parallels (macOS only)
  # vagrant plugin install vagrant-parallels
  config.vm.provider "parallels" do |prl|
    prl.name   = "hive-analysis"
    prl.memory = 5120
    prl.cpus   = 2
  end

  # Hyper-V (Windows — requires PowerShell as Administrator)
  config.vm.provider "hyperv" do |hv|
    hv.vmname          = "hive-analysis"
    hv.memory          = 5120
    hv.cpus            = 2
    hv.enable_virtualization_extensions = true
    hv.linked_clone    = true
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    set -e
    export HIVE_DIR=/home/vagrant/hive
    bash "$HIVE_DIR/vm-setup/setup-analysis-vm-ubuntu.sh"
  SHELL

  config.vm.post_up_message = <<~MSG

    ╔══════════════════════════════════════════════════════╗
    ║       hive analysis machine is up                    ║
    ╠══════════════════════════════════════════════════════╣
    ║  Kibana         http://localhost:5601                ║
    ║  Grafana        http://localhost:3000                ║
    ║  Elasticsearch  http://localhost:9200                ║
    ╠══════════════════════════════════════════════════════╣
    ║  Next steps:                                         ║
    ║  1. vagrant ssh                                      ║
    ║  2. sudo nano /etc/hive/secrets.env  (API keys)      ║
    ║  3. Set up WireGuard — see phase3b/README            ║
    ╚══════════════════════════════════════════════════════╝

  MSG

end
