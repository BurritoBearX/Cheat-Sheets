# =============================================================================
# PESTER CHEAT SHEET — PowerShell Testing Framework
# =============================================================================
# Pester is the standard testing and mocking framework for PowerShell.
# Use it for: unit tests, integration tests, STIG compliance checks,
# infrastructure validation, and DSC configuration testing.
#
# This cheatsheet covers Pester v5 (current). v4 differences are noted where
# they matter — the biggest breaking changes were mock assertions and scoping.
#
# Source:  https://pester.dev
# Install: Install-Module Pester -Force -SkipPublisherCheck
# =============================================================================


# =============================================================================
# INSTALLATION & VERSION
# =============================================================================

# Install latest Pester (v5)
Install-Module -Name Pester -Force -SkipPublisherCheck
Install-Module -Name Pester -RequiredVersion 5.6.1 -Force -SkipPublisherCheck

# Windows ships with Pester v3 in-box — always install v5 from PSGallery
# -SkipPublisherCheck is required because the inbox version is Microsoft-signed

# Verify version
Get-Module -Name Pester -ListAvailable | Select-Object Name, Version
Import-Module Pester -MinimumVersion 5.0

# Update to latest
Update-Module -Name Pester


# =============================================================================
# TEST FILE CONVENTIONS
# =============================================================================

# Pester discovers test files automatically by naming convention:
#   *.Tests.ps1
#
# Typical project layout:
#
#   MyModule\
#     MyModule.psm1
#     MyModule.psd1
#     Tests\
#       MyModule.Tests.ps1         — unit tests for the module
#       Integration.Tests.ps1      — integration / end-to-end tests
#       Stig.Tests.ps1             — STIG compliance checks
#
# Each test file dot-sources or imports what it needs to test.
# Pester auto-discovers all *.Tests.ps1 files under a given path.


# =============================================================================
# BASIC STRUCTURE — DESCRIBE / CONTEXT / IT
# =============================================================================

# Describe  — top-level grouping, usually one per function or feature
# Context   — optional sub-grouping within a Describe (for different scenarios)
# It        — a single test case (assertion)

Describe 'Get-UserReport' {

    Context 'When the user exists' {

        It 'Returns a PSCustomObject' {
            $result = Get-UserReport -Username 'alice'
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Returns the correct username' {
            $result = Get-UserReport -Username 'alice'
            $result.Username | Should -Be 'alice'
        }
    }

    Context 'When the user does not exist' {

        It 'Returns null' {
            $result = Get-UserReport -Username 'nobody'
            $result | Should -BeNullOrEmpty
        }

        It 'Does not throw' {
            { Get-UserReport -Username 'nobody' } | Should -Not -Throw
        }
    }
}


# =============================================================================
# SETUP & TEARDOWN — BeforeAll / AfterAll / BeforeEach / AfterEach
# =============================================================================

# BeforeAll  — runs ONCE before all tests in the Describe/Context block
# AfterAll   — runs ONCE after  all tests in the Describe/Context block
# BeforeEach — runs before EACH It block in the Describe/Context block
# AfterEach  — runs after  EACH It block in the Describe/Context block

# IMPORTANT (v5 scoping rule):
#   Variables set in BeforeAll are available inside It blocks automatically.
#   Do NOT set variables in the Describe body outside BeforeAll — they are
#   evaluated during Discovery (before tests run) and will be $null at runtime.

Describe 'Invoke-Deployment' {

    BeforeAll {
        # Dot-source the script under test
        . "$PSScriptRoot\..\src\Deploy.ps1"

        # Shared test data available to all It blocks in this Describe
        $script:testServer  = 'TestServer01'
        $script:testPackage = 'C:\Packages\app.zip'
    }

    AfterAll {
        # Clean up anything created during the test suite
        Remove-Item 'C:\Temp\TestDeploy' -Recurse -Force -ErrorAction SilentlyContinue
    }

    BeforeEach {
        # Runs before every single It block — good for resetting state
        $script:deployResult = $null
    }

    AfterEach {
        # Runs after every It block — good for cleanup
        # (TestDrive is auto-cleaned, but custom resources need manual cleanup)
    }

    It 'Returns success when server is reachable' {
        Mock Test-Connection { return $true }
        $result = Invoke-Deployment -Server $script:testServer -Package $script:testPackage
        $result.Success | Should -BeTrue
    }

    It 'Returns failure when server is unreachable' {
        Mock Test-Connection { return $false }
        $result = Invoke-Deployment -Server $script:testServer -Package $script:testPackage
        $result.Success | Should -BeFalse
    }
}


