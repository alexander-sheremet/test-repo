
if versioncmp($::puppetversion, '3.6.0') {Package {allow_virtual => true,}}

class artifactory {
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
  file { '/var/opt/jfrog/artifactory/etc/artifactory.config.import.xml':
    notify  => Service['artifactory'],  # restart the service when the file changed
    ensure => present,
    replace => yes,
    owner => artifactory,
    group => artifactory,
    mode => 644,
    require => Package['jfrog-artifactory-oss'],
    source => 'puppet:///modules/pa-artifact/artifactory.config.import.xml',
  }
  service { 'artifactory':
    ensure => 'running',
    enable => 'true',
    require => File['/var/opt/jfrog/artifactory/etc/artifactory.config.import.xml'],
  }
}

class appsrv {
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

node 'pa-artifact.mydev.com' {
  include artifactory
}

node 'pa-appsrv.mydev.com' {
  include appsrv
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
