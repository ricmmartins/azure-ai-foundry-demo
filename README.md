# Azure AI Foundry Demo

Demo-magic scripts for an Azure AI Foundry portal walkthrough. Provisions the full stack via Azure CLI with simulated typing for live demos.

## What gets created

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group | `rg-foundry-demo` | Container for all resources |
| Log Analytics | `law-foundry-demo` | Logs and metrics |
| Application Insights | `appi-foundry-demo` | Request tracing, latency, errors |
| AI Services | `ais-demo-lg` | Hosts model deployments (GPT-5 mini, etc.) |
| AI Foundry Hub | `hub-demo-lg` | Infrastructure layer (RBAC, networking) |
| AI Foundry Project | `demo-lg-hrtech` | Workspace for deployments and playground |
| GPT-5 mini Deployment | `gpt-5-mini-global` | Global Standard, 80K TPM |
| Diagnostic Settings | `foundry-diagnostics` | All logs + metrics to Log Analytics |

## Quick start

```bash
# In Azure Cloud Shell (bash):
git clone https://github.com/ricmmartins/azure-ai-foundry-demo.git
cd azure-ai-foundry-demo
chmod +x setup.sh demo.sh teardown.sh

# 1. Setup (once, before the demo)
./setup.sh

# 2. Run the demo (ENTER to advance each step)
./demo.sh

# 3. Cleanup (after the demo)
./teardown.sh
```

## How it works

Uses [demo-magic](https://github.com/paxtonhare/demo-magic) to simulate typing Azure CLI commands during a live presentation. Each step pauses and waits for ENTER, giving you time to explain what's happening.

## Demo flow

1. **Slides** (deck "Do Zero à Produção")
2. **Cloud Shell** - run `./demo.sh` (provisions everything live via CLI)
3. **Portal walkthrough** - switch to ai.azure.com to explore Playground, Model Catalog, Metrics

## Configuration

The scripts automatically detect the active subscription from your Azure Cloud Shell session (`az account show`). No manual subscription ID needed.

To change other settings, edit the variables at the top of `demo.sh`:
- Resource group name
- Region (default: `eastus2`)
- Hub/Project names

## Tips

- Use `./demo.sh -d` to disable simulated typing (debug mode)
- Adjust `TYPE_SPEED=40` for faster/slower typing
- The REST test uses **Entra ID (Bearer token)** auth, not API keys. This works even when the Hub disables local auth (default behavior)
- If re-running after a previous demo, purge soft-deleted AI Services first:
  ```bash
  az cognitiveservices account purge --name ais-demo-lg --resource-group rg-foundry-demo --location eastus2
  ```