# =============================================================================
# ASSERTIONS — Should
# =============================================================================

# --- Equality ---
$result | Should -Be           'expected'          # loose equality (like -eq)
$result | Should -BeExactly    'Expected'          # case-sensitive equality
$result | Should -Not -Be      'wrong'
$result | Should -BeNullOrEmpty                    # null or empty string/collection
$result | Should -Not -BeNullOrEmpty

# --- Booleans ---
$result | Should -BeTrue
$result | Should -BeFalse
$flag   | Should -Be $true
$flag   | Should -Be $false

# --- Type ---
$result | Should -BeOfType  [System.String]
$result | Should -BeOfType  'System.String'         # string form also works
$result | Should -BeOfType  [PSCustomObject]
$result | Should -Not -BeOfType [System.Int32]

# --- Numeric comparison ---
$count  | Should -BeGreaterThan        0
$count  | Should -BeGreaterOrEqual     1
$count  | Should -BeLessThan           100
$count  | Should -BeLessOrEqual        99
$value  | Should -BeIn @(1, 2, 3)      # value is a member of the set

# --- Strings ---
$str    | Should -BeLike        '*partial*'         # wildcard, case-insensitive
$str    | Should -BeLikeExactly '*Partial*'         # wildcard, case-sensitive
$str    | Should -Match         '^\d{4}-\d{2}-\d{2}$'  # regex match
$str    | Should -MatchExactly  'ExactString'       # case-sensitive regex
$str    | Should -Not -Match    'error'

# --- Collections ---
$array  | Should -Contain       'item'              # collection contains element
$array  | Should -Not -Contain  'missing'
$array  | Should -HaveCount     3                   # exact count
$array  | Should -Not -BeNullOrEmpty                # at least one element

# --- File system ---
'C:\Windows\System32' | Should -Exist               # path exists
'C:\NoSuchFile.txt'   | Should -Not -Exist

# --- Exceptions ---
{ Get-Item 'C:\NoSuchFile.txt' }      | Should -Throw                        # any exception
{ throw 'bad input' }                 | Should -Throw 'bad input'            # message match
{ throw 'bad input' }                 | Should -Throw -ExceptionType ([System.Exception])
{ 1/0 }                               | Should -Not -Throw                   # must NOT throw

# Capture the exception to inspect it
$err = { throw [System.IO.FileNotFoundException]'file missing' } |
       Should -Throw -PassThru
$err.Exception.GetType().Name | Should -Be 'FileNotFoundException'

# --- Parameters (function signature testing) ---
Get-Command 'Get-UserReport' | Should -HaveParameter 'Username'
Get-Command 'Get-UserReport' | Should -HaveParameter 'Username' -Mandatory
Get-Command 'Get-UserReport' | Should -HaveParameter 'Username' -Type [string]

# --- Custom failure message ---
$result | Should -Be 'expected' -Because 'the API contract requires this field'


# =============================================================================
# MOCKING
# =============================================================================

# Mock replaces a command for the duration of the Describe/Context block it's in.
# Use it to isolate the code under test from external systems.

Describe 'Send-Alert' {

    BeforeAll {
        . "$PSScriptRoot\..\src\Alerts.ps1"
    }

    It 'Calls Send-MailMessage when an alert fires' {

        # Replace Send-MailMessage with a no-op
        Mock Send-MailMessage {}

        Send-Alert -Message 'Disk full' -Severity 'High'

        # Verify the mock was called (v5 syntax)
        Should -Invoke Send-MailMessage -Times 1 -Exactly
    }

    It 'Passes the correct subject to Send-MailMessage' {

        Mock Send-MailMessage {}

        Send-Alert -Message 'Disk full' -Severity 'High'

        Should -Invoke Send-MailMessage -Times 1 -ParameterFilter {
            $Subject -like '*HIGH*' -and $Body -match 'Disk full'
        }
    }

    It 'Does not email for Low severity alerts' {

        Mock Send-MailMessage {}

        Send-Alert -Message 'Minor issue' -Severity 'Low'

        Should -Invoke Send-MailMessage -Times 0   # must NOT have been called
    }
}

# --- Mock with a return value ---
Mock Get-Service {
    return [PSCustomObject]@{ Name = 'FakeService'; Status = 'Running' }
}

