#!/bin/sh -x

# Write logs
LOGS="/tmp/userdata-log.$(date -I)"
exec >$LOGS 2>&1

# Define hostname
HOSTNAME=pa-appsrv
hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname
echo 172.31.37.107 pm-jenkins.mydev.com >> /etc/hosts
echo `ifconfig |awk '/broadcast/{print $2}'` $HOSTNAME >> /etc/hosts

# Install Puppet
yum -y install puppet

# Configure section [agent] in Pappet config
cat >>/etc/puppet/puppet.conf <<EOF

    server=pm-jenkins.mydev.com
    certname=$HOSTNAME.mydev.org
EOF

# Start Puppet service
systemctl start puppet.service

# Test connection to server
puppet agent --test
