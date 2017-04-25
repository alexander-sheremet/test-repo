#!/bin/sh
# Update /etc/hosts with specified IP address for specified hostname
# Copy this script to /root/bin and give jenkins user permission to execute the script under root:
#   sudo /root/bin/upd-hosts-ip.sh
# Exit codes:
#   0 - specified hostname found and IP address updated
#   1 - error: specified hostname not found in /etc/hosts

if [ $# -ne 2 ]
then
  echo "Usage: $0 IP-address HostName"
  exit 1
fi

IPADDR=$1
HOSTNAME=$2
HOSTS_TMP=`mktemp /tmp/hosts.XXXXXXX`

if ! awk -v IPADDR="$IPADDR" -v HOSTNAME="$HOSTNAME" '
BEGIN {updated = 0}
{
  if (tolower($0) ~ tolower(HOSTNAME))
  {
    split ($0, a, "[ \t]")
    print IPADDR "\t" a[2]
    updated = 1
  }
  else
  {
    print $0
  }
}
END {if (updated == 0) exit 1}
' /etc/hosts > $HOSTS_TMP
then
  echo "ERROR: the hostname $HOSTNAME not found in /etc/hosts"
  exit 1
fi

if cp $HOSTS_TMP /etc/hosts
then
  awk -v HOSTNAME="$HOSTNAME" '
  {
    if (tolower($0) ~ tolower(HOSTNAME))
    {
      print "The IP address updated:"
      print $0
    }
  }' /etc/hosts
fi

rm -f $HOSTS_TMP