# --- Mock with a scriptblock that uses the input parameters ---
Mock Get-Item {
    param($Path)
    return [PSCustomObject]@{ FullName = $Path; Exists = $true }
}

# --- Mock with ParameterFilter — only activates for specific arguments ---
Mock Get-Process { return $null }                           # default: return null for any call

Mock Get-Process {                                          # override for specific input
    return [PSCustomObject]@{ Name = 'nginx'; Id = 1234 }
} -ParameterFilter { $Name -eq 'nginx' }

# --- Verifiable mocks — must be called or the test fails ---
Mock Write-Log {} -Verifiable

Do-Something

Should -InvokeVerifiable    # fails if any -Verifiable mock was never called

# --- Mock a method on a .NET object ---
# Use a wrapper function around the method, then mock the wrapper

# --- Should -Invoke parameters ---
Should -Invoke Get-Process                          # called at least once
Should -Invoke Get-Process -Times 3                # called at least 3 times
Should -Invoke Get-Process -Times 3 -Exactly       # called EXACTLY 3 times
Should -Invoke Get-Process -Times 0                # never called
Should -Invoke Get-Process -Scope It               # scope: It | Context | Describe (default: It)

# v4 equivalents (for reference — prefer v5 syntax):
# Assert-MockCalled Get-Process -Times 1           # → Should -Invoke
# Assert-VerifiableMock                            # → Should -InvokeVerifiable


# =============================================================================
# MOCKING IN MODULES — InModuleScope
# =============================================================================

# When testing a module's private (unexported) functions, use InModuleScope.
# It runs code inside the module's scope so you can call private functions
# and mock commands the module uses internally.

Import-Module "$PSScriptRoot\..\MyModule\MyModule.psd1" -Force

Describe 'MyModule private functions' {

    InModuleScope MyModule {

        It 'Calls the private helper correctly' {

            # Mock a command as the module sees it
            Mock Invoke-RestMethod { return @{ status = 'ok' } }

            # Call a private function directly
            $result = Invoke-PrivateHelper -Endpoint '/api/data'

            $result.status | Should -Be 'ok'
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -match '/api/data'
            }
        }
    }
}


# =============================================================================
# TESTDRIVE — ISOLATED TEMPORARY FILE SYSTEM
# =============================================================================

# $TestDrive is a temporary directory unique to each test run.
# It is automatically cleaned up after the Describe block completes.
# Use it instead of hardcoded temp paths to keep tests isolated and clean.

Describe 'Export-Report' {

    BeforeAll {
        . "$PSScriptRoot\..\src\Reports.ps1"
    }

    It 'Creates a CSV file at the specified path' {
        $outputFile = Join-Path $TestDrive 'report.csv'

        Export-Report -Data @('row1','row2') -OutputPath $outputFile

        $outputFile     | Should -Exist
        $outputFile     | Should -Not -BeNullOrEmpty

        $content = Import-Csv $outputFile
        $content.Count  | Should -BeGreaterThan 0
    }

    It 'Overwrites an existing file' {
        $outputFile = Join-Path $TestDrive 'existing.csv'
        'old content'  | Set-Content $outputFile   # pre-existing file

        Export-Report -Data @('new') -OutputPath $outputFile

        $content = Get-Content $outputFile
        $content | Should -Not -Match 'old content'
    }
}

# $TestDrive path example: C:\Users\<user>\AppData\Local\Temp\...\Pester\<guid>
# Use Join-Path $TestDrive 'filename' — never hardcode paths inside tests


# =============================================================================
# TESTREGISTRY — ISOLATED REGISTRY HIVE
# =============================================================================

# $TestRegistry provides an isolated, temporary registry key.
# Cleaned up automatically after the test. Prevents tests from modifying real keys.

Describe 'Set-AppRegistryValue' {

    It 'Creates the expected registry value' {
        $regPath = Join-Path $TestRegistry 'MyApp'

        Set-AppRegistryValue -Path $regPath -Name 'Version' -Value '1.0.0'

        $value = Get-ItemPropertyValue -Path $regPath -Name 'Version'
        $value | Should -Be '1.0.0'
    }
}

# $TestRegistry base path: HKCU:\Software\Pester\<guid>


# =============================================================================
# DATA-DRIVEN TESTS — ForEach
# =============================================================================

# Run the same test logic against multiple inputs using -ForEach
# Available on Describe, Context, and It blocks

