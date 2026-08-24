# Architecture

CloudPlatformLab is designed as a small Azure platform engineering project rather than a complex application.

The application is intentionally simple. The main focus is the Azure architecture around it: infrastructure as code, CI/CD, identity, security, governance, networking, observability and cost control.

The project is being built incrementally so that each part can be understood, tested and documented properly.

---

## Current Architecture

CloudPlatformLab currently has deployed Dev networking, observability, security and governance foundations, with the application platform defined separately in Bicep.

```text
                              Azure DevOps
                                   |
                                   v
                            Build Application
                                   |
        +--------------------------+--------------------------+
        |              |                 |                   |
        v              v                 v                   v
   App Service     Networking       Observability        Security
        |              |                 |                   |
        +--------------+--------+--------+-------------------+
                                |
                                v
                           Governance

Each infrastructure domain follows:

Validation
    |
    v
Readiness
    |
    v
What-If
    |
    v
Manual Approval
    |
    v
Deployment
```

The networking, observability, security and governance deployment paths have been implemented through Azure DevOps.

The application also consumes deployed platform services during local development:

```text
ASP.NET Core Application
        |
        +-------------------------------+
        |                               |
        v                               v
DefaultAzureCredential          Application Insights SDK
        |                               |
        v                               v
Microsoft Entra ID             Application Insights
        |                               |
        v                      +--------+---------+
Azure RBAC                     |                  |
        |                      v                  v
        v              Log Analytics      Azure Monitor Alert
Azure Key Vault                                    |
                                                   v
                                             Action Group
                                                   |
                                                   v
                                           Email Notification
```

The local application authenticates to Azure through `DefaultAzureCredential` and the developer's authenticated Azure identity.

This allows Key Vault integration to be validated without storing application credentials in source control.

Application Insights is connected to the running application, and real request telemetry has been verified in Azure.

Azure Monitor alerting has also been implemented. Failed application requests are evaluated by a metric alert scoped to Application Insights. When the configured threshold is exceeded, an Azure Monitor Action Group sends an email notification.

This monitoring path has been tested end-to-end by deliberately generating failed application requests and confirming that the Azure Monitor alert fired and the Action Group delivered the notification.

The platform now also includes a deployed Management Group landing-zone hierarchy and Azure Policy governance.

The CloudPlatformLab subscription is placed beneath the `Dev` Management Group, while the required `Environment` tag policy is assigned at the `Landing Zones` Management Group.

This means governance is inherited through:

```text
Landing Zones
     |
     v
Dev
     |
     v
CloudPlatformLab subscription
     |
     v
Dev workload resources
```

The previous direct resource-group policy assignment was removed after Management Group inheritance was validated, avoiding duplicate governance at lower scopes.

Azure Policy compliance has been validated against the real Dev environment through the inherited assignment.

The latest evaluation showed:

```text
Resources evaluated: 8
Compliant:           6
Non-compliant:       2
Compliance:          75%
```

The non-compliant findings include Azure-created supporting resources rather than resources deliberately created without the project tagging standard.

These findings have deliberately not been changed simply to produce a 100% compliance score. They demonstrate that governance findings require investigation and an appropriate remediation, scope-refinement or exemption decision.

The App Service infrastructure follows an independent deployment path. Its Bicep definition is valid, but provisioning using the currently selected S1 SKU is blocked by the subscription's App Service quota.

Keeping these deployment paths independent allows networking, observability, security and governance work to continue without being blocked by an unrelated application-platform constraint.

The Azure DevOps pipeline has been modularised into reusable YAML stage templates so that each infrastructure domain can evolve independently without turning the root pipeline into a large monolithic definition.

---

## Application Layer

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the main objective of the project is to demonstrate the platform around the application rather than application complexity.

Current application components:

- ASP.NET Core .NET 8
- Products API
- Azure Key Vault configuration integration
- `DefaultAzureCredential` for local Azure authentication
- Key Vault integration verification endpoint
- Application Insights SDK integration
- real Application Insights request telemetry
- failed-request telemetry used by Azure Monitor alerting
- Azure App Service architecture
- `dev` deployment slot architecture

The application currently validates platform integrations locally against the real Azure Dev resources.

The App Service infrastructure is defined and validated through Bicep but is not provisioned because the subscription currently has no available quota for the selected S1 SKU.

The App Service Plan SKU is parameterised so the architecture is not permanently tied to S1 and can use another appropriate supported SKU in the future.

Local development configuration uses .NET User Secrets where appropriate so environment-specific values are not committed to source control.

---

## Infrastructure Layer

Infrastructure is defined using Bicep and separated by platform concern.

Current templates are located at:

```text
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
```

The App Service template defines:

- configurable App Service Plan SKU
- App Service
- `dev` deployment slot
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum
- resource tags

The networking template defines:

- Dev virtual network
- application subnet
- private endpoint subnet
- common resource tags

The observability template defines:

- Log Analytics workspace
- workspace-based Application Insights
- 30-day Log Analytics retention
- Azure Monitor Action Group
- failed-request metric alert
- common resource tags

The security template defines:

- Azure Key Vault
- Azure RBAC authorization model
- soft delete
- 90-day soft-delete retention
- purge protection
- common resource tags

The governance templates define:

- CloudPlatformLab Management Group hierarchy
- `Platform`, `Connectivity`, `Management`, `Landing Zones`, `Dev` and `Prod` Management Groups
- custom Azure Policy definition for the required `Environment` tag
- policy assignment at the `Landing Zones` Management Group
- inherited governance for descendant Management Groups and subscriptions
- separation between reusable policy definition and scope-specific assignment

Most workload infrastructure is deployed into:

```text
rg-cloudplatformlab-dev
```

Region:

```text
UK South
```

Governance is intentionally applied above the individual resource-group layer.

The Management Group hierarchy establishes governance boundaries while the reusable policy definition and Management Group assignment allow policy inheritance rather than duplicating the same assignment at every subscription or resource group.

Separating infrastructure by platform concern allows each area to be validated, deployed and evolved independently while remaining managed through the same repository and CI/CD workflow.

Using Bicep means the environment can be recreated instead of relying on manually configured resources.

Repeated deployments converge Azure towards the declared state rather than creating duplicate resources.

---

## Networking Architecture

The deployed networking foundation provides address space for application workloads and future private connectivity.

```text
vnet-cloudplatformlab-dev
Address space: 10.10.0.0/16
|
+-- snet-app
|   10.10.1.0/24
|
+-- snet-private-endpoints
    10.10.2.0/24
```

`snet-app` provides a dedicated subnet for application-related integration as the platform develops.

`snet-private-endpoints` reserves separate address space for future Azure Private Endpoints, keeping private platform-service connectivity separated from application integration.

The current network is intentionally small. Hub-spoke topology, Private DNS, VNet peering and additional network controls will be introduced when they support an implemented platform requirement rather than being added solely for architectural complexity.

The networking infrastructure is independently deployable through the Azure DevOps pipeline and has been successfully provisioned from Bicep.

---

## Observability Architecture

The deployed observability foundation provides application telemetry, centralized log storage, metric-based failure detection and automated notification.

```text
ASP.NET Core Application
          |
          v
Application Insights SDK
          |
          v
appi-cloudplatformlab-dev
Application Insights
          |
          +----------------------------+
          |                            |
          v                            v
log-cloudplatformlab-dev      Failed Request Metric
Log Analytics Workspace                |
          |                             v
          v                    Azure Monitor Alert
  30-day retention             alert-failed-requests-dev
                                        |
                                        v
                                  Action Group
                                        |
                                        v
                                Email Notification
```

Application Insights is linked to the Log Analytics workspace so application telemetry uses the workspace as the central observability data store.

The ASP.NET Core application is configured with the Application Insights SDK and has successfully sent real request telemetry to the deployed Application Insights resource.

Verified telemetry includes requests to the Key Vault integration endpoint, providing evidence that the running application is actively using the observability platform rather than Application Insights existing only as deployed infrastructure.

The Application Insights connection string is supplied through local environment configuration using .NET User Secrets rather than being stored in source control.

Application Insights registration is conditional so an environment without telemetry configuration can still run the application.

### Azure Monitor Alerting

The observability platform includes an Azure Monitor metric alert monitoring failed Application Insights requests.

The implemented monitoring flow is:

```text
Application Request
       |
       v
Application Insights
       |
       v
requests/failed metric
       |
       v
Azure Monitor Metric Alert
alert-failed-requests-dev
       |
       v
Azure Monitor Action Group
       |
       v
Email Notification
```

The failed-request alert is configured through Bicep and deployed through the same controlled observability pipeline as the rest of the monitoring infrastructure.

The alert uses the Application Insights failed-request metric and fires when failed requests exceed the configured threshold.

The Action Group email receiver is not hardcoded in the repository.

Instead, the notification email address is stored as the `AlertEmail` secret in Azure Key Vault.

During the observability What-If and deployment operations, the Azure DevOps service connection retrieves `AlertEmail` from Key Vault and supplies it to the Bicep deployment as a secure parameter.

```text
Azure Key Vault
kv-cloudplatformlab-dev
       |
       | AlertEmail
       v
Azure DevOps Service Connection Identity
       |
       | Key Vault Secrets User
       v
Observability Pipeline
       |
       | secure deployment parameter
       v
Observability Bicep
       |
       v
Azure Monitor Action Group
```

The pipeline identity is granted the `Key Vault Secrets User` role required to retrieve the secret value.

The pipeline does not print the retrieved email address to its logs.

This separates environment-specific notification configuration from the IaC definition while keeping the Action Group itself reproducibly deployed through Bicep.

The monitoring path has been validated end-to-end.

Failed application requests were deliberately generated, telemetry was received by Application Insights, `alert-failed-requests-dev` entered the fired state, and the configured Action Group successfully delivered an Azure Monitor Sev2 alert notification by email.

The Log Analytics workspace currently uses 30-day retention. This provides sufficient retention for a development environment while limiting unnecessary long-term data retention and associated cost.

---

## Security Architecture

The Dev environment includes a Key Vault security foundation deployed through Bicep and the controlled Azure DevOps pipeline.

```text
kv-cloudplatformlab-dev
Azure Key Vault
        |
        +-- Azure RBAC authorization
        |
        +-- Soft delete
        |     90-day retention
        |
        +-- Purge protection
        |
        +-- Application configuration
        |
        +-- AlertEmail
        |
        +-- Project tags
```

The Key Vault uses Azure RBAC rather than the legacy Key Vault access-policy model.

Soft delete provides recovery protection for deleted vault content, while purge protection prevents destructive permanent deletion during the configured protection period.

Public network access remains enabled at this stage deliberately.

Private network access will be introduced later through Private Endpoints and Private DNS as part of the private-connectivity phase rather than mixing network architecture changes into the initial Key Vault security foundation.

### Application-to-Key-Vault Integration

The ASP.NET Core application consumes configuration from the deployed Key Vault.

During local development, the application uses:

```text
ASP.NET Core Application
          |
          v
DefaultAzureCredential
          |
          v
Microsoft Entra ID
          |
          v
Azure RBAC
          |
          v
kv-cloudplatformlab-dev
```

`DefaultAzureCredential` resolves the developer's authenticated Azure identity locally.

Microsoft Entra ID authenticates that identity and Azure RBAC authorizes access to Key Vault.

A test configuration value has been successfully loaded from Key Vault into .NET configuration.

The `/health/keyvault` endpoint verifies that the value was loaded without returning or logging the secret itself.

Once App Service can be provisioned, the application authentication path is intended to become:

```text
App Service
System-Assigned Managed Identity
          |
          v
Microsoft Entra ID
          |
          v
Azure RBAC
          |
          v
Azure Key Vault
```

The application code can therefore move from a developer identity locally to a workload identity in Azure without introducing an application-managed client secret.

Key Vault also provides environment-specific configuration to the deployment platform. The Azure DevOps service connection identity has narrowly scoped secret-read access required to retrieve `AlertEmail` for the observability deployment.

No application secret values, notification email addresses or Azure connection strings are committed to the repository.

---

## Governance Architecture

CloudPlatformLab implements a Management Group-based governance model that separates shared platform concerns from workload landing zones.

The deployed hierarchy is:

```text
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
```

