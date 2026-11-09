param([string]$ScriptPath, [string]$Sandbox)
# The guide (G in the console, Help in the window, docs/GUIDE.md): every tool explained, in both
# languages, and the files on GitHub made from the same texts.
$script:fail = 0
function Check([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "ok   $what" } else { Write-Host "FAIL $what" -ForegroundColor Red; $script:fail++ }
}
if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force "$Sandbox/tmp" | Out-Null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
foreach ($fn in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) { Invoke-Expression $fn.Extent.Text }
$src = (Get-Content -LiteralPath $ScriptPath -Raw).Replace("`r`n", "`n")
$stateText = $src.Substring($src.IndexOf('#  Settings & state')); $stateText = $stateText.Substring(0, $stateText.IndexOf('#  UI helpers'))
$env:ProgramData = "$Sandbox/ProgramData"; $env:TEMP = "$Sandbox/tmp"; $env:ProgramFiles = "$Sandbox/ProgramFiles"
$DryRun = $false; $Auto = $false
Invoke-Expression $stateText
$script:FR = Get-FrenchStrings
$script:Lang = 'en'
$script:Answers = New-Object System.Collections.Queue
function Read-Host { param($Prompt) if ($script:Answers.Count -gt 0) { return $script:Answers.Dequeue() } return '' }
function Clear-Host { }

Write-Host "`n===== EVERY TOOL IS EXPLAINED =====" -ForegroundColor White
$topics = @(Get-HelpTopics)
$keys = @($topics | ForEach-Object { $_.Key })
$missing = @(@($script:MenuKeys + 'L') | Where-Object { $_ -ne 'G' -and $keys -notcontains $_ })
Check ($missing.Count -eq 0) "each option of the menu has its topic ($($topics.Count) topics; missing: $($missing -join ', '))"
Check (@($topics | Where-Object { -not $_.What -or -not $_.Changes -or -not $_.Undo }).Count -eq 0) 'each topic says what it does, what changes and how to undo it'
$inGroups = @(Get-HelpGroups | ForEach-Object { $_.Topics } | ForEach-Object { $_.Key })
Check ($inGroups.Count -eq $topics.Count -and @($inGroups | Select-Object -Unique).Count -eq $topics.Count) 'each topic is shown once, in the order of All tools'
Check (@(Get-HelpGroups | ForEach-Object { $_.Topics } | Where-Object { -not $_.Title }).Count -eq 0) 'each topic has a title (the tool''s name in the menu)'
$texts = @($topics | ForEach-Object { $_.Title; $_.What; $_.Changes; $_.Undo; $_.Steps } | Where-Object { $_ })
$noFr = @($texts | Where-Object { -not $script:FR.ContainsKey($_) -and -not (@(Get-GuiToolGroups | ForEach-Object { $_.Items } | ForEach-Object { $_[1] }) -contains $_) })
Check ($noFr.Count -eq 0) "every text is in French too ($($noFr | Select-Object -First 2))"
$dash = [string][char]0x2014
Check (@($texts + @($texts | ForEach-Object { $script:FR[$_] }) | Where-Object { "$_".Contains($dash) }).Count -eq 0) 'no long dashes'
Check ((Get-HelpTitle (@($topics | Where-Object { $_.Key -eq '29' })[0] | ForEach-Object { $_.Title = 'Virtual disks (compact VMs, WSL, Docker)'; $_ })) -eq '29. Virtual disks (compact VMs, WSL, Docker)') 'a tool''s title starts with its key in the menu'
$vd = @($topics | Where-Object { $_.Key -eq '29' })[0]
Check ($vd.Steps.Count -ge 4 -and $vd.Changes -match 'power cut' -and ($vd.Steps -join ' ') -match 'Copy the disk file') 'virtual disks: the risk and the backup, step by step'

Write-Host "`n===== IN THE CONSOLE (G) =====" -ForegroundColor White
Check ($script:MenuKeys -contains 'G') 'G is a key of the menu'
$script:Answers.Clear(); foreach ($a in @('1', '', '')) { $script:Answers.Enqueue($a) }
$out = Show-Guide 6>&1 | Out-String
Check ($out -match 'How YSO works' -and $out -match 'What it does' -and $out -match 'To undo it' -and $out -match 'Step by step') 'G lists the topics, a number shows one'
$script:Lang = 'fr'
$script:Answers.Clear(); foreach ($a in @('1', '', '')) { $script:Answers.Enqueue($a) }
$out = Show-Guide 6>&1 | Out-String
Check ($out -match 'Comment marche YSO' -and $out -match 'Ce que ça fait' -and $out -match 'Pour annuler') 'and in French'
$script:Lang = 'en'

Write-Host "`n===== ON GITHUB (docs/GUIDE.md) =====" -ForegroundColor White
$md = ConvertTo-GuideMarkdown 'en'
Check ($md -match '(?m)^### 29\. Virtual disks' -and $md -match '\[29\. Virtual disks \(compact VMs, WSL, Docker\)\]\(#29-virtual-disks-compact-vms-wsl-docker\)') 'one section per tool, with a contents list that links to it'
$fr = ConvertTo-GuideMarkdown 'fr'
Check ($fr -match '(?m)^# Guide de YSO' -and $fr -match 'Ce qui change' -and $fr -match '\(GUIDE\.md\)') 'the French guide links to the English one'
$root = Split-Path -Parent $ScriptPath
& pwsh -NoProfile -File (Join-Path $root 'tests/tools/build-guide.ps1') -ScriptPath $ScriptPath -Check | Out-Null
Check ($LASTEXITCODE -eq 0) 'docs/GUIDE.md and docs/GUIDE.fr.md are up to date (pwsh tests/tools/build-guide.ps1)'

Write-Host ("`nRESULT: {0}" -f $(if ($script:fail) { "$($script:fail) FAILURE(S)" } else { 'ALL CHECKS PASSED' })) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
