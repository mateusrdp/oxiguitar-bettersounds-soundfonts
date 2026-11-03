# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Installs OxiGuitar's recommended sound sets (see README.md). Nothing is
# downloaded before you have seen what and from where and said yes; every
# file is checked against the SHA-256 in sets.txt and a file that does not
# match is thrown away. Works in Windows PowerShell 5.1 and PowerShell 7.
#
#   .\install.ps1 -List
#   .\install.ps1 -Sets bass,drums
#   .\install.ps1 -Yes                 (all sets, no questions)
#   .\install.ps1 -Uninstall -Sets bass
param(
    [switch]$List,
    [string]$Sets = "",
    [string]$Dir = "",
    [switch]$Yes,
    [switch]$Uninstall
)
$ErrorActionPreference = "Stop"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }

$setsFile = if ($env:OXIGUITAR_SETS_FILE) { $env:OXIGUITAR_SETS_FILE } else { Join-Path $PSScriptRoot "sets.txt" }
if (-not (Test-Path -LiteralPath $setsFile)) { throw "cannot find $setsFile" }

$sets = [ordered]@{}
$files = @{}
foreach ($line in [IO.File]::ReadAllLines($setsFile, [Text.Encoding]::UTF8)) {
    if ($line.StartsWith("#") -or $line.Trim() -eq "") { continue }
    $f = $line.Split("|")
    if ($f[0] -eq "set") {
        $sets[$f[1]] = [pscustomobject]@{ Id = $f[1]; Name = $f[2]; Role = $f[3]; Licence = $f[4]; Credit = $f[5]
            Source = $f[6]; Count = [int]$f[7]; Bytes = [int64]$f[8]; Notice = $f[9] }
        $files[$f[1]] = New-Object System.Collections.ArrayList
    } elseif ($f[0] -eq "file") {
        [void]$files[$f[1]].Add([pscustomobject]@{ Sum = $f[2]; Size = [int64]$f[3]; Url = $f[4]; Path = $f[5] })
    }
}
function Mb($b) { "{0:N1} MB" -f ($b / 1e6) }

if ($List) {
    "{0,-18} {1,-10} {2,-12} {3}" -f "SET", "SIZE", "LICENCE", "CREDIT"
    foreach ($s in $sets.Values) { "{0,-18} {1,-10} {2,-12} {3}" -f $s.Id, (Mb $s.Bytes), $s.Licence, $s.Credit }
    return
}

if (-not $Dir) {
    $home_ = if ($env:OXIGUITAR_HOME) { $env:OXIGUITAR_HOME } else { Join-Path $env:APPDATA "OxiGuitar" }
    $Dir = Join-Path $home_ "soundfonts"
}

if (-not $Sets) {
    if ($Yes) { $Sets = "all" }
    elseif ($Uninstall) { throw "say which sets to remove with -Sets (see -List)" }
    else {
        "OxiGuitar sound sets:`n"
        foreach ($s in $sets.Values) { "  {0,-18} {1,-10} {2}" -f $s.Id, (Mb $s.Bytes), $s.Licence }
        $Sets = Read-Host "`nWhich sets? Names separated by commas, or `"all`" [all]"
        if (-not $Sets) { $Sets = "all" }
    }
}
if ($Sets -eq "all") { $chosen = @($sets.Keys) }
else {
    $chosen = @($Sets.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($id in $chosen) { if (-not $sets.Contains($id)) { throw "no such set: $id (see -List)" } }
}

function Confirm-Yes($question) {
    if ($Yes) { return $true }
    $a = Read-Host "$question [y/N]"
    return ($a -match '^(y|yes)$')
}

if ($Uninstall) {
    "This removes, from ${Dir}:"
    foreach ($id in $chosen) { "  $id" }
    if (-not (Confirm-Yes "Remove them?")) { "Nothing removed."; return }
    foreach ($id in $chosen) {
        $d = Join-Path $Dir $id
        # Only a folder this installer made (it holds oxiguitar-set.json).
        if (Test-Path -LiteralPath (Join-Path $d "oxiguitar-set.json")) { Remove-Item -LiteralPath $d -Recurse -Force; "removed $id" }
        else { "${id}: not installed" }
    }
    return
}

# What will happen, before anything does.
"These sets will be installed into:`n  $Dir`n"
$total = 0
foreach ($id in $chosen) {
    $s = $sets[$id]
    $total += $s.Bytes
    $hosts = ($files[$id] | ForEach-Object { ([uri]$_.Url).Host } | Sort-Object -Unique) -join " "
    "  ${id}: $(Mb $s.Bytes), $($s.Licence), $($s.Credit)"
    "      from $hosts"
    if ($s.Notice) { "      the licence asks for this credit: $($s.Notice)" }
}
"`nTotal download: $(Mb $total) at most (files already here are not fetched again)."
if (-not (Confirm-Yes "Download and install?")) { "Nothing downloaded."; return }

function Sha256($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Json($s) { $s.Replace("\", "\\").Replace('"', '\"') }
$utf8 = New-Object Text.UTF8Encoding($false)

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
$wc = New-Object Net.WebClient
try {
    foreach ($id in $chosen) {
        $s = $sets[$id]
        $setDir = Join-Path $Dir $id
        "== $id"
        $n = 0
        foreach ($f in $files[$id]) {
            $n++
            $target = Join-Path $setDir ($f.Path -replace "/", [IO.Path]::DirectorySeparatorChar)
            New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
            if ((Test-Path -LiteralPath $target) -and (Sha256 $target) -eq $f.Sum) { continue }
            Write-Host -NoNewline ("`r  {0}/{1}" -f $n, $s.Count)
            $part = "$target.part"
            $wc.DownloadFile($f.Url, $part)
            if ((Sha256 $part) -ne $f.Sum) {
                Remove-Item -LiteralPath $part -Force
                throw "$($f.Path) does not match the checksum in sets.txt; it was thrown away. Nothing from it is installed."
            }
            Move-Item -LiteralPath $part -Destination $target -Force
        }
        ""
        $json = "{`n  `"name`": `"$(Json $s.Name)`",`n  `"role`": `"$($s.Role)`",`n  `"licence`": `"$(Json $s.Licence)`",`n  `"credit`": `"$(Json $s.Credit)`",`n  `"source`": `"$(Json $s.Source)`"`n}`n"
        [IO.File]::WriteAllText((Join-Path $setDir "oxiguitar-set.json"), $json, $utf8)
    }
} finally { $wc.Dispose() }

# CREDITS.txt lists every set installed here, whatever its licence.
$credits = New-Object Text.StringBuilder
[void]$credits.AppendLine("OxiGuitar sound sets installed here")
[void]$credits.AppendLine("")
foreach ($s in $sets.Values) {
    if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $Dir $s.Id) "oxiguitar-set.json"))) { continue }
    [void]$credits.AppendLine($s.Id)
    [void]$credits.AppendLine("  by:      $($s.Credit)")
    [void]$credits.AppendLine("  licence: $($s.Licence)")
    [void]$credits.AppendLine("  source:  $($s.Source)")
    if ($s.Notice) { [void]$credits.AppendLine("  credit:  $($s.Notice)") }
    [void]$credits.AppendLine("")
}
[IO.File]::WriteAllText((Join-Path $Dir "CREDITS.txt"), $credits.ToString(), $utf8)

""
"Done. Open OxiGuitar's settings to pick the sets for your tracks."
"Credits are in $(Join-Path $Dir 'CREDITS.txt')"
