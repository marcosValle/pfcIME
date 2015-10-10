# pfcIME

This system provides a security module for Ubuntu 14.04 web servers. It is based on the following submodules:

1. Firewall iptables as the first defensive line.
2. fwsnort as a Snort based IPS
3. psad as the log monitor and email alert system.
4. update_daemon as the blocked IPs insertion script into an ipset.
5. [OPTIONAL] Honeypot to be used for receiving forwarded previously identified malicious requests.

# Architecture

The complete system has it's data flow shown in the picture below.

![alt tag](http://url/to/img.png)

Once a packet enters the system, it goes first through the firewall rules. If it does not attend to any of those rules it is logged.

In order to increase logging efficiency, fwsnort is used to automatically convert part of the Snort rules into iptables rules. This way it is possible to use Snort as an IPS through Netfilter's packets filtering resources.

The psad tools monitors logs and adds malicious IP addresses into ips_blocked_iptables. At first, all packets comming from these IPs will be dropped.

The update_daemon is a script that uses inotify_tools to monitor the ip_blocked_iptables and add the IPs into an ipset. This way, iptables is able to use these addresses to redirect them to the honeypot.

# Installation

The full architecture solution requires a honeypot machine to work properly. We recommend the use of HoneyDrive 3 OS. Both physical and virtualized solutions are acceptable. Some configurations must be manually set in the configuration files.

* config/iptables/iptables.sh
```
	$INT_NET >> endereco e mascara da rede interna
	$INT_INTF >> interface interna
	$EXT_INTF >> interface externa
	$SERVER_ADDR >> endereco IP do servidor
	$HPT_ADDR >> endereco IP do Honeypot
```
* config/psad/psad.conf
`EMAIL_ADDRESSES >> emails para receber os alertas`

# Usage

To start the solution

`./run`

To stop the solution and free IPs

`./stop_seg`

# Contributing

See [Contributing](docs/CONTRIBUTING.md)
