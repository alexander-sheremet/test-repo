
if versioncmp($::puppetversion, '3.6.0') {Package {allow_virtual => true,}}

class artifactory {

  # artifactory
  package { 'wget':
    ensure => 'installed',
  }
  exec { 'download_rpm_repo':
    command => '/bin/wget https://bintray.com/jfrog/artifactory-rpms/rpm -O /etc/yum.repos.d/jfrog-artifactory-rpms.repo',
    require => Package['wget'],
    unless => '/bin/test -f /etc/yum.repos.d/jfrog-artifactory-rpms.repo',
  }
  package { 'java-1.8.0-openjdk':
    ensure => 'installed',
  }
  package { 'jfrog-artifactory-oss':
    ensure => 'installed',
    require => [ Exec['download_rpm_repo'], Package['java-1.8.0-openjdk'] ],
  }
  file { '/var/opt/jfrog/artifactory/etc/artifactory.config.bootstrap.xml':
    notify  => Service['artifactory'],  # restart the service when the file changed
    ensure => present,
    replace => yes,
    owner => artifactory,
    group => artifactory,
    mode => 644,
    require => Package['jfrog-artifactory-oss'],
    source => 'puppet:///modules/pa-artifact/artifactory.config.bootstrap.xml',
  }
  service { 'artifactory':
    ensure => 'running',
    enable => 'true',
    require => File['/var/opt/jfrog/artifactory/etc/artifactory.config.bootstrap.xml'],
  }

  # nginx
  package { 'nginx':
    ensure => 'installed',
  }
  file { '/etc/nginx/nginx.conf':
    notify  => Service['nginx'],  # restart the service when the file changed
    ensure => present,
    replace => yes,
    owner => root,
    group => root,
    mode    => 644,
    require => Package['nginx'],
    source => 'puppet:///modules/pa-artifact/nginx.conf',
  }
  service { 'nginx':
    ensure    => 'running',
    enable => 'true',
    require => [ Package['nginx'], File['/etc/nginx/nginx.conf'] ],
  }
}

class appsrv {

  # tomcat
  package { 'java-1.8.0-openjdk':
    ensure => 'installed',
  }
  package { ['tomcat','tomcat-webapps','tomcat-admin-webapps']:
    ensure => 'installed',
    require => Package['java-1.8.0-openjdk'],
  }
  exec { 'install_tomcat_systemd_unit':
    command => '/bin/cp -p /usr/lib/systemd/system/tomcat.service /etc/systemd/system/',
    require => Package['tomcat'],
    unless => '/bin/test -f /etc/systemd/system/tomcat.service',
  }
  file { '/usr/share/tomcat/conf/tomcat-users.xml':
    notify  => Service['tomcat'],  # restart the service when the file changed
    ensure => present,
    replace => yes,
    owner => root,
    group => tomcat,
    mode => 640,
    require => Package['tomcat'],
    source => 'puppet:///modules/pa-appsrv/tomcat-users.xml',
  }
  service { 'tomcat':
    ensure => 'running',
    enable => 'true',
    require => [ Exec['install_tomcat_systemd_unit'], File['/usr/share/tomcat/conf/tomcat-users.xml'] ],
  }

  # nginx
  package { 'nginx':
    ensure => 'installed',
  }
  file { '/etc/nginx/nginx.conf':
    notify  => Service['nginx'],  # restart the service when the file changed
    ensure => present,
    replace => yes,
    owner => root,
    group => root,
    mode    => 644,
    require => Package['nginx'],
    source => 'puppet:///modules/pa-appsrv/nginx.conf',
  }
  service { 'nginx':
    ensure    => 'running',
    enable => 'true',
    require => [ Package['nginx'], File['/etc/nginx/nginx.conf'] ],
  }
}

class zabbix_agent {
  package { 'yum':
    ensure => 'installed',
  }
  exec { 'add_zabbix_repo':
    command => '/bin/yum -y install http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm',
    require => Package['yum'],
    unless => '/bin/test -f /etc/yum.repos.d/zabbix.repo',
  }
  package {"zabbix-agent":
    ensure => 'installed',
    require => Exec['add_zabbix_repo'],
  }
  file { '/etc/zabbix/zabbix_agentd.conf':
    notify  => Service['zabbix-agent'],  # restart the service when the file changed
    ensure => present,
    replace => yes,
    owner => root,
    group => root,
    mode    => 644,
    require => Package['zabbix-agent'],
    source => 'puppet:///modules/common/zabbix_agentd.conf',
  }
  service { 'zabbix-agent':
    ensure    => 'running',
    enable => 'true',
    require => File['/etc/zabbix/zabbix_agentd.conf'],
  }
}

class zabbix_host_removal {
  package { 'jq':
    ensure => 'installed',
  }
  file { '/etc/init.d/remove-zabbix':
    ensure => present,
    replace => yes,
    owner => root,
    group => root,
    mode    => 755,
    require => Package['jq'],
    source => 'puppet:///modules/common/remove-zabbix',
  }
  file { '/usr/lib/systemd/system/my-shutdown.service':
    ensure => present,
    replace => yes,
    owner => root,
    group => root,
    mode    => 644,
    require => File['/etc/init.d/remove-zabbix'],
    source => 'puppet:///modules/common/my-shutdown.service',
  }
  exec { 'zabbix_host_removal_service_enable':
    command => '/bin/systemctl enable my-shutdown.service',
    require => File['/usr/lib/systemd/system/my-shutdown.service'],
  }
  service { 'my-shutdown':
    ensure => 'running',
    enable => 'true',
    require => Exec['zabbix_host_removal_service_enable'],
  }
}

node 'pa-artifact.mydev.com' {
  include artifactory
  include zabbix_agent
  include zabbix_host_removal
}

node 'pa-appsrv.mydev.com' {
  include appsrv
  include zabbix_agent
  include zabbix_host_removal
}

class testfile {
  file { "/tmp/hello-file":
    replace => "no",
    owner => "root",
    group => "wheel",
    ensure  => "present",
    content => "Hello from Puppet\n",
    mode    => 644,
  }
}

node default {
  include testfile
}
