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
    echo "✅ Deleção do RG iniciada (rodando em background)."

    # Purgar AI Services soft-deleted para evitar erro FlagMustBeSetForRestore na próxima rodada
    echo ""
    echo "⏳ Aguardando RG ser deletado para purgar AI Services..."
    echo "   (Se não quiser esperar, rode manualmente depois:)"
    echo "   az cognitiveservices account purge --name ais-demo-lg --resource-group $RG --location eastus2"
    echo ""
    az group wait --name $RG --subscription $SUB --deleted 2>/dev/null
    az cognitiveservices account purge --name ais-demo-lg --resource-group $RG --location eastus2 --subscription $SUB 2>/dev/null && echo "✅ AI Services purgado." || echo "⚠️ Purge falhou ou já purgado. OK."

    echo ""
    echo "Verifique no portal: https://portal.azure.com"
else
    echo "Cancelado."
fi
