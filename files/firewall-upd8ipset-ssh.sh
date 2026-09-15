#!/bin/bash
# Filename: firewall-upd8ipset-{chain}
# Called by the task to update blocklists
# will update the ipset with ips from the blocklist

# WIP - should be a template for chain specific ipsets
# in this case it is just for SSH


IPCMD=$(command -v ipset)

#The timeout setting should be at more the freq if running this script§
# 7 days = 604800
# 1 month  2592000
# 24 days 2073600
# current max is 24 days - see https://marc.info/?l=netfilter-devel&m=141337202317570&w=2
TIMEOUT=2073600
MAXELEM=250000


# Create an ipset table with timeout
function createIPSET-Timeout {
  IPSET=$1
  IPTYP=$2
  IPTME=$3
  # check if the IP list exists
  if ! "$IPCMD" list "$IPSET" -name >/dev/null 2>&1
  then
    ipset_exists=false
  else
    # if it does exist check it uses the timeouts

    "$IPCMD" list "$IPSET" | grep -E '^Header: family inet.*timeout.([0-9]*)$'

    RESULT=$?   # grep will return 0 if it finds 'failure',  non-zero if it didn't

    if [ $RESULT -eq 0 ];then
     # ipset_timeout=true
      ipset_exists=true
    else
     # ipset_timeout=false
      echo "Destroying existing ipset as no timeout"
      $IPCMD destroy "$IPSET"
      ipset_exists=false
    fi
    #ipset_exists=true
  fi

if [ "$ipset_exists" == "false" ];then
 echo "Create $IPSET"
 $IPCMD create "$IPSET" "$IPTYP" hashsize 4096 maxelem "$MAXELEM" timeout "$IPTME" -exist || { echo "$0: Unable to create ipset: $IPSET" >&2; exit 2; }
else
  echo "$IPSET exists and is timeout compatable"
fi

}


# read in the iplists
function readIPLIST {
  SRC=$1
  IPSET=$2
  IPTYPE=$3

if [ ! -f "$SRC" ]; then
    echo "Input IPLIST File not found!: $SRC"
    exit 1
fi

if [ "$IPTYPE" = "hash:ip" ]; then
# removing invalid ips from file
#sed -rn -i.bak '/^([0-9]{1,3}\.){3}[0-9]{1,3}/!d' $SRC
 sed -ri '/^([0-9]{1,3}\.){3}[0-9]{1,3}/!d' "$SRC"
fi

# clean the list of spaces
sed -i 's/^[ \t]*//;s/[ \t]*$//' "$SRC"

# remove blank lines
sed -i '/^$/d' "$SRC"

#build a restore list
# Wrap line with 'add ipsetname' and 'timeout details'
# sed "s/.*/PREFIX&SUFFIX/" FILE
sed "s/.*/add $IPSET & timeout $TIMEOUT -exist/" "$SRC" > "$IPSET-restore"

#restore the list
$IPCMD restore < "$IPSET-restore"

# add the ips/networks to the list
#while read _ip
#do
    #ipset -A blocked-nets $ip1
 #   $IPCMD add $IPSET $_ip timeout $TIMEOUT -exist || { echo "$0: Unable to add $_ip to $IPSET, exiting early." >&2; exit 2; }
#echo "adding $_ip"
#done < $SRC | sort | uniq

}

createIPSET-Timeout "blocked-ssh" "hash:net" "2073600"
# updated this with the name of the source list
readIPLIST "/etc/firewall-blocked-AS209.txt" "blocked-ssh" "hash:net"
