targetScope = 'tenant'

var rootManagementGroupName = 'mg-cloudplatformlab'
var platformManagementGroupName = 'mg-cloudplatformlab-platform'
var connectivityManagementGroupName = 'mg-cloudplatformlab-connectivity'
var managementManagementGroupName = 'mg-cloudplatformlab-management'
var landingZonesManagementGroupName = 'mg-cloudplatformlab-landing-zones'
var devManagementGroupName = 'mg-cloudplatformlab-dev'
var prodManagementGroupName = 'mg-cloudplatformlab-prod'

resource cloudPlatformLab 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  name: rootManagementGroupName
  properties: {
    displayName: 'CloudPlatformLab'
  }
}

resource platform 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
  name: platformManagementGroupName
  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: cloudPlatformLab.id
      }
    }
  }
}

resource connectivity 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
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
  name: landingZonesManagementGroupName
  properties: {
    displayName: 'Landing Zones'
    details: {
      parent: {
        id: cloudPlatformLab.id
      }
    }
  }
}

resource dev 'Microsoft.Management/managementGroups@2024-02-01-preview' = {
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

output cloudPlatformLabManagementGroupId string = cloudPlatformLab.id
output platformManagementGroupId string = platform.id
output connectivityManagementGroupId string = connectivity.id
output managementManagementGroupId string = management.id
output landingZonesManagementGroupId string = landingZones.id
output devManagementGroupId string = dev.id
output prodManagementGroupId string = prod.id
