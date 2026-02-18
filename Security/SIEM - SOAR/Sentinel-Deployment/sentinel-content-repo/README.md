# Sentinel Free Connectors — GitHub CI/CD Repository

> **Purpose:** Deploy and manage Microsoft Sentinel's free data connectors as code using a GitHub Actions CI/CD pipeline. Based on the [Microsoft Sentinel Repositories](https://learn.microsoft.com/en-us/azure/sentinel/ci-cd-custom-content) CI/CD framework.

---

## Overview

This repository contains individual ARM templates for each of the free (no additional cost) Microsoft Sentinel data connectors. A GitHub Actions workflow validates and deploys the templates to your Sentinel workspace whenever changes are pushed to `main`.

### Why Separate Templates?

The main `sentinel-deployment.json` template deploys connectors as part of a full workspace build. This repository takes a different approach — each connector is an independent ARM template that can be:

- **Added or removed individually** without affecting other connectors
- **Version-controlled independently** with full commit history per connector
- **Deployed selectively** — only changed templates are redeployed (smart deployments)
- **Extended** — add analytics rules, hunting queries, and automation rules alongside connectors

---

## Repository Structure

```
sentinel-content-repo/
├── .github/
│   └── workflows/
│       └── sentinel-deploy-connectors.yml    # GitHub Actions CI/CD workflow
├── .sentinel/                                 # Tracking folder (used by Sentinel Repositories)
├── DataConnectors/
│   ├── azure-activity.json                    # Azure Activity Log (subscription scope)
│   ├── entra-id.json                          # Microsoft Entra ID (Azure AD)
│   ├── m365-defender.json                     # Microsoft 365 Defender
│   ├── threat-intelligence.json               # Microsoft Threat Intelligence
│   ├── defender-for-cloud.json                # Microsoft Defender for Cloud
│   ├── cloud-app-security.json                # Microsoft Defender for Cloud Apps
│   ├── office365.json                         # Office 365 (Exchange, SharePoint, Teams)
│   └── defender-for-identity.json             # Microsoft Defender for Identity
├── AnalyticsRules/                            # Analytics rules (add as needed)
├── HuntingQueries/                            # Hunting queries (add as needed)
├── AutomationRules/                           # Automation rules (add as needed)
├── sentinel-deployment.config                 # Deployment priority and exclusions
└── README.md
```

---

## Free Data Connectors

All connectors in this repository are included with Microsoft Sentinel at no additional ingestion cost.

| Connector | Template | Kind | Data Tables | Licence Requirement |
|---|---|---|---|---|
| **Azure Activity** | `azure-activity.json` | Diagnostic Setting | AzureActivity | None |
| **Microsoft Entra ID** | `entra-id.json` | AzureActiveDirectory | SigninLogs, AuditLogs | Entra ID P1/P2 |
| **Microsoft 365 Defender** | `m365-defender.json` | MicrosoftDefenderAdvancedThreatProtection | SecurityAlert (MDATP) | M365 Defender licence |
| **Microsoft Threat Intelligence** | `threat-intelligence.json` | MicrosoftThreatIntelligence | ThreatIntelligenceIndicator | None |
| **Defender for Cloud** | `defender-for-cloud.json` | AzureSecurityCenter | SecurityAlert (ASC) | Defender for Cloud (free tier) |
| **Defender for Cloud Apps** | `cloud-app-security.json` | MicrosoftCloudAppSecurity | SecurityAlert (MCAS), McasShadowItReporting | Defender for Cloud Apps licence |
| **Office 365** | `office365.json` | Office365 | OfficeActivity | Microsoft 365 licence |
| **Defender for Identity** | `defender-for-identity.json` | AzureAdvancedThreatProtection | SecurityAlert (AATP) | Defender for Identity licence |

> **Note:** "Free" means no additional Sentinel ingestion charges. Some connectors require a product licence (e.g., Entra ID P1/P2, Microsoft 365 Defender). The data ingestion itself is free once the licence is in place.

### Azure Activity Connector — Special Case

The Azure Activity connector uses a **subscription-level diagnostic setting** rather than the `Microsoft.SecurityInsights/dataConnectors` resource type. It is deployed at subscription scope (`az deployment sub create`) instead of resource group scope. The GitHub Actions workflow handles this automatically.

---

## Prerequisites

