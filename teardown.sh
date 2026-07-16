#!/bin/bash

########################
# Teardown: Limpar recursos da demo
########################

SUB=$(az account show --query id -o tsv)
if [ -z "$SUB" ]; then
  echo "❌ Erro: subscription não detectada. Verifique se está logado."
  exit 1
fi
RG="rg-foundry-demo"

echo "=== Removendo Resource Group: $RG ==="
echo "Isso vai deletar TODOS os recursos da demo."
echo ""
read -p "Confirmar? (y/N) " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    az group delete --name $RG --subscription $SUB --yes --no-wait
    echo "Deleção iniciada (rodando em background)."
    echo "Verifique no portal: https://portal.azure.com"
else
    echo "Cancelado."
fi
