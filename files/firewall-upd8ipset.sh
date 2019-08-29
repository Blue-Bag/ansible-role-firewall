#!/bin/bash
# Filename: firewall-upd8ipset
# Called by the task to update blocklists
# will update the ipset with ips from the bocklist


IPCMD=$(command -v ipset)

#The timeout setting should be at more the freq if running this script§
# 7 days = 604800
# 1 month  2592000
# 24 days 2073600
# current max is 24 days - see https://marc.info/?l=netfilter-devel&m=141337202317570&w=2
TIMEOUT=2073600

# read in the iplists
function readIPLIST {
  SRC=$1
  IPSET=$2
  IPTYPE=$3

if [ ! -f "$SRC" ]; then
    echo "Input IPLIST File not found!: $SRC"
    exit 1
fi


if [$IPTYPE === "hash:ip"]; then
# removing invalid ips from file
#sed -rn -i.bak '/^([0-9]{1,3}\.){3}[0-9]{1,3}/!d' $SRC
 sed -ri '/^([0-9]{1,3}\.){3}[0-9]{1,3}/!d' $SRC
fi
# clean the list of spaces
sed -i 's/^[ \t]*//;s/[ \t]*$//' $SRC

# remove blank lines
sed -i '/^$/d' $SRC

#build a restore list
# Wrap line with 'add ipsetname' and 'timeout details'
# sed "s/.*/PREFIX&SUFFIX/" FILE
sed "s/.*/add $IPSET & timeout $TIMEOUT -exist/" $SRC > $IPSET-restore

#restore the list
ipset restore < $IPSET-restore

# add the ips/networks to the list
#while read _ip
#do
    #ipset -A blocked-nets $ip1
 #   $IPCMD add $IPSET $_ip timeout $TIMEOUT -exist || { echo "$0: Unable to add $_ip to $IPSET, exiting early." >&2; exit 2; }
#echo "adding $_ip"
#done < $SRC | sort | uniq

}


{% for list in firewall_blocklists %}
readIPLIST "/etc/firewall-{{ list.name }}.txt" "{{ list.name }}" "{{ list.type }}"
{% endfor %}
