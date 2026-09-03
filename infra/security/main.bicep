targetScope = 'resourceGroup'

@description('Azure region for security resources.')
param location string = resourceGroup().location

@description('Environment name used for resource naming and tagging.')
param environment string = 'dev'

var keyVaultName = 'kv-cloudplatformlab-${environment}'

var tags = {
  Project: 'CloudPlatformLab'
  Environment: environment
  ManagedBy: 'Bicep'
  CostCenter: 'CloudPlatformLab'
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags

  properties: {
    tenantId: subscription().tenantId

    sku: {
      family: 'A'
      name: 'standard'
    }

    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true

    publicNetworkAccess: 'Enabled'

    accessPolicies: []
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
