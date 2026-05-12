# =============================================================================
# POWERSHELL DSC CHEAT SHEET — Desired State Configuration
# =============================================================================
# DSC is a PowerShell management platform that lets you define the desired state
# of a system declaratively, then enforce or monitor that state automatically.
#
# Core flow:
#   1. Write a Configuration (PowerShell script block)
#   2. Compile it into a .mof file
#   3. Apply the .mof to a node via Push or Pull mode
#   4. LCM (Local Configuration Manager) enforces/monitors the state
# =============================================================================


# =============================================================================
# BASIC CONFIGURATION SYNTAX
# =============================================================================

# A Configuration is a special PowerShell function that compiles to a .mof file
# Node blocks define WHICH machines to configure
# Resource blocks define WHAT state the machine should be in

Configuration MyFirstConfig {

    # Import resource modules you'll use (best practice — avoids ambiguity)
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # Node block — applies to a specific machine
    Node "Server01" {

        # Each resource block: ResourceType "UniqueName" { properties }
        WindowsFeature InstallIIS {
            Name   = "Web-Server"
            Ensure = "Present"       # Present = install it, Absent = remove it
        }

        File CreateWebRoot {
            DestinationPath = "C:\inetpub\wwwroot\app"
            Type            = "Directory"
            Ensure          = "Present"
        }

        Service StartW3SVC {
            Name        = "W3SVC"
            State       = "Running"
            StartupType = "Automatic"
            DependsOn   = "[WindowsFeature]InstallIIS"   # run after IIS is installed
        }
    }
}

# Compile the configuration — creates a Server01.mof in .\MyFirstConfig\
MyFirstConfig -OutputPath "C:\DSC\MyFirstConfig"

# Apply the compiled .mof to the local machine
Start-DscConfiguration -Path "C:\DSC\MyFirstConfig" -Wait -Verbose

# Apply to a remote machine
Start-DscConfiguration -Path "C:\DSC\MyFirstConfig" -ComputerName Server01 -Wait -Verbose

# Flags:
#   -Wait     — block until configuration finishes (otherwise runs as background job)
#   -Verbose  — show each resource's progress
#   -Force    — apply even if LCM is already processing a configuration


# =============================================================================
# PARAMETERS & CONFIGURATION DATA (INLINE)
# =============================================================================

# Add parameters to make configurations reusable across environments
Configuration ParameterizedConfig {
    param (
        [string]$NodeName    = "localhost",
        [string]$SiteName    = "DefaultSite",
        [string]$AppPoolName = "DefaultAppPool"
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $NodeName {
        WindowsFeature IIS {
            Name   = "Web-Server"
            Ensure = "Present"
        }
    }
}

# Compile with parameters
ParameterizedConfig -NodeName "WebServer01" -SiteName "MySite" -OutputPath "C:\DSC\Out"


# =============================================================================
# CONFIGURATION DATA — SEPARATING CONFIG FROM DATA
# =============================================================================

# ConfigurationData is a hashtable that separates node data from the config logic
# AllNodes is required — each entry must have a NodeName key
# NodeName = "*" applies variables to ALL nodes

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = "*"           # defaults for all nodes
            PSDscAllowPlainTextPassword = $true         # DEV ONLY — never in production
            RetryCount                  = 3
        },
        @{
            NodeName    = "WebServer01"
            Role        = "WebServer"
            SiteName    = "ProdSite"
            AppPoolName = "ProdPool"
        },
        @{
            NodeName    = "WebServer02"
            Role        = "WebServer"
            SiteName    = "StagingSite"
            AppPoolName = "StagingPool"
        },
        @{
            NodeName = "DBServer01"
            Role     = "Database"
        }
    )
    # Non-node data — global settings accessible via $ConfigurationData.SiteData
    SiteData = @{
        AdminEmail = "ops@example.com"
        LogPath    = "C:\Logs"
    }
}

