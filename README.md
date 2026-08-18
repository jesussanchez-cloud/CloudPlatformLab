# CloudPlatformLab

CloudPlatformLab is a production-oriented Azure platform engineering project demonstrating infrastructure as code, CI/CD, identity, security, networking, governance, observability and cost-aware cloud operations.

The application workload is intentionally simple. The engineering focus is the platform around it: reproducible infrastructure, secretless authentication, controlled deployments, environment validation, application-to-platform integration and operational safeguards.

The platform is being developed incrementally, with implemented capabilities separated from the target architecture so that architectural decisions, deployment controls and operational behaviour can be validated and documented as the platform evolves.

---

## Architecture

The platform is built as independently deployable infrastructure areas, with infrastructure defined in Bicep and validated and deployed through Azure DevOps.

```text
                              Azure DevOps
                                   |
                                   v
                            Build Application
                                   |
             +---------------------+---------------------+
             |                     |                     |
             v                     v                     v
       App Service             Networking          Observability
             |                     |                     |
             |                     |                     |
             +----------+----------+----------+----------+
                        |                     |
                        |                     v
                        |                  Security
                        |
              Each infrastructure path
                        |
                        v
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

The networking, observability and security foundations have been successfully deployed through their controlled pipeline paths.

The application is now also integrated with deployed platform services during local development:

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
        v                               v
Azure RBAC                    Log Analytics Workspace
        |
        v
Azure Key Vault
```

The local application authenticates to Azure through `DefaultAzureCredential` and the developer's Azure identity, allowing Key Vault integration to be validated without storing credentials in source control.

Application Insights is also connected to the running application, and real request telemetry has been verified in Azure.

The App Service infrastructure follows an independent deployment path. It is defined and validated through Bicep, but provisioning is currently blocked by a subscription-level App Service quota constraint.

Keeping the infrastructure paths independent allows one platform constraint to fail safely without unnecessarily preventing unrelated infrastructure from being validated or deployed.

The Azure DevOps pipeline has also been modularised into reusable YAML stage templates so that each infrastructure domain can evolve independently without turning the root pipeline into a large monolithic definition.

> **App Service deployment status:** The App Service infrastructure is defined in Bicep and validated independently. Final provisioning using the currently selected S1 SKU is blocked by an App Service quota of `0`. Application-to-platform integrations are therefore being validated locally first, using the same Azure services that will later support the deployed workload.

---

## Target Architecture

The project is being built towards a broader Azure platform architecture.

Not everything below is implemented yet. Components are added where they demonstrate a useful cloud/platform engineering pattern rather than simply increasing the number of Azure services in the project.

### Identity & Security

- Microsoft Entra ID
- Managed Identities
- Azure Key Vault
- Azure RBAC
- Azure Policy
- Defender for Cloud
- Private Endpoints

### Networking

- Hub-spoke virtual network
- VNet Peering
- Private DNS
- Private connectivity to platform services

### Application Platform

- ASP.NET Core .NET 8
- Azure App Service
- Deployment Slots

### Data

- Azure SQL
- Azure Storage
- Cosmos DB where appropriate

### Messaging

- Azure Service Bus for asynchronous messaging
- Azure Event Grid for event distribution

### Observability

- Azure Monitor
- Application Insights
- Log Analytics
- Alerts
- Action Groups
- Health checks

### Infrastructure & DevOps

- Bicep
- Terraform
- Azure DevOps
- Azure Repos
- GitHub
- CI/CD
- Reusable pipeline templates
- Automated testing

### Governance & FinOps

- Management Groups
- Azure Policy
- Azure RBAC
- Resource tagging
- Azure Cost Management
- Budgets and cost alerts
- Non-production cost controls
- Cost optimisation

---

## Current Implementation

The following sections describe capabilities that have actually been implemented or validated so far.

### Application

The current workload is an ASP.NET Core .NET 8 application containing a simple Products API.

The application is deliberately small because the engineering focus is the Azure platform and deployment architecture rather than application complexity.

Currently implemented:

- ASP.NET Core .NET 8 application
- Products API
- Azure Key Vault configuration integration
- `DefaultAzureCredential` authentication for local Azure access
- Key Vault integration verification endpoint
- Application Insights SDK integration
- real application request telemetry sent to Azure
- App Service infrastructure defined in Bicep
- `dev` deployment slot defined in Bicep
- system-assigned managed identity defined in Bicep
- App Service infrastructure validated through Bicep

The application currently validates platform integrations locally while App Service provisioning remains unavailable because of the subscription quota constraint.

