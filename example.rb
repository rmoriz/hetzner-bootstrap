#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'hetzner-bootstrap'

# get your API login from Hetzner's customer panel at: https://robot.your-server.de/
# assign env variables:
#   ROBOT_USER
#   ROBOT_PASSWORD
#
# rbenv-tip: checkout rbenv-vars, it's awesome!
#            https://github.com/sstephenson/rbenv-vars/

bs = Hetzner::Bootstrap.new(api: Hetzner::API.new(
  ENV['ROBOT_USER'],
  ENV['ROBOT_PASSWORD']
))

# 2 disks, software raid 1, etc.
template = <<~END_OF_TEMPLATE
  DRIVE1 /dev/sda
  DRIVE2 /dev/sdb
  FORMATDRIVE2 0

  ## ===============
  ##  SOFTWARE RAID:
  ## ===============

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

  PART /boot ext2    1G
  PART lvm   host   75G
  PART lvm   guest  all

  #LV <VG> <name> <mount> <filesystem> <size>
  LV host root /    ext3  50G
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


  IMAGE /root/images/Ubuntu-1204-precise-64-minimal.tar.gz

END_OF_TEMPLATE

# the post_install hook is a great place to setup further
# software/system provisioning
#
post_install = <<END_OF_POST_INSTALL
  # knife bootstrap <%= ip %> -N <%= hostname %> "role[base],role[kvm_host]"
END_OF_POST_INSTALL

# duplicate entry for each system
bs << { ip: '1.2.3.4',
        template: template,               # string will be parsed by erubis
        hostname: 'server100',            # sets hostname
        public_keys: '~/.ssh/id_dsa.pub', # will be copied to your system
        post_install: post_install }      # will be executed *locally* at the end

bs.bootstrap!
