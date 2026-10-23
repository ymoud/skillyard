<#
.SYNOPSIS
    Copies a skill into a project as a vendored copy, or checks a vendored copy
    against its manifest.

.DESCRIPTION
    Copy mode (-Source) copies the skill folder into
    <ProjectRoot>/.claude/skills/<name>/, removes the files the source no longer
    has, and writes vendor.json next to SKILL.md: the version, the source commit
    and a hash of every file. The version comes from the plugin manifest two
    levels above the skill folder: plugins/<plugin>/.claude-plugin/plugin.json.

    Check mode (-Check) recomputes the hashes of a vendored copy and lists the
    edited, missing and extra files. Hashes read CR LF as LF, so a checkout that
    converts line endings is not an edit.

    The script never stages or commits. It refuses to replace a folder without
    vendor.json, which is a project's own copy, unless -ReplaceUnvendored is given.

.PARAMETER Source
    The skill folder to copy, inside a plugin: plugins/<plugin>/skills/<skill>.

.PARAMETER ProjectRoot
    The workspace root of the project. The copy goes to .claude/skills/<name>/ in it.

.PARAMETER Name
    The skill's folder name. Defaults to the source folder's name, or to
    manage-tasks in check mode.

.PARAMETER ReplaceUnvendored
    Allow replacing a folder that has no vendor.json, after its rules were migrated.

.PARAMETER Check
    Check the vendored copy instead of copying.

