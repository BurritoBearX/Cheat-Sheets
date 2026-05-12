# =============================================================================
# POWERSTIG CHEAT SHEET — Automated STIG Compliance with PowerShell DSC
# =============================================================================
# PowerSTIG is a Microsoft open-source module that:
#   - Parses DISA STIG XCCDF content into PowerShell DSC configurations
#   - Applies STIG settings to Windows systems via DSC
#   - Scans for compliance and generates STIG Viewer (.ckl) checklists
#
# Source:      https://github.com/Microsoft/PowerStig
# Prereqs:     PowerShell 5.1+, DSC, WinRM, Admin rights
#
# Key concept: PowerSTIG wraps DSC resources. You write a Configuration block
# that references PowerSTIG DSC resources (like WindowsServer, IisSite, etc.)
# instead of individual DSC resources. PowerSTIG handles the STIG rules internally.
# =============================================================================


# =============================================================================
# INSTALLATION & SETUP
# =============================================================================

# Install PowerSTIG from PSGallery
Install-Module -Name PowerStig -Force -AllowClobber
Install-Module -Name PowerStig -RequiredVersion 4.22.0 -Force  # pin a specific version

# PowerSTIG has its own DSC resource dependencies — install them too
# The module manifest lists all required modules; this installs them automatically
Install-Module -Name PowerStig -Force -AllowClobber
# If dependencies fail to install automatically:
Install-Module -Name AccessControlDsc        -Force
Install-Module -Name AuditPolicyDsc          -Force
Install-Module -Name AuditSystemDsc          -Force
Install-Module -Name CertificateDsc          -Force
Install-Module -Name ComputerManagementDsc   -Force
Install-Module -Name FileContentDsc          -Force
Install-Module -Name GPRegistryPolicyDsc     -Force
Install-Module -Name PSDscResources          -Force
Install-Module -Name SecurityPolicyDsc       -Force
Install-Module -Name SqlServerDsc            -Force
Install-Module -Name WindowsDefenderDsc      -Force
Install-Module -Name xDnsServer              -Force
Install-Module -Name xWebAdministration      -Force

# Verify installation
Get-Module -Name PowerStig -ListAvailable       # confirm module is present
Import-Module PowerStig                          # load into current session
Get-Command -Module PowerStig                    # list all exported commands

# View all available PowerSTIG DSC resources
Get-DscResource -Module PowerStig

# Find where the module is installed (needed for StigData files)
$stigModulePath = (Get-Module PowerStig -ListAvailable | Select-Object -First 1).ModuleBase
$stigModulePath
# Typically: C:\Program Files\WindowsPowerShell\Modules\PowerStig\<version>

# StigData lives here — browse to understand what's available
Get-ChildItem "$stigModulePath\StigData\Processed"  # processed (parsed) STIG XML
Get-ChildItem "$stigModulePath\StigData\Archive"    # raw XCCDF files from DISA


# =============================================================================
# DISCOVERING AVAILABLE STIGS
# =============================================================================

# List all available STIG technologies and versions
$stigModulePath = (Get-Module PowerStig -ListAvailable | Select-Object -First 1).ModuleBase
Get-ChildItem "$stigModulePath\StigData\Processed" -Directory | Select-Object Name

# List available versions for a specific technology
Get-ChildItem "$stigModulePath\StigData\Processed\WindowsServer"
# Output shows files like:  WindowsServer-2019-MS-2.5.xml
#   Technology = WindowsServer
#   OsVersion  = 2019
#   Role       = MS  (Member Server) or DC (Domain Controller)
#   StigVersion= 2.5

# Available Technology types (DSC resource names):
#
#   Technology               OsVersion examples      Role examples
#   ─────────────────────────────────────────────────────────────
#   WindowsServer            2012R2, 2016, 2019, 2022  MS, DC
#   WindowsClient            10, 11                   -
#   WindowsDefender          1.0                      -
#   WindowsDnsServer         2012R2, 2016, 2019, 2022  -
#   WindowsFirewall          1.0 (all OS versions)    -
#   DotNetFramework          4                        -
#   IisServer                8.5, 10.0                -
#   IisSite                  8.5, 10.0                -
#   SqlServerInstance        2012, 2016, 2017, 2019   Database, Instance
#   SqlServerDatabase        2012, 2016, 2017, 2019   -
#   OracleJRE                8                        -
#   ChromeBrowser            1.0                      -
#   Firefox                  5, 3                     -
#   Adobe                    AcrobatReader, Acrobat   -
#   Office                   2016, 2019               Outlook, Word, Excel, PowerPoint