Configuration DataDrivenConfig {
    param ([hashtable]$ConfigurationData)

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # $AllNodes filters the AllNodes array — use .Where() or direct pipeline
    Node $AllNodes.Where({ $_.Role -eq "WebServer" }).NodeName {

        WindowsFeature IIS {
            Name   = "Web-Server"
            Ensure = "Present"
        }

        # Access per-node data via $Node
        File SiteRoot {
            DestinationPath = "C:\Sites\$($Node.SiteName)"
            Type            = "Directory"
            Ensure          = "Present"
        }
    }

    Node $AllNodes.Where({ $_.Role -eq "Database" }).NodeName {
        WindowsFeature SQLDependency {
            Name   = "NET-Framework-45-Core"
            Ensure = "Present"
        }
    }
}

# Compile — pass ConfigurationData, one .mof is created per NodeName entry
DataDrivenConfig -ConfigurationData $ConfigData -OutputPath "C:\DSC\DataDriven"


# =============================================================================
# LCM — LOCAL CONFIGURATION MANAGER
# =============================================================================

# The LCM is the DSC engine on every node — it applies and enforces configurations

# View current LCM settings
Get-DscLocalConfigurationManager

# Configure the LCM using a special meta-configuration
# Must use [DscLocalConfigurationManager()] attribute and compile like a normal config

[DscLocalConfigurationManager()]
Configuration ConfigureLCM {
    Node "localhost" {
        Settings {
            # How the LCM applies configuration
            ConfigurationMode              = "ApplyAndAutoCorrect"
            # ApplyOnly          — apply once, never check again
            # ApplyAndMonitor    — apply then report drift but don't fix it
            # ApplyAndAutoCorrect — apply, detect drift, and re-apply (default)

            # How often LCM checks for drift (minutes) — only with ApplyAndMonitor/AutoCorrect
            ConfigurationModeFrequencyMins = 30

            # How the LCM gets new configurations
            RefreshMode                    = "Push"
            # Push — admin pushes .mof to the node
            # Pull — node contacts a pull server to get its config

            # How often LCM contacts pull server (minutes)
            RefreshFrequencyMins           = 30

            # Reboot behavior
            RebootNodeIfNeeded             = $true

            # Action to take if node is in incorrect state on pull
            AllowModuleOverwrite           = $true

            DebugMode                      = "None"     # None / ForceModuleImport
        }
    }
}

# Compile and apply the meta-configuration
ConfigureLCM -OutputPath "C:\DSC\LCM"
Set-DscLocalConfigurationManager -Path "C:\DSC\LCM" -Verbose

# Apply meta-config to a remote machine
Set-DscLocalConfigurationManager -Path "C:\DSC\LCM" -ComputerName Server01 -Verbose


# =============================================================================
# PUSH MODE — APPLYING CONFIGURATIONS MANUALLY
# =============================================================================

# Push is the simplest model — admin compiles .mof and pushes it to nodes
# No pull server needed — good for ad-hoc or small environments

# Apply to local machine
Start-DscConfiguration -Path "C:\DSC\MyConfig" -Wait -Verbose

# Apply to one or more remote machines
Start-DscConfiguration -Path "C:\DSC\MyConfig" -ComputerName "Server01","Server02" -Wait -Verbose

# Apply using a CimSession (more control over connection)
$session = New-CimSession -ComputerName Server01 -Credential (Get-Credential)
Start-DscConfiguration -Path "C:\DSC\MyConfig" -CimSession $session -Wait -Verbose
Remove-CimSession $session


# =============================================================================
# PULL MODE — NODES PULL THEIR CONFIG FROM A SERVER
# =============================================================================

# In Pull mode nodes contact a pull server on a schedule to get their .mof
# Each node is identified by a ConfigurationID (GUID) or ConfigurationName
# Pull server can be HTTP (Web Pull) or SMB share

