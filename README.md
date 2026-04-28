# Upskill-Projecto-Final


Esqueci-me de incluir uma imagem no relatório relativamente à configuração do DNS na máquina host. O professor Paulo Mato recomendou colocá-la no repositório remoto, portanto, informo que a imagem tem o nome de "Config-DNS-Host.png" e encontra-se na raíz do projecto, tanto no repositório do GitHub como no do Azure Repos.

____________________________________________________

Como configurar o MYSQL e fazer o teste no navegador
____________________________________________________

Para não divulgar dados sensíveis no GitHub incluiu-se no .gitignore os seguintes ficheiros em relação a dados de acesso à base de dados MYSQL:
ansible/roles/mysql_container/defaults/main.yml
ansible/roles/nginx_container/templates/index.php

Para a base de dados funcionar é necessário definir os dados de acesso no seguinte ficheiro e alterar o nome deste para main.yml:
ansible/roles/mysql_container/defaults/main-template.yml 
(não se deve subescrever ou apagar main-template.yml)

O ficheiro index.php usa dados de acesso MYSQL, portanto para fazer o teste de ligação no browser é necessário preencher os campos vazios com a informação correcta no seguinte ficheiro e alterar o nome para index.php:
ansible/roles/nginx_container/templates/index-template.php
(não se deve subescrever ou apagar index-template.php)


Correr o playbook pb-webserver.yml para iniciar o nginx, mysql, phpmyadmin e php.
Se for necessário dns é necessário correr o playbook.yml

Playbooks:
pb-webserver.yml
playbook.yml

Para ligar ao servidor web:

http://192.168.10.20   <-   Porta 80
https://192.168.10.20   <-   Porta 433

ou

http://technova.pt  <-   Porta 80
https://technova.pt   <-   Porta 433



Para ligar ao PHPmyadmin:

http://192.168.10.20:8088  <-   Porta 80
https://192.168.10.20:8088  <-   Porta 443

ou

http://technova.pt:8088  <-   Porta 80
http://technova.pt:8088  <-   Porta 443



____________________________________________________

Servidor de Monitorização - Links das ferramentas
____________________________________________________


Prometheus    -> http://192.168.10.40:9090

Node Exporter -> http://192.168.10.10:9100
                 http://192.168.10.20:9100
                 http://192.168.10.30:9100
                 http://192.168.10.40:9100

                 http://192.168.10.10:9100/metrics
                 http://192.168.10.20:9100/metrics
                 http://192.168.10.30:9100/metrics
                 http://192.168.10.40:9100/metrics

Grafana       -> http://192.168.10.40:3000

cAdvisor      -> http://192.168.10.20:8080


___________________________________________________________

Servidor de Monitorização - Grafana - Persistencia de dados
___________________________________________________________

Para que os Dashboards criados no Grafana não sejam eliminados depois de apagar as Maquinas Virtuais (ex.: usando "vagrant destroy") mapeou-se a pasta local ./grafana-data com (mesmo directório do vagrantfile) à pasta /var/lib/grafana (no servidor de monitorização).

Se a pasta "./grafana-data" não existir ela é criada, mas se já existir, não se deve apagar, para não perder dados do Grafana como por exemplo, os Dashboards já criados. 

_______________________________________________________________

Common - Base de todas as VMs
_______________________________________________________________

Aplicado a todas as VMs antes de qualquer outra role, para garantir uma base consistente em todo o ambiente.

O que configura:

  - Atualização do cache apt 
  - Instalação de pacotes essenciais: curl, vim, git, htop, net-tools
  - Timezone do sistema: Europe/Lisbon
  - Serviço systemd-timesyncd ativo e a sincronizar o relógio

Para validar numa VM:

  timedatectl
  systemctl status systemd-timesyncd

_______________________________________________________________

Utilizadores de Sistema - sysadmin e operator
_______________________________________________________________

Criados em todas as VMs. O utilizador sysadmin tem privilégios totais (sudo sem password). O utilizador operator não tem acesso sudo.

sysadmin:
  Autenticação: exclusivamente por chave SSH (sem password)
  Sudo: NOPASSWD:ALL — pode executar qualquer comando como root sem password
  Chave privada: /home/vagrant/.ssh/technova_sysadmin (na VM auto)
  Chave pública: ansible/keys/sysadmin/technova_sysadmin.pub

operator:
  Autenticação: exclusivamente por chave SSH (sem password)
  Sudo: nenhum — não está no grupo sudo nem tem entrada em sudoers
  Password: bloqueada ao nível da conta (password_lock) — não é possível login por password
  Chave privada: /home/vagrant/.ssh/technova_operator (na VM auto)
  Chave pública: ansible/keys/operator/technova_operator.pub

Para ligar como sysadmin a partir da VM auto:

  ssh -i /home/vagrant/.ssh/technova_sysadmin sysadmin@192.168.10.10

Para ligar como operator a partir da VM auto:

  ssh -i /home/vagrant/.ssh/technova_operator operator@192.168.10.10

Para verificar acesso sudo numa VM (como sysadmin):

  sudo whoami          # deve retornar: root
  sudo -l              # lista todos os comandos permitidos

Para verificar que o operator não tem sudo:

  sudo whoami          # deve falhar com: operator is not in the sudoers file
  sudo -l              # deve retornar: User operator may not run sudo on <hostname>

___________________________________________________________________________

Servidor LDAP - LDAP Account Manager (LAM)
___________________________________________________________________________

Interface web para gestao de utilizadores do directorio LDAP.

