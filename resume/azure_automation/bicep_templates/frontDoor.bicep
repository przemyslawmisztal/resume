@description('Storage account name')
param storageAccountName string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: '${storageAccountName}-fd-profile'
  location: 'Global'
  sku: {
      name: 'Standard_AzureFrontDoor'
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  name: '${storageAccountName}-endpoint'
  parent: frontDoorProfile
  location: 'Global'
  properties: {
      enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  name: '${storageAccountName}-origin-group'
  parent: frontDoorProfile
  properties: {
      loadBalancingSettings: {
          sampleSize: 4
          successfulSamplesRequired: 3
          additionalLatencyInMilliseconds: 50
      }
      healthProbeSettings: {
          probePath: '/'
          probeRequestType: 'HEAD'
          probeProtocol: 'Https'
          probeIntervalInSeconds: 100
      }
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  name: '${storageAccountName}-origin'
  parent: frontDoorOriginGroup
  properties: {
      hostName: '${storageAccountName}.z13.web.${environment().suffixes.storage}'
      httpPort: 80
      httpsPort: 443
      priority: 1
      weight: 1000
      enabledState: 'Enabled'
      enforceCertificateNameCheck: true
      originHostHeader: '${storageAccountName}.z13.web.${environment().suffixes.storage}'
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  name: '${storageAccountName}-route'
  parent: frontDoorEndpoint
  dependsOn: [
      frontDoorOrigin
  ]
  properties: {
      originGroup: {
          id: frontDoorOriginGroup.id
      }
      supportedProtocols: [
          'Http'
          'Https'
      ]
      patternsToMatch: [
          '/*'
      ]
      linkToDefaultDomain: 'Enabled'
      httpsRedirect: 'Enabled'
  }
}

output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
