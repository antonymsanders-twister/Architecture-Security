# Azure Budget with Cost Alert Notifications

> **Template:** `azure-budget.json`
> **Purpose:** Creates an Azure budget with configurable soft and hard spending limits and email alert notifications at subscription or resource group scope.

---

## Overview

This template creates an Azure budget using the `Microsoft.Consumption/budgets` resource. It monitors actual and forecasted spending against a defined budget amount and sends email notifications when configurable thresholds are reached.

### Scope Selection

The first parameter you choose is **budgetScope**, which controls what the budget monitors:

| Scope | What It Monitors | When to Use |
|---|---|---|
| **Subscription** | All spending across the entire subscription | General cost governance for the whole subscription |
| **ResourceGroup** | Only spending in the resource group you specify | Targeted cost monitoring for specific workloads (e.g., Sentinel) |

When you select `ResourceGroup`, the budget is deployed **directly into the target resource group** via a nested deployment — this ensures it is properly scoped (not just filtered at subscription level).

> For **management group** scope, use the Azure CLI or REST API directly — see [Management Group Budget](#management-group-budget-cli-only) below.

### Alert Types

The template creates up to three alert notifications:

| Alert | Type | Default Threshold | Description |
|---|---|---|---|
| **Soft Limit** | Actual spend | **80%** of budget | Early warning — spend is approaching the budget. Take action to reduce costs or plan for the overage |
| **Hard Limit** | Actual spend | **100%** of budget | Critical — the full budget amount has been reached or exceeded |
| **Forecast Limit** | Forecasted spend | **100%** of budget | Predictive — Azure forecasts that spend will reach the budget before the period ends (enabled by default, can be disabled) |

> **Note:** Azure budgets are **informational only** — they send alerts but do **not** automatically stop or restrict resource usage. To enforce spending limits, combine budgets with Azure Policy or automation triggered by Action Groups.

---

## Prerequisites

| Requirement | Details |
|---|---|
| **Scope** | An active subscription or resource group |
| **Permissions** | `Contributor` or `Cost Management Contributor` role on the target scope |
| **Billing data** | The subscription must have at least one billing cycle of data for forecasted alerts to work accurately |

---

## Parameters

### Scope Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `budgetScope` | string | `Subscription` | **Select the scope:** `Subscription` (monitors entire subscription) or `ResourceGroup` (monitors a specific resource group) |
| `resourceGroupName` | string | *(empty)* | **Only used when budgetScope is `ResourceGroup`.** Name of the resource group to monitor. Must be an existing resource group. Leave empty for Subscription scope |

### Required Parameters

| Parameter | Type | Description |
|---|---|---|
| `budgetAmount` | int | Total budget amount in the subscription's billing currency (e.g., `1000` for £1,000) |
| `contactEmails` | string | Comma-separated email addresses to receive alert notifications (e.g., `admin@contoso.com,finance@contoso.com`) |

### Budget Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `budgetName` | string | `budget-monthly` | Name of the budget (must be unique within the scope) |
| `timeGrain` | string | `Monthly` | Budget period: `Monthly`, `Quarterly`, `Annually`, `BillingMonth`, `BillingQuarter`, `BillingAnnual` |
| `startDate` | string | *1st of current month* | Budget start date in `YYYY-MM-01` format. Defaults to the 1st of the current month |
| `endDate` | string | *(empty — rolling)* | End date in `YYYY-MM-01` format. Leave empty for a rolling budget with no end date |

### Alert Thresholds

| Parameter | Type | Default | Description |
|---|---|---|---|
| `softLimitPercentage` | int | `80` | Percentage threshold for the soft limit (warning) alert |
| `hardLimitPercentage` | int | `100` | Percentage threshold for the hard limit (critical) alert |
| `forecastAlertPercentage` | int | `100` | Percentage threshold for the forecasted spend alert |
| `enableForecastAlert` | bool | `true` | Enable or disable the forecasted spend alert |

### Notification Settings

| Parameter | Type | Default | Description |
|---|---|---|---|
| `contactRoles` | array | `["Owner", "Contributor"]` | RBAC roles whose members also receive notifications |
| `actionGroupResourceIds` | array | `[]` | Azure Monitor Action Group resource IDs for advanced notifications (Teams, SMS, webhooks) |

---

## Deployment Options

### Option A: Deploy via Template Spec (Recommended — Resource Group Dropdown)

Deploying as a Template Spec gives you the best Portal experience: a **resource group picker dropdown**, slider controls for thresholds, and email validation. The `azure-budget.createUiDefinition.json` file provides this custom UI.

**One-time setup — create the Template Spec:**

```bash
# Create a Template Spec with the UI definition
az ts create \
  --name "azure-budget" \
  --version "1.0" \
  --resource-group "rg-template-specs" \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --ui-form-definition "azure-budget.createUiDefinition.json" \
  --description "Azure budget with cost alert notifications for subscription or resource group scope"
```

**Deploy from the Portal:**

1. In the Azure Portal, search for **Template specs**
2. Select the `azure-budget` Template Spec and click **Deploy**
3. The custom form appears with:
   - A **Budget Scope** dropdown (`Subscription` or `Resource Group`)
   - A **Resource Group picker** (only visible when `Resource Group` is selected)
   - **Slider controls** for soft/hard thresholds
   - **Email validation** for alert recipients
4. Fill in the fields and click **Review + Create**, then **Create**

### Option B: Deploy via Portal — Custom Deployment

If you are not using Template Specs, you can paste the template directly:

1. In the Azure Portal, search for **Deploy a custom template**
2. Click **Build your own template in the editor**
3. Paste the contents of `azure-budget.json` and click **Save**
4. Select your **Subscription** and **Region**
5. Set **Budget Scope** to `Subscription` or `ResourceGroup`
6. If you selected `ResourceGroup`, type the resource group name in **Resource Group Name**
7. Fill in `budgetAmount` and `contactEmails`
8. Adjust thresholds if needed (defaults: 80% soft, 100% hard)
9. Click **Review + Create**, then **Create**

### Subscription Scope — CLI

```bash
# Budget for the entire subscription (startDate defaults to 1st of current month)
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetScope="Subscription" \
    budgetName="budget-sentinel-monthly" \
    budgetAmount=500 \
    contactEmails="admin@contoso.com,finance@contoso.com"
```

### Resource Group Scope — CLI

```bash
# Budget scoped to a specific resource group
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetScope="ResourceGroup" \
    resourceGroupName="rg-sentinel-prod" \
    budgetName="budget-rg-sentinel-prod" \
    budgetAmount=200 \
    contactEmails="admin@contoso.com"
```

### Resource Group Scope — PowerShell

```powershell
New-AzDeployment `
  -Location "uksouth" `
  -TemplateFile "azure-budget.json" `
  -budgetScope "ResourceGroup" `
  -resourceGroupName "rg-sentinel-prod" `
  -budgetName "budget-rg-sentinel-prod" `
  -budgetAmount 200 `
  -contactEmails "admin@contoso.com"
```

### Management Group Budget (CLI Only)

Management group scope cannot be deployed via this ARM template. Use the Azure CLI or REST API directly:

**Azure CLI:**

```bash
az consumption budget create \
  --budget-name "budget-mg-security" \
  --amount 5000 \
  --time-grain Monthly \
  --start-date "2026-03-01" \
  --end-date "2027-03-01" \
  --category Cost \
  --scope "/providers/Microsoft.Management/managementGroups/{management-group-id}" \
  --notifications \
    '{
      "SoftLimit": {
        "enabled": true,
        "operator": "GreaterThanOrEqualTo",
        "threshold": 80,
        "contactEmails": ["admin@contoso.com"],
        "contactRoles": ["Owner"]
      },
      "HardLimit": {
        "enabled": true,
        "operator": "GreaterThanOrEqualTo",
        "threshold": 100,
        "contactEmails": ["admin@contoso.com"],
        "contactRoles": ["Owner"]
      }
    }'
