# CloudPlatformLab

CloudPlatformLab is a production-oriented Azure platform engineering project demonstrating infrastructure as code, CI/CD, identity, security, networking, governance, observability and cost-aware cloud operations.

The application workload is intentionally simple. The engineering focus is the platform around it: reproducible infrastructure, secretless authentication, controlled deployments, environment validation, application-to-platform integration and operational safeguards.

The platform is being developed incrementally, with implemented capabilities separated from the target architecture so that architectural decisions, deployment controls and operational behaviour can be validated and documented as the platform evolves.

---

## Architecture

The platform is built as independently deployable infrastructure areas, with infrastructure defined in Bicep and validated and deployed through Azure DevOps.

    Azure DevOps
         |
         v
    Build Application
         |
         +----------------+----------------+----------------+
         |                |                |                |
         v                v                v                v
    App Service       Networking      Observability      Security
         |                |                |                |
         v                v                v                v
    Validation       Validation       Validation       Validation
         |                |                |                |
         v                v                v                v
    Readiness        Readiness        Readiness        Readiness
         |                |                |                |
         v                v                v                v
     What-If          What-If          What-If          What-If
         |                |                |                |
         v                v                v                v
     Approval         Approval         Approval         Approval
         |                |                |                |
         v                v                v                v
    Deployment       Deployment       Deployment       Deployment

The networking, observability and security foundations have been successfully deployed through their controlled pipeline paths.

The application is also integrated with deployed platform services during local development:

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
            v                     +---------+---------+
       Azure RBAC                |                   |
            |                    v                   v
            v              Log Analytics      Failed Requests
      Azure Key Vault                                |
                                                     v
                                             Azure Monitor Alert
                                                     |
                                                     v
                                                Action Group
                                                     |
                                                     v
                                             Email Notification

The local application authenticates to Azure through `DefaultAzureCredential` and the developer's Azure identity, allowing Key Vault integration to be validated without storing credentials in source control.

Application Insights is connected to the running application, and real request telemetry has been verified in Azure.

Azure Monitor alerting is also operational. Failed application requests are evaluated by a metric alert scoped to Application Insights. When the configured threshold is exceeded, the alert triggers an Azure Monitor Action Group that sends an email notification.

This monitoring path has been validated end-to-end by deliberately generating failed application requests, confirming that the Azure Monitor alert entered the fired state and verifying delivery of the Action Group email notification.

The App Service infrastructure follows an independent deployment path. It is defined and validated through Bicep, but provisioning is currently blocked by a subscription-level App Service quota constraint.

Keeping the infrastructure paths independent allows one platform constraint to fail safely without unnecessarily preventing unrelated infrastructure from being validated or deployed.

The Azure DevOps pipeline has been modularised into reusable YAML stage templates so that each infrastructure domain can evolve independently without turning the root pipeline into a large monolithic definition.

> **App Service deployment status:** The App Service infrastructure is defined in Bicep and validated independently. Final provisioning using the currently selected S1 SKU is blocked by an App Service quota of `0`. Application-to-platform integrations and operational monitoring are being validated against the real deployed Azure services independently of this capacity constraint.

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

- Azure Cosmos DB
- Azure SQL where appropriate
- Azure Storage

### Messaging

- Azure Service Bus for asynchronous messaging
- Azure Event Grid for event distribution

### API Platform

- Azure API Management
- API policies
- throttling / rate limiting
- authentication and authorization
- API versioning
- API observability

### Containers

- Azure Container Registry
- Azure Container Apps
- managed identity
- container deployment through CI/CD
- container observability and scaling

### Observability

- Azure Monitor
- Application Insights
- Log Analytics
- Metric alerts
- Action Groups
- Health checks
- Operational notifications

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
- failed-request telemetry used for Azure Monitor alerting
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
- failed-request Azure Monitor metric alert
- secure Action Group email parameter
- common resource tags

The security template defines:

- Azure Key Vault
- Azure RBAC authorization model
- soft delete
- 90-day soft-delete retention
- purge protection
- common resource tags

