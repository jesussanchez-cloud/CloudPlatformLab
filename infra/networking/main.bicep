targetScope = 'resourceGroup'

@description('Azure region for networking resources')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'Dev'

var projectName = 'CloudPlatformLab'

var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'Bicep'
  Owner: 'Jesus Sanchez'
  CostCenter: projectName
}

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

output virtualNetworkName string = vnet.name
output virtualNetworkId string = vnet.id
