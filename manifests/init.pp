#
class ccgcompute () inherits ccgcompute::params {

  class {'openstack':}

  file {'/etc/network/interfaces':
    content => template('ccgcompute/interfaces.erb'),
  }

  file {'/etc/default/grub':
    content => template('ccgcompute/grub.erb'),
  }

  exec { "/usr/sbin/update-grub":
    subscribe   => File["/etc/default/grub"],
    refreshonly => true
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

  exec {'system initial setup':
    command  => '/usr/local/bin/ccgcompute-setup.sh',
    provider => shell,
    require  => File['/usr/local/bin/ccgcompute-setup.sh']
  }

  exec { '/usr/bin/dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-`/bin/uname -r` || exit 0': }

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

  file { '/etc/cinder/cinder.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('ccgcompute/cinder.conf.erb'),
    require => Package[$ccgcompute::packages],
    notify  => Service['cinder-volume'],
  }

  service { 'cinder-volume':
    ensure    => running,
    enable    => true,
    provider  => upstart,
    require   => Package[$ccgcompute::packages],
    subscribe => File['/etc/cinder/cinder.conf'],
  }

  service { 'nova-compute':
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
