# Azure AI Foundry Demo

Demo-magic scripts for an Azure AI Foundry portal walkthrough. Provisions the full stack via Azure CLI with simulated typing for live demos.

## What gets created

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group | `rg-foundry-demo` | Container for all resources |
| RBAC Role Assignment | `Cognitive Services OpenAI Contributor` | Grants current user full permission to deploy and call models via Entra ID |
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

## Demo flow (11 steps)

1. Resource Group
2. **RBAC role assignment** (early, so it propagates during Hub creation)
3. Log Analytics workspace
4. Application Insights
5. AI Services (multi-service account)
6. AI Foundry Hub (~3-5 min)
7. AI Foundry Project
8. Diagnostic Settings
9. GPT-5 mini deployment (Global Standard, 80K TPM)
10. REST test with Entra ID auth (bearer token)
11. KQL log query

Then switch to portal (ai.azure.com) for the walkthrough.

## Why RBAC is step 2

The Hub disables local auth (API keys) by default on connected AI Services. The REST test in step 10 uses Entra ID bearer tokens, which requires the `Cognitive Services OpenAI Contributor` role. RBAC propagation takes 1-5 minutes, so we assign it early (step 2) and let it propagate during the Hub/Project creation time (~5 min).

The role is assigned at Resource Group scope to cover all Cognitive Services resources created in the demo.

## Configuration

The scripts automatically detect the active subscription from your Azure Cloud Shell session (`az account show`). No manual subscription ID needed.

To change other settings, edit the variables at the top of `demo.sh`:
- Resource group name
- Region (default: `eastus2`)
- Hub/Project names

## Tips

- Use `./demo.sh -d` to disable simulated typing (debug mode)
- Adjust `TYPE_SPEED=40` for faster/slower typing
- The REST test includes automatic retry: if the first call fails (RBAC still propagating), it waits 30s and retries with a fresh token
- If re-running after a previous demo, purge soft-deleted AI Services first:
  ```bash
  az cognitiveservices account purge --name ais-demo-lg --resource-group rg-foundry-demo --location eastus2
  ```

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `PermissionDenied: Principal lacks required data action` | RBAC not propagated yet | Wait 2-3 min and retry, or re-run `az role assignment create` |
| `PermissionDenied: Principal does not have access to API/Operation` | Same as above (variant message) | Same fix — RBAC propagation delay |
| `FlagMustBeSetForRestore` | AI Services soft-deleted from previous run | Run `az cognitiveservices account purge --name ais-demo-lg --resource-group rg-foundry-demo --location eastus2` |
| `Deployment not found` | Model deployment not yet ready | Wait 1-2 min after step 9, then retry |