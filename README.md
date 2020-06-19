# Ansible Role: Firewall (iptables)

[![Build Status](https://travis-ci.org/Blue-Bag/ansible-role-firewall.svg?branch=master](https://travis-ci.org/Blue-Bag/ansible-role-firewall)

Installs a simple iptables-based firewall for RHEL/CentOS or Debian/Ubuntu systems.

This firewall aims for simplicity over complexity, and only opens a few specific ports for incoming traffic (configurable through Ansible variables). If you have a rudimentary knowledge of `iptables` and/or firewalls in general, this role should be a good starting point for a secure system firewall.

After the role is run, a `firewall` init service will be available on the server. You can use `service firewall [start|stop|restart|status]` to control the firewall.

Using Jeff Geerlings role as a base this has been, updated to enable more complex chain based mode for the firewall and blocks for common attacks.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `vars/main.yml`):

    firewall_allowed_tcp_ports:
      - "22"
      - "80"
      ...
    firewall_allowed_udp_ports: []

A list of TCP or UDP ports (respectively) to open to incoming traffic.

    firewall_forwarded_tcp_ports:
      - { src: "22", dest: "2222" }
      - { src: "80", dest: "8080" }
    firewall_forwarded_udp_ports: []

Forward `src` port to `dest` port, either TCP or UDP (respectively).

    firewall_additional_rules: []

Any additional (custom) rules to be added to the firewall (in the same format you would add them via command line, e.g. `iptables [rule]`).

## Additional variables for chain
# firewall mode [simple | chain ]
    firewall_mode: simple
In simple mode the role is as per the original
In chain mode the role uses chains, whitelists and other blocks
All of the following variables are only relevant to chain mode

    firewall_whitelist:
     - { name: 'local', ip: "192.168.100.1" }
A list of IPs that will be whitelisted

    firewall_blacklist:
     - { name: 'Some rogue', ip: "96.47.225.0/24" }
A list of IPs that will be blacklisted

    firewall_protected_chains:
      - {
         port: "22",
         name: "SSH",
         default: "DROP",
         ratelimit: "True",
         hit_rate: 4,
         hit_ttl: 60
        }
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
      - {
         port: "3306",
         name: "MYSQL",
         default: "DROP"
         }
Chain definitions. The port to create a chain for and the default action

    firewall_allow_ping: true
An option t enable/disable ping blocking
Note you may need this on for monitoring

# extended rules
    firewall_extra_security: true
Option to exclude all of the following extra security blocks

    firewall_block_portscan: true
Include a portscan protection block

    firewall_block_spoofed: true
Inclde a block for spoofed addresses
This also has an exclusion to not include when running against a local group host

    firewall_block_smurf: true
A block to protect against smurf attacks

Rate limiting:
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset


## IPset

ipset add blocked-ips 195.154.215.122

# sort and filter the blocked ips list
cat blocked-ips.txt | sort -n | uniq > blocked-ips.txt


## Dependencies

None.

## Example Playbook

    - hosts: server
      vars_files:
        - vars/main.yml
      roles:
        - { role: geerlingguy.firewall }

*Inside `vars/main.yml`*:

    firewall_allowed_tcp_ports:
      - "22"
      - "25"
      - "80"

## TODO

  - Make outgoing ports more configurable.
  - Make other firewall features (like logging) configurable.

## License

MIT / BSD

## Author Information

This role was created in 2014 by [Jeff Geerling](http://jeffgeerling.com/), author of [Ansible for DevOps](http://ansiblefordevops.com/).
