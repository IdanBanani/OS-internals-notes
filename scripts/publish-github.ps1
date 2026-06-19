# get-help .\scripts\publish-github.ps1 -detailed 
# will show full descriptions, and -? gives the short version with parameter summaries.

<#
.SYNOPSIS
Publish or update this study-notes repository on GitHub.

.DESCRIPTION
Uses GitHub CLI (`gh`) for repository creation/lookup and `git` for staging,
committing, remote setup, and pushing.

The repository's `.gitignore` decides what is uploaded. In this project, large
local PDFs, course folders, malware samples, and other raw source material are
ignored by default; Markdown notes under `docs/`, root Markdown files, and this
script are trackable.

.EXAMPLE
# Create a new private repo under the authenticated GitHub user/org and push.
.\scripts\publish-github.ps1 -Repo owner/OS-internals-notes -Mode new -Visibility private -CommitMessage "Initial organized notes"

.EXAMPLE
# Update an existing public or private repo.
.\scripts\publish-github.ps1 -Repo owner/OS-internals-notes -Mode existing -CommitMessage "Update Windows internals notes"

.EXAMPLE
# Preview commands without changing GitHub or git state.
.\scripts\publish-github.ps1 -Repo owner/OS-internals-notes -Mode auto -Visibility private -DryRun

.EXAMPLE
# Use SSH remote URL instead of HTTPS.
.\scripts\publish-github.ps1 -Repo owner/OS-internals-notes -Protocol ssh

.PARAMETER Repo
    GitHub repository in "owner/name" format (e.g. IdanBanani/OS-internals-notes). Required.

.PARAMETER Mode
    auto    - Create repo if it doesn't exist, update if it does. (default)
    new     - Fail if the repo already exists.
    existing - Fail if the repo doesn't exist yet.

.PARAMETER Visibility
    private - Only you can see it. (default)
    public  - Anyone can see it. Change later with: gh repo edit owner/name --visibility public

.PARAMETER Protocol
    https - Use HTTPS remote URL. (default)
    ssh   - Use SSH remote URL. Requires SSH key set up with GitHub.

.PARAMETER Remote
    Name of the git remote to create or update. Default: origin

.PARAMETER Branch
    Local branch name to push. Default: main
    If your branch is 'master', pass -Branch master or change the default in the script.

.PARAMETER CommitMessage
    Commit message for staged changes. Default: "Update study notes"

.PARAMETER Description
    Repository description shown on GitHub. Default: "OS internals study notes"

.PARAMETER RenameCurrentBranch
    Rename the current local branch to match -Branch before pushing.
    Use this to rename master -> main in one step.

.PARAMETER NoCommit
    Skip git add and git commit. Only pushes whatever was already committed.

.PARAMETER NoPush
    Stage and commit changes locally but do not push to GitHub.

.PARAMETER DryRun
    Print all commands that would run without executing any of them.
    Always run this first on a new machine or repo.
#>


[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [ValidateSet("auto", "new", "existing")]
    [string]$Mode = "auto",

    [ValidateSet("private", "public")]
    [string]$Visibility = "private",

    [ValidateSet("https", "ssh")]
    [string]$Protocol = "https",

    [string]$Remote = "origin",

    [string]$Branch = "master",   # was "main"

    [string]$CommitMessage = "Update study notes",

    [string]$Description = "OS internals study notes",

    [switch]$RenameCurrentBranch,

    [switch]$NoCommit,

    [switch]$NoPush,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Format-CommandLine {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $quoted = foreach ($arg in $Arguments) {
        if ($arg -match "[\s`"']") {
            '"' + ($arg -replace '"', '\"') + '"'
        } else {
            $arg
        }
    }

    #return (($Tool, $quoted) -join " ")
	#Bug:System.Object[] in output
    #Format-CommandLine builds the return value as ($Tool, $quoted) -join " ", but $quoted is itself an array, so PowerShell nests it as [tool, array] and stringifies the inner array as System.Object[]
	
	return (@($Tool) + @($quoted) -join " ")
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $display = Format-CommandLine -Tool $Tool -Arguments $Arguments
    if ($DryRun) {
        Write-Host "[dry-run] $display"
        return $null
    }

    Write-Host "Running: $display"
    & $Tool @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Command failed with exit code ${exitCode}: $display"
    }
}

function Invoke-ToolCapture {
    param(
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $display = Format-CommandLine -Tool $Tool -Arguments $Arguments
    if ($DryRun) {
        Write-Host "[dry-run check] $display"
    }

    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"          # <-- let stderr through without throwing
    $output = & $Tool @Arguments 2>$null
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevPref

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Command failed with exit code ${exitCode}: $display"
    }

    return (($output | Out-String).Trim())
}

