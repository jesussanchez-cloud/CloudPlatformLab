# CloudPlatformLab

CloudPlatformLab is a production-oriented Azure platform engineering project demonstrating infrastructure as code, CI/CD, identity, security, networking, governance, observability and cost-aware cloud operations.

The application workload is intentionally simple. The engineering focus is the platform around it: reproducible infrastructure, secretless authentication, controlled deployments, environment validation and operational safeguards.

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
                +-------------+-------------+
                |             |             |
                v             v             v
          App Service     Networking   Observability
                |             |             |
                v             v             v
           Validation      Validation      Validation
                |             |             |
                v             v             v
            Readiness       Readiness       Readiness
                |             |             |
                v             v             v
             What-If         What-If         What-If
                |             |             |
                v             v             v
             Approval        Approval        Approval
                |             |             |
                v             v             v
            Deployment     Deployment     Deployment
            quota blocked      |             |
                               v             v
                         Virtual Network  Log Analytics
                                           |
                                           v
                                    Application Insights
```

The networking and observability foundations have been successfully deployed through their controlled pipeline paths.

The App Service infrastructure follows an independent deployment path. It is defined and validated through Bicep, but provisioning is currently blocked by a subscription-level App Service quota constraint.

Keeping the infrastructure paths independent allows one platform constraint to fail safely without unnecessarily preventing unrelated infrastructure from being validated or deployed.

> **App Service deployment status:** The App Service infrastructure is defined in Bicep and validated independently. Final provisioning using the currently selected S1 SKU is blocked by an App Service quota of `0`. See [Deployment Validation and Evidence](#deployment-validation-and-evidence).

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
- App Service infrastructure defined in Bicep
- `dev` deployment slot defined in Bicep
- system-assigned managed identity defined in Bicep
- App Service infrastructure validated through Bicep

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

The development infrastructure targets a dedicated resource group in UK South:

```text
rg-cloudplatformlab-dev
```

Bicep is kept in the repository alongside the application so infrastructure changes follow the same Git and pull request workflow as application changes.

Infrastructure is validated before deployment rather than relying on manually configured Azure resources.

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

The Dev environment now includes an observability foundation deployed through Bicep and the Azure DevOps pipeline.

The current observability infrastructure consists of:

- `log-cloudplatformlab-dev` — Log Analytics workspace
- `appi-cloudplatformlab-dev` — workspace-based Application Insights
- 30-day Log Analytics data retention

Application Insights is linked to the Log Analytics workspace so application telemetry can use the workspace as the central observability data store as the application deployment path develops.

```text
Application Insights
appi-cloudplatformlab-dev
          |
          v
Log Analytics Workspace
log-cloudplatformlab-dev
          |
          v
   30-day retention
```

Observability follows its own controlled deployment path:

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

The observability foundation has been successfully provisioned through this process.

Application telemetry integration, alerts, Action Groups, health monitoring and additional operational controls will be introduced as workloads requiring those capabilities are deployed.

---

## CI/CD

Azure DevOps is used for CI/CD.

Changes are developed using feature branches and merged into `Dev` through pull requests.

After the application build, infrastructure areas follow independent validation and deployment paths:

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
      +---------------------------+---------------------------+
      |                           |                           |
      v                           v                           v
App Service Path            Networking Path            Observability Path
      |                           |                           |
      v                           v                           v
Validation                  Validation                  Validation
      |                           |                           |
      v                           v                           v
Readiness                   Readiness                   Readiness
      |                           |                           |
      v                           v                           v
Bicep What-If               Bicep What-If               Bicep What-If
      |                           |                           |
      v                           v                           v
Manual Approval             Manual Approval             Manual Approval
      |                           |                           |
      v                           v                           v
Deployment                  Deployment                  Deployment
```

Separating infrastructure paths prevents an environmental constraint affecting one platform area from unnecessarily blocking another.

This is currently demonstrated by the App Service quota constraint: the App Service path can stop during readiness validation while networking and observability continue independently.

Bicep What-If runs before deployment so proposed infrastructure changes can be reviewed before anything is changed in Azure.

Infrastructure deployment uses an Azure DevOps Environment with an approval check, providing a control point between validating an infrastructure change and applying it.

---

## Deployment Validation and Evidence

The infrastructure deployment workflow is implemented through Azure DevOps and Bicep.

The pipeline currently provides:

- .NET 8 restore and build
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

The independent pipeline architecture means this constraint does not prevent networking or observability infrastructure from being validated and deployed.

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

### Evidence

Pipeline and IaC evidence is available in [`docs/evidence`](docs/evidence/):

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

Additional architectural decisions and implementation details are documented in [`docs/architecture.md`](docs/architecture.md).

---

## Identity & Security

The Azure DevOps pipeline connects to Azure using Workload Identity Federation.

This allows the pipeline to authenticate to Azure without storing a long-lived client secret in the repository or pipeline configuration.

The App Service definition also includes a system-assigned managed identity. As dependent Azure services are introduced, managed identity will be preferred where supported instead of application credentials.

Security controls currently implemented or represented in the deployment architecture include:

- Workload Identity Federation
- system-assigned Managed Identity
- HTTPS-only App Service configuration
- TLS 1.2 minimum
- Azure RBAC
- controlled Azure DevOps service connection
- manual deployment approval
- infrastructure readiness validation

Secrets and credentials are not stored in the repository.

Key Vault, Azure Policy, private connectivity and additional security controls form part of the target architecture and will be introduced where they support a concrete platform requirement.

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

As telemetry sources are introduced, ingestion volume and retention will be reviewed as part of the platform's cost controls.

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

Infrastructure, pipeline and documentation changes normally go through feature branches and pull requests rather than being changed directly on `Dev`.

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
|       +-- main.bicep
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

The networking and observability foundations and independent infrastructure deployment paths are now implemented and validated through the Dev pipeline.

The next phase will extend the platform with additional security, operational and private-connectivity capabilities.

Current priorities are:

- add automated application tests
- integrate application telemetry with Application Insights when the application deployment path is operational
- introduce Azure Monitor alerts and Action Groups
- add Key Vault and managed-identity based access where required
- introduce Private Endpoints and Private DNS as dependent platform services are added
- extend governance with Azure Policy
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
- Workload Identity Federation
- Managed Identity
- Bicep
- Bicep What-If
- Azure CLI
- ASP.NET Core
- .NET 8
- Git
- GitHub
- Azure Virtual Network
- Azure Subnets
- Application Insights
- Log Analytics

### Defined / In Progress

- Azure App Service
- App Service Deployment Slots

### Planned

- Terraform
- Azure Key Vault
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
