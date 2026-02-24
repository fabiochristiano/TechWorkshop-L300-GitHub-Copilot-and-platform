@description('Name of the AI Services account')
param name string

@description('Location for the resource')
param location string

@description('SKU for the AI Services account')
param skuName string = 'S0'

@description('Tags to apply to the resource')
param tags object = {}

// Azure AI Services account (supports GPT-4, Phi, and other models)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

// GPT-4o model deployment
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}

// Phi model deployment
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'Phi-4'
  dependsOn: [
    gpt4oDeployment
  ]
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '2'
    }
  }
}

@description('The resource ID of the AI Services account')
output id string = aiServices.id

@description('The endpoint of the AI Services account')
output endpoint string = aiServices.properties.endpoint

@description('The name of the AI Services account')
output name string = aiServices.name
