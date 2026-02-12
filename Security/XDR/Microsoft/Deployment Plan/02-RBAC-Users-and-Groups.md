# Microsoft Defender XDR — RBAC, Users & Groups Model

> **Last Updated:** February 2026
> **Scope:** Unified RBAC model, Entra ID security group design, role assignments, and suggested identity mapping for a common deployment.

---

## Table of Contents

1. [Unified RBAC Overview](#1-unified-rbac-overview)
2. [Entra ID Global Roles (Legacy)](#2-entra-id-global-roles-legacy)
3. [Unified RBAC Permission Groups](#3-unified-rbac-permission-groups)
4. [Suggested Security Group Model](#4-suggested-security-group-model)
5. [Suggested Identity Mapping — Common Deployment](#5-suggested-identity-mapping--common-deployment)
6. [Custom Role Definitions](#6-custom-role-definitions)
7. [Data Source Scoping & Device Groups](#7-data-source-scoping--device-groups)
8. [Activation & Migration to Unified RBAC](#8-activation--migration-to-unified-rbac)
9. [Key Reference Links](#9-key-reference-links)

---

## 1. Unified RBAC Overview

As of February 2025, the **Microsoft Defender XDR Unified RBAC** model is the default for all new Defender tenants. It replaces the legacy per-workload permission models with a single, centralised permissions management experience.

### Key Principles

| Principle | Details |
|---|---|
| **Least Privilege** | Grant only the minimum permissions required for each role |
| **Unified Management** | One permission model across Endpoint, Identity, Email, Cloud Apps |
| **Custom Roles** | Create fine-grained custom roles beyond the built-in options |
| **Group-Based Assignment** | Assign roles to Entra ID security groups (not individual users) |
| **Scoped Access** | Limit access by data source and device group |
| **No Global Admin Dependency** | Unified RBAC removes the need for Entra ID global roles for day-to-day operations |

### Workloads Covered

| Workload | Unified RBAC Support |
|---|---|
| Defender for Endpoint | Yes (default since Feb 2025) |
| Defender for Identity | Yes (default since Mar 2025) |
| Defender for Office 365 | Yes |
| Defender for Cloud Apps | Yes |
| Microsoft Sentinel | Separate Azure RBAC (integrates via Defender portal) |
| Defender for Cloud | Separate Azure RBAC |

---

## 2. Entra ID Global Roles (Legacy)

These Entra ID directory roles still provide access to the Defender portal but are **not recommended** for day-to-day operations. Use Unified RBAC custom roles instead.

| Entra ID Role | Defender XDR Access | When to Use |
|---|---|---|
| **Global Administrator** | Full access to everything | Emergency / break-glass only |
| **Security Administrator** | Full access to security settings, manage roles | Initial setup; transition to custom roles |
| **Security Operator** | View alerts + take response actions | Legacy; replace with custom role |
| **Security Reader** | Read-only access to all security data | Legacy; replace with custom role |
| **Global Reader** | Read-only across entire tenant | Auditors; consider scoped reader instead |

> **Recommendation:** After initial setup, create Unified RBAC custom roles and assign via security groups. Avoid relying on Entra ID global roles for ongoing operations.

---

## 3. Unified RBAC Permission Groups

Unified RBAC organises permissions into logical groups. Each custom role selects specific permissions from these groups.

### Permission Categories

| Category | Permissions | Use Case |
|---|---|---|
| **Security Operations** | View/manage alerts, incidents, advanced hunting, response actions | SOC analysts and operators |
| **Security Posture** | View/manage secure score, recommendations, posture | Security engineers and architects |
| **Authorization** | Manage RBAC roles, role assignments, and permissions | Security admins |
| **Security Data** | View raw data, advanced hunting, custom detections | Threat hunters and detection engineers |
| **Investigation** | View investigation details, take investigation actions | Incident responders |
| **Response** | Take response actions (isolate devices, run AV scan, collect investigation package) | SOC operators |

### Granular Permission Breakdown

| Permission | Read | Manage | Description |
|---|---|---|---|
| Security operations / Alerts | View alerts | Manage alerts (assign, classify, resolve) | Core SOC workflow |
| Security operations / Incidents | View incidents | Manage incidents (assign, classify, resolve) | Incident management |
| Security operations / Advanced hunting | Run queries | Create custom detections | Threat hunting |
| Security operations / Response actions | — | Take actions on devices, email, identities | Active response |
| Security posture / Posture management | View recommendations | Dismiss/complete recommendations | Posture management |
| Security posture / Secure score | View score | — | Dashboard visibility |
| Authorization / RBAC | View roles | Create/modify/delete roles | Admin function |
| Raw data / Email & collaboration | View email data | — | Email forensics |
| Raw data / Device | View device data | — | Endpoint forensics |
| Raw data / Identity | View identity data | — | Identity forensics |
| Raw data / Cloud apps | View cloud app data | — | CASB forensics |

---

## 4. Suggested Security Group Model

### Naming Convention

Use a consistent naming convention for all Defender XDR security groups:

```
SEC-Defender-{Role}-{Scope}
```

Examples:
- `SEC-Defender-SOCAnalyst-Tier1`
- `SEC-Defender-SOCAnalyst-Tier2`
- `SEC-Defender-ThreatHunter-Global`
- `SEC-Defender-SecurityAdmin-Global`

### Security Group Design

| Entra ID Security Group | Purpose | Group Type | Membership |
|---|---|---|---|
| `SEC-Defender-GlobalAdmin-BreakGlass` | Emergency access only | Assigned | 2 break-glass accounts |
| `SEC-Defender-SecurityAdmin` | Manage Defender XDR settings, RBAC, and policies | Assigned | Security team leads, CISO office |
| `SEC-Defender-SOCManager` | Full SOC operations + team management | Assigned | SOC managers |
| `SEC-Defender-SOCAnalyst-Tier2` | Investigate + respond to incidents; advanced hunting | Assigned | Senior SOC analysts |
| `SEC-Defender-SOCAnalyst-Tier1` | Triage alerts, manage incidents, basic response | Assigned | Junior SOC analysts |
| `SEC-Defender-ThreatHunter` | Advanced hunting, custom detections, raw data access | Assigned | Threat hunting team |
| `SEC-Defender-DetectionEngineer` | Create and manage custom detection rules | Assigned | Detection engineering team |
| `SEC-Defender-IncidentResponder` | Full response actions during active incidents | Assigned | IR team members |
| `SEC-Defender-SecurityPosture` | View and manage secure score and recommendations | Assigned | Security engineers, architects |
| `SEC-Defender-SecurityReader` | Read-only access across all Defender data | Assigned | Auditors, compliance, management |
| `SEC-Defender-EndpointAdmin` | Manage endpoint policies, onboarding, ASR rules | Assigned | Endpoint security team |
| `SEC-Defender-EmailAdmin` | Manage Defender for Office 365 policies | Assigned | Email security team |
| `SEC-Defender-IdentityAdmin` | Manage Defender for Identity sensors and policies | Assigned | Identity security team |
| `SEC-Defender-CloudAppsAdmin` | Manage Defender for Cloud Apps policies | Assigned | Cloud security team |
| `SEC-Defender-ExternalSOC` | Limited access for MSSP/outsourced SOC | Assigned | MSSP analyst accounts |

---

## 5. Suggested Identity Mapping — Common Deployment

### Organisational Role to Defender XDR Group Mapping

This mapping assumes a mid-to-large enterprise with a dedicated security operations function.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     IDENTITY MAPPING OVERVIEW                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  CISO / Security Director                                          │
│  └── SEC-Defender-SecurityReader                                   │
│  └── SEC-Defender-SecurityPosture                                  │
│                                                                     │
│  Security Operations Manager                                       │
│  └── SEC-Defender-SOCManager                                       │
│                                                                     │
│  SOC Analyst — Tier 2 (Senior)                                     │
│  └── SEC-Defender-SOCAnalyst-Tier2                                 │
│                                                                     │
│  SOC Analyst — Tier 1 (Junior)                                     │
│  └── SEC-Defender-SOCAnalyst-Tier1                                 │
│                                                                     │
│  Threat Hunter                                                      │
│  └── SEC-Defender-ThreatHunter                                     │
│                                                                     │
│  Detection Engineer                                                 │
│  └── SEC-Defender-DetectionEngineer                                │
│                                                                     │
│  Incident Response Lead                                             │
│  └── SEC-Defender-IncidentResponder                                │
│  └── SEC-Defender-SOCAnalyst-Tier2                                 │
│                                                                     │
│  Security Engineer / Architect                                      │
│  └── SEC-Defender-SecurityPosture                                  │
│  └── SEC-Defender-SecurityReader                                   │
│                                                                     │
│  Endpoint Security Specialist                                       │
│  └── SEC-Defender-EndpointAdmin                                    │
│  └── SEC-Defender-SOCAnalyst-Tier1                                 │
│                                                                     │
│  Email Security Specialist                                          │
│  └── SEC-Defender-EmailAdmin                                       │
│                                                                     │
│  Identity Security Specialist                                       │
│  └── SEC-Defender-IdentityAdmin                                    │
│                                                                     │
│  Cloud Security Specialist                                          │
│  └── SEC-Defender-CloudAppsAdmin                                   │
│                                                                     │
│  Security Platform Administrator                                    │
│  └── SEC-Defender-SecurityAdmin                                    │
│                                                                     │
│  Auditor / Compliance Officer                                       │
│  └── SEC-Defender-SecurityReader                                   │
│                                                                     │
│  MSSP / External SOC Analyst                                        │
│  └── SEC-Defender-ExternalSOC                                      │
│                                                                     │
│  IT Director / CTO (stakeholder visibility)                        │
│  └── SEC-Defender-SecurityReader                                   │
│                                                                     │
│  Break-Glass Accounts (emergency only)                              │
│  └── SEC-Defender-GlobalAdmin-BreakGlass                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Detailed Role-to-Permission Matrix

| Org Role | Entra Group | Alerts | Incidents | Hunting | Response Actions | Posture | RBAC Mgmt | Raw Data |
|---|---|---|---|---|---|---|---|---|
| **CISO** | SecurityReader + Posture | Read | Read | No | No | Read + Manage | No | No |
| **SOC Manager** | SOCManager | Read + Manage | Read + Manage | Yes | Yes | Read | No | Yes |
| **SOC Analyst T2** | SOCAnalyst-Tier2 | Read + Manage | Read + Manage | Yes | Yes | Read | No | Yes |
| **SOC Analyst T1** | SOCAnalyst-Tier1 | Read + Manage | Read + Manage | Limited | Limited | Read | No | No |
| **Threat Hunter** | ThreatHunter | Read | Read | Yes (full) | No | No | No | Yes (full) |
| **Detection Engineer** | DetectionEngineer | Read | Read | Yes + Create Custom | No | No | No | Yes |
| **IR Lead** | IncidentResponder + T2 | Read + Manage | Read + Manage | Yes | Yes (full) | No | No | Yes |
| **Security Engineer** | SecurityPosture + Reader | Read | Read | No | No | Read + Manage | No | No |
| **Platform Admin** | SecurityAdmin | Read + Manage | Read + Manage | Yes | Yes | Read + Manage | Yes | Yes |
| **Auditor** | SecurityReader | Read | Read | No | No | Read | No | Limited |
| **MSSP Analyst** | ExternalSOC | Read + Manage | Read + Manage | Limited | Limited | No | No | No |

### Small Organisation Simplified Mapping (< 500 users)

For smaller organisations without a dedicated SOC team:

| Org Role | Entra Group | Notes |
|---|---|---|
| IT Manager / CISO | SEC-Defender-SecurityAdmin | Full access |
| IT Security Analyst (1-2 people) | SEC-Defender-SOCAnalyst-Tier2 | Investigate and respond |
| IT Generalist (support desk) | SEC-Defender-SOCAnalyst-Tier1 | Triage alerts |
| External Auditor | SEC-Defender-SecurityReader | Read-only |
| Break-Glass | SEC-Defender-GlobalAdmin-BreakGlass | Emergency only |

---

## 6. Custom Role Definitions

### Creating Custom Roles in Unified RBAC

1. Navigate to **Microsoft Defender portal > Settings > Microsoft Defender XDR > Permissions and roles**
2. Click **Create custom role**
3. Name the role and select permissions from each permission group
4. Assign the role to an Entra ID security group
5. Optionally scope the assignment to specific data sources or device groups

### Example: SOC Analyst Tier 1 Custom Role

```
Role Name:        SOC Analyst - Tier 1
Description:      Triage alerts, manage incidents, basic response

Permissions:
  Security operations:
    ├── Alerts: Read, Manage
    ├── Incidents: Read, Manage
    ├── Advanced hunting: Read (no custom detections)
    └── Response actions: Basic (run AV scan, collect package)

  Security posture:
    └── Secure score: Read

  Raw data:
    └── None (no direct data access)

Assignment:
  Group: SEC-Defender-SOCAnalyst-Tier1
  Scope: All devices (or specific device group)
```

### Example: Threat Hunter Custom Role

```
Role Name:        Threat Hunter
Description:      Advanced hunting and detection engineering

Permissions:
  Security operations:
    ├── Alerts: Read
    ├── Incidents: Read
    ├── Advanced hunting: Read, Create custom detections
    └── Response actions: None

  Raw data:
    ├── Email & collaboration: Read
    ├── Device: Read
    ├── Identity: Read
    └── Cloud apps: Read

Assignment:
  Group: SEC-Defender-ThreatHunter
  Scope: All data sources
```

### Example: MSSP External SOC Role

```
Role Name:        External SOC Analyst
Description:      Limited access for managed security service provider

Permissions:
  Security operations:
    ├── Alerts: Read, Manage
    ├── Incidents: Read, Manage
    ├── Advanced hunting: Read
    └── Response actions: Basic

  Security posture:
    └── None

  Authorization:
    └── None

  Raw data:
    └── None

Assignment:
  Group: SEC-Defender-ExternalSOC
  Scope: Specific device groups only (exclude sensitive/exec devices)
```

---

## 7. Data Source Scoping & Device Groups

### Device Groups

Device groups allow you to scope role assignments to specific subsets of devices.

| Device Group | Criteria | Purpose |
|---|---|---|
| `DG-All-Devices` | All onboarded devices | Default scope |
| `DG-Servers` | OS = Windows Server | Server-specific operations |
| `DG-Workstations` | OS = Windows 10/11, macOS | User endpoint operations |
| `DG-Executive-Devices` | Tag = Executive | Restricted access — senior leadership devices |
| `DG-Critical-Infrastructure` | Tag = Critical | High-sensitivity devices |
| `DG-MSSP-Scope` | Tag = MSSP-Managed | Devices managed by external SOC |
| `DG-Linux-Servers` | OS = Linux | Linux-specific operations |
| `DG-Mobile` | OS = iOS, Android | Mobile device operations |

### Data Source Assignment

When creating a role assignment, you can scope it to specific data sources:

| Data Source | Workload |
|---|---|
| Microsoft Defender for Endpoint | Device alerts, investigations, response actions |
| Microsoft Defender for Office 365 | Email alerts, quarantine, submissions |
| Microsoft Defender for Identity | Identity alerts, lateral movement paths |
| Microsoft Defender for Cloud Apps | Cloud app alerts, OAuth app governance |

---

## 8. Activation & Migration to Unified RBAC

### For New Tenants

Unified RBAC is **enabled by default** since February 2025. No action required.

### For Existing Tenants (Migration)

| Step | Action | Details |
|---|---|---|
| 1 | Review current roles | Audit existing Entra ID role assignments and per-workload RBAC |
| 2 | Import existing roles | Use the **Import roles** feature to migrate per-workload roles into Unified RBAC |
| 3 | Map legacy roles | Use Microsoft's permission comparison tables to map old roles to new permissions |
| 4 | Create custom roles | Define custom roles that match your organisational structure |
| 5 | Assign to security groups | Assign new custom roles to Entra ID security groups |
| 6 | Activate Unified RBAC | In Settings > Permissions > Activate Unified RBAC per workload |
| 7 | Test access | Verify each group has correct access before deactivating legacy model |
| 8 | Deactivate legacy RBAC | Once validated, legacy per-workload RBAC is superseded |

### Permission Mapping Reference

| Legacy Role (Endpoint) | Unified RBAC Equivalent |
|---|---|
| Endpoint Admin | Security operations (full) + Response (full) |
| Endpoint Viewer | Security operations (read) |
| Security Operations | Security operations (read + manage alerts/incidents) |

**Full mapping guide:** https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles

---

## 9. Key Reference Links

| Resource | Link |
|---|---|
| Unified RBAC Overview | https://learn.microsoft.com/en-us/defender-xdr/manage-rbac |
| Create Custom Roles | https://learn.microsoft.com/en-us/defender-xdr/create-custom-rbac-roles |
| Permission Details | https://learn.microsoft.com/en-us/defender-xdr/custom-permissions-details |
| Activate Unified RBAC | https://learn.microsoft.com/en-us/defender-xdr/activate-defender-rbac |
| Import Roles | https://learn.microsoft.com/en-us/defender-xdr/import-rbac-roles |
| Compare / Map Roles | https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles |
| Entra ID Global Roles Access | https://learn.microsoft.com/en-us/defender-xdr/m365d-permissions |

---

*Disclaimer: RBAC features and permission models may evolve. Always verify against the latest Microsoft Learn documentation.*