.PARAMETER DryRun
    Print what would be added, changed and removed without changing anything.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File <clone>/plugins/manage-tasks/skills/manage-tasks/scripts/vendor-skill.ps1 -Source <clone>/plugins/manage-tasks/skills/manage-tasks -ProjectRoot . -DryRun

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/manage-tasks/scripts/vendor-skill.ps1 -Check -ProjectRoot .
#>
[CmdletBinding(DefaultParameterSetName = 'Copy')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Copy')]
    [string]$Source,

    [Parameter(Mandatory = $true, ParameterSetName = 'Check')]
    [switch]$Check,

    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$Name,

    [Parameter(ParameterSetName = 'Copy')]
    [switch]$ReplaceUnvendored,

    [Parameter(ParameterSetName = 'Copy')]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$manifestName = 'vendor.json'
$ignoredNames = @($manifestName, 'desktop.ini', 'Thumbs.db', '.DS_Store')

function Resolve-FullPath([string]$path) {
    [IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)).TrimEnd('\')
}

function Read-Json([string]$path) {
    Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

# SHA-256 of a file, reading every CR LF as LF. Files holding a NUL byte are hashed as they are.
function Get-NormalizedHash([string]$path) {
    $bytes = [IO.File]::ReadAllBytes($path)
    if ([Array]::IndexOf($bytes, [byte]0) -lt 0) {
        $kept = [System.Collections.Generic.List[byte]]::new($bytes.Length)
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            if ($bytes[$i] -eq 13 -and $i + 1 -lt $bytes.Length -and $bytes[$i + 1] -eq 10) { continue }
            $kept.Add($bytes[$i])
        }
        $bytes = $kept.ToArray()
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

# Relative path (forward slashes) -> normalized hash, for every file under the folder, sorted.
function Get-FileMap([string]$root) {
    $map = [ordered]@{}
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return $map }
    [string[]]$paths = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force |
            Where-Object { $ignoredNames -notcontains $_.Name } |
            ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') })
    [Array]::Sort($paths, [StringComparer]::Ordinal)
    foreach ($relative in $paths) { $map[$relative] = Get-NormalizedHash (Join-Path $root $relative.Replace('/', '\')) }
    $map
}

function Format-JsonValue($value) {
    if ($null -eq $value) { return 'null' }
    if ($value -is [bool]) { return $value.ToString().ToLowerInvariant() }
    ConvertTo-Json -InputObject ([string]$value) -Compress
}

# The manifest as two-space-indented JSON; Windows PowerShell's ConvertTo-Json output is hard to read in a diff.
function Format-Manifest($manifest) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('{')
    foreach ($key in @($manifest.Keys | Where-Object { $_ -ne 'files' })) { $lines.Add("  $(Format-JsonValue $key): $(Format-JsonValue $manifest[$key]),") }
    $lines.Add('  "files": {')
    $files = $manifest['files']
    $lines.Add((@($files.Keys | ForEach-Object { "    $(Format-JsonValue $_): $(Format-JsonValue $files[$_])" }) -join ",`n"))
    $lines.Add('  }')
    $lines.Add('}')
    ($lines -join "`n") + "`n"
}

# Output of a git command in the folder, or $null when git or the repository is missing.
function Invoke-Git([string]$dir, [string[]]$arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $dir @arguments 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        $output
    }
    catch { $null }
    finally { $ErrorActionPreference = $previous }
}

$ProjectRoot = Resolve-FullPath $ProjectRoot
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Project root not found: $ProjectRoot" }

if ($PSCmdlet.ParameterSetName -eq 'Check') {
    if (-not $Name) { $Name = 'manage-tasks' }
    $target = Join-Path $ProjectRoot ".claude\skills\$Name"
    $targetManifest = Join-Path $target $manifestName
    if (-not (Test-Path -LiteralPath $targetManifest -PathType Leaf)) {
        Write-Output "Not a vendored copy: no $manifestName in .claude/skills/$Name/"
        return
    }
    $manifest = Read-Json $targetManifest
    $recorded = @{}
    foreach ($property in $manifest.files.PSObject.Properties) { $recorded[$property.Name] = [string]$property.Value }
    $actual = Get-FileMap $target
    $edited = @($recorded.Keys | Where-Object { $actual.Contains($_) -and $actual[$_] -ne $recorded[$_] } | Sort-Object)
    $missing = @($recorded.Keys | Where-Object { -not $actual.Contains($_) } | Sort-Object)
    $extra = @($actual.Keys | Where-Object { -not $recorded.ContainsKey($_) } | Sort-Object)

    $origin = if ($manifest.sourceCommit) { ", from commit $(([string]$manifest.sourceCommit).Substring(0, 12))" } else { '' }
    Write-Output "$Name $($manifest.version), vendored on $($manifest.vendoredOn)$origin"
    if ($manifest.sourceDirty) { Write-Output 'Warning: copied from a source with uncommitted changes; it matches no released version.' }
    if ($edited.Count + $missing.Count + $extra.Count -eq 0) {
        Write-Output "OK: all $($recorded.Count) files match the manifest."
        return
    }
    Write-Output "Differences found: $($edited.Count) edited, $($missing.Count) missing, $($extra.Count) extra."
    foreach ($path in $edited) { Write-Output "  edited   $path" }
    foreach ($path in $missing) { Write-Output "  missing  $path" }
    foreach ($path in $extra) { Write-Output "  extra    $path" }
    return
}

# Copy mode.
$Source = Resolve-FullPath $Source
if (-not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md') -PathType Leaf)) { throw "No SKILL.md in $Source" }
if (-not $Name) { $Name = Split-Path $Source -Leaf }
$pluginManifest = Resolve-FullPath (Join-Path $Source '..\..\.claude-plugin\plugin.json')
if (-not (Test-Path -LiteralPath $pluginManifest -PathType Leaf)) {
    throw "No plugin manifest at $pluginManifest. Pass a skill folder inside a plugin: plugins/<plugin>/skills/<skill>."
}
$plugin = Read-Json $pluginManifest
if (-not $plugin.version) { throw "No version in $pluginManifest" }

$target = Join-Path $ProjectRoot ".claude\skills\$Name"
$targetManifest = Join-Path $target $manifestName
if ($target -ieq $Source) { throw 'The source and the target are the same folder.' }
$previousVersion = $null
if (Test-Path -LiteralPath $target) {
    if (Test-Path -LiteralPath $targetManifest -PathType Leaf) { $previousVersion = (Read-Json $targetManifest).version }
    elseif (-not $ReplaceUnvendored) {
        throw ".claude/skills/$Name/ exists without $manifestName, so it is the project's own copy. Migrate its rules first, then pass -ReplaceUnvendored."
    }
}

$sourceMap = Get-FileMap $Source
$targetMap = Get-FileMap $target
$added = @($sourceMap.Keys | Where-Object { -not $targetMap.Contains($_) })
$changed = @($sourceMap.Keys | Where-Object { $targetMap.Contains($_) -and $targetMap[$_] -ne $sourceMap[$_] })
$removed = @($targetMap.Keys | Where-Object { -not $sourceMap.Contains($_) })

$commit = Invoke-Git $Source @('rev-parse', 'HEAD')
$dirty = $null
if ($commit) { $dirty = [bool](Invoke-Git $Source @('status', '--porcelain', '--', '.')) }
$repository = $null
if ($plugin.repository) { $repository = [string]$plugin.repository }
elseif ($plugin.homepage) { $repository = [string]$plugin.homepage }

$manifest = [ordered]@{
    skill        = $Name
    version      = [string]$plugin.version
    repository   = $repository
    sourceCommit = $(if ($commit) { [string]$commit } else { $null })
    sourceDirty  = $dirty
    vendoredOn   = (Get-Date -Format 'yyyy-MM-dd')
    files        = $sourceMap
}

if (-not $DryRun) {
    foreach ($relative in $removed) { Remove-Item -LiteralPath (Join-Path $target $relative.Replace('/', '\')) -Force }
    foreach ($relative in @($added + $changed)) {
        $destination = Join-Path $target $relative.Replace('/', '\')
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $Source $relative.Replace('/', '\')) -Destination $destination -Force
    }
    Get-ChildItem -LiteralPath $target -Recurse -Directory |
        Sort-Object { $_.FullName.Length } -Descending |
        Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName }
    [IO.File]::WriteAllText($targetManifest, (Format-Manifest $manifest), (New-Object System.Text.UTF8Encoding $false))
}

$versions = if ($previousVersion) { "$previousVersion -> $($manifest.version)" } else { $manifest.version }
Write-Output "$(if ($DryRun) { 'Would vendor' } else { 'Vendored' }) $Name $versions into .claude/skills/$Name/"
if ($dirty) { Write-Output 'Warning: the source has uncommitted changes; this copy matches no released version.' }
if ($added.Count + $changed.Count + $removed.Count -eq 0) { Write-Output 'No file changes.' }
foreach ($path in $added) { Write-Output "  added    $path" }
foreach ($path in $changed) { Write-Output "  changed  $path" }
foreach ($path in $removed) { Write-Output "  removed  $path" }
if (-not $DryRun) { Write-Output 'Nothing is staged: review the changes, then stage the files by name.' }
