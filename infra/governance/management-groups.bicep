targetScope = 'managementGroup'

@description('Subscription ID to place in the Dev landing zone.')
param subscriptionId string

var platformManagementGroupName = 'mg-cloudplatformlab-platform'
var connectivityManagementGroupName = 'mg-cloudplatformlab-connectivity'
var managementManagementGroupName = 'mg-cloudplatformlab-management'
var landingZonesManagementGroupName = 'mg-cloudplatformlab-landing-zones'
var devManagementGroupName = 'mg-cloudplatformlab-dev'
var prodManagementGroupName = 'mg-cloudplatformlab-prod'

resource currentManagementGroup 'Microsoft.Management/managementGroups@2024-02-01-preview' existing = {
  scope: tenant()
  name: managementGroup().name
}

resource platform 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  scope: tenant()
  name: platformManagementGroupName

  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: currentManagementGroup.id
      }
    }
  }
}

resource connectivity 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  scope: tenant()
  name: connectivityManagementGroupName

  properties: {
    displayName: 'Connectivity'
    details: {
      parent: {
        id: platform.id
      }
    }
  }
}

resource management 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  scope: tenant()
  name: managementManagementGroupName

  properties: {
    displayName: 'Management'
    details: {
      parent: {
        id: platform.id
      }
    }
  }
}

resource landingZones 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  scope: tenant()
  name: landingZonesManagementGroupName

  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: currentManagementGroup.id
      }
    }
  }
}

resource dev 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  scope: tenant()
  name: devManagementGroupName

  properties: {
    displayName: 'Dev'
    details: {
      parent: {
        id: landingZones.id
      }
    }
  }
}

resource prod 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  scope: tenant()
  name: prodManagementGroupName

  properties: {
    displayName: 'Prod'
    details: {
      parent: {
        id: landingZones.id
      }
    }
  }
}

module subscriptionPlacement 'assignments/subscription.bicep' = {
  name: 'placeSubscriptionInDevLandingZone'

  params: {
    subscriptionId: subscriptionId
    targetManagementGroupId: devManagementGroupName
  }

  dependsOn: [
    dev
  ]
}

output platformManagementGroupId string = platform.id
output connectivityManagementGroupId string = connectivity.id
output managementManagementGroupId string = management.id
output landingZonesManagementGroupId string = landingZones.id
output devManagementGroupId string = dev.id
output prodManagementGroupId string = prod.id
output placedSubscriptionId string = subscriptionPlacement.outputs.subscriptionId
