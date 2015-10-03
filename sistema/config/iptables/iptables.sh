#!/bin/bash
#
#############################################################################
#
# Objetivo: Implementar a politica padrao de seguranca, com logs e regras.
# 	    
# Contato:
#	1TEN Marcos Valle 
#	marcos.valle01@gmail.com
# @2015
#############################################################################
#

IPTABLES=/sbin/iptables
IP6TABLES=/sbin/ip6tables
MODPROBE=/sbin/modprobe
INT_NET=192.168.1.0/16
INT_INTF=eth0	#Interface interna (entrada)
EXT_INTF=eth0	#Interfaca externa (saida)
SERVER_ADDR=192.168.56.103
HONEYPOT_ADDR=192.168.56.102

### remove regras existentes e define a politica padrao para DROP (default deny)
echo "[+] Removendo regras existentes..."
$IPTABLES -F	#remove regras da tabela INPUT
$IPTABLES -F -t nat	#remove regras da tabela NAT
$IPTABLES -X	#remove cadeias definidas pelo usuario
$IPTABLES -P INPUT DROP #define a politica default deny
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

### todo o trafego IPv6 e descartado
#
echo "[+] Desabilitando trafego IPv6..."
$IP6TABLES -P INPUT DROP
$IP6TABLES -P OUTPUT DROP
$IP6TABLES -P FORWARD DROP

### carrega modulos de rastreio de conexao
#
$MODPROBE ip_conntrack
$MODPROBE iptable_nat
$MODPROBE ip_conntrack_ftp
$MODPROBE ip_nat_ftp

###### cadeia INPUT ######
#
echo "[+] Configurando cadeia INPUT..."

### regras de rastreio
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j LOG --log-prefix "PACOTE INVALIDO " --log-ip-options --log-tcp-options
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP
$IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### regras anti-spoofing
$IPTABLES -A INPUT -i $INT_INTF ! -s $INT_NET -j LOG --log-prefix "PACOTE SPOOFADO"
$IPTABLES -A INPUT -i $INT_INTF ! -s $INT_NET -j DROP

### regras ACCEPT
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 22 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 80 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 443 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 8080 -m conntrack --ctstate NEW -j ACCEPT #aplicacao do admin
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 8081 -m conntrack --ctstate NEW -j ACCEPT #aplicacao do admin
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 4848 -m conntrack --ctstate NEW -j ACCEPT #glassfish admin
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 9090 -m conntrack --ctstate NEW -j ACCEPT #geoserver
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 9191 -m conntrack --ctstate NEW -j ACCEPT #geoserver
$IPTABLES -A INPUT -i $INT_INTF -p tcp -s $INT_NET --dport 5432 -m conntrack --ctstate NEW -j ACCEPT #postgres
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

### regra de log padrao da cadeia INPUT
$IPTABLES -A INPUT ! -i lo -j LOG --log-prefix "DROP " --log-ip-options --log-tcp-options

### todo trafego interno (loop) eh aceito
$IPTABLES -A INPUT -i lo -j ACCEPT

#
###### cadeia OUTPUT ######
#
echo "[+] Configurando cadeia OUTPUT..."

### regras de rastreio de status
$IPTABLES -A OUTPUT -m conntrack --ctstate INVALID -j LOG --log-prefix "PACOTE INVALIDO " --log-ip-options --log-tcp-options
$IPTABLES -A OUTPUT -m conntrack --ctstate INVALID -j DROP
$IPTABLES -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### regras ACCEPT para saida de pacotes
$IPTABLES -A OUTPUT -p tcp --dport 21 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 25 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 43 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 4321 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

$IPTABLES -A OUTPUT -p tcp --dport 8080 -m conntrack --ctstate NEW -j ACCEPT #aplicacao do admin
$IPTABLES -A OUTPUT -p tcp --dport 8081 -m conntrack --ctstate NEW -j ACCEPT #aplicacao do admin
$IPTABLES -A OUTPUT -p tcp --dport 4848 -m conntrack --ctstate NEW -j ACCEPT #glassfish admin
$IPTABLES -A OUTPUT -p tcp --dport 9090 -m conntrack --ctstate NEW -j ACCEPT #geoserver
$IPTABLES -A OUTPUT -p tcp --dport 9191 -m conntrack --ctstate NEW -j ACCEPT #geoserver
$IPTABLES -A OUTPUT -p tcp --dport 5432 -m conntrack --ctstate NEW -j ACCEPT #postgres
$IPTABLES -A OUTPUT -p udp --dport 5432 -m conntrack --ctstate NEW -j ACCEPT #postgres
$IPTABLES -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

### regra de log padrao para OUTPUT
$IPTABLES -A OUTPUT ! -o lo -j LOG --log-prefix "DROP " --log-ip-options --log-tcp-options

### aceita fluxo de saida interno
$IPTABLES -A OUTPUT -o lo -j ACCEPT

###### FORWARD chain ######
#
echo "[+] Configurando cadeia FORWARD..."

### regras de rastreio
$IPTABLES -A FORWARD -m conntrack --ctstate INVALID -j LOG --log-prefix "DROP INVALID " --log-ip-options --log-tcp-options
$IPTABLES -A FORWARD -m conntrack --ctstate INVALID -j DROP
$IPTABLES -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### regras anti-spoofing
$IPTABLES -A FORWARD -i $INT_INTF ! -s $INT_NET -j LOG --log-prefix "SPOOFED PKT "
$IPTABLES -A FORWARD -i $INT_INTF ! -s $INT_NET -j DROP

# Regras contra Stealth Scan
###########################################################
iptables -N STEALTH_SCAN # "STEALTH_SCAN"
iptables -A STEALTH_SCAN -j LOG --log-prefix "STEALTH SCAN: "
iptables -A STEALTH_SCAN -j ACCEPT

iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN

### regras ACCEPT
$IPTABLES -A FORWARD -p tcp -i $INT_INTF -s $INT_NET --dport 21 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp -i $INT_INTF -s $INT_NET --dport 22 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp -i $INT_INTF -s $INT_NET --dport 25 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp -i $INT_INTF -s $INT_NET --dport 43 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp -i $INT_INTF -s $INT_NET --dport 4321 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
$IPTABLES -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT

### regra de LOG padrao
$IPTABLES -A FORWARD ! -i lo -j LOG --log-prefix "DROP " --log-ip-options --log-tcp-options

###### forwarding ######
ipset create banned_nets hash:ip hashsize 4096
iptables -t nat -A PREROUTING -p tcp -m set -j DNAT --to-destination $HONEYPOT_ADDR --match-set banned_nets src
iptables -t nat -A PREROUTING -p udp -m set -j DNAT --to-destination $HONEYPOT_ADDR --match-set banned_nets src

iptables -t nat -A POSTROUTING -p tcp -m set -j SNAT --to-source $SERVER_ADDR --match-set banned_nets src
iptables -t nat -A POSTROUTING -p udp -m set -j SNAT --to-source $SERVER_ADDR --match-set banned_nets src


echo "[+] Ativando encaminhamento IP..."
echo 1 > /proc/sys/net/ipv4/ip_forward

### EOF ###
