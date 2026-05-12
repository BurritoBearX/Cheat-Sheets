# =============================================================================
# POWERSHELL CHEAT SHEET — Beginner Reference
# =============================================================================


# =============================================================================
# VARIABLES
# =============================================================================

# Variables start with $ — PowerShell infers the type
$name     = "Alice"
$age      = 25
$height   = 5.7
$isAdmin  = $true       # booleans are $true and $false (not True/False)
$nothing  = $null       # absence of value (not None)

# Check the type of a variable
$name.GetType()                 # IsPublic Name      BaseType
                                # True     String    System.Object

# Explicitly declare a type by putting it in brackets before the variable
[int]$count    = 10
[string]$label = "hello"
[bool]$flag    = $false

# Constants — cannot be changed after declaration
Set-Variable -Name PI -Value 3.14159 -Option Constant


# =============================================================================
# STRINGS
# =============================================================================

# Double quotes — variables and escape sequences are expanded
$user = "Alice"
"Hello, $user!"                 # Hello, Alice!

# Single quotes — everything is treated as a literal (no expansion)
'Hello, $user!'                 # Hello, $user!

# Embed an expression inside a string using $()
"Two plus two is $(2 + 2)"      # Two plus two is 4

# Here-string — multi-line string, closing marker must be at column 0
$block = @"
Name: $user
Age:  $age
"@

# Literal here-string — no variable expansion
$literal = @'
This is $user literally.
'@

# Common string methods (strings are .NET objects)
"hello".ToUpper()               # HELLO
"HELLO".ToLower()               # hello
"  hi  ".Trim()                 # hi
"hello world".Replace("world", "PS")    # hello PS
"hello".Length                  # 5
"a,b,c".Split(",")              # array: a  b  c
"hello".Contains("ell")         # True
"hello".StartsWith("he")        # True
"hello".Substring(1, 3)         # ell  — start index, length

# String formatting with -f operator (like printf)
"Name: {0}, Age: {1}" -f "Alice", 25    # Name: Alice, Age: 25
"{0:N2}" -f 3.14159                      # 3.14  — 2 decimal places


# =============================================================================
# NUMBERS & MATH
# =============================================================================

# Basic arithmetic
10 + 3          # 13
10 - 3          # 7
10 * 3          # 30
10 / 3          # 3.33333...
10 % 3          # 1    modulo (remainder)
[Math]::Pow(2, 8)       # 256  exponentiation
[Math]::Sqrt(16)        # 4
[Math]::Round(3.567, 2) # 3.57
[Math]::Abs(-5)         # 5

# Augmented assignment
$n = 10
$n += 5         # 15
$n -= 3         # 12
$n++            # 13
$n--            # 12

# Convert strings to numbers
[int]"42"               # 42
[double]"3.14"          # 3.14


# =============================================================================
# ARRAYS
# =============================================================================

# Create an array with @()
$fruits = @("apple", "banana", "cherry")

# Access by index (zero-based)
$fruits[0]              # apple
$fruits[-1]             # cherry — last item

# Add an item — creates a new array (arrays are fixed size in PS)
$fruits += "grape"

# Array length
$fruits.Count           # 4
$fruits.Length          # 4

# Check membership
$fruits -contains "banana"      # True
"banana" -in $fruits            # True

# Slice a range
$fruits[0..1]           # apple, banana
$fruits[1..3]           # banana, cherry, grape

# Loop through an array
foreach ($fruit in $fruits) {
    Write-Host $fruit
}

# Sort, filter, select
$fruits | Sort-Object                           # alphabetical
$fruits | Sort-Object -Descending
$fruits | Where-Object { $_.Length -gt 5 }     # items longer than 5 chars
$fruits | Select-Object -First 2                # first 2 items
$fruits | Select-Object -Last 1                 # last item

# Measure array items
$fruits | Measure-Object | Select-Object Count  # Count: 4

# Empty array
$empty = @()

# Strongly typed array — only accepts integers
[int[]]$numbers = 1, 2, 3, 4, 5


# =============================================================================
# HASH TABLES  (equivalent to dictionaries)
# =============================================================================

# Create a hash table with @{}
$person = @{
    Name  = "Alice"
    Age   = 25
    City  = "NYC"
}

# Access a value
$person["Name"]         # Alice
$person.Name            # Alice — dot notation also works

# Add or update a key
$person["Email"] = "alice@example.com"
$person.Age = 26

# Remove a key
$person.Remove("City")

# Check if a key exists
$person.ContainsKey("Name")     # True

# Loop through keys and values
foreach ($key in $person.Keys) {
    Write-Host "$key : $($person[$key])"
}