Describe 'Validate-IpAddress' -ForEach @(
    @{ IP = '192.168.1.1';    Valid = $true  }
    @{ IP = '10.0.0.1';      Valid = $true  }
    @{ IP = '999.999.999.1'; Valid = $false }
    @{ IP = 'not-an-ip';     Valid = $false }
) {
    It "Returns $Valid for IP <IP>" {
        Validate-IpAddress -Address $IP | Should -Be $Valid
    }
}

# ForEach on It — multiple cases within one Describe
Describe 'Get-StatusCode' {

    BeforeAll {
        . "$PSScriptRoot\..\src\Http.ps1"
    }

    It 'Returns HTTP <Code> for <Scenario>' -ForEach @(
        @{ Code = 200; Scenario = 'success';     Input = 'valid'   }
        @{ Code = 400; Scenario = 'bad request'; Input = 'invalid' }
        @{ Code = 404; Scenario = 'not found';   Input = 'missing' }
    ) {
        $result = Get-StatusCode -Input $Input
        $result | Should -Be $Code
    }
}


# =============================================================================
# TAGS — FILTERING TEST RUNS
# =============================================================================

# Tag tests to run specific subsets (unit vs integration, fast vs slow, by feature)

Describe 'Database Operations' -Tag 'Integration', 'Database' {

    It 'Connects to SQL Server' -Tag 'Slow' {
        { Connect-SqlServer -Server 'db01' } | Should -Not -Throw
    }

    It 'Returns records' -Tag 'Fast' {
        $records = Get-Records -Table 'Users'
        $records | Should -Not -BeNullOrEmpty
    }
}

Describe 'String Utilities' -Tag 'Unit', 'Fast' {

    It 'Trims whitespace' {
        '  hello  '.Trim() | Should -Be 'hello'
    }
}

# Run only tagged tests (see Invoke-Pester section)


# =============================================================================
# RUNNING TESTS — Invoke-Pester
# =============================================================================

# Run all tests in the current directory recursively
Invoke-Pester

# Run tests in a specific path
Invoke-Pester -Path 'C:\MyProject\Tests'
Invoke-Pester -Path 'C:\MyProject\Tests\MyModule.Tests.ps1'

# Verbosity levels: None | Minimal | Normal | Detailed | Diagnostic
Invoke-Pester -Output Detailed
Invoke-Pester -Output Diagnostic    # most verbose — useful for debugging mocks

# Filter by test name (supports wildcards)
Invoke-Pester -FullNameFilter '*Get-UserReport*'

# Filter by tag
Invoke-Pester -TagFilter 'Unit'
Invoke-Pester -TagFilter 'Unit', 'Fast'    # AND — must have both tags
Invoke-Pester -ExcludeTagFilter 'Slow', 'Integration'

# Capture test results as an object
$result = Invoke-Pester -PassThru
$result.TotalCount
$result.PassedCount
$result.FailedCount
$result.SkippedCount
$result.Duration
$result.Failed                                          # detailed list of failures

# Exit with non-zero code on failure (useful in CI/CD)
Invoke-Pester -Path . -OutputFormat NUnitXml -OutputFile 'TestResults.xml'
exit $result.FailedCount


# =============================================================================
# PESTER CONFIGURATION OBJECT (v5) — New-PesterConfiguration
# =============================================================================

# The configuration object is the preferred way to run Pester — more options,
# easier to version-control than long Invoke-Pester argument lists

$config = New-PesterConfiguration

# --- Run settings ---
$config.Run.Path        = @('./Tests', './Integration')  # one or more paths
$config.Run.PassThru    = $true                           # return result object
$config.Run.Exit        = $true                           # exit(1) on failure

# --- Output settings ---
$config.Output.Verbosity = 'Detailed'                     # None|Minimal|Normal|Detailed|Diagnostic

# --- Filter settings ---
$config.Filter.Tag          = @('Unit')
$config.Filter.ExcludeTag   = @('Slow')
$config.Filter.FullName     = @('*Get-UserReport*')

# --- Code coverage ---
$config.CodeCoverage.Enabled          = $true
$config.CodeCoverage.Path             = @('./src/*.ps1', './src/*.psm1')
$config.CodeCoverage.OutputPath       = './Coverage/coverage.xml'
$config.CodeCoverage.OutputFormat     = 'JaCoCo'          # JaCoCo | CoverageGutters
$config.CodeCoverage.CoveragePercentTarget = 80           # fail if below this %

