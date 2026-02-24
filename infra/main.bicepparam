using 'main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westus3')
param dockerImageAndTag = 'zavastorefrontapp:latest'
param tags = {}
