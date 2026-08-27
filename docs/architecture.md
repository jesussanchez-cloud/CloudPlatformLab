# Architecture

CloudPlatformLab is a small Azure platform-engineering project built around a deliberately simple ASP.NET Core workload.

The application exists primarily to exercise the platform. The architectural focus is Infrastructure as Code, CI/CD, identity, security, networking, observability, governance and cost control.

---

## Architecture Overview

The Dev platform is split into independently deployable infrastructure domains:

    Azure DevOps
         |
    Build Application
         |
         +-----------+-----------+-----------+-----------+
         |           |           |           |           |
         v           v           v           v           v
    App Service  Networking  Observability Security  Governance
         |           |           |           |           |
         +-----------+-----------+-----------+-----------+
                                 |
                                 v
                               Azure

Each infrastructure path follows the same deployment control:

    Validate
       |
    Readiness
       |
    What-If
       |
    Manual Approval
       |
    Deploy

Networking, observability, security and governance are deployed through Azure DevOps.

App Service is defined and validated in Bicep but is not currently provisioned because the subscription does not provide sufficient quota for the selected SKU. Infrastructure domains remain independent so this constraint does not block unrelated platform work.

---

## Application Layer

The workload is an ASP.NET Core .NET 8 application containing a simple Products API.

Current application capabilities include:

- ASP.NET Core .NET 8
- Products API
- Azure Key Vault configuration integration
- `DefaultAzureCredential`
- `/health/keyvault` integration verification
- Application Insights SDK
- real request telemetry
- failed-request telemetry used by Azure Monitor
- App Service and deployment-slot architecture defined in Bicep

During local development, the application authenticates through the developer's Azure identity:

    ASP.NET Core
         |
    DefaultAzureCredential
         |
    Microsoft Entra ID
         |
    Azure RBAC
         |
    Azure Key Vault

The `/health/keyvault` endpoint verifies that configuration has been loaded without returning the secret value.

Application Insights receives telemetry from the running application, allowing the workload to exercise both the security and observability layers.

Environment-specific local values are stored outside source control using .NET User Secrets.

When the application is hosted in Azure, the intended authentication path is:

    App Service
         |
    System-Assigned Managed Identity
         |
    Microsoft Entra ID
         |
    Azure RBAC
         |
    Azure Key Vault

This preserves the same application authentication model without introducing application-managed credentials.

---

## Infrastructure as Code

Azure infrastructure is primarily defined in Bicep and separated by platform concern.

    infra/
    +-- appservice/
    |   +-- main.bicep
    |
    +-- networking/
    |   +-- main.bicep
    |
    +-- observability/
    |   +-- main.bicep
    |
    +-- security/
    |   +-- main.bicep
    |
    +-- governance/
        +-- management-group-hierarchy.bicep
        +-- landing-zone-policy.bicep
        |
        +-- policy-definitions/
        |   +-- environment-tag-policy.bicep
        |
        +-- assignments/
            +-- environment-tag-assignment.bicep

Most Dev workload resources are deployed to:

    rg-cloudplatformlab-dev
    UK South

Separating infrastructure domains keeps their dependencies, permissions, validation and deployment lifecycle isolated while maintaining a single repository and CI/CD workflow.

---

## Networking Architecture

The Dev network is:

    vnet-cloudplatformlab-dev
    10.10.0.0/16
    |
    +-- snet-app
    |   10.10.1.0/24
    |
    +-- snet-private-endpoints
        10.10.2.0/24

`snet-app` is reserved for application-side VNet integration.

`snet-private-endpoints` is dedicated to Azure Private Endpoints.

### Key Vault Private Connectivity

Key Vault private connectivity is implemented through Azure Private Link.

    VNet-connected workload
            |
            | DNS query
            v
    kv-cloudplatformlab-dev.vault.azure.net
            |
            v
    privatelink.vaultcore.azure.net
            |
            v
        10.10.2.4
            |
            v
    Private Endpoint
    pe-kv-cloudplatformlab-dev
            |
            v
    Azure Key Vault
    kv-cloudplatformlab-dev

