# CI/CD: Build & Deploy to Azure App Service

The workflow in `.github/workflows/build-deploy.yml` builds the Docker image, pushes it to Azure Container Registry (ACR), and deploys it to Azure App Service on every push to `main`.

## Prerequisites

1. **Deploy infrastructure first** — run the Bicep templates in `infra/` so the resource group, ACR, and App Service exist.
2. **Create a service principal** with **Contributor** role on the resource group and **AcrPush** role on the ACR.

## Required GitHub Secrets

Set these under **Settings → Secrets and variables → Actions → Secrets**:

| Secret              | Description                                                    |
|---------------------|----------------------------------------------------------------|
| `AZURE_CREDENTIALS` | Full JSON output from `az ad sp create-for-rbac --json-auth`   |

To create the service principal and get the JSON:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --json-auth
```

Then assign **AcrPush** on the ACR:

```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

## Required GitHub Variables

Set these under **Settings → Secrets and variables → Actions → Variables**:

| Variable                         | Description                                                        | Example                        |
|----------------------------------|--------------------------------------------------------------------|--------------------------------|
| `AZURE_CONTAINER_REGISTRY_NAME`  | Name of the Azure Container Registry (alphanumeric, no `.azurecr.io`) | `acrzavastore7x2k`            |
| `AZURE_APP_SERVICE_NAME`         | Name of the Azure App Service                                     | `app-zavastore-7x2k`          |

> Both values are emitted as Bicep outputs (`acrName` and `webAppName`) after deploying the infrastructure.
