@description('Principal ID of the identity to assign the role to')
param principalId string

@description('Resource ID of the Container Registry')
param acrId string

@description('The principal type')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string = 'ServicePrincipal'

// AcrPull built-in role definition ID
// See: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

// Reference the existing ACR to scope the role assignment
resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: last(split(acrId, '/'))
}