# Ordered hash table — preserves insertion order
$ordered = [ordered]@{
    First  = 1
    Second = 2
    Third  = 3
}


# =============================================================================
# CONDITIONALS
# =============================================================================

$score = 85

# Basic if / elseif / else
if ($score -ge 90) {
    Write-Host "A"
} elseif ($score -ge 80) {
    Write-Host "B"
} elseif ($score -ge 70) {
    Write-Host "C"
} else {
    Write-Host "F"
}

# Comparison operators — PowerShell uses word-based operators, not symbols
# -eq    equal to
# -ne    not equal to
# -gt    greater than
# -lt    less than
# -ge    greater than or equal
# -le    less than or equal
# -like  wildcard match        "hello" -like "hel*"   → True
# -notlike
# -match regex match           "hello" -match "^hel"  → True
# -notmatch
# -contains  array contains value
# -in        value in array

# Logical operators
$age = 20
$hasId = $true

if ($age -ge 18 -and $hasId) {
    Write-Host "Allowed"
}

if ($age -lt 13 -or $age -gt 65) {
    Write-Host "Discount"
}

if (-not $hasId) {
    Write-Host "No ID"
}

# Switch statement — cleaner than many elseif chains
$day = "Monday"
switch ($day) {
    "Monday"    { Write-Host "Start of week" }
    "Friday"    { Write-Host "End of week" }
    "Saturday"  { Write-Host "Weekend" }
    "Sunday"    { Write-Host "Weekend" }
    default     { Write-Host "Midweek" }
}

# Switch with -Wildcard or -Regex
switch -Wildcard ($name) {
    "A*" { Write-Host "Starts with A" }
    "B*" { Write-Host "Starts with B" }
}


# =============================================================================
# LOOPS
# =============================================================================

# for — classic counter loop
for ($i = 0; $i -lt 5; $i++) {
    Write-Host $i          # 0 1 2 3 4
}

# foreach — iterate over a collection
foreach ($item in @("a", "b", "c")) {
    Write-Host $item
}

# while — repeat while condition is true
$count = 0
while ($count -lt 5) {
    Write-Host $count
    $count++
}

# do/while — always runs at least once
$count = 0
do {
    Write-Host $count
    $count++
} while ($count -lt 5)

# do/until — runs until condition becomes true
$count = 0
do {
    Write-Host $count
    $count++
} until ($count -ge 5)

# ForEach-Object — pipeline loop (use $_ for current item)
1..5 | ForEach-Object { Write-Host ($_ * 2) }      # 2 4 6 8 10

# break — exit the loop early
foreach ($n in 1..10) {
    if ($n -eq 5) { break }
    Write-Host $n
}

# continue — skip the rest of this iteration
foreach ($n in 1..10) {
    if ($n % 2 -eq 0) { continue }     # skip even numbers
    Write-Host $n
}

# Range operator .. generates a sequence of integers
1..10                   # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
10..1                   # 10, 9, 8, ... 1 (reverse)


# =============================================================================
# FUNCTIONS
# =============================================================================

# Define a function with function keyword
function Say-Hello {
    Write-Host "Hello!"
}

# Call it — no parentheses around arguments in PowerShell
Say-Hello

# Function with parameters
function Greet {
    param($Name)
    Write-Host "Hello, $Name!"
}

Greet -Name "Alice"     # Hello, Alice!
Greet "Alice"           # also works (positional)

# Typed parameters with defaults
function Add-Numbers {
    param(
        [int]$A = 0,
        [int]$B = 0
    )
    return $A + $B
}

Add-Numbers -A 3 -B 4   # 7
Add-Numbers 3 4          # 7

# Mandatory parameters — PowerShell prompts the user if not provided
function Get-Info {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username
    )
    Write-Host "User: $Username"
}

# Switch parameter — acts as a boolean flag
function Deploy {
    param(
        [string]$Environment,
        [switch]$Verbose
    )
    if ($Verbose) { Write-Host "Verbose mode on" }
    Write-Host "Deploying to $Environment"
}

Deploy -Environment "prod" -Verbose

# Return a value
function Get-Square {
    param([int]$N)
    return $N * $N
}

$result = Get-Square 5      # 25

# NOTE: In PowerShell, any uncaptured output is automatically returned.
# Use return explicitly for clarity, but it's not always required.


# =============================================================================
# THE PIPELINE
# =============================================================================

# The pipe | passes output from one command as input to the next
# $_ represents the current object in the pipeline

# Get all running processes, filter to those using > 100MB RAM, sort by name
Get-Process | Where-Object { $_.WorkingSet -gt 100MB } | Sort-Object Name

# Select specific properties
Get-Process | Select-Object Name, Id, CPU