Local development configuration uses .NET User Secrets where appropriate so Azure configuration values are not committed to source control.

---

## Infrastructure as Code

Azure infrastructure is defined using Bicep and separated by platform concern.

Current infrastructure definitions include:

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
    +-- main.bicep
```

The App Service template defines:

- configurable App Service Plan SKU
- App Service
- `dev` deployment slot
- system-assigned managed identity
- HTTPS-only configuration
- TLS 1.2 minimum
- resource tags

The networking template defines the Dev virtual network and subnet foundation.

The observability template defines the Log Analytics workspace and workspace-based Application Insights resource.

The security template defines the Dev Key Vault and its baseline protection configuration.

The development infrastructure targets a dedicated resource group in UK South:

```text
rg-cloudplatformlab-dev
```

Bicep is kept in the repository alongside the application so infrastructure changes follow the same Git and pull request workflow as application changes.

Infrastructure is validated before deployment rather than relying on manually configured Azure resources.

Repeated deployments converge Azure towards the state declared in Bicep, allowing existing resources to remain in place while new or modified infrastructure is applied through the same controlled deployment paths.

---

## Networking

The Dev environment includes a networking foundation deployed through Bicep and the Azure DevOps pipeline.

The current networking infrastructure consists of:

- `vnet-cloudplatformlab-dev`
- `snet-app` — `10.10.1.0/24`
- `snet-private-endpoints` — `10.10.2.0/24`

Networking changes follow a controlled deployment process:

```text
Networking Bicep
      |
      v
Validation
      |
      v
Readiness Checks
      |
      v
Bicep What-If
      |
      v
Manual Approval
      |
      v
Networking Deployment
```

The networking readiness stage verifies that the `Microsoft.Network` resource provider is registered and that the target resource group exists before the What-If and deployment stages are allowed to proceed.

The separate application and private endpoint subnets provide the initial network segmentation for the platform. The `snet-private-endpoints` subnet is reserved for private connectivity as services requiring Private Endpoints are introduced later.

Hub-spoke networking, VNet peering, Private DNS and Private Endpoints remain part of the target architecture and have not yet been implemented.

---

## Observability

The Dev environment includes an observability foundation deployed through Bicep and the Azure DevOps pipeline.

The current observability infrastructure consists of:

- `log-cloudplatformlab-dev` — Log Analytics workspace
- `appi-cloudplatformlab-dev` — workspace-based Application Insights
- 30-day Log Analytics data retention
- ASP.NET Core Application Insights SDK integration
- verified application request telemetry

Application Insights is linked to the Log Analytics workspace, providing a central observability data store for application telemetry.

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
          v
log-cloudplatformlab-dev
Log Analytics Workspace
          |
          v
   30-day retention
```

The application has been configured to send telemetry to the deployed Application Insights resource.

Real request telemetry has been verified in Azure, including requests to the Key Vault integration verification endpoint.

The Application Insights connection string is supplied through local development configuration rather than being committed to source control. Application Insights registration is conditional so environments without telemetry configuration can still run the application.

Observability infrastructure follows its own controlled deployment path:

```text
Observability Bicep
      |
      v
Validation
      |
      v
Readiness Checks
      |
      v
Bicep What-If
      |
      v
Manual Approval
      |
      v
Observability Deployment
```

The readiness stage validates the required Azure resource providers and target resource group before the deployment path continues.

The observability foundation and initial application telemetry integration have now both been successfully validated.

Azure Monitor alerts, Action Groups, health monitoring and additional operational controls will be introduced as the platform develops.

---

## Identity & Security

The Dev environment includes a security foundation deployed through Bicep and its own controlled Azure DevOps pipeline path.

The current security infrastructure includes:

- `kv-cloudplatformlab-dev` — Azure Key Vault
- Azure RBAC permission model
- soft delete enabled
- 90-day soft-delete retention
- purge protection enabled
- standard project tagging

The Key Vault uses the Azure RBAC authorization model rather than legacy vault access policies.

```text
Azure DevOps
     |
     v
Security Bicep
     |
     v
Validation
     |
     v
Readiness Checks
     |
     v
Bicep What-If
     |
     v
Manual Approval
     |
     v
kv-cloudplatformlab-dev
     |
     +-- Azure RBAC
     +-- Soft Delete
     +-- Purge Protection
```

The security readiness stage verifies that the `Microsoft.KeyVault` resource provider is registered and that the target resource group exists before deployment continues.

Azure DevOps authenticates to Azure using Workload Identity Federation, avoiding a long-lived client secret in the repository or pipeline configuration.