Implemented resources include:

- Key Vault Private Endpoint
- Private Endpoint NIC with `10.10.2.4`
- Private DNS zone `privatelink.vaultcore.azure.net`
- VNet link `link-vnet-cloudplatformlab-dev`
- Private DNS Zone Group
- Key Vault A record resolving to `10.10.2.4`

The Private DNS zone is linked to `vnet-cloudplatformlab-dev`, allowing workloads using the VNet's Azure DNS path to resolve the Key Vault private-link hostname to the Private Endpoint address.

A public Cloud Shell DNS lookup was captured as a baseline. Because normal Cloud Shell is outside the VNet, it follows the public DNS path rather than resolving the vault to `10.10.2.4`.

Runtime DNS resolution from a VNet-connected workload has not yet been captured because the subscription currently prevents deployment of the intended App Service workload and economical test VM capacity was unavailable. The deployed Private Endpoint, DNS zone, VNet link and A record are therefore validated as infrastructure, while runtime private-path validation remains separate.

Public network access to Key Vault remains enabled so existing local application integration continues to function until an Azure-hosted workload can consume the private path.

---

## Security Architecture

The Dev security foundation is centred on Azure identity, RBAC and Key Vault.

    kv-cloudplatformlab-dev
    |
    +-- Azure RBAC authorization
    +-- Soft delete
    +-- 90-day recovery period
    +-- Purge protection
    +-- Private Endpoint
    +-- Application configuration
    +-- AlertEmail

Key Vault uses Azure RBAC rather than legacy vault access policies.

Application access uses `DefaultAzureCredential`, Microsoft Entra ID and scoped Azure RBAC.

Azure DevOps also uses identity-based Key Vault access. The service connection identity has the `Key Vault Secrets User` role required to retrieve the `AlertEmail` configuration value used by the observability deployment.

No application secret values, notification email addresses or long-lived Azure client secrets are committed to the repository.

---

## Observability Architecture

The observability path is:

    ASP.NET Core Application
              |
    Application Insights SDK
              |
              v
    appi-cloudplatformlab-dev
              |
              +----------------------+
              |                      |
              v                      v
    Log Analytics             Failed Request Metric
    log-cloudplatformlab-dev          |
              |                       v
        30-day retention       Azure Monitor Alert
                                      |
                                      v
                              ag-cloudplatformlab-dev
                                      |
                                      v
                              Email Notification

Application Insights is workspace-based and uses `log-cloudplatformlab-dev` as its Log Analytics workspace.

Real application requests have been received and inspected in Application Insights.

### Alerting

`alert-failed-requests-dev` monitors failed Application Insights requests.

When the threshold is exceeded:

    Failed Application Request
              |
    Application Insights
              |
    Azure Monitor Metric Alert
              |
    Action Group
              |
    Email Notification

This path has been tested end-to-end by deliberately generating failed requests and confirming both the fired alert and delivered email notification.

The Action Group email address is not hardcoded in Bicep.

Instead:

    Azure Key Vault
         |
    AlertEmail
         |
    Azure DevOps WIF Identity
         |
    Observability Pipeline
         |
    Secure Bicep Parameter
         |
    Azure Monitor Action Group

The pipeline retrieves the value at deployment time through Azure RBAC and does not intentionally print it to pipeline logs.

The Log Analytics workspace uses 30-day retention to provide useful Dev telemetry while limiting unnecessary storage cost.

---

## Governance Architecture

CloudPlatformLab implements a Management Group landing-zone hierarchy:

    Tenant Root Group
    |
    +-- CloudPlatformLab
        |
        +-- Platform
        |   |
        |   +-- Connectivity
        |   +-- Management
        |
        +-- Landing Zones
            |
            +-- Dev
            |   |
            |   +-- CloudPlatformLab subscription
            |
            +-- Prod

