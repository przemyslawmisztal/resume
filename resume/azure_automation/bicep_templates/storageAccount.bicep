@description('Storage account name')
param storageAccountName string

@description('Location for the storage account')
param location string = resourceGroup().location

@description('Storage account SKU')
@allowed([
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Standard_ZRS'
    'Premium_LRS'
])
param sku string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: sku
    }
    kind: 'StorageV2'
    properties: {
        defaultToOAuthAuthentication: false
        allowCrossTenantReplication: true
        minimumTlsVersion: 'TLS1_2'
        allowBlobPublicAccess: true
        allowSharedKeyAccess: true
        networkAcls: {
            bypass: 'AzureServices'
            virtualNetworkRules: []
            ipRules: []
            defaultAction: 'Allow'
        }
        supportsHttpsTrafficOnly: true
        encryption: {
            services: {
                file: {
                    keyType: 'Account'
                    enabled: true
                }
                blob: {
                    keyType: 'Account'
                    enabled: true
                }
            }
            keySource: 'Microsoft.Storage'
        }
        accessTier: 'Cool'
    }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name


