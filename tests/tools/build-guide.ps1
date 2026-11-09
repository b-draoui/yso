<#
.SYNOPSIS
    Writes docs/GUIDE.md (English) and docs/GUIDE.fr.md (French) from the guide inside YSO.ps1
    (Get-HelpTopics): the same texts as the Help page of the window and G in the console.
    Run it after changing the guide:  pwsh tests/tools/build-guide.ps1
    -Check only compares (exit 1 when the files are not up to date), for the tests.
#>
param([string]$ScriptPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'YSO.ps1'), [switch]$Check)
$ErrorActionPreference = 'Stop'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
foreach ($fn in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) { . ([scriptblock]::Create($fn.Extent.Text)) }
$line = (Get-Content -LiteralPath $ScriptPath | Where-Object { $_ -match '^\$script:MenuKeys\s+=' } | Select-Object -First 1)
Invoke-Expression $line
$script:FR = Get-FrenchStrings
$docs = Join-Path (Split-Path -Parent $ScriptPath) 'docs'
$stale = @()
foreach ($pair in @(@('en', 'GUIDE.md'), @('fr', 'GUIDE.fr.md'))) {
    $text = ConvertTo-GuideMarkdown $pair[0]
    $file = Join-Path $docs $pair[1]
    if ($Check) {
        $now = $(if (Test-Path -LiteralPath $file) { [System.IO.File]::ReadAllText($file).Replace("`r`n", "`n") } else { '' })
        if ($now -ne $text) { $stale += $pair[1] }
    } else {
        [System.IO.File]::WriteAllText($file, $text, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "written: docs/$($pair[1])"
    }
}
if ($Check) {
    if ($stale.Count) { Write-Host "not up to date: $($stale -join ', ') (run: pwsh tests/tools/build-guide.ps1)"; exit 1 }
    Write-Host 'docs/GUIDE.md and docs/GUIDE.fr.md are up to date'
}