# Get only unique values
@(1, 2, 2, 3, 3) | Sort-Object -Unique      # 1 2 3

# Count items coming through the pipeline
Get-ChildItem | Measure-Object | Select-Object Count

# Group items by a property
Get-Process | Group-Object -Property Company

# Pass pipeline input into a function using ValueFromPipeline
function Show-Item {
    param(
        [Parameter(ValueFromPipeline=$true)]
        $Item
    )
    process {
        Write-Host "Item: $Item"
    }
}

@("a", "b", "c") | Show-Item


# =============================================================================
# INPUT & OUTPUT
# =============================================================================

# Print to the console
Write-Host "Hello, World!"
Write-Host "Name: $name" -ForegroundColor Green
Write-Host "Error!" -ForegroundColor Red -BackgroundColor Black

# Write to the pipeline (preferred in scripts — doesn't format output)
Write-Output "Hello"

# Prompt the user for input
$input = Read-Host "Enter your name"
$secure = Read-Host "Enter password" -AsSecureString

# Write to different output streams
Write-Verbose "Detailed info"      # only shows with -Verbose flag
Write-Warning "Something is off"
Write-Error "Something failed"
Write-Debug "Debug detail"         # only shows with -Debug flag


# =============================================================================
# FILE SYSTEM
# =============================================================================

# List files and folders in the current directory
Get-ChildItem
Get-ChildItem -Path "C:\Users"
Get-ChildItem -Recurse              # include subdirectories
Get-ChildItem -Filter "*.txt"       # only .txt files
Get-ChildItem -File                 # only files (no directories)
Get-ChildItem -Directory            # only directories

# Navigate directories
Set-Location "C:\Users\Admin"
Set-Location ..                     # go up one level
Get-Location                        # print current path  (like pwd)

# Copy, move, rename, delete
Copy-Item "file.txt" "backup.txt"
Copy-Item "folder" "folder_copy" -Recurse
Move-Item "file.txt" "C:\Temp\file.txt"
Rename-Item "old.txt" "new.txt"
Remove-Item "file.txt"
Remove-Item "folder" -Recurse -Force    # delete a folder and its contents

# Create files and directories
New-Item -ItemType File      -Path "notes.txt"
New-Item -ItemType Directory -Path "MyFolder"

# Test if a path exists
Test-Path "C:\Temp\file.txt"    # True or False

# Get properties of a file
$file = Get-Item "notes.txt"
$file.Name
$file.Length                    # size in bytes
$file.LastWriteTime


# =============================================================================
# FILE I/O — READING & WRITING
# =============================================================================

# Write text to a file — creates or overwrites
Set-Content -Path "output.txt" -Value "Hello, file!"

# Write multiple lines
Set-Content -Path "output.txt" -Value @("Line 1", "Line 2", "Line 3")

# Append text to a file without overwriting
Add-Content -Path "output.txt" -Value "Appended line"

# Read entire file as a single string
$content = Get-Content -Path "output.txt" -Raw

# Read file as an array of lines
$lines = Get-Content -Path "output.txt"
foreach ($line in $lines) {
    Write-Host $line
}

# Read and write JSON
$data = @{ Name = "Alice"; Age = 25 }
$data | ConvertTo-Json | Set-Content "data.json"

$loaded = Get-Content "data.json" | ConvertFrom-Json
$loaded.Name        # Alice

# Read and write CSV
Import-Csv "users.csv"                                  # reads as objects
Export-Csv -Path "output.csv" -NoTypeInformation        # write objects to CSV


# =============================================================================
# ERROR HANDLING
# =============================================================================

# try / catch / finally — same pattern as other languages
try {
    $result = 1 / 0
} catch {
    Write-Host "Error: $($_.Exception.Message)"
} finally {
    Write-Host "Always runs"
}

# Catch a specific exception type
try {
    [int]"not a number"
} catch [System.FormatException] {
    Write-Host "Bad format"
} catch {
    Write-Host "Other error: $_"
}

# -ErrorAction controls what happens when a non-terminating error occurs
Get-Item "missing.txt" -ErrorAction SilentlyContinue    # suppress the error
Get-Item "missing.txt" -ErrorAction Stop                 # convert to terminating error

# $ErrorActionPreference sets the default for the whole script
$ErrorActionPreference = "Stop"

# Check if the last command succeeded
Get-Item "file.txt"
if ($?) { Write-Host "Success" } else { Write-Host "Failed" }

# Throw a custom error
function Divide {
    param([int]$A, [int]$B)
    if ($B -eq 0) { throw "Cannot divide by zero" }
    return $A / $B
}


# =============================================================================
# COMMON CMDLETS REFERENCE
# =============================================================================

