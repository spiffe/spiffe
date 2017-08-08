# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "spiffe.svid-test.windows"
  config.vm.provision "docker"
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y build-essential python3-pip
    pip3 install --upgrade pip
    pip3 install virtualenv
  SHELL
end
