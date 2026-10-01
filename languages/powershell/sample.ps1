#!/usr/bin/env pwsh
# PowerShell 7.5 — syntax showcase
#requires -Version 7.2
#requires -Modules @{ ModuleName = 'Microsoft.PowerShell.Utility'; ModuleVersion = '7.0.0' }

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Management.Automation
using module Microsoft.PowerShell.Utility
using assembly System.Net.Http

<#
.SYNOPSIS
    Audits warehouse stock levels and rotates old logs.
.DESCRIPTION
    Showcase of PowerShell syntax: comment-based help, parameters, strings,
    here-strings, classes, enums, pipelines, error handling and workflows.
.PARAMETER LogDir
    Directory holding the *.log files.
.PARAMETER KeepDays
    Number of days to keep.
.EXAMPLE
    ./sample.ps1 -LogDir ./logs -KeepDays 7 -WhatIf
.NOTES
    TODO: support compressed archives
    FIXME: long paths on Windows
#>

# ── Comments ──
# A line comment
<# an inline block comment #> Write-Verbose 'after block'
<#
    multi-line
    block comment <# not nested in PowerShell #>

# ── Parameters and attributes ──
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByDir')]
[OutputType([System.Collections.Hashtable])]
param(
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByDir', ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$LogDir = "$HOME\logs",

    [ValidateRange(1, 365)]
    [int]$KeepDays = 14,

    [ValidateSet('Debug', 'Info', 'Warn')]
    [string]$Level = 'Info',

    [ValidatePattern('^[A-Z]{2}-\d{4}$')]
    [string[]]$Skus = @('AC-1001', 'AC-1002'),

    [Alias('Dry')]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Counter = 0
$global:Warehouse = 'north'
$env:INVENTORY_HOME = Join-Path $HOME 'inventory'
${weird name} = 'braced variable'
$null = $true -and $false

# ── Enums, classes and types ──
enum Status : int {
    Pending = 0
    Paid = 1
    Cancelled = 2
}

[Flags()] enum Access { None = 0; Read = 1; Write = 2; Admin = 4 }

class Product {
    [string]$Sku
    [decimal]$Price
    hidden [int]$Quantity = 0
    static [int]$Created = 0

    Product([string]$sku, [decimal]$price) {
        $this.Sku = $sku
        $this.Price = $price
        [Product]::Created++
    }

    [decimal] Total() { return $this.Price * $this.Quantity }

    static [Product] Parse([string]$line) {
        $parts = $line -split ','
        return [Product]::new($parts[0], [decimal]$parts[1])
    }

    [string] ToString() { return "$($this.Sku) @ $($this.Price)" }
}

class Perishable : Product {
    [datetime]$Expires
    Perishable([string]$sku, [decimal]$price, [datetime]$expires) : base($sku, $price) {
        $this.Expires = $expires
    }
}

# ── Numbers ──
$int = 42
$neg = -17
$hex = 0xFF_EA
$bin = 0b1010_0101
$float = 3.14159
$exp = 1.5e-3
$big = 123456789012L
$dec = 19.99d
$ulong = 18446744073709551615ul
$short = 12s
$sbyte = 8y
$kb = 4KB; $mb = 2MB; $gb = 1GB; $tb = 1TB; $pb = 1PB
$cplx = [double]::NaN + [double]::PositiveInfinity

# ── Strings ──
$single = 'It''s a single-quoted string; $notExpanded\n'
$double = "Tab`t newline`n quote`" dollar`$ backtick`` bell`a unicode`u{1F4E6} null`0"
$interp = "Name: $LogDir, count: $($Skus.Count), env: $env:HOME, prop: $($global:Warehouse.ToUpper())"
$simple = "Value $int and ${weird name} and $script:Counter and $Skus[0]"
$here = @"
Warehouse report for $global:Warehouse
  Items: $($Skus -join ', ')
  Escaped: `$literal and "quotes" stay as-is
"@
$hereRaw = @'
Raw here-string: $nothing is expanded `n here
'@
$fmt = '{0:N1} MB of {1} ({2:P0}) [{3,8:C2}] {{braces}}' -f 12.5, 'disk', 0.42, 19.99
$charArray = [char[]]'abc'
$ch = [char]0x41

# ── Collections ──
$array = @(1, 2, 3)
$range = 1..10
$empty = @()
$nested = @(@(1, 2), @(3, 4))
$hash = @{
    Sku      = 'AC-1001'
    Quantity = 25
    'Odd Key' = $true
    Nested   = @{ Inner = $null }
}
$ordered = [ordered]@{ first = 1; second = 2 }
$typed = [System.Collections.Generic.List[string]]::new()
$typed.Add('item')
$splat = @{ Path = $HOME; Recurse = $true; Filter = '*.log' }
$sb = { param($x, $y) $x + $y }
$sorted = $array | Sort-Object -Descending
$sub = $array[1..2]
$last = $array[-1]
$member = $hash.Sku
$dynamic = $hash['Odd Key']
$sbCall = & $sb 1 2
$dot = . $sb 3 4

# ── Operators ──
$a = 5; $b = 3
$sum = $a + $b; $diff = $a - $b; $prod = $a * $b; $quot = $a / $b; $mod = $a % $b
$a += 1; $a -= 1; $a *= 2; $a /= 2; $a %= 7; $a++; $a--; ++$a; --$a
$cmp = ($a -eq $b) -or ($a -ne $b) -and ($a -gt $b) -xor ($a -ge $b) -or -not ($a -lt $b) -or ($a -le $b)
$ci = 'ABC' -ceq 'abc'; $ci2 = 'abc' -ieq 'ABC'; $like = 'warehouse' -like 'ware*'; $nl = 'x' -notlike 'y*'
$match = 'AC-1001' -match '^(?<prefix>[A-Z]+)-(?<num>\d+)$'
$prefix = $Matches['prefix']
$rep = 'a-b-c' -replace '-', '_'
$spl = 'a,b;c' -split '[,;]'
$joined = 'a', 'b' -join '+'
$contains = $array -contains 2; $notin = 3 -notin $array; $inop = 2 -in $array
$type = $a -is [int]; $cast = $a -as [string]; $isnot = $a -isnot [string]
$bits = (5 -band 3) -bor (1 -shl 4) -bxor 2; $shr = 256 -shr 2; $bnot = -bnot 5
$fmtop = '{0:D4}' -f 7
$ternary = $a -gt 3 ? 'big' : 'small'
$coalesce = $undefinedVar ?? 'default'
$undefinedVar ??= 'assigned'
$safe = $hash?.Nested?.Inner
Get-Process -Id $PID && Write-Output 'ok' || Write-Output 'failed'
$sub = $(Get-Date).Year
$static = [Math]::Pow(2, 10) + [int]::MaxValue
Start-Job { Get-Date } | Out-Null
$unary = -$a + +$b
$ref = [ref]$a
$splatCall = Get-ChildItem @splat

# ── Functions ──
function Format-Size {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [long]$Bytes,
        [int]$Precision = 1
    )
    begin   { $i = 0 }
    process {
        if ($Bytes -gt 1MB) { '{0:N1} MB' -f ($Bytes / 1MB) }
        elseif ($Bytes -gt 1KB) { '{0:N0} KB' -f ($Bytes / 1KB) }
        else { "$Bytes B" }
        $i++
    }
    end     { Write-Verbose "formatted $i value(s)" }
}