```

**REST API:**

```bash
az rest --method PUT \
  --url "https://management.azure.com/providers/Microsoft.Management/managementGroups/{management-group-id}/providers/Microsoft.Consumption/budgets/{budget-name}?api-version=2023-11-01" \
  --body '{
    "properties": {
      "category": "Cost",
      "amount": 5000,
      "timeGrain": "Monthly",
      "timePeriod": {
        "startDate": "2026-03-01",
        "endDate": "2027-03-01"
      },
      "notifications": {
        "SoftLimit": {
          "enabled": true,
          "operator": "GreaterThanOrEqualTo",
          "threshold": 80,
          "thresholdType": "Actual",
          "contactEmails": ["admin@contoso.com"],
          "contactRoles": ["Owner"]
        },
        "HardLimit": {
          "enabled": true,
          "operator": "GreaterThanOrEqualTo",
          "threshold": 100,
          "thresholdType": "Actual",
          "contactEmails": ["admin@contoso.com"],
          "contactRoles": ["Owner"]
        }
      }
    }
  }'
```

---

## Examples

### Example 1: Basic Monthly Subscription Budget (£500)

```bash
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetName="budget-sentinel-monthly" \
    budgetAmount=500 \
    contactEmails="secops@contoso.com"
```

This creates (starting from the 1st of the current month):
- Soft limit alert at **£400** (80% of £500)
- Hard limit alert at **£500** (100%)
- Forecast alert when Azure predicts spend will reach **£500**

### Example 2: Resource Group Budget for Sentinel

```bash
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetScope="ResourceGroup" \
    resourceGroupName="rg-sentinel-prod" \
    budgetName="budget-sentinel-rg" \
    budgetAmount=200 \
    contactEmails="sentinel-admins@contoso.com" \
    softLimitPercentage=75
