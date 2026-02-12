# Microsoft Defender XDR — Identity Lifecycle Management

> **Last Updated:** February 2026
> **Scope:** Managing the lifecycle of Defender XDR security roles using Entra ID Governance — onboarding, access reviews, PIM, and offboarding.

---

## Table of Contents

1. [Why Lifecycle Management for XDR Roles](#1-why-lifecycle-management-for-xdr-roles)
2. [Lifecycle Management Components](#2-lifecycle-management-components)
3. [Onboarding — Joiner Workflows](#3-onboarding--joiner-workflows)
4. [Role Changes — Mover Workflows](#4-role-changes--mover-workflows)
5. [Offboarding — Leaver Workflows](#5-offboarding--leaver-workflows)
6. [Privileged Identity Management (PIM) for XDR Roles](#6-privileged-identity-management-pim-for-xdr-roles)
7. [Access Reviews for XDR Groups](#7-access-reviews-for-xdr-groups)
8. [Entitlement Management — Access Packages](#8-entitlement-management--access-packages)
9. [Automation with Lifecycle Workflows](#9-automation-with-lifecycle-workflows)
10. [Monitoring & Audit](#10-monitoring--audit)
11. [Implementation Checklist](#11-implementation-checklist)
12. [Key Reference Links](#12-key-reference-links)

---

## 1. Why Lifecycle Management for XDR Roles

Defender XDR roles grant access to sensitive security data — alerts, incidents, raw telemetry, and response actions. Without lifecycle management:

| Risk | Impact |
|---|---|
| **Orphaned access** | Former analysts retain access to security tools after role change or departure |
| **Privilege creep** | Analysts accumulate permissions over time without review |
| **Standing privileges** | Permanent admin access creates a persistent attack surface |
| **No audit trail** | Cannot demonstrate who had access and when for compliance |
| **Delayed onboarding** | New SOC analysts wait days for manual access provisioning |

### Lifecycle Management Addresses

- **Automated provisioning** — new analysts get access on day one
- **Just-in-time elevation** — admins activate privileges only when needed
- **Periodic review** — managers attest to continued access need quarterly
- **Automated deprovisioning** — leavers lose access immediately
- **Full audit trail** — every access change is logged for compliance

---

## 2. Lifecycle Management Components

| Component | Service | Purpose |
|---|---|---|
| **Lifecycle Workflows** | Entra ID Governance | Automate joiner/mover/leaver processes |
| **Entitlement Management** | Entra ID Governance | Self-service access request with approval workflows |
| **Access Reviews** | Entra ID Governance | Periodic recertification of group membership |
| **Privileged Identity Management (PIM)** | Entra ID P2 | Just-in-time role activation for privileged operations |
| **Conditional Access** | Entra ID P1/P2 | Context-aware access policies for XDR portal |
| **Dynamic Groups** | Entra ID P1 | Attribute-based automatic group membership |
| **Audit Logs** | Entra ID | Full audit trail of all access changes |

### Licensing Required

| Feature | Licence |
|---|---|
| PIM | Entra ID P2 or M365 E5 |
| Access Reviews | Entra ID Governance or M365 E5 |
| Lifecycle Workflows | Entra ID Governance |
| Entitlement Management | Entra ID Governance or Entra ID P2 (basic) |
| Conditional Access | Entra ID P1 or M365 E3+ |
| Dynamic Groups | Entra ID P1 |

---

## 3. Onboarding — Joiner Workflows

### Scenario: New SOC Analyst Joins

When a new SOC analyst is hired, they need access to Defender XDR on or before their start date.

#### Option A: Lifecycle Workflow (Automated)

Configure a **pre-hire workflow** triggered by the employee's start date in HR systems (Workday, SAP SuccessFactors, etc.) via Entra ID inbound provisioning.

```
Trigger:    Employee start date - 1 day (pre-hire)
Condition:  Department = "Security Operations" AND Job Title contains "Analyst"

Actions:
  1. Enable user account
  2. Add to SEC-Defender-SOCAnalyst-Tier1 (security group)
  3. Add to Defender XDR access package (entitlement management)
  4. Send welcome email with onboarding instructions
  5. Generate temporary access pass for first sign-in
```

#### Option B: Entitlement Management (Self-Service Request)

1. Create an **Access Package** called "Defender XDR — SOC Analyst Tier 1"
2. Package includes membership in `SEC-Defender-SOCAnalyst-Tier1`
3. New analyst (or their manager) requests the package
4. SOC Manager approves the request
5. Access is granted with a defined expiry (e.g., 12 months, renewable)

#### Option C: Manual Assignment

1. Security administrator manually adds user to the appropriate Entra ID security group
2. Unified RBAC applies permissions automatically based on group membership

> **Recommendation:** Use Lifecycle Workflows for fully automated onboarding where HR integration exists. Use Entitlement Management as a self-service alternative.

---

## 4. Role Changes — Mover Workflows

### Scenario: Analyst Promoted from Tier 1 to Tier 2

```
Trigger:    Job title change detected (HR integration) OR manager submits request
Condition:  Previous group = SEC-Defender-SOCAnalyst-Tier1

Actions:
  1. Remove from SEC-Defender-SOCAnalyst-Tier1
  2. Add to SEC-Defender-SOCAnalyst-Tier2
  3. Notify the user and their manager of the access change
  4. Log the change for audit
```

### Scenario: Analyst Moves to Non-Security Role

```
Trigger:    Department change from "Security Operations" to another department
Condition:  User is member of any SEC-Defender-* group

Actions:
  1. Remove from ALL SEC-Defender-* security groups
  2. Revoke any active PIM role assignments
  3. Revoke any active access package assignments
  4. Notify the user's new manager
  5. Log the change for audit
```

### Using Dynamic Groups for Automatic Moves

For attribute-driven changes, **dynamic security groups** can automatically add/remove users:

```
Group:  SEC-Defender-SOCAnalyst-Tier1
Type:   Dynamic Security Group
Rule:   (user.department -eq "Security Operations") and
        (user.jobTitle -contains "SOC Analyst") and
        (user.jobTitle -notContains "Senior")
```

```
Group:  SEC-Defender-SOCAnalyst-Tier2
Type:   Dynamic Security Group
Rule:   (user.department -eq "Security Operations") and
        ((user.jobTitle -contains "Senior SOC Analyst") or
         (user.jobTitle -contains "Lead SOC Analyst"))
```

> **Caution:** Dynamic groups depend on accurate HR attribute synchronisation. Use assigned groups for sensitive roles if HR data quality is uncertain.

---

## 5. Offboarding — Leaver Workflows

### Scenario: SOC Analyst Leaves the Organisation

```
Trigger:    Employee termination date (from HR system)
            OR account disable event

Actions (immediate — on last day):
  1. Remove from ALL SEC-Defender-* security groups
  2. Revoke ALL active PIM role assignments
  3. Revoke ALL entitlement management access packages
  4. Revoke ALL active sessions (Conditional Access: require re-authentication)
  5. Disable the user account
  6. Notify SOC Manager of access removal
  7. Log all changes for audit

Actions (post-departure — 30 days):
  8. Convert mailbox to shared (if needed for continuity)
  9. Remove from all remaining group memberships
  10. Delete account (per retention policy)
```

### Emergency Offboarding (Security Incident / Insider Threat)

```
Trigger:    Manual — initiated by Security Admin or HR

Actions (immediate):
  1. Disable user account
  2. Revoke all sessions (Entra ID: Revoke Sessions)
  3. Remove from ALL security groups
  4. Revoke ALL PIM assignments
  5. Block sign-in
  6. Preserve mailbox and OneDrive for investigation (legal hold)
  7. Notify IR team and Legal
  8. Audit the user's recent Defender XDR activity
```

---

## 6. Privileged Identity Management (PIM) for XDR Roles

### Which Groups Should Use PIM

| Group | PIM Required | Justification |
|---|---|---|
| `SEC-Defender-GlobalAdmin-BreakGlass` | **Yes** | Highest privilege; emergency only |
| `SEC-Defender-SecurityAdmin` | **Yes** | Can modify RBAC and policies |
| `SEC-Defender-SOCManager` | **Yes** | Full SOC operations access |
| `SEC-Defender-IncidentResponder` | **Yes** | Full response actions on devices and identities |
| `SEC-Defender-SOCAnalyst-Tier2` | Optional | Consider for advanced hunting and response actions |
| `SEC-Defender-SOCAnalyst-Tier1` | No | Standing access for daily triage operations |
| `SEC-Defender-SecurityReader` | No | Read-only; low risk |
| `SEC-Defender-ExternalSOC` | **Yes** | Third-party access should always be time-bound |

### PIM Configuration for Security Admin Group

| Setting | Value |
|---|---|
| Activation maximum duration | 4 hours |
| Require MFA on activation | Yes |
| Require justification | Yes |
| Require approval | Yes (approved by CISO or Security Director) |
| Require ticket information | Yes (link to change request or incident) |
| Notification on activation | Notify all Security Admins |
| Eligible assignment expiry | 12 months (re-eligible after access review) |

### PIM Configuration for Incident Responder Group

| Setting | Value |
|---|---|
| Activation maximum duration | 8 hours |
| Require MFA on activation | Yes |
| Require justification | Yes |
| Require approval | Yes (approved by SOC Manager) |
| Require ticket information | Yes (incident number) |
| Eligible assignment expiry | 12 months |

### PIM Configuration for MSSP External SOC

| Setting | Value |
|---|---|
| Activation maximum duration | 8 hours |
| Require MFA on activation | Yes |
| Require justification | Yes |
| Require approval | Yes (internal SOC Manager must approve) |
| Require ticket information | Yes |
| Eligible assignment expiry | 6 months (aligned with MSSP contract review) |

---

## 7. Access Reviews for XDR Groups

### Review Schedule

| Group | Review Frequency | Reviewer | Auto-Apply |
|---|---|---|---|
| `SEC-Defender-GlobalAdmin-BreakGlass` | Quarterly | CISO | No (manual) |
| `SEC-Defender-SecurityAdmin` | Quarterly | CISO | Yes (remove on deny) |
| `SEC-Defender-SOCManager` | Quarterly | Security Director | Yes |
| `SEC-Defender-SOCAnalyst-Tier2` | Quarterly | SOC Manager | Yes |
| `SEC-Defender-SOCAnalyst-Tier1` | Semi-annually | SOC Manager | Yes |
| `SEC-Defender-ThreatHunter` | Quarterly | SOC Manager | Yes |
| `SEC-Defender-DetectionEngineer` | Quarterly | SOC Manager | Yes |
| `SEC-Defender-IncidentResponder` | Quarterly | SOC Manager | Yes |
| `SEC-Defender-SecurityReader` | Semi-annually | Security Director | Yes |
| `SEC-Defender-EndpointAdmin` | Quarterly | Security Admin | Yes |
| `SEC-Defender-EmailAdmin` | Quarterly | Security Admin | Yes |
| `SEC-Defender-IdentityAdmin` | Quarterly | Security Admin | Yes |
| `SEC-Defender-CloudAppsAdmin` | Quarterly | Security Admin | Yes |
| `SEC-Defender-ExternalSOC` | Monthly | SOC Manager + Contract Owner | Yes |

### Access Review Configuration

```
Review Name:     Defender XDR - SOC Analyst Tier 2 Access Review
Scope:           Members of SEC-Defender-SOCAnalyst-Tier2
Frequency:       Quarterly
Duration:        14 days for reviewers to respond
Reviewer:        SOC Manager (group owner)
Fallback:        If reviewer doesn't respond, access is removed
Auto-apply:      Yes
Notifications:   Email reminder at start, day 7, and day 12
Recommendations: Show sign-in activity to help reviewer decide
```

---

## 8. Entitlement Management — Access Packages

### Access Package Design

| Package Name | Includes | Approval | Expiry | Requestable By |
|---|---|---|---|---|
| **Defender XDR — SOC Analyst Tier 1** | SEC-Defender-SOCAnalyst-Tier1 | SOC Manager | 12 months (renewable) | Security Operations dept |
| **Defender XDR — SOC Analyst Tier 2** | SEC-Defender-SOCAnalyst-Tier2 | SOC Manager | 12 months (renewable) | Security Operations dept |
| **Defender XDR — Threat Hunter** | SEC-Defender-ThreatHunter | SOC Manager | 12 months | Threat Intelligence dept |
| **Defender XDR — Incident Response** | SEC-Defender-IncidentResponder + T2 | SOC Manager + CISO | 6 months | IR team |
| **Defender XDR — Read Only (Auditor)** | SEC-Defender-SecurityReader | Security Admin | 90 days | Compliance, Audit, Management |
| **Defender XDR — MSSP Access** | SEC-Defender-ExternalSOC | SOC Manager + Contract Owner | 6 months | MSSP accounts (external users) |
| **Defender XDR — Platform Admin** | SEC-Defender-SecurityAdmin (PIM-eligible) | CISO | 12 months | Security team leads |

### Catalogue Structure

```
Catalogue:  "Security Operations Access"
├── Defender XDR — SOC Analyst Tier 1
├── Defender XDR — SOC Analyst Tier 2
├── Defender XDR — Threat Hunter
├── Defender XDR — Incident Response
├── Defender XDR — Read Only (Auditor)
├── Defender XDR — MSSP Access
└── Defender XDR — Platform Admin
```

---

## 9. Automation with Lifecycle Workflows

### Workflow Templates

#### Joiner: Security Operations New Hire

| Property | Value |
|---|---|
| Trigger | Employee hire date - 1 day |
| Conditions | Department = "Security Operations" |
| Actions | Enable account, add to SOC Analyst T1 group, send welcome email, generate TAP |

#### Mover: Promotion to Senior Analyst

| Property | Value |
|---|---|
| Trigger | Job title change (attribute change) |
| Conditions | New title contains "Senior SOC" AND Department = "Security Operations" |
| Actions | Remove from T1 group, add to T2 group, notify manager, log change |

#### Mover: Department Transfer Out of Security

| Property | Value |
|---|---|
| Trigger | Department attribute change |
| Conditions | Previous department = "Security Operations" AND new department != "Security Operations" |
| Actions | Remove from ALL SEC-Defender-* groups, revoke PIM assignments, revoke access packages, notify old and new manager |

#### Leaver: Employee Termination

| Property | Value |
|---|---|
| Trigger | Employee termination date |
| Conditions | User is member of any SEC-Defender-* group |
| Actions | Remove from all groups, revoke PIM, revoke access packages, disable account, send notification |

---

## 10. Monitoring & Audit

### Key Audit Events to Monitor

| Event | Source | Alert |
|---|---|---|
| User added to SEC-Defender-SecurityAdmin | Entra ID Audit Logs | High — immediate notification |
| User added to any SEC-Defender-* group | Entra ID Audit Logs | Medium — daily summary |
| PIM role activated for SecurityAdmin | Entra ID PIM Logs | High — immediate notification |
| PIM role activated for IncidentResponder | Entra ID PIM Logs | Medium — log and review |
| Access review completed with denials | Entra ID Governance | Medium — review removed users |
| Lifecycle workflow failure | Entra ID Governance | High — investigate and remediate |
| External user added to Defender group | Entra ID Audit Logs | High — verify authorisation |
| User removed from all Defender groups (offboarding) | Entra ID Audit Logs | Low — informational |

### Sentinel Integration

Forward Entra ID audit logs and PIM logs to Microsoft Sentinel for:
- Correlation with Defender XDR activity (did the user do anything suspicious before/after access change?)
- KQL-based hunting queries for access anomalies
- Automated playbooks for suspicious access patterns

### Example KQL: Detect Unexpected Defender Admin Group Changes

```kql
AuditLogs
| where OperationName == "Add member to group"
| where TargetResources[0].displayName startswith "SEC-Defender-"
| extend GroupName = TargetResources[0].displayName
| extend AddedUser = TargetResources[0].userPrincipalName
| extend Actor = InitiatedBy.user.userPrincipalName
| where GroupName in ("SEC-Defender-SecurityAdmin", "SEC-Defender-GlobalAdmin-BreakGlass")
| project TimeGenerated, Actor, AddedUser, GroupName, OperationName
| sort by TimeGenerated desc
```

---

## 11. Implementation Checklist

| # | Task | Owner | Status |
|---|---|---|---|
| 1 | Create all SEC-Defender-* security groups in Entra ID | Security Admin | ☐ |
| 2 | Configure Unified RBAC custom roles in Defender portal | Security Admin | ☐ |
| 3 | Assign custom roles to security groups | Security Admin | ☐ |
| 4 | Enable PIM for privileged groups (Admin, Manager, IR, MSSP) | Security Admin | ☐ |
| 5 | Configure PIM settings (duration, MFA, approval, justification) | Security Admin | ☐ |
| 6 | Create access packages in entitlement management | Security Admin | ☐ |
| 7 | Configure access review schedules per group | Security Admin | ☐ |
| 8 | Create lifecycle workflows (joiner, mover, leaver) | Identity Admin | ☐ |
| 9 | Test joiner workflow with test account | Identity Admin | ☐ |
| 10 | Test mover workflow (T1 → T2 promotion) | Identity Admin | ☐ |
| 11 | Test leaver workflow (offboarding) | Identity Admin | ☐ |
| 12 | Configure Conditional Access policies for Defender portal | Identity Admin | ☐ |
| 13 | Forward Entra ID audit + PIM logs to Sentinel | Security Engineer | ☐ |
| 14 | Create Sentinel analytics rules for access anomalies | Detection Engineer | ☐ |
| 15 | Document and communicate access request process to SOC team | SOC Manager | ☐ |
| 16 | Run first access review cycle | SOC Manager / CISO | ☐ |
| 17 | Review and tune lifecycle workflows after 30 days | Identity Admin | ☐ |

---

## 12. Key Reference Links

| Resource | Link |
|---|---|
| Entra ID Governance Overview | https://learn.microsoft.com/en-us/entra/id-governance/identity-governance-overview |
| Lifecycle Workflows | https://learn.microsoft.com/en-us/entra/id-governance/what-are-lifecycle-workflows |
| Access Reviews | https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview |
| Entitlement Management | https://learn.microsoft.com/en-us/entra/id-governance/entitlement-management-overview |
| PIM for Groups | https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/concept-pim-for-groups |
| Plan Access Reviews Deployment | https://learn.microsoft.com/en-us/entra/id-governance/deploy-access-reviews |
| Governance Deployment Guide | https://learn.microsoft.com/en-us/entra/architecture/governance-deployment-intro |
| Entra ID Governance Licensing | https://learn.microsoft.com/en-us/entra/id-governance/licensing-fundamentals |
| Defender XDR Unified RBAC | https://learn.microsoft.com/en-us/defender-xdr/manage-rbac |

---

*Disclaimer: Feature availability depends on licensing (Entra ID P2, Entra ID Governance, M365 E5). Verify requirements against the latest Microsoft documentation.*
