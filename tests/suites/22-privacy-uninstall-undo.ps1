param([string]$ScriptPath, [string]$Sandbox)
# Privacy & ads (30), Uninstall apps (31), Undo YSO changes (32), the icon next to the clock and
# the Microsoft Store package: every change written down and put back, leftovers found without
# touching another app, alerts at most once a week. The registry is a table in memory here.
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
$env:ProgramData = "$Sandbox/ProgramData"; $env:TEMP = "$Sandbox/tmp"; $env:ProgramFiles = "$Sandbox/ProgramFiles"; $env:WINDIR = "$Sandbox/Windows"
$DryRun = $false; $Auto = $false
Invoke-Expression $stateText
$script:FR = Get-FrenchStrings
$script:Lang = 'en'
Import-Settings
New-Item -ItemType Directory -Force $script:DataDir | Out-Null

# --- the registry, in memory: "key|name" -> @{ Type; Data }, and the keys that exist ---
$script:Reg = @{}
$script:RegKeys = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
function Set-FakeReg([string]$Path, [string]$Name, $Data, [string]$Type = 'DWord') { [void]$script:RegKeys.Add($Path); $script:Reg["$Path|$Name"] = @{ Type = $Type; Data = $Data } }
function Get-FakeReg([string]$Path, [string]$Name) { return $script:Reg["$Path|$Name"] }
function Read-RegValue([string]$Path, [string]$Name) {
    $v = $script:Reg["$Path|$Name"]
    return [pscustomobject]@{ KeyExisted = $script:RegKeys.Contains($Path); Existed = [bool]$v; Type = $(if ($v) { $v.Type } else { '' }); Data = $(if ($v) { $v.Data } else { $null }) }
}
function Write-RegValue([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') { Set-FakeReg $Path $Name $Value $Type }
function Remove-RegValue([string]$Path, [string]$Name) { [void]$script:Reg.Remove("$Path|$Name") }
function Get-MissingRegParent([string]$Path) { if ($script:RegKeys.Contains($Path)) { return '' } return $Path }
function Remove-EmptyRegKeys([string]$Path, [string]$Top) {
    if (-not $Top) { return }
    if (@($script:Reg.Keys | Where-Object { $_.StartsWith("$Path|") }).Count -eq 0) { [void]$script:RegKeys.Remove($Path) }
}
$script:Answers = New-Object System.Collections.Queue
function Read-Host { param($Prompt) if ($script:Answers.Count -gt 0) { return $script:Answers.Dequeue() } return '' }
function Clear-Host { }
function Answer([object[]]$List) { $script:Answers.Clear(); foreach ($a in $List) { $script:Answers.Enqueue($a) } }
function Get-Process { }

Write-Host "`n===== THE LIST OF CHANGES =====" -ForegroundColor White
$k = 'HKCU:\Software\Test'
Set-FakeReg $k 'Existing' 1
Set-FakeReg $k 'Gone' 'hello' 'String'
Set-FakeReg 'HKCU:\Software\Startup' 'App' ([Convert]::ToBase64String([byte[]](2, 0, 0, 0))) 'Binary'
$c = New-ChangeEntry 'Privacy & ads' 'Switched off: {0}' @(, [string[]]@('Ad tracking', 'Copilot in Windows'))
Set-RegValueLogged $c $k 'Existing' 0
Set-RegValueLogged $c 'HKLM:\SOFTWARE\Policies\New' 'Made' 1
Set-RegValueLogged $c $k 'Existing' 5
Remove-RegValueLogged $c $k 'Gone'
Remove-RegValueLogged $c $k 'NeverThere'
Set-RegValueLogged $c 'HKCU:\Software\Startup' 'App' ([Convert]::ToBase64String([byte[]](3, 0, 0, 0))) 'Binary'
Check (@($c.Items).Count -eq 5) "each change is written down before it is made, a value removed that was not there is not ($(@($c.Items).Count))"
Add-ChangeEntry $c
Add-ChangeEntry (New-ChangeEntry 'Power plan' 'nothing')
$j = @(Read-ChangeJournal)
Check ($j.Count -eq 1 -and @($j[0].Items).Count -eq 5) 'it is saved to changes.json; a change with nothing in it is not'
Check ((Get-ChangeTitle $j[0]) -eq 'Switched off: Ad tracking, Copilot in Windows') "a list in the title is joined ($(Get-ChangeTitle $j[0]))"
$script:Lang = 'fr'
Check ((Get-ChangeTitle $j[0]) -eq 'Désactivé : Suivi publicitaire, Copilot dans Windows') "and translated when shown ($(Get-ChangeTitle $j[0]))"
$script:Lang = 'en'
$r = Undo-ChangeEntry $j[0]
Check ($r.Ok -eq 5 -and $r.Failed -eq 0) 'undo puts back every item'
Check ((Get-FakeReg $k 'Existing').Data -eq 1) 'a value changed twice gets its very first state back'
Check ($null -eq (Get-FakeReg 'HKLM:\SOFTWARE\Policies\New' 'Made') -and -not $script:RegKeys.Contains('HKLM:\SOFTWARE\Policies\New')) 'a value YSO created goes, and so does the empty key YSO made for it'
Check ((Get-FakeReg $k 'Gone').Data -eq 'hello' -and (Get-FakeReg $k 'Gone').Type -eq 'String') 'a removed value comes back with its kind'
Check ((Get-FakeReg 'HKCU:\Software\Startup' 'App').Data -eq [Convert]::ToBase64String([byte[]](2, 0, 0, 0))) 'binary values (startup on/off) come back byte for byte'
$many = @(for ($i = 0; $i -lt 305; $i++) { New-ChangeEntry 'Power plan' 'x' })
Save-ChangeJournal $many
Check (@(Read-ChangeJournal).Count -eq 300) 'the last 300 changes are kept'
Set-Content -LiteralPath $script:JournalPath -Value '{ broken'
Check (@(Read-ChangeJournal).Count -eq 0) 'a damaged list gives an empty one, not an error'
Remove-Item -LiteralPath $script:JournalPath -Force

Write-Host "`n===== UNDO YSO CHANGES (32) =====" -ForegroundColor White
Set-FakeReg $k 'Existing' 1
$c = New-ChangeEntry 'Startup programs' '{0} no longer starts with Windows' @('Spotify')
Set-RegValueLogged $c $k 'Existing' 0
Add-ChangeEntry $c
Answer @('1', 'y', '', '')
$out = Show-UndoCenter 6>&1 | Out-String
Check ((Get-FakeReg $k 'Existing').Data -eq 1) 'choosing a change and saying yes puts it back'
$j = @(Read-ChangeJournal)
Check ($j.Count -eq 1 -and $j[0].Undone) 'it is marked undone in the list'
Check ($out -match 'Spotify no longer starts with Windows') 'the list says what changed, in words'
Answer @('1', '', '')
$out = Show-UndoCenter 6>&1 | Out-String
Check ($out -match 'Already undone') 'an undone change is not undone twice'
Remove-Item -LiteralPath $script:JournalPath -Force
$out = Show-UndoCenter 6>&1 | Out-String
Check ($out -match 'Nothing yet') 'with nothing written down, it says where changes come from'

Write-Host "`n===== PRIVACY & ADS (30) =====" -ForegroundColor White
$script:Build = 22631
$g = @(Get-PrivacyGroups)
Check (@($g | ForEach-Object { $_.Id } | Select-Object -Unique).Count -eq $g.Count) "every group has its own id ($($g.Count) groups)"
Check (@($g | Where-Object { $_.Id -eq 'recall' }).Count -eq 0) 'Recall is not offered before Windows 11 24H2'
$script:Build = 26100
$g = @(Get-PrivacyGroups)
Check (@($g | Where-Object { $_.Id -eq 'recall' }).Count -eq 1) 'and offered on 24H2'
$vals = @($g | ForEach-Object { $_.Values } )
Check (@($vals | Where-Object { @($_).Count -ne 4 -or "$($_[2])" -notmatch '^[01]$' -or "$($_[0])" -notmatch '^HK(CU|LM):\\' }).Count -eq 0) "every value: key, name, 0 or 1, default ($($vals.Count) values)"
Check (@($vals | Where-Object { "$($_[0])\$($_[1])" -match 'Defender|WindowsUpdate|WindowsStore|Spynet' }).Count -eq 0) 'nothing about Defender, Windows Update or the Store'
Check ((@($g | Where-Object { $_.Recommended } | ForEach-Object { $_.Id }) -join ',') -eq 'ads,lock,bing,tracking') 'the recommended ones: ads, lock screen, Bing, ad tracking'
$script:Reg.Clear()
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
Set-FakeReg $cdm 'SoftLandingEnabled' 1
Check (-not (Test-PrivacyGroup $g[0])) 'on a new PC, ads are on'
Answer @('')
[void](Show-PrivacySettings 6>&1)
Check ($script:Reg.Count -eq 1 -and @(Read-ChangeJournal).Count -eq 0) 'Cancel: nothing changes'
Answer @('1', 'A', 'y', 'n')
$out = Show-PrivacySettings 6>&1 | Out-String
Check ((Test-PrivacyGroup $g[0]) -and (Get-FakeReg $cdm 'SoftLandingEnabled').Data -eq 0) 'tick one line and Apply: it is switched off'
Check ($out -match 'managed by your organization') 'with a word about "managed by your organization" for policies'
$j = @(Read-ChangeJournal)
Check ($j.Count -eq 1 -and (Get-ChangeTitle $j[0]) -eq 'Switched off: Ads and suggestions in Windows' -and @($j[0].Items).Count -eq @($g[0].Values).Count) 'written down as one change, with every value'
Answer @('A', '')
$out = Show-PrivacySettings 6>&1 | Out-String
Check ($out -match 'Nothing to change') 'Apply with nothing new: nothing to do'
Answer @('1', 'A', 'y', 'n')
[void](Show-PrivacySettings 6>&1)
Check ((Get-FakeReg $cdm 'SoftLandingEnabled').Data -eq 1 -and $null -eq (Get-FakeReg 'HKLM:\Software\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent')) 'untick and Apply: the Windows default is back (policies removed)'
Check ((Get-ChangeTitle @(Read-ChangeJournal)[-1]) -eq 'Back on: Ads and suggestions in Windows') 'also written down'
$script:Reg.Clear(); Remove-Item -LiteralPath $script:JournalPath -Force
Answer @('R', 'A', 'y', 'n')
[void](Show-PrivacySettings 6>&1)
$on = @($g | Where-Object { Test-PrivacyGroup $_ } | ForEach-Object { $_.Id }) -join ','
Check ($on -eq 'ads,lock,bing,tracking') "Tick the recommended ones: exactly those ($on)"
$r = Undo-ChangeEntry @(Read-ChangeJournal)[-1]
Check ($r.Failed -eq 0 -and $script:Reg.Count -eq 0) 'and Undo leaves the registry exactly as it was'
$script:DryRun = $true
Answer @('1', 'A')
[void](Show-PrivacySettings 6>&1)
Check ($script:Reg.Count -eq 0) 'analyze-only mode: nothing changes'
$script:DryRun = $false

Write-Host "`n===== INSTALLED APPS =====" -ForegroundColor White
$base = @{ DisplayName = 'Mozilla Firefox (x64 en-US)'; UninstallString = '"C:\Program Files\Mozilla Firefox\uninstall\helper.exe"'; Publisher = 'Mozilla'; DisplayVersion = '147.0'; EstimatedSize = 250000; InstallDate = '20260115'; InstallLocation = 'C:\Program Files\Mozilla Firefox'; DisplayIcon = 'C:\Program Files\Mozilla Firefox\firefox.exe,0' }
$a = ConvertTo-InstalledApp $base 'HKLM:\x\Firefox' 'Mozilla Firefox' 'everyone'
Check ($a -and $a.Size -eq 250000KB -and $a.Installed -eq [datetime]'2026-01-15' -and $a.Icon -eq 'C:\Program Files\Mozilla Firefox\firefox.exe') 'an app: name, size, install date, its program'
$x = $base.Clone(); $x.SystemComponent = 1
$y = $base.Clone(); $y.ParentKeyName = 'Office'
$z = $base.Clone(); $z.Remove('UninstallString')
$u = $base.Clone(); $u.ReleaseType = 'Security Update'
Check ($null -eq (ConvertTo-InstalledApp $x 'k' 'a' 'x') -and $null -eq (ConvertTo-InstalledApp $y 'k' 'a' 'x') -and $null -eq (ConvertTo-InstalledApp $z 'k' 'a' 'x') -and $null -eq (ConvertTo-InstalledApp $u 'k' 'a' 'x')) 'Windows components, parts of an app, updates and entries without uninstaller are not listed'
Check ($null -eq (ConvertTo-InstalledApp $base 'k' 'YSO' 'x')) 'YSO itself is not listed'
$m = Get-UninstallCommand 'MsiExec.exe /I{23170F69-40C1-2702-2408-000001000000}'
Check ($m.File -match 'msiexec\.exe$' -and $m.Arguments -eq '/x {23170F69-40C1-2702-2408-000001000000}') 'Windows Installer apps: msiexec /x with their code (never /I)'
$m = Get-UninstallCommand '"C:\Program Files\App\uninst.exe" /S /quiet'
Check ($m.File -eq 'C:\Program Files\App\uninst.exe' -and $m.Arguments -eq '/S /quiet') 'a quoted program and its arguments'
$m = Get-UninstallCommand 'C:\Program Files (x86)\Some App\unins000.exe /SILENT'
Check ($m.File -eq 'C:\Program Files (x86)\Some App\unins000.exe' -and $m.Arguments -eq '/SILENT') 'an unquoted program with spaces in its path'
$m = Get-UninstallCommand 'rundll32 something'
Check ($m.File -match 'cmd\.exe$') 'anything else goes through cmd'
Check ((Test-SharedComponent ([pscustomobject]@{ Name = 'Microsoft Visual C++ 2015-2022 Redistributable (x64)' })) -and -not (Test-SharedComponent $a)) 'runtimes are recognised (other apps need them)'
$apps = @(
    [pscustomobject]@{ Name = 'Zeta'; Publisher = 'Z'; Size = 10MB; LastUsed = [datetime]'2026-10-01' },
    [pscustomobject]@{ Name = 'alpha'; Publisher = 'Acme Corp'; Size = 900MB; LastUsed = $null },
    [pscustomobject]@{ Name = 'Mid'; Publisher = 'Acme Corp'; Size = 50MB; LastUsed = [datetime]'2025-01-01' })
Check (((@(Get-SortedApps $apps 'name' '') | ForEach-Object { $_.Name }) -join ',') -eq 'alpha,Mid,Zeta') 'by name'
Check (((@(Get-SortedApps $apps 'size' '') | ForEach-Object { $_.Name }) -join ',') -eq 'alpha,Mid,Zeta') 'biggest first'
Check (((@(Get-SortedApps $apps 'used' '') | ForEach-Object { $_.Name }) -join ',') -eq 'Mid,Zeta,alpha') 'least used first, apps without a date last'
Check (((@(Get-SortedApps $apps 'name' 'acme') | ForEach-Object { $_.Name }) -join ',') -eq 'alpha,Mid') 'typing part of a name (or publisher) finds it'

Write-Host "`n===== WHAT AN APP LEAVES BEHIND =====" -ForegroundColor White
Check ((@(Get-AppNameKeys $a)) -contains 'mozillafirefox' -and (@(Get-AppNameKeys $a)) -contains 'firefox' -and (@(Get-AppNameKeys $a)) -notcontains 'mozilla') "names of its folders: mozillafirefox, firefox, never just the publisher ($((Get-AppNameKeys $a) -join ','))"
Check ((@(Get-AppNameKeys ([pscustomobject]@{ Name = '7-Zip 24.08 (x64)'; Publisher = 'Igor Pavlov'; Location = '' }))) -contains '7zip') 'version numbers and (x64) are left out'
$mk = @(Get-AppNameKeys ([pscustomobject]@{ Name = 'Microsoft Update Health Tools'; Publisher = 'Microsoft Corporation'; Location = '' }))
Check ($mk -notcontains 'microsoft' -and $mk -notcontains 'update' -and $mk -notcontains 'tools' -and $mk.Count -ge 1) "common words are never names on their own ($($mk -join ','))"
$S = "$Sandbox/fs"
$env:APPDATA = "$S/Users/me/AppData/Roaming"; $env:LOCALAPPDATA = "$S/Users/me/AppData/Local"; $env:USERPROFILE = "$S/Users/me"
$env:ProgramData = "$S/ProgramData"; $env:ProgramFiles = "$S/Program Files"; $env:WINDIR = "$S/Windows"
foreach ($d in @("$env:APPDATA/Mozilla/Firefox/Profiles", "$env:APPDATA/Mozilla/Thunderbird", "$env:LOCALAPPDATA/Mozilla/Firefox", "$env:ProgramFiles/Mozilla Firefox", "$env:ProgramFiles/Mozilla Thunderbird", "$env:ProgramData/Other", "$env:WINDIR/Firefox")) { New-Item -ItemType Directory -Force $d | Out-Null }
Set-Content -LiteralPath "$env:APPDATA/Mozilla/Firefox/Profiles/prefs.js" -Value ('x' * 2048)
$ff = [pscustomobject]@{ Name = 'Mozilla Firefox (x64 en-US)'; Publisher = 'Mozilla'; Location = "$env:ProgramFiles/Mozilla Firefox"; KeyPath = 'ff' }
$tb = [pscustomobject]@{ Name = 'Mozilla Thunderbird (x64 en-US)'; Publisher = 'Mozilla'; Location = "$env:ProgramFiles/Mozilla Thunderbird"; KeyPath = 'tb' }
$script:FakeKeys = @{ 'HKCU:\Software' = @('Mozilla', 'Firefox', 'Microsoft', 'Classes'); 'HKCU:\Software\Mozilla' = @('Firefox', 'Thunderbird'); 'HKLM:\SOFTWARE' = @('Mozilla'); 'HKLM:\SOFTWARE\Mozilla' = @('Mozilla Firefox') }
function Get-RegSubKeyNames([string]$Path) { return @($script:FakeKeys[$Path]) }
$left = @(Find-AppLeftovers $ff @($tb))
$paths = @($left | ForEach-Object { $_.Path.Replace('\', '/') })
Check ($paths -contains "$env:APPDATA/Mozilla/Firefox" -and $paths -contains "$env:LOCALAPPDATA/Mozilla/Firefox" -and $paths -contains "$env:ProgramFiles/Mozilla Firefox") "its folders, also inside the publisher's folder ($($left.Count) found)"
Check (@($paths | Where-Object { $_ -match 'Thunderbird' -or $_ -match '/Mozilla$' -or $_ -match '/Windows/' -or $_ -match 'Other' }).Count -eq 0) "never another app's folder, the publisher's folder itself, or Windows"
Check ($paths -contains 'HKCU:/Software/Mozilla/Firefox' -and $paths -contains 'HKCU:/Software/Firefox' -and $paths -contains 'HKLM:/SOFTWARE/Mozilla/Mozilla Firefox' -and @($paths | Where-Object { $_ -match 'Thunderbird|Microsoft|Classes' }).Count -eq 0) 'its registry keys, and only those'
Check ((@($left | Where-Object { $_.Path -match 'Roaming.Mozilla.Firefox$' })[0].Size) -ge 2048) 'with the size of each folder'
$py2 = [pscustomobject]@{ Name = 'Python 3.12.1 (64-bit)'; Publisher = 'Python Software Foundation'; Location = ''; KeyPath = 'p1' }
$py3 = [pscustomobject]@{ Name = 'Python 3.13.0 (64-bit)'; Publisher = 'Python Software Foundation'; Location = ''; KeyPath = 'p2' }
Check (@(Find-AppLeftovers $py2 @($py3)).Count -eq 0) 'two versions of one app: nothing is offered (the folders may be the other one''s)'
Check (-not (Test-SafeLeftoverFolder $env:ProgramFiles @()) -and -not (Test-SafeLeftoverFolder $env:APPDATA @()) -and -not (Test-SafeLeftoverFolder 'C:\Games' @()) -and -not (Test-SafeLeftoverFolder "$env:WINDIR/Firefox" @())) 'never Program Files, AppData, a top folder or Windows'
Check (-not (Test-SafeLeftoverFolder "$env:ProgramFiles/Mozilla" @("$env:ProgramFiles/Mozilla/Thunderbird")) -and (Test-SafeLeftoverFolder "$env:ProgramFiles/Mozilla Firefox" @("$env:ProgramFiles/Mozilla Thunderbird"))) 'never a folder that holds another app'

Write-Host "`n===== REMOVING THE LEFTOVERS =====" -ForegroundColor White
function Move-ToRecycleBin([string]$Path) { Microsoft.PowerShell.Management\Remove-Item -LiteralPath $Path -Recurse -Force }
function Export-RegKey([string]$Key, [string]$File) { Set-Content -LiteralPath $File -Value "saved $Key" }
$script:RegRemoved = @()
function Remove-Item {
    param([string]$LiteralPath, [switch]$Recurse, [switch]$Force, $ErrorAction)
    if ($LiteralPath -match '^HK') { $script:RegRemoved += $LiteralPath } else { Microsoft.PowerShell.Management\Remove-Item -LiteralPath $LiteralPath -Recurse:$Recurse -Force:$Force }
}
$big = [pscustomobject]@{ Kind = 'folder'; Path = "$S/Users/me/AppData/Local/Huge"; Size = 3GB }
New-Item -ItemType Directory -Force $big.Path | Out-Null
$items = @($left | Where-Object { $_.Path -match 'Roaming|HKCU:\\Software\\Firefox' }) + @($big)
Answer @('D')
$out = Remove-AppLeftovers $ff $items 'Mozilla Firefox was uninstalled.' 6>&1 | Out-String
Check (-not (Test-Path "$env:APPDATA/Mozilla/Firefox") -and (Test-Path "$env:APPDATA/Mozilla/Thunderbird")) 'a ticked folder goes (to the Recycle Bin), the others stay'
Check ((Test-Path $big.Path) -and $out -match '1 GB or more') 'a folder of 1 GB or more starts unticked: it stays unless you tick it'
Check ($script:RegRemoved -contains 'HKCU:\Software\Firefox' -and @(Get-ChildItem "$script:DataDir/Backups" -Filter '*.reg').Count -eq 1) 'a registry key is saved to a .reg file, then removed'
$j = @(Read-ChangeJournal)[-1]
Check ((Get-ChangeTitle $j) -eq 'Leftovers of Mozilla Firefox (x64 en-US) removed' -and (@($j.Items | ForEach-Object { $_.Kind }) -join ',') -eq 'recycled,regkey') 'written down: the folder (Recycle Bin) and the key (its file), for Undo'
Answer @('')
$out = Remove-AppLeftovers $ff @($big) '' 6>&1 | Out-String
Check ((Test-Path $big.Path) -and $out -match 'Nothing was removed') 'Keep everything: nothing goes'
Remove-Item Function:\Remove-Item

Write-Host "`n===== THE ICON NEXT TO THE CLOCK =====" -ForegroundColor White
Check ($null -eq (Get-TrayDiskAlert ([pscustomobject]@{ DriveLetter = 'C'; Size = 1TB; SizeRemaining = 200GB }))) 'plenty of free space: nothing to say'
$d = Get-TrayDiskAlert ([pscustomobject]@{ DriveLetter = 'C'; Size = 500GB; SizeRemaining = 8GB })
Check ($d -and $d.Id -eq 'disk-space' -and $d.Text -match '^C: ') 'less than 10 GB free: an alert'
Check ($null -ne (Get-TrayDiskAlert ([pscustomobject]@{ DriveLetter = 'C'; Size = 500GB; SizeRemaining = 40GB }))) 'less than 10 % free: an alert'
$now = Get-Date
$st = @{ 'disk-space' = $now.AddDays(-2).ToString('yyyyMMddHHmmss'); 'battery' = $now.AddDays(-8).ToString('yyyyMMddHHmmss'); 'odd' = $now.AddDays(3).ToString('yyyyMMddHHmmss') }
Check ((Test-TrayDue $st 'new' $now) -and -not (Test-TrayDue $st 'disk-space' $now) -and (Test-TrayDue $st 'battery' $now) -and (Test-TrayDue $st 'odd' $now)) 'each alert at most once a week (a date in the future does not block it)'
$one = Get-TrayMessage @((New-TrayAlert 'a' 'Title A' 'Text A'))
$three = Get-TrayMessage @((New-TrayAlert 'a' 'Title A' 'x'), (New-TrayAlert 'b' 'Title B' 'y' 'Info'), (New-TrayAlert 'c' 'Title C' 'z'))
Check ($one.Title -eq 'Title A' -and $one.Text -eq 'Text A' -and $three.Title -eq '3 things to look at' -and $three.Text -eq "Title A`nTitle B`nTitle C" -and $three.Kind -eq 'Warning') 'one notification, even for several things'
"Run,Mode,Category,Files,Bytes`n" + ('"{0}","Auto","Temporary files","10","1000"' -f $now.AddHours(-2).ToString('yyyy-MM-dd HH:mm:ss.fff')) + "`n" + ('"{0}","Auto","Browser caches","5","500"' -f $now.AddHours(-2).ToString('yyyy-MM-dd HH:mm:ss.fff')) + "`n" + ('"{0}","Auto","Temporary files","1","99999"' -f $now.AddDays(-7).ToString('yyyy-MM-dd HH:mm:ss.fff')) | Set-Content -LiteralPath $script:HistoryPath
$lc = Get-LastAutoClean
Check ($lc -and $lc.Bytes -eq 1500 -and ($now - $lc.When).TotalHours -lt 3) 'the last weekly cleanup and what it freed, from the history'
$script:Shown = @()
function Show-TrayBalloon([string]$Title, [string]$Text, [string]$Kind) { $script:Shown += $Title }
function Get-TrayAlerts { return @((New-TrayAlert 'disk-space' 'Your disk is almost full' 'C: only 8 GB free.')) }
Invoke-TrayCheck; Invoke-TrayCheck
Check ($script:Shown.Count -eq 1) 'checked twice: told once'
Invoke-TrayCheck -Now
Check ($script:Shown.Count -eq 2) 'Check my PC now: always answers'
function Get-TrayAlerts { return @() }
Invoke-TrayCheck -Now
Check ($script:Shown[-1] -eq 'Everything looks fine') 'and says when everything is fine'

Write-Host "`n===== MENU, WINDOW AND STORE PACKAGE =====" -ForegroundColor White
Check ((@('30', '31', '32') | Where-Object { $script:MenuKeys -notcontains $_ }).Count -eq 0) 'the menu knows 30, 31 and 32'
Check ((@('30', '31', '32') | Where-Object { -not (Get-GuiToolInfo $_)[1] }).Count -eq 0) 'each has an icon and a sentence on the All tools page'
$titles = @(Get-GuiToolGroups | ForEach-Object { $_.Items } | ForEach-Object { $_[0] })
Check ((@('30', '31', '32') | Where-Object { $titles -notcontains $_ }).Count -eq 0) 'and a place in a group'
Check ("C:\Program Files\WindowsApps\YSO_1.1.7.0_x64__abc\YSO.ps1" -match '\\WindowsApps\\' -and $src -match '\$script:IsPackaged\s+=\s+\("\$PSCommandPath" -match ''\\\\WindowsApps\\\\''\)') 'YSO knows when it runs from its Microsoft Store package'
$script:IsPackaged = $true
Check ($null -eq (Get-YsoUpdateOffer -Force)) 'from the Store: no update offer of its own (the Store updates it)'
Check (-not (Install-Yso 6>$null)) 'and no install of its own'
$script:IsPackaged = $false
$manifest = [xml](Get-Content -LiteralPath (Join-Path (Split-Path -Parent $ScriptPath) 'packaging/AppxManifest.xml') -Raw)
$caps = @($manifest.Package.Capabilities.ChildNodes | ForEach-Object { $_.GetAttribute('Name') })
Check (($caps -contains 'runFullTrust') -and ($caps -contains 'allowElevation') -and ($caps -contains 'unvirtualizedResources') -and $manifest.Package.Applications.Application.EntryPoint -eq 'Windows.FullTrustApplication') 'the package manifest: full trust, administrator rights, real registry and files'
Check ($manifest.OuterXml -match 'RegistryWriteVirtualization>disabled' -and $manifest.OuterXml -match 'FileSystemWriteVirtualization>disabled') 'changes go to the real Windows settings, not to a private copy'

Write-Host ("`nRESULT: {0}" -f $(if ($script:fail) { "$($script:fail) FAILURE(S)" } else { 'ALL CHECKS PASSED' })) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