# --- Configure LCM for HTTP Pull (ConfigurationNames — v2 pull) ---
[DscLocalConfigurationManager()]
Configuration SetPullMode {
    Node "WebServer01" {
        Settings {
            RefreshMode          = "Pull"
            ConfigurationMode    = "ApplyAndAutoCorrect"
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded   = $true
        }

        ConfigurationRepositoryWeb PullServer {
            ServerURL          = "https://pull.example.com:8080/PSDSCPullServer.svc"
            RegistrationKey    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            ConfigurationNames = @("WebServerConfig")   # name of the .mof on pull server
            AllowUnsecureConnection = $false
        }

        # Optional: pull resource modules from the same server
        ResourceRepositoryWeb PullServerModules {
            ServerURL       = "https://pull.example.com:8080/PSDSCPullServer.svc"
            RegistrationKey = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        }

        # Optional: send compliance reports to a reporting server
        ReportServerWeb ReportServer {
            ServerURL       = "https://pull.example.com:8080/PSDSCPullServer.svc"
            RegistrationKey = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        }
    }
}

# --- Configure LCM for SMB Pull ---
[DscLocalConfigurationManager()]
Configuration SetSmbPullMode {
    Node "Server01" {
        Settings {
            RefreshMode = "Pull"
        }

        ConfigurationRepositoryShare SMBShare {
            SourcePath = "\\FileServer\DSCConfig"
        }

        ResourceRepositoryShare SMBModules {
            SourcePath = "\\FileServer\DSCModules"
        }
    }
}

# Force the LCM to check the pull server immediately (don't wait for next interval)
Update-DscConfiguration -Wait -Verbose
Update-DscConfiguration -ComputerName Server01 -Wait -Verbose


# =============================================================================
# TESTING & MONITORING CONFIGURATIONS
# =============================================================================

# Test whether the current state matches the desired state — returns $true or $false
Test-DscConfiguration                                   # test local machine
Test-DscConfiguration -ComputerName Server01            # test remote machine
Test-DscConfiguration -Path "C:\DSC\MyConfig"          # test against a specific .mof
Test-DscConfiguration -Detailed                         # show per-resource pass/fail detail

# Get the CURRENT actual state of the managed resources
Get-DscConfiguration                                    # local
Get-DscConfiguration -CimSession $session               # remote

# Get status of past configuration runs
Get-DscConfigurationStatus                              # most recent run
Get-DscConfigurationStatus -All                         # all recorded runs
# Status field: Success | Failure | Pending

# Restore the last-known-good configuration
Restore-DscConfiguration                                # local
Restore-DscConfiguration -ComputerName Server01

# Remove a pending configuration document
Remove-DscConfigurationDocument -Stage Pending          # clear pending config
Remove-DscConfigurationDocument -Stage Current          # clear current config
Remove-DscConfigurationDocument -Stage Previous         # clear previous config

# Stop an in-progress DSC configuration
Stop-DscConfiguration -Force


# =============================================================================
# DEPENDSON — RESOURCE ORDERING
# =============================================================================

# DependsOn forces a resource to wait for another to complete first
# Format: "[ResourceType]ResourceName"  — must match exactly

Configuration DependencyExample {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "localhost" {

        WindowsFeature InstallIIS {
            Name   = "Web-Server"
            Ensure = "Present"
        }

        WindowsFeature InstallAspNet {
            Name      = "Web-Asp-Net45"
            Ensure    = "Present"
            DependsOn = "[WindowsFeature]InstallIIS"    # wait for IIS first
        }

        File CreateConfig {
            DestinationPath = "C:\inetpub\wwwroot\web.config"
            Ensure          = "Present"
            Contents        = "<configuration/>"
            DependsOn       = @(
                "[WindowsFeature]InstallIIS",           # wait for multiple resources
                "[WindowsFeature]InstallAspNet"
            )
        }
    }
}


# =============================================================================
# BUILT-IN RESOURCE REFERENCE
# =============================================================================

