#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Groups, Microsoft.Graph.Identity.Governance

<#
.SYNOPSIS
    Provisions Entra ID security groups, assigns members, and configures access reviews
    for a Microsoft Defender XDR Unified RBAC deployment.

.DESCRIPTION
    This script implements the group model defined in 02-RBAC-Users-and-Groups.md.
    It is designed to be reusable across environments by using variables for all
    configurable values.

    The script performs three phases:
      Phase 1 — Create security groups (if they do not already exist)
      Phase 2 — Add members to groups based on the identity mapping
      Phase 3 — Create access review schedules for each group with the designated reviewer

    IMPORTANT — Read Before Running:
    ────────────────────────────────
    1. This script uses the Microsoft Graph PowerShell SDK.
       Install it first:  Install-Module Microsoft.Graph -Scope CurrentUser

    2. The account running this script needs these Entra ID roles:
       - Groups Administrator (to create groups and manage membership)
       - Identity Governance Administrator (to create access reviews)
       OR
       - Global Administrator (not recommended for day-to-day use)

    3. Run in a TEST TENANT first (e.g., M365 Developer Program tenant).
       Never run untested scripts against production.

    4. The script is IDEMPOTENT — it checks if groups exist before creating them
       and checks membership before adding users.

    5. All variables are defined in the CONFIGURATION section below.
       Edit ONLY that section to adapt this to your environment.

.NOTES
    Version:        1.0
    Author:         Security Engineering
    Last Updated:   February 2026
    Reference:      02-RBAC-Users-and-Groups.md
                    03-Identity-Lifecycle-Management.md

.EXAMPLE
    # Connect to Graph first, then run the script
    Connect-MgGraph -Scopes "Group.ReadWrite.All","AccessReview.ReadWrite.All","User.Read.All"
    .\Deploy-DefenderXDR-RBAC.ps1
#>

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION — Edit this section to match your environment
# ═══════════════════════════════════════════════════════════════════════════════

#region Configuration

# ── Naming Prefix ──
# All groups will be created with this prefix. Change this to match your
# organisation's naming convention (e.g., "SEC-Defender", "SG-XDR", "GRP-SOC").
$GroupPrefix = "SEC-Defender"

# ── Group Mail Nickname Prefix ──
# Entra ID requires a mailNickname (no spaces/special chars). This is auto-generated
# from the group name but you can set a prefix here for consistency.
$MailPrefix = "sec-defender"

# ── Tag / Description Suffix ──
# Added to every group description for filtering and identification.
$TagDescription = "Managed by Deploy-DefenderXDR-RBAC.ps1 | Defender XDR Unified RBAC"

# ── Control Flags ──
# Set to $true to execute that phase, $false to skip it.
# This allows you to run phases independently (e.g., create groups first, add members later).
$CreateGroups       = $true
$AssignMembers      = $true
$CreateAccessReviews = $true

# ── Dry Run Mode ──
# Set to $true to preview all actions WITHOUT making changes.
# Recommended for the first run in any environment.
$DryRun = $true

# ═══════════════════════════════════════════════════════════════════════════════
# GROUP DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════
# Each group is defined with:
#   Key            = Short name (appended to $GroupPrefix)
#   Description    = Purpose of the group (shown in Entra ID)
#   ReviewFrequency = How often access is reviewed (Quarterly, SemiAnnual, Monthly)
#   ReviewerUPN    = UPN of the person who reviews membership
#                    Set to $null if no access review is needed for this group
#
# To add or remove groups, edit this hashtable.
# ─────────────────────────────────────────────────────────────────────────────

