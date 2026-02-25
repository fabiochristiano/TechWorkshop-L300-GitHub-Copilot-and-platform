targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string

@description('Base name for resource naming')
param baseName string = 'zavastore'

@description('Docker image name and tag')
param dockerImageAndTag string = 'zavastorefrontapp:latest'

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName))

// ============================================================================
// Modules
// ============================================================================

// Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: 'log-${baseName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    name: 'appi-${baseName}-${resourceToken}'
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// Azure Container Registry (name must be alphanumeric only, 5-50 chars)
module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: 'acr${baseName}${resourceToken}'
    location: location
    skuName: 'Basic'
    tags: tags
  }
}

// App Service (Plan + Web App for Containers)
module appService 'modules/appService.bicep' = {
  name: 'appService'
  params: {
    appServicePlanName: 'asp-${baseName}-${resourceToken}'
    webAppName: 'app-${baseName}-${resourceToken}'
    location: location
    skuName: 'B1'
    acrLoginServer: acr.outputs.loginServer
    dockerImageAndTag: dockerImageAndTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// AcrPull Role Assignment — Web App managed identity → ACR
module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: appService.outputs.principalId
    acrId: acr.outputs.id
    principalType: 'ServicePrincipal'
  }
}

// AI Services (GPT-4 and Phi models)
module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'aiFoundry'
  params: {
    name: 'ai-${baseName}-${resourceToken}'
    location: location
    skuName: 'S0'
    tags: tags
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The default hostname of the deployed Web App')
output webAppUrl string = 'https://${appService.outputs.defaultHostName}'

@description('The ACR login server')
output acrLoginServer string = acr.outputs.loginServer

@description('The name of the Web App')
output webAppName string = appService.outputs.name

@description('The name of the ACR')
output acrName string = acr.outputs.name

@description('The AI Services endpoint')
output aiServicesEndpoint string = aiFoundry.outputs.endpoint

@description('The Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString
