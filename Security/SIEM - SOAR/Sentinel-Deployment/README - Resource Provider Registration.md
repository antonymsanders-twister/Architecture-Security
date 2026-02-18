# Resource Provider Registration for Microsoft Sentinel

> **Template:** `01-resource-provider-Sentinel.json`
> **Purpose:** Registers the required Azure resource providers on your subscription before deploying Microsoft Sentinel.

---

## Overview

Before Microsoft Sentinel can be deployed, three Azure resource providers must be registered on the target subscription. This template automates the check-and-register process using an Azure `deploymentScript` resource that runs Azure CLI commands inside a container instance.

The script runs under the identity of the **user or service principal that submits the deployment** — no separate Managed Identity is required. If you deploy the template from the Azure CLI, it runs as your logged-in Azure account. If deployed via an Azure DevOps pipeline, it runs as the pipeline's service connection identity.

### Providers Registered

| Provider Namespace | Required For | Description |
|---|---|---|
| `Microsoft.OperationalInsights` | Log Analytics Workspace | Enables creation and management of Log Analytics workspaces, which store all Sentinel data |
| `Microsoft.OperationsManagement` | Sentinel Solution | Enables the SecurityInsights solution (the OMS Gallery package that activates Sentinel on a workspace) |
| `Microsoft.SecurityInsights` | Microsoft Sentinel | Enables Sentinel-specific resources: data connectors, analytics rules, incidents, UEBA settings, and automation |

---

## Prerequisites

| Requirement | Details |
|---|---|
| **Azure Subscription** | Active subscription where you want to deploy Sentinel |
| **Permissions** | `Contributor` role on the subscription (required to register resource providers) — the deploying user or service principal must have this |
| **Resource Group** | Any existing resource group to host the deployment script resource (the script itself operates at subscription level) |

> **No Managed Identity needed.** The deployment script runs as the user or service principal that submits the deployment (API version `2023-08-01`). The deploying identity just needs `Contributor` on the subscription.

---

## Deployment Options

### Option A: Deploy via Azure CLI (Recommended for Manual Use)

If you just need to register the providers without the ARM template, run these commands directly:

```bash
# Register all three providers
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.SecurityInsights
```

### Option B: Deploy the ARM Template

The template runs as your currently logged-in Azure CLI identity — no extra parameters needed for authentication:

```bash
# Deploy the template to a resource group (runs as the logged-in user)
az deployment group create \
  --resource-group "rg-sentinel-prod" \
  --template-file "01-resource-provider-Sentinel.json"
```

To selectively skip a provider, pass the toggle parameters:

```bash
# Example: only register SecurityInsights (skip the other two)
az deployment group create \
  --resource-group "rg-sentinel-prod" \
  --template-file "01-resource-provider-Sentinel.json" \
  --parameters \
    enableOperationalInsights=false \
    enableOperationsManagement=false \
    enableSecurityInsights=true
```

### Option C: Deploy via Azure Portal

1. Go to **Deploy a custom template** in the Azure Portal
2. Click **Build your own template in the editor**
3. Paste the contents of `01-resource-provider-Sentinel.json`
4. Select the target subscription and resource group
5. Optionally toggle which providers to register
6. Click **Review + Create**

The script will run under your Portal login identity.

---

## How to Check if Providers Are Registered

### Check All Three at Once

```bash
az provider show --namespace Microsoft.OperationalInsights --query "{Provider:namespace, State:registrationState}" --output table
az provider show --namespace Microsoft.OperationsManagement --query "{Provider:namespace, State:registrationState}" --output table
az provider show --namespace Microsoft.SecurityInsights --query "{Provider:namespace, State:registrationState}" --output table
```

### Check a Single Provider

```bash
az provider show --namespace Microsoft.SecurityInsights --query "registrationState" --output tsv
```

Expected output when registered:

```
Registered
```

### One-Liner to Check All Three

```bash
for NS in Microsoft.OperationalInsights Microsoft.OperationsManagement Microsoft.SecurityInsights; do
  echo -n "$NS: "
  az provider show --namespace "$NS" --query "registrationState" --output tsv
done
```

Expected output:

```
Microsoft.OperationalInsights: Registered
Microsoft.OperationsManagement: Registered
Microsoft.SecurityInsights: Registered
```

### Check via Azure Portal

