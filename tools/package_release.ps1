param(
    [string]$Version,
    [string]$Workspace,
    [string]$GameRoot = "D:\Program Files (x86)\Steam\steamapps\common\Street Fighter 6",
    [string]$OutputDir,
    [switch]$Force,
    [switch]$UpdateRepoManifest
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label not found: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Resolve-OrCreateDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Assert-ChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$ChildPath,
        [Parameter(Mandatory = $true)][string]$ParentPath
    )

    $childFull = [System.IO.Path]::GetFullPath($ChildPath)
    $parentFull = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd('\') + '\'
    if (-not $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside output directory: $childFull"
    }
}

function Remove-ExistingArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$OutputRoot,
        [Parameter(Mandatory = $true)][bool]$AllowRemove
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if (-not $AllowRemove) {
        throw "Artifact already exists. Re-run with -Force to overwrite: $Path"
    }

    Assert-ChildPath -ChildPath $Path -ParentPath $OutputRoot
    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Copy-TrackedReframeworkFiles {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$PackageRoot
    )

    $trackedFiles = & git -C $SourceRoot ls-files -- autorun data fonts images plugins
    if ($LASTEXITCODE -ne 0) {
        throw "git ls-files failed. Run this script inside a Git checkout."
    }

    $untrackedFiles = & git -C $SourceRoot ls-files --others --exclude-standard -- autorun data fonts images plugins
    if ($LASTEXITCODE -ne 0) {
        throw "git ls-files for untracked files failed. Run this script inside a Git checkout."
    }

    if ($untrackedFiles.Count -gt 0) {
        $preview = ($untrackedFiles | Select-Object -First 20) -join [Environment]::NewLine
        throw "Untracked package-source files exist. Track them or move them before packaging:$([Environment]::NewLine)$preview"
    }

    foreach ($relativePath in $trackedFiles) {
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            continue
        }

        $windowsRelativePath = $relativePath -replace '/', '\'
        $sourcePath = Join-Path $SourceRoot $windowsRelativePath
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Tracked file is missing: $sourcePath"
        }

        $destinationPath = Join-Path $PackageRoot (Join-Path "reframework" $windowsRelativePath)
        $destinationDirectory = Split-Path -Parent $destinationPath
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    }
}

function New-ZipFromDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$ZipPath
    )

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    $zipItems = Join-Path $SourceDirectory "*"
    Compress-Archive -Path $zipItems -DestinationPath $ZipPath -CompressionLevel Optimal
}

function Get-ReleaseFileEntry {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)][string]$ReleaseVersion
    )

    $relativePath = $File.FullName.Substring($RootPath.Length + 1)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($File.FullName)
    try {
        $hashBytes = $sha256.ComputeHash($stream)
        $hash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $stream.Dispose()
        $sha256.Dispose()
    }

    [pscustomobject]@{
        path = $relativePath
        version = $ReleaseVersion
        sha256 = $hash
        required = $true
    }
}

function New-ReleaseManifest {
    param(
        [Parameter(Mandatory = $true)][string]$RuntimePackageRoot,
        [Parameter(Mandatory = $true)][string]$ReleaseVersion,
        [Parameter(Mandatory = $true)][string]$RuntimeZipName
    )

    $rootPath = (Resolve-Path -LiteralPath $RuntimePackageRoot).Path
    $files = Get-ChildItem -LiteralPath $RuntimePackageRoot -Recurse -File |
        Sort-Object FullName |
        ForEach-Object { Get-ReleaseFileEntry -File $_ -RootPath $rootPath -ReleaseVersion $ReleaseVersion }

    [pscustomobject]@{
        version = $ReleaseVersion
        sourceZip = $RuntimeZipName
        files = @($files)
    }
}

$scriptDirectory = if ($PSScriptRoot) {
    $PSScriptRoot
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
$defaultWorkspace = Split-Path -Parent $scriptDirectory

if ([string]::IsNullOrWhiteSpace($Workspace)) {
    $Workspace = $defaultWorkspace
}

$workspacePath = Resolve-ExistingPath -Path $Workspace -Label "Workspace"
$gameRootPath = Resolve-ExistingPath -Path $GameRoot -Label "Game root"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $workspacePath "release"
}