The development infrastructure targets a dedicated resource group in UK South:

    rg-cloudplatformlab-dev

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

The networking readiness stage verifies that the `Microsoft.Network` resource provider is registered and that the target resource group exists before the What-If and deployment stages are allowed to proceed.

The separate application and private endpoint subnets provide the initial network segmentation for the platform. The `snet-private-endpoints` subnet is reserved for private connectivity as services requiring Private Endpoints are introduced later.

Hub-spoke networking, VNet peering, Private DNS and Private Endpoints remain part of the target architecture and have not yet been implemented.

---

## Observability

The Dev environment includes an observability foundation deployed through Bicep and the Azure DevOps pipeline.

The current observability infrastructure consists of:

- `log-cloudplatformlab-dev` — Log Analytics workspace
- `appi-cloudplatformlab-dev` — workspace-based Application Insights
- `ag-cloudplatformlab-dev` — Azure Monitor Action Group
- `alert-failed-requests-dev` — Azure Monitor metric alert
- 30-day Log Analytics data retention
- ASP.NET Core Application Insights SDK integration
- verified application request telemetry
- failed-request monitoring
- automated email notification

Application Insights is linked to the Log Analytics workspace, providing a central observability data store for application telemetry.

    ASP.NET Core Application
              |
              v
    Application Insights SDK
              |
              v
    appi-cloudplatformlab-dev
    Application Insights
              |
              +-----------------------------+
              |                             |
              v                             v
    log-cloudplatformlab-dev        Failed Request Metric
    Log Analytics Workspace                 |
              |                              v
              v                     Azure Monitor Alert
       30-day retention             alert-failed-requests-dev
                                             |
                                             v
                                   ag-cloudplatformlab-dev
                                       Action Group
                                             |
                                             v
                                    Email Notification

The application has been configured to send telemetry to the deployed Application Insights resource.

Real request telemetry has been verified in Azure, including requests to the Key Vault integration verification endpoint.

The Application Insights connection string is supplied through local development configuration rather than being committed to source control. Application Insights registration is conditional so environments without telemetry configuration can still run the application.

### Azure Monitor Alerting

The observability platform monitors failed Application Insights requests through an Azure Monitor metric alert.

The alert and Action Group are defined through Bicep and deployed through the controlled observability pipeline.

The Action Group notification address is not hardcoded in the repository. Instead, the email address is stored in Azure Key Vault as:

    AlertEmail

During the observability What-If and deployment stages, the Azure DevOps service connection retrieves `AlertEmail` from Key Vault and supplies it to the Bicep deployment as a secure parameter.

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

The service connection identity has scoped `Key Vault Secrets User` access to the Key Vault.

The retrieved email value is not printed to pipeline logs.

This allows environment-specific notification configuration to remain outside the public repository while keeping the monitoring infrastructure reproducible through Bicep.

The monitoring path has been validated end-to-end.

Failed application requests were deliberately generated, telemetry was received by Application Insights, `alert-failed-requests-dev` entered the fired state, and the Action Group successfully delivered an Azure Monitor Sev2 alert notification by email.

The Log Analytics workspace currently uses 30-day retention. This provides sufficient retention for a development environment while limiting unnecessary long-term data retention and associated cost.

Additional health monitoring and operational controls will be introduced where they provide useful platform behaviour.

---

## Identity & Security

The Dev environment includes a security foundation deployed through Bicep and its own controlled Azure DevOps pipeline path.

The current security infrastructure includes:

- `kv-cloudplatformlab-dev` — Azure Key Vault
- Azure RBAC permission model
- soft delete enabled
- 90-day soft-delete retention
- purge protection enabled
- application configuration
- `AlertEmail` deployment configuration
- standard project tagging

The Key Vault uses the Azure RBAC authorization model rather than legacy vault access policies.

Azure DevOps authenticates to Azure using Workload Identity Federation, avoiding a long-lived client secret in the repository or pipeline configuration.