filter Select-Paid { if ($_.Status -eq [Status]::Paid) { $_ } }

function Get-Stock([string]$Sku, [int[]]$Levels) {
    if (-not $Sku) { throw [System.ArgumentException]::new('Sku is required') }
    return @{ Sku = $Sku; Levels = $Levels }
}

function script:Private-Helper { 'private' }
function global:Public-Helper { 'public' }
Set-Alias -Name fs -Value Format-Size
New-Item -Path function:\Inline -Value { 'inline' } | Out-Null

# ── Control flow ──
if ($KeepDays -gt 30) {
    Write-Warning 'Keeping a long time'
} elseif ($KeepDays -gt 7) {
    Write-Host 'About right'
} else {
    Write-Host 'Short retention'
}

switch -Regex -CaseSensitive ($Level) {
    '^Deb' { 'debug mode'; continue }
    'Info'  { 'info mode'; break }
    default { 'other' }
}

switch ($removed) {
    0 { Write-Host "nothing older than $KeepDays days" }
    { $_ -gt 100 } { Write-Host 'a lot' }
    default { Write-Host "$removed file(s) removed" -ForegroundColor Green }
}

for ($i = 0; $i -lt 3; $i++) { Write-Debug "i=$i" }
foreach ($sku in $Skus) { if ($sku -eq 'skip') { continue }; Write-Output $sku }
$array | ForEach-Object { $_ * 2 } | Where-Object { $_ -gt 2 } | Out-Null
$array.ForEach({ $_ + 1 }); $array.Where({ $_ -gt 1 })
$n = 0
while ($n -lt 3) { $n++ }
do { $n-- } while ($n -gt 0)
do { $n++ } until ($n -ge 2)
:outer foreach ($x in 1..3) {
    foreach ($y in 1..3) {
        if ($y -eq 2) { continue outer }
        if ($x -eq 3) { break outer }
    }
}

