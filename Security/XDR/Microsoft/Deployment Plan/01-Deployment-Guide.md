# Microsoft Defender XDR — Deployment Guide

> **Last Updated:** February 2026
> **Scope:** End-to-end deployment plan for Microsoft Defender XDR across Identity, Email, Endpoint, Cloud Apps, and Cloud workloads with Sentinel integration.

---

## Table of Contents

1. [Deployment Overview](#1-deployment-overview)
2. [Prerequisites](#2-prerequisites)
3. [Licensing Requirements](#3-licensing-requirements)
4. [Deployment Phases](#4-deployment-phases)
5. [Phase 1 — Foundation & Identity](#5-phase-1--foundation--identity)
6. [Phase 2 — Email & Collaboration](#6-phase-2--email--collaboration)
7. [Phase 3 — Endpoint](#7-phase-3--endpoint)
8. [Phase 4 — Cloud Apps & Shadow IT](#8-phase-4--cloud-apps--shadow-it)
9. [Phase 5 — Cloud Workloads](#9-phase-5--cloud-workloads)
10. [Phase 6 — Sentinel Integration & Unified SOC](#10-phase-6--sentinel-integration--unified-soc)
11. [Phase 7 — Tuning, Automation & Optimisation](#11-phase-7--tuning-automation--optimisation)
12. [Deployment Timeline](#12-deployment-timeline)
13. [Key Reference Links](#13-key-reference-links)

---

## 1. Deployment Overview

Microsoft recommends a phased pilot-to-production approach, deploying components in the following order based on effort-to-value ratio:

```
Phase 1: Defender for Identity          (AD/Entra ID protection)
    ↓
Phase 2: Defender for Office 365        (Email & collaboration)
    ↓
Phase 3: Defender for Endpoint          (Devices — Windows, Mac, Linux, mobile)
    ↓
Phase 4: Defender for Cloud Apps        (SaaS visibility & CASB)
    ↓
Phase 5: Defender for Cloud             (Azure/AWS/GCP workloads)
    ↓
Phase 6: Sentinel Integration           (Unified SIEM + XDR SOC)
    ↓
Phase 7: Tuning & Automation            (AIR, custom detections, playbooks)
```

This order is designed to deliver the highest value first with the least deployment effort. Identity protection and email security are the fastest to enable and cover the two most common attack vectors.

---

## 2. Prerequisites

### Azure & Entra ID

| Requirement | Details |
|---|---|
| Azure Tenant | Active Microsoft Entra ID tenant |
| Global Administrator | Required for initial setup; transition to least-privilege after |
| Security Administrator | Manage Defender XDR settings and policies |
| Entra ID P2 | Required for Identity Protection, PIM, and Conditional Access |
| Azure Subscription | Required for Defender for Cloud (Phase 5) and Sentinel (Phase 6) |

### Network

| Requirement | Details |
|---|---|
| Defender for Endpoint URLs | Allow-list Microsoft Defender service URLs through proxy/firewall |
| Defender for Identity Sensors | Network access from DCs to Defender for Identity cloud service |
| SSL/TLS Inspection | Exclude Defender service URLs from SSL inspection or configure certificate trust |

### Infrastructure

| Requirement | Details |
|---|---|
| Domain Controllers | Defender for Identity sensors install on all DCs and AD FS servers |
| DNS | Defender for Identity requires DNS resolution to the cloud service |
| Microsoft Endpoint Manager (Intune) | Recommended for endpoint onboarding at scale |
| Group Policy / SCCM | Alternative endpoint onboarding methods |

### Resource Providers (for Azure-based components)

```bash
az provider register --namespace Microsoft.Security
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.SecurityInsights
```

---

## 3. Licensing Requirements

| Component | Minimum Licence | Recommended Licence |
|---|---|---|
| **Defender for Identity** | Entra ID P2 or M365 E5 Security | M365 E5 |
| **Defender for Office 365** | Plan 1 (E3 add-on) or Plan 2 (E5) | M365 E5 |
| **Defender for Endpoint** | Plan 1 (E3) or Plan 2 (E5) | M365 E5 |
| **Defender for Cloud Apps** | M365 E5 or standalone | M365 E5 |
| **Defender for Cloud** | Free tier (CSPM) or per-resource plans | Per workload plan |
| **Microsoft Sentinel** | Pay-As-You-Go or Commitment Tier | Commitment Tier (100 GB+/day) |
| **Copilot for Security** | Separate SCU-based licence | Add-on |

### Bundle Recommendation

**Microsoft 365 E5** or **M365 E5 Security add-on** provides the most cost-effective access to the full Defender XDR stack (except Defender for Cloud and Sentinel, which require Azure billing).

---

## 4. Deployment Phases

### Phase Summary

| Phase | Component | Duration | Effort | Risk Impact |
|---|---|---|---|---|
| 1 | Defender for Identity | 1 - 2 weeks | Low | Identity compromise |
| 2 | Defender for Office 365 | 1 - 2 weeks | Low-Medium | Phishing, BEC, malware |
| 3 | Defender for Endpoint | 2 - 6 weeks | Medium-High | Endpoint compromise, ransomware |
| 4 | Defender for Cloud Apps | 1 - 2 weeks | Low | Shadow IT, data exfiltration |
| 5 | Defender for Cloud | 2 - 4 weeks | Medium | Cloud workload compromise |
| 6 | Sentinel Integration | 2 - 4 weeks | Medium | Unified detection & response |
| 7 | Tuning & Automation | Ongoing | Medium | Operational maturity |

---

## 5. Phase 1 — Foundation & Identity

### Defender for Identity

**Purpose:** Detect identity-based attacks (credential theft, lateral movement, privilege escalation) by monitoring Active Directory and Entra ID.

#### Steps

| Step | Action | Details |
|---|---|---|
| 1.1 | Create Defender for Identity instance | In the Defender portal > Settings > Identities |
| 1.2 | Configure directory service account | gMSA (recommended) or standard AD service account with read permissions |
| 1.3 | Install sensors on all DCs | Download sensor package; install on every domain controller |
| 1.4 | Install sensors on AD FS servers | Required for AD FS authentication monitoring |
| 1.5 | Configure entity tags | Tag sensitive accounts, honeytoken accounts, and Exchange servers |
| 1.6 | Configure notifications | Set alert notification recipients |
| 1.7 | Validate detections | Trigger test detections (e.g., reconnaissance) to verify sensor operation |
| 1.8 | Review exclusions | Exclude known service accounts generating false positives |

#### Key Detections Enabled

- Pass-the-Hash / Pass-the-Ticket
- Kerberoasting / AS-REP Roasting
- DCSync / DCShadow
- Lateral movement paths
- Honeytoken activity
- Suspicious authentication activity

#### Timeline: 1 - 2 weeks

---

## 6. Phase 2 — Email & Collaboration

### Defender for Office 365

**Purpose:** Protect against phishing, business email compromise (BEC), malicious attachments, and unsafe links in Exchange Online, Teams, and SharePoint.

#### Steps

| Step | Action | Details |
|---|---|---|
| 2.1 | Review preset security policies | Standard and Strict preset policies are pre-configured |
| 2.2 | Enable Safe Attachments | Sandbox detonation for email attachments |
| 2.3 | Enable Safe Links | URL rewriting and time-of-click protection |
| 2.4 | Configure anti-phishing policies | Impersonation protection for VIPs, domains, and mailbox intelligence |
| 2.5 | Enable ZAP (Zero-hour Auto Purge) | Retroactively remove threats from delivered messages |
| 2.6 | Configure Safe Attachments for SharePoint/OneDrive/Teams | Extend file detonation to collaboration workloads |
| 2.7 | Enable Attack Simulation Training | Run phishing simulations to test and train users |
| 2.8 | Configure alert policies | Tune notification thresholds |

#### Pilot Approach

Microsoft recommends piloting with a **specific user group** (e.g., security team, IT department) before expanding to all users. Use Strict preset policies for the pilot group and Standard for the broader organisation.

#### Timeline: 1 - 2 weeks

---

## 7. Phase 3 — Endpoint

### Defender for Endpoint

**Purpose:** Next-gen antivirus, EDR, attack surface reduction, and automated investigation on all devices.

#### Steps

| Step | Action | Details |
|---|---|---|
| 3.1 | Configure tenant settings | In Defender portal > Settings > Endpoints |
| 3.2 | Pilot onboarding (50-100 devices) | Use local script for initial pilot |
| 3.3 | Validate onboarding | Run detection test (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { Invoke-WebRequest https://aka.ms/ioavtest }"`) |
| 3.4 | Enable attack surface reduction (ASR) rules | Start in audit mode; move to block after tuning |
| 3.5 | Configure next-gen AV policies | Real-time protection, cloud-delivered protection, automatic sample submission |
| 3.6 | Enable EDR in block mode | For devices running third-party AV |
| 3.7 | Full production onboarding | Intune, SCCM, or Group Policy for remaining devices |
| 3.8 | Onboard non-Windows devices | macOS (Intune/JAMF), Linux (script/Ansible), iOS/Android (Intune MAM) |
| 3.9 | Configure device groups | Group devices by risk, department, or criticality |
| 3.10 | Enable automated investigation & response (AIR) | Set automation levels per device group |

#### Onboarding Methods

| Method | Best For |
|---|---|
| Microsoft Intune | Cloud-managed devices (recommended) |
| SCCM/ConfigMgr | On-premises managed devices |
| Group Policy | Domain-joined devices without Intune |
| Local Script | Small-scale testing / pilot |
| VDI | Non-persistent virtual desktops |

#### Timeline: 2 - 6 weeks (depends on device estate size)

---

## 8. Phase 4 — Cloud Apps & Shadow IT

### Defender for Cloud Apps

**Purpose:** Cloud Access Security Broker (CASB) for shadow IT discovery, SaaS app governance, and data protection.

#### Steps

| Step | Action | Details |
|---|---|---|
| 4.1 | Enable Cloud Discovery | Integrate with Defender for Endpoint for automatic app discovery |
| 4.2 | Connect sanctioned apps | OAuth app connectors for M365, Google Workspace, Box, Salesforce, etc. |
| 4.3 | Configure session policies | Conditional Access App Control for real-time session monitoring |
| 4.4 | Enable anomaly detection | Built-in policies for impossible travel, mass download, unusual impersonation |
| 4.5 | Configure app governance | Monitor and govern OAuth apps connected to M365 |
| 4.6 | Set up information protection policies | DLP policies for sensitive data in connected apps |
| 4.7 | Block unsanctioned apps | Use cloud discovery to identify and block risky apps |

#### Timeline: 1 - 2 weeks

---

## 9. Phase 5 — Cloud Workloads

### Defender for Cloud

**Purpose:** Cloud Security Posture Management (CSPM) and Cloud Workload Protection (CWPP) for Azure, AWS, and GCP.

#### Steps

| Step | Action | Details |
|---|---|---|
| 5.1 | Enable Defender for Cloud on Azure subscriptions | In Azure Portal > Defender for Cloud > Environment settings |
| 5.2 | Enable Foundational CSPM (free) | Secure score, security recommendations |
| 5.3 | Enable Defender plans per workload | Servers, Databases, App Service, Storage, Key Vault, DNS, etc. |
| 5.4 | Connect AWS accounts | AWS CloudTrail integration via connector |
| 5.5 | Connect GCP projects | GCP Security Command Center integration |
| 5.6 | Configure regulatory compliance | Enable compliance standards (CIS, NIST, ISO, PCI) |
| 5.7 | Enable agentless scanning | Agentless vulnerability scanning for VMs |
| 5.8 | Configure alert suppression rules | Reduce noise from known acceptable configurations |

#### Timeline: 2 - 4 weeks

---

## 10. Phase 6 — Sentinel Integration & Unified SOC

### Microsoft Sentinel

**Purpose:** Centralise all Defender XDR signals into Sentinel for unified SIEM, advanced hunting, and SOAR automation.

#### Steps

| Step | Action | Details |
|---|---|---|
| 6.1 | Deploy Log Analytics Workspace | See Sentinel Deployment pipeline in the SIEM - SOAR folder |
| 6.2 | Enable Microsoft Sentinel | Install SecurityInsights solution on the workspace |
| 6.3 | Connect Defender XDR connector | Native bi-directional connector (incidents sync both ways) |
| 6.4 | Enable UEBA | Correlate identity behaviour across all sources |
| 6.5 | Enable analytics rules | Fusion, ML-based, and scheduled detections |
| 6.6 | Create automation rules | Auto-assign incidents, auto-close false positives, trigger playbooks |
| 6.7 | Deploy workbooks | Operational dashboards for SOC visibility |
| 6.8 | Configure data retention | Set table-level retention policies |

#### Key Integration Point

The **Defender XDR connector** in Sentinel provides:
- Bi-directional incident sync (incidents created in Defender appear in Sentinel and vice versa)
- Raw alert data ingestion for advanced hunting in KQL
- No double-billing — Defender XDR data connected to Sentinel is not charged for ingestion

#### Timeline: 2 - 4 weeks

---

## 11. Phase 7 — Tuning, Automation & Optimisation

### Ongoing Activities

| Activity | Description | Frequency |
|---|---|---|
| ASR rule tuning | Move rules from audit to block as false positives resolve | Weeks 4-12 |
| Alert tuning | Suppress false positives; refine detection thresholds | Ongoing |
| Custom detection rules | KQL-based detections for organisation-specific threats | Monthly |
| Automated investigation levels | Adjust AIR automation levels per device group | Quarterly |
| Threat hunting | Proactive KQL hunting across unified schema | Weekly |
| Incident response playbooks | Build Sentinel playbooks (Logic Apps) for common scenarios | As needed |
| Secure score review | Address security recommendations to improve posture | Weekly |
| Access reviews | Review Defender XDR role assignments (see RBAC guide) | Quarterly |
| Copilot for Security | Enable and train analysts on AI-assisted investigation | When licenced |

---

## 12. Deployment Timeline

### Typical Enterprise (2,000 - 10,000 users)

```
Week 1-2:    Phase 1 — Defender for Identity (sensors on all DCs)
Week 2-3:    Phase 2 — Defender for Office 365 (pilot → production)
Week 3-8:    Phase 3 — Defender for Endpoint (pilot → full onboarding)
Week 6-8:    Phase 4 — Defender for Cloud Apps (parallel with endpoint)
Week 8-12:   Phase 5 — Defender for Cloud (Azure/AWS/GCP)
Week 10-14:  Phase 6 — Sentinel integration and unified SOC
Week 14+:    Phase 7 — Ongoing tuning, automation, threat hunting
```

### Accelerated (< 500 users)

```
Week 1:      Phases 1 + 2 (Identity + Email)
Week 2-3:    Phase 3 (Endpoint)
Week 3-4:    Phases 4 + 5 (Cloud Apps + Cloud)
Week 4-5:    Phase 6 (Sentinel)
Week 5+:     Phase 7 (Tuning)
```

---

## 13. Key Reference Links

| Resource | Link |
|---|---|
| Pilot & Deploy Overview | https://learn.microsoft.com/en-us/defender-xdr/pilot-deploy-overview |
| Deploy Defender for Identity | https://learn.microsoft.com/en-us/defender-xdr/pilot-deploy-defender-identity |
| Deploy Defender for Office 365 | https://learn.microsoft.com/en-us/defender-xdr/pilot-deploy-defender-office-365 |
| Deploy Defender for Endpoint | https://learn.microsoft.com/en-us/defender-xdr/pilot-deploy-defender-endpoint |
| Deploy Defender for Cloud Apps | https://learn.microsoft.com/en-us/defender-xdr/pilot-deploy-defender-cloud-apps |
| Investigate & Respond | https://learn.microsoft.com/en-us/defender-xdr/pilot-deploy-investigate-respond |
| Defender XDR Documentation | https://learn.microsoft.com/en-us/defender-xdr/ |
| Defender for Cloud Documentation | https://learn.microsoft.com/en-us/azure/defender-for-cloud/ |

---

*Disclaimer: Deployment timelines are estimates based on typical enterprise environments. Actual timelines vary based on organisation size, complexity, and readiness.*