# Get all rules for a specific STIG (useful for building exceptions/skip lists)
$xccdfPath = "$stigModulePath\StigData\Archive\WindowsServer\U_MS_Windows_Server_2019_STIG_V2R5_Manual-xccdf.xml"
Get-Content $xccdfPath | Select-String -Pattern 'id="V-'   # quick view of rule IDs

# Recommended: use STIG Viewer (DoD tool) to browse rules visually
# Download STIG Viewer from: https://public.cyber.mil/stigs/srg-stig-tools/


# =============================================================================
# ORGANIZATIONAL SETTINGS (ORGSET)
# =============================================================================

# Some STIG rules have values within an acceptable range (e.g. "max password age
# must be between 1 and 60 days"). OrgSettings let you define your org's specific
# value for those rules without violating compliance.

# Find the OrgSettings file for your STIG
$orgSettingsPath = "$stigModulePath\StigData\Processed\WindowsServer"
Get-ChildItem $orgSettingsPath -Filter "*.xml" | Where-Object { $_.Name -like "*OrgSettings*" }
# Files named like: WindowsServer-2019-MS-2.5.org.default.xml

# Copy the default OrgSettings to your project and customize it
Copy-Item "$stigModulePath\StigData\Processed\WindowsServer\WindowsServer-2019-MS-2.5.org.default.xml" `
          "C:\DSC\OrgSettings\WindowsServer-2019-MS.xml"

# The XML looks like this — edit values within the allowed range for each rule:
# <OrganizationalSettings>
#   <OrganizationalSetting id="V-93147" value="14" />   <!-- password min length -->
#   <OrganizationalSetting id="V-93505" value="60" />   <!-- max password age    -->
# </OrganizationalSettings>

# Reference OrgSettings in your configuration
# OrgSettings = "C:\DSC\OrgSettings\WindowsServer-2019-MS.xml"
# — OR —
# OrgSettings as a hashtable (inline):
# OrgSettings = @{ 'V-93147' = @{ ValueData = '14' } }


# =============================================================================
# EXCEPTIONS & SKIP RULES
# =============================================================================

# Exception — override a specific rule's expected value (e.g. your env requires
# a different but still compliant value than what PowerSTIG defaults to)
$ExceptionExample = @{
    'V-93507' = @{
        ValueData = '2'             # override the configured value for this rule
    }
    'V-93519' = @{
        Identity  = 'BUILTIN\Administrators'
        ValueData = '1'
    }
}

# SkipRule — completely exclude rules that don't apply to your environment
# (e.g. a rule for a feature you don't use, or handled by a compensating control)
$SkipRuleExample = @(
    'V-93147',   # document WHY you are skipping each rule
    'V-93505',
    'V-93515'
)

# SkipRuleType — skip an entire category of rule types
# Rule types: AccountPolicy, AuditPolicy, DnsServerRootHint, DnsServerSetting,
#             IISLogging, MimeType, Permission, Registry, RootHint, SecurityOption,
#             Service, SqlScriptQuery, UserRight, WinEventLog, WMI, xccdf_org.cisecurity
$SkipRuleTypeExample = @(
    'DnsServerRootHint'   # skip all DNS root hint rules (if using internal DNS)
)


# =============================================================================
# WINDOWS SERVER STIG CONFIGURATION
# =============================================================================

Configuration WindowsServerStigConfig {
    param (
        [string]$NodeName    = 'localhost',
        [string]$OsVersion   = '2019',
        [string]$Role        = 'MS',            # MS = Member Server, DC = Domain Controller
        [string]$StigVersion = '2.5',
        [string]$OrgSettings = 'C:\DSC\OrgSettings\WindowsServer-2019-MS.xml'
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName {

        WindowsServer BaseStig {
            OsVersion   = $OsVersion
            OsRole      = $Role                 # MS | DC
            StigVersion = $StigVersion
            OrgSettings = $OrgSettings

            # Optional: skip rules that don't apply
            SkipRule = @(
                'V-93147',   # rule not applicable — compensating control in place
                'V-93505'
            )

            # Optional: override specific rule values
            Exception = @{
                'V-93519' = @{
                    Identity = 'BUILTIN\Administrators'
                }
            }
        }
    }
}

# Compile to MOF
WindowsServerStigConfig -OutputPath 'C:\DSC\WindowsServer'

# Apply to local machine
Start-DscConfiguration -Path 'C:\DSC\WindowsServer' -Wait -Verbose -Force

# Apply to remote machine
Start-DscConfiguration -Path 'C:\DSC\WindowsServer' `
    -ComputerName 'Server01' -Wait -Verbose


