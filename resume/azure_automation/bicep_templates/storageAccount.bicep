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
        allowBlobPublicAccess: false
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
        accessTier: 'Hot'
    }
}


resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
    parent: storageAccount
    name: 'default'
    properties: {
        cors: {
            corsRules: []
        }
        deleteRetentionPolicy: {
            enabled: false
        }
    }
}

resource staticWebsite 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
    parent: blobService
    name: '$web'
    properties: {
        publicAccess: 'None'
    }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
