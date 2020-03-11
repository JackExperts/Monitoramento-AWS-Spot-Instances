#!/bin/bash
# Autor: Ruan Oliveira ruan@jac.bsb.br

inicio=$(date "+%Y-%m-%dT%H:%M:%S" -d '1 hour ago')
fim=$(date "+%Y-%m-%dT%H:%M:%S")

# prereq: aws configure
# as credencias devem estar no home do usuario zabbix

aws ec2 describe-spot-price-history --instance-types $1 --max-items 1 --product-description "Red Hat Enterprise Linux" --start-time $inicio --end-time $fim