# Microsoft Sentinel Deployment — Azure DevOps Pipeline

> **Version:** 1.0
> **Last Updated:** February 2026
> **Pipeline:** `azure-pipelines.yml`
> **ARM Template:** `sentinel-deployment.json`

---

## Table of Contents

1. [Overview](#1-overview)
2. [What Gets Deployed](#2-what-gets-deployed)
3. [Prerequisites](#3-prerequisites)
4. [Repository Structure](#4-repository-structure)
5. [Variable Reference](#5-variable-reference)
6. [Setup Instructions](#6-setup-instructions)
7. [Pipeline Stages Explained](#7-pipeline-stages-explained)
8. [IAM — Roles and Permissions](#8-iam--roles-and-permissions)
9. [Customisation Guide](#9-customisation-guide)
10. [Post-Deployment Steps](#10-post-deployment-steps)
11. [Troubleshooting](#11-troubleshooting)
12. [Cost Considerations](#12-cost-considerations)

---

## 1. Overview

This pipeline automates the deployment of a Microsoft Sentinel SIEM instance on Azure using an ARM template and Azure DevOps YAML pipeline. Every configurable setting is exposed as a pipeline variable so the same pipeline can be reused across environments (dev, staging, production) by changing variable values.

### Design Principles

- **Reusable** — all settings are variables; no hardcoded values in templates
- **Idempotent** — safe to run multiple times; creates or updates resources
- **Validated** — template is validated and a what-if analysis runs before deployment
- **Verified** — post-deployment stage confirms configuration matches expectations

---

## 2. What Gets Deployed

| Resource | Details |
|---|---|
| **Resource Providers** | Automatically registers `Microsoft.OperationalInsights`, `Microsoft.OperationsManagement`, and `Microsoft.SecurityInsights` on the subscription |
| **Resource Group** | Created if it does not exist |
| **Log Analytics Workspace** | Pay-As-You-Go (PerGB2018) pricing tier |
| **Microsoft Sentinel** | Enabled on the workspace via SecurityInsights solution |
| **Daily Ingestion Cap** | 5 MB/day (0.005 GB) — configurable via `dailyQuotaGb` |
| **Table Retention** | 90 days default — configurable via `retentionInDays` |
| **UEBA** | Enabled with AuditLogs, AzureActivity, SecurityEvent, SigninLogs sources |
| **IAM Role Assignments** | Assigns Microsoft Sentinel and Log Analytics RBAC roles to specified Entra ID groups or users at the resource group level |

### Free Data Connectors Enabled

| Connector | Data Tables | Cost |
|---|---|---|
| **Azure Activity** | AzureActivity | Free |
| **Microsoft Entra ID (Azure AD)** | SigninLogs, AuditLogs | Free (with P1/P2 licence) |
| **Microsoft 365 Defender** | SecurityAlert (MDATP) | Free |
| **Microsoft Threat Intelligence** | ThreatIntelligenceIndicator | Free |

---

## 3. Prerequisites

### Azure Requirements

| Requirement | Details |
|---|---|
| **Azure Subscription** | Active subscription with billing enabled |
| **Azure Permissions** | Contributor + Microsoft Sentinel Contributor on the subscription or resource group |
| **Microsoft Entra ID** | P1 or P2 licence required for Sign-In and Audit Log connectors |
| **Microsoft 365 Defender** | Active M365 Defender licence for the Defender connector |
| **Resource Providers** | `Microsoft.OperationalInsights`, `Microsoft.OperationsManagement`, `Microsoft.SecurityInsights` must be registered (the pipeline handles this automatically — see below) |

### Azure DevOps Requirements

| Requirement | Details |
|---|---|
| **Azure DevOps Project** | An existing Azure DevOps project |
| **Service Connection** | Managed Identity service connection to the target Azure subscription |
| **Self-Hosted Agent** (for MI) | If using Managed Identity, the agent VM must have the identity assigned with the required roles |
| **Pipeline Environment** | Create an environment called `sentinel-production` in Azure DevOps (Pipelines > Environments) |

### Resource Provider Registration (Automatic)

The pipeline automatically checks and registers the following resource providers on the target subscription before each deployment:

- `Microsoft.OperationalInsights`
- `Microsoft.OperationsManagement`
- `Microsoft.SecurityInsights`

The registration step runs in both the **Validate** and **Deploy** stages. It checks the current registration state of each provider, registers any that are missing, and waits for registration to complete before proceeding.

> **Note:** The service principal or Managed Identity used by the pipeline must have permission to register resource providers on the subscription (the `Contributor` role includes this permission).

If you prefer to register providers manually (e.g. in a locked-down subscription), run the following in Azure CLI or Cloud Shell:

```bash
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.SecurityInsights
```

---

## 4. Repository Structure

```
Security/SIEM - SOAR/Sentinel-Deployment/
├── 01-resource-provider-Sentinel.json          # Standalone ARM template for provider registration
├── azure-budget.json                            # ARM template for budget and cost alert notifications
├── azure-pipelines.yml                          # Azure DevOps pipeline definition
├── sentinel-deployment.json                     # ARM template for all resources (workspace, Sentinel, connectors, UEBA, IAM)
├── Deployment Instructions.md                   # This file
├── README - Azure Budget.md                     # Guide for budget deployment at all scopes (MG, sub, RG)
└── README - Resource Provider Registration.md   # Guide for standalone provider registration and verification
```

---

## 5. Variable Reference

All configurable settings are defined in the `variables` block of `azure-pipelines.yml`.

### Core Infrastructure Variables

| Variable | Default | Description |
|---|---|---|
| `azureSubscriptionId` | `YOUR_SUBSCRIPTION_ID` | Azure subscription ID or service connection name |
| `resourceGroupName` | `rg-sentinel-prod` | Target resource group name |
| `location` | `uksouth` | Azure region for deployment |

### Workspace Variables

| Variable | Default | Description |
|---|---|---|
| `workspaceName` | `law-sentinel-prod` | Log Analytics workspace name |
| `skuName` | `PerGB2018` | Pricing tier (Pay-As-You-Go) |
| `dailyQuotaGb` | `0.005` | Daily ingestion cap in GB (0.005 GB = 5 MB) |
| `retentionInDays` | `90` | Default retention for workspace tables (30-730 days) |

### Data Connector Variables

| Variable | Default | Description |
|---|---|---|
| `enableAzureActivityConnector` | `true` | Enable Azure Activity connector |
| `enableEntraIDConnector` | `true` | Enable Entra ID Sign-In/Audit connector |
| `enableM365DefenderConnector` | `true` | Enable M365 Defender connector |
| `enableThreatIntelConnector` | `true` | Enable Microsoft Threat Intelligence connector |

### UEBA Variables

| Variable | Default | Description |
|---|---|---|
| `enableUEBA` | `true` | Enable User and Entity Behavior Analytics |

### IAM Role Assignment Variables

| Variable | Default | Description |
|---|---|---|
| `sentinelReaderPrincipalIds` | `[]` | Entra ID object IDs for Microsoft Sentinel Reader role |
| `sentinelResponderPrincipalIds` | `[]` | Entra ID object IDs for Microsoft Sentinel Responder role |
| `sentinelContributorPrincipalIds` | `[]` | Entra ID object IDs for Microsoft Sentinel Contributor role |
| `sentinelPlaybookOperatorPrincipalIds` | `[]` | Entra ID object IDs for Microsoft Sentinel Playbook Operator role |
| `logAnalyticsReaderPrincipalIds` | `[]` | Entra ID object IDs for Log Analytics Reader role |
| `logAnalyticsContributorPrincipalIds` | `[]` | Entra ID object IDs for Log Analytics Contributor role |
| `iamPrincipalType` | `Group` | Type of principal: `Group`, `User`, or `ServicePrincipal` |

### Tag Variables

| Variable | Default | Description |
|---|---|---|
| `tagEnvironment` | `Production` | Environment tag value |
| `tagManagedBy` | `AzureDevOps` | Managed-by tag value |
| `tagSolution` | `MicrosoftSentinel` | Solution tag value |

---

## 6. Setup Instructions

### Step 1: Configure the Service Connection

Since you are using **Managed Identity** authentication:

1. Ensure your self-hosted Azure DevOps agent VM has a **System-Assigned** or **User-Assigned Managed Identity**
2. Assign the following roles to the Managed Identity on the target subscription or resource group:
   - `Contributor` (for resource deployment and provider registration)
   - `Microsoft Sentinel Contributor` (for Sentinel configuration)
   - `User Access Administrator` (required if using IAM role assignment features — allows the pipeline to assign roles to groups/users)
3. In Azure DevOps, go to **Project Settings > Service connections**
4. Create a new **Azure Resource Manager** service connection using **Managed Identity**
5. Note the service connection name — this replaces `YOUR_SUBSCRIPTION_ID` in the pipeline

### Step 2: Update Pipeline Variables

Edit `azure-pipelines.yml` and update the variables section:

```yaml
variables:
  azureSubscriptionId: 'my-sentinel-service-connection'    # your service connection name
  resourceGroupName: 'rg-sentinel-prod'                     # your resource group
  location: 'uksouth'                                       # your region
  workspaceName: 'law-sentinel-prod'                        # your workspace name
  dailyQuotaGb: '0.005'                                     # 5 MB daily cap
  retentionInDays: 90                                        # 90 day retention
```

### Step 3: Create the Pipeline Environment

1. In Azure DevOps, go to **Pipelines > Environments**
2. Click **New environment**
3. Name it `sentinel-production`
4. Optionally add **approval checks** so deployments require manual sign-off

### Step 4: Create the Pipeline

1. In Azure DevOps, go to **Pipelines > New Pipeline**
2. Select your repository source (Azure Repos Git, GitHub, etc.)
3. Choose **Existing Azure Pipelines YAML file**
4. Set the path to `Security/SIEM - SOAR/Sentinel-Deployment/azure-pipelines.yml`
5. Click **Run** to execute the pipeline

### Step 5: Approve and Monitor

1. The **Validate** stage runs automatically — check the what-if output to preview changes
2. The **Deploy** stage requires the pipeline to be running on the `main` branch
3. If you added approval checks on the `sentinel-production` environment, approve the deployment
4. The **Verify** stage confirms the workspace settings match your variables

---

## 7. Pipeline Stages Explained

### Stage 1: Validate

| Step | Action |
|---|---|
| Register Resource Providers | Checks and registers `Microsoft.OperationalInsights`, `Microsoft.OperationsManagement`, and `Microsoft.SecurityInsights` on the subscription if not already registered |
| Create Resource Group | Creates the RG if it doesn't exist (idempotent) |
| Validate ARM Template | Runs `az deployment group validate` to check for syntax and parameter errors |
| What-If Analysis | Shows a preview of what resources will be created, modified, or deleted |

The validate stage runs on **all branches and PRs** so you can review changes before merging.

### Stage 2: Deploy

| Step | Action |
|---|---|
| Register Resource Providers | Ensures all required providers are registered before deployment |
| Create Resource Group | Ensures RG exists (idempotent) |
| Deploy ARM Template | Runs `az deployment group create` with all parameters |
| Verify Outputs | Displays the deployment outputs (workspace ID, customer ID, retention, daily cap) |

The deploy stage only runs on the `main` branch (`refs/heads/main`) and uses a **deployment job** with the `sentinel-production` environment for approval gates.

### Stage 3: Verify

| Step | Action |
|---|---|
| Verify Sentinel | Confirms the SecurityInsights solution is installed |
| Verify Workspace | Checks retention and daily cap match expected values |
| Verify IAM | Lists all Sentinel and Log Analytics role assignments on the resource group |

---

## 8. IAM — Roles and Permissions

This deployment supports automated RBAC role assignments aligned with Microsoft's recommended role model for Sentinel and Log Analytics. Roles are assigned at the **resource group** level, which is Microsoft's recommended scope for Sentinel deployments.

> **References:**
> - [Roles and permissions in Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/roles)
> - [Prerequisites for deploying Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/prerequisites)

### 8.1 Microsoft's Recommended Role Model

Microsoft recommends using the principle of least privilege. Assign the most restrictive role that still allows users to complete their tasks. The following table summarises the built-in roles and their intended audiences:

| Role | Intended For | Permissions |
|---|---|---|
| **Microsoft Sentinel Reader** | Executives, compliance officers, read-only stakeholders | View data, incidents, workbooks, and recommendations |
| **Microsoft Sentinel Responder** | SOC analysts (Tier 1/2) | All Reader permissions + manage incidents (triage, assign, dismiss) |
| **Microsoft Sentinel Contributor** | Security engineers, Tier 3 analysts | All Responder permissions + create/edit analytics rules, workbooks, manage content hub |
| **Microsoft Sentinel Playbook Operator** | SOC analysts who need to run playbooks | List, view, and manually run playbooks |
| **Log Analytics Reader** | Auditors, reporting users | Read-only access to Log Analytics workspace data and settings |
| **Log Analytics Contributor** | Workspace administrators, data engineers | Read/write access to Log Analytics workspace data, settings, and connected sources |

#### Additional Roles for Specific Tasks

| Task | Required Roles |
|---|---|
| Connect data sources | **Write** permission on the workspace (e.g. Contributor); check connector docs for extra permissions |
| Create/edit playbooks | **Logic App Contributor** on the playbook resource group |
| Allow Sentinel to run playbooks via automation rules | **Owner** role on the playbook resource group (to grant the Sentinel service account access) |
| Guest users assigning incidents | **Directory Reader** (Entra ID role) + **Microsoft Sentinel Responder** |
| Create/delete workbooks | **Microsoft Sentinel Contributor** or lesser Sentinel role + **Workbook Contributor** |

### 8.2 How Role Assignments Work in This Deployment

The ARM template creates `Microsoft.Authorization/roleAssignments` resources for each principal ID you provide. Assignments are:

- **Scoped to the resource group** — covers the workspace, Sentinel solution, and all related resources
- **Idempotent** — safe to run multiple times; existing assignments are not duplicated
- **Conditional** — if a principal ID array is empty (`[]`), no role assignments are created for that role
- **Deterministic** — role assignment names are generated using `guid()` based on the resource group, principal ID, and role name, ensuring consistency across deployments

### 8.3 Configuring IAM Role Assignments

#### Step 1: Create Entra ID Security Groups (Recommended)

Microsoft recommends assigning roles to **security groups** rather than individual users. Create groups in Entra ID (Azure AD) for each role:

| Entra ID Group Name (example) | Sentinel Role |
|---|---|
| `SG-Sentinel-Readers` | Microsoft Sentinel Reader |
| `SG-Sentinel-Responders` | Microsoft Sentinel Responder |
| `SG-Sentinel-Contributors` | Microsoft Sentinel Contributor |
| `SG-Sentinel-PlaybookOperators` | Microsoft Sentinel Playbook Operator |
| `SG-LogAnalytics-Readers` | Log Analytics Reader |
| `SG-LogAnalytics-Contributors` | Log Analytics Contributor |

To get the object ID for a group:

```bash
az ad group show --group "SG-Sentinel-Responders" --query id --output tsv
```

To get the object ID for an individual user:

```bash
az ad user show --id "user@contoso.com" --query id --output tsv
```

#### Step 2: Update Pipeline Variables

Edit the IAM variables in `azure-pipelines.yml` with the Entra ID object IDs as JSON arrays:

```yaml
# --- IAM Role Assignments ---
sentinelReaderPrincipalIds: '["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]'
sentinelResponderPrincipalIds: '["11111111-2222-3333-4444-555555555555"]'
sentinelContributorPrincipalIds: '["66666666-7777-8888-9999-000000000000"]'
sentinelPlaybookOperatorPrincipalIds: '["11111111-2222-3333-4444-555555555555"]'
logAnalyticsReaderPrincipalIds: '[]'
logAnalyticsContributorPrincipalIds: '[]'
iamPrincipalType: 'Group'
```

**Multiple principals per role** — pass multiple object IDs in the array:

```yaml
sentinelResponderPrincipalIds: '["group-id-1", "group-id-2", "group-id-3"]'
```

**Individual users** — if assigning to users instead of groups, change the principal type:

```yaml
iamPrincipalType: 'User'
sentinelResponderPrincipalIds: '["user-object-id-1", "user-object-id-2"]'
```

#### Step 3: Deploy and Verify

After the pipeline runs, the **Verify** stage will list all Sentinel and Log Analytics role assignments on the resource group. You can also verify manually:

```bash
# List all Sentinel and Log Analytics role assignments
az role assignment list \
  --resource-group rg-sentinel-prod \
  --query "[?contains(roleDefinitionName, 'Sentinel') || contains(roleDefinitionName, 'Log Analytics')].{Principal:principalName, Role:roleDefinitionName, PrincipalType:principalType}" \
  --output table
```

### 8.4 Role Assignment Examples by Organisation Size

#### Small Team (1-5 people, all roles)

```yaml
sentinelContributorPrincipalIds: '["security-team-group-id"]'
logAnalyticsContributorPrincipalIds: '["security-team-group-id"]'
iamPrincipalType: 'Group'
```

#### Medium SOC (separate analyst and engineering roles)

```yaml
sentinelResponderPrincipalIds: '["soc-analysts-group-id"]'
sentinelContributorPrincipalIds: '["security-engineers-group-id"]'
sentinelPlaybookOperatorPrincipalIds: '["soc-analysts-group-id"]'
sentinelReaderPrincipalIds: '["management-group-id", "compliance-group-id"]'
logAnalyticsReaderPrincipalIds: '["compliance-group-id"]'
logAnalyticsContributorPrincipalIds: '["security-engineers-group-id"]'
iamPrincipalType: 'Group'
```

#### Enterprise (tiered SOC with strict separation)

```yaml
sentinelReaderPrincipalIds: '["executives-group-id", "compliance-group-id", "it-ops-group-id"]'
sentinelResponderPrincipalIds: '["soc-tier1-group-id", "soc-tier2-group-id"]'
sentinelContributorPrincipalIds: '["soc-tier3-group-id", "security-engineers-group-id"]'
sentinelPlaybookOperatorPrincipalIds: '["soc-tier1-group-id", "soc-tier2-group-id"]'
logAnalyticsReaderPrincipalIds: '["compliance-group-id", "audit-group-id"]'
logAnalyticsContributorPrincipalIds: '["security-engineers-group-id"]'
iamPrincipalType: 'Group'
```

### 8.5 Important Notes on IAM

- **Roles are cumulative** — a user with both Sentinel Reader and Contributor will have the combined permissions of both roles. Avoid assigning overlapping roles unless intentional.
- **Scope matters** — this deployment assigns roles at the resource group level. For more granular control (e.g. table-level RBAC or resource-context RBAC), configure additional permissions in the Azure Portal. See [resource-context RBAC](https://learn.microsoft.com/en-us/azure/sentinel/resource-context-rbac).
- **Pipeline service principal** — the Managed Identity or service principal running the pipeline needs `Owner` or `User Access Administrator` on the resource group to create role assignments. The `Contributor` role alone is **not sufficient** for assigning roles.
- **Microsoft recommends a dedicated resource group** for Sentinel to simplify RBAC. All resources in the group inherit the same role assignments, reducing complexity.
- **Sentinel is moving to the Defender portal** — after March 2027, Sentinel will only be available in the Microsoft Defender portal. Role assignments made via Azure RBAC will continue to apply. See [Microsoft's migration guidance](https://learn.microsoft.com/en-us/azure/sentinel/move-to-defender).

---

## 9. Customisation Guide

### Using Variable Groups (Recommended for Multiple Environments)

Instead of hardcoding variables in the YAML, use **Azure DevOps Variable Groups** to manage environment-specific values:

1. Go to **Pipelines > Library > + Variable group**
2. Create groups like `sentinel-dev`, `sentinel-staging`, `sentinel-prod`
3. Reference them in the pipeline:

```yaml
variables:
  - group: sentinel-prod    # swap for sentinel-dev, sentinel-staging, etc.
```

### Example: Dev Environment Overrides

| Variable | Production | Development |
|---|---|---|
| `resourceGroupName` | `rg-sentinel-prod` | `rg-sentinel-dev` |
| `workspaceName` | `law-sentinel-prod` | `law-sentinel-dev` |
| `retentionInDays` | `90` | `30` |
| `dailyQuotaGb` | `0.005` | `0.001` |
| `tagEnvironment` | `Production` | `Development` |

### Changing the Daily Ingestion Cap

The `dailyQuotaGb` variable controls the daily data cap. Common values:

| Setting | Value | Use Case |
|---|---|---|
| 5 MB/day | `0.005` | Lab / learning / minimal testing |
| 100 MB/day | `0.1` | Small pilot deployment |
| 1 GB/day | `1` | Small production environment |
| 5 GB/day | `5` | Mid-size production |
| 10 GB/day | `10` | Larger production |
| No cap | `-1` | Unlimited (not recommended without budget controls) |

> **Important — Sizing the Daily Cap for Your Organisation:**
>
> The free tier of Microsoft Sentinel provides approximately **5 MB of ingestion per user per day**. When setting the `dailyQuotaGb` value, you should **multiply 5 MB by the total number of licences/seats** in your organisation to estimate your baseline free allowance.
>
> **Formula:** `dailyQuotaGb = (5 MB x number of licences) / 1024`
>
> | Licences/Seats | Free Allowance | `dailyQuotaGb` Value |
> |---|---|---|
> | 1 | 5 MB/day | `0.005` |
> | 10 | 50 MB/day | `0.049` |
> | 25 | 125 MB/day | `0.122` |
> | 50 | 250 MB/day | `0.244` |
> | 100 | 500 MB/day | `0.488` |
> | 250 | 1.22 GB/day | `1.221` |
> | 500 | 2.44 GB/day | `2.441` |
> | 1,000 | 4.88 GB/day | `4.883` |
>
> For example, if your organisation has **50 Microsoft 365 licences**, your free daily allowance is approximately **250 MB/day** — set `dailyQuotaGb` to `0.244` or higher to stay within that allowance. Setting the cap below your calculated allowance means you may not be using all of your free entitlement; setting it above means you will incur Pay-As-You-Go charges for the overage.

### Changing Retention

The `retentionInDays` variable controls default table retention:

| Setting | Details |
|---|---|
| `30` | Minimum retention (free tier included) |
| `90` | Default in this pipeline — covers most compliance baselines |
| `180` | Common for security operations |
| `365` | Regulatory (HIPAA, PCI-DSS annual retention) |
| `730` | Maximum supported retention |

> **Cost note:** The first 31 days of retention are included free. Days 32-90 are included free with Sentinel. Retention beyond 90 days is charged at ~$0.12/GB/month.

### Disabling Specific Connectors

Set any connector variable to `false` to skip it:

```yaml
enableM365DefenderConnector: false    # skip if no M365 Defender licence
enableEntraIDConnector: false         # skip if no Entra ID P1/P2
```

### Adding Additional Free Connectors

To add more connectors, add new resource blocks to `sentinel-deployment.json` following the existing pattern. Other free connectors include:

| Connector | Kind Value | Licence Needed |
|---|---|---|
| Microsoft Defender for Cloud | `AzureSecurityCenter` | Defender for Cloud |
| Microsoft Defender for IoT | `IOT` | Defender for IoT |
| Microsoft Cloud App Security | `MicrosoftCloudAppSecurity` | MCAS licence |
| Office 365 | `Office365` | Office 365 licence |

---

## 10. Post-Deployment Steps

After the pipeline completes successfully, perform these manual steps in the Azure Portal:

### 10.1 Verify UEBA Configuration

1. Navigate to **Microsoft Sentinel > Entity behavior (UEBA)**
2. Confirm that UEBA is enabled and the configured data sources are active
3. Verify entity pages are populating (may take 24-48 hours for initial data)

### 10.2 Enable Analytics Rules

The pipeline deploys connectors but does not enable analytics (detection) rules. To enable:

1. Go to **Microsoft Sentinel > Analytics > Rule templates**
2. Filter by data source to see rules available for your enabled connectors
3. Enable the recommended rules — start with:
   - Fusion detection (ML-based multi-stage attack detection)
   - Microsoft Security incident creation rules (auto-creates incidents from Defender alerts)
   - Built-in Scheduled rules for high-fidelity detections

### 10.3 Configure Diagnostic Settings

Route Azure Activity logs to the workspace:

1. Go to **Azure Monitor > Activity Log > Diagnostic settings**
2. Add a diagnostic setting to send logs to the Log Analytics workspace
3. Select all log categories

### 10.4 Set Up Automation (Optional)

1. Go to **Microsoft Sentinel > Automation**
2. Create automation rules for common actions:
   - Auto-assign incidents to analysts
   - Auto-close known false positives
   - Run playbooks (Logic Apps) for enrichment or response

### 10.5 Review Workbooks

1. Go to **Microsoft Sentinel > Workbooks > Templates**
2. Save key workbooks to your workspace:
   - Azure Activity
   - Microsoft Entra ID Sign-In Logs
   - UEBA Insights
   - Security Operations Efficiency

---

## 11. Troubleshooting

### Common Issues

| Issue | Cause | Resolution |
|---|---|---|
| `ResourceProviderNotRegistered` | Required provider not registered | Run `az provider register --namespace Microsoft.SecurityInsights` |
| `AuthorizationFailed` | Managed Identity lacks permissions | Assign `Contributor` + `Microsoft Sentinel Contributor` roles |
| `WorkspaceNotFound` during connector deployment | Timing issue — workspace not yet ready | The template uses `dependsOn` to handle this; if persistent, re-run the pipeline |
| `InvalidTemplateDeployment` | Parameter type mismatch | Check that `retentionInDays` is an integer and `dailyQuotaGb` is a string |
| Entra ID connector shows "No data" | Missing P1/P2 licence or diagnostic settings | Verify Entra ID licence tier and enable diagnostic settings in Entra admin centre |
| UEBA not populating entities | Data needs time to process | Allow 24-48 hours after deployment for initial entity data |
| `DailyQuotaReached` in workspace | Ingestion exceeded the 5 MB cap | Increase `dailyQuotaGb` or wait for the next UTC day reset |
| Pipeline fails on deploy stage | Branch is not `main` | Deploy stage has a branch condition; merge to main or remove the condition for testing |
| `RoleAssignmentExists` | Role already assigned to that principal | Safe to ignore — the template uses deterministic GUIDs so re-runs are idempotent |
| `AuthorizationFailed` on role assignment | Pipeline identity lacks permission to assign roles | Assign `Owner` or `User Access Administrator` on the resource group to the pipeline identity |
| `PrincipalNotFound` | Invalid or deleted Entra ID object ID | Verify the object ID exists: `az ad group show --group "<object-id>"` or `az ad user show --id "<object-id>"` |

### Useful Azure CLI Commands for Debugging

```bash
# Check resource group exists
az group show --name rg-sentinel-prod

# Check workspace configuration
az monitor log-analytics workspace show \
  --workspace-name law-sentinel-prod \
  --resource-group rg-sentinel-prod \
  --output jsonc

# List Sentinel solutions
az monitor log-analytics solution list \
  --resource-group rg-sentinel-prod \
  --query "[?contains(name, 'SecurityInsights')]" \
  --output table

# Check deployment status
az deployment group show \
  --name sentinel-BUILDNUMBER \
  --resource-group rg-sentinel-prod \
  --query "properties.provisioningState"

# List registered providers
az provider show --namespace Microsoft.SecurityInsights \
  --query "registrationState"

# List Sentinel and Log Analytics role assignments
az role assignment list \
  --resource-group rg-sentinel-prod \
  --query "[?contains(roleDefinitionName, 'Sentinel') || contains(roleDefinitionName, 'Log Analytics')].{Principal:principalName, Role:roleDefinitionName, Type:principalType}" \
  --output table

# Get Entra ID group object ID
az ad group show --group "SG-Sentinel-Responders" --query id --output tsv

# Get Entra ID user object ID
az ad user show --id "user@contoso.com" --query id --output tsv
```

---

## 12. Cost Considerations

### Pay-As-You-Go (PerGB2018) Pricing

| Component | Cost | Notes |
|---|---|---|
| **Log Analytics ingestion** | ~$2.76/GB (UK South) | First 5 GB/month may be free on some subscriptions |
| **Sentinel charge** | ~$2.46/GB | On top of Log Analytics cost |
| **Total per GB** | ~$5.22/GB | Combined ingestion cost |
| **Retention (first 90 days)** | Free | 31 days free for LA + 59 days free for Sentinel |
| **Retention (beyond 90 days)** | ~$0.12/GB/month | Per GB of retained data |
| **UEBA** | Free | No additional charge |
| **Free connectors** | Free | Azure Activity, Entra ID, Defender, Threat Intelligence |

### Free Tier Allowance

Microsoft Sentinel's free tier provides approximately **5 MB of data ingestion per user per day**. This means the daily cap you configure should reflect the number of licences/seats in your organisation:

**Daily free allowance = 5 MB x number of licences/seats**

For example:
- **10 licences** = 50 MB/day free (`dailyQuotaGb: '0.049'`)
- **100 licences** = 500 MB/day free (`dailyQuotaGb: '0.488'`)
- **500 licences** = 2.44 GB/day free (`dailyQuotaGb: '2.441'`)

Any ingestion beyond this free allowance is charged at the Pay-As-You-Go rate shown above. Set your `dailyQuotaGb` value accordingly to make full use of your free entitlement without incurring unexpected charges.

### Monthly Cost Estimate at 5 MB/Day (Single User)

| Metric | Value |
|---|---|
| Daily ingestion | 5 MB (0.005 GB) |
| Monthly ingestion | ~150 MB (0.15 GB) |
| Monthly cost (LA + Sentinel) | ~$0.78/month |
| Annual cost | ~$9.40/year |

> With a 5 MB daily cap, this deployment is effectively a lab/learning environment or single-user setup with minimal cost. For production workloads, multiply by your licence count and increase `dailyQuotaGb` accordingly.

### Cost Optimisation Tips

- Use **Commitment Tiers** if ingesting 100+ GB/day for significant discounts
- Set the `dailyQuotaGb` cap to prevent unexpected cost spikes
- Use **Basic Logs** for high-volume, low-value tables (cheaper ingestion, limited query)
- Archive data beyond 90 days to **Archive tier** at ~$0.02/GB/month
- Review the **Sentinel Free Trial** — 10 GB/day free for the first 31 days on new workspaces

### Azure Budget Alerts

Use the `azure-budget.json` template to create a budget with cost alert notifications for your Sentinel deployment. The template supports deployment at **management group**, **subscription**, or **resource group** scope and sends email alerts at configurable soft and hard spending thresholds.

**Quick deployment (subscription-level budget for £500/month):**

```bash
# startDate defaults to the 1st of the current month
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetName="budget-sentinel-monthly" \
    budgetAmount=500 \
    contactEmails='["secops@contoso.com"]'
```

This creates alerts at **80% (soft limit)** and **100% (hard limit)** of the budget, plus a **forecasted spend** alert. The start date defaults to the 1st of the current month. See `README - Azure Budget.md` for full deployment options, examples, and instructions for all three scopes.

---

*For questions or issues with this pipeline, raise an issue in the repository or contact the security engineering team.*