The hierarchy is represented through Bicep and deployed through the dedicated governance pipeline.

The CloudPlatformLab subscription is placed beneath the `Dev` Management Group, allowing governance assigned higher in the hierarchy to be inherited by the development subscription and its resources.

### Policy Scope and Inheritance

The first implemented governance control audits Azure resources for the required `Environment` tag.

The custom policy definition is separated from its assignment so that the governance rule can be reused independently of the scope at which it is applied.

The policy is assigned at the `Landing Zones` Management Group:

```text
Landing Zones
|
+-- Environment tag policy assignment
|
+-- Dev
|   |
|   +-- CloudPlatformLab subscription
|       |
|       +-- rg-cloudplatformlab-dev
|           |
|           +-- Azure resources
|
+-- Prod
```

This allows the policy to flow through the Management Group hierarchy rather than duplicating the same assignment at individual resource-group or subscription scope.

The previous direct assignment to `rg-cloudplatformlab-dev` was removed after Management Group inheritance was validated.

### Subscription Placement and Least Privilege

Subscription placement is intentionally treated separately from the repeatable Azure DevOps governance deployment.

Moving a subscription between Management Groups requires broader permissions than normal governance deployment.

The project therefore separates:

```text
Privileged platform/bootstrap operation
|
+-- Subscription placement

Repeatable Azure DevOps governance
|
+-- Management Group hierarchy
+-- Policy definition
+-- Policy assignment
+-- Validation
+-- What-If
+-- Controlled deployment
```

This avoids escalating the normal deployment identity simply to automate an infrequent administrative operation.

### Compliance Evaluation

Azure Policy compliance has been successfully evaluated through the inherited `Landing Zones` assignment.

```text
Resources evaluated: 8
Compliant:           6
Non-compliant:       2
Compliance:          75%
```

The non-compliant results include Azure-created/supporting resources including:

```text
application insights smart detection

NetworkWatcher_uksouth
```

The findings have deliberately not been changed simply to produce a 100% compliance score.

Instead, they demonstrate:

```text
Inherited Policy
      |
      v
Compliance Evaluation
      |
      v
Non-Compliant Resource
      |
      v
Investigation
      |
      +--> Remediate where appropriate
      |
      +--> Refine policy scope where appropriate
      |
      +--> Use a justified exemption where appropriate
```

### Governance Pipeline

Governance has its own reusable Azure DevOps pipeline template:

```text
pipelines/templates/governance.yml
```

The cleaned governance path focuses on:

```text
Management Group Hierarchy
          +
Landing Zone Policy
```

Obsolete subscription-governance deployment stages and the old resource-group policy assignment were removed after the Management Group model became the authoritative governance design.

The governance path follows:

```text
Bicep Validation
      |
      v
Governance Readiness
      |
      v
What-If
      |
      v
Manual Approval
      |
      v
Deployment
```

Governance readiness validates:

- `Microsoft.Authorization`
- `Microsoft.PolicyInsights`
- `Microsoft.Management`
- Management Group access
- required deployment prerequisites

The Azure DevOps service connection authenticates through Workload Identity Federation.

The feature-branch pipeline was run again after the governance cleanup and all governance stages and deployments completed successfully.

---

## Application Integration Architecture

The runtime and operational integrations connect the application to the deployed security and observability capabilities, while Azure Policy evaluates the surrounding platform resources through inherited Management Group governance.

```text
                         ASP.NET Core Application
                                  |
                  +---------------+---------------+
                  |                               |
                  v                               v
        DefaultAzureCredential          Application Insights SDK
                  |                               |
                  v                               v
        Microsoft Entra ID               Application Insights
                  |                               |
                  v                    +----------+----------+
             Azure RBAC               |                     |
                  |                    v                     v
                  v             Log Analytics        Failed Requests
             Azure Key Vault                                 |
                                                            v
                                                    Azure Monitor Alert
                                                            |
                                                            v
                                                       Action Group
                                                            |
                                                            v
                                                    Email Notification

                       Azure Policy Governance
                                  |
                                  v
                    Landing Zones Management Group
                                  |
                                  v
                          Inherited by Dev
                                  |
                                  v
                     CloudPlatformLab Subscription
                                  |
                                  v
                     Dev Resource Evaluation
                                  |
                                  v
                      Compliance / Findings
```

The workload actively consumes the identity/security and observability capabilities provided by the platform, while the governance layer independently evaluates Azure resources against inherited policy requirements.

The current application integration is tested locally because App Service provisioning remains blocked by subscription quota.

When App Service becomes deployable, the developer identity used by `DefaultAzureCredential` locally can be replaced by the App Service system-assigned managed identity while preserving the same application authentication model.

---

## Deployment Architecture

Azure DevOps is used for CI/CD.

Changes are developed in feature branches and merged into `Dev` through pull requests. The `Dev` branch is the deployment source for the Dev environment.

As the platform grew, the pipeline was refactored from one large YAML file into a root orchestration pipeline with reusable stage templates.

```text
azure-pipelines.yml
        |
        +-- pipelines/templates/appservice.yml
        |
        +-- pipelines/templates/networking.yml
        |
        +-- pipelines/templates/observability.yml
        |
        +-- pipelines/templates/security.yml
        |
        +-- pipelines/templates/governance.yml
```

The root pipeline performs the shared application build and then invokes the independent infrastructure templates.

```text
Feature branch
      |
      v
Pull Request
      |
      v
Dev
      |
      v
Build Application
      |
      +---------------+---------------+---------------+---------------+
      |               |               |               |               |
      v               v               v               v               v
 App Service      Networking     Observability      Security      Governance
      |               |               |               |               |
      v               v               v               v               v
 Validation      Validation      Validation      Validation      Validation
      |               |               |               |               |
      v               v               v               v               v
 Readiness       Readiness       Readiness       Readiness       Readiness
      |               |               |               |               |
      v               v               v               v               v
  What-If         What-If         What-If         What-If         What-If
      |               |               |               |               |
      v               v               v               v               v
 Approval         Approval         Approval         Approval         Approval
      |               |               |               |               |
      v               v               v               v               v
Deployment       Deployment      Deployment      Deployment      Deployment
```

The independent paths prevent a deployment constraint affecting one infrastructure area from unnecessarily blocking another.

