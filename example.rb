#!/usr/bin/env ruby
require "rubygems"
require "hetzner-bootstrap"

# get your API login from Hetzner's customer panel at: https://robot.your-server.de/
# assign env variables:
#   ROBOT_USER 
#   ROBOT_PASSWORD
#
# rbenv-tip: checkout rbenv-vars, it's awesome! 
#            https://github.com/sstephenson/rbenv-vars/

bs = Hetzner::Bootstrap.new :api => Hetzner::API.new ENV['ROBOT_USER'], ENV['ROBOT_PASSWORD']

# 2 disks, software raid 1, etc.
template = <<EOT
DRIVE1 /dev/sda
DRIVE2 /dev/sdb
FORMATDRIVE2 0

SWRAID 1
SWRAIDLEVEL 1

BOOTLOADER grub

HOSTNAME <%= hostname %>

PART /boot ext2    1G
PART lvm   host   75G
PART lvm   guest  all

LV host root /    ext3  50G
LV host swap swap swap   5G

IMAGE /root/images/Ubuntu-1204-precise-64-minimal.tar.gz
EOT

# the post_install hook is a great place to setup software/system provisioning
#
post_install = <<EOT
knife bootstrap <%= ip %> -N <%= hostname %> "role[base],role[kvm_host]"
EOT

# duplicate entry for each system
bs << { :ip => "1.2.3.4",
        :template => template,                 # string will be parsed by erubis
        :hostname => 'server100.example.com',  # will be used for setting the systems' hostname
        :public_keys => "~/.ssh/id_dsa.pub",   # will be copied over to the freshly bootstrapped system
        :post_install => post_install }        # will be called locally at the end and can be used e.g. to run a chef bootstrap

bs.bootstrap!