# --- Test result output (JUnit / NUnit XML for CI systems) ---
$config.TestResult.Enabled      = $true
$config.TestResult.OutputPath   = './TestResults/results.xml'
$config.TestResult.OutputFormat = 'NUnitXml'              # NUnitXml | NUnit2.5 | JUnitXml

# --- Should settings ---
$config.Should.ErrorAction = 'Stop'                       # Stop = first failure stops the It block

# Run with the configuration
$result = Invoke-Pester -Configuration $config

# Store config in a hashtable for easy reuse
$pesterParams = @{
    Path             = './Tests'
    Output           = 'Detailed'
    PassThru         = $true
    TagFilter        = @('Unit')
    ExcludeTagFilter = @('Slow')
}
$result = Invoke-Pester @pesterParams


# =============================================================================
# CODE COVERAGE
# =============================================================================

# Measure which lines of your source code are executed during tests

$config = New-PesterConfiguration
$config.Run.Path                           = './Tests'
$config.CodeCoverage.Enabled              = $true
$config.CodeCoverage.Path                 = './src'       # measure coverage of these files
$config.CodeCoverage.OutputPath           = './coverage.xml'
$config.CodeCoverage.OutputFormat         = 'JaCoCo'
$config.CodeCoverage.CoveragePercentTarget = 70           # minimum % before test run fails

$result = Invoke-Pester -Configuration $config

# View results
$result.CodeCoverage.CoveragePercent
$result.CodeCoverage.CommandsMissedCount
$result.CodeCoverage.CommandsExecutedCount

# Lines NOT covered — the gaps to write tests for
$result.CodeCoverage.MissedCommands |
    Select-Object File, Line, Command |
    Format-Table -AutoSize


# =============================================================================
# TESTING POWERSHELL FUNCTIONS & MODULES
# =============================================================================

# Pattern: dot-source the script or import the module in BeforeAll,
# then call the functions directly in It blocks.

# --- Testing a script file ---
Describe 'Deploy.ps1' {

    BeforeAll {
        # Dot-source so all functions in the script are available
        . "$PSScriptRoot\..\src\Deploy.ps1"
    }

    It 'Expand-ArchivePath returns the correct path' {
        $result = Expand-ArchivePath -Source 'C:\pkg\app.zip' -Destination 'C:\deploy'
        $result | Should -Be 'C:\deploy\app'
    }
}

# --- Testing a module ---
Describe 'MyModule' {

    BeforeAll {
        # Force re-import to pick up latest changes
        Remove-Module MyModule -Force -ErrorAction SilentlyContinue
        Import-Module "$PSScriptRoot\..\MyModule\MyModule.psd1" -Force
    }

    AfterAll {
        Remove-Module MyModule -Force -ErrorAction SilentlyContinue
    }

    It 'Exports the expected public functions' {
        $exported = (Get-Module MyModule).ExportedFunctions.Keys
        $exported | Should -Contain 'Get-UserReport'
        $exported | Should -Contain 'Send-Alert'
    }

    It 'Module manifest is valid' {
        { Test-ModuleManifest "$PSScriptRoot\..\MyModule\MyModule.psd1" } |
            Should -Not -Throw
    }
}

# --- Testing function parameters ---
Describe 'Get-UserReport parameter validation' {

    BeforeAll { . "$PSScriptRoot\..\src\Reports.ps1" }

    It 'Has a mandatory Username parameter' {
        Get-Command Get-UserReport |
            Should -HaveParameter 'Username' -Mandatory
    }

    It 'Has an optional Verbose switch' {
        Get-Command Get-UserReport |
            Should -HaveParameter 'Verbose'
    }

    It 'Throws on empty Username' {
        { Get-UserReport -Username '' } | Should -Throw
    }
}


# =============================================================================
# TESTING DSC CONFIGURATIONS
# =============================================================================

# Test that DSC configurations compile and contain expected resources

