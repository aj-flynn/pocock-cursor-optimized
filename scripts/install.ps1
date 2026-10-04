# Copy this repo's Cursor skills and the engineering-session rule into another project.
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'

function Write-Err([string]$Message) {
  [Console]::Error.WriteLine($Message)
}

if ([string]::IsNullOrWhiteSpace($Path)) {
  Write-Err "Usage: .\scripts\install.ps1 -Path <project>"
  Write-Err "Copy these skills into <project>\.cursor\skills and the engineering-session rule into <project>\.cursor\rules."
  exit 2
}

function Resolve-Directory([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Err "Not a directory: $Path"
    exit 1
  }
  $item = Get-Item -LiteralPath (Resolve-Path -LiteralPath $Path).Path -Force
  for ($i = 0; $i -lt 32; $i++) {
    $targetProp = $item.PSObject.Properties['Target']
    if ($null -eq $targetProp -or [string]::IsNullOrWhiteSpace([string]@($item.Target)[0])) {
      break
    }
    $next = [string]@($item.Target)[0]
    if (-not [System.IO.Path]::IsPathRooted($next)) {
      $next = Join-Path (Split-Path -Parent $item.FullName) $next
    }
    $item = Get-Item -LiteralPath $next -Force
  }
  $full = $item.FullName
  if ($full.Length -eq 3 -and $full[1] -eq ':') {
    return $full
  }
  return $full.TrimEnd('\', '/')
}

$sourceRoot = Resolve-Directory (Join-Path $PSScriptRoot '..')
$target = Resolve-Directory $Path
$separator = [System.IO.Path]::DirectorySeparatorChar
$sourceRoot = $sourceRoot.Replace('/', $separator).Replace('\', $separator).TrimEnd($separator)
$target = $target.Replace('/', $separator).Replace('\', $separator).TrimEnd($separator)

if ([string]::Equals($sourceRoot, $target, [StringComparison]::OrdinalIgnoreCase)) {
  Write-Err "Refusing to install into this repo. The skills already live in .cursor/ here."
  exit 1
}
if ($target.StartsWith($sourceRoot + $separator, [StringComparison]::OrdinalIgnoreCase)) {
  Write-Err "Refusing to install into a directory inside this repo."
  exit 1
}

$srcSkills = Join-Path $sourceRoot (Join-Path '.cursor' 'skills')
$destSkills = Join-Path $target (Join-Path '.cursor' 'skills')
if (-not (Test-Path -LiteralPath $srcSkills -PathType Container)) {
  Write-Err "Missing skills directory: $srcSkills"
  exit 1
}
New-Item -ItemType Directory -Force -Path $destSkills | Out-Null

function Get-RelativeSkill([string]$SkillDir) {
  $root = $srcSkills.TrimEnd('\', '/')
  if (-not $SkillDir.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
    Write-Err "Skill is outside the skills directory: $SkillDir"
    exit 1
  }
  return ($SkillDir.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/')
}

function Join-SkillDest([string]$RelativePath) {
  $dest = $destSkills
  foreach ($part in $RelativePath.Split('/')) {
    if ($part) {
      $dest = Join-Path $dest $part
    }
  }
  return $dest
}

function Copy-Tree([string]$Source, [string]$Destination) {
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  foreach ($child in @(Get-ChildItem -LiteralPath $Source -Force)) {
    $destChild = Join-Path $Destination $child.Name
    if ($child.PSIsContainer) {
      Copy-Tree $child.FullName $destChild
    } else {
      Copy-Item -LiteralPath $child.FullName -Destination $destChild -Force
    }
  }
}

$skillFiles = @(Get-ChildItem -LiteralPath $srcSkills -Recurse -Force -Filter SKILL.md -File | Sort-Object FullName)
foreach ($skillFile in $skillFiles) {
  $skillDir = $skillFile.Directory.FullName
  $relative = Get-RelativeSkill $skillDir
  $dest = Join-SkillDest $relative
  $nested = @(Get-ChildItem -LiteralPath $skillDir -Recurse -Force -Filter SKILL.md -File | Where-Object {
      -not [string]::Equals($_.Directory.FullName, $skillDir, [StringComparison]::OrdinalIgnoreCase)
    } | Select-Object -First 1)

  if ($nested.Count -gt 0) {
    if (-not (Test-Path -LiteralPath $dest)) {
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $skillDir -Force -File)) {
      Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $dest $file.Name) -Force
      Write-Output "installed file $relative/$($file.Name)"
    }
  } else {
    if (Test-Path -LiteralPath $dest) {
      $destPhysical = Resolve-Directory $dest
      if ([string]::Equals($destPhysical, (Resolve-Directory $skillDir), [StringComparison]::OrdinalIgnoreCase)) {
        Write-Err "Refusing to replace $dest because it is the source directory."
        exit 1
      }
      Remove-Item -LiteralPath $dest -Recurse -Force
    }
    $parent = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Tree $skillDir $dest
    Write-Output "installed skill $relative"
  }
}

$ruleDir = Join-Path $target (Join-Path '.cursor' 'rules')
New-Item -ItemType Directory -Force -Path $ruleDir | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceRoot (Join-Path '.cursor' (Join-Path 'rules' 'engineering-session.mdc'))) -Destination (Join-Path $ruleDir 'engineering-session.mdc') -Force
Write-Output "installed rule engineering-session.mdc"

$gitignore = Join-Path $target '.gitignore'
if (Test-Path -LiteralPath $gitignore -PathType Leaf) {
  $ignoresScratch = $false
  foreach ($line in [System.IO.File]::ReadAllLines($gitignore)) {
    if ($line -eq '.scratch/' -or $line -eq '.scratch') {
      $ignoresScratch = $true
      break
    }
  }
  if (-not $ignoresScratch) {
    $newline = "`n"
    $bytes = [System.IO.File]::ReadAllBytes($gitignore)
    for ($i = 0; $i -lt $bytes.Length - 1; $i++) {
      if ($bytes[$i] -eq 13 -and $bytes[$i + 1] -eq 10) {
        $newline = "`r`n"
        break
      }
    }
    $suffix = [System.Text.Encoding]::UTF8.GetBytes("${newline}# Engineering session state${newline}.scratch/${newline}")
    $combined = New-Object byte[] ($bytes.Length + $suffix.Length)
    [System.Buffer]::BlockCopy($bytes, 0, $combined, 0, $bytes.Length)
    [System.Buffer]::BlockCopy($suffix, 0, $combined, $bytes.Length, $suffix.Length)
    [System.IO.File]::WriteAllBytes($gitignore, $combined)
    Write-Output "appended .scratch/ to .gitignore"
  }
} else {
  Write-Output "No .gitignore in the target. Add .scratch/ so the engineering session file stays uncommitted."
}
