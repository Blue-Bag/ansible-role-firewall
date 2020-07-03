


# Ansible Role: Firewall (iptables)
  [![Build Status](https://travis-ci.org/Blue-Bag/ansible-role-firewall.svg?branch=master)](https://travis-ci.org/Blue-Bag/ansible-role-firewall)

This role is based on the Ansible Firewall role by Jeff Geerling which
> installs a simple iptables-based firewall for RHEL/CentOS or Debian/Ubuntu systems.

and

>aims for simplicity over complexity, and only opens a few specific ports for incoming traffic (configurable through Ansible variables). If you have a rudimentary knowledge of `iptables` and/or firewalls in general, this role should be a good starting point for a secure system firewall.

This role builds on that basic functionality and adds support for a wide range of Iptables Ip6tables and IPSET features.
You can still use the source functionality by setting the file wall mode to simple. If that is your aim then use the geerlingguy.firewall role.

```
# firewall modes [simple | chain ]
firewall_mode: 'simple'

```

After the role is run, a `firewall` init service will be available on the server. You can use `service firewall [start|stop|restart|status]` to control the firewall.
Using Jeff Geerlings role as a base this has been, updated to enable more complex chain based mode for the firewall and blocks for common attacks.
## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `vars/main.yml`):

### Backing up and saving rules
`firewall_backup_cfg: false`
Make a backup of the existing firewall.bash script. This is handy in case you make undesired changes so you can revert to the previous rule set . This uses the backup parameter of the template module:
> Create a backup file including the timestamp information so you can get the original file back if you somehow clobbered it incorrectly.

`firewall_iptables_save: false`
Export the rules using:
`iptables-save > /etc/iptables.up.rules`
Whilst this might be useful, the restoration of rules on a restart is handled by the firewall service that this role creates.

`firewall_debug: false`
When creating molecule tests it was apparent that support for testing ipv6 in containers is flaky at best and the role kept failing due to a systemd startup error on the service. If this happens to you , you can set debug to true to log the output of the systemd error. Helpful to resolve this on remote containers.
The error in my case was:
```
ip6tables v1.6.0: can't initialize ip6tables table `filter': Table does not exist (do you need to insmod?)
```
Seems to be common when using docker etc
`firewall_modprobe: false`
In some cases this is due to the need to initialize ip6tables.  So there is a task that runs mod_probe
For background see [https://ilhicas.com/2018/04/08/Fixing-do-you-need-insmod.html](https://ilhicas.com/2018/04/08/Fixing-do-you-need-insmod.html)

`firewall_state: started`
Start the firewall
`firewall_enabled_at_boot: true`
Enable the firewall on reboot
`firewall_flush_rules_and_chains: true`
Flush the existing rules and chains when building the firewall.


## Simple config
`firewall_mode: 'simple'`
In simple mode the role is as per the original
### Firewall defaults
These al relate to both modes.
```
filewall_input_default: 'ACCEPT'
filewall_forward_default: 'ACCEPT'
filewall_output_default: 'ACCEPT'
```
Note: it is advisable to set these to DENY so that all ports are denied by default and only opened explicitly.
But be cautious when configuring at first to make sure you don't lock your self out!
### Incoming ports:
```
firewall_allowed_tcp_ports:
  - "22"
  - "25"
  - "80"
  - "443"
```
List the tcp ports (ipv4) that you want to be allowed.

`firewall_allowed_tcp_ports_ip6: []`
Similar to above but don't put ssh in here as we treat that separately

### Outgoing ports

```
firewall_allowed_tcp_ports_out:
  - "25"
```
allow mail port out

### Other firewalls
`firewall_disable_firewalld: false`
`firewall_disable_ufw: false`
Set to true to ensure other firewall management software is disabled.

## Allowed Ports (more detailed)
```
firewall_allowed_tcp_ports:
  - "22"
  - "80"
...
```
`firewall_allowed_udp_ports: []`

 A list of TCP or UDP ports (respectively) to open to incoming traffic.
## Forwarded Ports
```
firewall_forwarded_tcp_ports:
  - { src: "22", dest: "2222" }
  - { src: "80", dest: "8080" }
```
A list of ports that can be forwarded
```
firewall_forwarded_udp_ports: []
```
Forward `src` port to `dest` port, either TCP or UDP (respectively).

## IPV4 Additional (custom) rules
`firewall_additional_rules: []`
Any additional (custom) rules to be added to the firewall (in the same format you would add them via command line, e.g. `iptables [rule]`).

## IPv6
Often IPv6 is forgotten about and may be in use but not adequately 'protected'. This is a common attack surface when ipv4 is protected but not ipv6. This role provides a range of protection for ipv6.
`firewall_enable_ipv6: true` - Enable the ipv6 set of rules

`firewall_ip6_additional_rules: []`
Any additional (custom) rules to be added to the firewall (in the same format you would add them via command line, e.g. `ip6tables [rule]`).

## Logging
Dropped packets can be logged to allow for analysis and monitoring
`firewall_log_dropped_packets: true`
Note this can get verbose when large port scans are experienced
So choose a logging level

`firewall_log_level: 4`

```
# 0 emerg
# 1 alert
# 2 crit
# 3 err
# 4 warning
# 5 notice
# 6 info
# 7 debug
```
## Additional variables for chain


# firewall chain mode
`firewall_mode: chain`
In chain mode the firewall becomes more feature rich.
Chains are used to group rules for specific ports to allow:
 - protected ports (restricted to specific ips)
 - rate limiting,
 - logging,
 - AllowLists,
 - DenyLists etc

This mode also makes use of IPSETs to manage long lists of blocked ips, lists of allowed ips etc

In chain mode the role also allows for other blocks such as security precautions.

```
firewall_allowlist:

- { name: 'local', ip: "192.168.100.1" }
```
A list of IPs that will be allowed
```
firewall_denylist:
- { name: 'Some rogue', ip: "96.47.225.0/24" }
```
A list of IPs that will be blocked

## Access Control Lists (ACLs)
The chain mode firewall makes use of lists, ipsets and blocks of chains to manage the control of access to specific ports.
All ports are protected from lists of known ips from block lists.
Such lists can be obtained from services such as blocklist.de etc
See the refs for details about a role to manage these ipset block lists.

Note: This role is being heavily refactored to eradicate problematic vocabulary.
The terminology used is as follows:

 - `AllowList` - IPs that are trusted and know
 - `TrustedList` - IPs that are trusted but not given blanket privileged
access to all ports
 - `DenyList` - IPs that are explicitly excluded from access to any ports and dropped
Note that packets can be dropped or rejected.

```
firewall_allowlist_ip:
  - {name: 'local', ip: "192.168.100.1"}
```
You can specify a list of IPs to grant access to the server on all ports.
The name is used as a comeent in IPsets and in the Firewall defintion

`firewall_allowlist_net: []`
Access lists can also be provided in CIDR format to provide network block Access
Use with caution as you may grant access wider than intended.

If you want to use IPsets you can specifc the names to be used for the AccessList IPset
`firewall_allow_ipset: 'AccessAllow_ip'`
When the firewall is 'built' the list of ips in the firewall_allowlist will be written to an external IPset of that name.

Allowlists are a useful way of providing access to your various services/servers and users.
One useful method is to compile a list of all of your web servers and adding them to the Allow list for your databases for example. This particularly useful for setting up a private network and granting access to load balancers etc
You can specify a group in your inventory to be used a set to be added to the AllowList

`firewall_allowlistgroup: "remote"` - select a host group from your inventory
The Allow list is built up from a set of lists.

You can also provide a specific list just for the chains that may be less 'trusted' than the trusted AccessList
allowing access to the chains but not everything else

`firewall_chain_al: "{{ firewall_allowlist }}"`
`firewall_chain_al: "{{ firewall_allowlist }}"`

 It is possible also to maintain a list  of Denied ips.
 However it is better t use the blocklists discussed later as these lists can get very long!
 ```
 firewall_denylist:
  - {name: 'Some rogue', ip: "96.47.225.0/24"}
```
Note: Ips can be specified as both Ips and CIDR nets

### Rate limiting:
Defaults can be given for rate limiting certain chains
`firewall_ddos_rate: '150/second'`

`firewall_ddos_burst: '160'`
They can be usedin chain defintions:
```
- {
  port: "80",
  name: "HTTP",
  state: "NEW,RELATED,ESTABLISHED",
  default: "ACCEPT",
  ddos: true,
  ddos_rate: "{{ firewall_ddos_rate }}",
  ddos_burst: "{{ firewall_ddos_burst }}"
}
```
This will allow all access to port 80 but limit the connection rate to 150/sec by IP
`iptables -A HTTP -p tcp --dport 80 -m state --state NEW -m limit --limit 150/second --limit-burst 160 -j ACCEPT`

General Rate limiting:
You could provide a custom additional rule for general rate limiting
`iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset`


### Protected Chains
Chains are used to protect ports. They allow for the use of ipsets and other lists to control access.
They also allow rate limiting and configure logging.
All chains are:
-  protected by default from IPs listed in the DenyList.
- Accessible to IPs listed in the AllowList

Chain definitions. The port to create a chain for and the default action and details about rate limiting etc
```
firewall_protected_chains:
- {
   port: "22",
   name: "SSH",
   default: "ACCEPT",
   ratelimit: "True",
   hit_rate: 4,
   hit_ttl: 60
  }
```
This protected chain:
-  allows any ips to access the port
-  ratelimits the port to 4 hits in 60 seconds
```
- {
  port: "80",
  name: "HTTP",
  default: "ACCEPT"
 }
- {
  port: "443",
  name: "HTTPS",
  default: "ACCEPT"
}
```
These chains allow all traffic to ports 80 & 443 with no restrictions (other than applied by other blocks)
```
- {
  port: "3306",
  name: "MYSQL",
  default: "DROP"
}
```
This chain denies access to the 3306 port for all but ips listed on the Allow list ACLs.

## IPSETs
The chain firewall makes use of Ipsets for managing long lists of Allowed and Denied IPs
Ipsets are ver efficient (far more so than long lists of Iptables rules)
They have the added advantage of being able to be updated without having to restart the firewall.
They can also be create with timeouts. This means that an ip can be added to the DenyList and will timeout after a period and drop from the list. Very handy for blocking a malicious visitor for a period but not gradually building up a massive lists of Ips for ever.
They can also be compiled from public block lists.
Ipsets can also be created with support for comments.
This is useful for AllowLists to annotate and keep track of any Ips added.


`firewall_ipset: false` - Use ipsets or not

`firewall_reban_hosts: true` - Add dropped ips to a timeout DenyList ipset
`firewall_reban_list: 'banned-hosts'` - The name of ipset to use.
This is more efficient as a banned ip will get blocked early on on a revisit and for all ports.

`firewall_ipset_timeout: 2073600` - The default timeout for DenyList ipsets

`firewall_ipset_bl_maxelem: 100000` - The default max elements for a DenyList

### Managing an using blocklists
Create lists, for network blocks and single IP addresses

if using a local job to update lists then set these to your locally generated list
These lists can be generated and sourced form any source and compiled in the following format:
 hash:net = Networks in CIDR format one per line in plain text
 hash:ip = single IPs one per line in plain text
```
firewall_blocklists:
  - {
     name: blocked-nets,
     type: 'hash:net',
     src: 'blocked-nets.txt',
     persist: true,
     timeout: "{{ firewall_ipset_timeout }}"
  }
- {
   name: blocked-ips,
   type: 'hash:ip',
   src: 'blocked-ips.txt',
   persist: true,
   timeout: "{{ firewall_ipset_timeout }}"
  }
```

### Extended rules

`firewall_extra_security: true`
Option to exclude all of the following extra security blocks

`firewall_block_portscan: true`
Include a portscan protection block

`firewall_block_spoofed: true`
Include a block for spoofed addresses
This also has an exclusion to not include when running against a local group host

`firewall_block_smurf: true`
A block to protect against smurf attacks

`firewall_allow_ping: true`
An option to enable/disable ping blocking
Note you may need this on for monitoring

##  Badips
Support is provided for reporting blocked ips to Badips
`badips_key: ''`

`firewall_block_badips: false`

`firewall_badips_level: '0'` - level to report 0 = all

service to report on - we want all of ours

`firewall_badips_service: 'any'`

`firewall_badips_ipset: 'badips'`

`firewall_badips_folder: '/usr/share/badips'`

`firewall_badips_db: '/usr/share/badips/badips.db'`



##  Cloudflare
You can specif a list of trusted ips such as Cloudflare.
This will stop blocking of cloudflare traffic
`firewall_whitelist_cf: false`

`firewall_cf_ipset: 'whitelist_cf'`


## IPset
Once the firewall is operational you can add to the ipsets to block an ip

`ipset add blocked-ips 195.154.215.122`



# sorting and filtering the blocked ips list

`cat blocked-ips.txt | sort -n | uniq > blocked-ips.txt`

Note about filtering out Alloed ipsfrom blockllists
{To_do}

## Dependencies

None.


## Example Playbook

``

- hosts: server

vars_files:

- vars/main.yml

roles:

- { role: geerlingguy.firewall }

```

Inside `vars/main.yml`*:

```

firewall_allowed_tcp_ports:

- "22"

- "25"

- "80"

```

## TODO
- Make outgoing ports more configurable.
- Make other firewall features (like logging) configurable.


## License

MIT / BSD

## Author Information

George Boobyer (iAugur)



This role was based on one created in 2014 by [Jeff Geerling](http://jeffgeerling.com/), author of [Ansible for DevOps](http://ansiblefordevops.com/).