Describe 'WindowsServerStigConfig DSC configuration' {

    BeforeAll {
        . "$PSScriptRoot\..\DSC\WindowsServerStigConfig.ps1"

        # Compile the configuration to a temp directory
        $mofPath = Join-Path $TestDrive 'DSCOutput'
        WindowsServerStigConfig -OutputPath $mofPath -NodeName 'TestNode'
    }

    It 'Compiles without errors' {
        $mofPath | Should -Exist
    }

    It 'Generates a MOF file for the target node' {
        Join-Path $mofPath 'TestNode.mof' | Should -Exist
    }

    It 'MOF file is not empty' {
        $mof = Get-Item (Join-Path $mofPath 'TestNode.mof')
        $mof.Length | Should -BeGreaterThan 0
    }

    It 'MOF references the WindowsServer DSC resource' {
        $mofContent = Get-Content (Join-Path $mofPath 'TestNode.mof') -Raw
        $mofContent | Should -Match 'WindowsServer'
    }
}


# =============================================================================
# TESTING STIG COMPLIANCE WITH PESTER
# =============================================================================

# Use Pester as a compliance scanner — run it against live systems instead of
# relying solely on Test-DscConfiguration. Gives granular, readable output.

Describe 'Windows Server STIG Compliance' -Tag 'STIG', 'Compliance' {

    # Password policy checks (STIG rule examples)
    Context 'Password Policy' {

        It 'V-93147 — Minimum password length must be 14 or greater' {
            $policy = Get-LocalUser | Where-Object Enabled |
                ForEach-Object { net accounts } |
                Select-String 'Minimum password length'
            $minLength = ([regex]::Match($policy, '\d+')).Value -as [int]
            $minLength | Should -BeGreaterOrEqual 14
        }

        It 'V-93217 — Account lockout threshold must be 3 or fewer attempts' {
            $threshold = (net accounts | Select-String 'Lockout threshold').ToString() -replace '\D'
            [int]$threshold | Should -BeLessOrEqual 3
        }
    }

    Context 'Audit Policy' {

        It 'V-93339 — Account Logon auditing must be enabled for Success' {
            $auditResult = auditpol /get /subcategory:"Credential Validation"
            $auditResult | Should -Match 'Success'
        }

        It 'V-93341 — Account Logon auditing must be enabled for Failure' {
            $auditResult = auditpol /get /subcategory:"Credential Validation"
            $auditResult | Should -Match 'Failure'
        }
    }

    Context 'Services' {

        It 'V-93515 — Telnet Client must not be installed' {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient -ErrorAction SilentlyContinue
            $feature.State | Should -Not -Be 'Enabled'
        }

        It 'V-93519 — TFTP Client must not be installed' {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName TFTP -ErrorAction SilentlyContinue
            $feature.State | Should -Not -Be 'Enabled'
        }
    }

    Context 'Registry Settings' {

        It 'V-93205 — SMBv1 must be disabled' {
            $val = Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol
            $val | Should -BeFalse
        }

        It 'V-93499 — WDigest authentication must be disabled' {
            $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest'
            $val  = Get-ItemPropertyValue -Path $path -Name 'UseLogonCredential' -ErrorAction SilentlyContinue
            $val  | Should -Be 0
        }
    }

    Context 'Windows Firewall' {

        It 'V-93459 — Domain firewall profile must be enabled' {
            $fw = Get-NetFirewallProfile -Profile Domain
            $fw.Enabled | Should -BeTrue
        }

        It 'V-93463 — Public firewall profile must be enabled' {
            $fw = Get-NetFirewallProfile -Profile Public
            $fw.Enabled | Should -BeTrue
        }
    }
}


# =============================================================================
# CI/CD INTEGRATION
# =============================================================================

# --- Azure DevOps / GitHub Actions pattern ---
# Generate NUnit/JUnit XML for the pipeline to parse test results

$config = New-PesterConfiguration

$config.Run.Path              = './Tests'
$config.Run.Exit              = $true          # exit code 1 if any test fails
$config.Output.Verbosity      = 'Normal'

$config.TestResult.Enabled    = $true
$config.TestResult.OutputPath = './TestResults/Pester-Results.xml'
$config.TestResult.OutputFormat = 'NUnitXml'  # Azure DevOps understands NUnitXml

$config.CodeCoverage.Enabled  = $true
$config.CodeCoverage.Path     = './src'
$config.CodeCoverage.OutputPath = './TestResults/Coverage.xml'

Invoke-Pester -Configuration $config

# Azure DevOps pipeline YAML snippet:
# - task: PublishTestResults@2
#   inputs:
#     testResultsFormat: NUnit
#     testResultsFiles: '**/TestResults/Pester-Results.xml'
#
# - task: PublishCodeCoverageResults@1
#   inputs:
#     codeCoverageTool: JaCoCo
#     summaryFileLocation: '**/TestResults/Coverage.xml'