```

### Example 3: Quarterly Budget with Custom Thresholds

```bash
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetName="budget-quarterly-security" \
    budgetAmount=3000 \
    timeGrain="Quarterly" \
    startDate="2026-04-01" \
    endDate="2027-04-01" \
    softLimitPercentage=50 \
    hardLimitPercentage=90 \
    forecastAlertPercentage=80 \
    contactEmails="cfo@contoso.com,secops@contoso.com"
```

This creates:
- Soft limit alert at **£1,500** (50%)
- Hard limit alert at **£2,700** (90%)
- Forecast alert when projected spend reaches **£2,400** (80%)

### Example 4: Budget with Action Group (Teams/SMS)

```bash
# First, create an action group (or use an existing one)
AG_ID=$(az monitor action-group show \
  --resource-group "rg-monitoring" \
  --name "ag-cost-alerts" \
  --query id --output tsv)

# Deploy budget with action group
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetName="budget-with-teams" \
    budgetAmount=1000 \
    contactEmails="admin@contoso.com" \
    actionGroupResourceIds="[\"$AG_ID\"]"
```

---

## How to Check Existing Budgets

### Azure CLI

```bash
# List all budgets on the subscription
az consumption budget list --output table

# Show a specific budget
az consumption budget show --budget-name "budget-sentinel-monthly" --output json
```

### Azure Portal

1. Go to **Cost Management + Billing**
2. Select **Cost Management** > **Budgets**
3. Select your scope (management group, subscription, or resource group)
4. View existing budgets, their current spend, and alert status

### Azure PowerShell

```powershell
# List all budgets
Get-AzConsumptionBudget