The structure separates shared platform concerns from workload landing zones and provides governance scope above individual subscriptions.

### Azure Policy

A custom Azure Policy audits resources for the required `Environment` tag.

The reusable policy definition is separated from its assignment.

The policy is assigned once at the `Landing Zones` Management Group:

    Landing Zones
    |
    +-- Environment tag policy
    |
    +-- Dev
        |
        +-- CloudPlatformLab subscription
            |
            +-- rg-cloudplatformlab-dev
                |
                +-- Resources

The assignment is inherited by the Dev Management Group, subscription and workload resources.

The previous direct resource-group assignment was removed after Management Group inheritance was confirmed.

### Compliance

The validated inherited policy evaluation reported:

    Resources evaluated: 8
    Compliant:            6
    Non-compliant:        2
    Compliance:           75%

The non-compliant results include Azure-created supporting resources such as Application Insights smart-detection and Network Watcher resources.

They were investigated rather than modified solely to produce a 100% compliance score.

The intended governance response is:

    Policy Finding
         |
    Investigate
         |
         +--> Remediate
         +--> Refine scope
         +--> Justified exemption

### Subscription Placement

Subscription placement is treated as a privileged bootstrap operation rather than part of the normal CI/CD identity.

Moving subscriptions between Management Groups requires broader access than repeatable policy and hierarchy deployment. Keeping that operation separate avoids granting unnecessary permanent privilege to the standard Azure DevOps service connection.

---

## CI/CD Architecture

Azure DevOps provides CI/CD.

Changes are developed in feature branches and merged into `Dev` through pull requests. `Dev` is the deployment source for the Dev environment.

The pipeline is split into a root orchestration file and reusable infrastructure templates:

    azure-pipelines.yml
    |
    +-- pipelines/templates/appservice.yml
    +-- pipelines/templates/networking.yml
    +-- pipelines/templates/observability.yml
    +-- pipelines/templates/security.yml
    +-- pipelines/templates/governance.yml

The flow is:

    Feature Branch
          |
    Pull Request
          |
    Dev
          |
    Build
          |
          +-----------+-----------+-----------+-----------+
          |           |           |           |           |
     App Service  Networking  Observability Security  Governance
          |           |           |           |           |
       Validate    Validate    Validate    Validate    Validate
          |           |           |           |           |
      Readiness   Readiness   Readiness   Readiness   Readiness
          |           |           |           |           |
       What-If     What-If     What-If     What-If     What-If
          |           |           |           |           |
      Approval    Approval    Approval    Approval    Approval
          |           |           |           |           |
       Deploy      Deploy      Deploy      Deploy      Deploy

Infrastructure deployments target:

    env-cloudplatformlab-dev

The Azure DevOps Environment provides the manual approval control before deployment.

Independent deployment paths prevent an environmental constraint in one domain from blocking unrelated platform changes.

---

## Deployment Safeguards

Every infrastructure path uses:

1. Bicep validation
2. readiness checks
3. Bicep What-If
4. manual approval
5. deployment

Readiness checks currently include:

| Domain | Checks |
|---|---|
| App Service | `Microsoft.Web`, resource group, configured SKU quota |
| Networking | `Microsoft.Network`, resource group |
| Observability | `Microsoft.OperationalInsights`, `Microsoft.Insights`, resource group |
| Security | `Microsoft.KeyVault`, resource group |
| Governance | `Microsoft.Authorization`, `Microsoft.PolicyInsights`, `Microsoft.Management`, Management Group access |

Bicep validation determines whether the infrastructure definition is valid.

Readiness checks detect subscription, permission and environmental conditions that may prevent valid IaC from being deployed.

Keeping these concerns separate produces clearer pipeline failures.

---

## Identity and Authentication

### Azure DevOps

The service connection is:

    sc-cloudplatformlab-dev