# Use Get-DscResource to list available resources and their properties
Get-DscResource                                     # list all available resources
Get-DscResource -Module PSDesiredStateConfiguration # built-in resources only
Get-DscResource -Name File                          # details for a specific resource
Get-DscResource -Name File | Select -Expand Properties  # show all properties

# --- File ---
File CopyFile {
    SourcePath      = "\\share\source\app.config"   # required for Copy type
    DestinationPath = "C:\App\app.config"           # required always
    Ensure          = "Present"                     # Present | Absent
    Type            = "File"                        # File | Directory
    Contents        = "Hello World"                 # inline content (mutually exclusive with SourcePath)
    Checksum        = "SHA-256"                     # MD5 | SHA-1 | SHA-256 | ModifiedDate | CreatedDate
    MatchSource     = $true                         # re-copy if source changes
    Recurse         = $true                         # for directories
    Force           = $true                         # overwrite read-only files
    Credential      = $Cred                         # for UNC share access
    Attributes      = "Hidden","ReadOnly"
}

# --- Registry ---
Registry SetValue {
    Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\MyApp"  # full registry path
    ValueName = "Version"
    ValueData = "1.0.0"
    ValueType = "String"        # String | Binary | DWord | QWord | MultiString | ExpandString
    Ensure    = "Present"       # Present | Absent
    Force     = $true           # create parent keys if they don't exist
}

# --- Service ---
Service ConfigureService {
    Name        = "wuauserv"
    DisplayName = "Windows Update"              # optional — for new service creation
    State       = "Running"                     # Running | Stopped | Ignore
    StartupType = "Automatic"                   # Automatic | Manual | Disabled
    Ensure      = "Present"                     # Present | Absent (deletes service)
    Path        = "C:\App\myservice.exe"        # only needed when creating a new service
    Description = "My custom service"
    Credential  = $Cred                         # run-as credentials
    DependsOn   = "[File]CopyBinary"
}

# --- WindowsFeature ---
WindowsFeature InstallFeature {
    Name                 = "Web-Server"         # use Get-WindowsFeature to find names
    Ensure               = "Present"            # Present | Absent
    IncludeAllSubFeature = $true                # install all child features
    LogPath              = "C:\DSC\feature.log"
    Source               = "D:\sources\sxs"    # for offline installs (WIM/ISO source)
}

# --- WindowsOptionalFeature (workstations / client OS) ---
WindowsOptionalFeature EnableHyperV {
    Name   = "Microsoft-Hyper-V"
    Ensure = "Enable"           # Enable | Disable
    Source = "C:\sources\sxs"
}

# --- Package ---
Package InstallApp {
    Name      = "Notepad++"                     # display name in Add/Remove Programs
    Path      = "C:\Installers\npp.exe"         # path to installer
    ProductId = "{GUID}"                        # MSI product GUID (for MSI files)
    Arguments = "/S"                            # silent install arguments
    Ensure    = "Present"
    Credential = $Cred
    LogPath   = "C:\DSC\install.log"
    ReturnCode = @(0, 3010)                    # 3010 = success but needs reboot
}

# --- MsiPackage (more reliable than Package for .msi) ---
MsiPackage InstallMSI {
    ProductId  = "{GUID-FROM-MSI}"
    Path       = "C:\Installers\myapp.msi"
    Ensure     = "Present"
    Arguments  = "TRANSFORMS=transform.mst"
    LogPath    = "C:\DSC\msi.log"
}

# --- User ---
User CreateUser {
    UserName             = "svcMyApp"
    FullName             = "My App Service Account"
    Description          = "Service account for MyApp"
    Password             = $Cred                    # PSCredential — username is ignored
    Ensure               = "Present"                # Present | Absent
    Disabled             = $false
    PasswordNeverExpires = $true
    PasswordChangeRequired = $false
    PasswordChangeNotAllowed = $true
}