This is currently demonstrated by the App Service quota constraint: App Service deployment can stop at its readiness stage while networking, observability, security and governance continue independently.

Deployment stages target the Azure DevOps environment:

```text
env-cloudplatformlab-dev
```

The environment uses a manual approval check before infrastructure changes are applied.

Feature-branch pipeline runs are used to validate infrastructure and pipeline behaviour before changes are merged. Dev environment infrastructure deployment is performed from the merged `Dev` branch.

The observability pipeline retrieves the `AlertEmail` value from Key Vault during What-If and deployment.

The pipeline identity is authorized through Azure RBAC and uses the `Key Vault Secrets User` role at the Key Vault scope.

The email value is passed to the observability Bicep deployment as a secure parameter rather than being hardcoded in the repository.

The governance pipeline deploys and validates the Management Group hierarchy and inherited Azure Policy governance through the same controlled CI/CD approach used by the other infrastructure domains.

The governance pipeline was cleaned after the Management Group implementation became authoritative. Obsolete subscription-governance stages and the previous direct resource-group policy assignment were removed.

---

### Deployment Safeguards

Infrastructure changes are not deployed directly from a developer workstation.

Each infrastructure path follows a controlled sequence:

1. Bicep validation
2. Deployment readiness checks
3. Bicep What-If
4. Azure DevOps Environment approval
5. Bicep deployment

App Service readiness currently validates:

- `Microsoft.Web` resource provider registration
- target resource group availability
- quota availability for the configured App Service SKU

Networking readiness currently validates:

- `Microsoft.Network` resource provider registration
- target resource group availability

Observability readiness currently validates:

- `Microsoft.OperationalInsights` resource provider registration
- `Microsoft.Insights` resource provider registration
- target resource group availability

Security readiness currently validates:

- `Microsoft.KeyVault` resource provider registration
- target resource group availability

Governance readiness currently validates:

- `Microsoft.Authorization` resource provider registration
- `Microsoft.PolicyInsights` resource provider registration
- `Microsoft.Management` resource provider registration
- Management Group access
- required deployment scope/environment prerequisites

Readiness checks are intentionally separated from Bicep validation.

Bicep validation verifies the infrastructure definition, while readiness checks detect known subscription, permission or environmental conditions that could prevent a valid template from being deployed or evaluated correctly.

This distinction produces clearer pipeline failures and prevents known environmental constraints from being confused with invalid infrastructure code.

The deployment stages use an Azure Resource Manager service connection configured with Workload Identity Federation, avoiding a long-lived client secret in the pipeline.

---

## Resource Provider Strategy

Azure resource-provider registration is treated as a subscription/platform readiness concern rather than being embedded in workload templates.

The pipeline verifies required providers before the relevant deployment path continues.

Providers currently relevant to implemented platform areas include:

```text
App Service
Microsoft.Web

Networking
Microsoft.Network

Observability
Microsoft.OperationalInsights
Microsoft.Insights

Security
Microsoft.KeyVault

Governance
Microsoft.Authorization
Microsoft.PolicyInsights
Microsoft.Management
```

`Microsoft.PolicyInsights` supports Azure Policy compliance evaluation.

`Microsoft.Management` supports the Management Group governance layer.

This keeps subscription-level and platform-level preparation separate from workload-level Infrastructure as Code.

New resource providers will be introduced and validated as additional platform capabilities are implemented rather than registering unrelated providers in advance.

---

## Identity and Authentication

The Azure DevOps pipeline authenticates to Azure using Workload Identity Federation.

This avoids storing an Azure client secret in the pipeline or repository.

The service connection is:

```text
sc-cloudplatformlab-dev
```

The application currently uses two Azure identity contexts depending on where code is running.

During local development:

```text
Local Application
      |
      v
DefaultAzureCredential
      |
      v
Authenticated Developer Identity
      |
      v
Microsoft Entra ID
      |
      v
Azure RBAC
      |
      v
Azure Key Vault
```

For the future Azure-hosted workload:

```text
App Service
      |
      v
System-Assigned Managed Identity
      |
      v
Microsoft Entra ID
      |
      v
Azure RBAC
      |
      v
Azure Key Vault
```

The Azure DevOps service connection also uses an identity-based access path for deployment-time Key Vault access:

```text
Azure DevOps
      |
      v
Workload Identity Federation
      |
      v
Service Connection Identity
      |
      v
Azure RBAC
Key Vault Secrets User
      |
      v
Azure Key Vault
      |
      v
AlertEmail
```

For governance operations, the service connection identity is granted the Azure permissions required to manage the implemented policy and Management Group resources.

Subscription placement is intentionally separated from the normal repeatable deployment path because moving subscriptions between Management Groups requires broader permissions than the standard governance deployment should retain.

This extends the same identity-first and least-privilege deployment model to governance rather than introducing a separate credential mechanism.

---

## Security Design

Current security controls include:

- Workload Identity Federation
- Azure Key Vault
- Azure RBAC Key Vault authorization
- Key Vault soft delete
- 90-day Key Vault soft-delete retention
- Key Vault purge protection
- application-to-Key-Vault configuration integration
- `DefaultAzureCredential`
- developer identity authentication through Microsoft Entra ID
- Azure RBAC authorization for Key Vault access
- Key Vault integration verification without exposing secret values
- Azure DevOps service connection identity granted scoped `Key Vault Secrets User` access
- monitoring notification email stored in Key Vault rather than source control
- observability pipeline retrieves deployment-time configuration from Key Vault
- Azure RBAC
- Azure Policy compliance auditing
- Management Group governance hierarchy
- inherited policy assignment
- separation of privileged subscription placement from repeatable governance deployment
- controlled Azure DevOps service connection
- manual approval before infrastructure deployment
- deployment readiness checks
- infrastructure validation before deployment
- system-assigned managed identity defined for App Service
- HTTPS-only App Service configuration
- TLS 1.2 minimum App Service configuration
- separate subnet reserved for future Private Endpoints
- environment-specific values kept out of source control

Planned security improvements include:

- App Service-to-Key-Vault access through system-assigned managed identity
- Private Endpoints
- Private DNS
- network segmentation controls where appropriate
- Defender for Cloud
- tighter RBAC where appropriate

