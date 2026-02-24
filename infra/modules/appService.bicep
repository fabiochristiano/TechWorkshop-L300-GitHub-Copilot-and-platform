@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the Web App')
param webAppName string

@description('Location for the resources')
param location string

@description('SKU for the App Service Plan')
param skuName string = 'B1'

@description('ACR login server URL (e.g., myregistry.azurecr.io)')
param acrLoginServer string

@description('Docker image name and tag (e.g., zavastorefrontapp:latest)')
param dockerImageAndTag string = 'zavastorefrontapp:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Tags to apply to the resources')
param tags object = {}

// App Service Plan - Linux
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// Web App for Containers
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  tags: union(tags, {
    'azd-service-name': 'web'
  })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageAndTag}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
      ]
    }
  }
}

@description('The resource ID of the Web App')
output id string = webApp.id

@description('The default hostname of the Web App')
output defaultHostName string = webApp.properties.defaultHostName

@description('The principal ID of the Web App managed identity')
output principalId string = webApp.identity.principalId

@description('The name of the Web App')
output name string = webApp.name

@description('The resource ID of the App Service Plan')
output appServicePlanId string = appServicePlan.id