# --- Group ---
Group AddToAdmins {
    GroupName        = "Administrators"
    Ensure           = "Present"
    MembersToInclude = @("svcMyApp","DOMAIN\alice")  # add without removing others
    MembersToExclude = @("DOMAIN\bob")               # ensure these are NOT members
    # Members = @("user1","user2")                   # exact membership — removes unlisted
    Credential       = $DomainCred                   # to resolve domain accounts
}

# --- Environment ---
Environment SetEnvVar {
    Name   = "JAVA_HOME"
    Value  = "C:\Program Files\Java\jdk-17"
    Ensure = "Present"                  # Present | Absent
    Target = "Machine"                  # Machine | Process | Machine,Process (default: Machine)
    Path   = $false                     # set $true to treat as PATH-style append
}

# --- Environment PATH append ---
Environment AddToPath {
    Name   = "PATH"
    Value  = "C:\MyApp\bin"
    Ensure = "Present"
    Path   = $true                      # appends to existing PATH instead of replacing
}

# --- Script ---
# Use when no built-in resource exists — implement Get/Set/Test yourself
Script RunCustomScript {
    GetScript  = {
        @{ Result = (Get-Content "C:\App\version.txt" -ErrorAction SilentlyContinue) }
    }
    TestScript = {
        Test-Path "C:\App\version.txt"   # return $true if already in desired state
    }
    SetScript  = {
        "1.0.0" | Set-Content "C:\App\version.txt"  # make it so
    }
    Credential = $Cred
    DependsOn  = "[File]AppDir"
}

# --- Archive ---
Archive ExtractApp {
    Path        = "C:\Downloads\app.zip"    # source .zip file
    Destination = "C:\App"                  # where to extract
    Ensure      = "Present"                 # Present | Absent
    Force       = $true                     # overwrite existing files
    Validate    = $true                     # validate checksums after extract
    Checksum    = "SHA-256"
    Credential  = $Cred
}

# --- Log ---
Log WriteLog {
    Message = "DSC applied configuration at $(Get-Date)"  # writes to DSC event log
}


# =============================================================================
# CREDENTIALS IN DSC
# =============================================================================

# Credentials in .mof files are a security concern — several options:

# Option 1: Encrypt with a certificate (PRODUCTION — recommended)
# Each node has a cert; DSC encrypts the credential using the node's public key
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName              = "Server01"
            CertificateFile       = "C:\Certs\Server01.cer"    # public key (on authoring machine)
            Thumbprint            = "AAABBB..."                 # thumbprint on target node
        }
    )
}

Configuration SecureCredConfig {
    param ([PSCredential]$AdminCred)

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.NodeName {
        User CreateAdmin {
            UserName = "localadmin"
            Password = $AdminCred
            Ensure   = "Present"
        }
    }
}

SecureCredConfig -AdminCred (Get-Credential) -ConfigurationData $ConfigData -OutputPath "C:\DSC\Secure"

# Option 2: PSDscAllowPlainTextPassword (DEV/LAB ONLY — credentials in plaintext in .mof)
$LabConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = "localhost"
            PSDscAllowPlainTextPassword = $true     # NEVER use this in production
        }
    )
}

# Option 3: PsDscRunAsCredential — run a specific resource block as a different user
Configuration RunAsExample {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node "localhost" {
        Script RunAsUser {
            GetScript  = { @{} }
            TestScript = { $false }
            SetScript  = { Write-Host "Running as $env:USERNAME" }
            PsDscRunAsCredential = $using:Cred    # $using: scope for variables from outer scope
        }
    }
}


# =============================================================================
# CLASS-BASED RESOURCES (PowerShell 5.0+)
# =============================================================================

# Class-based resources are defined in a .psm1 module file
# They replace the older MOF schema approach — cleaner syntax, full IntelliSense

# Module file: MyModule\DSCResources\MyResource\MyResource.psm1

[DscResource()]                         # marks this class as a DSC resource
class MyFileResource {

    [DscProperty(Key)]                  # Key = uniquely identifies the instance
    [string] $Path

