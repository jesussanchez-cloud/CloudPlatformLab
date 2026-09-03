@description('Azure region for observability resources.')
param location string = resourceGroup().location

@description('Environment name used for resource naming and tagging.')
param environment string = 'dev'

@description('Email address used for Azure Monitor alert notifications.')
param alertEmail string

var logAnalyticsWorkspaceName = 'log-cloudplatformlab-${environment}'
var applicationInsightsName = 'appi-cloudplatformlab-${environment}'
var actionGroupName = 'ag-cloudplatformlab-${environment}'
var failedRequestsAlertName = 'alert-failed-requests-${environment}'

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

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags

  properties: {
    groupShortName: 'CPLDev'
    enabled: true

    emailReceivers: [
      {
        name: 'CloudPlatformLabEmail'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]

    smsReceivers: []
    webhookReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
  }
}

resource failedRequestsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: failedRequestsAlertName
  location: 'global'
  tags: tags

  properties: {
    description: 'Alerts when failed application requests are detected.'
    severity: 2
    enabled: true
    autoMitigate: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'

    scopes: [
      applicationInsights.id
    ]

    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'

      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'FailedRequests'
          metricName: 'requests/failed'
          metricNamespace: 'microsoft.insights/components'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Count'
          skipMetricValidation: false
        }
      ]
    }

    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

output applicationInsightsName string = applicationInsights.name
output applicationInsightsId string = applicationInsights.id

output actionGroupName string = actionGroup.name
output actionGroupId string = actionGroup.id

output failedRequestsAlertName string = failedRequestsAlert.name
output failedRequestsAlertId string = failedRequestsAlert.id
