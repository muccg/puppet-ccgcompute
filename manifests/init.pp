#
class ccgcompute () inherits ccgcompute::params {

  class {'openstack':}

  file {'/etc/network/interfaces':
    content => template('ccgcompute/interfaces.erb'),
  }

  package { $ccgcompute::absent_packages:
    ensure  => absent,
    require => Class['openstack']
  }

  package { $ccgcompute::packages:
    ensure  => present,
    require => Class['openstack']
  }

  file { '/usr/local/bin/ccgcompute-setup.sh':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('ccgcompute/ccgcompute-setup.sh.erb'),
  }

  file { '/usr/local/bin/ccgcompute-network.sh':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0755',
      content => template('ccgcompute/ccgcompute-network.sh.erb'),
  }

  exec {'system initial setup':
    command  => '/usr/local/bin/ccgcompute-setup.sh',
    provider => shell,
    require  => File['/usr/local/bin/ccgcompute-setup.sh']
  }

  # TODO This script references neutron, is it still current?
  exec {'system initial network setup':
    command  => '/usr/local/bin/ccgcompute-network.sh',
    provider => shell,
    require  => File['/usr/local/bin/ccgcompute-network.sh']
  }

  exec { '/usr/sbin/dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-`/bin/uname -r` || exit 0': }

  file { '/etc/nova/api-paste.ini':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('ccgcompute/api-paste.ini.erb'),
    require => Package[$ccgcompute::packages],
    notify  => Service['nova-compute'],
  }

  file { '/etc/nova/nova.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('ccgcompute/nova.conf.erb'),
    require => Package[$ccgcompute::packages],
    notify  => Service['nova-compute'],
  }

  service { 'nova-compute':
    ensure    => running,
    enable    => true,
    provider  => upstart,
    require   => Package[$ccgcompute::packages],
    subscribe => File['/etc/nova/nova.conf'],
  }

  service { 'nova-network':
    ensure    => running,
    enable    => true,
    provider  => upstart,
    require   => Package[$ccgcompute::packages],
    subscribe => File['/etc/nova/nova.conf'],
  }

  service { 'nova-api-metadata':
    ensure    => running,
    enable    => true,
    provider  => upstart,
    require   => Package[$ccgcompute::packages],
    subscribe => File['/etc/nova/nova.conf'],
  }
}
