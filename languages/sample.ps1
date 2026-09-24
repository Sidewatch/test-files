<#
.SYNOPSIS
    Rotates old logs and reports what was removed.
#>
[CmdletBinding()]
param(
    [string]$LogDir = "$HOME\logs",
    [int]$KeepDays = 14,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Format-Size([long]$Bytes) {
    if ($Bytes -gt 1MB) { '{0:N1} MB' -f ($Bytes / 1MB) } else { '{0:N0} KB' -f ($Bytes / 1KB) }
}

$cutoff = (Get-Date).AddDays(-$KeepDays)
$removed = 0

Get-ChildItem -Path $LogDir -Filter *.log | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
    Write-Verbose "removing $($_.Name) ($(Format-Size $_.Length))"
    if (-not $WhatIf) { Remove-Item $_.FullName }
    $removed++
}

switch ($removed) {
    0 { Write-Host "nothing older than $KeepDays days" }
    default { Write-Host "$removed file(s) removed" -ForegroundColor Green }
}