### Application-to-Key-Vault Integration

The ASP.NET Core application is now integrated with the deployed Key Vault.

During local development, the application uses `DefaultAzureCredential`, which resolves the authenticated developer identity and uses Microsoft Entra ID and Azure RBAC to access Key Vault.

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

A test secret is successfully loaded into .NET configuration from Key Vault.

The `/health/keyvault` verification endpoint confirms that the configuration value was loaded without returning or logging the secret itself.

This provides a working application-to-platform integration while the App Service deployment path remains quota constrained.

When App Service becomes operational, the intended authentication path is:

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

This allows the application code to move from a developer identity during local development to a workload identity in Azure without introducing application credentials.

Security controls currently implemented or represented in the platform include:

- Workload Identity Federation
- Azure Key Vault
- Azure RBAC Key Vault authorization
- Key Vault soft delete
- Key Vault purge protection
- application Key Vault integration
- `DefaultAzureCredential`
- system-assigned Managed Identity defined for App Service
- HTTPS-only App Service configuration
- TLS 1.2 minimum
- Azure RBAC
- controlled Azure DevOps service connection
- manual infrastructure deployment approval
- infrastructure readiness validation
- secrets excluded from source control

Key Vault private connectivity, Azure Policy and additional security controls will be introduced as the dependent platform capabilities are implemented.

---

## CI/CD

Azure DevOps is used for CI/CD.

Changes are developed using feature branches and merged into `Dev` through pull requests.

As the number of independently deployable platform areas increased, the pipeline was refactored from a single large YAML definition into a small orchestration pipeline backed by reusable stage templates.

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
```

The root pipeline contains the application build and orchestrates the infrastructure templates.

Each infrastructure domain retains its own controlled lifecycle:

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
Restore & Build
      |
      +---------------+---------------+---------------+
      |               |               |               |
      v               v               v               v
 App Service      Networking     Observability      Security
      |               |               |               |
      v               v               v               v
 Validation      Validation      Validation      Validation
      |               |               |               |
      v               v               v               v
 Readiness       Readiness       Readiness       Readiness
      |               |               |               |
      v               v               v               v
  What-If         What-If         What-If         What-If
      |               |               |               |
      v               v               v               v
 Approval         Approval         Approval         Approval
      |               |               |               |
      v               v               v               v
Deployment       Deployment      Deployment      Deployment
```

Separating infrastructure paths prevents an environmental constraint affecting one platform area from unnecessarily blocking another.

This is currently demonstrated by the App Service quota constraint: the App Service path can stop during readiness validation while networking, observability and security continue independently.

Bicep What-If runs before deployment so proposed infrastructure changes can be reviewed before anything is changed in Azure.

Infrastructure deployment uses an Azure DevOps Environment with an approval check, providing a control point between validating an infrastructure change and applying it.

The reusable template structure also reduces YAML duplication and provides a cleaner path for adding additional platform domains as the project grows.

---

## Deployment Validation and Evidence

The infrastructure deployment workflow is implemented through Azure DevOps and Bicep.

The pipeline currently provides:

- .NET 8 restore and build
- modular reusable YAML stage templates
- independent infrastructure validation paths
- Azure subscription and deployment readiness checks
- resource-provider validation
- App Service SKU quota validation
- Bicep validation
- Bicep What-If before deployment
- Azure DevOps Environment approval
- Bicep resource-group deployment
- Azure authentication through Workload Identity Federation

### App Service deployment constraint

App Service provisioning using the currently selected S1 SKU is blocked by an Azure subscription-level quota of `0`.

Rather than bypassing the deployment controls or manually creating resources, the App Service readiness stage detects this condition and stops its deployment path.

This is an Azure subscription constraint rather than a Bicep validation failure.

The App Service SKU is parameterised so the infrastructure architecture is not permanently tied to S1.

The independent pipeline architecture means this constraint does not prevent networking, observability or security infrastructure from being validated and deployed.

Application integrations are being validated locally against the deployed Azure platform services while this constraint remains in place.

### Successfully deployed infrastructure

The networking deployment path has successfully provisioned:

- `vnet-cloudplatformlab-dev`
- `snet-app`
- `snet-private-endpoints`

The observability deployment path has successfully provisioned:

- `log-cloudplatformlab-dev`
- `appi-cloudplatformlab-dev`
- workspace-based Application Insights integration
- 30-day Log Analytics retention

The security deployment path has successfully provisioned:

