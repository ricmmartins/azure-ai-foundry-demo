#!/bin/bash

########################
# Demo: Azure AI Foundry do Zero
# Usa demo-magic para simulated typing
# Cada passo espera ENTER para avançar
########################

# Detectar se pv existe
HAS_PV=true
if ! command -v pv &> /dev/null; then
    HAS_PV=false
fi

# Carregar demo-magic
# -d = desabilita TYPE_SPEED (bypass do check_pv)
# -n = no wait automático (controlamos manualmente com wait)
. ./demo-magic.sh -d -n

# Se pv existe, reabilitar simulated typing
if [ "$HAS_PV" = true ]; then
    TYPE_SPEED=40
fi
DEMO_PROMPT="${GREEN}azure-demo${COLOR_RESET} $ "

# === Variáveis ===
SUB=$(az account show --query id -o tsv)
if [ -z "$SUB" ]; then
  echo "❌ Erro: subscription não detectada. Rode 'az login' primeiro."
  exit 1
fi
echo "✅ Subscription: $SUB"
RG="rg-foundry-demo"
LOCATION="eastus2"
HUB_NAME="hub-demo-lg"
PROJECT_NAME="demo-lg-hrtech"
LOG_ANALYTICS="law-foundry-demo"
APP_INSIGHTS="appi-foundry-demo"

clear

# ===================================
# Passo 1: Resource Group
# ===================================
p "# === Passo 1: Criar Resource Group ==="
wait
pe "az group create --name $RG --location $LOCATION --subscription $SUB --tags team=foundry-demo"

# ===================================
# Passo 2: Log Analytics Workspace
# ===================================
p "# === Passo 2: Criar Log Analytics Workspace ==="
wait
pe "az monitor log-analytics workspace create --resource-group $RG --workspace-name $LOG_ANALYTICS --location $LOCATION --subscription $SUB --retention-time 30"

# ===================================
# Passo 3: Application Insights
# ===================================
p "# === Passo 3: Criar Application Insights ==="
wait

pe "LAW_ID=\$(az monitor log-analytics workspace show --resource-group $RG --workspace-name $LOG_ANALYTICS --subscription $SUB --query id -o tsv)"

pe "az monitor app-insights component create --app $APP_INSIGHTS --location $LOCATION --resource-group $RG --subscription $SUB --workspace \$LAW_ID --kind web"

# ===================================
# Passo 4: AI Foundry Hub
# ===================================
p "# === Passo 4: Criar AI Foundry Hub ==="
wait

pe "APPINSIGHTS_ID=\$(az monitor app-insights component show --app $APP_INSIGHTS --resource-group $RG --subscription $SUB --query id -o tsv)"

pe "az ml workspace create --kind hub --resource-group $RG --name $HUB_NAME --location $LOCATION --subscription $SUB --application-insights \$APPINSIGHTS_ID"

# ===================================
# Passo 5: AI Foundry Project
# ===================================
p "# === Passo 5: Criar AI Foundry Project ==="
wait

pe "HUB_ID=\$(az ml workspace show --name $HUB_NAME --resource-group $RG --subscription $SUB --query id -o tsv)"

pe "az ml workspace create --kind project --resource-group $RG --name $PROJECT_NAME --hub-id \$HUB_ID --subscription $SUB"

# ===================================
# Passo 6: Diagnostic Settings
# ===================================
p "# === Passo 6: Configurar Diagnostic Settings ==="
wait

pe "LAW_ID=\$(az monitor log-analytics workspace show --resource-group $RG --workspace-name $LOG_ANALYTICS --subscription $SUB --query id -o tsv)"

pe "HUB_RESOURCE_ID=\$(az ml workspace show --name $HUB_NAME --resource-group $RG --subscription $SUB --query id -o tsv)"

pe "az monitor diagnostic-settings create --name foundry-diagnostics --resource \$HUB_RESOURCE_ID --workspace \$LAW_ID --logs '[{\"categoryGroup\":\"allLogs\",\"enabled\":true}]' --metrics '[{\"category\":\"AllMetrics\",\"enabled\":true}]'"