# Show a specific budget
Get-AzConsumptionBudget -Name "budget-sentinel-monthly"
```

---

## Understanding Budget Alerts

### How Alerts Work

- Azure evaluates budgets **once per day** (not in real-time)
- Alerts are sent via email to the configured `contactEmails` and to users with the configured `contactRoles`
- If Action Groups are configured, those are also triggered (enabling Teams, SMS, webhook, or Logic App notifications)
- Alert emails include the current spend amount, percentage of budget, and a link to Cost Analysis in the Portal

### Threshold Types

| Type | Meaning | Use Case |
|---|---|---|
| **Actual** | Alert when actual accumulated spend reaches the threshold | React to current overspending |
| **Forecasted** | Alert when Azure's ML model predicts spend will reach the threshold by end of period | Proactively prevent overspending before it happens |

### What Happens When You Exceed the Budget

- **Nothing automatic** — Azure budgets are informational only
- Email alerts are sent to configured recipients
- Action Groups are triggered (if configured)
- The budget continues to track spend and send alerts
- **No resources are stopped, deleted, or throttled**

To enforce spending limits, combine budgets with:
- **Azure Policy** — deny new resource creation when budget is exceeded
- **Logic Apps** — triggered by Action Groups to shut down or deallocate resources
- **Azure Automation** — runbooks triggered by Action Groups to take corrective action

---

## Updating an Existing Budget

Re-deploying the template with the same `budgetName` will update the existing budget. You can change the amount, thresholds, contacts, or scope.

```bash
# Update budget amount and thresholds
az deployment sub create \
  --location "uksouth" \
  --template-file "azure-budget.json" \
  --parameters \
    budgetName="budget-sentinel-monthly" \
    budgetAmount=750 \
    softLimitPercentage=70 \
    hardLimitPercentage=95 \
    contactEmails="secops@contoso.com,finance@contoso.com"
```

---

## Deleting a Budget

**Azure CLI:**

```bash
az consumption budget delete --budget-name "budget-sentinel-monthly"
```

**Azure Portal:**

1. Go to **Cost Management** > **Budgets**
2. Select the budget and click **Delete**

---

## Troubleshooting

| Issue | Cause | Resolution |
|---|---|---|
| `BudgetStartDateMustBeFirstOfMonth` | Start date is not the 1st of a month | Use format `YYYY-MM-01` (e.g., `2026-03-01`) |
| `BudgetStartDateMustBeCurrentOrFuture` | Start date is in the past | Set `startDate` to the current month or a future month |
| `BudgetTimePeriodExceeded` | End date is more than 10 years from start | Set `endDate` within 10 years of `startDate`, or leave empty for rolling |
| No emails received | `contactEmails` was empty or malformed | Ensure at least one email is provided, comma-separated with no spaces |
| No forecast alerts received | Not enough billing history | Azure needs at least one full billing cycle to generate forecasts |
| Alerts delayed | Azure evaluates budgets daily | Budget alerts are not real-time; expect up to 24 hours latency |
| `AuthorizationFailed` | Insufficient permissions | Ensure you have `Contributor` or `Cost Management Contributor` on the target scope |
| `BudgetNameAlreadyExists` | Budget with same name exists at this scope | Use a different `budgetName` or update the existing budget by redeploying |
| Resource group filter not working | Resource group name misspelled or doesn't exist | Verify with `az group list --output table` |
| Budget scope wrong after changing | Re-deployed with different scope but same name | Delete the old budget first, then re-deploy with the new scope |

---

## Cost Guidance for Microsoft Sentinel

When setting a budget for a Sentinel deployment, consider:

| Component | Billing Model | Estimate Guidance |
|---|---|---|
| **Log Analytics ingestion** | Per GB ingested per day | Free tier: ~5 MB per user per day. Multiply by your total licence/seat count |
| **Sentinel solution** | Per GB analysed per day | Same data volume as Log Analytics ingestion |
| **Data retention** | First 90 days free, then per GB per month | Factor in retention beyond 90 days |
| **Automation rules** | Free | No cost for Sentinel automation rules |
| **Playbooks (Logic Apps)** | Per trigger/action execution | Depends on playbook complexity and frequency |

### Quick Budget Formula for Sentinel

```
Monthly Budget = (Daily Ingestion GB x 30 x Price per GB) + Playbook Costs + Retention Costs
```

For a small organisation (50 users, ~5 MB/user/day = 0.25 GB/day):
- Log Analytics: ~0.25 GB x 30 days x £2.30/GB = ~£17.25/month
- Sentinel: ~0.25 GB x 30 days x £1.84/GB = ~£13.80/month
- **Total: ~£31/month** (excluding free tier credits)

> **Tip:** Start with a conservative budget and adjust after 1-2 months of actual data collection. Use the forecasted alert to catch unexpected ingestion spikes early.

---

*For questions or issues, raise an issue in the repository or contact the security engineering team.*
