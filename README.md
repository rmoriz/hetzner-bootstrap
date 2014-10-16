hetzner-bootstrap
=================

hetzner-bootstrap allows you to bootstrap a provisioned EQ Server from hetzner.de

[![Gem Version](https://badge.fury.io/rb/hetzner-bootstrap.png)](http://badge.fury.io/rb/hetzner-bootstrap)

What it does:
-------------

When you purchase a lot of servers at hetzner you're usually ending in reinstalling
each system manually prior to the first usage because you may have different opinions
about partitioning or RAID levels. This rubygem helps to fully automate the provisioning
of a rootserver.

Warning: All existing data on the system will be lost!

Requirements:
-------------

- get a webservice login from your customer panel (https://robot.your-server.de/)
- the ip address of the shipped, running system(s)

Implemented steps:
------------------

1. Enable Rescue Mode (using Hetzner's webservice)
2. Resetting the System to boot into rescue mode (using Hetzner's webservice)
3. Log into the rescue system, write your installimage template, execute installation
4. Reboot
5. verify installation (very basic check but can be overwritten)
6. copy your local ssh public-key into root's .authorized_keys
7. adds the generated server key into your .know_hosts file
8. execute post_install hooks (optional)


Example:
--------
**see example.rb file for usage!**

Warning: All existing data on the system will be lost!



```ruby

#!/usr/bin/env ruby
require 'hetzner-bootstrap'

bs = Hetzner::Bootstrap.new api => Hetzner::API.new(ENV['ROBOT_USER'], ENV['ROBOT_PASSWORD'])

template = <<EOT
DRIVE1 /dev/sda
DRIVE2 /dev/sdb

## activate software RAID?  < 0 | 1 >
SWRAID 1

## Choose the level for the software RAID < 0 | 1 >
SWRAIDLEVEL 1

## which bootloader should be used?  < lilo | grub >
BOOTLOADER grub

HOSTNAME <%= hostname %>

## PART  <mountpoint/lvm>  <filesystem/VG>  <size in MB>
##
## * <mountpoint/lvm> mountpoint for this filesystem  *OR*  keyword 'lvm'
##                    to use this PART as volume group (VG) for LVM
## * <filesystem/VG>  can be ext2, ext3, reiserfs, xfs, swap  *OR*  name
##                    of the LVM volume group (VG), if this PART is a VG
## * <size>           you can use the keyword 'all' to assign all the
##                    remaining space of the drive to the *last* partition.
##                    you can use M/G/T for unit specification in MIB/GIB/TIB
##
## notes:
##   - extended partitions are created automatically
##   - '/boot' cannot be on a xfs filesystem!
##   - '/boot' cannot be on LVM!
##   - when using software RAID 0, you need a '/boot' partition

PART /boot ext3    1G
PART lvm   host   75G
PART lvm   guest  all

#LV <VG> <name> <mount> <filesystem> <size>
LV host root /    ext4  50G
LV host swap swap swap   5G


## ========================
##  OPERATING SYSTEM IMAGE:
## ========================

## full path to the operating system image
##   supported image sources:  local dir,  ftp,  http,  nfs
##   supported image types:  tar,  tar.gz,  tar.bz,  tar.bz2,  tgz,  tbz
## examples:
#
# local: /path/to/image/filename.tar.gz
# ftp:   ftp://<user>:<password>@hostname/path/to/image/filename.tar.bz2
# http:  http://<user>:<password>@hostname/path/to/image/filename.tbz
# https: https://<user>:<password>@hostname/path/to/image/filename.tbz
# nfs:   hostname:/path/to/image/filename.tgz

# Default images provided by hetzner as of October 2014:
# Archlinux-2014-64-minmal.tar.gz
# CentOS-65-32-minimal.tar.gz
# CentOS-65-64-cpanel.tar.gz
# CentOS-65-64-minimal.tar.gz
# CentOS-70-64-minimal.tar.gz
# Debian-76-wheezy-32-minimal.tar.gz
# Debian-76-wheezy-64-LAMP.tar.gz
# Debian-76-wheezy-64-minimal.tar.gz
# openSUSE-131-64-minimal.tar.gz
# Ubuntu-1204-precise-64-minimal.tar.gz
# Ubuntu-1404-trusty-64-minimal.tar.gz


IMAGE /root/images/Ubuntu-1404-trusty-64-minimal.tar.gz

EOT

# the post_install hook is a great place to setup further software/system provisioning
#
post_install = <<EOT
  # knife bootstrap <%= ip %> -N <%= hostname %> "role[base],role[kvm_host]"
EOT

bs << { 
        ip:  '1.2.3.4',
        template:  template,                # string will be parsed by erubis
        hostname: 'server100.example.com',  # will be used for setting the systems' hostname
        public_keys: "~/.ssh/id_dsa.pub",   # will be copied over to the freshly bootstrapped system
        post_install: post_install          # will be called locally at the end and can be used e.g. to run a chef bootstrap
      }

bs << { 
        ip:  '1.2.3.5',
        template:  template,                # string will be parsed by erubis
        hostname: 'server101.example.com',  # will be used for setting the systems' hostname
        public_keys: "~/.ssh/id_dsa.pub",   # will be copied over to the freshly bootstrapped system
        post_install: post_install          # will be called locally at the end and can be used e.g. to run a chef bootstrap
      }

…        
bs.bootstrap!


```

Installation:
-------------

**gem install hetzner-bootstrap**

Warnings:
---------

* All existing data on the system will be wiped on bootstrap!
* This is not an official Hetzner AG project.
* The gem and the author are not related to Hetzner AG!

**Use at your very own risk. Satisfaction is NOT guaranteed.**

Commercial Support available through:
-------------------------------------

[![Moriz GmbH](https://moriz.de/images/logo.png)](http://moriz.de/)

[Moriz GmbH, München](http://moriz.de/)


Copyright
---------

Copyright © 2013 [Roland Moriz](https://roland.io), [Moriz GmbH](https://moriz.de/)

[![LinkedIn](http://www.linkedin.com/img/webpromo/btn_viewmy_160x25.png)](http://www.linkedin.com/in/rmoriz)
[![Twitter](http://i.imgur.com/1kYFHlu.png)](https://twitter.com/rmoriz)