function Test-Tool {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool not found on PATH: $Name"
    }
}

function Get-RemoteUrl {
    param(
        [Parameter(Mandatory = $true)][string]$NameWithOwner,
        [Parameter(Mandatory = $true)][string]$Kind
    )

    if ($Kind -eq "ssh") {
        return "git@github.com:${NameWithOwner}.git"
    }

    return "https://github.com/${NameWithOwner}.git"
}

Test-Tool -Name "git"
Test-Tool -Name "gh"

$repoRoot = Invoke-ToolCapture -Tool "git" -Arguments @("rev-parse", "--show-toplevel")
if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    throw "This script must be run inside a git repository."
}

Set-Location -LiteralPath $repoRoot

Invoke-Tool -Tool "gh" -Arguments @("auth", "status")

$repoExists = $false
$existingFullName = Invoke-ToolCapture -Tool "gh" -Arguments @("repo", "view", $Repo, "--json", "nameWithOwner", "--jq", ".nameWithOwner") -AllowFailure
# Add this guard:
if ($existingFullName -notmatch '^[\w.-]+/[\w.-]+$') {
    $existingFullName = ""   # treat garbage output as "repo not found"
}
if (-not [string]::IsNullOrWhiteSpace($existingFullName)) {
    $repoExists = $true
}

switch ($Mode) {
    "new" {
        if ($repoExists) {
            throw "GitHub repository already exists: $existingFullName"
        }
    }
    "existing" {
        if (-not $repoExists) {
            throw "GitHub repository does not exist: $Repo"
        }
    }
    "auto" {
        # Continue. Missing repositories will be created below.
    }
}

if (-not $repoExists) {
    $visibilityFlag = "--$Visibility"
    Invoke-Tool -Tool "gh" -Arguments @(
        "repo", "create", $Repo,
        $visibilityFlag,
        "--description", $Description,
        "--disable-wiki"
    )

    if ($DryRun) {
        if ($Repo.Contains("/")) {
            $existingFullName = $Repo
        } else {
            $existingFullName = "<authenticated-user>/$Repo"
        }
    } else {
        $existingFullName = Invoke-ToolCapture -Tool "gh" -Arguments @("repo", "view", $Repo, "--json", "nameWithOwner", "--jq", ".nameWithOwner")
    }
    $repoExists = $true
} else {
    Write-Host "Using existing GitHub repository: $existingFullName"
    Write-Host "Existing repository visibility is not changed by this script."
}

$nameWithOwner = $existingFullName
$remoteUrl = Get-RemoteUrl -NameWithOwner $nameWithOwner -Kind $Protocol

$currentBranch = Invoke-ToolCapture -Tool "git" -Arguments @("branch", "--show-current")
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    throw "Git is in detached HEAD state. Check out a branch before publishing."
}

if ($currentBranch -ne $Branch) {
    if ($RenameCurrentBranch) {
        Invoke-Tool -Tool "git" -Arguments @("branch", "-M", $Branch)
        $currentBranch = $Branch
    } else {
        throw "Current branch is '$currentBranch', but -Branch is '$Branch'. Rerun with -Branch '$currentBranch' or pass -RenameCurrentBranch."
    }
}

$remoteNames = Invoke-ToolCapture -Tool "git" -Arguments @("remote")
$remoteExists = (($remoteNames -split "\r?\n") -contains $Remote)
if ($remoteExists) {
    Invoke-Tool -Tool "git" -Arguments @("remote", "set-url", $Remote, $remoteUrl)
} else {
    Invoke-Tool -Tool "git" -Arguments @("remote", "add", $Remote, $remoteUrl)
}

if (-not $NoCommit) {
    Invoke-Tool -Tool "git" -Arguments @("add", "-A")

    $staged = Invoke-ToolCapture -Tool "git" -Arguments @("diff", "--cached", "--name-only")
    if ([string]::IsNullOrWhiteSpace($staged)) {
        Write-Host "No staged changes to commit."
    } else {
        Invoke-Tool -Tool "git" -Arguments @("commit", "-m", $CommitMessage)
    }
} else {
    Write-Host "Skipping commit because -NoCommit was supplied."
}

if (-not $NoPush) {
    Invoke-Tool -Tool "git" -Arguments @("push", "-u", $Remote, $currentBranch)
} else {
    Write-Host "Skipping push because -NoPush was supplied."
}

Write-Host "Done. Repository: https://github.com/$nameWithOwner"