# =============================================================================
# DOMAIN CONTROLLER STIG
# =============================================================================

Configuration DomainControllerStigConfig {
    param (
        [string]$NodeName    = 'DC01',
        [string]$OsVersion   = '2019',
        [string]$StigVersion = '2.5',
        [string]$OrgSettings = 'C:\DSC\OrgSettings\WindowsServer-2019-DC.xml'
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName {

        # DC STIG — note OsRole = 'DC'
        WindowsServer DcStig {
            OsVersion   = $OsVersion
            OsRole      = 'DC'
            StigVersion = $StigVersion
            OrgSettings = $OrgSettings
        }

        # DNS Server STIG — apply alongside DC STIG if DNS role is installed
        WindowsDnsServer DnsStig {
            OsVersion   = $OsVersion
            StigVersion = '2.5'
        }
    }
}

DomainControllerStigConfig -OutputPath 'C:\DSC\DC'
Start-DscConfiguration -Path 'C:\DSC\DC' -ComputerName 'DC01' -Wait -Verbose


# =============================================================================
# WINDOWS CLIENT (WORKSTATION) STIG
# =============================================================================

Configuration WindowsClientStigConfig {
    param (
        [string]$OsVersion   = '10',
        [string]$StigVersion = '2.6',
        [string]$OrgSettings = 'C:\DSC\OrgSettings\WindowsClient-10.xml'
    )

    Import-DscResource -ModuleName PowerStig

    Node 'localhost' {

        WindowsClient WindowsClientStig {
            OsVersion   = $OsVersion
            StigVersion = $StigVersion
            OrgSettings = $OrgSettings
            SkipRule    = @('V-220726')   # example: biometrics rule not applicable
        }

        WindowsDefender DefenderStig {
            OsVersion   = $OsVersion
            StigVersion = '2.4'
        }

        WindowsFirewall FirewallStig {
            OsVersion   = '1.0'
            StigVersion = '1.7'
        }

        DotNetFramework DotNetStig {
            FrameworkVersion = '4'
            StigVersion      = '2.2'
        }
    }
}

WindowsClientStigConfig -OutputPath 'C:\DSC\WindowsClient'
Start-DscConfiguration -Path 'C:\DSC\WindowsClient' -Wait -Verbose


# =============================================================================
# IIS WEB SERVER & SITE STIG
# =============================================================================

Configuration IisStigConfig {
    param (
        [string]$NodeName       = 'WebServer01',
        [string]$IisVersion     = '10.0',
        [string]$StigVersion    = '2.8',
        [string[]]$SiteNames    = @('Default Web Site', 'MyApp')
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName {

        # IIS Server STIG — server-wide settings
        IisServer IisServerStig {
            IisVersion  = $IisVersion
            StigVersion = $StigVersion
        }

        # IIS Site STIG — once per site
        foreach ($site in $SiteNames) {
            IisSite "IisSiteStig_$($site -replace ' ', '_')" {
                IisVersion  = $IisVersion
                StigVersion = $StigVersion
                SiteName    = $site
            }
        }

        # Apply Windows Server STIG on the same node
        WindowsServer OsStig {
            OsVersion   = '2019'
            OsRole      = 'MS'
            StigVersion = '2.5'
        }
    }
}

IisStigConfig -OutputPath 'C:\DSC\IIS'
Start-DscConfiguration -Path 'C:\DSC\IIS' -ComputerName 'WebServer01' -Wait -Verbose


# =============================================================================
# SQL SERVER STIG
# =============================================================================

Configuration SqlStigConfig {
    param (
        [string]$NodeName       = 'SqlServer01',
        [string]$SqlVersion     = '2019',
        [string]$StigVersion    = '1.2',
        [string]$SqlInstance    = 'MSSQLSERVER',      # default instance
        [string[]]$Databases    = @('master', 'MyAppDb')
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName {

        # SQL Server Instance STIG
        SqlServerInstance SqlInstanceStig {
            SqlVersion   = $SqlVersion
            SqlRole      = 'Instance'
            StigVersion  = $StigVersion
            ServerInstance = $SqlInstance

            SkipRule = @(
                'V-213923'   # example: rule for feature not installed
            )
        }

        # SQL Server Database STIG — once per database
        foreach ($db in $Databases) {
            SqlServerDatabase "SqlDbStig_$db" {
                SqlVersion   = $SqlVersion
                SqlRole      = 'Database'
                StigVersion  = $StigVersion
                ServerInstance = $SqlInstance
                Database     = $db
            }
        }
    }
}

SqlStigConfig -OutputPath 'C:\DSC\SQL'
Start-DscConfiguration -Path 'C:\DSC\SQL' -ComputerName 'SqlServer01' -Wait -Verbose


# =============================================================================
# MULTI-STIG NODE — APPLYING SEVERAL STIGS TO ONE MACHINE
# =============================================================================

# Best practice: one Configuration that applies ALL relevant STIGs to a node type
# so a single MOF captures the full desired state

Configuration FullMemberServerStig {
    param (
        [string]$NodeName = 'localhost'
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName {

        WindowsServer OsStig {
            OsVersion   = '2019'
            OsRole      = 'MS'
            StigVersion = '2.5'
            OrgSettings = 'C:\DSC\OrgSettings\WindowsServer-2019-MS.xml'
        }

        WindowsDefender DefenderStig {
            OsVersion   = '2019'
            StigVersion = '2.4'
        }

        WindowsFirewall FirewallStig {
            OsVersion   = '1.0'
            StigVersion = '1.7'
        }

        DotNetFramework DotNetStig {
            FrameworkVersion = '4'
            StigVersion      = '2.2'
        }

        # If IIS role is installed on this server, add the IIS STIGs too
        IisServer IisServerStig {
            IisVersion  = '10.0'
            StigVersion = '2.8'
        }

        IisSite DefaultSiteStig {
            IisVersion  = '10.0'
            StigVersion = '2.8'
            SiteName    = 'Default Web Site'
        }
    }
}

FullMemberServerStig -OutputPath 'C:\DSC\FullMemberServer'
Start-DscConfiguration -Path 'C:\DSC\FullMemberServer' -Wait -Verbose


# =============================================================================
# CONFIGURATION DATA FOR MULTIPLE NODES
# =============================================================================

# Use ConfigurationData to manage many servers with one configuration

$StigConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = '*'
            PSDscAllowPlainTextPassword = $false   # use cert encryption in production
            PSDscAllowDomainUser        = $true
        },
        @{
            NodeName    = 'WebServer01'
            Role        = 'WebServer'
            OsVersion   = '2019'
            OrgSettings = 'C:\DSC\OrgSettings\WindowsServer-2019-MS.xml'
        },
        @{
            NodeName    = 'WebServer02'
            Role        = 'WebServer'
            OsVersion   = '2019'
            OrgSettings = 'C:\DSC\OrgSettings\WindowsServer-2019-MS.xml'
        },
        @{
            NodeName    = 'DC01'
            Role        = 'DomainController'
            OsVersion   = '2019'
            OrgSettings = 'C:\DSC\OrgSettings\WindowsServer-2019-DC.xml'
        }
    )
}

Configuration ScaledStigConfig {
    Import-DscResource -ModuleName PowerStig

    # Web servers
    Node $AllNodes.Where({ $_.Role -eq 'WebServer' }).NodeName {
        WindowsServer OsStig {
            OsVersion   = $Node.OsVersion
            OsRole      = 'MS'
            StigVersion = '2.5'
            OrgSettings = $Node.OrgSettings
        }
        IisServer IisStig {
            IisVersion  = '10.0'
            StigVersion = '2.8'
        }
    }

    # Domain controllers
    Node $AllNodes.Where({ $_.Role -eq 'DomainController' }).NodeName {
        WindowsServer OsStig {
            OsVersion   = $Node.OsVersion
            OsRole      = 'DC'
            StigVersion = '2.5'
            OrgSettings = $Node.OrgSettings
        }
        WindowsDnsServer DnsStig {
            OsVersion   = $Node.OsVersion
            StigVersion = '2.5'
        }
    }
}

# Compile — creates one MOF per node
ScaledStigConfig -ConfigurationData $StigConfigData -OutputPath 'C:\DSC\Scaled'

# Deploy to all nodes in parallel (no -Wait = background jobs)
Start-DscConfiguration -Path 'C:\DSC\Scaled' -Verbose

# Wait for all jobs to finish
Get-Job | Wait-Job | Receive-Job


# =============================================================================
# SCANNING / COMPLIANCE CHECKING
# =============================================================================

# --- Check compliance without making changes ---

# Quick check — returns $true (compliant) or $false (non-compliant)
Test-DscConfiguration -Verbose

# Detailed check — shows exactly which rules are passing and failing
$result = Test-DscConfiguration -Detailed
$result.InDesiredState                          # overall $true / $false
$result.ResourcesInDesiredState                 # compliant rules
$result.ResourcesNotInDesiredState              # non-compliant rules — the findings

# Count findings
($result.ResourcesNotInDesiredState).Count

# Show just the finding names and instance names
$result.ResourcesNotInDesiredState |
    Select-Object ResourceId, InstanceName, InDesiredState |
    Format-Table -AutoSize

# Remote compliance check
$cimSession = New-CimSession -ComputerName 'Server01' -Credential (Get-Credential)
$result = Test-DscConfiguration -CimSession $cimSession -Detailed
Remove-CimSession $cimSession

# Scan multiple machines and aggregate results
$servers = @('Server01', 'Server02', 'Server03')
$allResults = foreach ($server in $servers) {
    $session = New-CimSession -ComputerName $server
    $res = Test-DscConfiguration -CimSession $session -Detailed
    [PSCustomObject]@{
        ComputerName    = $server
        InDesiredState  = $res.InDesiredState
        FindingCount    = ($res.ResourcesNotInDesiredState).Count
        PassCount       = ($res.ResourcesInDesiredState).Count
    }
    Remove-CimSession $session
}
$allResults | Format-Table -AutoSize

# Export compliance summary to CSV
$allResults | Export-Csv -Path 'C:\Reports\StigComplianceSummary.csv' -NoTypeInformation


# =============================================================================
# GENERATING STIG VIEWER CHECKLISTS (.ckl FILES)
# =============================================================================

# .ckl files are the standard format for STIG findings — importable into STIG Viewer
# PowerSTIG can generate them from a DSC result

# --- Generate a CKL from a live compliance scan ---

# Step 1: Gather the reference MOF content and DSC result
$mofPath = 'C:\DSC\WindowsServer\localhost.mof'

# Step 2: Run a compliance test to get the current state
$dscResult = Test-DscConfiguration -Detailed

# Step 3: Generate the .ckl checklist
New-StigChecklist `
    -ReferenceConfiguration $mofPath `
    -DscResult              $dscResult `
    -OutputPath             'C:\Reports\WindowsServer2019-MS.ckl'

# --- Generate CKL for a remote machine ---
$session  = New-CimSession -ComputerName 'Server01' -Credential (Get-Credential)
$dscResult = Test-DscConfiguration -CimSession $session -Detailed

New-StigChecklist `
    -ReferenceConfiguration 'C:\DSC\WindowsServer\Server01.mof' `
    -DscResult              $dscResult `
    -OutputPath             'C:\Reports\Server01-STIG.ckl'

Remove-CimSession $session

# Verify the output file
Test-Path 'C:\Reports\Server01-STIG.ckl'
Get-Item  'C:\Reports\Server01-STIG.ckl'


# =============================================================================
# AUTOMATED COMPLIANCE PIPELINE
# =============================================================================

# Full pipeline: compile → apply → scan → report → alert
# Run this as a scheduled task, CI/CD step, or Azure Automation runbook

function Invoke-StigCompliancePipeline {
    param (
        [string[]]$Targets          = @('localhost'),
        [string]$ConfigPath         = 'C:\DSC\FullMemberServer',
        [string]$ReportPath         = 'C:\Reports',
        [int]$FindingThreshold      = 0,     # alert if findings exceed this number
        [switch]$Remediate                   # if set, apply config before scanning
    )

    # Ensure report directory exists
    if (-not (Test-Path $ReportPath)) { New-Item -ItemType Directory -Path $ReportPath | Out-Null }

    $timestamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
    $summaryFile = "$ReportPath\StigSummary_$timestamp.csv"
    $allResults  = @()

    foreach ($target in $Targets) {
        Write-Host "Processing $target..." -ForegroundColor Cyan

        try {
            $session = if ($target -eq 'localhost') {
                $null
            } else {
                New-CimSession -ComputerName $target -ErrorAction Stop
            }

            # Optionally remediate before scanning
            if ($Remediate) {
                Write-Host "  Applying configuration to $target..." -ForegroundColor Yellow
                if ($session) {
                    Start-DscConfiguration -Path $ConfigPath -CimSession $session -Wait -Force
                } else {
                    Start-DscConfiguration -Path $ConfigPath -Wait -Force
                }
            }

            # Scan compliance
            Write-Host "  Scanning $target..." -ForegroundColor Yellow
            $dscResult = if ($session) {
                Test-DscConfiguration -CimSession $session -Detailed
            } else {
                Test-DscConfiguration -Detailed
            }

            $findingCount = ($dscResult.ResourcesNotInDesiredState).Count
            $passCount    = ($dscResult.ResourcesInDesiredState).Count
            $total        = $findingCount + $passCount
            $pctCompliant = if ($total -gt 0) { [math]::Round(($passCount / $total) * 100, 1) } else { 0 }

            # Generate CKL
            $mofFile = Get-ChildItem $ConfigPath -Filter '*.mof' |
                Where-Object { $_.BaseName -eq $target } |
                Select-Object -First 1

            if ($mofFile) {
                $cklPath = "$ReportPath\$target-$timestamp.ckl"
                New-StigChecklist -ReferenceConfiguration $mofFile.FullName `
                                  -DscResult $dscResult `
                                  -OutputPath $cklPath
                Write-Host "  CKL saved: $cklPath" -ForegroundColor Green
            }

            $row = [PSCustomObject]@{
                ComputerName   = $target
                Timestamp      = (Get-Date)
                Compliant      = $dscResult.InDesiredState
                Findings       = $findingCount
                Passing        = $passCount
                PercentPass    = $pctCompliant
                CklFile        = if ($mofFile) { $cklPath } else { 'MOF not found' }
            }

            # Alert on threshold breach
            if ($findingCount -gt $FindingThreshold) {
                Write-Warning "$target has $findingCount STIG findings (threshold: $FindingThreshold)"
            }

            $allResults += $row

        } catch {
            Write-Error "Failed to process $target : $_"
            $allResults += [PSCustomObject]@{
                ComputerName = $target
                Timestamp    = (Get-Date)
                Compliant    = $false
                Findings     = -1
                Passing      = -1
                PercentPass  = 0
                CklFile      = "ERROR: $_"
            }
        } finally {
            if ($session) { Remove-CimSession $session }
        }
    }

    # Export summary report
    $allResults | Export-Csv -Path $summaryFile -NoTypeInformation
    Write-Host "`nSummary written to: $summaryFile" -ForegroundColor Green
    $allResults | Format-Table -AutoSize
}

# Example usage:
Invoke-StigCompliancePipeline -Targets @('Server01','Server02','Server03') `
                              -ConfigPath 'C:\DSC\FullMemberServer' `
                              -ReportPath 'C:\Reports' `
                              -FindingThreshold 5

# Remediate AND scan:
Invoke-StigCompliancePipeline -Targets @('Server01') `
                              -ConfigPath 'C:\DSC\FullMemberServer' `
                              -ReportPath 'C:\Reports' `
                              -Remediate


# =============================================================================
# SCHEDULED COMPLIANCE MONITORING (TASK SCHEDULER)
# =============================================================================

# Create a wrapper script to run the compliance pipeline
$scriptContent = @'
Import-Module PowerStig
. C:\DSC\Scripts\Invoke-StigCompliancePipeline.ps1

$servers = Get-Content 'C:\DSC\serverlist.txt'

Invoke-StigCompliancePipeline `
    -Targets           $servers `
    -ConfigPath        'C:\DSC\FullMemberServer' `
    -ReportPath        'C:\Reports' `
    -FindingThreshold  10
'@

$scriptContent | Set-Content 'C:\DSC\Scripts\Run-StigScan.ps1'

# Register a scheduled task to run daily at 6 AM
$action  = New-ScheduledTaskAction  -Execute 'powershell.exe' `
                                    -Argument '-NonInteractive -File C:\DSC\Scripts\Run-StigScan.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At '06:00AM'
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName 'DailyStigScan' `
                       -Action   $action `
                       -Trigger  $trigger `
                       -Settings $settings `
                       -Principal $principal

# Run the task immediately to verify it works
Start-ScheduledTask -TaskName 'DailyStigScan'
Get-ScheduledTaskInfo  -TaskName 'DailyStigScan'


# =============================================================================
# USING DSC PULL MODE FOR CONTINUOUS ENFORCEMENT
# =============================================================================

# Pull mode is ideal for STIG automation — nodes auto-correct drift on a schedule
# See powershell_dsc_cheatsheet.ps1 for full pull server setup

# Configure the LCM on managed nodes for continuous STIG enforcement
[DscLocalConfigurationManager()]
Configuration StigLcmConfig {
    Node 'localhost' {
        Settings {
            RefreshMode                    = 'Pull'
            ConfigurationMode              = 'ApplyAndAutoCorrect'  # auto-fix drift
            ConfigurationModeFrequencyMins = 60                     # check every hour
            RefreshFrequencyMins           = 60
            RebootNodeIfNeeded             = $false   # set $true only if you accept reboots
        }

        ConfigurationRepositoryWeb StigPullServer {
            ServerURL          = 'https://pullserver.example.com:8080/PSDSCPullServer.svc'
            RegistrationKey    = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
            ConfigurationNames = @('FullMemberServerStig')
        }
    }
}

# On the pull server — publish updated STIG MOFs and checksums
Copy-Item 'C:\DSC\FullMemberServer\*.mof'     'C:\DSCConfig\'
New-DscChecksum -Path 'C:\DSCConfig' -Force   # regenerate checksums after update


# =============================================================================
# INVESTIGATING INDIVIDUAL STIG RULES
# =============================================================================

# Get all rules from a STIG (useful for building skip/exception lists)
$modulePath  = (Get-Module PowerStig -ListAvailable | Select-Object -First 1).ModuleBase
$xccdfFile   = Get-ChildItem "$modulePath\StigData\Archive\WindowsServer" |
               Where-Object { $_.Name -like '*2019*V2*' } |
               Select-Object -Last 1   # get latest version

# Read and search the XCCDF
[xml]$xccdf = Get-Content $xccdfFile.FullName
$rules = $xccdf.Benchmark.Group

# List all rules with their titles
$rules | ForEach-Object {
    [PSCustomObject]@{
        Id       = $_.id
        Title    = $_.Rule.title
        Severity = $_.Rule.severity
    }
} | Sort-Object Severity | Format-Table -AutoSize

# Find rules for a specific topic
$rules | Where-Object { $_.Rule.title -match 'password' } |
    Select-Object @{n='Id';e={$_.id}}, @{n='Title';e={$_.Rule.title}}

# View a specific rule in detail
$rules | Where-Object { $_.id -eq 'V-93147' } | Select-Object -ExpandProperty Rule |
    Select-Object title, severity, description

# Find configurable rules (ones that need OrgSettings)
$rules | Where-Object { $_.Rule.check.'check-content' -match 'configur' } |
    Select-Object @{n='Id';e={$_.id}}, @{n='Title';e={$_.Rule.title}} |
    Select-Object -First 20


# =============================================================================
# TROUBLESHOOTING
# =============================================================================

# --- DSC / LCM issues ---
Get-DscLocalConfigurationManager                    # check LCM state
Get-DscConfigurationStatus                          # last run result
Get-DscConfigurationStatus -All | Select-Object -First 5   # recent history

# View DSC event log for errors
Get-WinEvent -LogName 'Microsoft-Windows-Desired State Configuration-Operational' |
    Where-Object LevelDisplayName -eq 'Error' |
    Select-Object TimeCreated, Message |
    Format-List

# --- PowerSTIG module issues ---

# Verify all required modules are present
$required = (Get-Module PowerStig -ListAvailable | Select-Object -First 1).RequiredModules
foreach ($mod in $required) {
    $installed = Get-Module $mod.Name -ListAvailable
    [PSCustomObject]@{
        Module    = $mod.Name
        Required  = $mod.Version
        Installed = $installed.Version
        OK        = $installed.Version -ge $mod.Version
    }
} | Format-Table -AutoSize

# Re-import to refresh module cache
Remove-Module PowerStig -Force -ErrorAction SilentlyContinue
Import-Module PowerStig -Verbose

# --- Compilation errors ---
# If a configuration fails to compile, add -Verbose and check for:
#   1. Missing required module — run Install-Module for any missing dependency
#   2. Invalid StigVersion — verify against StigData\Processed directory
#   3. Invalid OsVersion — check file names in StigData\Processed\<Technology>

# Validate your OrgSettings XML against the default
$defaultOrg  = "$modulePath\StigData\Processed\WindowsServer\WindowsServer-2019-MS-2.5.org.default.xml"
$customOrg   = 'C:\DSC\OrgSettings\WindowsServer-2019-MS.xml'

[xml]$default = Get-Content $defaultOrg
[xml]$custom  = Get-Content $customOrg

$defaultIds = $default.OrganizationalSettings.OrganizationalSetting.id
$customIds  = $custom.OrganizationalSettings.OrganizationalSetting.id

# Find IDs in your custom file that don't exist in the default (typos, stale rules)
$customIds | Where-Object { $_ -notin $defaultIds }

# --- Test a single resource in isolation ---
Invoke-DscResource -Name WindowsServer -Method Test -ModuleName PowerStig -Property @{
    OsVersion   = '2019'
    OsRole      = 'MS'
    StigVersion = '2.5'
}

# --- LCM is stuck ---
Stop-DscConfiguration -Force
Remove-DscConfigurationDocument -Stage Pending
Start-DscConfiguration -Path 'C:\DSC\FullMemberServer' -Wait -Verbose -Force


# =============================================================================
# QUICK REFERENCE — COMMON WORKFLOWS
# =============================================================================

# 1. Find what STIGs are available
$mp = (Get-Module PowerStig -ListAvailable | Select-Object -First 1).ModuleBase
Get-ChildItem "$mp\StigData\Processed" -Directory

# 2. Copy and customize OrgSettings for your environment
Copy-Item "$mp\StigData\Processed\WindowsServer\WindowsServer-2019-MS-2.5.org.default.xml" `
          'C:\DSC\OrgSettings\WindowsServer-2019-MS.xml'

# 3. Write your Configuration (see sections above), then compile
MyConfig -OutputPath 'C:\DSC\Output'

# 4. Apply (push mode)
Start-DscConfiguration -Path 'C:\DSC\Output' -Wait -Verbose

# 5. Scan for compliance
$r = Test-DscConfiguration -Detailed
"Findings: $($r.ResourcesNotInDesiredState.Count)"
"Passing:  $($r.ResourcesInDesiredState.Count)"

# 6. Generate CKL for STIG Viewer
New-StigChecklist -ReferenceConfiguration 'C:\DSC\Output\localhost.mof' `
                  -DscResult $r `
                  -OutputPath 'C:\Reports\Scan.ckl'

# 7. Remediate and re-scan
Start-DscConfiguration -Path 'C:\DSC\Output' -Wait -Verbose -Force
Test-DscConfiguration -Detailed
