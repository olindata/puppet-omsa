# == Class: omsa::repo
#
# This class provides everything which is needed for the actual installation of Dell OpenManage
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
class omsa::repo (
) {
  case $::operatingsystem {
    'sles': {
      # Workaround until zypprepo allows the adding of the keys
      # https://github.com/deadpoint/puppet-zypprepo/issues/4
      exec { 'add-rpm-gpg-key-dell':
        path    =>  ['/bin', '/sbin', '/usr/bin/', '/usr/sbin/'],
        command =>  'wget -q -O /tmp/RPM-GPG-KEY-dell http://linux.dell.com/repo/hardware/latest/RPM-GPG-KEY-dell; rpm --import /tmp/RPM-GPG-KEY-dell',
        unless  =>  'rpm -q gpg-pubkey-23b66a9d',
      }
      exec { 'add-rpm-gpg-key-libsmbios':
        path    =>  ['/bin', '/sbin', '/usr/bin/', '/usr/sbin/'],
        command =>  'wget -q -O /tmp/RPM-GPG-KEY-libsmbios http://linux.dell.com/repo/hardware/latest/RPM-GPG-KEY-libsmbios; rpm --import /tmp/RPM-GPG-KEY-libsmbios',
        unless  =>  'rpm -q gpg-pubkey-5e3d7775',
      }

      case $::operatingsystemrelease {
        '11.0',
        '11.1',
        '11.2',
        '11.3': {
          zypprepo { 'dell-omsa-hwindep':
            type         => 'rpm-md',
            baseurl      => 'http://linux.dell.com/repo/hardware/latest/platform_independent/suse11_64/',
            enabled      => 1,
            autorefresh  => 0,
            name         => 'dell-omsa-hwindep',
          }

          # We place a dummy file which has an placeholder for the system device id. This is going to be replaced by Exec['replace-system-dev-id']
          # Yep this is ugly. I know. But since there is no other option...
          file { '/etc/zypp/repos.d/dell-omsa-hw.repo':
            ensure  =>  present,
            replace =>  false,
            owner   =>  'root',
            group   =>  'root',
            mode    =>  '0644',
            source  =>  'puppet:///modules/omsa/zypper-dell-omsa-hw.repo',
            before  =>  Exec['replace-system-dev-id'],
          } ->
          exec { 'replace-system-dev-id':
            path    =>  ['/bin', '/sbin', '/usr/bin/', '/usr/sbin/'],
            command =>  '/usr/sbin/getSystemId | grep \'^System ID:\' | cut -d: -f2 | tr A-Z a-z | perl -p -i -e \'s/\s*//\' > /tmp/sysdevid;
                         sed -i "s/#DEVID#/$(cat /tmp/sysdevid)/g" /etc/zypp/repos.d/dell-omsa-hw.repo',
            onlyif  =>  'grep -q "#DEVID#" /etc/zypp/repos.d/dell-omsa-hw.repo',
            require =>  [
                          File['/etc/zypp/repos.d/dell-omsa-hw.repo'],
                          Package['yum-dellsysid'],
                          Package['libsmbios2'],
                        ],
          }


          package { [ 'yum-dellsysid', 'libsmbios2', ]:
            ensure  =>  present,
            require =>  [
                          Zypprepo['dell-omsa-hwindep'],
                          Exec['add-rpm-gpg-key-dell'],
                          Exec['add-rpm-gpg-key-libsmbios'],
                        ],
          }
        }
        default: {
          fail("unsupported: ${::osfamily}/${::operatingsystem}/${::operatingsystemrelease}")
        }
      }
    }
    'ubuntu': {
      case $::lsbdistrelease {
        '12.04': {
          apt::source { 'osma':
            location          => 'http://linux.dell.com/repo/community/ubuntu',
            release           => 'precise',
            repos             => 'openmanage',
            key               => '1285491434D8786F',
            key_server        => 'pool.sks-keyservers.net',
            include_src       => false,
          }
        }
        default: {
          fail("unsupported: ${::osfamily}/${::operatingsystem}/${::operatingsystemrelease}")
        }
      }
    }
    default: {
      fail("unsupported: ${::osfamily}/${::operatingsystem}/${::operatingsystemrelease}")
    }
  }
}
