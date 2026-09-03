targetScope = 'resourceGroup'

@description('Azure region for networking resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'Dev'

@description('Name of the existing key vault to connect privately')
param keyVaultName string = 'kv-cloudplatformlab-dev'

var projectName = 'CloudPlatformLab'

var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'Bicep'
  Owner: 'Jesus Sanchez'
  CostCenter: projectName
}

var keyVaultPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-cloudplatformlab-dev'
  location: location
  tags: commonTags

  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }

    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.10.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${keyVaultName}'
  location: location
  tags: commonTags

  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }

    privateLinkServiceConnections: [
      {
        name: 'keyvault-private-link'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: keyVaultPrivateDnsZoneName
  location: 'global'
  tags: commonTags
}

resource keyVaultPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: keyVaultPrivateDnsZone
  name: 'link-vnet-cloudplatformlab-dev'
  location: 'global'

  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: keyVaultPrivateEndpoint
  name: 'default'

  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyvault-private-dns'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZone.id
        }
      }
    ]
  }
}

output virtualNetworkName string = vnet.name
output virtualNetworkId string = vnet.id
output keyVaultPrivateEndpointId string = keyVaultPrivateEndpoint.id