    [DscProperty(Mandatory)]            # Mandatory = required property
    [string] $Content

    [DscProperty()]                     # optional property
    [Ensure] $Ensure = [Ensure]::Present

    [DscProperty(NotConfigurable)]      # read-only — only returned by Get(), never set by user
    [string] $ActualContent

    # Get() — returns current state as an instance of this class
    [MyFileResource] Get() {
        $result = [MyFileResource]::new()
        $result.Path    = $this.Path
        if (Test-Path $this.Path) {
            $result.Ensure        = [Ensure]::Present
            $result.ActualContent = Get-Content $this.Path -Raw
        } else {
            $result.Ensure = [Ensure]::Absent
        }
        return $result
    }

    # Test() — returns $true if already in desired state, $false if Set() needs to run
    [bool] Test() {
        if ($this.Ensure -eq [Ensure]::Absent) {
            return -not (Test-Path $this.Path)
        }
        if (-not (Test-Path $this.Path)) { return $false }
        return (Get-Content $this.Path -Raw) -eq $this.Content
    }

    # Set() — enforces desired state
    [void] Set() {
        if ($this.Ensure -eq [Ensure]::Absent) {
            Remove-Item $this.Path -Force
        } else {
            $this.Content | Set-Content $this.Path -Force
        }
    }
}

# Use a class-based resource in a configuration exactly like a built-in resource
Configuration UseClassResource {
    Import-DscResource -ModuleName MyModule

    Node "localhost" {
        MyFileResource EnsureConfigFile {
            Path    = "C:\App\settings.txt"
            Content = "debug=false"
            Ensure  = "Present"
        }
    }
}


# =============================================================================
# COMPOSITE RESOURCES — REUSABLE RESOURCE BUNDLES
# =============================================================================

# Composite resources wrap a set of resources into a single reusable resource
# They are just a .psm1 + .psd1 inside a module's DSCResources folder
# Use them to avoid copy-pasting the same resource blocks across many configs

# Example composite resource: MyModule\DSCResources\WebServerSetup\WebServerSetup.schema.psm1

