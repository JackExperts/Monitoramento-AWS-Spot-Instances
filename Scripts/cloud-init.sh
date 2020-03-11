#!/bin/bash
# Autor: Ruan Oliveira ruan@jac.bsb.br

# infos da instancia ec2
URL_BASE="http://169.254.169.254/latest/meta-data"
HOST=$(curl "$URL_BASE/hostname")
DNS=$(curl "$URL_BASE/public-hostname")
PUBLIC_IP=$(curl "$URL_BASE/public-ipv4")
INSTANCE_ID=$(curl "$URL_BASE/instance-id")
INSTANCE_TYPE=$(curl "$URL_BASE/instance-type")
CREDENTIALS_EC2=$(curl -s "$URL_BASE/identity-credentials/ec2/security-credentials/ec2-instance" | grep -Ev '{|}' | sed -e 's/["]//g' | sed -e ':a;N;$!ba;s/\n//g')
ZONE=$(curl "$URL_BASE/placement/availability-zone")

### Criação e configuração de usuário ###
useradd -s /bin/bash academiajac
echo -e "AlunoJAC\nAlunoJAC" | passwd  sysadmin
chage -d0 academiajac
echo "academiajac    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/turmazabbix
sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/'  /etc/ssh/sshd_config
systemctl restart sshd

# -> install agent zabbix-agent
wget https://repo.zabbix.com/zabbix/4.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.4-1+bionic_all.deb
dpkg -i zabbix-release_4.4-1+bionic_all.deb
apt update
apt install -y zabbix-agent
#rpm -Uvh https://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-2.el7.noarch.rpm
#yum install -y zabbix-agent

# -> configura zabbix-agent
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.ORI
echo 'LogFile=/tmp/zabbix_agentd.log
PidFile=/run/zabbix/zabbix_agentd.pid
EnableRemoteCommands=1
LogRemoteCommands=1
Server=<ip server or proxy zabbix>
ListenPort=10050
Include=/etc/zabbix/zabbix_agentd.d/*.conf
HostnameItem=system.hostname' > /etc/zabbix/zabbix_agentd.conf

# -> inicia servico zabbix
systemctl stop zabbix-agent
systemctl enable zabbix-agent
systemctl start zabbix-agent

## instala docker e docker-compose
apt install -y python3 python3-pip && pip3 install docker-compose && curl https://get.docker.com | bash


### Monitoramento professor ###

API="<url do zabbix>"
ZABBIX_USER='<user do zabbix>'
ZABBIX_PASS='<senha do zabbix>'
GROUP_ID=17 # TO-DO: Buscar o id do grupo via API ou criar se nao existir.


authenticate()
{
    wget --no-check-certificate -O- -o /dev/null $API --header 'Content-Type: application/json' --post-data "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"user.login\",
        \"params\": {
                \"user\": \"$ZABBIX_USER\",
                \"password\": \"$ZABBIX_PASS\"},
        \"auth\": null,
        \"id\": 1}" | cut -d'"' -f8
}
AUTH_TOKEN=$(authenticate)

echo "Autenticacao: $AUTH_TOKEN"

create_host(){
    wget --no-check-certificate -O- -o /dev/null $API --header 'Content-Type: application/json' --post-data "{
      \"jsonrpc\": \"2.0\",
      \"method\": \"host.create\",
      \"params\": {
          \"host\": \"$HOST\",
          \"interfaces\": [
              {
                  \"type\": 1,
                  \"main\": 1,
                  \"useip\": 1,
                  \"ip\": \"$PUBLIC_IP\",
                  \"dns\": \"$DNS\",
                  \"port\": \"10055\"
              }
          ],
          \"groups\": [
              {
                  \"groupid\": \"$GROUP_ID\"
              }
          ],
          \"templates\": [
              {
                  \"templateid\": \"10001\"
              }
          ],
           \"macros\": [
            {
                \"macro\": \"{\$INSTANCE_ID}\",
                \"value\": \"$INSTANCE_ID\"
            },
            {
                \"macro\": \"{\$INSTANCE_TYPE}\",
                \"value\": \"$INSTANCE_TYPE\"
            }
          ],
          \"inventory_mode\": \"0\",
          \"inventory\": {
            \"location\": \"$ZONE\",
            \"type\": \"$INSTANCE_TYPE\",
            \"notes\": \"$CREDENTIALS_EC2\",
            \"tag\": \"$INSTANCE_ID\"
          }
      },
      \"auth\": \"$AUTH_TOKEN\",
      \"id\": 1}"
}

get_host_id(){
    wget --no-check-certificate -O- -o /dev/null $API --header 'Content-Type: application/json' --post-data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"host.get\",
    \"params\": {
    	\"output\": [\"hostid\"],
        \"filter\": {
            \"host\": [
                \"$HOST\"
            ]
        }
    },

    \"auth\": \"$AUTH_TOKEN\",
    \"id\": 1}" | cut -d'"' -f10
}

update_host(){

    HOSTID=$(get_host_id)

    wget --no-check-certificate -O- -o /dev/null $API --header 'Content-Type: application/json' --post-data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"host.update\",
    \"params\": {
        \"hostid\": \"$HOSTID\",
        \"inventory_mode\": 0,
        \"macros\": [
            {
                \"macro\": \"{\$INSTANCE_ID}\",
                \"value\": \"$INSTANCE_ID\"
            },
            {
                \"macro\": \"{\$INSTANCE_TYPE}\",
                \"value\": \"$INSTANCE_TYPE\"
            }
        ],
        \"inventory\": {
            \"location\": \"$ZONE\",
            \"type\": \"$INSTANCE_TYPE\",
            \"notes\": \"$CREDENTIALS_EC2\",
            \"tag\": \"$INSTANCE_ID\"
        }
    },
    \"auth\": \"$AUTH_TOKEN\",
    \"id\": 1}"
}

hostinterface_get_id() {

    HOSTID=$(get_host_id)

    wget --no-check-certificate -O- -o /dev/null $API --header 'Content-Type: application/json' --post-data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"hostinterface.get\",
    \"params\": {
        \"output\": \"interfaceid\",
        \"hostids\": \"$HOSTID\"
    },
    \"auth\": \"$AUTH_TOKEN\",
    \"id\": 1}" | cut -d'"' -f10
}

hostinterface_update() {

    INTERFACEID=$(hostinterface_get_id)

    wget --no-check-certificate -O- -o /dev/null $API --header 'Content-Type: application/json' --post-data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"hostinterface.update\",
    \"params\": {
        \"interfaceid\": \"$INTERFACEID\",
        \"ip\": \"$PUBLIC_IP\",
        \"dns\": \"$DNS\"
    },
    \"auth\": \"$AUTH_TOKEN\",
    \"id\": 1}"
}

HOSTID=$(get_host_id)

if [ "$HOSTID" == "" ]; then
    echo "Criando host no Zabbix, aguarde por favor."
    create_host;
else
    echo "Host ja existe, atualizando-o..."
    update_host;
    hostinterface_update;
fi