Secrets and credentials are not intended to be stored in source control.

---

## Resource Organisation and Governance

Development workload resources are grouped under:

```text
rg-cloudplatformlab-dev
```

The subscription containing those resources is organised beneath the `Dev` Management Group in the CloudPlatformLab landing-zone hierarchy.

```text
CloudPlatformLab
|
+-- Landing Zones
    |
    +-- Dev
        |
        +-- CloudPlatformLab subscription
            |
            +-- rg-cloudplatformlab-dev
```

Resources are tagged to support ownership, governance and cost tracking.

Current standard tags include:

```text
Project       = CloudPlatformLab
Environment   = Dev
ManagedBy     = Bicep
CostCenter    = CloudPlatformLab
```

Tagging is no longer represented only as a convention in the Bicep templates.

Azure Policy evaluates the Dev environment through an inherited assignment at the `Landing Zones` Management Group.

The latest compliance evaluation identified:

```text
Resources evaluated: 8
Compliant:           6
Non-compliant:       2
Compliance:          75%
```

The non-compliant resources were investigated rather than automatically modified.

The findings include Azure-created/supporting resources, demonstrating the distinction between defining a governance standard and blindly forcing every discovered resource into compliance.

The previous direct resource-group policy assignment was removed once Management Group inheritance was validated.

This leaves the higher-level `Landing Zones` assignment as the intentional governance source for the workload hierarchy.

Future governance work can extend the current audit model with additional policies, justified exemptions and stronger enforcement where appropriate. The Management Group landing-zone foundation itself is now implemented.

---

## Cost Management

Cost is treated as part of the architecture.

This is a personal lab environment, so paid Azure resources are not intended to remain online when they are not needed.

The current process is:

```text
Bicep change
     |
     v
Bicep validation
     |
     v
Readiness checks
     |
     v
What-If
     |
     v
Review proposed resources
     |
     v
Check expected Azure cost
     |
     v
Manual approval
     |
     v
Deploy
     |
     v
Validate and gather evidence
     |
     v
Remove paid resources when appropriate
```

The Log Analytics workspace uses a 30-day retention period to provide a useful observability foundation without retaining development telemetry unnecessarily.

The application is generating real telemetry, allowing ingestion volume and retention to be reviewed against actual application activity as part of the platform's cost controls.

Monitoring resources are kept intentionally small and focused. The current alerting implementation uses an existing Application Insights metric and a single project Action Group rather than introducing unnecessary monitoring infrastructure.

Azure Policy and Management Groups add governance capability without requiring the project to introduce unnecessary workload infrastructure simply for demonstration purposes.

Because the environment is defined as code, resources can be removed and recreated later.

This also helps test whether the infrastructure is genuinely reproducible.

The independent deployment architecture allows useful platform, governance and application-integration work to continue without bypassing the App Service quota constraint.

---

## Target Architecture

The deployed networking, observability, security and governance foundations, together with the application integrations, operational alerting and defined App Service workload, form the initial platform baseline.

The remaining target architecture focuses on a small number of high-value platform-engineering capabilities rather than continuously adding Azure services.

### Identity and Security

Implemented:

- Microsoft Entra ID authentication
- Workload Identity Federation
- Azure Key Vault
- Azure RBAC
- system-assigned managed identity defined for App Service

Remaining:

- App Service-to-Key-Vault access through managed identity
- Private Endpoints
- private service access
- Defender for Cloud where appropriate

### Networking

Implemented:

- Dev VNet
- application subnet
- dedicated Private Endpoint subnet

Remaining:

- hub-spoke virtual network architecture
- VNet peering
- Private DNS
- Private Endpoints
- private connectivity to Azure platform services
- network segmentation controls where appropriate

### Application Platform

Defined:

- Azure App Service
- deployment slots
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum

Remaining:

- deployment when suitable App Service capacity is available
- health checks
- controlled promotion where appropriate

### Observability

Implemented:

- Azure Monitor
- Application Insights
- Log Analytics
- metric alerts
- Action Groups
- real application telemetry
- end-to-end failed-request alerting

Remaining:

- broader health monitoring where justified

### Infrastructure and DevOps

Implemented:

- Bicep
- Azure DevOps
- Azure Repos
- GitHub
- reusable pipeline templates
- CI/CD
- validation
- What-If
- approval gates
- readiness checks

Remaining:

- Terraform implementation
- automated application tests

### Governance and FinOps

Implemented:

- Management Group hierarchy
- landing-zone structure
- Azure Policy
- inherited policy assignment
- policy compliance evaluation
- Azure RBAC
- resource tagging
- cost-aware deployment
- non-production cost controls

Remaining:

- additional policy controls only where justified
- policy exemptions where justified
- final governance documentation and ADRs

---

## Landing Zone Implementation

The project now includes a working Management Group hierarchy representing a small enterprise landing-zone model.

```text
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
```

This structure separates shared platform concerns from workload landing zones and provides governance scopes above individual subscriptions and resource groups.

The `Landing Zones` Management Group is the current policy-assignment boundary.

The required `Environment` tag policy is assigned there and inherited by the `Dev` hierarchy, the CloudPlatformLab subscription and its workload resources.

The implementation demonstrates:

- Management Group hierarchy
- subscription organisation
- policy inheritance
- Management Group policy scope
- reusable policy definitions
- separation of policy definition and assignment
- Azure RBAC
- least-privilege CI/CD boundaries
- controlled governance deployment
- Azure Policy compliance evaluation
- architecture that can scale to additional subscriptions without duplicating assignments

The project deliberately keeps the landing-zone implementation small.

The objective is not to reproduce the size of a large enterprise Azure estate. The project implements the architectural pattern at a practical scale and documents how the same design could expand.

---

## Design Decisions

### Why App Service

App Service provides a managed application platform without requiring VM or Kubernetes management.

It is suitable for demonstrating deployment slots, managed identity, application configuration and CI/CD without adding unnecessary infrastructure complexity.

The App Service Plan SKU is parameterised so the architecture is not permanently tied to a specific SKU such as S1.

### Why a Deployment Slot

The `dev` slot allows changes to be deployed and validated separately from the main production site.

This also creates a path toward slot swapping and rollback later.