URL: https://192.168.10.10
Login: sysadmin / Sysadmin2026!

Para correr o playbook:

vagrant ssh auto
cd /vagrant/ansible
ansible-playbook -i inventory.ini playbook.yml --limit infra

Para verificar os utilizadores no directorio (executar na VM infra):

   ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=technova,dc=local" -w Sysadmin2026! -b "ou=users,dc=technova,dc=local" "(objectClass=posixAccount)" uid

Para pesquisar um utilizador especifico:

   ldapsearch -x -H ldap://127.0.0.1 -D "cn=admin,dc=technova,dc=local" -w Sysadmin2026! -b "dc=technova,dc=local" "(uid=jjunior)"

Para confirmar resolucao POSIX via SSSD:

   id jjunior

Para o browser confiar no certificado LDAP (necessario uma vez por maquina):

1. Copiar o certificado da CA da VM (executar na raiz do projeto):

   vagrant scp infra:/etc/ssl/technova-ca/ca.crt ./ca.crt

2. Importar no Windows (PowerShell como Administrador):

   Import-Certificate -FilePath ".\ca.crt" -CertStoreLocation Cert:\LocalMachine\Root

3. Importar no macOS:

   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./ca.crt

   Apos importar, reiniciar o browser.

Nota: o plugin vagrant-scp deve estar instalado: vagrant plugin install vagrant-scp

___________________________________________________________________________

Samba - Pasta Partilhada
___________________________________________________________________________

Acesso via explorador de ficheiros do Windows.

Endereco: \\192.168.10.10\share

Utilizadores validos: sysadmin, operator e utilizadores do grupo smbusers
Passwords: sysadmin (Sysadmin2026!); operator (Operator2026!); demais utilizadores (Change2026!).

Para verificar acesso ao Samba (executar na VM infra):

   smbclient //192.168.10.10/share -U utilizador%password!

Para confirmar resolucao do utilizador via SSSD:

   id utilizador

No explorador de ficheiros do Windows introduzir:
\\192.168.10.10\share
_______________________________________________________________

Firewall - iptables
_______________________________________________________________

Aplicada a todas as VMs antes de qualquer role de serviço. Define política DROP por defeito no chain INPUT e abre apenas as portas necessárias em cada máquina.

Portas abertas por máquina:

  Todas as VMs  ->  22/TCP  (SSH)
                    80/TCP  (HTTP)
                   443/TCP  (HTTPS)

  infra         ->  53/TCP e 53/UDP  (DNS)
                   389/TCP           (LDAP)
                   445/TCP           (Samba SMB)

  app           ->  8080/TCP  (cAdvisor)
                    8088/TCP  (PHPMyAdmin HTTP)
                    8443/TCP  (PHPMyAdmin HTTPS)

  monitor       ->  3000/TCP  (Grafana)
                    9090/TCP  (Prometheus)

Nota: as portas 9100 (Node Exporter) e 9101/9102/9103 (Bacula) são abertas pelas respetivas roles diretamente.

Para verificar as regras activas numa VM:

  sudo iptables -L INPUT -n -v --line-numbers

Para testar conectividade entre VMs (ex.: testar LDAP a partir da app):

  nc -zv 192.168.10.10 389

Para testar ping entre VMs:

  ping -c 3 192.168.10.10

Para abrir uma porta temporariamente (sem Ansible):

  sudo iptables -I INPUT 1 -p tcp --dport <porta> -j ACCEPT

Para remover uma porta temporariamente:

  sudo iptables -L INPUT -n --line-numbers          # ver número da linha
  sudo iptables -D INPUT <numero_da_linha>           # remover pelo número

Para tornar alterações manuais persistentes:

  sudo netfilter-persistent save

Para adicionar uma porta de forma permanente, editar o ficheiro host_vars do host em causa:

  ansible/host_vars/infra.yml
  ansible/host_vars/app.yml
  ansible/host_vars/monitor.yml

E re-correr o playbook a partir da VM auto:

  vagrant ssh auto
  cd /vagrant/ansible
  ansible-playbook -i inventory.ini playbook.yml

_______________________________________________________________

Segurança - SSH Hardening + fail2ban
_______________________________________________________________

Aplicado a todas as VMs. Desativa autenticação por password e acesso root via SSH — apenas chaves públicas são aceites. O fail2ban monitoriza tentativas de login falhadas e bane IPs automaticamente.

Configuração SSH aplicada:

  PermitRootLogin no
  PasswordAuthentication no
  KbdInteractiveAuthentication no
  PubkeyAuthentication yes

fail2ban (jail SSH):

  5 tentativas falhadas em 10 minutos -> ban de 1 hora

Para validar numa VM:

  sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication'
  sudo fail2ban-client status sshd

_______________________________________________________________

Backup - Bacula
_______________________________________________________________

Sistema de backup agendado diariamente as 02:00. Faz backup de /etc, /var/log e /home em todas as VMs. No infra inclui tambem o dump do LDAP.

Director + Storage: infra (192.168.10.10)
Clientes: todas as VMs (auto, infra, app, monitor)

Para correr o playbook:

vagrant ssh auto
cd /vagrant/ansible
ansible-playbook -i inventory.ini playbook.yml

Para gerir backups (na VM infra):

sudo bconsole

Comandos uteis no bconsole:
status dir                     - estado do Director e jobs agendados
status client                  - estado dos clientes
run job=Backup-<VM>            - executar backup manualmente (VMs: infra, app, monitor, auto)
list jobs                      - historico de backups
list volumes                   - volumes guardados em /backup
