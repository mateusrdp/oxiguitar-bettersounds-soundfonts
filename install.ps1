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
#   .\install.ps1 -Patches all        (every instrument of each set, not only
#                                      the recommended one; without it you are
#                                      asked for each set that has others)
#   .\install.ps1 -Uninstall -Sets bass
param(
    [switch]$List,
    [string]$Sets = "",
    [string]$Dir = "",
    [string]$Patches = "",
    [switch]$Yes,
    [switch]$Uninstall
)
$ErrorActionPreference = "Stop"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }

$setsFile = if ($env:OXIGUITAR_SETS_FILE) { $env:OXIGUITAR_SETS_FILE } else { Join-Path $PSScriptRoot "sets.txt" }
if (-not (Test-Path -LiteralPath $setsFile)) { throw "cannot find $setsFile" }

if ($Patches -notin @("", "all", "recommended")) { throw "-Patches takes all or recommended" }
$catalog = [ordered]@{}
$files = @{}
$archives = @{}
$extras = @{}
$patchNames = @{}
foreach ($line in [IO.File]::ReadAllLines($setsFile, [Text.Encoding]::UTF8)) {
    if ($line.StartsWith("#") -or $line.Trim() -eq "") { continue }
    $f = $line.Split("|")
    if ($f[0] -eq "set") {
        $catalog[$f[1]] = [pscustomobject]@{ Id = $f[1]; Name = $f[2]; Role = $f[3]; Licence = $f[4]; Credit = $f[5]
            Source = $f[6]; Count = [int]$f[7]; Bytes = [int64]$f[8]; Notice = $f[9] }
        $files[$f[1]] = New-Object System.Collections.ArrayList
        $patchNames[$f[1]] = New-Object System.Collections.ArrayList
    } elseif ($f[0] -eq "extra") {
        $extras[$f[1]] = [pscustomobject]@{ Count = [int]$f[2]; Bytes = [int64]$f[3] }
    } elseif ($f[0] -eq "patch") {
        [void]$patchNames[$f[1]].Add([pscustomobject]@{ Path = $f[2]; Name = $f[3]; Recommended = ($f[4] -eq "1") })
    } elseif ($f[0] -eq "archive") {
        $archives[$f[1]] = [pscustomobject]@{ Sum = $f[2]; Url = $f[4] }
    } elseif ($f[0] -eq "file") {
        [void]$files[$f[1]].Add([pscustomobject]@{ Sum = $f[2]; Size = [int64]$f[3]; Url = $f[4]; Path = $f[5]; Extra = ($f.Length -gt 6 -and $f[6] -eq "extra") })
    }
}
function Mb($b) { "{0:N1} MB" -f ($b / 1e6) }

