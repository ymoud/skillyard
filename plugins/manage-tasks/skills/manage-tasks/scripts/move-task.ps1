<#
.SYNOPSIS
    Moves task files between tasks/ongoing, tasks/backlog and tasks/history and
    rewrites every link to them across the docs repository.

.DESCRIPTION
    A task file lives in the folder that matches its state:
        backlog/   not started, or paused and parked - row in backlog.md
        ongoing/   active - row in ongoing.md
        history/   closed - Complete, Rejected, Superseded or removed

    Never move a task file by hand. The script moves every file of a task (the
    task file plus companions such as task-042-findings.md), then rewrites:
      - relative links to a moved file, in every .md, .html, .htm and .txt file
      - relative links inside a moved file, so they resolve from the new folder
      - plain-text paths such as my-project.docs/tasks/history/task-090-x.md,
        except under the -SnapshotFolders, whose text records a past state

    Tracked files move with git mv, so the renames are staged. Untracked files
    move on disk. Link rewrites stay unstaged: review them, then stage the files
    by name. Rewritten files keep their encoding, BOM and line endings. Running
    the script again for a task that is already in place changes nothing.

.PARAMETER Id
    Task IDs as they appear in file names (042, 140a). One- and two-digit IDs
    are zero-padded. Separate several IDs with commas.

.PARAMETER Path
    Files that do not follow task-{ID}-{slug}.md, relative to the docs root.
    Separate several paths with commas.

.PARAMETER To
    Destination folder: ongoing, backlog or history.

.PARAMETER DocsRoot
    Root of the docs repository, the folder that holds tasks/. Relative paths
    resolve from the current directory.

.PARAMETER SnapshotFolders
    Docs folders, relative to the docs root, whose plain-text task paths are
    left alone: reports that record what a past commit touched. Links in them
    are still rewritten. Separate several folders with commas.