# Process management
Get-Process                             # list all running processes
Get-Process -Name "chrome"             # find a specific process
Stop-Process -Name "notepad" -Force    # kill a process
Start-Process "notepad.exe"            # start a process

# Services
Get-Service                            # list all services
Get-Service -Name "wuauserv"          # Windows Update service
Start-Service -Name "wuauserv"
Stop-Service -Name "wuauserv"
Restart-Service -Name "wuauserv"

# System information
Get-ComputerInfo                       # detailed system info
$env:COMPUTERNAME                      # machine name
$env:USERNAME                          # current user
$env:OS                                # operating system
[System.Environment]::OSVersion       # OS version details

# Environment variables
$env:PATH                              # read PATH
$env:MYVAR = "hello"                   # set for current session
[System.Environment]::SetEnvironmentVariable("MYVAR","hello","User")   # persist

# Network
Test-Connection "google.com"           # like ping
Test-NetConnection "google.com" -Port 443   # test if a port is open
Resolve-DnsName "google.com"          # DNS lookup

# Date and time
Get-Date                               # current date and time
Get-Date -Format "yyyy-MM-dd"          # 2024-01-15
Get-Date -Format "HH:mm:ss"           # 14:30:00
(Get-Date).AddDays(7)                  # date 7 days from now
(Get-Date).DayOfWeek                   # Monday

# Clipboard
"Hello" | Set-Clipboard                # copy to clipboard
Get-Clipboard                          # paste from clipboard

# Web requests
Invoke-WebRequest -Uri "https://example.com"                     # like curl
Invoke-RestMethod -Uri "https://api.example.com/data"            # parses JSON automatically


# =============================================================================
# OBJECTS & SELECT-OBJECT
# =============================================================================

# PowerShell everything is an object — use dot notation to access properties
$proc = Get-Process -Name "explorer"
$proc.Name
$proc.Id
$proc.CPU

# Select specific properties to display
Get-Process | Select-Object Name, Id, CPU | Format-Table

# Create a custom object
$obj = [PSCustomObject]@{
    Name  = "Alice"
    Score = 95
    Grade = "A"
}

$obj.Name       # Alice

# Add a property to an existing object
$obj | Add-Member -MemberType NoteProperty -Name "Passed" -Value $true

# Calculated properties in Select-Object
Get-ChildItem | Select-Object Name, @{
    Name = "SizeKB"
    Expression = { [math]::Round($_.Length / 1KB, 2) }
}


# =============================================================================
# REGULAR EXPRESSIONS
# =============================================================================

# -match tests a string against a regex — result in $Matches
"user@example.com" -match "^[\w.]+@[\w.]+\.\w+$"    # True
$Matches[0]                                            # full match

# -replace replaces matches with a string
"Hello World" -replace "World", "PowerShell"    # Hello PowerShell
"abc123" -replace "\d+", "NUM"                  # abcNUM

# Select-String — grep-like search in files or strings
Select-String -Path "*.log" -Pattern "ERROR"
"line one`nline two" | Select-String "one"

# Extract groups from a match
"2024-01-15" -match "(\d{4})-(\d{2})-(\d{2})"
$Matches[1]     # 2024  (year group)
$Matches[2]     # 01    (month group)


# =============================================================================
# SCRIPT PARAMETERS
# =============================================================================

# Put this block at the top of a .ps1 script file to accept arguments
param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [int]$Port = 80,

    [ValidateSet("http", "https")]
    [string]$Protocol = "https",

    [switch]$Verbose
)

# Run the script from terminal:
# .\myscript.ps1 -Target "example.com" -Port 443 -Protocol https -Verbose


# =============================================================================
# USEFUL ONE-LINERS
# =============================================================================

# Find all .txt files recursively
Get-ChildItem -Recurse -Filter "*.txt"

# Search file content for a string (like grep)
Select-String -Path "*.log" -Pattern "error" -CaseSensitive

# Get the 10 most CPU-hungry processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Kill all instances of a process
Get-Process "chrome" | Stop-Process -Force

# Get total size of a folder in MB
(Get-ChildItem "C:\Logs" -Recurse | Measure-Object Length -Sum).Sum / 1MB

# List only files modified in the last 7 days
Get-ChildItem -Recurse | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }

# Export running processes to CSV
Get-Process | Export-Csv -Path "processes.csv" -NoTypeInformation

# Base64 encode and decode a string
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("hello"))
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("aGVsbG8="))

# Download a file from the internet
Invoke-WebRequest -Uri "https://example.com/file.zip" -OutFile "file.zip"

# Get public IP address
(Invoke-RestMethod "https://api.ipify.org?format=json").ip

# Stop execution for N seconds
Start-Sleep -Seconds 5
Start-Sleep -Milliseconds 500
