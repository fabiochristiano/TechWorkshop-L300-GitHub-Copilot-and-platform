# ZavaStorefront — Azure Infrastructure

## Overview

This folder contains modular Bicep templates for provisioning all Azure resources required by the ZavaStorefront web application, following the requirements in [GitHub Issue #1](../../../issues/1).

## Architecture

```
Resource Group (westus3, dev)
├── Azure Container Registry (Basic)        — stores container images
├── App Service Plan (Linux, B1)             — hosting plan
├── Web App for Containers                   — runs the .NET 8 app
│   └── System-Assigned Managed Identity     — AcrPull RBAC on ACR
├── Log Analytics Workspace                  — centralized logs
├── Application Insights                     — app monitoring & telemetry
└── Azure AI Services (S0)                   — GPT-4 and Phi model deployments
```

## File Structure

| File | Purpose |
|---|---|
| `main.bicep` | Root orchestration template — calls all modules |
| `main.bicepparam` | Parameters file (environment, location, image tag) |
| `modules/acr.bicep` | Azure Container Registry |
| `modules/logAnalytics.bicep` | Log Analytics Workspace |
| `modules/appInsights.bicep` | Application Insights |
| `modules/appService.bicep` | App Service Plan + Web App for Containers |
| `modules/aiFoundry.bicep` | Azure AI Services with GPT-4 and Phi deployments |
| `modules/roleAssignment.bicep` | AcrPull role assignment (Managed Identity → ACR) |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
- Authenticated to Azure (`az login` / `azd auth login`)

## Deployment

### 1. Initialize AZD (first time only)

```bash
azd init
```

### 2. Preview resources before deploying

```bash
azd provision --preview
```

### 3. Deploy infrastructure and application

```bash
azd up
```

This will:
- Create all Azure resources defined in the Bicep templates
- Build the container image via `az acr build` (no local Docker needed)
- Deploy the image to the Web App for Containers

### Building the Container Image (without local Docker)

```bash
az acr build --registry <acr-name> --image zavastorefrontapp:latest .
```

## Security

- **No admin credentials**: ACR admin user is disabled; the Web App pulls images using its system-assigned managed identity with `AcrPull` role
- **HTTPS only**: Web App enforces HTTPS
- **No hardcoded secrets**: All sensitive config flows through App Settings and managed identity

## Cost Considerations (Dev)

| Resource | SKU | Est. Monthly Cost |
|---|---|---|
| Container Registry | Basic | ~$5 |
| App Service Plan | B1 | ~$13 |
| Log Analytics | PerGB2018 (30 day retention) | Pay-per-use |
| Application Insights | Linked to Log Analytics | Pay-per-use |
| AI Services | S0 | Pay-per-use |