- `kv-cloudplatformlab-dev`
- Azure RBAC authorization model
- soft delete
- 90-day soft-delete retention
- purge protection

Application-level validation has additionally demonstrated:

- authenticated Key Vault access from the ASP.NET Core application
- Key Vault configuration loading without exposing secret values
- real ASP.NET Core request telemetry reaching Application Insights
- individual application requests visible in Azure telemetry

### Evidence

Pipeline, IaC and runtime integration evidence is available in [`docs/evidence`](docs/evidence/):

- [Pre-deployment quota gate](docs/evidence/01-pre-deployment-validation-quota-gate.png)
- [Bicep Infrastructure as Code What-If](docs/evidence/02-infrastructure-as-code-bicep-what-if.png)
- [Dev deployment slot defined through Bicep](docs/evidence/03-deployment-slot-iac-bicep.png)
- [Manual Dev deployment gate](docs/evidence/04-manual-dev-deployment-gate.png)
- [Networking Bicep deployment](docs/evidence/05-networking-bicep-deployment-success.png)
- [Deployed Azure Virtual Network](docs/evidence/06-networking-vnet-deployed-azure.png)
- [Deployed networking subnets](docs/evidence/07-networking-subnets-deployed-azure.png)
- [Observability deployment pipeline](docs/evidence/08-observability-deployment-pipeline.png)
- [Application Insights deployed and linked to Log Analytics](docs/evidence/09-application-insights-deployed.png)
- [Log Analytics workspace deployed](docs/evidence/10-log-analytics-workspace-deployed.png)
- [Log Analytics 30-day data retention](docs/evidence/11-log-analytics-data-retention.png)
- [Key Vault deployed in Azure](docs/evidence/12-key-vault-deployed-azure.png)
- [Key Vault security controls](docs/evidence/13-key-vault-security-controls.png)
- [Key Vault RBAC access model](docs/evidence/14-key-vault-rbac-access-model.png)
- [Key Vault application integration](docs/evidence/15-key-vault-application-integration.png)
- [Application Insights live telemetry](docs/evidence/16-application-insights-live-telemetry.png)
- [Application Insights request telemetry](docs/evidence/17-application-insights-request-telemetry.png)

Additional architectural decisions and implementation details are documented in [`docs/architecture.md`](docs/architecture.md).

---

## Resource Organisation

Development resources target:

```text
rg-cloudplatformlab-dev
```

Resources are tagged to make their purpose and ownership easier to identify and to support cost reporting and governance.

Current tags include:

```text
Project       = CloudPlatformLab
Environment   = Dev
ManagedBy     = Bicep
CostCenter    = CloudPlatformLab
```

The same tagging approach can later be enforced through Azure Policy as the governance layer develops.

---

## Cost Management

Cost management is treated as part of the platform design rather than as a separate administrative task.

Because this is a personal lab environment, paid Azure resources do not need to remain online when they are not being actively used.

Before deploying paid infrastructure:

1. Run Bicep What-If.
2. Review the proposed resource changes.
3. Check the expected Azure cost.
4. Validate subscription prerequisites.
5. Manually approve the deployment.
6. Validate the deployed infrastructure.
7. Remove paid resources when they are no longer required.

The Log Analytics workspace currently uses a 30-day retention period to provide an observability foundation while keeping data retention appropriate for a development environment.

Application telemetry is now being generated, so ingestion volume and retention can be reviewed against actual workload telemetry as part of the platform's cost controls.

Because the environment is defined as code, resources can be destroyed when they are not needed and recreated later from Bicep.

This also tests infrastructure reproducibility rather than relying on resources that were configured manually and left running indefinitely.

---

## Git Workflow

Azure Repos is used for the main development and pull request workflow.

GitHub is maintained as the public repository for the project.

The normal workflow is:

```text
feature/*
    |
    v
Pull Request
    |
    v
Dev
    |
    v
Build and Infrastructure Validation
    |
    v
Controlled Dev Deployment
```

Infrastructure, pipeline, application integration and documentation changes normally go through feature branches and pull requests rather than being changed directly on `Dev`.

Feature-branch pipeline runs are used to validate infrastructure and pipeline behaviour before changes are merged. Dev environment deployments are performed from the merged `Dev` branch.

After changes are merged, the public GitHub repository is synchronized with the Azure Repos version.

---

## Repository Structure

