@description('Name of the Azure Container Registry')
param name string

@description('Location for the resource')
param location string

@description('SKU for the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false // Use RBAC instead of admin credentials
    publicNetworkAccess: 'Enabled'
  }
}

@description('The resource ID of the Container Registry')
output id string = acr.id

@description('The login server URL of the Container Registry')
output loginServer string = acr.properties.loginServer

@description('The name of the Container Registry')
output name string = acr.name