### Why Bicep

Bicep is Azure-native, works directly with Azure Resource Manager and fits naturally with the rest of the Azure-focused project.

Terraform will be introduced later to demonstrate a second IaC approach without maintaining two identical copies of every resource.

### Why Workload Identity Federation

Workload Identity Federation allows Azure DevOps to authenticate to Azure without storing a long-lived client secret.

This reduces secret-management overhead and is closer to the authentication approach intended for a production cloud environment.

### Why DefaultAzureCredential

`DefaultAzureCredential` provides an environment-aware authentication model for the application.

During local development, it can use the developer's authenticated Azure identity. When the application runs in Azure, the same application design can use a managed identity instead.

This allows authentication to change with the execution environment without introducing application-managed credentials.

### Why Azure RBAC for Key Vault

Key Vault uses the Azure RBAC permission model rather than legacy vault access policies.

This provides a consistent authorization model across Azure resources and allows access to be managed using scoped Azure role assignments.

### Why Soft Delete and Purge Protection

Key Vault can contain security-sensitive configuration that should not be permanently destroyed accidentally.

Soft delete provides a recovery window, while purge protection prevents protected content from being permanently removed before the recovery period expires.

### Why Public Key Vault Access Initially

Public network access remains enabled for the first security foundation so Key Vault deployment, RBAC and application integration can be implemented independently from private networking.

Private Endpoint and Private DNS integration will be introduced as a separate networking/security increment.

This keeps identity, authorization and networking concerns independently testable while the platform is developed incrementally.

### Why Application Insights SDK Integration

Deploying Application Insights alone does not demonstrate application observability.

Integrating the Application Insights SDK into the ASP.NET Core application allows real request telemetry to be generated and sent to the deployed observability platform.

This validates the path from the running workload through Application Insights to the Log Analytics workspace and provides a foundation for alerts, investigation and operational monitoring.

### Why Azure Monitor Failed-Request Alerting

The project already produces real Application Insights request telemetry, so failed-request monitoring provides a meaningful operational control rather than an artificial alert created only for demonstration.

The alert is scoped to the deployed Application Insights resource and evaluates the failed-request metric.

This creates a direct operational path from application failure telemetry to an actionable notification.

### Why an Action Group

An Azure Monitor alert without a notification path only detects a problem.

The Action Group turns that detection into an operational response by delivering an alert notification when the metric condition is met.

This demonstrates the difference between collecting telemetry and actually operating a monitored workload.

### Why Store AlertEmail in Key Vault

The notification destination is environment-specific configuration and does not need to be hardcoded into public Infrastructure as Code.

Storing `AlertEmail` in Key Vault keeps the value out of source control while still allowing the deployment pipeline to create the Action Group reproducibly.

The Azure DevOps service connection identity retrieves the value through Azure RBAC at deployment time.

### Why Pipeline Identity Reads Key Vault

The observability pipeline needs the Action Group email value during both What-If and deployment.

Rather than using a static pipeline secret or client credential, the existing Workload Identity Federation service connection is granted scoped `Key Vault Secrets User` access.

This extends the project's identity-first model to deployment-time configuration retrieval.

### Why Azure Policy

Resource tags existed in the project's Bicep definitions, but IaC conventions alone do not provide an independent governance control.

Azure Policy allows the platform to evaluate deployed resources against a governance requirement regardless of how those resources were created.

The initial policy audits the `Environment` tag because it provides a simple but genuine governance control that can be validated against real Azure resources.

### Why Audit Before Enforcement

The first policy uses the `Audit` effect rather than immediately denying deployments.

Audit mode allows the project to observe how the rule behaves against the existing environment before introducing enforcement.

This has already demonstrated its value by identifying Azure-created supporting resources that do not satisfy the tagging standard.

Introducing enforcement without first understanding cases like these could create unnecessary deployment failures.

### Why Investigate Non-Compliance Instead of Forcing 100%

Policy compliance is not simply a score to maximize.

The inherited policy currently reports two non-compliant Azure-created/supporting resources.

The findings are therefore treated as governance decisions rather than manually changing resources solely to produce a green compliance dashboard.

The appropriate treatment can be remediation, refinement of policy scope or a documented policy exemption.

### Why Separate Policy Definition and Assignment

The policy definition describes the reusable governance rule, while the assignment determines where that rule applies.

Separating these concerns allows the same policy definition to be applied at different scopes or environments without duplicating policy logic.

### Why Assign Policy at the Landing Zones Management Group

The tagging standard applies to workload landing zones rather than to one individual resource group.

Assigning the policy at `Landing Zones` establishes the governance rule once and allows it to be inherited by child Management Groups and subscriptions.

This better represents an enterprise governance model than duplicating the same policy assignment at individual resource groups.

### Why Management Groups

Resource groups organise resources inside a subscription, but they do not provide a governance hierarchy above subscriptions.

Management Groups allow CloudPlatformLab to demonstrate platform-level organisation and policy inheritance.

The hierarchy separates shared platform concerns from workload landing zones and creates a structure that can scale to additional subscriptions without redesigning the governance model.

### Why Separate Subscription Placement from the Governance Pipeline

Moving a subscription between Management Groups requires broader permissions than those needed for normal repeatable governance deployment.

Subscription placement is therefore treated as a privileged bootstrap or administrative operation rather than granting the standard pipeline identity unnecessary permanent privilege.

This keeps the repeatable CI/CD identity closer to least privilege.

### Why Governance Has Its Own Pipeline Path

Governance resources have different scope, permissions and readiness requirements from application, networking, observability and security resources.

Giving governance its own reusable pipeline path keeps these concerns isolated while preserving the same validation, What-If, approval and deployment controls used elsewhere in the platform.

### Why Local Integration Before App Service Deployment

The App Service infrastructure is currently blocked by a subscription-level quota constraint rather than an application or IaC problem.

Key Vault and Application Insights are already available, so application-to-platform integrations are validated locally against those real Azure services instead of delaying unrelated engineering work.

This separates application integration from the App Service capacity constraint and allows the eventual hosted workload to reuse the validated integration patterns.

### Why Manual Approval

Infrastructure changes can affect availability, security, governance and cost.

The approval gate creates a deliberate review point between validation and deployment.

