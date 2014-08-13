#
class ccgcompute::params {

    case $::hostname {
      /^compute([\d+])$/: {
        $hostnum = $1
      }
      default: {
        fail("${::hostname} does not match expected hostname pattern")
      }
    }

    $absent_packages = [
      'network-manager',
      'neutron-plugin-openvswitch-agent',
      'neutron-common',
    ]

    $packages = [
      'xfsprogs',
      'mysql-client',
      'nova-network',
      'nova-compute',
      'nova-compute-kvm',
      'openvswitch-common',
      'nova-api-metadata',
      'python-novaclient',
      'cinder-volume',
      'gdisk'
    ]
}
