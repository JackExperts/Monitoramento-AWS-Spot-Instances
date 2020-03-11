# Monitoramento Spot Instance AWS

Projeto destinado a scripts e templates Zabbix para monitoramento de instancias Spot na AWS via Spotinst.

Material elaborado durante o curso Zabbix para SysAdmin da Academia JAC, ou seja, trata-se de conteúdo para treinamento e não foi usado "ainda" em ambiente de Produção.

Contas necessárias:
- Conta AWS (com suporte a instancias Spot)
  - Access key e Secret key para integrações
- Conta Spotinst integrada a AWS
  - Token gerado

Pré-requisitos para os scripts:
- jq instalado
- awscli instalado e configurado
- curl
- wget
- Configuração das credencias e variáveis conforme seu ambiente.

SO utilizado:
- Ubuntu 18.04

Versões Zabbix testadas:
- 4.2
- 4.4

#### Templates

- Template Conta AWS
  - Conf: aws.conf
  - Script: spotinstAccount.sh
  - LLD: 
    - Discovery: lista_tipos_ec2.txt
    - Script: spotCostHistoryAWS.sh
  
- Template Spot Instance
  - Conf: spots.conf
  - Script: spotInstance.sh (colocar em externalscripts)
  - Necessário configuração da macro {$INSTANCE_ID} com o ID da instancia no host (use o script cloud-init.sh e seja feliz :)
  
#### Complementos

- spotManager.sh: Script que pode ser utilizado em ações automáticas ou em chamadas pelos scripts globais da interface do Zabbix ou qualquer outra forma que considere conveniente.
- cloud-init.sh: Script utilizado no cloud-init AWS para configuração do SO, coleta de dados da instancia em questão, instalação e configuração do Zabbix e registro via API na interface gráfica do Zabbix (cria ou atualiza).

#### Vídeo com demostração

https://www.youtube.com/watch?v=P4aZdRqLAWo&t=1s