Authentication uses Workload Identity Federation:

    Azure DevOps
         |
    Workload Identity Federation
         |
    Microsoft Entra ID
         |
    Azure RBAC
         |
    Azure Resources

This avoids long-lived pipeline client secrets.

### Application

Local development:

    Application
         |
    DefaultAzureCredential
         |
    Developer Identity
         |
    Microsoft Entra ID
         |
    Azure RBAC
         |
    Key Vault

Azure-hosted target:

    App Service
         |
    Managed Identity
         |
    Microsoft Entra ID
         |
    Azure RBAC
         |
    Key Vault

The application therefore uses an identity-first authentication model across environments.

---

## Resource Organisation

The main Dev resource group is:

    rg-cloudplatformlab-dev

Its subscription is organised under:

    CloudPlatformLab
    |
    +-- Landing Zones
        |
        +-- Dev
            |
            +-- CloudPlatformLab subscription

Standard project tags include:

    Project      = CloudPlatformLab
    Environment  = Dev
    ManagedBy    = Bicep
    CostCenter   = CloudPlatformLab

Azure Policy independently evaluates the required `Environment` tag instead of relying only on IaC conventions.

## Cost Management

Cost is treated as an architectural constraint.

The project uses a deploy, validate, capture evidence and remove-when-appropriate approach:

    IaC Change
        |
    Validate
        |
    Readiness
        |
    What-If
        |
    Cost Review
        |
    Approval
        |
    Deploy
        |
    Validate
        |
    Capture Evidence
        |
    Remove Paid Resources When Appropriate

Examples of cost controls include:

- 30-day Log Analytics retention
- small Dev-focused monitoring configuration
- infrastructure recreated from IaC instead of kept online unnecessarily
- avoiding expensive temporary resources solely for portfolio evidence
- independent deployment paths so quota or cost constraints do not halt unrelated work

---

## Current Platform State

Currently deployed:

    Tenant Root Group
    |
    +-- CloudPlatformLab
        |
        +-- Platform
        |   |
        |   +-- Connectivity
        |   +-- Management
        |
        +-- Landing Zones
            |
            +-- Environment tag policy
            |
            +-- Dev
            |   |
            |   +-- CloudPlatformLab subscription
            |       |
            |       +-- rg-cloudplatformlab-dev
            |           |
            |           +-- vnet-cloudplatformlab-dev
            |           |   10.10.0.0/16
            |           |   |
            |           |   +-- snet-app
            |           |   |   10.10.1.0/24
            |           |   |
            |           |   +-- snet-private-endpoints
            |           |       10.10.2.0/24
            |           |
            |           +-- pe-kv-cloudplatformlab-dev
            |           |   |
            |           |   +-- Private IP: 10.10.2.4
            |           |
            |           +-- privatelink.vaultcore.azure.net
            |           |   |
            |           |   +-- VNet link
            |           |   +-- kv-cloudplatformlab-dev -> 10.10.2.4
            |           |
            |           +-- kv-cloudplatformlab-dev
            |           |
            |           +-- log-cloudplatformlab-dev
            |           |   30-day retention
            |           |
            |           +-- appi-cloudplatformlab-dev
            |           |
            |           +-- alert-failed-requests-dev
            |           |
            |           +-- ag-cloudplatformlab-dev
            |
            +-- Prod

Defined but not currently provisioned:

- App Service Plan
- Products API App Service
- `dev` deployment slot

The App Service definition includes:

- configurable Plan SKU
- App Service
- `dev` slot
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum
- project tags

---

## Target Architecture

CloudPlatformLab deliberately avoids becoming a catalogue of Azure services.

The remaining work focuses on capabilities that materially strengthen the platform-engineering story.

### Implemented

**Application and Identity**

- .NET 8 Products API
- `DefaultAzureCredential`
- Microsoft Entra ID
- Azure RBAC
- Key Vault integration
- system-assigned managed identity architecture

**Networking**