### Application-to-Key-Vault Integration

The ASP.NET Core application is integrated with the deployed Key Vault.

During local development, the application uses `DefaultAzureCredential`, which resolves the authenticated developer identity and uses Microsoft Entra ID and Azure RBAC to access Key Vault.

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

A test secret is successfully loaded into .NET configuration from Key Vault.

The `/health/keyvault` verification endpoint confirms that the configuration value was loaded without returning or logging the secret itself.

When App Service becomes operational, the intended authentication path is:

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

This allows the application code to move from a developer identity during local development to a workload identity in Azure without introducing application credentials.

### Pipeline-to-Key-Vault Integration

Key Vault is also used for deployment-time configuration.

The observability pipeline requires the Action Group notification address during What-If and deployment.

Rather than storing this value in the repository or as a hardcoded YAML value, the existing Azure DevOps Workload Identity Federation service connection retrieves `AlertEmail` from Key Vault.

The service connection identity is granted scoped `Key Vault Secrets User` access, and the value is supplied to the observability Bicep deployment as a secure parameter.

This extends the project's identity-first approach beyond application runtime authentication to deployment-time configuration retrieval.

Security controls currently implemented or represented in the platform include:

- Workload Identity Federation
- Azure Key Vault
- Azure RBAC Key Vault authorization
- Key Vault soft delete
- Key Vault purge protection
- application Key Vault integration
- `DefaultAzureCredential`
- developer authentication through Microsoft Entra ID
- system-assigned Managed Identity defined for App Service
- scoped `Key Vault Secrets User` access for the Azure DevOps service connection identity
- deployment-time configuration retrieval from Key Vault
- monitoring notification email excluded from source control
- HTTPS-only App Service configuration
- TLS 1.2 minimum
- Azure RBAC
- controlled Azure DevOps service connection
- manual infrastructure deployment approval
- infrastructure readiness validation
- secrets and environment-specific values excluded from source control

Key Vault private connectivity, Azure Policy and additional security controls will be introduced as the dependent platform capabilities are implemented.

---

## CI/CD

Azure DevOps is used for CI/CD.

Changes are developed using feature branches and merged into `Dev` through pull requests.

As the number of independently deployable platform areas increased, the pipeline was refactored from a single large YAML definition into a small orchestration pipeline backed by reusable stage templates.

    azure-pipelines.yml
            |
            +-- pipelines/templates/appservice.yml
            |
            +-- pipelines/templates/networking.yml
            |
            +-- pipelines/templates/observability.yml
            |
            +-- pipelines/templates/security.yml

The root pipeline contains the application build and orchestrates the infrastructure templates.

Each infrastructure domain retains its own controlled lifecycle:

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

Separating infrastructure paths prevents an environmental constraint affecting one platform area from unnecessarily blocking another.

This is currently demonstrated by the App Service quota constraint: the App Service path can stop during readiness validation while networking, observability and security continue independently.

Bicep What-If runs before deployment so proposed infrastructure changes can be reviewed before anything is changed in Azure.

Infrastructure deployment uses an Azure DevOps Environment with an approval check, providing a control point between validating an infrastructure change and applying it.

The observability pipeline additionally retrieves the `AlertEmail` value from Azure Key Vault during What-If and deployment.

The Azure DevOps service connection identity is authorized through Azure RBAC with the scoped `Key Vault Secrets User` role. The retrieved value is supplied to the Bicep deployment as a secure parameter rather than being stored in the repository.

The reusable template structure reduces YAML duplication and provides a cleaner path for adding additional platform domains as the project grows.

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
- deployment-time Key Vault configuration retrieval for observability
- secure parameter handling for the Action Group notification address

### App Service deployment constraint

App Service provisioning using the currently selected S1 SKU is blocked by an Azure subscription-level quota of `0`.

Rather than bypassing the deployment controls or manually creating resources, the App Service readiness stage detects this condition and stops its deployment path.

