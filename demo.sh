#!/bin/bash

########################
# Demo: Azure AI Foundry do Zero
# Usa demo-magic para simulated typing
# Cada passo espera ENTER para avançar
########################

# Se pv não estiver instalado, desabilita simulated typing
# (demo-magic checa TYPE_SPEED no source e aborta se pv não existe)
HAS_PV=true
if ! command -v pv &> /dev/null; then
    echo "⚠ pv não encontrado. Rodando sem simulated typing."
    echo "  Para ter typing simulado: ./setup.sh (instala pv)"
    echo ""
    HAS_PV=false
fi

# Carregar demo-magic (sem TYPE_SPEED para evitar check_pv)
unset TYPE_SPEED
. ./demo-magic.sh -n

# Agora sim, configurar TYPE_SPEED se pv existe
if [ "$HAS_PV" = true ]; then
    TYPE_SPEED=40
fi
DEMO_PROMPT="${GREEN}azure-demo${COLOR_RESET} $ "

# === Variáveis ===
SUB="313dd062-1c1c-428a-afc4-4e271378679f"
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
# Passo 7: Listar serviços AI disponíveis
# ===================================
p "# === Passo 7: Listar AI Services do Hub ==="
wait

pe "az cognitiveservices account list --resource-group $RG --subscription $SUB -o table"

# ===================================
# Passo 8: Deploy do modelo GPT-4o
# ===================================
p "# === Passo 8: Deploy do GPT-4o ==="
wait

pe "AI_SERVICES_NAME=\$(az cognitiveservices account list --resource-group $RG --subscription $SUB --query '[0].name' -o tsv)"

pe "az cognitiveservices account deployment create --name \$AI_SERVICES_NAME --resource-group $RG --subscription $SUB --deployment-name gpt-4o-global --model-name gpt-4o --model-version 2024-11-20 --model-format OpenAI --sku-capacity 80 --sku-name GlobalStandard"

# ===================================
# Passo 9: Testar via REST
# ===================================
p "# === Passo 9: Testar o modelo via REST ==="
wait

pe "AI_ENDPOINT=\$(az cognitiveservices account show --name \$AI_SERVICES_NAME --resource-group $RG --subscription $SUB --query properties.endpoint -o tsv)"

pe "AI_KEY=\$(az cognitiveservices account keys list --name \$AI_SERVICES_NAME --resource-group $RG --subscription $SUB --query key1 -o tsv)"

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