# ===================================
# Passo 7: Aguardar AI Services (criado pelo Hub)
# ===================================
p "# === Passo 7: Aguardando AI Services ficar disponível ==="
wait

p "# O Hub cria o AI Services automaticamente, mas pode levar alguns minutos..."

# Polling loop - espera até o AI Services existir no RG
AI_SERVICES_NAME=""
RETRIES=0
MAX_RETRIES=30
while [ -z "$AI_SERVICES_NAME" ] && [ $RETRIES -lt $MAX_RETRIES ]; do
  AI_SERVICES_NAME=$(az cognitiveservices account list --resource-group $RG --subscription $SUB --query '[0].name' -o tsv 2>/dev/null)
  if [ -z "$AI_SERVICES_NAME" ]; then
    RETRIES=$((RETRIES + 1))
    echo "  ⏳ Tentativa $RETRIES/$MAX_RETRIES - aguardando AI Services... (10s)"
    sleep 10
  fi
done

if [ -z "$AI_SERVICES_NAME" ]; then
  echo "❌ AI Services não encontrado após ${MAX_RETRIES} tentativas."
  echo "   Verifique se o Hub foi criado corretamente."
  exit 1
fi

echo "✅ AI Services encontrado: $AI_SERVICES_NAME"
pe "az cognitiveservices account list --resource-group $RG --subscription $SUB -o table"

# ===================================
# Passo 8: Deploy do modelo GPT-4o
# ===================================
p "# === Passo 8: Deploy do GPT-4o ==="
wait

pe "az cognitiveservices account deployment create --name $AI_SERVICES_NAME --resource-group $RG --subscription $SUB --deployment-name gpt-4o-global --model-name gpt-4o --model-version 2024-11-20 --model-format OpenAI --sku-capacity 80 --sku-name GlobalStandard"

# ===================================
# Passo 9: Testar via REST
# ===================================
p "# === Passo 9: Testar o modelo via REST ==="
wait

pe "AI_ENDPOINT=\$(az cognitiveservices account show --name $AI_SERVICES_NAME --resource-group $RG --subscription $SUB --query properties.endpoint -o tsv)"

pe "AI_KEY=\$(az cognitiveservices account keys list --name $AI_SERVICES_NAME --resource-group $RG --subscription $SUB --query key1 -o tsv)"

p "# Enviando prompt de teste (cenário RH - triagem de currículo)..."
wait

pe "curl -s \"\${AI_ENDPOINT}openai/deployments/gpt-4o-global/chat/completions?api-version=2024-10-21\" -H \"Content-Type: application/json\" -H \"api-key: \$AI_KEY\" -d '{\"messages\":[{\"role\":\"system\",\"content\":\"Você é um assistente de RH especializado em triagem de currículos.\"},{\"role\":\"user\",\"content\":\"Analise este perfil: João Silva, 5 anos exp Python/Django, AWS, inglês fluente. A vaga pede: 3+ anos Python, cloud, inglês. Ele é aderente?\"}],\"max_tokens\":300}' | python3 -m json.tool"

# ===================================
# Passo 10: KQL Query
# ===================================
p "# === Passo 10: Consulta KQL nos logs ==="
wait

pe "az monitor log-analytics query --workspace \$LAW_ID --analytics-query 'AzureDiagnostics | where ResourceProvider == \"MICROSOFT.COGNITIVESERVICES\" | project TimeGenerated, OperationName, DurationMs, ResultSignature | order by TimeGenerated desc | take 10' --timespan PT1H -o table 2>/dev/null || echo '(Logs podem levar alguns minutos para aparecer)'"

# ===================================
# Fim
# ===================================
echo ""
p "# === Demo finalizada! ==="
p "# Agora vamos ver tudo isso no portal: https://ai.azure.com"
echo ""