```text
CloudPlatformLab
|
+-- src
|   +-- CloudPlatformLab.Web
|   +-- CloudPlatformLab.Application
|
+-- infra
|   +-- appservice
|   |   +-- main.bicep
|   |
|   +-- networking
|   |   +-- main.bicep
|   |
|   +-- observability
|   |   +-- main.bicep
|   |
|   +-- security
|       +-- main.bicep
|
+-- pipelines
|   +-- templates
|       +-- appservice.yml
|       +-- networking.yml
|       +-- observability.yml
|       +-- security.yml
|
+-- tests
|
+-- docs
|   +-- architecture.md
|   +-- evidence
|
+-- azure-pipelines.yml
|
+-- CloudPlatformLab.sln
|
+-- README.md
```

The `tests` area is currently being prepared. Genuine automated tests will be added as the deployment workflow develops.

---

## Deployment Strategy

Infrastructure areas are independently validated and deployed so that unrelated platform constraints do not block one another.

For the application platform, the intended deployment architecture uses one App Service with a development deployment slot.

```text
Dev branch
     |
     v
Azure DevOps Pipeline
     |
     v
dev deployment slot
     |
     v
Validation
     |
     v
Production
```

The intended promotion path validates application changes in the `dev` slot before promoting them to the main production App Service.

Deployment slot swapping and rollback can then provide controlled promotion and recovery once the application deployment path is operational.

While App Service provisioning remains quota constrained, application integration with Key Vault and Application Insights is validated locally against the real deployed Azure services.

This allows application-to-platform behaviour to be developed and evidenced independently of the App Service capacity constraint.

---

## Landing Zone and Governance

A later phase will extend the project from workload-level infrastructure into a small enterprise-style governance model.

The target model explores a structure such as:

```text
Tenant Root
     |
     +-- CloudPlatformLab
           |
           +-- Platform
           |     |
           |     +-- Connectivity
           |     +-- Management
           |
           +-- Landing Zones
                 |
                 +-- Dev
                 +-- Prod
```

This architecture will be used to explore:

- Management Groups
- subscription organisation
- Azure Policy
- RBAC
- governance inheritance
- budgets and cost controls
- networking
- platform security

The objective is not to create unnecessary paid resources or subscriptions simply to reproduce the size of an enterprise environment.

Where appropriate, the project will implement a smaller working example and document how the same design would scale in a production environment.

---

## Bicep and Terraform

Bicep is currently used for Azure workload infrastructure.

Terraform will be introduced later for selected infrastructure.

The intention is not to maintain two identical implementations of every resource. The project will use both tools where they demonstrate useful infrastructure patterns and the differences between Azure-native IaC and a provider-based IaC workflow.

---

## Current Work

The networking, observability and security foundations are deployed and independently managed through reusable Azure DevOps pipeline templates.

The application now consumes the security and observability foundations rather than those services existing only as isolated infrastructure:

- Key Vault configuration retrieval has been validated from the ASP.NET Core application.
- Application Insights is receiving real application request telemetry.
- Application-to-Azure authentication is being validated locally through `DefaultAzureCredential`.
- The future App Service workload identity path is already represented through the system-assigned managed identity defined in Bicep.

The next phase will extend the platform into governance, operational controls and private-connectivity capabilities while continuing to build application and platform maturity.

Current priorities are:

- introduce Azure Policy and governance controls
- add automated application tests
- introduce Azure Monitor alerts and Action Groups
- add application health monitoring
- transition Key Vault authentication to App Service managed identity when the application platform becomes deployable
- introduce Private Endpoints and Private DNS for appropriate platform services
- introduce Terraform for selected infrastructure
- develop the landing zone and governance model

The architecture and documentation will continue to evolve alongside implemented capabilities.

---

## Technologies

### Currently Used

- Microsoft Azure
- Microsoft Entra ID
- Azure DevOps
- Azure Repos
- Azure Pipelines
- Azure DevOps Environments
- Reusable Azure Pipelines YAML templates
- Workload Identity Federation
- Managed Identity
- DefaultAzureCredential
- Azure Key Vault
- Azure RBAC
- Bicep
- Bicep What-If
- Azure CLI
- ASP.NET Core
- .NET 8
- .NET User Secrets
- Git
- GitHub
- Azure Virtual Network
- Azure Subnets
- Application Insights
- Application Insights SDK
- Log Analytics

### Defined / In Progress

- Azure App Service
- App Service Deployment Slots

### Planned

- Terraform
- Azure Policy
- Azure Monitor alerts
- Action Groups
- Azure SQL
- Azure Storage
- Azure Service Bus
- Azure Event Grid
- Private Endpoints
- Private DNS
- Hub-spoke networking
- Management Groups
- Landing Zone governance
- Defender for Cloud