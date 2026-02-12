# Security Frameworks & Resources

> **Last Updated:** February 2026
> **Purpose:** Comprehensive reference of major cybersecurity frameworks — what they are, where and how they apply, free resources, and how they relate to each other.

---

## Table of Contents

1. [MITRE Frameworks](#1-mitre-frameworks)
   - [MITRE ATT&CK](#11-mitre-attck)
   - [MITRE D3FEND](#12-mitre-d3fend)
   - [MITRE ENGAGE](#13-mitre-engage)
   - [MITRE CALDERA](#14-mitre-caldera)
   - [MITRE CAR (Cyber Analytics Repository)](#15-mitre-car)
   - [MITRE Atlas](#16-mitre-atlas)
2. [NIST Frameworks](#2-nist-frameworks)
   - [NIST Cybersecurity Framework (CSF) 2.0](#21-nist-cybersecurity-framework-csf-20)
   - [NIST SP 800-53 Rev. 5](#22-nist-sp-800-53-rev-5)
   - [NIST SP 800-171 Rev. 3](#23-nist-sp-800-171-rev-3)
   - [NIST Risk Management Framework (RMF)](#24-nist-risk-management-framework-rmf)
3. [CIS Controls & Benchmarks](#3-cis-controls--benchmarks)
4. [ISO/IEC Standards](#4-isoiec-standards)
5. [Lockheed Martin Cyber Kill Chain](#5-lockheed-martin-cyber-kill-chain)
6. [OWASP Frameworks](#6-owasp-frameworks)
7. [COBIT](#7-cobit)
8. [FAIR (Factor Analysis of Information Risk)](#8-fair)
9. [Zero Trust Architecture (ZTA)](#9-zero-trust-architecture-zta)
10. [Diamond Model of Intrusion Analysis](#10-diamond-model-of-intrusion-analysis)
11. [CMMC (Cybersecurity Maturity Model Certification)](#11-cmmc)
12. [Framework Mapping & Cross-Reference](#12-framework-mapping--cross-reference)
13. [Free Learning Resources by Framework](#13-free-learning-resources-by-framework)

---

## 1. MITRE Frameworks

MITRE operates as a federally funded research and development center (FFRDC) and provides some of the most widely adopted cybersecurity frameworks in the world — all freely available.

---

### 1.1 MITRE ATT&CK

**Full Name:** Adversarial Tactics, Techniques, and Common Knowledge

#### What It Is

A globally accessible, community-driven knowledge base of adversary tactics and techniques based on real-world observations. ATT&CK documents how threat actors operate at each stage of an attack lifecycle.

#### Structure

| Component | Description |
|---|---|
| **Tactics (14)** | The "why" — adversary goals (e.g., Initial Access, Persistence, Exfiltration) |
| **Techniques (~200+)** | The "how" — methods used to achieve tactics |
| **Sub-Techniques (~400+)** | Granular variations of techniques |
| **Procedures** | Specific implementations observed in the wild |
| **Groups (140+)** | Known threat actor groups mapped to their TTPs |
| **Software (700+)** | Malware and tools mapped to techniques |
| **Mitigations** | Defensive measures to counter techniques |
| **Data Sources** | Where to collect telemetry for detection |

#### Matrices

| Matrix | Scope | Use Case |
|---|---|---|
| **Enterprise** | Windows, macOS, Linux, Cloud (AWS, Azure, GCP, SaaS, Office 365), Network, Containers | General IT / enterprise security |
| **Mobile** | Android, iOS | Mobile device security |
| **ICS** | Industrial Control Systems | OT / SCADA / critical infrastructure security |

#### Where / How It Applies

| Use Case | How ATT&CK Is Applied |
|---|---|
| **Threat Intelligence** | Map observed TTPs to ATT&CK for structured threat reporting |
| **Detection Engineering** | Build detection rules aligned to specific techniques and sub-techniques |
| **Red Teaming / Pen Testing** | Use ATT&CK as a playbook to simulate real-world adversary behavior |
| **Security Gap Analysis** | Identify which techniques your defenses can and cannot detect |
| **SOC Operations** | Prioritize alerts and investigations based on technique severity |
| **Vendor Evaluation** | Assess SIEM/EDR/XDR coverage against ATT&CK techniques |
| **Compliance Mapping** | Map ATT&CK mitigations to NIST, CIS, and ISO controls |
| **Incident Response** | Trace attack chains using ATT&CK techniques during forensics |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| ATT&CK Matrix (interactive) | https://attack.mitre.org/ | Free |
| ATT&CK Navigator (visualization tool) | https://mitre-attack.github.io/attack-navigator/ | Free |
| ATT&CK Workbench (customization tool) | https://github.com/center-for-threat-informed-defense/attack-workbench-frontend | Free |
| ATT&CK STIX Data (machine-readable) | https://github.com/mitre-attack/attack-stix-data | Free |
| MAD20 Training & Certification | https://mad20.io/ | Free & paid |
| ATT&CK Evaluations (vendor comparison) | https://attackevals.mitre-engenuity.org/ | Free |

#### Free Learning

| Resource | Description | Cost |
|---|---|---|
| ATT&CK Documentation & Getting Started | https://attack.mitre.org/resources/ | Free |
| ATT&CK Training — MAD20 Foundations | Foundational course on using ATT&CK for defenders | Free |
| ATT&CK for CTI Training | Using ATT&CK for cyber threat intelligence | Free |
| SANS ATT&CK Poster | Visual reference of the full Enterprise matrix | Free |
| YouTube — MITRE ATT&CK Channel | Presentations, workshops, and conference talks | Free |

---

### 1.2 MITRE D3FEND

**Full Name:** Detection, Denial, and Disruption Framework Empowering Network Defense
**Current Version:** v1.3.0 (December 2025) — 267 defensive techniques

#### What It Is

The defensive counterpart to ATT&CK. D3FEND is a knowledge base of cybersecurity countermeasure techniques that maps defensive capabilities to offensive techniques. Funded by the NSA Cybersecurity Directorate.

#### Structure — Seven Tactical Categories

| Tactic | Description |
|---|---|
| **Harden** | Reduce the attack surface through system hardening |
| **Detect** | Identify malicious activity through monitoring and analysis |
| **Isolate** | Contain threats by isolating compromised systems or segments |
| **Deceive** | Misdirect attackers using decoys, honeypots, and fake assets |
| **Evict** | Remove adversary presence from the environment |
| **Restore** | Recover systems and data to a known-good state |
| **Model** | Asset inventorying, network mapping, and data-flow analysis |

#### Where / How It Applies

| Use Case | How D3FEND Is Applied |
|---|---|
| **Security Architecture** | Select defensive technologies mapped to known offensive techniques |
| **Gap Analysis** | Identify which ATT&CK techniques lack defensive countermeasures in your environment |
| **Product Evaluation** | Assess security product coverage against D3FEND techniques |
| **SOC Playbook Design** | Build response playbooks anchored to specific D3FEND countermeasures |
| **OT / ICS Security** | D3FEND 1.3 includes OT-specific defensive techniques |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| D3FEND Matrix (interactive) | https://d3fend.mitre.org/ | Free |
| D3FEND Knowledge Graph | https://d3fend.mitre.org/dao/ | Free |
| D3FEND GitHub | https://github.com/d3fend | Free |
| ATT&CK-to-D3FEND Mappings | https://d3fend.mitre.org/ | Free |

---

### 1.3 MITRE ENGAGE

#### What It Is

A framework for planning and executing adversary engagement operations using denial and deception. ENGAGE helps organizations interact with attackers in controlled ways to gather intelligence, disrupt operations, and waste adversary resources.

#### Structure

| Category | Description |
|---|---|
| **Strategic Goals** | Define what the organization wants to achieve through engagement |
| **Engagement Approaches** | Denial (prevent adversary success) and Deception (mislead adversary) |
| **Engagement Activities** | Specific activities like luring, channeling, monitoring, and collecting intelligence |

#### Where / How It Applies

| Use Case | How ENGAGE Is Applied |
|---|---|
| **Deception Operations** | Deploy honeypots, honeynets, and decoy assets strategically |
| **Threat Intelligence** | Engage adversaries to collect intelligence on their TTPs |
| **Active Defense** | Move beyond passive detection to controlled adversary interaction |
| **Red/Purple Teaming** | Design engagement scenarios that test deception defenses |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| ENGAGE Framework | https://engage.mitre.org/ | Free |
| ENGAGE Handbook | https://engage.mitre.org/learn/ | Free |
| Starter Kit | https://engage.mitre.org/starter-kit/ | Free |

---

### 1.4 MITRE CALDERA

#### What It Is

An open-source adversary emulation platform that automates red team operations using ATT&CK techniques. CALDERA runs real adversary behaviors against your environment to test defenses.

#### Capabilities

| Feature | Description |
|---|---|
| **Automated Adversary Emulation** | Execute multi-step attack scenarios using ATT&CK TTPs |
| **Agent-Based** | Deploy lightweight agents on target systems for attack simulation |
| **Plugin Architecture** | Extensible with community and custom plugins |
| **Adversary Profiles** | Pre-built profiles mimicking known threat groups |
| **Blue Team Operations** | Can also automate defensive testing and incident response |
| **Training Mode** | Safe mode for learning and exercises |

#### Where / How It Applies

| Use Case | How CALDERA Is Applied |
|---|---|
| **Red Team Automation** | Automate adversary emulation engagements at scale |
| **Detection Validation** | Test whether SIEM/EDR/XDR detects specific ATT&CK techniques |
| **Purple Team Exercises** | Run attacks and validate detections simultaneously |
| **Security Training** | Train analysts using realistic attack simulations |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| CALDERA GitHub | https://github.com/mitre/caldera | Free (open-source) |
| CALDERA Documentation | https://caldera.readthedocs.io/ | Free |
| CALDERA Plugins | https://github.com/mitre/caldera/wiki/Plugin-library | Free |

---

### 1.5 MITRE CAR

**Full Name:** Cyber Analytics Repository

#### What It Is

A knowledge base of analytics (detection rules) based on the ATT&CK adversary model. CAR provides validated detection logic that security teams can implement directly.

#### Where / How It Applies

| Use Case | Application |
|---|---|
| **Detection Engineering** | Use CAR analytics as starting points for SIEM detection rules |
| **SOC Operations** | Implement pre-validated detections mapped to ATT&CK |
| **Coverage Assessment** | Measure detection coverage against ATT&CK techniques |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| CAR Knowledge Base | https://car.mitre.org/ | Free |
| CAR GitHub | https://github.com/mitre-attack/car | Free |

---

### 1.6 MITRE ATLAS

**Full Name:** Adversarial Threat Landscape for AI Systems

#### What It Is

A knowledge base of adversary techniques targeting machine learning and AI systems. Modeled after ATT&CK but focused specifically on AI/ML threats.

#### Where / How It Applies

| Use Case | Application |
|---|---|
| **AI/ML Security** | Understand and defend against attacks on AI models |
| **LLM Security** | Address prompt injection, data poisoning, and model theft |
| **Risk Assessment** | Evaluate AI deployment risks using structured threat modeling |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| ATLAS Matrix | https://atlas.mitre.org/ | Free |
| ATLAS Case Studies | https://atlas.mitre.org/studies | Free |

---

## 2. NIST Frameworks

The National Institute of Standards and Technology (NIST) publishes the most widely referenced cybersecurity standards in the U.S. and globally. All NIST publications are free.

---

### 2.1 NIST Cybersecurity Framework (CSF) 2.0

**Released:** February 2024 (major update from CSF 1.1)

#### What It Is

A voluntary framework providing a common language for managing cybersecurity risk. CSF 2.0 applies to organizations of all sizes and sectors — not just critical infrastructure.

#### Structure — Six Core Functions

| Function | Code | Description |
|---|---|---|
| **Govern** (NEW in 2.0) | GV | Establish and monitor cybersecurity risk management strategy, expectations, and policies |
| **Identify** | ID | Understand organizational context, assets, risks, and supply chain |
| **Protect** | PR | Implement safeguards to ensure delivery of critical services |
| **Detect** | DE | Identify cybersecurity events in a timely manner |
| **Respond** | RS | Take action when a cybersecurity incident is detected |
| **Recover** | RC | Restore capabilities impaired by a cybersecurity incident |

#### Where / How It Applies

| Sector | Application |
|---|---|
| **All Industries** | CSF 2.0 is sector-agnostic and applies to any organization |
| **U.S. Federal Agencies** | Required under Executive Order 13800 |
| **Critical Infrastructure** | 16 CI sectors (energy, healthcare, financial, etc.) |
| **Supply Chain** | New supply chain risk management (C-SCRM) emphasis in 2.0 |
| **Small & Medium Businesses** | Simplified community profiles and quick-start guides |
| **International** | Adopted or referenced by 50+ countries |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| CSF 2.0 Official Page | https://www.nist.gov/cyberframework | Free |
| CSF 2.0 Full Document (PDF) | https://doi.org/10.6028/NIST.CSWP.29 | Free |
| CSF 2.0 Reference Tool (interactive) | https://csrc.nist.gov/projects/cybersecurity-framework/filters#/csf/filters | Free |
| CSF 2.0 Quick-Start Guides | https://www.nist.gov/cyberframework/getting-started | Free |
| Community Profiles | https://www.nist.gov/cyberframework/csf-20-community-profiles | Free |

#### Free Learning

| Resource | Link | Cost |
|---|---|---|
| NIST CSF 2.0 Learning Modules | https://www.nist.gov/cyberframework/getting-started | Free |
| SANS NIST CSF Poster | https://www.sans.org/posters/ | Free |
| Coursera — NIST CSF Courses | https://www.coursera.org/search?query=nist+cybersecurity+framework | Free (audit) |

---

### 2.2 NIST SP 800-53 Rev. 5

**Full Title:** Security and Privacy Controls for Information Systems and Organizations

#### What It Is

The most comprehensive catalog of security and privacy controls available. Contains 1,000+ controls organized into 20 control families. Used by federal agencies and widely adopted by the private sector.

#### Control Families (20)

| ID | Family | ID | Family |
|---|---|---|---|
| AC | Access Control | PE | Physical & Environmental Protection |
| AT | Awareness & Training | PL | Planning |
| AU | Audit & Accountability | PM | Program Management |
| CA | Assessment, Authorization & Monitoring | PS | Personnel Security |
| CM | Configuration Management | PT | Personally Identifiable Information |
| CP | Contingency Planning | RA | Risk Assessment |
| IA | Identification & Authentication | SA | System & Services Acquisition |
| IR | Incident Response | SC | System & Communications Protection |
| MA | Maintenance | SI | System & Information Integrity |
| MP | Media Protection | SR | Supply Chain Risk Management |

#### Where / How It Applies

| Context | Application |
|---|---|
| **U.S. Federal Information Systems** | Mandatory under FISMA |
| **FedRAMP** | Required for cloud services serving federal agencies |
| **DoD / Intelligence** | Baseline for DISA STIGs and CNSSI 1253 |
| **Private Sector** | Voluntary; widely adopted as a control catalog |
| **Compliance Mapping** | Maps to ISO 27001, CIS Controls, HIPAA, PCI-DSS |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| SP 800-53 Rev. 5 | https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final | Free |
| Control Catalog (searchable) | https://csrc.nist.gov/projects/cprt/catalog#/cprt/framework/version/SP_800_53_5_1_1/home | Free |
| SP 800-53A (Assessment Procedures) | https://csrc.nist.gov/publications/detail/sp/800-53a/rev-5/final | Free |
| SP 800-53B (Control Baselines) | https://csrc.nist.gov/publications/detail/sp/800-53b/final | Free |

---

### 2.3 NIST SP 800-171 Rev. 3

**Full Title:** Protecting Controlled Unclassified Information in Nonfederal Systems and Organizations

#### What It Is

Defines 110 security requirements for protecting CUI (Controlled Unclassified Information) in non-federal systems. Required for all DoD contractors and subcontractors handling CUI.

#### Where / How It Applies

| Context | Application |
|---|---|
| **DoD Contractors** | Required under DFARS clause 252.204-7012 |
| **CMMC** | 800-171 is the technical foundation for CMMC Level 2 |
| **Federal Supply Chain** | Any org handling CUI must comply |
| **Higher Education** | Research institutions receiving federal grants with CUI |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| SP 800-171 Rev. 3 | https://csrc.nist.gov/publications/detail/sp/800-171/rev-3/final | Free |
| SP 800-171A (Assessment Procedures) | https://csrc.nist.gov/publications/detail/sp/800-171a/rev-3/final | Free |
| CUI Registry | https://www.archives.gov/cui | Free |

---

### 2.4 NIST Risk Management Framework (RMF)

**Reference:** SP 800-37 Rev. 2

#### What It Is

A structured process for integrating security, privacy, and supply chain risk management into the system development lifecycle.

#### Seven Steps

| Step | Activity |
|---|---|
| 1. **Prepare** | Establish context and priorities for managing risk |
| 2. **Categorize** | Determine information system impact level (FIPS 199) |
| 3. **Select** | Choose appropriate security controls (from 800-53) |
| 4. **Implement** | Deploy the selected controls |
| 5. **Assess** | Evaluate whether controls are effective |
| 6. **Authorize** | Senior official accepts the residual risk |
| 7. **Monitor** | Continuous monitoring of the security posture |

#### Key Links

| Resource | Link | Cost |
|---|---|---|
| SP 800-37 Rev. 2 (RMF) | https://csrc.nist.gov/publications/detail/sp/800-37/rev-2/final | Free |
| RMF Online Learning | https://csrc.nist.gov/projects/risk-management | Free |

---

## 3. CIS Controls & Benchmarks

**Organization:** Center for Internet Security (CIS)
**Current Version:** CIS Controls v8.1 (2024)

### What It Is

A prioritized set of 18 security controls with 153 safeguards, organized into three implementation groups (IGs) based on organizational maturity. Widely considered the most practical, actionable security framework available.

### The 18 CIS Controls

| # | Control | IG1 | IG2 | IG3 |
|---|---|---|---|---|
| 1 | Inventory and Control of Enterprise Assets | Yes | Yes | Yes |
| 2 | Inventory and Control of Software Assets | Yes | Yes | Yes |
| 3 | Data Protection | Yes | Yes | Yes |
| 4 | Secure Configuration of Enterprise Assets and Software | Yes | Yes | Yes |
| 5 | Account Management | Yes | Yes | Yes |
| 6 | Access Control Management | Yes | Yes | Yes |
| 7 | Continuous Vulnerability Management | Yes | Yes | Yes |
| 8 | Audit Log Management | Yes | Yes | Yes |
| 9 | Email and Web Browser Protections | Yes | Yes | Yes |
| 10 | Malware Defenses | Yes | Yes | Yes |
| 11 | Data Recovery | Yes | Yes | Yes |
| 12 | Network Infrastructure Management | — | Yes | Yes |
| 13 | Network Monitoring and Defense | — | Yes | Yes |
| 14 | Security Awareness and Skills Training | Yes | Yes | Yes |
| 15 | Service Provider Management | — | Yes | Yes |
| 16 | Application Software Security | — | Yes | Yes |
| 17 | Incident Response Management | Yes | Yes | Yes |
| 18 | Penetration Testing | — | — | Yes |

### Implementation Groups

| Group | Target Audience | Safeguards |
|---|---|---|
| **IG1** (Essential Cyber Hygiene) | Small/medium orgs with limited IT resources | 56 safeguards |
| **IG2** | Mid-size orgs with dedicated IT/security staff | 130 safeguards (includes IG1) |
| **IG3** | Large enterprises / regulated industries | All 153 safeguards |

### Where / How It Applies

| Context | Application |
|---|---|
| **SMBs** | IG1 is designed as the minimum standard for all organizations |
| **Compliance Baseline** | Maps to NIST CSF, 800-53, PCI-DSS, HIPAA, GDPR |
| **Insurance Underwriting** | Many cyber insurers reference CIS Controls for risk assessment |
| **Government (state/local)** | CIS provides free tools to SLTT (state, local, tribal, territorial) |
| **Vendor Assessment** | Used in supply chain security questionnaires |

### CIS Benchmarks

In addition to the Controls, CIS publishes **Benchmarks** — detailed hardening guides for specific technologies:

| Category | Examples |
|---|---|
| **Operating Systems** | Windows Server, Windows 11, Ubuntu, RHEL, macOS |
| **Cloud Platforms** | AWS, Azure, GCP, Oracle Cloud, Alibaba Cloud |
| **Databases** | SQL Server, Oracle, PostgreSQL, MongoDB |
| **Applications** | Microsoft 365, Google Workspace, Kubernetes, Docker |
| **Network Devices** | Cisco, Palo Alto, Juniper, Fortinet |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| CIS Controls v8.1 | https://www.cisecurity.org/controls/v8-1 | Free (registration) |
| CIS Controls Download | https://learn.cisecurity.org/cis-controls-download | Free |
| CIS Controls Navigator | https://www.cisecurity.org/controls/cis-controls-navigator | Free |
| Implementation Groups Guide | https://www.cisecurity.org/controls/implementation-groups | Free |
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks | Free (PDF, registration) |
| CIS-CAT (Assessment Tool) | https://www.cisecurity.org/cybersecurity-tools/cis-cat-pro | Free (Lite) / Paid (Pro) |
| CIS Hardened Images | https://www.cisecurity.org/cis-hardened-images | Paid (marketplace) |

### Free Learning

| Resource | Link | Cost |
|---|---|---|
| CIS Controls v8.1 Companion Guides | https://www.cisecurity.org/controls/v8-1 | Free |
| CIS WorkBench (community platform) | https://workbench.cisecurity.org/ | Free |
| CIS Policy Templates | Via CIS Controls download | Free |
| SANS CIS Controls Poster | https://www.sans.org/posters/ | Free |

---

## 4. ISO/IEC Standards

**Organization:** International Organization for Standardization / International Electrotechnical Commission

### ISO/IEC 27001:2022

#### What It Is

The international standard for Information Security Management Systems (ISMS). Specifies the requirements for establishing, implementing, maintaining, and continually improving an ISMS.

#### Structure

| Clause | Requirement |
|---|---|
| 4 | Context of the organization |
| 5 | Leadership |
| 6 | Planning |
| 7 | Support |
| 8 | Operation |
| 9 | Performance evaluation |
| 10 | Improvement |
| **Annex A** | 93 controls across 4 themes (Organizational, People, Physical, Technological) |

#### Where / How It Applies

| Context | Application |
|---|---|
| **Global Standard** | Recognized in 160+ countries |
| **Certification** | Third-party audited certification demonstrates security maturity |
| **Regulatory Compliance** | Referenced by GDPR, HIPAA, and many national regulations |
| **Customer Trust** | Increasingly required in enterprise procurement and RFPs |
| **Supply Chain** | Demonstrates due diligence to partners and customers |

### ISO/IEC 27002:2022

The companion code of practice providing detailed implementation guidance for each Annex A control.

### Key Links

| Resource | Link | Cost |
|---|---|---|
| ISO 27001:2022 Standard | https://www.iso.org/standard/27001 | ~$180 (purchase) |
| ISO 27002:2022 Standard | https://www.iso.org/standard/75652.html | ~$230 (purchase) |
| ISO 27001 Free Preview | https://www.iso.org/obp/ui/en/#iso:std:iso-iec:27001:ed-3:v2:en | Free |
| Coursera - ISO 27001 Courses | https://www.coursera.org/search?query=iso+27001 | Free (audit) |

---

## 5. Lockheed Martin Cyber Kill Chain

### What It Is

A seven-phase model describing the stages of a cyberattack from an adversary's perspective. Originally developed by Lockheed Martin for intelligence-driven defense.

### The Seven Phases

| Phase | Description | Defender Action |
|---|---|---|
| 1. **Reconnaissance** | Adversary researches targets — OSINT, scanning, social engineering | Monitor for scanning; reduce public exposure |
| 2. **Weaponization** | Creates exploit payload (e.g., trojanized document, malicious link) | Threat intelligence; understand adversary tooling |
| 3. **Delivery** | Transmits weapon to target — email, web, USB, supply chain | Email filtering, web proxy, endpoint protection |
| 4. **Exploitation** | Exploits vulnerability to execute code on target | Patch management, application hardening, EDR |
| 5. **Installation** | Installs persistent backdoor on target system | Endpoint detection, integrity monitoring |
| 6. **Command & Control (C2)** | Establishes communication channel with adversary infrastructure | Network monitoring, DNS filtering, firewall rules |
| 7. **Actions on Objectives** | Adversary achieves goal — data theft, destruction, ransomware | DLP, data classification, incident response |

### Where / How It Applies

| Use Case | Application |
|---|---|
| **Incident Analysis** | Map observed activity to kill chain phases to identify attack stage |
| **Defense Planning** | Ensure controls exist at each phase to break the chain |
| **Threat Intelligence** | Classify adversary capabilities by kill chain phase |
| **Security Architecture** | Validate defense-in-depth by mapping tools to each phase |
| **SOC Operations** | Prioritize alerts based on kill chain progression |

### Relationship to ATT&CK

The Kill Chain provides a high-level attack lifecycle view, while ATT&CK provides granular technique-level detail within each phase. They are complementary:

| Kill Chain Phase | ATT&CK Tactics |
|---|---|
| Reconnaissance | Reconnaissance |
| Weaponization | Resource Development |
| Delivery | Initial Access |
| Exploitation | Execution |
| Installation | Persistence, Privilege Escalation |
| Command & Control | Command and Control |
| Actions on Objectives | Collection, Exfiltration, Impact |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| Cyber Kill Chain (Lockheed Martin) | https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html | Free |
| Original Research Paper | https://www.lockheedmartin.com/content/dam/lockheed-martin/rms/documents/cyber/LM-White-Paper-Intel-Driven-Defense.pdf | Free |

---

## 6. OWASP Frameworks

**Organization:** Open Worldwide Application Security Project (OWASP)

### Key Projects

| Project | Description | Latest Version |
|---|---|---|
| **OWASP Top 10** | Most critical web application security risks | 2021 |
| **OWASP Top 10 for LLMs** | Security risks for Large Language Model applications | 2025 v2.0 |
| **OWASP API Security Top 10** | Most critical API security risks | 2023 |
| **OWASP Mobile Top 10** | Most critical mobile application security risks | 2024 |
| **OWASP ASVS** | Application Security Verification Standard — detailed control requirements | 4.0.3 |
| **OWASP SAMM** | Software Assurance Maturity Model — measuring AppSec programs | 2.0 |
| **OWASP Testing Guide** | Comprehensive web application security testing methodology | 4.2 |
| **OWASP ZAP** | Free open-source web application security scanner | Current |

### OWASP Top 10 (2021)

| # | Risk |
|---|---|
| A01 | Broken Access Control |
| A02 | Cryptographic Failures |
| A03 | Injection |
| A04 | Insecure Design |
| A05 | Security Misconfiguration |
| A06 | Vulnerable and Outdated Components |
| A07 | Identification and Authentication Failures |
| A08 | Software and Data Integrity Failures |
| A09 | Security Logging and Monitoring Failures |
| A10 | Server-Side Request Forgery (SSRF) |

### Where / How It Applies

| Context | Application |
|---|---|
| **Application Development** | Secure coding standards and developer training |
| **Penetration Testing** | Testing methodology for web and API assessments |
| **DevSecOps** | Integrate OWASP checks into CI/CD pipelines |
| **Compliance** | PCI-DSS requirement 6 references OWASP |
| **Vendor Assessment** | Evaluate software vendor security practices |
| **AI/ML Applications** | OWASP Top 10 for LLMs covers prompt injection, training data poisoning, etc. |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| OWASP Top 10 | https://owasp.org/www-project-top-ten/ | Free |
| OWASP Top 10 for LLMs | https://genai.owasp.org/ | Free |
| OWASP API Security Top 10 | https://owasp.org/API-Security/ | Free |
| OWASP ASVS | https://owasp.org/www-project-application-security-verification-standard/ | Free |
| OWASP ZAP (scanner) | https://www.zaproxy.org/ | Free (open-source) |
| OWASP Juice Shop (training app) | https://owasp.org/www-project-juice-shop/ | Free (open-source) |
| OWASP WebGoat (training app) | https://owasp.org/www-project-webgoat/ | Free (open-source) |
| OWASP Cheat Sheet Series | https://cheatsheetseries.owasp.org/ | Free |

---

## 7. COBIT

**Full Name:** Control Objectives for Information and Related Technologies
**Organization:** ISACA
**Current Version:** COBIT 2019

### What It Is

A governance and management framework for enterprise IT. COBIT bridges the gap between business requirements, control needs, and technical issues, providing a holistic approach to IT governance.

### Structure

| Component | Description |
|---|---|
| **Governance Objectives** | Evaluate, Direct, Monitor (EDM) — 5 processes |
| **Management Objectives** | Align, Plan, Organize (APO) — 14 processes; Build, Acquire, Implement (BAI) — 11 processes; Deliver, Service, Support (DSS) — 6 processes; Monitor, Evaluate, Assess (MEA) — 4 processes |
| **Design Factors** | 11 factors for tailoring governance to organizational context |
| **Maturity Model** | Capability levels 0-5 based on CMMI |

### Where / How It Applies

| Context | Application |
|---|---|
| **IT Governance** | Aligning IT strategy with business goals |
| **Regulatory Compliance** | SOX, GDPR, HIPAA — IT control framework |
| **Audit** | IT audit planning and control assessment |
| **Risk Management** | Enterprise IT risk identification and treatment |
| **Service Management** | Complements ITIL for IT service delivery |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| COBIT Overview | https://www.isaca.org/resources/cobit | Free (overview) |
| COBIT 2019 Framework | https://www.isaca.org/resources/cobit | $175+ (full guide) |
| COBIT Certification (CGEIT) | https://www.isaca.org/credentialing/cgeit | ~$575 exam |

---

## 8. FAIR

**Full Name:** Factor Analysis of Information Risk
**Organization:** FAIR Institute / The Open Group

### What It Is

A quantitative risk analysis framework that uses financial terms to express cybersecurity risk. FAIR replaces subjective "high/medium/low" ratings with probabilistic financial models.

### Structure

| Component | Description |
|---|---|
| **Loss Event Frequency (LEF)** | How often a threat event is expected to occur |
| **Loss Magnitude (LM)** | The probable financial loss from a single event |
| **Threat Event Frequency** | How often threat agents act against assets |
| **Vulnerability** | Probability that a threat event becomes a loss event |
| **Primary Loss** | Direct losses (response, replacement, fines) |
| **Secondary Loss** | Indirect losses (reputation, competitive disadvantage) |

### Where / How It Applies

| Context | Application |
|---|---|
| **Board Reporting** | Communicate cyber risk in financial terms executives understand |
| **Investment Prioritization** | Compare ROI of security investments using quantified risk reduction |
| **Cyber Insurance** | Quantify exposures for policy sizing and underwriting |
| **Risk Appetite Statements** | Define acceptable risk levels in dollar terms |
| **Compliance** | Quantitative basis for risk-based compliance decisions |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| FAIR Institute | https://www.fairinstitute.org/ | Free (membership) |
| FAIR Model Overview | https://www.fairinstitute.org/what-is-fair | Free |
| Open FAIR Standard (Open Group) | https://www.opengroup.org/certifications/openfair | Free (overview) |
| RiskLens (FAIR platform) | https://www.risklens.com/ | Paid |

---

## 9. Zero Trust Architecture (ZTA)

**Reference:** NIST SP 800-207

### What It Is

A security model that eliminates implicit trust and requires continuous verification of every user, device, and network flow. Core principle: "Never trust, always verify."

### Core Tenets

| Tenet | Description |
|---|---|
| **Verify Explicitly** | Authenticate and authorize every request based on all data points — identity, location, device health, data classification |
| **Least Privilege Access** | Limit user/system access to the minimum needed for the task, with just-in-time and just-enough-access |
| **Assume Breach** | Design systems expecting that perimeter has been compromised; segment, monitor, and encrypt end-to-end |

### Zero Trust Pillars

| Pillar | Focus |
|---|---|
| **Identity** | Strong authentication, conditional access, identity governance |
| **Devices** | Device health validation, compliance checking, MDM/EDR |
| **Network** | Micro-segmentation, encrypted transport, software-defined perimeters |
| **Applications** | Application-level access control, API security, shadow IT discovery |
| **Data** | Classification, encryption, DLP, rights management |
| **Infrastructure** | Cloud workload protection, just-in-time access, immutable infrastructure |
| **Visibility & Analytics** | Continuous monitoring, SIEM/SOAR, behavioral analytics |

### Where / How It Applies

| Context | Application |
|---|---|
| **U.S. Federal Agencies** | Mandatory under OMB M-22-09 (Federal Zero Trust Strategy) by end of FY2024 |
| **DoD** | DoD Zero Trust Reference Architecture and Strategy |
| **Enterprise** | Modern security architecture for hybrid/multi-cloud environments |
| **Remote Work** | Replaces VPN-centric perimeter security |
| **Cloud-Native** | Foundation for SASE and SSE architectures |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| NIST SP 800-207 (ZTA) | https://csrc.nist.gov/publications/detail/sp/800-207/final | Free |
| CISA Zero Trust Maturity Model | https://www.cisa.gov/zero-trust-maturity-model | Free |
| DoD Zero Trust Reference Architecture | https://dodcio.defense.gov/Portals/0/Documents/Library/ZTRef.pdf | Free |
| Microsoft Zero Trust Guidance | https://learn.microsoft.com/en-us/security/zero-trust/ | Free |
| Google BeyondCorp (original ZT paper) | https://cloud.google.com/beyondcorp | Free |

---

## 10. Diamond Model of Intrusion Analysis

### What It Is

An analytic framework that models cyber intrusions using four core features: Adversary, Capability, Infrastructure, and Victim. Enables structured analysis and pivoting between features.

### The Four Vertices

| Vertex | Description | Examples |
|---|---|---|
| **Adversary** | The threat actor conducting the operation | APT29, FIN7, insider threat |
| **Capability** | The tools and techniques used | Malware, exploit, phishing kit |
| **Infrastructure** | The systems used to deliver and manage the attack | C2 servers, domains, VPN nodes |
| **Victim** | The target of the intrusion | Organization, system, person |

### Where / How It Applies

| Use Case | Application |
|---|---|
| **Threat Intelligence** | Structure CTI reports around the four vertices |
| **Pivoting & Enrichment** | Use one vertex to discover the others (e.g., infrastructure to adversary) |
| **Campaign Tracking** | Group related events into activity threads and campaigns |
| **Attribution** | Build adversary profiles through correlated features |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| Original Paper | https://www.activeresponse.org/wp-content/uploads/2013/07/diamond.pdf | Free |
| SANS Diamond Model Course | https://www.sans.org/cyber-security-courses/cyber-threat-intelligence/ | Paid |

---

## 11. CMMC

**Full Name:** Cybersecurity Maturity Model Certification
**Organization:** U.S. Department of Defense
**Current Version:** CMMC 2.0

### What It Is

A DoD certification framework verifying that defense contractors meet cybersecurity requirements for protecting Federal Contract Information (FCI) and Controlled Unclassified Information (CUI).

### CMMC 2.0 Levels

| Level | Name | Controls | Assessment | Who Needs It |
|---|---|---|---|---|
| **Level 1** | Foundational | 15 practices (FAR 52.204-21) | Annual self-assessment | Contractors handling FCI |
| **Level 2** | Advanced | 110 controls (NIST 800-171 Rev. 2) | Third-party assessment (C3PAO) or self-assessment | Contractors handling CUI |
| **Level 3** | Expert | 110+ controls (800-171 + 800-172 enhancements) | Government-led assessment (DIBCAC) | Highest-priority programs |

### Where / How It Applies

| Context | Application |
|---|---|
| **DoD Contractors** | Required in DoD contracts starting 2025 (phased rollout) |
| **Subcontractors** | Flow-down requirements at appropriate levels |
| **Defense Industrial Base** | All 300,000+ companies in the DIB |
| **IT Service Providers** | MSPs/MSSPs serving defense contractors must meet requirements |

### Key Links

| Resource | Link | Cost |
|---|---|---|
| CMMC Official Site | https://dodcio.defense.gov/CMMC/ | Free |
| CMMC Model Overview | https://dodcio.defense.gov/CMMC/Model/ | Free |
| Cyber AB (Accreditation Body) | https://cyberab.org/ | Free |
| NIST 800-171 (CMMC L2 basis) | https://csrc.nist.gov/publications/detail/sp/800-171/rev-3/final | Free |

---

## 12. Framework Mapping & Cross-Reference

### How Frameworks Relate

| Framework | Primary Purpose | Pairs Well With |
|---|---|---|
| **MITRE ATT&CK** | Adversary behavior modeling | D3FEND, Kill Chain, CIS Controls, NIST 800-53 |
| **MITRE D3FEND** | Defensive countermeasure selection | ATT&CK, NIST CSF, CIS Controls |
| **NIST CSF 2.0** | Risk management & governance | 800-53, CIS Controls, ISO 27001, FAIR |
| **NIST 800-53** | Comprehensive control catalog | CSF, RMF, CIS Controls, ISO 27001 |
| **CIS Controls v8.1** | Prioritized actionable controls | ATT&CK, NIST CSF, 800-53, ISO 27001 |
| **ISO 27001** | ISMS certification & governance | CIS Controls, NIST CSF, COBIT |
| **Kill Chain** | Attack lifecycle modeling | ATT&CK, Diamond Model |
| **OWASP** | Application security | CIS Controls (Control 16), NIST 800-53 (SA family) |
| **COBIT** | IT governance | ISO 27001, NIST CSF, FAIR |
| **FAIR** | Quantitative risk analysis | NIST CSF, ISO 27001, COBIT |
| **Zero Trust** | Security architecture | NIST CSF, ATT&CK, CIS Controls |
| **CMMC** | DoD contractor compliance | NIST 800-171, 800-53, CIS Controls |

### Common Compliance Crosswalks

| Compliance Need | Primary Framework | Supporting Frameworks |
|---|---|---|
| **HIPAA** | NIST CSF / 800-53 | CIS Controls, ISO 27001 |
| **PCI-DSS** | PCI-DSS v4.0 | CIS Controls, OWASP, NIST 800-53 |
| **GDPR** | ISO 27001 | NIST CSF, CIS Controls |
| **SOX (IT Controls)** | COBIT | NIST 800-53, ISO 27001 |
| **FISMA** | NIST RMF / 800-53 | CIS Controls |
| **DFARS / CMMC** | NIST 800-171 | 800-53, CIS Controls |
| **FedRAMP** | NIST 800-53 | CIS Controls |
| **Cyber Insurance** | CIS Controls / FAIR | NIST CSF |

---

## 13. Free Learning Resources by Framework

### Centralized Free Resources

| Platform | What It Offers | Link |
|---|---|---|
| **NIST (all publications)** | All NIST SPs, frameworks, and tools — 100% free | https://csrc.nist.gov/ |
| **MITRE (all frameworks)** | ATT&CK, D3FEND, ENGAGE, CALDERA, CAR, ATLAS — 100% free | https://attack.mitre.org/ |
| **CIS (Controls & Benchmarks)** | Controls v8.1, Benchmarks, and assessment tools — free with registration | https://www.cisecurity.org/ |
| **OWASP (all projects)** | Top 10 lists, testing guides, free tools — 100% free | https://owasp.org/ |
| **SANS Posters** | Visual references for ATT&CK, CIS, Cloud, IR, and more | https://www.sans.org/posters/ |
| **Coursera / edX** | Free audit access to cybersecurity framework courses | https://www.coursera.org/ |
| **Cybrary** | Free cybersecurity training including framework-specific content | https://www.cybrary.it/ |
| **TryHackMe** | Hands-on labs for ATT&CK, Kill Chain, OWASP, and more | https://tryhackme.com/ |
| **Hack The Box Academy** | Structured cybersecurity learning paths | https://academy.hackthebox.com/ |
| **CISA Resources** | Free tools, advisories, and framework guidance from U.S. CISA | https://www.cisa.gov/resources-tools |

### Certifications by Framework Focus

| Certification | Framework Focus | Exam Cost |
|---|---|---|
| **CompTIA Security+** | Broad (NIST, CIS, Kill Chain basics) | ~$392 |
| **CompTIA CySA+** | ATT&CK, Kill Chain, threat detection | ~$392 |
| **CompTIA CASP+** | Advanced risk mgmt, Zero Trust, enterprise security | ~$494 |
| **CISSP (ISC2)** | All frameworks at a governance level | ~$749 |
| **CISM (ISACA)** | ISO 27001, COBIT, NIST CSF, risk management | ~$760 |
| **CISA (ISACA)** | Audit — COBIT, ISO 27001, NIST | ~$760 |
| **GIAC GCTI** | MITRE ATT&CK, Diamond Model, Kill Chain (threat intel) | ~$949 |
| **SC-200 (Microsoft)** | ATT&CK, MITRE, SOC operations | ~$165 |
| **SC-400 (Microsoft)** | Data protection, DLP, information governance | ~$165 |
| **AWS Security Specialty** | NIST, CIS, cloud security architecture | ~$300 |
| **MAD20 Certified (MITRE)** | MITRE ATT&CK specific certification | Free & paid |

---

*Disclaimer: Framework versions, links, and certification costs are current as of February 2026 and subject to change. Always verify with the issuing organization for the latest information.*