### Why Separate Infrastructure Deployment Paths

App Service, networking, observability, security and governance have different deployment dependencies and readiness requirements.

Keeping them in independent pipeline paths means a constraint affecting one platform area does not unnecessarily block validation or deployment of another.

This is demonstrated by the current App Service quota restriction: the application-platform deployment can stop at its readiness check while networking, observability, security and governance continue independently.

### Why Modular Pipeline Templates

As additional platform domains were introduced, maintaining every stage in one root YAML pipeline would create unnecessary complexity and duplication.

Reusable stage templates keep each infrastructure domain isolated while preserving a single platform pipeline entry point.

This allows the root pipeline to remain readable while platform-specific validation and deployment logic can evolve independently.

### Why Separate Application and Private Endpoint Subnets

Application integration and Private Endpoints serve different networking purposes.

Using separate subnets provides a clearer boundary between application connectivity and private access to Azure platform services and gives each area room to evolve with its own configuration and controls.

### Why Workspace-Based Application Insights

Application Insights is linked to a Log Analytics workspace so application telemetry can use a central observability data store.

The application is actively sending telemetry through this architecture rather than the observability resources existing only as infrastructure.

This provides a foundation for KQL queries, alerts, operational investigation and correlation as additional application and platform telemetry is introduced.

### Why 30-Day Log Retention

The Dev environment does not require long-term telemetry retention.

A 30-day retention period provides enough history for development troubleshooting and observability work while limiting unnecessary retention and cost.

### Why Readiness Checks Before What-If

Some Azure deployment failures are caused by subscription, permission or environment conditions rather than invalid infrastructure code.

Readiness checks detect known environmental constraints before deployment evaluation continues, while Bicep validation independently verifies that the infrastructure definition is valid.

The governance implementation reinforced this approach as Management Group and Azure Policy operations introduced scope and provider requirements distinct from workload deployments.

This produces clearer pipeline failures by distinguishing invalid infrastructure from Azure subscription or deployment-readiness constraints.

### Why Cost-Aware Deployment

The project is a lab environment rather than a permanent production workload.

Paid resources are deployed only when they are needed and can be removed afterwards because the environment can be recreated from IaC.

---

## Current Status

Implemented and validated:

- .NET 8 application
- Products API
- Azure DevOps CI/CD pipeline
- reusable Azure DevOps YAML stage templates
- independent App Service, networking, observability, security and governance pipeline paths
- Bicep infrastructure definitions
- Bicep validation
- Bicep What-If
- Workload Identity Federation
- Azure DevOps Environment
- manual deployment approval
- resource-provider readiness validation
- App Service SKU quota validation
- system-assigned managed identity defined in Bicep
- resource tagging defined in Bicep
- Dev virtual network deployed through Bicep
- application subnet deployed through Bicep
- private endpoint subnet deployed through Bicep
- Log Analytics workspace deployed through Bicep
- workspace-based Application Insights deployed through Bicep
- Application Insights linked to Log Analytics
- 30-day Log Analytics retention
- Azure Key Vault deployed through Bicep
- Azure RBAC Key Vault authorization
- Key Vault soft delete
- 90-day Key Vault soft-delete retention
- Key Vault purge protection
- `DefaultAzureCredential` application authentication
- application-to-Key-Vault configuration integration
- Key Vault access through Microsoft Entra ID and Azure RBAC
- Key Vault verification endpoint without exposing secret values
- Application Insights SDK integrated with the ASP.NET Core application
- real application telemetry received by Application Insights
- individual application requests verified in Application Insights
- local environment-specific configuration kept outside source control using .NET User Secrets
- Azure Monitor Action Group deployed through Bicep
- failed-request Azure Monitor metric alert deployed through Bicep
- alert scoped to Application Insights request-failure telemetry
- `AlertEmail` stored in Azure Key Vault
- Azure DevOps service connection identity granted scoped `Key Vault Secrets User` access
- observability pipeline retrieves `AlertEmail` securely during What-If and deployment
- email value kept out of Git and pipeline logs
- Azure Monitor failed-request alert tested with deliberately generated failed requests
- Sev2 Azure Monitor alert successfully fired
- Action Group successfully delivered the alert notification by email
- CloudPlatformLab Management Group landing-zone hierarchy deployed
- `Platform` Management Group deployed
- `Connectivity` Management Group deployed beneath `Platform`
- `Management` Management Group deployed beneath `Platform`
- `Landing Zones` Management Group deployed
- `Dev` Management Group deployed beneath `Landing Zones`
- `Prod` Management Group deployed beneath `Landing Zones`
- CloudPlatformLab subscription placed beneath `Dev`
- custom `Environment` tag Azure Policy represented through Bicep
- policy assignment deployed at the `Landing Zones` Management Group
- policy inheritance validated at subscription scope
- obsolete direct Dev resource-group policy assignment removed
- governance Bicep structure cleaned after Management Group implementation
- obsolete subscription-governance pipeline stages removed
- independent governance Azure DevOps pipeline path
- `Microsoft.Authorization` governance readiness validation
- `Microsoft.PolicyInsights` governance readiness validation
- `Microsoft.Management` governance readiness validation
- Azure DevOps service connection authorized for implemented governance deployment
- Management Group hierarchy deployed through the controlled pipeline
- Landing Zone policy deployed through the controlled pipeline
- governance pipeline successfully rerun after cleanup
- real inherited Azure Policy compliance evaluation completed
- eight resources evaluated
- six resources confirmed compliant
- two non-compliant Azure-created/supporting resources identified
- resource-level policy compliance investigated rather than blindly remediated

Currently provisioned:

```text
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
        +-- Environment tag policy assignment
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
        |           +-- log-cloudplatformlab-dev
        |           |   Log Analytics Workspace
        |           |   30-day retention
        |           |
        |           +-- appi-cloudplatformlab-dev
        |           |   Application Insights
        |           |   linked to Log Analytics
        |           |   receiving application telemetry
        |           |   monitored for failed requests
        |           |
        |           +-- ag-cloudplatformlab-dev
        |           |   Azure Monitor Action Group
        |           |
        |           +-- alert-failed-requests-dev
        |           |   Azure Monitor metric alert
        |           |
        |           +-- kv-cloudplatformlab-dev
        |               Azure Key Vault
        |               Azure RBAC
        |               Soft delete
        |               90-day recovery period
        |               Purge protection
        |
        +-- Prod
```