1. Go to **Subscriptions** > select your subscription
2. Under **Settings**, click **Resource providers**
3. Search for each provider name and confirm the status shows **Registered**

### Check via PowerShell

```powershell
Get-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights | Select-Object ProviderNamespace, RegistrationState
Get-AzResourceProvider -ProviderNamespace Microsoft.OperationsManagement | Select-Object ProviderNamespace, RegistrationState
Get-AzResourceProvider -ProviderNamespace Microsoft.SecurityInsights | Select-Object ProviderNamespace, RegistrationState
```

---

## Typical Registration Wait Times

Resource provider registration is **not instant**. The time varies depending on the provider and the current state of the subscription.

### Expected Timings

| Provider | Typical Wait Time | Notes |
|---|---|---|
| `Microsoft.OperationalInsights` | **30 seconds – 2 minutes** | Usually the fastest to register; commonly already registered on subscriptions that have used Azure Monitor |
| `Microsoft.OperationsManagement` | **30 seconds – 3 minutes** | Slightly slower; registers the solutions management framework |
| `Microsoft.SecurityInsights` | **1 – 5 minutes** | Often the slowest of the three; may take up to 10 minutes in rare cases |

### Total Expected Time

| Scenario | Time |
|---|---|
| All three already registered | **< 10 seconds** (just checking state) |
| One provider needs registering | **1 – 5 minutes** |
| All three need registering | **3 – 10 minutes** |
| Worst case (busy subscription, large tenant) | **Up to 15 minutes** |

### What Affects Registration Time

- **Subscription age and size** — older subscriptions with many resources may take slightly longer
- **Azure region load** — registration is a global operation but can be slower during peak periods
- **Provider complexity** — `Microsoft.SecurityInsights` has more resource types to register than the others
- **First-time registration** — the first registration on a subscription is typically slower than subsequent ones
- **Tenant size** — large enterprise tenants with complex policies may experience additional latency

### Registration States

During the process, providers pass through these states:

| State | Meaning |
|---|---|
| `NotRegistered` | Provider has never been registered on this subscription |
| `Registering` | Registration is in progress — wait for it to complete |
| `Registered` | Provider is fully registered and ready to use |
| `Unregistering` | Provider is being unregistered (rare, usually manual) |

> **Important:** Do **not** proceed with the Sentinel deployment until all three providers show `Registered`. Deploying resources against an unregistered provider will result in a `ResourceProviderNotRegistered` error.

---

## Troubleshooting

| Issue | Cause | Resolution |
|---|---|---|
| Provider stuck in `Registering` | Azure backend processing delay | Wait up to 15 minutes; if still stuck, run `az provider register --namespace <PROVIDER>` again |
| `AuthorizationFailed` on register | Insufficient permissions | Ensure the deploying user or service principal has `Contributor` role on the subscription |
| Provider shows `NotRegistered` after register command | Command didn't complete | Use `az provider register --namespace <PROVIDER> --wait` to block until complete |
| `DeploymentScriptError` in template | Container instance failed to start | Check the deployment script logs in the resource group; ensure the deploying identity has permission to create container instances |
| Provider registered but Sentinel deployment still fails | Propagation delay | Wait 2-3 minutes after registration before deploying Sentinel resources |

### Force Re-Registration

If a provider is in an inconsistent state, you can unregister and re-register it:

```bash
# Unregister (only if needed — this may affect existing resources)
az provider unregister --namespace Microsoft.SecurityInsights

# Wait for unregistration to complete
az provider show --namespace Microsoft.SecurityInsights --query "registrationState" --output tsv

# Re-register
az provider register --namespace Microsoft.SecurityInsights --wait
```

> **Warning:** Unregistering a provider does not delete existing resources, but it prevents new resources of that type from being created until re-registered. Only do this as a last resort.

---

## Relationship to the Main Pipeline

The main Sentinel deployment pipeline (`azure-pipelines.yml`) includes its own automatic provider registration step in both the **Validate** and **Deploy** stages. You only need to use this standalone template (`01-resource-provider-Sentinel.json`) if:

- You want to register providers **before** setting up the pipeline
- You are deploying Sentinel **manually** (without the pipeline)
- Your subscription has **restricted permissions** and a separate team manages provider registration
- You want to **verify** provider state as a standalone operation

If you are using the full pipeline, provider registration is handled automatically and this template is optional.

---

*For questions or issues, raise an issue in the repository or contact the security engineering team.*
