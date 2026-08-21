targetScope = 'managementGroup'

@description('ID of the policy definition to assign.')
param policyDefinitionId string

@description('Environment name used for naming.')
param environment string = 'dev'

var policyAssignmentName = 'require-environment-tag-${environment}'

resource environmentTagAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: policyAssignmentName

  properties: {
    displayName: 'Audit missing Environment tag - ${environment}'
    description: 'Audits resources in this management group scope that do not contain the Environment tag.'
    policyDefinitionId: policyDefinitionId
    enforcementMode: 'Default'

    nonComplianceMessages: [
      {
        message: 'Resources should contain the Environment tag.'
      }
    ]

    metadata: {
      assignedBy: 'CloudPlatformLab'
      environment: environment
      scopeType: 'ManagementGroup'
    }
  }
}

output policyAssignmentName string = environmentTagAssignment.name
output policyAssignmentId string = environmentTagAssignment.id
