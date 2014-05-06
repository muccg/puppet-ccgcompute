#
class ccgcompute {
    class {'openstack':}

    case $::hostname {
      /^compute([\d+])$/: {
        $hostnum = $1
      }
      default {
        fail("${::hostname} does not match expected hostname pattern")
      }
    }
    $ifaces_src="auto lo \niface lo inet loopback\nauto eth1\niface eth1 inet manual\n  up ifconfig \$IFACE 0.0.0.0 up\n  up ifconfig \$IFACE promisc\nauto eth2\niface eth2 inet dhcp\n"
    file {'/etc/network/interfaces':
        content => $ifaces_src,
    }

    package { 'network-manager':
      ensure => absent
    }

    package { 'xfsprogs':
      ensure  => present,
    }
    package { 'mysql-client':
      ensure  => present,
    }
    file { '/usr/local/bin/ccgcompute-setup.sh':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0755',
      content => template('ccgcompute/ccgcompute-setup.sh.erb'),
      require => [ Package['xfsprogs'] ],
    }
    file { '/usr/local/bin/ccgcompute-nework.sh':
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
    exec {'system initial network setup':
        command  => '/usr/local/bin/ccgcompute-nework.sh',
        provider => shell,
        require  => [ File['/usr/local/bin/ccgcompute-setup.sh'] ]
    }
    package { 'neutron-plugin-openvswitch-agent':
      ensure  => absent,
      require => [ Class['openstack'] ]
    }
    package { 'neutron-common':
      ensure  => absent,
      require => [ Class['openstack'] ]
    }
    package { 'nova-compute':
      ensure  => present,
      require => [ Class['openstack'] ]
    }
    package { 'nova-compute-kvm':
      ensure  => present,
      require => [ Class['openstack'] ]
    }
    package { 'nova-network':
      ensure  => absent,
      require => [ Class['openstack'] ]
    }
    package { 'openvswitch-common':
      ensure  => absent,
      require => [ Class['openstack'] ]
    }
    package { 'nova-api-metadata':
      ensure  => present,
      require => [ Class['openstack'] ]
    }
    package { 'python-novaclient':
      ensure  => present,
      require => [ Class['openstack'] ]
    }

    service { 'nova-compute':
      ensure    => running,
      enable    => true,
      provider  => upstart,
      subscribe => [ File['/etc/nova/nova.conf'] ],
    }
    service { 'nova-network':
      ensure    => running,
      enable    => true,
      provider  => upstart,
      subscribe => File['/etc/nova/nova.conf'],
    }
    service { 'nova-api-metadata':
      ensure    => running,
      enable    => true,
      provider  => upstart,
      subscribe => File['/etc/nova/nova.conf'],
      require   => Package['nova-api-metadata'],
    }

    exec { '/usr/sbin/dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-`/bin/uname -r` || exit 0': }

    file { '/etc/nova/api-paste.ini':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('ccgcompute/api-paste.ini.erb'),
      require => Package['nova-compute'],
      notify  => Service['nova-compute'],
    }

    file { '/etc/nova/nova.conf':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['nova-compute'],
      content => template('ccgcompute/nova.conf.erb'),
      notify  => Service['nova-compute'],
    }
}
