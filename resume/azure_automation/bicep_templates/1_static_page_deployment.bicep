param resourceGroupName string = 'crc_resource_group'
param storageAccountSku string = 'Standard_LRS'
param location string = 'eastus'

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: deployment().location
}

var generatedStorageAccountName = 'storacc${uniqueString(resourceGroup.id)}'

module storageAccountModule 'storageAccount.bicep' = {
  name: 'storageAccountDeployment'
  scope: resourceGroup
  params: {
    storageAccountName: generatedStorageAccountName
    sku: storageAccountSku
    location: location
  }
}

output storageAccountId string = storageAccountModule.outputs.storageAccountId
output storageAccountName string = storageAccountModule.outputs.storageAccountName