- Dev VNet
- application subnet
- Private Endpoint subnet
- Key Vault Private Endpoint
- Private DNS zone
- VNet DNS link
- Private DNS Zone Group
- private A record

**Observability**

- Application Insights
- Log Analytics
- real application telemetry
- Azure Monitor metric alert
- Action Group
- tested email notification path

**Security**

- Workload Identity Federation
- Key Vault
- Azure RBAC authorization
- soft delete
- purge protection
- Private Link foundation
- secrets and environment-specific configuration kept out of source control

**Governance**

- Management Group hierarchy
- landing-zone structure
- custom Azure Policy
- inherited Management Group assignment
- compliance evaluation
- least-privilege separation of subscription placement

**DevOps**

- Bicep
- Azure DevOps
- reusable YAML templates
- validation
- readiness checks
- What-If
- approval gates
- independent infrastructure deployment paths

### Remaining High-Value Work

- Terraform networking implementation
- containerised Products API and bounded AKS implementation
- hub-and-spoke networking where justified
- Architecture Decision Records
- resilience/DR design
- FinOps documentation
- final architecture diagram and repository cleanup

The project will stop expanding once these capabilities provide sufficient evidence of platform ownership.

---

## Design Decisions

### Why App Service

App Service provides a managed application platform without requiring VM or Kubernetes administration.

It is appropriate for the simple Products API and demonstrates deployment slots, managed identity, secure configuration and CI/CD.

The Plan SKU is parameterised so the architecture is not tied permanently to S1.

### Why Keep an AKS Increment Separate

The application does not require Kubernetes merely to function.

AKS is therefore treated as a separate platform-engineering exercise rather than replacing App Service as the default architecture for a simple API.

This demonstrates Kubernetes capability while retaining an architecture decision based on workload requirements rather than technology preference.

### Why Bicep

Bicep provides an Azure-native IaC model with direct ARM integration.

Terraform will be introduced for a meaningful platform slice rather than duplicating every existing Bicep resource.

### Why Workload Identity Federation

Workload Identity Federation allows Azure DevOps to authenticate without storing a long-lived client secret.

### Why `DefaultAzureCredential`

`DefaultAzureCredential` allows the application to use a developer identity locally and managed identity in Azure without changing the application's credential model.

### Why Azure RBAC for Key Vault

Azure RBAC provides a consistent authorization model across Azure and avoids the legacy Key Vault access-policy model.

### Why Soft Delete and Purge Protection

Key Vault contains configuration that should be recoverable after accidental deletion.

Soft delete provides recovery and purge protection prevents permanent deletion during the protected period.

### Why Private Endpoints

Private Endpoints allow Azure platform services to be reached through private addresses within the VNet.

Key Vault is the first implemented private-service integration.

### Why Private DNS

Private Endpoint connectivity requires service names to resolve to the private endpoint address for VNet-connected workloads.

The `privatelink.vaultcore.azure.net` zone provides this mapping for Key Vault and is linked to the Dev VNet.

### Why Separate Application and Private Endpoint Subnets

Application VNet integration and Private Endpoints have different purposes.

Separate subnets provide clearer boundaries and allow each area to evolve independently.

### Why Keep Key Vault Public Access Enabled for Now

The Private Endpoint and Private DNS infrastructure are implemented, but the application currently runs outside the Azure VNet because App Service deployment is unavailable.

Keeping public access enabled allows existing local Key Vault integration to continue. Public access can be disabled after a hosted VNet-connected workload is available and the private path has been validated.

### Why Application Insights Integration

Deploying Application Insights without sending telemetry would prove only infrastructure deployment.

The application SDK generates real request telemetry, allowing the monitoring platform to be exercised operationally.

### Why Failed-Request Alerting

Failed requests provide a real application signal that can be detected and acted on.

The implementation demonstrates a complete path from application failure to notification.

### Why Store `AlertEmail` in Key Vault

The notification destination is environment-specific configuration and does not belong in public source control.

