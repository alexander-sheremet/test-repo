#!/bin/sh -x

# write logs
LOGS="/tmp/userdata-log.$(date -I)"
exec > $LOGS 2>&1

hostname pa-artefactory.mydev.org
echo 172.31.37.107 pm-jenkins.mydev.com >> /etc/hosts
ifconfig
echo `ifconfig |awk '/broadcast/{print $2}'` pa-artefactory.mydev.org >> /etc/hosts
yum -y install puppet
