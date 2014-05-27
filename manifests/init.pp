# == Class: omsa
#
# A puppet module which manages the whole Dell OpenManage installation process
#
# === Examples
#
#
# === Authors
#
# Matthias Baur <matthias.baur@dmc.de>
#
# === Copyright
#
# Copyright 2014 dmc digital media center GmbH, unless otherwise noted.
#
class omsa (
) {
  include omsa::repo

  package { 'srvadmin-all':
    ensure  => present,
    require => Class['omsa::repo']
  }

  service { 'dataeng':
    ensure  => running,
    require => Package['srvadmin-all'],
  }

  service { 'dsm_om_connsvc':
    ensure  => running,
    require => Package['srvadmin-all'],
  }
}