# ── Error handling ──
try {
    $cutoff = (Get-Date).AddDays(-$KeepDays)
    Get-ChildItem -Path $LogDir -Filter *.log -ErrorAction Stop |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        ForEach-Object {
            Write-Verbose "removing $($_.Name) ($(Format-Size $_.Length))"
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                if (-not $DryRun) { Remove-Item -LiteralPath $_.FullName }
            }
            $script:Counter++
        }
}
catch [System.IO.DirectoryNotFoundException] {
    Write-Error "Missing directory: $($_.Exception.Message)"
}
catch [System.UnauthorizedAccessException], [System.Security.SecurityException] {
    Write-Warning $_
}
catch {
    Write-Error -ErrorRecord $_
    throw
}
finally {
    Write-Host 'cleanup done'
}

trap [System.DivideByZeroException] { Write-Host 'div by zero'; continue }

# ── Pipelines, redirection, special variables ──
Get-Process | Where-Object CPU -gt 10 | Sort-Object CPU -Descending | Select-Object -First 3 Name, @{ N = 'MB'; E = { [math]::Round($_.WS / 1MB, 1) } }
Write-Output 'text' > out.txt
Write-Output 'more' >> out.txt
Get-Content missing.txt 2> errors.txt
Get-Content missing.txt 2>&1 | Out-Null
Write-Output 'all' *> all.txt
Write-Host $?, $LASTEXITCODE, $PSScriptRoot, $PSCommandPath, $MyInvocation.MyCommand, $args.Count, $_, $input, $PID, $PSVersionTable.PSVersion, $true, $false, $null, $Error[0], $Host.Name, $Home, $PWD, $ExecutionContext
$using:Counter
Invoke-Command -ScriptBlock { $using:a } -ComputerName 'host.example.com'
Invoke-Expression 'Get-Date'
Add-Type -TypeDefinition 'public class Dummy { public int X; }'
[Console]::WriteLine('static call')
[System.IO.Path]::Combine('a', 'b')
[void][System.Console]::Out
[string]::Join(',', 'x', 'y')
New-Object -TypeName System.Text.StringBuilder -ArgumentList 16 | Out-Null

