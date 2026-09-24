// A storage account and a blob container, parameterised by environment.
targetScope = 'resourceGroup'

@description('Deployment environment')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

param location string = resourceGroup().location
var accountName = toLower('st${environment}${uniqueString(resourceGroup().id)}')

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: accountName
  location: location
  sku: { name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storage.name}/default/uploads'
  properties: { publicAccess: 'None' }
}

output blobEndpoint string = storage.properties.primaryEndpoints.blob