Configuration WebServerSetup {
    param (
        [Parameter(Mandatory)][string]$SiteName,
        [string]$Port = "80"
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    WindowsFeature IIS {
        Name   = "Web-Server"
        Ensure = "Present"
    }

    WindowsFeature ASPNET {
        Name      = "Web-Asp-Net45"
        Ensure    = "Present"
        DependsOn = "[WindowsFeature]IIS"
    }

    File SiteRoot {
        DestinationPath = "C:\Sites\$SiteName"
        Type            = "Directory"
        Ensure          = "Present"
        DependsOn       = "[WindowsFeature]IIS"
    }
}

# Use the composite resource in a parent configuration like any other resource
Configuration DeployWebApp {
    Import-DscResource -ModuleName MyModule     # module containing WebServerSetup

    Node "WebServer01" {
        WebServerSetup SetupIIS {
            SiteName = "MyApp"
            Port     = "8080"
        }
    }
}


# =============================================================================
# PARTIAL CONFIGURATIONS
# =============================================================================

# Partial configurations let multiple teams/sources contribute to one node's config
# Each partial config is applied independently and merged by the LCM

[DscLocalConfigurationManager()]
Configuration PartialLCMConfig {
    Node "Server01" {
        Settings {
            RefreshMode = "Pull"
        }

        PartialConfiguration OSBase {
            Description         = "Base OS configuration from infra team"
            ConfigurationSource = @("[ConfigurationRepositoryWeb]PullServer")
        }

        PartialConfiguration AppConfig {
            Description         = "Application config from app team"
            ConfigurationSource = @("[ConfigurationRepositoryWeb]PullServer")
            DependsOn           = "[PartialConfiguration]OSBase"   # apply after OSBase
        }
    }
}


# =============================================================================
# MANAGING DSC RESOURCES (MODULES)
# =============================================================================

# DSC resources are packaged as PowerShell modules
# PowerShellGet makes installing them easy

# Find DSC resources on PSGallery
Find-Module -Tag DSC                                # find all DSC modules
Find-DscResource -Name xWebAdministration           # find a specific resource
Find-DscResource -ModuleName PSDscResources         # find resources in a module

# Install DSC resource modules
Install-Module -Name PSDscResources -Force          # Microsoft's maintained resource pack
Install-Module -Name xWebAdministration             # IIS management
Install-Module -Name xNetworking                    # network config
Install-Module -Name SqlServerDsc                   # SQL Server config
Install-Module -Name ActiveDirectoryDsc             # AD management
Install-Module -Name StorageDsc                     # disk/volume management
Install-Module -Name ComputerManagementDsc          # OS-level settings

# List installed DSC resource modules
Get-DscResource | Select-Object -Property Name, Module, Version | Sort-Object Module

# Update a module
Update-Module -Name PSDscResources

# Resource module file locations:
# C:\Program Files\WindowsPowerShell\Modules\   — all users
# C:\Users\<user>\Documents\WindowsPowerShell\Modules\   — current user


# =============================================================================
# TROUBLESHOOTING & DIAGNOSTICS
# =============================================================================

# --- Check current and recent status ---
Get-DscConfigurationStatus                          # last run result
Get-DscConfigurationStatus -All                     # all recorded runs
# .Status:    Success / Failure / Pending
# .Mode:      Push / Pull
# .Resources: per-resource results

# --- Test for drift without applying ---
$result = Test-DscConfiguration -Detailed
$result.ResourcesNotInDesiredState                  # resources that are drifted
$result.ResourcesInDesiredState                     # resources already correct

# --- DSC event logs (Windows Event Viewer) ---
Get-WinEvent -LogName "Microsoft-Windows-Desired State Configuration-Operational" | Select-Object -First 20
Get-WinEvent -LogName "Microsoft-Windows-Desired State Configuration-Operational" |
    Where-Object { $_.LevelDisplayName -eq "Error" }

# DSC log files on disk
# C:\Windows\System32\Configuration\   — .mof files (Current, Pending, Previous)
# C:\Windows\System32\Configuration\ConfigurationStatus\   — DSCStatusHistory.json

# Decode a .mof file to read its contents
Get-Content "C:\Windows\System32\Configuration\Current.mof"

# --- Enable verbose DSC logging ---
$env:PSModulePath                                   # verify resource modules are on path
Start-DscConfiguration -Path "C:\DSC\Config" -Wait -Verbose -Debug

# --- Analytic and Debug event channels (disabled by default) ---
wevtutil set-log "Microsoft-Windows-Desired State Configuration-Analytic" /enabled:true
wevtutil set-log "Microsoft-Windows-Desired State Configuration-Debug"    /enabled:true

# --- LCM is stuck / locked ---
Stop-DscConfiguration -Force                        # break out of stuck configuration
Remove-DscConfigurationDocument -Stage Pending      # remove stuck pending config
Start-DscConfiguration -UseExisting -Wait -Verbose  # re-apply current config

# --- Verify resource module is found ---
Import-Module PSDesiredStateConfiguration
Get-DscResource -Name File                          # should return resource details

# --- Test a single resource manually (without a full config) ---
Invoke-DscResource -Name File -Method Test -Property @{
    DestinationPath = "C:\test.txt"
    Ensure          = "Present"
}

Invoke-DscResource -Name File -Method Set -Property @{
    DestinationPath = "C:\test.txt"
    Contents        = "hello"
    Ensure          = "Present"
}

Invoke-DscResource -Name File -Method Get -Property @{
    DestinationPath = "C:\test.txt"
}


# =============================================================================
# PULL SERVER SETUP (WINDOWS PULL SERVER)
# =============================================================================

# Pull server requires: Windows Server, IIS, DSC Service role
# For new environments prefer Azure Automation DSC or a configuration management
# tool (Ansible, Chef, Puppet) — Windows pull server is legacy

Install-Module xPSDesiredStateConfiguration -Force  # contains xDscWebService resource

Configuration PullServerSetup {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    Node "PullServer" {
        WindowsFeature DSCServiceFeature {
            Name   = "DSC-Service"
            Ensure = "Present"
        }

        xDscWebService PSDSCPullServer {
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbprint   = "AAABBB..."       # SSL cert thumbprint
            ModulePath              = "C:\DSCModules"   # where to store resource modules
            ConfigurationPath       = "C:\DSCConfig"    # where to store .mof files
            RegistrationKeyPath     = "C:\DSCReg"       # where registration keys live
            State                   = "Started"
            UseSecurityBestPractices = $true
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
        }
    }
}

# On the pull server — publish a configuration for nodes to pull
# File naming convention:  ConfigurationName.mof  (must match what LCM requests)
# Also needs a checksum:
New-DscChecksum -Path "C:\DSCConfig"                # creates ConfigurationName.mof.checksum

# Node registration key — nodes send this to register with the pull server
# Create a file: C:\DSCReg\RegistrationKeys.txt
# Contents: one GUID per line — each is a valid registration key


# =============================================================================
# AZURE AUTOMATION DSC (modern alternative to Windows Pull Server)
# =============================================================================

# Azure Automation DSC manages nodes from Azure — no pull server to maintain

# Onboard a machine to Azure Automation DSC
# From Azure Portal: Automation Account → DSC Nodes → Add Node

# Onboard via PowerShell (on the node being onboarded)
$AutomationParams = @{
    AutomationAccountName = "MyAutomationAccount"
    ResourceGroupName     = "MyResourceGroup"
    SubscriptionId        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    NodeConfigurationName = "WebServerConfig.WebServer01"  # ConfigName.NodeName
    ConfigurationMode     = "ApplyAndAutoCorrect"
    RebootNodeIfNeeded    = $true
}

# Upload a configuration to Azure Automation
Import-AzAutomationDscConfiguration `
    -AutomationAccountName "MyAutomationAccount" `
    -ResourceGroupName     "MyResourceGroup" `
    -SourcePath            "C:\DSC\WebServerConfig.ps1" `
    -Published

# Compile the configuration in Azure
Start-AzAutomationDscCompilationJob `
    -AutomationAccountName "MyAutomationAccount" `
    -ResourceGroupName     "MyResourceGroup" `
    -ConfigurationName     "WebServerConfig"

# Get node compliance status
Get-AzAutomationDscNode `
    -AutomationAccountName "MyAutomationAccount" `
    -ResourceGroupName     "MyResourceGroup"


# =============================================================================
# QUICK REFERENCE — MOST USED COMMANDS
# =============================================================================

# Compile a configuration to .mof
MyConfig -OutputPath "C:\DSC\MyConfig"

# Apply configuration (push)
Start-DscConfiguration -Path "C:\DSC\MyConfig" -Wait -Verbose
Start-DscConfiguration -Path "C:\DSC\MyConfig" -ComputerName Server01 -Wait -Verbose

# Test — is current state == desired state?
Test-DscConfiguration
Test-DscConfiguration -Detailed

# Get current state of managed resources
Get-DscConfiguration

# View LCM settings
Get-DscLocalConfigurationManager

# Apply LCM meta-configuration
Set-DscLocalConfigurationManager -Path "C:\DSC\LCM" -Verbose

# View status of last run
Get-DscConfigurationStatus

# Manually invoke a single resource (no config needed)
Invoke-DscResource -Name File -Method Test -Property @{ DestinationPath = "C:\test.txt"; Ensure = "Present" }

# Force pull from pull server now
Update-DscConfiguration -Wait -Verbose

# List all available DSC resources on this machine
Get-DscResource

# Find and install resource modules
Find-Module -Tag DSC
Install-Module PSDscResources -Force
