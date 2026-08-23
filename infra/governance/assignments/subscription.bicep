targetScope = 'managementGroup'

@description('Subscription ID to place under the target management group.')
param subscriptionId string

@description('Management Group ID that will become the parent of the subscription.')
param targetManagementGroupId string = 'mg-cloudplatformlab-dev'

resource subscriptionPlacement 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = {
  scope: tenant()
  name: '${targetManagementGroupId}/${subscriptionId}'
}

output subscriptionId string = subscriptionId
output targetManagementGroupId string = targetManagementGroupId
