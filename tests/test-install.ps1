# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# install.ps1 against two made-up sets served from local files (see
# test-install.sh, which does the same for install.sh). Needs no network.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$work = Join-Path ([IO.Path]::GetTempPath()) ("oxi-" + [guid]::NewGuid().ToString("N"))
$src = Join-Path $work "src"
New-Item -ItemType Directory -Force -Path (Join-Path $src "samples") | Out-Null
function Fail($m) { throw "FAILED: $m" }
function Put($rel, $text) { [IO.File]::WriteAllText((Join-Path $src $rel), $text) }
Put "one.sfz" "sfz one"; Put "samples/a.flac" "sample a"; Put "LICENSE" "licence text"; Put "two.sfz" "sfz two"
function Sum($rel) { (Get-FileHash -LiteralPath (Join-Path $src $rel) -Algorithm SHA256).Hash.ToLowerInvariant() }
function Len($rel) { (Get-Item -LiteralPath (Join-Path $src $rel)).Length }
function Url($rel) { ([uri](Join-Path $src $rel)).AbsoluteUri }
$arcDir = Join-Path $work "arc/third-1.0"
New-Item -ItemType Directory -Force -Path (Join-Path $arcDir "samples") | Out-Null
[IO.File]::WriteAllText((Join-Path $arcDir "Three.sfz"), "sfz three")
[IO.File]::WriteAllText((Join-Path $arcDir "samples/b.wav"), "sample b")
[IO.File]::WriteAllText((Join-Path $arcDir "readme.txt"), "read me, CC0")
[IO.File]::WriteAllText((Join-Path $arcDir "Other.sfz"), "not wanted")
$tarball = Join-Path $work "third.tar.xz"
& tar -C (Join-Path $work "arc") -cJf $tarball third-1.0
if ($LASTEXITCODE -ne 0) { Fail "tar cannot make a .tar.xz here" }
function AUrl($p) { ([uri]$p).AbsoluteUri }
function ASum($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function ALen($p) { (Get-Item -LiteralPath $p).Length }
$lines = @(
    "set|first|FreePats|electric-guitars|CC0 1.0|Somebody `"Q`" (First)|https://example.org/first|3|0|",
    "file|first|$(Sum 'one.sfz')|$(Len 'one.sfz')|$(Url 'one.sfz')|First Guitar.sfz",
    "file|first|$(Sum 'samples/a.flac')|$(Len 'samples/a.flac')|$(Url 'samples/a.flac')|samples/a.flac",
    "file|first|$(Sum 'LICENSE')|$(Len 'LICENSE')|$(Url 'LICENSE')|LICENSE",
    "set|second|FreePats|drums|CC BY 4.0|Somebody Else|https://example.org/second|1|7|Drums by Example.org",
    "file|second|$(Sum 'two.sfz')|$(Len 'two.sfz')|$(Url 'two.sfz')|Second Kit.sfz",
    "set|third|FreePats|acoustic-guitars|GPL|Somebody Three|https://example.org/third|3|$(ALen $tarball)|",
    "archive|third|$(ASum $tarball)|$(ALen $tarball)|$(AUrl $tarball)",
    "file|third|$(ASum (Join-Path $arcDir 'Three.sfz'))|$(ALen (Join-Path $arcDir 'Three.sfz'))|archive:third-1.0/Three.sfz|Third.sfz",
    "file|third|$(ASum (Join-Path $arcDir 'samples/b.wav'))|$(ALen (Join-Path $arcDir 'samples/b.wav'))|archive:third-1.0/samples/b.wav|samples/b.wav",
    "file|third|$(ASum (Join-Path $arcDir 'readme.txt'))|$(ALen (Join-Path $arcDir 'readme.txt'))|archive:third-1.0/readme.txt|readme.txt"
)
[IO.File]::WriteAllLines((Join-Path $work "sets.txt"), $lines)
$env:OXIGUITAR_SETS_FILE = Join-Path $work "sets.txt"
$out = Join-Path $work "out"
try {
    if (-not ((& "$root/install.ps1" -List) -match '^first ')) { Fail "-List does not show the first set" }
    & "$root/install.ps1" -Yes -Dir $out | Out-Null
    if ([IO.File]::ReadAllText((Join-Path $out "first/First Guitar.sfz")) -ne "sfz one") { Fail "entry missing" }
    if ([IO.File]::ReadAllText((Join-Path $out "first/samples/a.flac")) -ne "sample a") { Fail "sample missing" }
    $json = [IO.File]::ReadAllText((Join-Path $out "first/oxiguitar-set.json"))
    if ($json -notmatch '"role": "electric-guitars"') { Fail "role missing" }
    if (-not $json.Contains('Somebody \"Q\" (First)')) { Fail "credit not escaped" }
    $credits = [IO.File]::ReadAllText((Join-Path $out "CREDITS.txt"))
    if (-not $credits.Contains("Drums by Example.org")) { Fail "notice missing from CREDITS.txt" }
    if ([IO.File]::ReadAllText((Join-Path $out "third/Third.sfz")) -ne "sfz three") { Fail "archive entry missing" }
    if ([IO.File]::ReadAllText((Join-Path $out "third/samples/b.wav")) -ne "sample b") { Fail "archive sample missing" }
    if (Test-Path -LiteralPath (Join-Path $out "third/Other.sfz")) { Fail "a file that is not listed was kept" }
    if (Test-Path -LiteralPath (Join-Path $out ".oxiguitar-archive")) { Fail "the archive was left behind" }
    & "$root/install.ps1" -Yes -Sets first -Dir $out | Out-Null   # again: nothing changes
    Put "two.sfz" "tampered"
    Remove-Item -Recurse -Force (Join-Path $out "second")
    $refused = $false
    try { & "$root/install.ps1" -Yes -Sets second -Dir $out | Out-Null } catch { $refused = $_.Exception.Message -match "checksum" }
    if (-not $refused) { Fail "a bad checksum was not refused" }
    if (Test-Path -LiteralPath (Join-Path $out "second/Second Kit.sfz")) { Fail "the bad file was kept" }
    & "$root/install.ps1" -Yes -Uninstall -Sets first -Dir $out | Out-Null
    if (Test-Path -LiteralPath (Join-Path $out "first")) { Fail "uninstall left the set" }
    $unknown = $false
    try { & "$root/install.ps1" -Yes -Sets nope -Dir $out | Out-Null } catch { $unknown = $true }
    if (-not $unknown) { Fail "unknown set accepted" }
    "install.ps1: all checks passed"
} finally { Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue }
