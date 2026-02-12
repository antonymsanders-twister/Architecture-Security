# Defender XDR RBAC Script — Execution Guide

> **Script:** `Deploy-DefenderXDR-RBAC.ps1`
> **Last Updated:** February 2026
> **Reference:** [02-RBAC-Users-and-Groups.md](02-RBAC-Users-and-Groups.md) | [03-Identity-Lifecycle-Management.md](03-Identity-Lifecycle-Management.md)

---

## Table of Contents

1. [What the Script Does](#1-what-the-script-does)
2. [Prerequisites](#2-prerequisites)
3. [Configuration Walkthrough](#3-configuration-walkthrough)
4. [Execution Steps](#4-execution-steps)
5. [Post-Script: Create Unified RBAC Roles in the Portal](#5-post-script-create-unified-rbac-roles-in-the-portal)
6. [Post-Script: Enable PIM for Privileged Groups](#6-post-script-enable-pim-for-privileged-groups)
7. [Validation & Testing](#7-validation--testing)
8. [Ongoing Maintenance](#8-ongoing-maintenance)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. What the Script Does

The script automates three phases of the Defender XDR Unified RBAC group model:

| Phase | What It Does | Idempotent |
|---|---|---|
| **Phase 1** | Creates 15 Entra ID security groups matching the naming convention in 02-RBAC-Users-and-Groups.md | Yes — skips groups that already exist |
| **Phase 2** | Adds users to groups based on the identity mapping (CISO, SOC Analysts, Admins, etc.) | Yes — skips users already in the group |
| **Phase 3** | Creates recurring access review schedules with the designated reviewer for each group | Yes — skips reviews that already exist |

### What the Script Does NOT Do

| Action | Why | What to Do Instead |
|---|---|---|
| Create Unified RBAC custom roles | Custom roles must be configured in the Defender portal UI or via the Security Graph API | See [Section 5](#5-post-script-create-unified-rbac-roles-in-the-portal) |
| Enable PIM for groups | PIM enablement requires the Entra PIM portal or Graph Beta API | See [Section 6](#6-post-script-enable-pim-for-privileged-groups) |
| Remove members from groups | The script only adds; it does not remove stale members | Access reviews handle this automatically |
| Configure Conditional Access | CA policies are environment-specific and should be designed separately | See Microsoft Learn CA documentation |

---

## 2. Prerequisites

### Software

| Requirement | Install Command |
|---|---|
| PowerShell 7+ | Pre-installed on most systems; or `winget install Microsoft.PowerShell` |
| Microsoft Graph PowerShell SDK | `Install-Module Microsoft.Graph -Scope CurrentUser` |

### Entra ID Permissions

The account running the script needs these Entra ID roles:

| Role | Purpose | Phase |
|---|---|---|
| **Groups Administrator** | Create security groups and manage membership | Phase 1, 2 |
| **Identity Governance Administrator** | Create access review schedule definitions | Phase 3 |

Alternatively, **Global Administrator** provides all permissions but is not recommended.

### Graph API Scopes

The script requires these Microsoft Graph scopes when connecting:

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","AccessReview.ReadWrite.All","User.Read.All"
```

### Licensing

| Feature | Licence Required |
|---|---|
| Security Groups | Entra ID Free (any tier) |
| Access Reviews | Entra ID Governance or Entra ID P2 |
| PIM (post-script) | Entra ID P2 or M365 E5 |

---

## 3. Configuration Walkthrough

All configuration is in the top section of the script. Here is a step-by-step guide.

### Step 1: Set the Naming Prefix

```powershell
$GroupPrefix = "SEC-Defender"     # Change to match your naming convention
$MailPrefix  = "sec-defender"     # Auto-generated mail alias prefix
```

If your organisation uses a different convention (e.g., `SG-XDR`, `GRP-SOC`), change these variables. All 15 groups will use this prefix.

### Step 2: Set Control Flags

```powershell
$CreateGroups        = $true      # Phase 1: create groups
$AssignMembers       = $true      # Phase 2: add users to groups
$CreateAccessReviews = $true      # Phase 3: configure access reviews
$DryRun              = $true      # Preview mode — no changes made
```

**Recommended approach:**
1. First run with `$DryRun = $true` to preview all actions
2. Then set `$DryRun = $false` and run again to apply

You can also run phases independently — for example, create groups first, then add members later:

```powershell
# Run 1: Create groups only
$CreateGroups        = $true
$AssignMembers       = $false
$CreateAccessReviews = $false

# Run 2: Add members only (after verifying groups in the portal)
$CreateGroups        = $false
$AssignMembers       = $true
$CreateAccessReviews = $false

# Run 3: Set up access reviews (after verifying membership)
$CreateGroups        = $false
$AssignMembers       = $false
$CreateAccessReviews = $true
```

### Step 3: Configure Group Definitions

Each group has a reviewer UPN and review frequency. Update the UPNs to match your organisation:

```powershell
"SOCAnalyst-Tier2" = @{
    Description     = "Senior SOC analysts — investigate, hunt, and respond"
    ReviewFrequency = "Quarterly"
    ReviewerUPN     = "soc.manager@contoso.com"     # ← Change this
}
```

| Review Frequency | When It Runs |
|---|---|
| `Monthly` | Every month — use for high-risk groups (ExternalSOC, BreakGlass) |
| `Quarterly` | Every 3 months — use for most operational groups |
| `SemiAnnual` | Every 6 months — use for low-risk read-only groups |

### Step 4: Configure Member Assignments

Map real user UPNs to their groups:

```powershell
$MemberAssignments = @{
    "jane.doe@yourcompany.com" = @(
        "SOCAnalyst-Tier2"
    )
    "john.smith@yourcompany.com" = @(
        "SOCAnalyst-Tier1"
    )
}
```

**Tips:**
- A user can belong to multiple groups (e.g., IR Lead gets `IncidentResponder` + `SOCAnalyst-Tier2`)
- For guest/external users, use their full external UPN format
- The break-glass accounts should be cloud-only accounts, not synced from AD

### Step 5: Configure Access Review Defaults

```powershell
$ReviewDurationDays        = 14              # Days reviewers have to respond
$DefaultDecisionOnTimeout  = "removeAccess"  # Remove access if no response
$AutoApplyResults          = $true           # Auto-apply reviewer decisions
$RequireJustification      = $true           # Reviewers must explain approvals
```

The `removeAccess` default on timeout enforces a "deny by default" posture — if the reviewer ignores the review, the user loses access. This is the most secure option.

---

## 4. Execution Steps

### Step 1: Open PowerShell 7

```powershell
pwsh
```

### Step 2: Install the Graph SDK (first time only)

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### Step 3: Connect to Microsoft Graph

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","AccessReview.ReadWrite.All","User.Read.All"
```

A browser window will open for authentication. Sign in with an account that has the required roles.

### Step 4: Navigate to the script directory

```powershell
cd "Security/XDR/Microsoft/Deployment Plan"
```

### Step 5: Run in Dry Run mode first

```powershell
.\Deploy-DefenderXDR-RBAC.ps1
```

Review the output. Every action will be prefixed with `[DRY RUN]` and show what **would** happen.

### Step 6: Review the dry run output

Verify:
- All 15 groups would be created with correct names
- All users are mapped to the correct groups
- Access reviews have the correct reviewer and frequency

### Step 7: Switch to live mode and execute

Open the script, change `$DryRun = $false`, save, and re-run:

```powershell
.\Deploy-DefenderXDR-RBAC.ps1
```

The script will ask you to type `CONFIRM` before making changes.

### Step 8: Verify in the Entra admin centre

Navigate to https://entra.microsoft.com > **Groups** and confirm:
- All groups exist with the correct names and descriptions
- Members are assigned correctly
- Access reviews are visible under **Identity Governance > Access Reviews**

---

## 5. Post-Script: Create Unified RBAC Roles in the Portal

After the groups exist, you need to create **Unified RBAC custom roles** in the Defender portal and assign them to these groups.

### Steps

1. Go to **https://security.microsoft.com**
2. Navigate to **Settings > Microsoft Defender XDR > Permissions and roles**
3. Click **Create custom role** for each role needed

### Role Configurations

Create these roles, assigning each to its corresponding Entra ID group:

#### SOC Analyst — Tier 1

| Setting | Value |
|---|---|
| Role Name | SOC Analyst - Tier 1 |
| Permissions | Alerts: Read+Manage, Incidents: Read+Manage, Hunting: Read, Response: Basic |
| Posture | Secure Score: Read |
| Assign To | SEC-Defender-SOCAnalyst-Tier1 |
| Scope | All devices |

#### SOC Analyst — Tier 2

| Setting | Value |
|---|---|
| Role Name | SOC Analyst - Tier 2 |
| Permissions | Alerts: Read+Manage, Incidents: Read+Manage, Hunting: Read+Custom, Response: Full |
| Raw Data | All sources: Read |
| Posture | Secure Score: Read |
| Assign To | SEC-Defender-SOCAnalyst-Tier2 |
| Scope | All devices |

#### SOC Manager

| Setting | Value |
|---|---|
| Role Name | SOC Manager |
| Permissions | All Security Operations: Read+Manage, Response: Full |
| Raw Data | All sources: Read |
| Posture | Secure Score: Read |
| Assign To | SEC-Defender-SOCManager |
| Scope | All devices |

#### Threat Hunter

| Setting | Value |
|---|---|
| Role Name | Threat Hunter |
| Permissions | Alerts: Read, Incidents: Read, Hunting: Read+Create Custom Detections |
| Raw Data | All sources: Read |
| Assign To | SEC-Defender-ThreatHunter |
| Scope | All data sources |

#### Security Reader

| Setting | Value |
|---|---|
| Role Name | Security Reader |
| Permissions | Alerts: Read, Incidents: Read, Posture: Read |
| Assign To | SEC-Defender-SecurityReader |
| Scope | All devices |

#### External SOC (MSSP)

| Setting | Value |
|---|---|
| Role Name | External SOC Analyst |
| Permissions | Alerts: Read+Manage, Incidents: Read+Manage, Response: Basic |
| Assign To | SEC-Defender-ExternalSOC |
| Scope | MSSP-managed device group only |

> Refer to Section 6 of [02-RBAC-Users-and-Groups.md](02-RBAC-Users-and-Groups.md) for the full set of custom role definitions.

---

## 6. Post-Script: Enable PIM for Privileged Groups

The following groups should have **Privileged Identity Management** enabled so membership is just-in-time rather than standing:

| Group | PIM | Activation Duration | Approval Required |
|---|---|---|---|
| SEC-Defender-GlobalAdmin-BreakGlass | Yes | 1 hour | CISO |
| SEC-Defender-SecurityAdmin | Yes | 4 hours | CISO |
| SEC-Defender-SOCManager | Yes | 8 hours | Security Director |
| SEC-Defender-IncidentResponder | Yes | 8 hours | SOC Manager |
| SEC-Defender-ExternalSOC | Yes | 8 hours | SOC Manager |

### Steps to Enable PIM for Groups

1. Go to **https://entra.microsoft.com**
2. Navigate to **Identity Governance > Privileged Identity Management > Groups**
3. Click **Discover groups** and select the groups listed above
4. For each group, configure:
   - **Eligible assignments** — add users who can activate membership
   - **Activation settings** — MFA required, justification required, approval workflow
   - **Assignment settings** — maximum activation duration, expiry

See Section 6 of [03-Identity-Lifecycle-Management.md](03-Identity-Lifecycle-Management.md) for detailed PIM configuration per group.

---

## 7. Validation & Testing

### Checklist

| # | Test | Expected Result |
|---|---|---|
| 1 | Sign in as SOC Analyst T1 | Can see alerts and incidents; cannot run advanced hunting |
| 2 | Sign in as SOC Analyst T2 | Can see alerts, incidents, run hunting, and take response actions |
| 3 | Sign in as Threat Hunter | Can run advanced hunting and access raw data; cannot take response actions |
| 4 | Sign in as Security Reader | Read-only access to all dashboards; no manage or response capability |
| 5 | Sign in as External SOC | Can manage alerts/incidents only for MSSP-scoped device group |
| 6 | Sign in as Security Admin | Full access including RBAC management |
| 7 | PIM activation test | Eligible user can activate SecurityAdmin role; requires MFA and approval |
| 8 | Access review test | SOC Manager receives review email; can approve/deny membership |
| 9 | Offboard test | Remove user from group; confirm they lose Defender portal access within minutes |

### Useful PowerShell Validation Commands

```powershell
# List all Defender groups
Get-MgGroup -Filter "startsWith(displayName, 'SEC-Defender')" | Select DisplayName, Id, Description

# List members of a specific group
$group = Get-MgGroup -Filter "displayName eq 'SEC-Defender-SOCAnalyst-Tier1'"
Get-MgGroupMember -GroupId $group.Id | ForEach-Object {
    Get-MgUser -UserId $_.Id | Select DisplayName, UserPrincipalName
}

# List all access reviews for Defender groups
Get-MgIdentityGovernanceAccessReviewDefinition | Where-Object {
    $_.DisplayName -like "*Defender*"
} | Select DisplayName, Status, @{N="Scope";E={$_.Scope.Query}}
```

---

## 8. Ongoing Maintenance

| Task | Frequency | How |
|---|---|---|
| Add new SOC analyst | As needed | Add their UPN to `$MemberAssignments` and re-run Phase 2 |
| Remove analyst who left | As needed | Remove from group in Entra portal (or let access review handle it) |
| Promote analyst (T1 → T2) | As needed | Remove from T1 group, add to T2 group in Entra portal |
| Review access review results | Per schedule | Check Identity Governance > Access Reviews in Entra portal |
| Audit group changes | Monthly | Review Entra audit logs or Sentinel KQL query from 03-Identity-Lifecycle-Management.md |
| Re-run script for new groups | As needed | Add new group definition to `$GroupDefinitions` and re-run |
| Update reviewer assignments | As needed | Change `ReviewerUPN` in `$GroupDefinitions` and re-run Phase 3 |

### Re-Running the Script

The script is idempotent. You can safely re-run it at any time:
- Existing groups are skipped (not duplicated)
- Existing members are skipped (not re-added)
- Existing access reviews are skipped (not duplicated)
- Only new groups, members, or reviews are created

---

## 9. Troubleshooting

| Issue | Cause | Resolution |
|---|---|---|
| `Not connected to Microsoft Graph` | Forgot to connect before running | Run `Connect-MgGraph -Scopes "..."` first |
| `Insufficient privileges` | Account lacks Groups Admin or Governance Admin | Assign the required Entra ID roles to your account |
| `User not found: user@contoso.com` | UPN is incorrect or user doesn't exist | Verify the UPN in Entra admin centre |
| `Access review creation fails` | Missing Entra ID P2 or Governance licence | Verify licensing in Entra admin centre > Licences |
| `Group already exists` | Script detected an existing group | This is expected — the script skips it and uses the existing group |
| `AccessReview.ReadWrite.All scope not consented` | Admin consent required for the Graph scope | An admin needs to grant consent, or use `Connect-MgGraph` with `-ContextScope Process` |
| Script runs but users can't access Defender portal | Groups exist but no Unified RBAC role is assigned to them | Create custom roles in the Defender portal (Section 5) |
| PIM not working for groups | PIM not enabled for the group | Enable PIM for the group in Entra portal (Section 6) |

---

*Disclaimer: Always test in a non-production tenant first. Verify all actions in the Entra admin centre after execution.*