The pipeline retrieves it through its federated identity at deployment time.

### Why Azure Policy

IaC tagging conventions apply only to resources created through those templates.

Azure Policy evaluates resources independently of their deployment mechanism and therefore provides a separate governance control.

### Why Audit Before Deny

Audit allows policy behaviour and exceptions to be understood before enforcement can block deployments.

The current policy has already identified Azure-created resources that require governance judgement rather than automatic enforcement.

### Why Assign Policy at `Landing Zones`

The policy represents a landing-zone standard rather than a rule for one resource group.

Assigning it once at the Management Group allows child environments and subscriptions to inherit the requirement.

### Why Management Groups

Management Groups provide governance scope above subscriptions and allow policy inheritance across an Azure estate.

The project implements the pattern at a small scale without attempting to reproduce a large enterprise environment.

### Why Separate Subscription Placement

Subscription movement requires broader administrative access than normal policy deployment.

Treating it as a bootstrap activity keeps the repeatable pipeline identity closer to least privilege.

### Why Independent Infrastructure Pipelines

Platform domains have different providers, permissions, dependencies and failure conditions.

Independent paths prevent one constraint from unnecessarily stopping all platform deployment.

### Why Modular YAML Templates

Reusable templates keep domain-specific deployment logic isolated while preserving a readable root pipeline.

### Why Manual Approval

Infrastructure changes can affect security, governance, availability and cost.

The approval gate creates a deliberate review point before Azure is changed.

### Why Readiness Checks

A valid Bicep template can still fail because of quota, provider registration, permissions or deployment-scope conditions.

Readiness checks identify these environmental problems before deployment.

### Why Workspace-Based Application Insights

A Log Analytics workspace provides a central telemetry store for Application Insights and supports querying, alerting and investigation.

### Why 30-Day Retention

The Dev environment needs enough telemetry for troubleshooting without paying for unnecessary long-term retention.

### Why Cost-Aware Deployment

CloudPlatformLab is a portfolio environment, not a permanently running production workload.

Resources are kept only when their ongoing value justifies their cost, and IaC allows them to be recreated when needed.

---

## Current Status

Implemented and validated:

- .NET 8 Products API
- Azure DevOps CI/CD
- reusable YAML stage templates
- independent infrastructure deployment paths
- Bicep validation and What-If
- deployment readiness checks
- Azure DevOps Environment approval
- Workload Identity Federation
- Dev VNet and subnet segmentation
- Key Vault Private Endpoint
- Private Endpoint address `10.10.2.4`
- Key Vault Private DNS zone
- Private DNS VNet link
- Private DNS Zone Group
- Key Vault private A record
- Azure Key Vault
- Azure RBAC Key Vault authorization
- soft delete and purge protection
- `DefaultAzureCredential`
- application-to-Key-Vault integration
- Application Insights
- Log Analytics
- 30-day retention
- real application request telemetry
- Azure Monitor failed-request alert
- Action Group notification
- end-to-end alert test
- Key Vault-backed Action Group configuration
- Management Group landing-zone hierarchy
- custom `Environment` tag policy
- inherited `Landing Zones` policy assignment
- Azure Policy compliance evaluation
- investigation of non-compliant supporting resources
- least-privilege separation of subscription placement

The hosted App Service remains defined but undeployed because of subscription quota.

Private-networking runtime verification from a VNet-connected workload remains outstanding because no suitable low-cost VNet-connected compute is currently available. Infrastructure-level Private Endpoint and DNS configuration has been deployed and evidenced.

---

## Remaining Portfolio Work

1. Terraform networking module
2. bounded AKS implementation
3. hub-and-spoke networking where it adds architectural value
4. Architecture Decision Records
5. resilience and disaster-recovery design
6. FinOps documentation
7. final architecture diagram
8. final README and evidence cleanup

After these items, platform expansion stops and the repository becomes a stable portfolio asset rather than an indefinitely growing lab.

---

