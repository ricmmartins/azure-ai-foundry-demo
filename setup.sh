#!/bin/bash

########################
# Setup: Preparar ambiente para a demo
# Rodar ANTES da demo (no Cloud Shell)
########################

echo "=== Baixando demo-magic ==="
curl -s https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh -o demo-magic.sh
chmod +x demo-magic.sh

echo "=== Verificando pv (simulated typing) ==="
if ! command -v pv &> /dev/null; then
    echo "pv não encontrado. Instalando..."
    sudo apt-get install -y pv 2>/dev/null || echo "Cloud Shell já deve ter pv."
else
    echo "pv OK"
fi

echo "=== Instalando extensões Azure CLI ==="
az extension add --name application-insights --yes 2>/dev/null
az extension add --name ml --yes 2>/dev/null

echo "=== Verificando subscription ==="
az account set --subscription "313dd062-1c1c-428a-afc4-4e271378679f"
az account show --query "{name:name, id:id}" -o table

echo ""
echo "=== Setup pronto! ==="
echo "Para rodar a demo:"
echo "  ./demo.sh"
echo ""
echo "Dica: use -d para debug (sem simulated typing)"
echo "  ./demo.sh -d"