$GroupDefinitions = [ordered]@{

    "GlobalAdmin-BreakGlass" = @{
        Description     = "Emergency break-glass access only — 2 accounts maximum"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "ciso@contoso.com"                # ← CHANGE to your CISO UPN
    }

    "SecurityAdmin" = @{
        Description     = "Manage Defender XDR settings, RBAC roles, and security policies"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "ciso@contoso.com"                # ← CHANGE
    }

    "SOCManager" = @{
        Description     = "Full SOC operations access including team management"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "security.director@contoso.com"   # ← CHANGE
    }

    "SOCAnalyst-Tier2" = @{
        Description     = "Senior SOC analysts — investigate, hunt, and respond to incidents"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "soc.manager@contoso.com"         # ← CHANGE
    }

    "SOCAnalyst-Tier1" = @{
        Description     = "Junior SOC analysts — triage alerts, manage incidents, basic response"
        ReviewFrequency = "SemiAnnual"
        ReviewerUPN     = "soc.manager@contoso.com"         # ← CHANGE
    }

    "ThreatHunter" = @{
        Description     = "Advanced hunting, custom detections, and full raw data access"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "soc.manager@contoso.com"         # ← CHANGE
    }

    "DetectionEngineer" = @{
        Description     = "Create and manage custom detection rules and analytics"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "soc.manager@contoso.com"         # ← CHANGE
    }

    "IncidentResponder" = @{
        Description     = "Full response actions during active security incidents"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "soc.manager@contoso.com"         # ← CHANGE
    }

    "SecurityPosture" = @{
        Description     = "View and manage secure score, recommendations, and security posture"
        ReviewFrequency = "SemiAnnual"
        ReviewerUPN     = "security.director@contoso.com"   # ← CHANGE
    }

    "SecurityReader" = @{
        Description     = "Read-only access across all Defender XDR data and dashboards"
        ReviewFrequency = "SemiAnnual"
        ReviewerUPN     = "security.director@contoso.com"   # ← CHANGE
    }

    "EndpointAdmin" = @{
        Description     = "Manage Defender for Endpoint policies, onboarding, and ASR rules"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "security.admin@contoso.com"      # ← CHANGE
    }

    "EmailAdmin" = @{
        Description     = "Manage Defender for Office 365 email security policies"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "security.admin@contoso.com"      # ← CHANGE
    }

    "IdentityAdmin" = @{
        Description     = "Manage Defender for Identity sensors, policies, and configurations"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "security.admin@contoso.com"      # ← CHANGE
    }

    "CloudAppsAdmin" = @{
        Description     = "Manage Defender for Cloud Apps policies and app governance"
        ReviewFrequency = "Quarterly"
        ReviewerUPN     = "security.admin@contoso.com"      # ← CHANGE
    }

    "ExternalSOC" = @{
        Description     = "Limited access for MSSP or outsourced SOC analysts"
        ReviewFrequency = "Monthly"
        ReviewerUPN     = "soc.manager@contoso.com"         # ← CHANGE
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEMBER ASSIGNMENTS
# ═══════════════════════════════════════════════════════════════════════════════
# Map user UPNs to the groups they should belong to.
# Each entry is a user UPN with an array of group short names (matching the
# keys in $GroupDefinitions above).
#
# To add users, add new entries to this hashtable.
# To remove users from a group, remove the group name from their array.
#
# NOTE: This script ADDS members. It does NOT remove existing members who are
# not listed here. Use access reviews to handle stale membership removal.
# ─────────────────────────────────────────────────────────────────────────────

$MemberAssignments = @{

    # ── CISO / Security Director ──
    "ciso@contoso.com" = @(                                 # ← CHANGE UPN
        "SecurityReader",
        "SecurityPosture"
    )

    # ── Security Operations Manager ──
    "soc.manager@contoso.com" = @(                          # ← CHANGE UPN
        "SOCManager"
    )

    # ── Senior SOC Analysts (Tier 2) ──
    "analyst.senior1@contoso.com" = @(                      # ← CHANGE UPN
        "SOCAnalyst-Tier2"
    )
    "analyst.senior2@contoso.com" = @(                      # ← CHANGE UPN
        "SOCAnalyst-Tier2"
    )

    # ── Junior SOC Analysts (Tier 1) ──
    "analyst.junior1@contoso.com" = @(                      # ← CHANGE UPN
        "SOCAnalyst-Tier1"
    )
    "analyst.junior2@contoso.com" = @(                      # ← CHANGE UPN
        "SOCAnalyst-Tier1"
    )

    # ── Threat Hunter ──
    "threat.hunter@contoso.com" = @(                        # ← CHANGE UPN
        "ThreatHunter"
    )

    # ── Detection Engineer ──
    "detection.engineer@contoso.com" = @(                   # ← CHANGE UPN
        "DetectionEngineer"
    )

    # ── Incident Response Lead (gets IR + T2 access) ──
    "ir.lead@contoso.com" = @(                              # ← CHANGE UPN
        "IncidentResponder",
        "SOCAnalyst-Tier2"
    )

    # ── Security Engineer / Architect ──
    "sec.engineer@contoso.com" = @(                         # ← CHANGE UPN
        "SecurityPosture",
        "SecurityReader"
    )

    # ── Platform Administrator ──
    "security.admin@contoso.com" = @(                       # ← CHANGE UPN
        "SecurityAdmin"
    )

    # ── Endpoint Security Specialist ──
    "endpoint.admin@contoso.com" = @(                       # ← CHANGE UPN
        "EndpointAdmin",
        "SOCAnalyst-Tier1"
    )

    # ── Email Security Specialist ──
    "email.admin@contoso.com" = @(                          # ← CHANGE UPN
        "EmailAdmin"
    )

    # ── Identity Security Specialist ──
    "identity.admin@contoso.com" = @(                       # ← CHANGE UPN
        "IdentityAdmin"
    )

    # ── Cloud Security Specialist ──
    "cloud.admin@contoso.com" = @(                          # ← CHANGE UPN
        "CloudAppsAdmin"
    )

    # ── Auditor / Compliance (read-only) ──
    "auditor@contoso.com" = @(                              # ← CHANGE UPN
        "SecurityReader"
    )

    # ── MSSP / External SOC ──
    # NOTE: For external (guest) users, use their full UPN including #EXT#
    # e.g., "analyst_mssp.com#EXT#@contoso.onmicrosoft.com"
    "mssp.analyst1@contoso.com" = @(                        # ← CHANGE UPN
        "ExternalSOC"
    )

    # ── Break-Glass Accounts ──
    "breakglass1@contoso.com" = @(                          # ← CHANGE UPN
        "GlobalAdmin-BreakGlass"
    )
    "breakglass2@contoso.com" = @(                          # ← CHANGE UPN
        "GlobalAdmin-BreakGlass"
    )
}

# ═══════════════════════════════════════════════════════════════════════════════
# ACCESS REVIEW SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════
# These settings apply to ALL access reviews created by this script.
# Individual review frequency is set per-group in $GroupDefinitions above.
# ─────────────────────────────────────────────────────────────────────────────

# Duration in days that reviewers have to complete the review once it starts.
$ReviewDurationDays = 14

# What happens if a reviewer does not respond within the duration.
# Options: "removeAccess", "keepAccess", "acceptAccessRecommendation"
$DefaultDecisionOnTimeout = "removeAccess"

# Whether to show AI-generated recommendations to the reviewer based on sign-in activity.
$ShowRecommendations = $true

# Whether to auto-apply the reviewer's decisions at the end of the review period.
$AutoApplyResults = $true

# Justification required from reviewers when they approve or deny access.
$RequireJustification = $true

# Send reminder emails to reviewers who haven't responded.
$SendReminders = $true

#endregion Configuration

# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTION — Do NOT edit below this line unless you know what you are doing
# ═══════════════════════════════════════════════════════════════════════════════

#region Helper Functions

function Write-Phase {
    param([string]$Phase, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = if ($DryRun) { "[DRY RUN]" } else { "[EXECUTE]" }
    Write-Host "$prefix [$timestamp] [$Phase] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Get-ReviewRecurrencePattern {
    # Converts a friendly frequency name into the Graph API recurrence pattern.
    param([string]$Frequency)

    switch ($Frequency) {
        "Monthly" {
            return @{
                type     = "absoluteMonthly"
                interval = 1
            }
        }
        "Quarterly" {
            return @{
                type     = "absoluteMonthly"
                interval = 3
            }
        }
        "SemiAnnual" {
            return @{
                type     = "absoluteMonthly"
                interval = 6
            }
        }
        "Annual" {
            return @{
                type     = "absoluteMonthly"
                interval = 12
            }
        }
        default {
            Write-Fail "Unknown review frequency: $Frequency. Defaulting to Quarterly."
            return @{
                type     = "absoluteMonthly"
                interval = 3
            }
        }
    }
}

#endregion Helper Functions

#region Pre-Flight Checks

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
Write-Host "  Microsoft Defender XDR — RBAC Group Provisioning Script     " -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "  MODE: DRY RUN — No changes will be made." -ForegroundColor Yellow
    Write-Host "  Set `$DryRun = `$false` in the configuration to execute." -ForegroundColor Yellow
} else {
    Write-Host "  MODE: LIVE — Changes WILL be applied to your tenant." -ForegroundColor Red
}

Write-Host ""
Write-Host "  Phases enabled:" -ForegroundColor White
Write-Host "    Phase 1 - Create Groups:        $CreateGroups" -ForegroundColor White
Write-Host "    Phase 2 - Assign Members:        $AssignMembers" -ForegroundColor White
Write-Host "    Phase 3 - Create Access Reviews:  $CreateAccessReviews" -ForegroundColor White
Write-Host ""

# Verify Microsoft Graph connection
try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected"
    }
    Write-Host "  Connected as: $($context.Account)" -ForegroundColor Green
    Write-Host "  Tenant ID:    $($context.TenantId)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  ERROR: Not connected to Microsoft Graph." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Run the following command first:" -ForegroundColor Yellow
    Write-Host '  Connect-MgGraph -Scopes "Group.ReadWrite.All","AccessReview.ReadWrite.All","User.Read.All"' -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Confirm before live execution
if (-not $DryRun) {
    $confirmation = Read-Host "  Type 'CONFIRM' to proceed with LIVE changes"
    if ($confirmation -ne "CONFIRM") {
        Write-Host "  Aborted. No changes made." -ForegroundColor Yellow
        exit 0
    }
}

#endregion Pre-Flight Checks

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: CREATE SECURITY GROUPS
# ═══════════════════════════════════════════════════════════════════════════════

#region Phase 1

# Stores group IDs for use in later phases.
$CreatedGroups = @{}

if ($CreateGroups) {
    Write-Host ""
    Write-Phase "PHASE 1" "Creating Entra ID Security Groups"
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

    foreach ($groupKey in $GroupDefinitions.Keys) {
        $fullName     = "$GroupPrefix-$groupKey"
        $mailNickname = ($MailPrefix + "-" + $groupKey).ToLower() -replace "[^a-z0-9-]", ""
        $description  = "$($GroupDefinitions[$groupKey].Description) | $TagDescription"

        # Check if group already exists
        $existingGroup = Get-MgGroup -Filter "displayName eq '$fullName'" -ErrorAction SilentlyContinue

        if ($existingGroup) {
            Write-Skip "Group already exists: $fullName (ID: $($existingGroup.Id))"
            $CreatedGroups[$groupKey] = $existingGroup.Id
        } else {
            if ($DryRun) {
                Write-Success "Would create group: $fullName"
                $CreatedGroups[$groupKey] = "dry-run-placeholder-$groupKey"
            } else {
                try {
                    $newGroup = New-MgGroup -DisplayName $fullName `
                        -MailEnabled:$false `
                        -MailNickname $mailNickname `
                        -SecurityEnabled:$true `
                        -Description $description `
                        -GroupTypes @()

                    Write-Success "Created group: $fullName (ID: $($newGroup.Id))"
                    $CreatedGroups[$groupKey] = $newGroup.Id
                } catch {
                    Write-Fail "Failed to create group: $fullName — $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Host ""
    Write-Phase "PHASE 1" "Complete — $($CreatedGroups.Count) groups processed"
} else {
    Write-Host ""
    Write-Phase "PHASE 1" "SKIPPED (CreateGroups = `$false)"

    # Still need to look up existing group IDs for later phases
    foreach ($groupKey in $GroupDefinitions.Keys) {
        $fullName = "$GroupPrefix-$groupKey"
        $existing = Get-MgGroup -Filter "displayName eq '$fullName'" -ErrorAction SilentlyContinue
        if ($existing) {
            $CreatedGroups[$groupKey] = $existing.Id
        }
    }
}

#endregion Phase 1

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: ASSIGN MEMBERS TO GROUPS
# ═══════════════════════════════════════════════════════════════════════════════

#region Phase 2

if ($AssignMembers) {
    Write-Host ""
    Write-Phase "PHASE 2" "Assigning Members to Security Groups"
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

    $totalAssignments = 0
    $skippedAssignments = 0
    $failedAssignments = 0

    foreach ($userUPN in $MemberAssignments.Keys) {
        $groupNames = $MemberAssignments[$userUPN]

        # Look up the user in Entra ID
        $user = $null
        try {
            $user = Get-MgUser -UserId $userUPN -ErrorAction Stop
        } catch {
            Write-Fail "User not found: $userUPN — skipping all assignments for this user"
            $failedAssignments += $groupNames.Count
            continue
        }

        foreach ($groupKey in $groupNames) {
            $fullName = "$GroupPrefix-$groupKey"
            $groupId  = $CreatedGroups[$groupKey]

            if (-not $groupId -or $groupId -like "dry-run-*") {
                if ($DryRun) {
                    Write-Success "Would add $userUPN → $fullName"
                    $totalAssignments++
                } else {
                    Write-Fail "Group not found: $fullName — cannot add $userUPN"
                    $failedAssignments++
                }
                continue
            }

            # Check if user is already a member
            $isMember = $false
            try {
                $members = Get-MgGroupMember -GroupId $groupId -All
                $isMember = $members.Id -contains $user.Id
            } catch {
                # If we can't check membership, try to add anyway
            }

            if ($isMember) {
                Write-Skip "Already a member: $userUPN → $fullName"
                $skippedAssignments++
            } else {
                if ($DryRun) {
                    Write-Success "Would add: $userUPN → $fullName"
                    $totalAssignments++
                } else {
                    try {
                        $params = @{
                            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
                        }
                        New-MgGroupMemberByRef -GroupId $groupId -BodyParameter $params
                        Write-Success "Added: $userUPN → $fullName"
                        $totalAssignments++
                    } catch {
                        Write-Fail "Failed to add $userUPN → $fullName — $($_.Exception.Message)"
                        $failedAssignments++
                    }
                }
            }
        }
    }

    Write-Host ""
    Write-Phase "PHASE 2" "Complete — Added: $totalAssignments | Skipped: $skippedAssignments | Failed: $failedAssignments"
} else {
    Write-Host ""
    Write-Phase "PHASE 2" "SKIPPED (AssignMembers = `$false)"
}

#endregion Phase 2

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: CREATE ACCESS REVIEWS
# ═══════════════════════════════════════════════════════════════════════════════

#region Phase 3

if ($CreateAccessReviews) {
    Write-Host ""
    Write-Phase "PHASE 3" "Creating Access Review Schedules"
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

    $reviewsCreated = 0
    $reviewsSkipped = 0
    $reviewsFailed  = 0

    foreach ($groupKey in $GroupDefinitions.Keys) {
        $groupDef   = $GroupDefinitions[$groupKey]
        $fullName   = "$GroupPrefix-$groupKey"
        $groupId    = $CreatedGroups[$groupKey]
        $reviewerUPN = $groupDef.ReviewerUPN
        $frequency   = $groupDef.ReviewFrequency

        # Skip groups with no reviewer configured
        if (-not $reviewerUPN) {
            Write-Skip "No reviewer configured for $fullName — skipping access review"
            $reviewsSkipped++
            continue
        }

        # Skip if group doesn't exist yet (dry run)
        if (-not $groupId -or $groupId -like "dry-run-*") {
            if ($DryRun) {
                Write-Success "Would create $frequency access review for $fullName (reviewer: $reviewerUPN)"
                $reviewsCreated++
                continue
            } else {
                Write-Fail "Group not found: $fullName — cannot create access review"
                $reviewsFailed++
                continue
            }
        }

        # Look up the reviewer user
        $reviewer = $null
        try {
            $reviewer = Get-MgUser -UserId $reviewerUPN -ErrorAction Stop
        } catch {
            Write-Fail "Reviewer not found: $reviewerUPN — skipping review for $fullName"
            $reviewsFailed++
            continue
        }

        # Build the access review schedule definition
        $reviewDisplayName = "Defender XDR Access Review — $fullName"
        $recurrence = Get-ReviewRecurrencePattern -Frequency $frequency
        $startDate  = (Get-Date).AddDays(1).ToString("yyyy-MM-ddT00:00:00.000Z")

        # Check if an access review already exists for this group
        $existingReviews = $null
        try {
            $existingReviews = Get-MgIdentityGovernanceAccessReviewDefinition -Filter "displayName eq '$reviewDisplayName'" -ErrorAction SilentlyContinue
        } catch {
            # If the filter fails, continue and try to create
        }

        if ($existingReviews) {
            Write-Skip "Access review already exists: $reviewDisplayName"
            $reviewsSkipped++
            continue
        }

        if ($DryRun) {
            Write-Success "Would create $frequency access review for $fullName (reviewer: $reviewerUPN)"
            $reviewsCreated++
        } else {
            try {
                $reviewParams = @{
                    displayName = $reviewDisplayName
                    descriptionForAdmins  = "Recurring $frequency review of $fullName membership. Reviewer: $reviewerUPN. Auto-removes access if not approved."
                    descriptionForReviewers = "Please review whether each member still needs access to the $fullName security group for Microsoft Defender XDR. Deny access for anyone who no longer requires it."
                    scope = @{
                        query     = "/groups/$groupId/members"
                        queryType = "MicrosoftGraph"
                    }
                    reviewers = @(
                        @{
                            query     = "/users/$($reviewer.Id)"
                            queryType = "MicrosoftGraph"
                        }
                    )
                    fallbackReviewers = @(
                        @{
                            query     = "/groups/$groupId/owners"
                            queryType = "MicrosoftGraph"
                        }
                    )
                    settings = @{
                        mailNotificationsEnabled        = $true
                        reminderNotificationsEnabled     = $SendReminders
                        justificationRequiredOnApproval  = $RequireJustification
                        defaultDecisionEnabled           = $true
                        defaultDecision                  = $DefaultDecisionOnTimeout
                        autoApplyDecisionsEnabled        = $AutoApplyResults
                        recommendationsEnabled           = $ShowRecommendations
                        instanceDurationInDays           = $ReviewDurationDays
                        recurrence = @{
                            pattern = $recurrence
                            range = @{
                                type      = "noEnd"
                                startDate = $startDate
                            }
                        }
                    }
                }

                New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $reviewParams
                Write-Success "Created $frequency access review: $reviewDisplayName"
                $reviewsCreated++
            } catch {
                Write-Fail "Failed to create access review for $fullName — $($_.Exception.Message)"
                $reviewsFailed++
            }
        }
    }

    Write-Host ""
    Write-Phase "PHASE 3" "Complete — Created: $reviewsCreated | Skipped: $reviewsSkipped | Failed: $reviewsFailed"
} else {
    Write-Host ""
    Write-Phase "PHASE 3" "SKIPPED (CreateAccessReviews = `$false)"
}

#endregion Phase 3

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
Write-Host "  DEPLOYMENT SUMMARY                                          " -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
Write-Host ""
Write-Host "  Groups processed:          $($CreatedGroups.Count)" -ForegroundColor White
Write-Host "  Member assignments:        $($MemberAssignments.Count) users" -ForegroundColor White
Write-Host "  Access reviews configured: $($GroupDefinitions.Count) groups" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "  This was a DRY RUN. No changes were made." -ForegroundColor Yellow
    Write-Host "  To apply changes, set `$DryRun = `$false and re-run." -ForegroundColor Yellow
} else {
    Write-Host "  All changes have been applied." -ForegroundColor Green
}

Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor White
Write-Host "  ────────────" -ForegroundColor Gray
Write-Host "  1. Go to the Defender portal > Settings > Permissions" -ForegroundColor White
Write-Host "     and create Unified RBAC custom roles pointing to these groups." -ForegroundColor White
Write-Host "  2. Review 02-RBAC-Users-and-Groups.md for custom role definitions." -ForegroundColor White
Write-Host "  3. Optionally enable PIM for privileged groups — see" -ForegroundColor White
Write-Host "     03-Identity-Lifecycle-Management.md Section 6." -ForegroundColor White
Write-Host "  4. Forward Entra ID audit logs to Sentinel to monitor" -ForegroundColor White
Write-Host "     group membership changes." -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