$outputPath = Resolve-OrCreateDirectory -Path $OutputDir

if ([string]::IsNullOrWhiteSpace($Version)) {
    $repoManifestPath = Join-Path $workspacePath "sf6cm_manifest.json"
    if (-not (Test-Path -LiteralPath $repoManifestPath)) {
        throw "Version was not provided and sf6cm_manifest.json was not found."
    }

    $Version = (Get-Content -Raw -LiteralPath $repoManifestPath | ConvertFrom-Json).version
}

$releaseVersion = $Version.Trim()
if ($releaseVersion.StartsWith("v", [System.StringComparison]::OrdinalIgnoreCase)) {
    $releaseVersion = $releaseVersion.Substring(1)
}
if ([string]::IsNullOrWhiteSpace($releaseVersion)) {
    throw "Release version cannot be empty."
}

$packagePrefix = "XiaoTun_SF6_TrainingMOD_v$releaseVersion"
$standardPackageName = $packagePrefix
$runtimePackageName = "${packagePrefix}_runtime"

$dinputPath = Resolve-ExistingPath -Path (Join-Path $gameRootPath "dinput8.dll") -Label "dinput8.dll"
$configPath = Resolve-ExistingPath -Path (Join-Path $gameRootPath "re2_fw_config.txt") -Label "re2_fw_config.txt"

$standardPackagePath = Join-Path $outputPath $standardPackageName
$runtimePackagePath = Join-Path $outputPath $runtimePackageName
$standardZipPath = Join-Path $outputPath "$standardPackageName.zip"
$runtimeZipPath = Join-Path $outputPath "$runtimePackageName.zip"
$manifestPath = Join-Path $outputPath "sf6cm_manifest_v$releaseVersion.json"

Remove-ExistingArtifact -Path $standardPackagePath -OutputRoot $outputPath -AllowRemove ([bool]$Force)
Remove-ExistingArtifact -Path $runtimePackagePath -OutputRoot $outputPath -AllowRemove ([bool]$Force)
Remove-ExistingArtifact -Path $standardZipPath -OutputRoot $outputPath -AllowRemove ([bool]$Force)
Remove-ExistingArtifact -Path $runtimeZipPath -OutputRoot $outputPath -AllowRemove ([bool]$Force)
Remove-ExistingArtifact -Path $manifestPath -OutputRoot $outputPath -AllowRemove ([bool]$Force)

New-Item -ItemType Directory -Path $standardPackagePath | Out-Null
New-Item -ItemType Directory -Path $runtimePackagePath | Out-Null

Copy-TrackedReframeworkFiles -SourceRoot $workspacePath -PackageRoot $standardPackagePath
Copy-TrackedReframeworkFiles -SourceRoot $workspacePath -PackageRoot $runtimePackagePath

Copy-Item -LiteralPath $dinputPath -Destination (Join-Path $standardPackagePath "dinput8.dll") -Force
Copy-Item -LiteralPath $dinputPath -Destination (Join-Path $runtimePackagePath "dinput8.dll") -Force
Copy-Item -LiteralPath $configPath -Destination (Join-Path $runtimePackagePath "re2_fw_config.txt") -Force

New-ZipFromDirectory -SourceDirectory $standardPackagePath -ZipPath $standardZipPath
New-ZipFromDirectory -SourceDirectory $runtimePackagePath -ZipPath $runtimeZipPath

$manifest = New-ReleaseManifest -RuntimePackageRoot $runtimePackagePath -ReleaseVersion $releaseVersion -RuntimeZipName "$runtimePackageName.zip"
$manifestJson = $manifest | ConvertTo-Json -Depth 5
Set-Content -LiteralPath $manifestPath -Value $manifestJson -Encoding UTF8

if ($UpdateRepoManifest) {
    Set-Content -LiteralPath (Join-Path $workspacePath "sf6cm_manifest.json") -Value $manifestJson -Encoding UTF8
}

Write-Host "Release packaged successfully."
Write-Host "Output directory: $outputPath"
Write-Host "Standard package: $standardZipPath"
Write-Host "Runtime package:  $runtimeZipPath"
Write-Host "Manifest:         $manifestPath"