## Implementation Evidence

Selected implementation evidence is stored in [`docs/evidence`](evidence/).

| Evidence | Demonstrates |
|---|---|
| [01 - Pre-deployment quota gate](evidence/01-pre-deployment-validation-quota-gate.png) | Fail-fast subscription readiness validation |
| [02 - Bicep What-If](evidence/02-infrastructure-as-code-bicep-what-if.png) | Infrastructure changes previewed before deployment |
| [03 - App Service IaC](evidence/03-deployment-slot-iac-bicep.png) | Deployment slot, managed identity, HTTPS/TLS and tagging |
| [04 - Manual deployment gate](evidence/04-manual-dev-deployment-gate.png) | Controlled Dev deployment approval |
| [05 - Networking pipeline](evidence/05-networking-bicep-deployment-success.png) | Networking deployment through Azure DevOps |
| [06 - Virtual Network](evidence/06-networking-vnet-deployed-azure.png) | Deployed Dev VNet |
| [07 - Networking subnets](evidence/07-networking-subnets-deployed-azure.png) | Application and Private Endpoint subnet separation |
| [08 - Observability pipeline](evidence/08-observability-deployment-pipeline.png) | Controlled observability deployment |
| [09 - Application Insights](evidence/09-application-insights-deployed.png) | Workspace-based Application Insights |
| [10 - Log Analytics](evidence/10-log-analytics-workspace-deployed.png) | Central telemetry workspace |
| [11 - Log retention](evidence/11-log-analytics-data-retention.png) | 30-day Dev retention |
| [12 - Key Vault deployment](evidence/12-key-vault-deployed-azure.png) | Deployed Key Vault |
| [13 - Key Vault security](evidence/13-key-vault-security-controls.png) | Soft delete, purge protection and recovery settings |
| [14 - Key Vault RBAC](evidence/14-key-vault-rbac-access-model.png) | Azure RBAC authorization model |
| [15 - Key Vault application integration](evidence/15-key-vault-application-integration.png) | Application consuming Key Vault configuration |
| [16 - Live telemetry](evidence/16-application-insights-live-telemetry.png) | Real application telemetry |
| [17 - Request telemetry](evidence/17-application-insights-request-telemetry.png) | Individual application requests in Application Insights |
| [18 - Alert email](evidence/18-azure-monitor-alert-email-fired.png) | Operational email notification |
| [19 - Fired alert](evidence/19-azure-monitor-alert-fired.png) | Azure Monitor alert activation |
| [20 - Earlier policy compliance](evidence/20-azure-policy-environment-tag-compliance.png) | Initial resource-group policy validation |
| [21 - Earlier resource compliance](evidence/21-azure-policy-resource-compliance.png) | Resource-level findings that informed governance expansion |
| [22 - Management Group hierarchy](evidence/22-management-group-landing-zone-hierarchy.png) | Landing-zone Management Group structure |
| [23 - Policy inheritance](evidence/23-management-group-policy-inheritance.png) | Policy inherited from `Landing Zones` |
| [24 - Management Group compliance](evidence/24-management-group-policy-compliance.png) | Inherited compliance evaluation |
| [25 - Resource compliance](evidence/25-management-group-policy-resource-compliance.png) | Resource-level inherited-policy findings |
| [26 - Key Vault Private Endpoint](evidence/26-key-vault-private-endpoint-private-ip.png) | Private Endpoint NIC using `10.10.2.4` |
| [27 - Key Vault Private DNS zone](evidence/27-key-vault-private-dns-zone.png) | `privatelink.vaultcore.azure.net` and VNet integration |
| [28 - Key Vault private A record](evidence/28-private-dns-key-vault-a-record.png) | Key Vault private hostname mapped to `10.10.2.4` |
| [29 - Public DNS baseline](evidence/29-public-dns-baseline-keyvault.png) | Non-VNet Cloud Shell following the public DNS path, providing a baseline for future private-path runtime validation |
