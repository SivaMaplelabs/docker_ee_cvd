class docker_ee_cvd::docker::role::ucp::dtr::master(
  $dtr_version             = $docker_ee_cvd::docker::params::dtr_version,
  $ucp_username            = $docker_ee_cvd::docker::params::ucp_username,
  $ucp_password            = $docker_ee_cvd::docker::params::ucp_password,
  $package_source_location = $docker_ee_cvd::docker::params::package_source_location,
  $package_key_source      = $docker_ee_cvd::docker::params::package_key_source,
  $package_repos           = $docker_ee_cvd::docker::params::package_repos,
  $ntp_server              = $docker_ee_cvd::docker::params::ntp_server,
) inherits docker_ee_cvd::docker::params {

  $ucp_ipaddress_query= 'facts {
    name = "ipaddress" and certname in resources[certname] {
     type = "Class" and title = "Docker_ee_cvd::Docker::Role::Ucp::Controller::Master" 
    }
  }'
  
  $ucp_controller_port_query = 'facts {
    name = "ucp_controller_port" and certname in resources[certname] {
     type = "Class" and title = "Docker_ee_cvd::Docker::Role::Ucp::Controller::Master" 
    }
  }'

  $dtr_node_ip         = $facts['networking']['ip']
  $dtr_node_hostname   = $facts['networking']['fqdn']
  $ucp_ipaddress       = puppetdb_query($ucp_ipaddress_query)[0]['value']
  $ucp_controller_port = puppetdb_query($ucp_controller_port_query)[0]['value']

  class { 'docker_ee_cvd::docker::role::ucp::worker':
    package_source_location => $package_source_location,
    package_key_source      => $package_key_source,
    package_repos           => $package_repos,
    ntp_server              => $ntp_server,
    require                 => Class['docker'],
  }

  exec { 'DTR sleep time':
    command => 'sleep 90',
    path    => ['/usr/bin', '/usr/sbin',],
    require => Class['docker_ee_cvd::docker::role::ucp::worker'],
  }

  docker_ddc::dtr { 'Dtr install':
    install          => true,
    dtr_version      => $dtr_version,
    dtr_external_url => "https://${dtr_node_ip}",
    ucp_node         => $dtr_node_hostname,
    ucp_username     => $ucp_username,
    ucp_password     => $ucp_password,
    ucp_insecure_tls => true,
    dtr_ucp_url      => "https://${ucp_ipaddress}:${ucp_controller_port}",
    require          => Exec['DTR sleep time'],
    }
}