| Requirement | Details |
|---|---|
| **GitHub Repository** | A GitHub repository (public or private) to host this content |
| **Sentinel Workspace** | An existing Log Analytics workspace with Microsoft Sentinel enabled |
| **Azure Service Principal** | With `Microsoft Sentinel Contributor` role on the resource group (for connector deployment) and `Contributor` on the subscription (for the Azure Activity diagnostic setting) |
| **GitHub Secrets** | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` configured for OIDC federated credentials |
| **GitHub Variables** | `SENTINEL_RESOURCE_GROUP`, `SENTINEL_WORKSPACE_NAME`, and optionally `AZURE_LOCATION` (defaults to `uksouth`) |

---

## Setup

### Step 1: Create an Entra ID App Registration with Federated Credentials

The workflow uses OIDC (OpenID Connect) for passwordless authentication — no client secrets to rotate.

```bash
# Create the app registration
az ad app create --display-name "sp-sentinel-github-deploy"

# Note the appId from the output, then create a service principal
APP_ID="<appId from above>"
az ad sp create --id "$APP_ID"

# Get the service principal object ID
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id --output tsv)

# Assign Microsoft Sentinel Contributor on the resource group
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Microsoft Sentinel Contributor" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group>"

# Assign Contributor on the subscription (for Azure Activity diagnostic setting)
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>"

# Add federated credential for GitHub Actions
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<github-org>/<repo-name>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Add federated credential for the production environment
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-production-env",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<github-org>/<repo-name>:environment:production",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 2: Configure GitHub Secrets and Variables

In your GitHub repository, go to **Settings > Secrets and variables > Actions**.

**Secrets** (Settings > Secrets > Actions):

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | The `appId` of the app registration |
| `AZURE_TENANT_ID` | Your Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

**Variables** (Settings > Variables > Actions):

| Variable | Value | Example |
|---|---|---|
| `SENTINEL_RESOURCE_GROUP` | Resource group containing the Sentinel workspace | `rg-sentinel-prod` |
| `SENTINEL_WORKSPACE_NAME` | Name of the Log Analytics workspace | `law-sentinel-prod` |
| `AZURE_LOCATION` | Azure region (optional, defaults to `uksouth`) | `uksouth` |

### Step 3: Create the GitHub Environment

1. Go to **Settings > Environments**
2. Create an environment called **production**
3. Optionally add required reviewers for manual approval before deployment

### Step 4: Push to Main

Push the repository contents to the `main` branch. The workflow triggers automatically and deploys all connector templates.

---

## How the Workflow Works

### Trigger

The workflow triggers on:
- **Push to `main`** — when any file under `DataConnectors/` is added or modified
- **Manual dispatch** — click **Run workflow** in the Actions tab with an option to deploy all connectors regardless of changes

### Stages

| Stage | What It Does |
|---|---|
| **Validate** | Runs `az deployment group validate` on each resource-group-scoped template and `az deployment sub validate` on the Azure Activity template |
| **Deploy** | Deploys only changed templates (smart deployment). Azure Activity is deployed at subscription scope; all others at resource group scope |
| **Summary** | Writes a deployment summary to the GitHub Actions job summary |

### Smart Deployments

By default, the workflow only deploys connector templates that changed in the most recent commit. Use the manual dispatch with **Deploy all connectors** set to `true` to force a full redeployment.

---

## Adding or Removing Connectors

### Add a New Connector

1. Create a new ARM template in the `DataConnectors/` folder following the existing pattern
2. Commit and push to `main`
3. The workflow automatically validates and deploys the new template

### Remove a Connector

1. Delete the template file from `DataConnectors/`
2. Commit and push to `main`

> **Note:** Removing a template from the repository does **not** delete the connector from Sentinel. To fully remove a connector, also delete it from the Sentinel workspace via the Portal or CLI.

### Disable a Connector Without Removing

Edit the template and set the data type state to `Disabled`:

```json
"dataTypes": {
  "alerts": {
    "state": "Disabled"
  }
}
```

---

## Extending the Repository

This repository follows the [Microsoft Sentinel CI/CD](https://learn.microsoft.com/en-us/azure/sentinel/ci-cd-custom-content) content structure. You can extend it by adding content to the other folders:

| Folder | Content Type | Deployed Via |
|---|---|---|
| `AnalyticsRules/` | Scheduled, NRT, and Fusion analytics rules | Sentinel Repositories connection or custom workflow |
| `HuntingQueries/` | KQL hunting queries (saved searches) | Sentinel Repositories connection or custom workflow |
| `AutomationRules/` | Automation rules for incident handling | Sentinel Repositories connection or custom workflow |

### Connecting via Sentinel Repositories (Portal)

For content types supported by the built-in Repositories feature (analytics rules, automation rules, hunting queries, parsers, playbooks, workbooks), you can connect this repository directly to Sentinel:

1. In the Azure Portal, go to **Microsoft Sentinel > Content management > Repositories**
2. Click **Add new**
3. Authorise the GitHub connection and select this repository
4. Select the content types to deploy

> **Important:** The built-in Repositories feature does **not** support data connector deployment. The custom GitHub Actions workflow in this repository handles connector deployment separately.

---

## Deployment Configuration

The `sentinel-deployment.config` file controls deployment priority and exclusions:

```json
{
  "prioritizedcontentfiles": [
    "DataConnectors/entra-id.json",
    "DataConnectors/azure-activity.json"
  ],
  "excludecontentfiles": [],
  "parameterfilemappings": {}
}
```

- **prioritizedcontentfiles** — templates deployed first (e.g., identity-related connectors before others)
- **excludecontentfiles** — templates excluded from deployment (useful for temporarily disabling a connector)
- **parameterfilemappings** — map parameter files to content for multi-workspace deployments (see [Microsoft docs](https://learn.microsoft.com/en-us/azure/sentinel/ci-cd-custom-deploy#scale-your-deployments-with-parameter-files))

---

## Manual Deployment (Without GitHub Actions)

If you prefer to deploy manually without the CI/CD pipeline:

### Deploy All Resource Group Connectors

```bash
for TEMPLATE in DataConnectors/*.json; do
  FILENAME=$(basename "$TEMPLATE")
  [ "$FILENAME" = "azure-activity.json" ] && continue

  echo "Deploying: $FILENAME"
  az deployment group create \
    --resource-group "rg-sentinel-prod" \
    --template-file "$TEMPLATE" \
    --parameters workspaceName="law-sentinel-prod"
done
```

### Deploy Azure Activity (Subscription Scope)

```bash
az deployment sub create \
  --location "uksouth" \
  --template-file "DataConnectors/azure-activity.json" \
  --parameters \
    workspaceName="law-sentinel-prod" \
    workspaceResourceGroup="rg-sentinel-prod"
```

### Deploy a Single Connector

```bash
az deployment group create \
  --resource-group "rg-sentinel-prod" \
  --template-file "DataConnectors/office365.json" \
  --parameters workspaceName="law-sentinel-prod"
```

---

## Troubleshooting

| Issue | Cause | Resolution |
|---|---|---|
| `AuthorizationFailed` | Service principal lacks permissions | Ensure `Microsoft Sentinel Contributor` on the RG and `Contributor` on the subscription |
| `ResourceNotFound` for workspace | Workspace name incorrect or in different subscription | Verify `SENTINEL_WORKSPACE_NAME` and `SENTINEL_RESOURCE_GROUP` variables |
| Connector not appearing in Sentinel | Deployment succeeded but connector not visible | Check Sentinel > Data connectors in the Portal; some connectors take a few minutes to appear |
| `WorkspaceNotOnboarded` | Sentinel not enabled on the workspace | Enable Sentinel on the workspace first (use `sentinel-deployment.json` from the parent folder) |
| OIDC login failure | Federated credential subject mismatch | Ensure the `subject` in the federated credential matches the repo name, branch, and environment exactly |
| `DeploymentQuotaExceeded` | Over 800 deployments in the resource group | Delete old deployments: `az deployment group list --resource-group <RG> --query "[?properties.timestamp<'2025-01-01']" --output tsv \| xargs -I {} az deployment group delete --resource-group <RG> --name {}` |
| Azure Activity connector fails | Diagnostic setting already exists | Use a unique `diagnosticSettingName` or update the existing one |

---

## Relationship to the Main Sentinel Deployment

| Template | Scope | Purpose |
|---|---|---|
| `sentinel-deployment.json` (parent folder) | Full workspace build | Creates the workspace, enables Sentinel, deploys 4 connectors, UEBA, and IAM in a single template |
| This repository | Connector management | Manages individual connectors as code with CI/CD, supports adding/removing connectors independently |

Use the main template for initial workspace provisioning. Use this repository for ongoing connector management and to extend beyond the original 4 connectors.

---

*For questions or issues, raise an issue in the repository or contact the security engineering team.*
