#!/bin/bash
# Autor: Ruan Oliveira ruan@jac.bsb.br

TOKEN=<token aqui>
ACCOUNT_ID=<id da conta>

curl -X GET -s -H "Content-Type: application/json" -H  "Authorization: Bearer ${TOKEN}" "https://api.spotinst.io/aws/costs?accountId=${ACCOUNT_ID}"