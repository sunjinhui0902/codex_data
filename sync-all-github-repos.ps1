param(
    [string]$GitHubUser = "sunjinhui0902",
    [string]$BaseDir = "D:\ai_data\codex",
    [string]$ReposDirName = "repos"
)

$ErrorActionPreference = "Stop"

$python = "C:\Users\Miche\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if (-not (Test-Path -LiteralPath $python)) {
    throw "Python runtime not found: $python"
}

$reposDir = Join-Path $BaseDir $ReposDirName
New-Item -ItemType Directory -Path $reposDir -Force | Out-Null

$repoJson = & $python -c "import json, urllib.request; print(json.dumps(json.load(urllib.request.urlopen('https://api.github.com/users/$GitHubUser/repos?per_page=100')), ensure_ascii=False))"
$repos = $repoJson | ConvertFrom-Json

if ($null -eq $repos -or $repos.Count -eq 0) {
    throw "No repositories returned for $GitHubUser"
}

$snapshotPath = Join-Path $BaseDir "github-repo-list.json"
$repos | Select-Object name, full_name, ssh_url, clone_url, private, default_branch, pushed_at |
    ConvertTo-Json -Depth 3 |
    Set-Content -LiteralPath $snapshotPath -Encoding UTF8

Push-Location $BaseDir
try {
    $rootOrigin = ""
    if (Test-Path -LiteralPath (Join-Path $BaseDir ".git")) {
        $rootOrigin = git remote get-url origin 2>$null
    }

    foreach ($repo in $repos) {
        if ($repo.ssh_url -eq $rootOrigin) {
            Write-Host "Updating root repo $($repo.name)..."
            git fetch origin
            continue
        }

        $targetPath = Join-Path $reposDir $repo.name
        if (Test-Path -LiteralPath (Join-Path $targetPath ".git")) {
            Write-Host "Pulling $($repo.name)..."
            Push-Location $targetPath
            try {
                git pull --ff-only origin $repo.default_branch
            } finally {
                Pop-Location
            }
        } else {
            Write-Host "Cloning $($repo.name)..."
            git clone -b $repo.default_branch $repo.ssh_url $targetPath
        }
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "All visible GitHub repositories are synced."
Write-Host "Snapshot file: $snapshotPath"
