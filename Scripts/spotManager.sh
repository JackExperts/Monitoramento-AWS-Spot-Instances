#!/bin/bash
# Autor: Ruan Oliveira ruan@jac.bsb.br

TOKEN=<token aqui>
ACCOUNT_ID=<id da conta>
GROUP_ID=<id do grupo>
ESCOLHA=$1
ESCOLHA_OP=$2

obtem() {
   URL=https://api.spotinst.io/aws/ec2/group/${GROUP_ID}/status?accountId=${ACCOUNT_ID}
   RETORNO=`curl -s -H "Content-Type: application/json" -H  "Authorization: Bearer $TOKEN"  $URL`
   echo $RETORNO | jq '.[]' | grep public | cut -d ":" -f 2
}

sobe() {
  RETORNO=`curl -X PUT -s -H "Content-Type: application/json" -H  "Authorization: Bearer $TOKEN"  https://api.spotinst.io/aws/ec2/group/${GROUP_ID}/scale/up?adjustment=${ESCOLHA_OP}&accountId=${ACCOUNT_ID}`
  echo $RETORNO | jq .
}

para() {
  RETORNO=`curl -X PUT -s -H "Content-Type: application/json" -H  "Authorization: Bearer $TOKEN"   https://api.spotinst.io/aws/ec2/group/${GROUP_ID}/scale/down?adjustment=${ESCOLHA_OP}&accountId=${ACCOUNT_ID}`
  echo $RETORNO | jq .
}

pause() {
  RETORNO=`curl -X PUT -s -H "Content-Type: application/json" -H  "Authorization: Bearer $TOKEN"   https://api.spotinst.io/aws/ec2/group/${GROUP_ID}/statefulInstance/${ESCOLHA_OP}/pause?accountId=${ACCOUNT_ID}`
  echo $RETORNO | jq .
}

main() {
  case $ESCOLHA in
    ver) obtem;;
    sobe) sobe;;
    para) para;;
    pause) pause;;
    *)             echo "ver, sobe ou para";;
  esac
}

main