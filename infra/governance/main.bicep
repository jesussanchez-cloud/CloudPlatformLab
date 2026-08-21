targetScope = 'subscription'

@description('Resource group where the policy will be assigned.')
param resourceGroupName string = 'rg-cloudplatformlab-dev'

@description('Environment name used for naming.')
param environment string = 'dev'

var policyDefinitionName = 'require-environment-tag'

resource requireEnvironmentTagPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: policyDefinitionName

  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Audit resources missing the Environment tag'
    description: 'Audits Azure resources that do not contain the Environment tag.'

    metadata: {
      category: 'CloudPlatformLab Governance'
      version: '1.0.0'
    }

    policyRule: {
      if: {
        field: 'tags[Environment]'
        exists: 'false'
      }
      then: {
        effect: 'audit'
      }
    }
  }
}

module resourceGroupPolicyAssignment 'assignments/resource-group.bicep' = {
  name: 'deployEnvironmentTagResourceGroupAssignment'
  scope: resourceGroup(resourceGroupName)

  params: {
    policyDefinitionId: requireEnvironmentTagPolicy.id
    environment: environment
  }
}

output policyDefinitionName string = requireEnvironmentTagPolicy.name
output policyDefinitionId string = requireEnvironmentTagPolicy.id
output resourceGroupPolicyAssignmentName string = resourceGroupPolicyAssignment.outputs.policyAssignmentName
output resourceGroupPolicyAssignmentId string = resourceGroupPolicyAssignment.outputs.policyAssignmentId
