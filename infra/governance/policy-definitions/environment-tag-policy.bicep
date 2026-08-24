targetScope = 'managementGroup'

@description('Name of the custom policy definition.')
param policyDefinitionName string = 'require-environment-tag'

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

output policyDefinitionName string = requireEnvironmentTagPolicy.name
output policyDefinitionId string = requireEnvironmentTagPolicy.id
