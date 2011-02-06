#!/usr/bin/env ruby
require "hetzner-bootstrap"

API_USERNAME="xxx"
API_PASSWORD="yyy"

bs = Hetzner::Bootstrap.new :api => Hetzner::API.new(API_USERNAME, API_PASSWORD)

# 2 disks, software raid 1, etc.
template = <<EOT
DRIVE1 /dev/sda
DRIVE2 /dev/sdb
FORMATDRIVE2 0

SWRAID 1
SWRAIDLEVEL 1

BOOTLOADER grub

HOSTNAME <%= hostname %>

PART /boot ext2 1G
PART lvm   host   75G
PART lvm   guest  all

LV host root /    ext3  50G
LV host swap swap swap   5G

IMAGE /root/images/Ubuntu-1010-maverick-64-minimal.tar.gz
EOT

post_install = <<EOT
bundle exec knife bootstrap <%= hostname %> "role[base],role[kvm_host]" -x <%= login %> -P "<%= password %> --sudo -l debug
EOT

# duplicate entry for each system
bs << { :ip => "1.2.3.4",
        :template => template,                 # string will be parsed by erubis
        :hostname => 'server100.example.com',  # will be used for setting the systems' hostname
        :public_keys => "~/.ssh/id_dsa.pub",   # will be copied over to the freshly bootstrapped system
        :post_install => post_install }        # will be called locally at the end and can be used e.g. to run a chef bootstrap

bs.bootstrap!