This is an Azure subscription constraint rather than a Bicep validation failure.

The App Service SKU is parameterised so the infrastructure architecture is not permanently tied to S1.

The independent pipeline architecture means this constraint does not prevent networking, observability or security infrastructure from being validated and deployed.

Application integrations and operational monitoring are being validated against the deployed Azure platform services while this constraint remains in place.

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
- `ag-cloudplatformlab-dev` Action Group
- `alert-failed-requests-dev` Azure Monitor metric alert

The security deployment path has successfully provisioned:

- `kv-cloudplatformlab-dev`
- Azure RBAC authorization model
- soft delete
- 90-day soft-delete retention
- purge protection

Application and operational validation has additionally demonstrated:

- authenticated Key Vault access from the ASP.NET Core application
- Key Vault configuration loading without exposing secret values
- real ASP.NET Core request telemetry reaching Application Insights
- individual application requests visible in Azure telemetry
- failed application requests captured by Application Insights
- failed-request metric evaluation by Azure Monitor
- Azure Monitor alert entering the fired state
- Action Group email notification delivered successfully
- deployment-time `AlertEmail` retrieval from Key Vault by the Azure DevOps service connection identity

### Evidence

Pipeline, IaC, runtime integration and operational monitoring evidence is available in `docs/evidence`:

- Pre-deployment quota gate — `docs/evidence/01-pre-deployment-validation-quota-gate.png`
- Bicep Infrastructure as Code What-If — `docs/evidence/02-infrastructure-as-code-bicep-what-if.png`
- Dev deployment slot defined through Bicep — `docs/evidence/03-deployment-slot-iac-bicep.png`
- Manual Dev deployment gate — `docs/evidence/04-manual-dev-deployment-gate.png`
- Networking Bicep deployment — `docs/evidence/05-networking-bicep-deployment-success.png`
- Deployed Azure Virtual Network — `docs/evidence/06-networking-vnet-deployed-azure.png`
- Deployed networking subnets — `docs/evidence/07-networking-subnets-deployed-azure.png`
- Observability deployment pipeline — `docs/evidence/08-observability-deployment-pipeline.png`
- Application Insights deployed and linked to Log Analytics — `docs/evidence/09-application-insights-deployed.png`
- Log Analytics workspace deployed — `docs/evidence/10-log-analytics-workspace-deployed.png`
- Log Analytics 30-day data retention — `docs/evidence/11-log-analytics-data-retention.png`
- Key Vault deployed in Azure — `docs/evidence/12-key-vault-deployed-azure.png`
- Key Vault security controls — `docs/evidence/13-key-vault-security-controls.png`
- Key Vault RBAC access model — `docs/evidence/14-key-vault-rbac-access-model.png`
- Key Vault application integration — `docs/evidence/15-key-vault-application-integration.png`
- Application Insights live telemetry — `docs/evidence/16-application-insights-live-telemetry.png`
- Application Insights request telemetry — `docs/evidence/17-application-insights-request-telemetry.png`
- Azure Monitor alert email fired — `docs/evidence/18-azure-monitor-alert-email-fired.png`
- Azure Monitor alert fired — `docs/evidence/19-azure-monitor-alert-fired.png`

Additional architectural decisions and implementation details are documented in `docs/architecture.md`.

---

## Resource Organisation

Development resources target:

    rg-cloudplatformlab-dev

Resources are tagged to make their purpose and ownership easier to identify and to support cost reporting and governance.

Current tags include:

    Project       = CloudPlatformLab
    Environment   = Dev
    ManagedBy     = Bicep
    CostCenter    = CloudPlatformLab

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
7. Gather implementation evidence.
8. Remove paid resources when they are no longer required.

The Log Analytics workspace currently uses a 30-day retention period to provide an observability foundation while keeping data retention appropriate for a development environment.

Application telemetry is now being generated, so ingestion volume and retention can be reviewed against actual workload telemetry as part of the platform's cost controls.

