@description('Azure region for observability resources.')
param location string = resourceGroup().location

@description('Environment name used for resource naming and tagging.')
param environment string = 'dev'

var logAnalyticsWorkspaceName = 'log-cloudplatformlab-${environment}'
var applicationInsightsName = 'appi-cloudplatformlab-${environment}'

var tags = {
  Project: 'CloudPlatformLab'
  Environment: environment
  ManagedBy: 'Bicep'
  CostCenter: 'CloudPlatformLab'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags

  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  tags: tags

  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

output applicationInsightsName string = applicationInsights.name
output applicationInsightsId string = applicationInsights.id