A reusable custom Azure Policy definition audits resources missing the required `Environment` tag.

The policy is assigned at the `Landing Zones` Management Group and inherited by the Dev hierarchy rather than being directly assigned to `rg-cloudplatformlab-dev`.

Infrastructure defined but not currently provisioned:

- App Service Plan
- Products API App Service
- `dev` deployment slot

The App Service infrastructure has been validated through Bicep, but provisioning using the currently selected S1 SKU is blocked by the Azure subscription's App Service quota.

The App Service SKU is parameterised so the deployment architecture is not permanently tied to S1.

The App Service quota constraint does not prevent application integration, operational monitoring, networking or governance work from continuing.

The application currently consumes the real Dev Key Vault and Application Insights resources while running locally, Azure Monitor operates against that real telemetry, and inherited Azure Policy evaluates the deployed Dev resources independently of the application-hosting constraint.

In progress:

- repository cleanup and final documentation alignment
- automated application tests
- application deployment once suitable App Service capacity is available
- broader health monitoring where justified
- treatment of Azure-created resources that fall outside project tagging conventions

### Remaining Portfolio Build Work

Before stopping platform expansion and moving the primary focus to applications and interviews:

1. Private Endpoints and Private DNS
2. hub-spoke networking and VNet peering
3. network segmentation / NSGs where appropriate
4. meaningful Terraform implementation
5. Architecture Decision Records
6. final architecture diagram and README cleanup
7. lightweight resilience / disaster-recovery design
8. lightweight threat model

After these areas are complete, CloudPlatformLab will stop expanding for portfolio purposes.

The objective is to demonstrate platform-engineering and architecture ownership rather than build an arbitrary catalogue of Azure services.

---

## Implementation Evidence

Selected implementation evidence is stored in [`docs/evidence`](evidence/).

| Evidence | Demonstrates |
|---|---|
| [Pre-deployment quota gate](evidence/01-pre-deployment-validation-quota-gate.png) | Subscription readiness validation and fail-fast deployment control |
| [Bicep What-If](evidence/02-infrastructure-as-code-bicep-what-if.png) | Infrastructure as Code evaluated against Azure before deployment |
| [Dev deployment slot](evidence/03-deployment-slot-iac-bicep.png) | Deployment slot, managed identity, HTTPS/TLS and tagging represented through Bicep |
| [Manual Dev deployment gate](evidence/04-manual-dev-deployment-gate.png) | Controlled promotion into the Dev environment |
| [Networking deployment](evidence/05-networking-bicep-deployment-success.png) | Successful networking infrastructure deployment through the controlled Azure DevOps pipeline |
| [Deployed Virtual Network](evidence/06-networking-vnet-deployed-azure.png) | Azure Virtual Network successfully provisioned from Bicep |
| [Networking subnets](evidence/07-networking-subnets-deployed-azure.png) | Application and private endpoint subnet segmentation deployed in Azure |
| [Observability deployment pipeline](evidence/08-observability-deployment-pipeline.png) | Observability validation, readiness, What-If, approval and deployment through Azure DevOps |
| [Application Insights](evidence/09-application-insights-deployed.png) | Workspace-based Application Insights deployed and linked to Log Analytics |
| [Log Analytics workspace](evidence/10-log-analytics-workspace-deployed.png) | Central Log Analytics workspace successfully provisioned through Bicep |
| [Log Analytics retention](evidence/11-log-analytics-data-retention.png) | Explicit 30-day telemetry retention configuration for the Dev environment |
| [Key Vault deployment](evidence/12-key-vault-deployed-azure.png) | Azure Key Vault successfully provisioned in the Dev environment |
| [Key Vault security controls](evidence/13-key-vault-security-controls.png) | Soft delete, 90-day recovery protection, purge protection and project tagging |
| [Key Vault RBAC access model](evidence/14-key-vault-rbac-access-model.png) | Azure RBAC selected as the Key Vault permission model |
| [Key Vault application integration](evidence/15-key-vault-application-integration.png) | ASP.NET Core application successfully loading Key Vault configuration through Azure identity and RBAC without exposing the secret value |
| [Application Insights live telemetry](evidence/16-application-insights-live-telemetry.png) | Real telemetry from the running ASP.NET Core application received by the deployed Application Insights resource |
| [Application Insights request telemetry](evidence/17-application-insights-request-telemetry.png) | Individual application requests, including the Key Vault integration endpoint, captured and correlated in Application Insights |
| [Azure Monitor alert email fired](evidence/18-azure-monitor-alert-email-fired.png) | End-to-end operational notification from failed application request telemetry through Azure Monitor and the Action Group to email |
| [Azure Monitor alert fired](evidence/19-azure-monitor-alert-fired.png) | Fired Azure Monitor metric alert visible in Azure and scoped to the Application Insights failed-request signal |
| [Azure Policy Environment Tag Compliance](evidence/20-azure-policy-environment-tag-compliance.png) | Earlier resource-group-scoped Azure Policy compliance evidence captured before the Management Group governance expansion |
| [Azure Policy Resource-Level Compliance](evidence/21-azure-policy-resource-compliance.png) | Earlier resource-level Policy evaluation that informed the later Management Group governance design |
| [Management Group landing-zone hierarchy](evidence/22-management-group-landing-zone-hierarchy.png) | Deployed CloudPlatformLab hierarchy showing Platform, Landing Zones, Dev, Prod and the CloudPlatformLab subscription beneath Dev |
| [Management Group policy inheritance](evidence/23-management-group-policy-inheritance.png) | Subscription-level Policy view showing the Environment-tag policy inherited from the Landing Zones Management Group |
| [Management Group policy compliance](evidence/24-management-group-policy-compliance.png) | Inherited Management Group policy evaluation showing 8 resources evaluated, 6 compliant and 2 non-compliant |
| [Management Group policy resource compliance](evidence/25-management-group-policy-resource-compliance.png) | Resource-level inherited-policy results identifying compliant resources and Azure-created/supporting resources requiring governance review |