.PARAMETER DryRun
    Print the moves and every link rewrite without changing anything.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/manage-tasks/scripts/move-task.ps1 -DocsRoot my-project.docs -Id 42 -To history

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/manage-tasks/scripts/move-task.ps1 -DocsRoot my-project.docs -Id 280,281 -To ongoing -SnapshotFolders reporting/weekly -DryRun
#>
[CmdletBinding(DefaultParameterSetName = 'Id')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Id')]
    [string[]]$Id,

    [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
    [string[]]$Path,

    [Parameter(Mandatory = $true)]
    [ValidateSet('ongoing', 'backlog', 'history')]
    [string]$To,

    [Parameter(Mandatory = $true)]
    [string]$DocsRoot,

    [string[]]$SnapshotFolders = @(),

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$stateFolders = @('ongoing', 'backlog', 'history')
$textExtensions = @('.md', '.html', '.htm', '.txt')
$snapshotFolders = @($SnapshotFolders -split ',' | ForEach-Object { $_.Trim().Trim('/', '\') } | Where-Object { $_ -and $_ -ne '-' } | ForEach-Object { $_.Replace('/', '\') + '\' })

function Get-DocsRelative([string]$fullPath) {
    $fullPath.Substring($DocsRoot.Length + 1).Replace('\', '/')
}

function Get-RelativeLink([string]$fromDir, [string]$toFile) {
    $fromUri = New-Object System.Uri ($fromDir.TrimEnd('\') + '\')
    $toUri = New-Object System.Uri $toFile
    [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString())
}

# Returns the link target rewritten for the post-move layout, or the target unchanged.
function Convert-Link([string]$target, [string]$oldDir, [string]$newDir, [bool]$fileMoves) {
    $angle = $target.StartsWith('<') -and $target.EndsWith('>')
    $link = if ($angle) { $target.Substring(1, $target.Length - 2) } else { $target }
    if ($link -match '^[A-Za-z][A-Za-z0-9+.\-]*:' -or $link -match '^[#/\\]') { return $target }
    $hash = $link.IndexOf('#')
    $pathPart = if ($hash -ge 0) { $link.Substring(0, $hash) } else { $link }
    $fragment = if ($hash -ge 0) { $link.Substring($hash) } else { '' }
    if (-not $pathPart) { return $target }
    try {
        $decoded = [System.Uri]::UnescapeDataString($pathPart)
        $oldTarget = [IO.Path]::GetFullPath([IO.Path]::Combine($oldDir, $decoded.Replace('/', '\')))
    }
    catch { return $target }
    if ($newByOld.ContainsKey($oldTarget)) { $newTarget = $newByOld[$oldTarget] }
    elseif ($fileMoves -and (Test-Path -LiteralPath $oldTarget -PathType Leaf)) { $newTarget = $oldTarget }
    else { return $target }
    $relative = Get-RelativeLink $newDir $newTarget
    if ($relative -ceq $decoded.Replace('\', '/')) { return $target }
    if ($pathPart.Contains('%20')) { $relative = $relative.Replace(' ', '%20') }
    if ($angle) { "<$relative$fragment>" } else { "$relative$fragment" }
}

$DocsRoot =[IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DocsRoot)).TrimEnd('\')
$tasksRoot = Join-Path $DocsRoot 'tasks'
if (-not (Test-Path -LiteralPath $tasksRoot -PathType Container)) { throw "No tasks folder under '$DocsRoot'. Pass -DocsRoot." }
$targetDir = Join-Path $tasksRoot $To

# 1. Resolve the files to move.
$sources = New-Object System.Collections.Generic.List[string]
if ($PSCmdlet.ParameterSetName -eq 'Id') {
    foreach ($taskId in @($Id -split ',' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })) {
        if ($taskId -notmatch '^[0-9]+[a-z]?$') { throw "Invalid task ID '$taskId'. Use -Path for files without a task-{ID}- prefix." }
        if ($taskId -match '^[0-9]{1,2}$') { $taskId = $taskId.PadLeft(3, '0') }
        $found = @(foreach ($folder in $stateFolders) {
                $dir = Join-Path $tasksRoot $folder
                if (Test-Path -LiteralPath $dir) { Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Name -like "task-$taskId-*.md" } }
            })
        if ($found.Count -eq 0) { throw "No task-$taskId-*.md in tasks/ongoing, tasks/backlog or tasks/history." }
        $folders = @($found | ForEach-Object { $_.Directory.Name } | Sort-Object -Unique)
        if ($folders.Count -gt 1) { throw "Task $taskId has files in several folders ($($folders -join ', ')). Fix that first." }
        foreach ($f in $found) { $sources.Add($f.FullName) }
    }
}
else {
    foreach ($p in @($Path -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $full = if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $DocsRoot $p }
        $full = [IO.Path]::GetFullPath($full)
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "File not found: $p" }
        $sources.Add($full)
    }
}
if ($sources.Count -eq 0) { throw 'No files to move. Pass -Id or -Path.' }

# 2. Plan the moves.
$moves = New-Object System.Collections.Generic.List[object]
$newByOld = @{}
$namesMoving = @{}
foreach ($source in $sources) {
    if (-not $source.StartsWith($tasksRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Not under tasks/: $source" }
    $name = [IO.Path]::GetFileName($source)
    $destination = Join-Path $targetDir $name
    if ($source -ieq $destination) { Write-Output "Already in tasks/$To/: $name"; continue }
    if ($newByOld.ContainsKey($source)) { continue }
    if ($namesMoving.ContainsKey($name) -or (Test-Path -LiteralPath $destination)) { throw "tasks/$To/$name already exists or is requested twice." }
    $moves.Add([pscustomobject]@{ Old = $source; New = $destination })
    $newByOld[$source] = $destination
    $namesMoving[$name] = $true
}
if ($moves.Count -eq 0) { return }

# 3. Compute every link rewrite against the current, pre-move layout.
$linkPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?<=\]\(\s*)(?:<[^>\r\n]+>|[^)\s<>]+)' +
    '|(?<=^[ ]{0,3}\[[^\]\r\n]+\]:[ \t]*)(?:<[^>\r\n]+>|[^\s<>]+)' +
    '|(?<=\b(?:href|src)\s*=\s*["''])[^"''\r\n]+',
    [System.Text.RegularExpressions.RegexOptions]::Multiline)
$mentionPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?<![A-Za-z0-9_.\-/\\])(?<pre>(?:[A-Za-z0-9_.\-]+[/\\])*tasks[/\\])(?<folder>items|ongoing|backlog|history)(?<sep>[/\\])(?<name>[A-Za-z0-9_.\-]+\.md)(?![A-Za-z0-9_\-])',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$rewrites = New-Object System.Collections.Generic.List[object]
foreach ($file in @(Get-ChildItem -LiteralPath $DocsRoot -Recurse -File | Where-Object { $textExtensions -contains $_.Extension })) {
    $readPath = $file.FullName
    $fileMoves = $newByOld.ContainsKey($readPath)
    $writePath = if ($fileMoves) { $newByOld[$readPath] } else { $readPath }
    $bytes = [IO.File]::ReadAllBytes($readPath)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $encoding = [System.Text.UTF8Encoding]::new($hasBom, $true)
    $offset = if ($hasBom) { 3 } else { 0 }
    try { $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset) }
    catch { Write-Warning "Skipped, not UTF-8: $(Get-DocsRelative $readPath)"; continue }

    $oldDir = [IO.Path]::GetDirectoryName($readPath)
    $newDir = [IO.Path]::GetDirectoryName($writePath)
    $isSnapshot = @($snapshotFolders | Where-Object { $readPath.StartsWith((Join-Path $DocsRoot $_), [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
    $log = New-Object System.Collections.Generic.List[string]
    $newText = $linkPattern.Replace($text, [System.Text.RegularExpressions.MatchEvaluator] {
            param($match)
            $converted = Convert-Link $match.Value $oldDir $newDir $fileMoves
            if ($converted -cne $match.Value) { $log.Add("$($match.Value) -> $converted") }
            $converted
        })
    if (-not $isSnapshot) {
        $newText = $mentionPattern.Replace($newText, [System.Text.RegularExpressions.MatchEvaluator] {
                param($match)
                $mentioned = $match.Groups['name'].Value
                if (-not $namesMoving.ContainsKey($mentioned) -or $match.Groups['folder'].Value -eq $To) { return $match.Value }
                $converted = $match.Groups['pre'].Value + $To + $match.Groups['sep'].Value + $mentioned
                $log.Add("$($match.Value) -> $converted")
                $converted
            })
    }
    if ($log.Count -gt 0) { $rewrites.Add([pscustomobject]@{ Path = $writePath; Text = $newText; Encoding = $encoding; Log = $log }) }
}

# 4. Apply, unless this is a dry run.
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $tracked = @{}
    $lsFiles = @(& git -C $DocsRoot ls-files -- tasks)
    if ($LASTEXITCODE -ne 0) { throw "git ls-files failed in $DocsRoot" }
    foreach ($relativePath in $lsFiles) { $tracked[(Join-Path $DocsRoot $relativePath.Replace('/', '\'))] = $true }
    $gitSources = @($moves | Where-Object { $tracked.ContainsKey($_.Old) } | ForEach-Object { $_.Old })
    for ($i = 0; $i -lt $gitSources.Count; $i += 100) {
        $chunk = @($gitSources[$i..([Math]::Min($i + 99, $gitSources.Count - 1))])
        & git -C $DocsRoot mv -- @chunk $targetDir
        if ($LASTEXITCODE -ne 0) { throw 'git mv failed. Check git status: part of the batch may have moved.' }
    }
    foreach ($move in @($moves | Where-Object { -not $tracked.ContainsKey($_.Old) })) {
        Move-Item -LiteralPath $move.Old -Destination $move.New
    }
    foreach ($rewrite in $rewrites) { [IO.File]::WriteAllText($rewrite.Path, $rewrite.Text, $rewrite.Encoding) }
    foreach ($dir in @($moves | ForEach-Object { [IO.Path]::GetDirectoryName($_.Old) } | Sort-Object -Unique)) {
        if ($stateFolders -notcontains (Split-Path $dir -Leaf) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir }
    }
}

# 5. Report.
$showDetails = $DryRun -or $VerbosePreference -ne 'SilentlyContinue'
Write-Output "$(if ($DryRun) { 'Would move' } else { 'Moved' }) $($moves.Count) file(s) to tasks/$To/"
if ($moves.Count -le 20 -or $showDetails) { foreach ($move in $moves) { Write-Output "  $(Get-DocsRelative $move.Old)" } }
$linkCount = 0
foreach ($rewrite in $rewrites) { $linkCount += $rewrite.Log.Count }
Write-Output "$(if ($DryRun) { 'Would rewrite' } else { 'Rewrote' }) $linkCount link(s) in $($rewrites.Count) file(s)"
foreach ($rewrite in ($rewrites | Sort-Object Path)) {
    Write-Output "  $(Get-DocsRelative $rewrite.Path) ($($rewrite.Log.Count))"
    if ($showDetails) { foreach ($line in $rewrite.Log) { Write-Output "      $line" } }
}
if (-not $DryRun) { Write-Output 'Renames are staged. Link rewrites are not: review them, then stage the files by name.' }
