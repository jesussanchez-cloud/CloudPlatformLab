targetScope = 'managementGroup'

@description('Management Group where the reusable policy definition is created.')
param policyDefinitionManagementGroupName string = 'mg-cloudplatformlab'

@description('Management Group where the policy is assigned and inherited by child landing zones.')
param policyAssignmentManagementGroupName string = 'mg-cloudplatformlab-landing-zones'

module policyDefinition 'policy-definitions/management-group.bicep' = {
  name: 'deployManagementGroupPolicyDefinition'
  scope: managementGroup(policyDefinitionManagementGroupName)

  params: {
    policyDefinitionName: 'require-environment-tag'
  }
}

module policyAssignment 'assignments/management-group.bicep' = {
  name: 'deployLandingZonesPolicyAssignment'
  scope: managementGroup(policyAssignmentManagementGroupName)

  params: {
    policyDefinitionId: policyDefinition.outputs.policyDefinitionId
    environment: 'landing-zones'
  }
}

output policyDefinitionId string = policyDefinition.outputs.policyDefinitionId
output policyAssignmentId string = policyAssignment.outputs.policyAssignmentId