Monitoring resources are intentionally focused. The current implementation uses existing Application Insights request telemetry, a failed-request metric alert and a single Action Group rather than introducing unnecessary monitoring infrastructure.

Because the environment is defined as code, resources can be destroyed when they are not needed and recreated later from Bicep.

This also tests infrastructure reproducibility rather than relying on resources that were configured manually and left running indefinitely.

---

## Git Workflow

Azure Repos is used for the main development and pull request workflow.

GitHub is maintained as the public repository for the project.

The normal workflow is:

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

Infrastructure, pipeline, application integration, monitoring and documentation changes normally go through feature branches and pull requests rather than being changed directly on `Dev`.

Feature-branch pipeline runs are used to validate infrastructure and pipeline behaviour before changes are merged.

Dev environment deployments are performed from the merged `Dev` branch.

After changes are merged, the public GitHub repository is synchronized with the Azure Repos version.

---

## Repository Structure

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

The `tests` area is currently being prepared. Genuine automated tests will be added as the deployment workflow develops.

---

## Deployment Strategy

Infrastructure areas are independently validated and deployed so that unrelated platform constraints do not block one another.

For the application platform, the intended deployment architecture uses one App Service with a development deployment slot.

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

The intended promotion path validates application changes in the `dev` slot before promoting them to the main production App Service.

Deployment slot swapping and rollback can then provide controlled promotion and recovery once the application deployment path is operational.

While App Service provisioning remains quota constrained, application integration with Key Vault and Application Insights is validated locally against the real deployed Azure services.

Operational monitoring is also active against the telemetry produced by the locally running application.

This allows application-to-platform integration and operational behaviour to be developed and evidenced independently of the App Service capacity constraint.

---

## Landing Zone and Governance

A later phase will extend the project from workload-level infrastructure into a small enterprise-style governance model.

The target model explores a structure such as:

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

The intention is not to maintain two identical implementations of every resource.

The project will use both tools where they demonstrate useful infrastructure patterns and the differences between Azure-native IaC and a provider-based IaC workflow.

---

## Current Work

The networking, observability and security foundations are deployed and independently managed through reusable Azure DevOps pipeline templates.

The application now consumes the security and observability foundations rather than those services existing only as isolated infrastructure:

- Key Vault configuration retrieval has been validated from the ASP.NET Core application.
- Application Insights is receiving real application request telemetry.
- Application-to-Azure authentication is being validated locally through `DefaultAzureCredential`.
- The future App Service workload identity path is represented through the system-assigned managed identity defined in Bicep.
- Failed application requests are monitored through Azure Monitor.
- The failed-request alert and Action Group are deployed through Bicep.
- The Action Group notification address is retrieved securely from Key Vault by the Azure DevOps pipeline.
- The monitoring path has been tested end-to-end through a deliberately generated application failure and successful email notification.

The next phases will broaden the project beyond the initial platform foundations into governance, data, API management, containerisation and private connectivity while continuing to increase operational maturity.

Current priorities are:

- add automated application tests
- introduce Azure Policy and governance controls
- add broader application health monitoring
- transition Key Vault authentication to App Service managed identity when the application platform becomes deployable
- introduce Private Endpoints and Private DNS for appropriate platform services
- introduce Cosmos DB for application persistence
- containerise the application and introduce Azure Container Registry
- deploy a container workload through Azure Container Apps
- introduce Azure API Management
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
- Key Vault Secrets User
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
- Azure Monitor
- Azure Monitor metric alerts
- Azure Monitor Action Groups

### Defined / In Progress

- Azure App Service
- App Service Deployment Slots
- Automated application testing
- Application health monitoring

### Planned

- Terraform
- Azure Policy
- Azure Cosmos DB
- Azure SQL where appropriate
- Azure Storage
- Azure Service Bus
- Azure Event Grid
- Azure Container Registry
- Azure Container Apps
- Azure API Management
- Private Endpoints
- Private DNS
- Hub-spoke networking
- Management Groups
- Landing Zone governance
- Defender for Cloud