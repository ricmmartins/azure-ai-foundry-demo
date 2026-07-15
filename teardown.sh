#!/bin/bash

########################
# Teardown: Limpar recursos da demo
########################

SUB="313dd062-1c1c-428a-afc4-4e271378679f"
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
