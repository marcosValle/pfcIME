# pfcIME

Esse sistema provê um módulo de segurança para servidores linux Ubuntu 14.04 baseado nos seguintes sub-módulos:

1. Firewall iptables como primeira barreira de defesa.
2. fwsnort como IPS baseado no Snort, com suas regras convertidas para regras iptables.
3. psad como monitor de logs e sistema de alerta por email.
4. update_daemon como script de inserção de IPs bloqueados pel psad em um ipset, para serem verificados pelo firewall
5. [OPCIONAL] Honeypot a ser utilizado para o encaminhamento de requisições previamente identificada como maliciosas.

# Arquitetura

O sistema completo tem seu fluxo de dados ilustrado na figura abaixo

![alt tag](http://url/to/img.png)

Uma vez que um pacote direcionado ao servidor entra no sistema, passa primeiramente pelas regras do firewall. Caso não esteja de acordo com alguma, é registrado no arquivo de logs.

Para aumentar a eficácia dos registros, é utilizado o fwsnort, que converte automaticamente parte das regras Snort para regras iptables com grau de acerto aceitável. Com isso é possível utilizar do Snort como IPS por meio dos recursos de filtragem de pacotes do netfilter.

A ferramenta psad monitora os logs e adiciona endereços IPs identificados como maliciosos ao arquivo ips_blocked_iptables. A princípio, todos os pacotes vindos desses IPs seriam então descartados.

O update_daemon é um script que usa inotify_tools para monitorar o ip_blocked_iptables e adicionar os IPs a um ipset. Dessa forma, o iptables pode utilizar esses endereços para redirecioná-los para o honeypot.