if ($List) {
    "{0,-18} {1,-10} {2,-12} {3}" -f "SET", "SIZE", "LICENCE", "CREDIT"
    foreach ($s in $catalog.Values) { "{0,-18} {1,-10} {2,-12} {3}" -f $s.Id, (Mb $s.Bytes), $s.Licence, $s.Credit }
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
        foreach ($s in $catalog.Values) { "  {0,-18} {1,-10} {2}" -f $s.Id, (Mb $s.Bytes), $s.Licence }
        $Sets = Read-Host "`nWhich sets? Names separated by commas, or `"all`" [all]"
        if (-not $Sets) { $Sets = "all" }
    }
}
if ($Sets -eq "all") { $chosen = @($catalog.Keys) }
else {
    $chosen = @($Sets.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($id in $chosen) { if (-not $catalog.Contains($id)) { throw "no such set: $id (see -List)" } }
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

# Which sets also get their other patches: those with some, when asked for
# all of them (-Patches all) or when you answer a; never under -Yes alone.
$withExtra = @{}
foreach ($id in $chosen) {
    if (-not $extras.Contains($id)) { continue }
    $others = $patchNames[$id].Count - 1
    if ($Patches -eq "all") { $withExtra[$id] = $true }
    elseif (-not $Patches -and -not $Yes) {
        $a = Read-Host "$id has $others other patches (+$(Mb $extras[$id].Bytes)). Install them all, or only the recommended one? [a/R]"
        if ($a -match '^(a|all)$') { $withExtra[$id] = $true }
    }
}

# What will happen, before anything does.
"These sets will be installed into:`n  $Dir`n"
$total = 0
foreach ($id in $chosen) {
    $s = $catalog[$id]
    $size = $s.Bytes
    $more = ""
    if ($withExtra[$id]) { $size += $extras[$id].Bytes; $more = ", with its $($patchNames[$id].Count - 1) other patches" }
    $total += $size
    $hosts = ($files[$id] | ForEach-Object { ([uri]$_.Url).Host } | Sort-Object -Unique) -join " "
    "  ${id}: $(Mb $size)$more, $($s.Licence), $($s.Credit)"
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
        $s = $catalog[$id]
        $setDir = Join-Path $Dir $id
        "== $id"
        # A folder this installer made earlier (it holds oxiguitar-set.json)
        # is its own: what an older version of the set left there is removed
        # below, once the new files are in.
        $owned = Test-Path -LiteralPath (Join-Path $setDir "oxiguitar-set.json")
        $n = 0
        $count = $s.Count
        if ($withExtra[$id]) { $count += $extras[$id].Count }
        $pending = New-Object System.Collections.ArrayList
        foreach ($f in $files[$id]) {
            if ($f.Extra -and -not $withExtra[$id]) { continue }
            $n++
            $target = Join-Path $setDir ($f.Path -replace "/", [IO.Path]::DirectorySeparatorChar)
            New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
            if ((Test-Path -LiteralPath $target) -and (Sha256 $target) -eq $f.Sum) { continue }
            if ($f.Url.StartsWith("archive:")) { [void]$pending.Add([pscustomobject]@{ Inner = $f.Url.Substring(8); Sum = $f.Sum; Target = $target; Path = $f.Path }); continue }
            Write-Host -NoNewline ("`r  {0}/{1}" -f $n, $count)
            $part = "$target.part"
            $wc.DownloadFile($f.Url, $part)
            if ((Sha256 $part) -ne $f.Sum) {
                Remove-Item -LiteralPath $part -Force
                throw "$($f.Path) does not match the checksum in sets.txt; it was thrown away. Nothing from it is installed."
            }
            Move-Item -LiteralPath $part -Destination $target -Force
        }
        # A set that is one archive: fetched once, and only the files listed for
        # it are taken out of it, each checked on its own.
        if ($pending.Count -gt 0) {
            $a = $archives[$id]
            if (-not $a) { throw "${id}: sets.txt has no archive for it" }
            $arc = Join-Path $Dir ".oxiguitar-archive"
            $unpack = Join-Path $Dir ".oxiguitar-unpack"
            try {
                Write-Host -NoNewline "`r  downloading the archive"
                $wc.DownloadFile($a.Url, $arc)
                if ((Sha256 $arc) -ne $a.Sum) { throw "the archive for $id does not match the checksum in sets.txt; it was thrown away." }
                if (Test-Path -LiteralPath $unpack) { Remove-Item -LiteralPath $unpack -Recurse -Force }
                New-Item -ItemType Directory -Force -Path $unpack | Out-Null
                & tar -xf $arc -C $unpack
                if ($LASTEXITCODE -ne 0) { throw "could not unpack the archive for $id (tar needs xz support)" }
                foreach ($p in $pending) {
                    $src = Join-Path $unpack ($p.Inner -replace "/", [IO.Path]::DirectorySeparatorChar)
                    if (-not (Test-Path -LiteralPath $src)) { throw "$($p.Inner) is missing from the archive" }
                    if ((Sha256 $src) -ne $p.Sum) { throw "$($p.Path) does not match the checksum in sets.txt; it was thrown away." }
                    Move-Item -LiteralPath $src -Destination $p.Target -Force
                }
            } finally {
                Remove-Item -LiteralPath $arc -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $unpack -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        ""
        if ($owned) {
            $expected = @{}
            foreach ($f in $files[$id]) { $expected[$f.Path] = $true }
            $setRoot = (Resolve-Path -LiteralPath $setDir).Path.TrimEnd("\", "/")
            foreach ($item in @(Get-ChildItem -LiteralPath $setDir -Recurse -File -Force)) {
                $rel = $item.FullName.Substring($setRoot.Length + 1) -replace "\\", "/"
                if ($rel -eq "oxiguitar-set.json" -or $expected.ContainsKey($rel)) { continue }
                Remove-Item -LiteralPath $item.FullName -Force
                "  removed $rel (not part of this version of the set)"
            }
            foreach ($d in @(Get-ChildItem -LiteralPath $setDir -Recurse -Directory -Force | Sort-Object { $_.FullName.Length } -Descending)) {
                if (-not (Get-ChildItem -LiteralPath $d.FullName -Force)) { Remove-Item -LiteralPath $d.FullName -Force }
            }
        }
        $json = "{`n  `"name`": `"$(Json $s.Name)`",`n  `"role`": `"$($s.Role)`",`n  `"licence`": `"$(Json $s.Licence)`",`n  `"credit`": `"$(Json $s.Credit)`",`n  `"source`": `"$(Json $s.Source)`""
        # With the other patches here, the file names each instrument, so the
        # MIDI plugin lists them by name and plays the recommended one.
        if ($withExtra[$id]) {
            $rec = @($patchNames[$id] | Where-Object { $_.Recommended })[0]
            $json += ",`n  `"recommended`": `"$(Json $rec.Path)`",`n  `"patches`": {"
            $json += (@($patchNames[$id] | ForEach-Object { "`n    `"$(Json $_.Path)`": `"$(Json $_.Name)`"" }) -join ",")
            $json += "`n  }"
        }
        $json += "`n}`n"
        [IO.File]::WriteAllText((Join-Path $setDir "oxiguitar-set.json"), $json, $utf8)
    }
} finally { $wc.Dispose() }

# CREDITS.txt lists every set installed here, whatever its licence.
$credits = New-Object Text.StringBuilder
[void]$credits.AppendLine("OxiGuitar sound sets installed here")
[void]$credits.AppendLine("")
foreach ($s in $catalog.Values) {
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
"Done. OxiGuitar plays each kind of track with its set from the next time it plays; Tools, Plugins, MIDI (SoundFont, SFZ), Settings changes them."
"Credits are in $(Join-Path $Dir 'CREDITS.txt')"