# ── Providers, wildcards, paths ──
Get-ChildItem -Path C:\Windows\*.dll, ~/logs/*.log, ./relative/path, HKLM:\Software, Env:\PATH, Variable:\a
Set-Location -Path .. ; Push-Location ./logs ; Pop-Location

# ── Import / dot-sourcing ──
Import-Module -Name Pester -MinimumVersion 5.0 -ErrorAction SilentlyContinue
. "$PSScriptRoot/helpers.ps1"

# ── Data section, dynamic keywords ──
data localized { ConvertFrom-StringData @'
greeting = Hello
farewell = Goodbye
'@ }

Write-Host "$($script:Counter) file(s) removed" -ForegroundColor Green
# ── PowerShell 7.x additions ──
# Pipeline chain operators, background operator, null-conditional access
Test-Path $HOME && Write-Output 'home exists'
Test-Path /nope || Write-Output 'no such path'
Get-Date &
$maybe = $null
$value = $maybe?.Length
$item = $array?[0]
$name = ${maybe}?.Name
$maybe ??= 'filled'

# Ternary and null-coalescing assignment
$size = $array.Count -gt 2 ? 'many' : 'few'

# ForEach-Object -Parallel with $using:
1..3 | ForEach-Object -Parallel { "item $_ of $using:KeepDays" } -ThrottleLimit 3
$job = Start-ThreadJob -ScriptBlock { Get-Date }
Receive-Job $job -Wait -AutoRemoveJob

# Function with every block, including clean (7.3), dynamicparam and nested attributes
function Get-Everything {
    [CmdletBinding(DefaultParameterSetName = 'Name', PositionalBinding = $false)]
    [Alias('gev')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'A name')]
        [Alias('N', 'Title')]
        [ValidateScript({ Test-Path $_ -IsValid })]
        [ValidateLength(1, 64)]
        [ValidateCount(1, 5)]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [AllowNull()]
        [ArgumentCompleter({ param($cmd, $param, $word) 'alpha', 'beta' | Where-Object { $_ -like "$word*" } })]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'Id')]
        [ValidateRange('Positive')]
        [int]$Id,

        [switch]$Force,
        [Parameter(DontShow)][object]$Hidden = $null
    )
    dynamicparam {
        $dict = [RuntimeDefinedParameterDictionary]::new()
        return $dict
    }
    begin { $count = 0 }
    process { $count++; $PSItem }
    end { "done $count" }
    clean { Write-Verbose 'cleanup' }
}

# Classes: inheritance, interfaces, static members, constructors chaining, hidden
class Animal : System.IComparable {
    [string]$Name
    static [int]$Count
    hidden [string]$Secret = 'x'
    Animal() : this('unnamed') { }
    Animal([string]$name) { $this.Name = $name; [Animal]::Count++ }
    [int] CompareTo([object]$other) { return $this.Name.CompareTo($other.Name) }
    [void] Speak() { Write-Host "$($this.Name) makes a sound" }
    static [Animal] Create([string]$n) { return [Animal]::new($n) }
}
class Dog : Animal {
    Dog([string]$name) : base($name) { }
    [void] Speak() { ([Animal]$this).Speak(); Write-Host 'Woof' }
}
[Dog]::new('Rex').Speak()

# Enums with flags and explicit types
enum Color : byte { Red = 1; Green = 2; Blue = 4 }
[Flags()] enum Perm { None = 0; Read = 1; Write = 2; Execute = 4; All = 7 }
[Perm]'Read, Write'
[Color]::Red -as [int]

# Strings: format, subexpressions, escapes, verbatim and ANSI
$ansi = "$($PSStyle.Foreground.Red)red$($PSStyle.Reset) `e[1mbold`e[0m"
$esc = "`a`b`f`r`v`'`"`#"
$verbatim = '--% passes through'
$sub = "Sum: $(1 + 2) and array: $($array[0]) and method: $($Skus.Where({ $_ })[0])"
$hereCombo = @"
$($PSVersionTable.PSVersion) -- @"nested"@ -- $env:HOME
"@
$wildcard = 'a*b?[c-d]'
$regex = [regex]::new('(?<y>\d{4})-(?<m>\d{2})')
$ms = [regex]::Matches('2025-10', '\d+')

# Splatting, argument-list and call forms
$params = @{ Name = 'x'; Force = $true }
Get-Everything @params
Get-Everything -Name 'a', 'b' -Force:$false
Get-Everything -Name:'a'
Get-Everything --% %PATH% | Out-Null
& 'C:\Program Files\tool.exe' --flag "value with space"
& { param($p) $p } 42
& (Get-Command Get-Date) -Format 'yyyy'
. { $leaked = 1 }
$cmd = Get-Command -Name Get-Date
$fn = ${function:Get-Everything}
${env:PATH}
${Env:HOME}
@($null) | Measure-Object

# Type accelerators, casting and generic types
[int]'42'; [datetime]'2025-01-01'; [guid]::NewGuid(); [version]'7.5.0'; [bigint]::Parse('1'); [uri]'https://example.com'
[System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[int]]]::new()
[ordered]@{ a = 1 }; [pscustomobject]@{ A = 1; B = 2 }; [psobject]; [xml]'<a/>'; [regex]; [scriptblock]; [hashtable]; [array]; [bool]; [byte[]]
[Nullable[int]]$null
[ValidateSet('a', 'b')][string]$constrained = 'a'
[int[]]$typedArray = 1, 2, 3
[ref]$ref

# Comparison and bitwise operators (all spellings)
1 -eq 1; 1 -ne 2; 1 -lt 2; 1 -le 2; 1 -gt 0; 1 -ge 0
'a' -ceq 'a'; 'a' -cne 'b'; 'a' -clike 'a*'; 'a' -cnotlike 'b*'; 'a' -cmatch 'a'; 'a' -cnotmatch 'b'
'a' -inotmatch 'b'; 'a' -ilike 'A'; 'a' -inotlike 'B'
1 -iin 1, 2; 1 -cin 1, 2; 1 -cnotin 2; 1, 2 -ccontains 1; 1, 2 -cnotcontains 3; 1, 2 -icontains 1; 1, 2 -inotcontains 3
'abc' -creplace 'B', 'x'; 'abc' -ireplace 'B', 'x'; 'a b' -csplit ' '; 'a b' -isplit ' '
-split 'a b c'; -join ('a', 'b')
-not $true; !$true; -bnot 1
1 -xor 0; 1 -shl 2; 8 -shr 1; 5 -band 1; 5 -bor 2; 5 -bxor 1
$obj -is [object]; $obj -isnot [string]; $obj -as [int]

# Labels, flow, and statement forms
:retry while ($true) { while ($true) { break retry } }
foreach ($i in 1..3) { if ($i -eq 2) { continue }; $i }
for (;;) { break }
for ($i = 0, $j = 10; $i -lt $j; $i++, $j--) { }
switch -Wildcard ('abc') { 'a*' { 'starts with a' } '*c' { 'ends with c' } }
switch -Exact -CaseSensitive ('A') { 'A' { 'upper' } default { 'other' } }
switch -File ./values.txt { 'x' { 'found' } }
switch ($PSVersionTable.PSEdition) { 'Core' { 'core' } 'Desktop' { 'desktop' } }
if (($x = 5) -gt 3) { 'assigned in condition' }
try { throw 'text' } catch { $_.Exception.Message } finally { }
try { 1 / 0 } catch [DivideByZeroException] { 'div' } catch [System.ArgumentException], [System.IO.IOException] { 'arg' }
throw [System.NotImplementedException]::new()
return

# Misc commands and aliases
ls; dir; gci; cat; echo hi; ps; kill 0; cls; % { $_ }; ? { $_ }; gm; select -First 1
$PSDefaultParameterValues = @{ 'Get-ChildItem:Force' = $true }
$PSStyle.OutputRendering = 'Ansi'
[Environment]::SetEnvironmentVariable('X', '1', 'Process')
Register-ArgumentCompleter -CommandName Get-Everything -ParameterName Name -ScriptBlock { 'a' }
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Write-Host 'bye' } | Out-Null
$ExecutionContext.SessionState.PSVariable.Set('dyn', 1)
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Write-Progress -Activity 'Working' -Status '50%' -PercentComplete 50
Write-Information 'info' -InformationAction Continue
Write-Host "`e[32mgreen`e[0m"
exit 0
