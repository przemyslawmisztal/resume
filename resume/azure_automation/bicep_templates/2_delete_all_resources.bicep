param resourceGroupName string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope: subscription()
}

module deleteResourceGroup 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'deleteResourceGroup'
  scope: subscription()
  params: {
    name: resourceGroupName
    location: resourceGroup.location
    lock: {
      kind: 'None'
    }
  }
}
