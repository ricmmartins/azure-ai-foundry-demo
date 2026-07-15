# Azure AI Foundry Demo

Demo-magic scripts for an Azure AI Foundry portal walkthrough. Provisions the full stack via Azure CLI with simulated typing for live demos.

## What gets created

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group | `rg-foundry-demo` | Container for all resources |
| Log Analytics | `law-foundry-demo` | Logs and metrics |
| Application Insights | `appi-foundry-demo` | Request tracing, latency, errors |
| AI Foundry Hub | `hub-demo-lg` | Infrastructure layer (RBAC, networking) |
| AI Foundry Project | `demo-lg-hrtech` | Workspace for deployments and playground |
| GPT-4o Deployment | `gpt-4o-global` | Global Standard, 80K TPM |
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

Edit the variables at the top of `demo.sh` to change:
- Subscription ID
- Resource group name
- Region (default: `eastus2`)
- Hub/Project names

## Tips

- Use `./demo.sh -d` to disable simulated typing (debug mode)
- Adjust `TYPE_SPEED=40` for faster/slower typing
- The test prompt uses an HR scenario (resume screening)