# GitHub Actions example step:
# - name: Run Pester Tests
#   shell: pwsh
#   run: |
#     Install-Module Pester -Force -SkipPublisherCheck
#     $config = New-PesterConfiguration
#     $config.Run.Path              = './Tests'
#     $config.Run.Exit              = $true
#     $config.TestResult.Enabled    = $true
#     $config.TestResult.OutputPath = 'TestResults.xml'
#     $config.TestResult.OutputFormat = 'JUnitXml'
#     Invoke-Pester -Configuration $config


# =============================================================================
# SKIPPING TESTS
# =============================================================================

# Skip a single test
It 'Feature not yet implemented' -Skip {
    Get-NewFeature | Should -Not -BeNullOrEmpty
}

# Skip conditionally (e.g. only runs on domain-joined machines)
It 'Queries Active Directory' -Skip:(-not (Get-WmiObject Win32_ComputerSystem).PartOfDomain) {
    Get-ADUser -Filter * | Should -Not -BeNullOrEmpty
}

# Skip an entire Describe block
Describe 'IIS Tests' -Skip:(-not (Get-Service W3SVC -ErrorAction SilentlyContinue)) {
    It 'IIS is running' {
        (Get-Service W3SVC).Status | Should -Be 'Running'
    }
}

# Mark as pending (same as skip but signals work in progress)
It 'Needs implementation' -Pending {
    $true | Should -Be $true
}


# =============================================================================
# DEBUGGING FAILING TESTS
# =============================================================================

# Run with Diagnostic output to see everything
Invoke-Pester -Output Diagnostic

# Run a single test file in verbose mode
Invoke-Pester -Path './Tests/MyModule.Tests.ps1' -Output Detailed

# Run just one specific test by name
Invoke-Pester -FullNameFilter 'Get-UserReport*Returns the correct username'

# Check why a mock wasn't called
Invoke-Pester -Output Diagnostic    # shows all mock invocation attempts

# Inspect the result object for failure details
$result = Invoke-Pester -PassThru -Output None
$result.Failed | ForEach-Object {
    Write-Host "FAILED: $($_.Name)" -ForegroundColor Red
    Write-Host "  $($_.ErrorRecord.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  $($_.ErrorRecord.ScriptStackTrace)" -ForegroundColor Gray
}

# Common v5 gotcha: variable defined in Describe body is null in It blocks
# WRONG:
Describe 'Bad scoping example' {
    $shared = 'value'                 # evaluated during Discovery — not available at Run time
    It 'Uses shared variable' {
        $shared | Should -Be 'value'  # $shared is $null here — test fails
    }
}

# RIGHT:
Describe 'Correct scoping example' {
    BeforeAll {
        $script:shared = 'value'      # set in BeforeAll, available in It blocks
    }
    It 'Uses shared variable' {
        $script:shared | Should -Be 'value'   # works correctly
    }
}


# =============================================================================
# QUICK REFERENCE — ASSERTION CHEAT CARD
# =============================================================================

# Value assertions
#   Should -Be                  loose equality (case-insensitive for strings)
#   Should -BeExactly           case-sensitive equality
#   Should -BeNullOrEmpty       null, empty string, or empty collection
#   Should -BeTrue / -BeFalse   boolean
#   Should -BeOfType [T]        type check

# Numeric
#   Should -BeGreaterThan       >
#   Should -BeGreaterOrEqual    >=
#   Should -BeLessThan          <
#   Should -BeLessOrEqual       <=
#   Should -BeIn @(...)         value is in set

# String
#   Should -BeLike  '*glob*'    wildcard, case-insensitive
#   Should -Match   'regex'     regex match

# Collection
#   Should -Contain  'item'     item is in collection
#   Should -HaveCount N         collection has exactly N items

# File
#   Should -Exist               path exists on disk

# Exception
#   Should -Throw               block throws any error
#   Should -Throw 'message'     block throws matching message
#   Should -Not -Throw          block must not throw

# Mock
#   Should -Invoke CmdName -Times N -Exactly
#   Should -Invoke CmdName -ParameterFilter { $Param -eq 'value' }
#   Should -InvokeVerifiable    all -Verifiable mocks were called

# Negate any assertion with -Not:
#   Should -Not -Be 'wrong'
#   Should -Not -Contain 'item'
#   Should -Not -Invoke Write-Error
