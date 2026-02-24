@description('Name of the Log Analytics Workspace')
param name string

@description('Location for the resource')
param location string

@description('SKU for Log Analytics Workspace')
param skuName string = 'PerGB2018'

@description('Retention period in days')
param retentionInDays int = 30

@description('Tags to apply to the resource')
param tags object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
  }
}

@description('The resource ID of the Log Analytics Workspace')
output id string = logAnalytics.id

@description('The name of the Log Analytics Workspace')
output name string = logAnalytics.name
