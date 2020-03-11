#!/bin/bash
# Autor: Ruan Oliveira ruan@jac.bsb.br

TOKEN=<token aqui>
ACCOUNT_ID=<id da conta>
GROUP_ID=<id do grupo>
INSTANCE_ID=$1

curl -X GET -s -H "Content-Type: application/json" -H  "Authorization: Bearer ${TOKEN}" "https://api.spotinst.io/aws/ec2/group/${GROUP_ID}/costs/detailed?accountId=${ACCOUNT_ID}" | jq -r ".response.items[] | select(.instanceId==\"$INSTANCE_ID\")" | jq -r "$2"