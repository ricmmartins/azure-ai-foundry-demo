#!/bin/bash

########################
# Setup: Preparar ambiente para a demo
# Rodar ANTES da demo (no Cloud Shell)
########################

echo "=== Instalando pv (simulated typing) ==="
if ! command -v pv &> /dev/null; then
    echo "pv não encontrado. Tentando instalar..."
    # Azure Cloud Shell usa Azure Linux (tdnf)
    if command -v tdnf &> /dev/null; then
        sudo tdnf install -y pv 2>/dev/null
    # Fallback Debian/Ubuntu
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq pv 2>/dev/null
    fi

    if command -v pv &> /dev/null; then
        echo "✅ pv instalado!"
    else
        echo "⚠ pv não pôde ser instalado. A demo roda sem simulated typing."
    fi
else
    echo "✅ pv já instalado"
fi

echo ""
echo "=== Baixando demo-magic ==="
curl -s https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh -o demo-magic.sh
chmod +x demo-magic.sh
echo "✅ demo-magic.sh baixado"

echo ""
echo "=== Instalando extensões Azure CLI ==="
az extension add --name application-insights --yes --only-show-errors 2>/dev/null
az extension add --name ml --yes --only-show-errors 2>/dev/null
echo "✅ Extensões instaladas"

echo ""
echo "=== Verificando subscription ==="
az account set --subscription "313dd062-1c1c-428a-afc4-4e271378679f"
az account show --query "{name:name, id:id}" -o table

echo ""
echo "================================="
echo "  Setup pronto!"
echo "  ./demo.sh        (rodar demo)"
echo "  ./demo.sh -d     (sem typing)"
echo "================================="
