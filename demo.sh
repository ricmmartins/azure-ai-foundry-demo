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
AI_SERVICES="ais-demo-lg"

clear

# ===================================
p "# Primeiro, vamos criar o Resource Group onde tudo vai ficar organizado"
wait
pe "az group create --name $RG --location $LOCATION --subscription $SUB --tags team=foundry-demo"

# ===================================
p "# Agora o Log Analytics — é aqui que todos os logs e métricas vão parar"
wait
pe "az monitor log-analytics workspace create --resource-group $RG --workspace-name $LOG_ANALYTICS --location $LOCATION --subscription $SUB --retention-time 30"

# ===================================
p "# Application Insights conectado ao Log Analytics — rastreia requests, latência, erros"
wait

pe "LAW_ID=\$(az monitor log-analytics workspace show --resource-group $RG --workspace-name $LOG_ANALYTICS --subscription $SUB --query id -o tsv)"

pe "az monitor app-insights component create --app $APP_INSIGHTS --location $LOCATION --resource-group $RG --subscription $SUB --workspace \$LAW_ID --kind web"

# ===================================
p "# Criando o AI Services — é o recurso que hospeda os modelos (GPT-5, etc.)"
wait

pe "az cognitiveservices account create --name $AI_SERVICES --resource-group $RG --kind AIServices --sku-name S0 --location $LOCATION --subscription $SUB --yes"

# ===================================
p "# Criando o AI Foundry Hub — a camada de infraestrutura (RBAC, rede, Key Vault)"
p "# Isso leva uns 3-5 minutos..."
wait

pe "APPINSIGHTS_ID=\$(az monitor app-insights component show --app $APP_INSIGHTS --resource-group $RG --subscription $SUB --query id -o tsv)"

pe "az ml workspace create --kind hub --resource-group $RG --name $HUB_NAME --location $LOCATION --subscription $SUB --application-insights \$APPINSIGHTS_ID"

# ===================================
p "# Criando o Projeto dentro do Hub — é onde o time trabalha no dia a dia"
p "# Na prática vocês teriam projetos por caso de uso: triagem, avaliação, etc."
wait

pe "HUB_ID=\$(az ml workspace show --name $HUB_NAME --resource-group $RG --subscription $SUB --query id -o tsv)"

pe "az ml workspace create --kind project --resource-group $RG --name $PROJECT_NAME --hub-id \$HUB_ID --subscription $SUB"

# ===================================
p "# Habilitando Diagnostic Settings — sem isso vocês ficam cegos em produção"
wait

pe "LAW_ID=\$(az monitor log-analytics workspace show --resource-group $RG --workspace-name $LOG_ANALYTICS --subscription $SUB --query id -o tsv)"

pe "HUB_RESOURCE_ID=\$(az ml workspace show --name $HUB_NAME --resource-group $RG --subscription $SUB --query id -o tsv)"

pe "az monitor diagnostic-settings create --name foundry-diagnostics --resource \$HUB_RESOURCE_ID --workspace \$LAW_ID --logs '[{\"categoryGroup\":\"allLogs\",\"enabled\":true}]' --metrics '[{\"category\":\"AllMetrics\",\"enabled\":true}]'"

# ===================================
p "# Agora o deploy do GPT-5 mini — Global Standard, pay-per-token, 80K TPM"
p "# Para produção, vocês migrariam para PTU (Provisioned)"
wait

pe "az cognitiveservices account deployment create --name $AI_SERVICES --resource-group $RG --subscription $SUB --deployment-name gpt-5-mini-global --model-name gpt-5-mini --model-version 2025-08-07 --model-format OpenAI --sku-capacity 80 --sku-name GlobalStandard"

# ===================================
p "# Vamos testar! Chamada REST direto no modelo, cenário de triagem de currículo"
p "# Usamos autenticação via Entra ID (Bearer token) — mais seguro que API keys"
wait

pe "AI_ENDPOINT=\$(az cognitiveservices account show --name $AI_SERVICES --resource-group $RG --subscription $SUB --query properties.endpoint -o tsv)"

pe "TOKEN=\$(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)"

p "# Enviando prompt de triagem..."
wait

pe "curl -s \"\${AI_ENDPOINT}openai/deployments/gpt-5-mini-global/chat/completions?api-version=2024-10-21\" -H \"Content-Type: application/json\" -H \"Authorization: Bearer \$TOKEN\" -d '{\"messages\":[{\"role\":\"system\",\"content\":\"Você é um assistente de RH especializado em triagem de currículos.\"},{\"role\":\"user\",\"content\":\"Analise este perfil: João Silva, 5 anos exp Python/Django, AWS, inglês fluente. A vaga pede: 3+ anos Python, cloud, inglês. Ele é aderente?\"}],\"max_tokens\":300}' | python3 -m json.tool"

# ===================================
p "# Por último, consultando os logs via KQL — é isso que alimenta o monitoramento"
wait

pe "az monitor log-analytics query --workspace \$LAW_ID --analytics-query 'AzureDiagnostics | where ResourceProvider == \"MICROSOFT.COGNITIVESERVICES\" | project TimeGenerated, OperationName, DurationMs, ResultSignature | order by TimeGenerated desc | take 10' --timespan PT1H -o table 2>/dev/null || echo '(Logs podem levar alguns minutos para aparecer)'"

# ===================================
echo ""
p "# Pronto! Agora vamos ver tudo isso no portal: https://ai.azure.com"
echo ""
