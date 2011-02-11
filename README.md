hetzner-bootstrap
=================

hetzner-bootstrap allows you to bootstrap a provisioned EQ Server from hetzner.de

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

[![Moriz GmbH](http://moriz.de/images/logo.png)](http://moriz.de/)

[Moriz GmbH, München](http://moriz.de/)


Copyright
---------

Copyright (c) 2011 Moriz GmbH, Roland Moriz. See LICENSE file for details.
