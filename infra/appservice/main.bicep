targetScope = 'resourceGroup'

@description('Name of the App Service Plan.')
param appServicePlanName string = 'asp-cloudplatformlab'

@description('Globally unique name of the Products API App Service.')
param webAppName string = 'cloudplatformlab-products-api'

@description('Azure region for the resources.')
param location string = resourceGroup().location

@description('Deployment slot used for development and validation.')
param slotName string = 'dev'

@description('App Service Plan SKU. Default is Standard S1.')
param appServicePlanSku string = 'S1'

var tags = {
  Project: 'CloudPlatformLab'
  Environment: 'Dev'
  ManagedBy: 'Bicep'
  Owner: 'Jesus Sanchez'
  CostCenter: 'CloudPlatformLab'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'app'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: false
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2025-03-01' = {
  name: webAppName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
      ftpsState: 'Disabled'
    }
  }
  tags: tags
}

resource devSlot 'Microsoft.Web/sites/slots@2025-03-01' = {
  parent: webApp
  name: slotName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v8.0'
      ftpsState: 'Disabled'
    }
  }
  tags: tags
}

output appServiceName string = webApp.name
output appServicePlanName string = appServicePlan.name
output devSlotName string = devSlot.name
output appServiceUrl string = '[https://${webApp.properties.defaultHostName}]https://${webApp.properties.defaultHostName}'
output devSlotUrl string = '[https://${webApp.name}-${slotName}.azurewebsites.net]https://${webApp.name}-${slotName}.azurewebsites.net'
