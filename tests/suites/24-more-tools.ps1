param([string]$ScriptPath, [string]$Sandbox)
# Tools 33 to 39 and what 1.0.2 added to 19, 28 and 31: every setting written down and put back,
# files only shown (never deleted), measures compared, verdicts on drives, browser extensions read
# from their own files, and a PDF report without names. The registry is a table in memory here.
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

# --- the registry, in memory ---
$script:Reg = @{}
$script:RegKeys = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
function Set-FakeReg([string]$Path, [string]$Name, $Data, [string]$Type = 'DWord') { [void]$script:RegKeys.Add($Path); $script:Reg["$Path|$Name"] = @{ Type = $Type; Data = $Data } }
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
function Start-Process { $script:Started += @("$($args -join ' ') $($PSBoundParameters.Values -join ' ')") }
$script:Started = @()
function Get-LastJournal { return @(Read-ChangeJournal)[-1] }

Write-Host "`n===== PERFORMANCE MODE (38) =====" -ForegroundColor White
$desk = 'HKCU:\Control Panel\Desktop'
Set-FakeReg $desk 'MenuShowDelay' '400' 'String'
Set-FakeReg $desk 'UserPreferencesMask' ([Convert]::ToBase64String([byte[]](0x9E, 0x1E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00))) 'Binary'
Check (-not (Test-PerformanceMode)) 'off on a PC with the Windows defaults'
Answer @('y')
Show-PerformanceMode | Out-Null
Check (Test-PerformanceMode) 'switched on: every value of "best performance" is set'
Check ((Read-RegValue $desk 'FontSmoothing').Data -eq '2') 'text stays smooth (font smoothing on)'
$e = Get-LastJournal
Check ($e.Tool -eq 'Performance mode' -and @($e.Items).Count -eq @(Get-PerformanceValues).Count) "written down, one line per setting ($(@($e.Items).Count))"
$r = Undo-ChangeEntry $e
Check ($r.Failed -eq 0 -and -not (Test-PerformanceMode)) 'Undo puts the Windows effects back'
Check ((Read-RegValue $desk 'MenuShowDelay').Data -eq '400' -and -not (Read-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting').Existed) 'exact previous values: menu delay 400, a value that was not there is removed'
Answer @('y'); Show-PerformanceMode | Out-Null
Answer @('y'); Show-PerformanceMode | Out-Null
Check (-not (Test-PerformanceMode) -and (Read-RegValue $desk 'MenuShowDelay').Data -eq '400') 'run again: switched off, back to the Windows defaults'
$script:DryRun = $true; $n = $script:Reg.Count; Answer @('y'); Show-PerformanceMode | Out-Null; $script:DryRun = $false
Check ($script:Reg.Count -eq $n -and -not (Test-PerformanceMode)) 'analyze-only mode changes nothing'

Write-Host "`n===== RIGHT-CLICK MENU (37) =====" -ForegroundColor White
Check (-not (Test-ClassicMenu)) 'Windows 11 menu by default'
$c = New-ChangeEntry (N 'Right-click menu') (N 'Classic right-click menu')
Set-RegValueLogged $c $script:ClassicMenuKey '' '' 'String'
Add-ChangeEntry $c
Check (Test-ClassicMenu) 'classic menu: the empty (default) value of the key is set'
$e = Get-LastJournal
[void](Undo-ChangeEntry $e)
Check (-not (Test-ClassicMenu) -and -not $script:RegKeys.Contains($script:ClassicMenuKey)) "undo: the value and the key YSO made are gone (made: $($e.Items[0].Created))"
$clsid = '{11111111-2222-3333-4444-555555555555}'
$c = New-ChangeEntry (N 'Right-click menu') (N '{0} removed from the right-click menu') @('Some tool')
Set-RegValueLogged $c $script:ShellBlockedKey $clsid '' 'String'
Add-ChangeEntry $c
Check ((Read-RegValue $script:ShellBlockedKey $clsid).Existed) 'an entry is switched off with Windows'' Blocked list'
Check ((Get-ChangeTitle (Get-LastJournal)) -eq 'Some tool removed from the right-click menu') 'the list of changes names the program'
[void](Undo-ChangeEntry (Get-LastJournal))
Check (-not (Read-RegValue $script:ShellBlockedKey $clsid).Existed) 'undo: the entry is back'

Write-Host "`n===== WINDOWS UPDATE: RESTART HOURS AND PAUSE (28 > 7) =====" -ForegroundColor White
$script:Build = 22631
Answer @('1', '8', '23', '')
Show-WindowsUpdateSettings | Out-Null
Check ((Read-RegValue $script:WuUxKey 'ActiveHoursStart').Data -eq 8 -and (Read-RegValue $script:WuUxKey 'ActiveHoursEnd').Data -eq 23 -and (Read-RegValue $script:WuUxKey 'SmartActiveHoursState').Data -eq 0) 'restart hours 8:00 to 23:00, Windows'' own guess switched off'
$n = @(Read-ChangeJournal).Count
Answer @('1', '6', '1', ''); Show-WindowsUpdateSettings | Out-Null
Check (@(Read-ChangeJournal).Count -eq $n -and (Read-RegValue $script:WuUxKey 'ActiveHoursStart').Data -eq 8) 'more than 18 hours (6:00 to 1:00 = 19 h) is refused'
Answer @('1', '9', '9', ''); Show-WindowsUpdateSettings | Out-Null
Check ((Read-RegValue $script:WuUxKey 'ActiveHoursStart').Data -eq 8) 'the same hour twice is refused'
Answer @('2', '6', ''); Show-WindowsUpdateSettings | Out-Null
Check ($null -eq (Get-WuPause)) '6 weeks is refused (Windows allows 5)'
Answer @('2', '2', ''); Show-WindowsUpdateSettings | Out-Null
$until = Get-WuPause
Check ($until -and [int][math]::Round(($until.Date - (Get-Date).Date).TotalDays) -eq 14) "paused for 2 weeks (until $($until))"
Check ("$((Read-RegValue $script:WuUxKey 'PauseQualityUpdatesEndTime').Data)" -match '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$' -and (Read-RegValue $script:WuUxKey 'PauseFeatureUpdatesStartTime').Existed) 'the same values as Settings > Windows Update (UTC, ISO 8601)'
Answer @('3', ''); Show-WindowsUpdateSettings | Out-Null
Check ($null -eq (Get-WuPause) -and -not (Read-RegValue $script:WuUxKey 'PauseUpdatesExpiryTime').Existed) 'resume: the pause values are removed'
$e = @(Read-ChangeJournal | Where-Object { $_.Tool -eq 'Updates' })
Check ($e.Count -eq 3) "hours, pause and resume each written down ($($e.Count))"
[void](Undo-ChangeEntry $e[2]); Check ($null -ne (Get-WuPause)) 'undo the resume: paused again'
[void](Undo-ChangeEntry $e[1]); Check ($null -eq (Get-WuPause)) 'undo the pause: not paused'
[void](Undo-ChangeEntry $e[0]); Check (-not (Read-RegValue $script:WuUxKey 'ActiveHoursStart').Existed) 'undo the hours: Windows chooses them again'
Set-FakeReg $script:WuUxKey 'PauseUpdatesExpiryTime' '2001-01-01T00:00:00Z' 'String'
Check ($null -eq (Get-WuPause)) 'a pause that ended long ago does not count'

Write-Host "`n===== PRE-INSTALLED APPS (31 > W) =====" -ForegroundColor White
$cat = @(Get-BloatCatalog)
$never = @('Microsoft.WindowsStore', 'Microsoft.Windows.Photos', 'Microsoft.WindowsCalculator', 'Microsoft.WindowsCamera', 'Microsoft.WindowsNotepad', 'Microsoft.Paint',
    'Microsoft.WindowsTerminal', 'Microsoft.ZuneMusic', 'Microsoft.XboxGamingOverlay', 'Microsoft.GamingApp', 'Microsoft.DesktopAppInstaller', 'Microsoft.SecHealthUI',
    'Microsoft.StorePurchaseApp', 'Microsoft.ScreenSketch', 'Microsoft.WindowsAlarms', 'Microsoft.VCLibs.140.00', 'NVIDIACorp.NVIDIAControlPanel', 'RealtekSemiconductorCorp.RealtekAudioControl')
$hit = @(foreach ($n in $never) { foreach ($b in $cat) { if ($n -like $b[0]) { "$n ($($b[0]))" } } })
Check ($hit.Count -eq 0) "never offers the Store, Photos, Calculator, Notepad, Paint, Terminal, Xbox, App Installer, Security or drivers' apps $($hit -join ', ')"
$apps = @([pscustomobject]@{ Name = 'Microsoft.BingNews'; PackageFullName = 'Microsoft.BingNews_4.1_x64__8wekyb3d8bbwe'; PackageFamilyName = 'Microsoft.BingNews_8wekyb3d8bbwe'; IsFramework = $false; NonRemovable = $false },
          [pscustomobject]@{ Name = 'king.com.CandyCrushSaga'; PackageFullName = 'king.com.CandyCrushSaga_1.0_x86__kgqvnymyfvs32'; PackageFamilyName = 'king.com.CandyCrushSaga_kgqvnymyfvs32'; IsFramework = $false; NonRemovable = $false },
          [pscustomobject]@{ Name = 'Microsoft.BingWeather'; PackageFullName = 'Microsoft.BingWeather_4.5_x64__8wekyb3d8bbwe'; PackageFamilyName = 'Microsoft.BingWeather_8wekyb3d8bbwe'; IsFramework = $false; NonRemovable = $false },
          [pscustomobject]@{ Name = 'Microsoft.WindowsCalculator'; PackageFullName = 'Microsoft.WindowsCalculator_11_x64__8wekyb3d8bbwe'; PackageFamilyName = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe'; IsFramework = $false; NonRemovable = $false })
function Get-AppxPackage { param([switch]$AllUsers, [string]$Name) if ($Name) { return @() } return $script:FakeAppx }
$script:FakeAppx = $apps
$script:RemovedAppx = @()
function Remove-AppxPackage { param([string]$Package) $script:RemovedAppx += $Package; $script:FakeAppx = @($script:FakeAppx | Where-Object { $_.PackageFullName -ne $Package }) }
$b = @(Get-InstalledBloat)
Check ($b.Count -eq 3 -and -not @($b | Where-Object { $_.Name -match 'Calculator' }).Count) "only known pre-installed apps are listed ($(@($b | ForEach-Object Name) -join ', '))"
Answer @('U', 'D', 'y', '', '')
Show-PreinstalledApps | Out-Null
Check ($script:RemovedAppx.Count -eq 2 -and ($script:RemovedAppx -join ' ') -match 'BingNews' -and ($script:RemovedAppx -join ' ') -notmatch 'Weather') "U ticks the usual ones (News, Candy Crush), not Weather ($($script:RemovedAppx -join ', '))"
$e = Get-LastJournal
Check ($e.Tool -eq 'Uninstall apps' -and @($e.Items | Where-Object { $_.Kind -eq 'appx' -and $_.Family }).Count -eq 2) 'each removed app is written down with its family name'
Check ((Get-ChangeItemText $e.Items[0]) -match 'Microsoft Store') 'the list of changes says it comes back from the Microsoft Store'
$script:Started = @()
[void](Undo-ChangeEntry $e)
Check ($script:Started.Count -eq 2 -and ($script:Started -join ' ') -match 'ms-windows-store://pdp/\?PFN=Microsoft\.BingNews_8wekyb3d8bbwe') 'undo opens each app''s page in the Microsoft Store'
$script:RemovedAppx = @(); Answer @('1', 'D', 'n', '')
Show-PreinstalledApps | Out-Null
Check ($script:RemovedAppx.Count -eq 0) 'nothing is removed when the answer is no'

Write-Host "`n===== MORE SPACE FROM WINDOWS (33) =====" -ForegroundColor White
Check ((Get-ShadowCap 100GB) -eq 5GB -and (Get-ShadowCap 1TB) -eq [long][math]::Floor(1TB * 0.05)) 'restore points limited to 5 % of the drive, at least 5 GB'
Check ((Get-ChangeItemText ([pscustomobject]@{ Kind = 'compactos'; Before = $false })) -match 'Compact OS' -and (Get-ChangeItemText ([pscustomobject]@{ Kind = 'reserved'; Before = 'Enabled' })) -match 'reserved' -and
       (Get-ChangeItemText ([pscustomobject]@{ Kind = 'shadow'; Drive = 'C:'; Before = -1 })) -match 'restore points on C:') 'each setting has its line in Undo YSO changes'
$script:Calls = @()
function vssadmin.exe { $script:Calls += , @($args); $global:LASTEXITCODE = 0 }
function compact.exe { $script:Calls += , @($args); $global:LASTEXITCODE = 0 }
function Set-WindowsReservedStorageState { param([string]$State) $script:Calls += , @('reserved', $State) }
Check ((Undo-ChangeItem ([pscustomobject]@{ Kind = 'shadow'; Drive = 'C:'; Before = -1 })) -and ($script:Calls[-1] -join ' ') -eq 'Resize ShadowStorage /For=C: /On=C: /MaxSize=UNBOUNDED') 'undo: no limit again'
Check ((Undo-ChangeItem ([pscustomobject]@{ Kind = 'shadow'; Drive = 'C:'; Before = 20GB })) -and ($script:Calls[-1] -join ' ') -eq 'Resize ShadowStorage /For=C: /On=C: /MaxSize=20480MB') 'undo: the previous limit again'
Check ((Undo-ChangeItem ([pscustomobject]@{ Kind = 'compactos'; Before = $false })) -and ($script:Calls[-1] -join ' ') -eq '/compactos:never') 'undo Compact OS: uncompressed again'
Check ((Undo-ChangeItem ([pscustomobject]@{ Kind = 'reserved'; Before = 'Enabled' })) -and ($script:Calls[-1] -join ' ') -eq 'reserved Enabled') 'undo reserved storage: on again'
function Get-FreeBytes { 50GB }
Answer @('y')
Set-ShadowStorageChoice ([pscustomobject]@{ Max = -1L; Used = 3GB; Size = 200GB }) | Out-Null
Check (($script:Calls[-1] -join ' ') -eq 'Resize ShadowStorage /For= /On= /MaxSize=10240MB' -or ($script:Calls[-1] -join ' ') -match '/MaxSize=10240MB$') 'no limit on a 200 GB drive: limited to 10 GB'
$e = Get-LastJournal
Check ($e.Items[0].Kind -eq 'shadow' -and $e.Items[0].Before -eq -1) 'the previous limit (none) is written down'
$n = $script:Calls.Count
Set-ShadowStorageChoice ([pscustomobject]@{ Max = 8GB; Used = 3GB; Size = 200GB }) | Out-Null
Check ($script:Calls.Count -eq $n) 'already under the limit: nothing to do'
Answer @('n')
Set-ShadowStorageChoice ([pscustomobject]@{ Max = -1L; Used = 3GB; Size = 200GB }) | Out-Null
Check ($script:Calls.Count -eq $n) 'answer no: nothing changed'

Write-Host "`n===== FILES YOU MIGHT NOT NEED (34) =====" -ForegroundColor White
$dl = "$Sandbox/Downloads"; New-Item -ItemType Directory -Force $dl, "$Sandbox/Docs/sub", "$Sandbox/Pics" | Out-Null
function New-File([string]$Path, [byte[]]$Bytes, [int]$Days = 0) { [IO.File]::WriteAllBytes($Path, $Bytes); if ($Days) { (Get-Item -LiteralPath $Path).LastWriteTime = (Get-Date).AddDays(-$Days) } }
$big = New-Object byte[] (2MB); (New-Object Random 7).NextBytes($big)
$big2 = [byte[]]$big.Clone(); $big2[$big2.Length - 1] = $big2[$big2.Length - 1] -bxor 0xFF   # same size, same start, different end
New-File "$dl/setup-old.exe" (New-Object byte[] 4096) 90
New-File "$dl/Win11.iso" (New-Object byte[] 8192) 45
New-File "$dl/setup-new.msi" (New-Object byte[] 4096) 3
New-File "$dl/report.pdf" (New-Object byte[] 4096) 400
$old = @(Get-OldInstallers @($dl))
Check ($old.Count -eq 2 -and $old[0].Name -eq 'Win11.iso') "installers and disk images older than 30 days, biggest first ($(@($old | ForEach-Object Name) -join ', '))"
New-File "$Sandbox/Docs/a.bin" $big; New-File "$Sandbox/Pics/copy of a.bin" $big; New-File "$Sandbox/Docs/sub/a again.bin" $big
New-File "$Sandbox/Docs/b.bin" $big2
New-File "$Sandbox/Docs/small1.txt" ([byte[]](1, 2, 3)); New-File "$Sandbox/Pics/small2.txt" ([byte[]](1, 2, 3))
$g = @(Find-DuplicateFiles @("$Sandbox/Docs", "$Sandbox/Pics"))
Check ($g.Count -eq 1 -and $g[0].Files.Count -eq 3) "one group of 3 real copies; same size and start but other content is not a copy ($($g.Count) group(s))"
Check ($g[0].Waste -eq 2 * 2MB) 'what could be freed: every copy but one'
Check (@(Find-DuplicateFiles @("$Sandbox/Docs", "$Sandbox/Pics") -MinSize 1).Count -eq 2) 'small files count when asked (1 MB or more by default)'
$before = @(Get-ChildItem -LiteralPath $Sandbox -Recurse -File).Count
Answer @('1', '', '')
Show-UnneededFiles | Out-Null
Check ($before -eq @(Get-ChildItem -LiteralPath $Sandbox -Recurse -File).Count) 'nothing is ever deleted by this tool'
$mob = "$Sandbox/Users/Ana/AppData/Roaming/Apple Computer/MobileSync/Backup/00008110-AB"
New-Item -ItemType Directory -Force $mob | Out-Null
Set-Content -LiteralPath "$mob/Info.plist" -Value '<plist><dict><key>Device Name</key><string>Phone of A</string></dict></plist>'
New-File "$mob/blob" (New-Object byte[] 10000)
$script:Profiles = @("$Sandbox/Users/Ana")
$bk = @(Get-DeviceBackups)
Check ($bk.Count -eq 1 -and $bk[0].Name -eq 'Phone of A' -and $bk[0].Size -gt 10000) 'iPhone backup found, with the device name and its size'

Write-Host "`n===== MY PC OVER TIME (35) =====" -ForegroundColor White
function Get-LastBootSeconds { 41.6 }
function Get-FixedVolumes { @([pscustomobject]@{ DriveLetter = 'C'; SizeRemaining = 80GB; Size = 500GB }) }
function Get-StartupEntries { param([switch]$Fast) @([pscustomobject]@{ Enabled = $true }, [pscustomobject]@{ Enabled = $true }, [pscustomobject]@{ Enabled = $false }) }
$env:SystemDrive = 'C:'
Save-PcSnapshot; Save-PcSnapshot
$rows = @(Read-PcHistory)
Check ($rows.Count -eq 1 -and $rows[0].BootSeconds -eq '41.6' -and $rows[0].Startup -eq '2' -and [long]$rows[0].FreeBytes -eq 80GB) 'measured once a day: startup time, free space, programs at startup'
Check ($null -eq (Get-PcProgress $rows)) 'one day: too soon to compare'
$d0 = (Get-Date).AddDays(-30).ToString('yyyyMMdd'); $d1 = (Get-Date).AddDays(-3).ToString('yyyyMMdd')
$hist = @([pscustomobject]@{ Day = $d0; BootSeconds = '62'; FreeBytes = "$(70GB)"; Startup = '9' }, [pscustomobject]@{ Day = $d1; BootSeconds = ''; FreeBytes = "$(75GB)"; Startup = '9' }) + $rows
$p = Get-PcProgress $hist
Check ($p.Boot.Before -eq 62 -and $p.Boot.After -eq 41.6 -and $p.Free.After - $p.Free.Before -eq 10GB -and $p.Startup.After -eq 2) 'first day against today; a day without a startup time is skipped'
$t = Get-PcProgressText $p
Check ($t -match '^startup 42 s \(62 s before\), 10[\.,0]* GB more free space, 7 fewer programs at startup$') "said in one line: $t"
$script:Lang = 'fr'; $tf = Get-PcProgressText $p; $script:Lang = 'en'
Check ($tf -match '^démarrage 42 s \(62 s avant\)' -and $tf -match 'programmes de moins au démarrage') "and in French: $tf"
$same = @([pscustomobject]@{ Day = $d0; BootSeconds = '40'; FreeBytes = "$(80GB)"; Startup = '2' }, [pscustomobject]@{ Day = $d1; BootSeconds = '40'; FreeBytes = "$(80GB)"; Startup = '2' })
Check ((Get-PcProgressText (Get-PcProgress $same)) -eq '') 'nothing changed: nothing to say'
@($hist) | Export-Csv -LiteralPath $script:PcHistoryPath -NoTypeInformation -Encoding UTF8
$h = @(Get-HealthItems | Where-Object { $_.Name -eq 'Over time' })
Check ($h.Count -eq 1 -and $h[0].Action -eq '35' -and $h[0].Text -match '^since ') 'the home page shows it, with a link to the tool'

Write-Host "`n===== DISK SPEED & TEMPERATURE (36) =====" -ForegroundColor White
Check ((Get-DiskKind ([pscustomobject]@{ Bus = 'NVMe'; Media = 'SSD' })) -eq 'nvme' -and (Get-DiskKind ([pscustomobject]@{ Bus = 'SATA'; Media = 'HDD' })) -eq 'hdd' -and
       (Get-DiskKind ([pscustomobject]@{ Bus = 'USB'; Media = 'SSD' })) -eq 'usb' -and (Get-DiskKind ([pscustomobject]@{ Bus = 'SATA'; Media = 'Unspecified' })) -eq 'ssd') 'kind of drive: NVMe, SATA SSD, hard drive, USB'
Check ((Get-SpeedVerdict 'nvme' 3200).Level -eq 'Good' -and (Get-SpeedVerdict 'nvme' 900).Level -eq 'Warn' -and (Get-SpeedVerdict 'nvme' 450).Level -eq 'Bad') 'NVMe: 3200 fast, 900 a bit slow, 450 slow'
Check ((Get-SpeedVerdict 'hdd' 150).Level -eq 'Good' -and (Get-SpeedVerdict 'hdd' 40).Level -eq 'Bad' -and (Get-SpeedVerdict 'ssd' 520).Level -eq 'Good') 'hard drive 150 is fast for a hard drive, SATA SSD 520 is fast'
Check ($null -eq (Get-TempVerdict $null) -and (Get-TempVerdict 38).Level -eq 'Good' -and (Get-TempVerdict 60).Level -eq 'Warn' -and (Get-TempVerdict 74).Level -eq 'Bad') 'temperature: 38 normal, 60 warm, 74 hot, unknown says nothing'
Check ((ConvertFrom-WinsatSpeed @('Windows System Assessment Tool', '> Disk  Sequential 64.0 Read                   2873.24 MB/s          9.4', '> Total Run Time 00:00:03.06')) -eq 2873.24) 'winsat: the MB/s figure is read'
Check ((ConvertFrom-WinsatSpeed @('> Disk  Sequential 64.0 Write   512,5 MB/s   7.9')) -eq 512.5 -and $null -eq (ConvertFrom-WinsatSpeed @('error'))) 'with a decimal comma too; nothing when winsat failed'

Write-Host "`n===== BROWSER EXTENSIONS (39) =====" -ForegroundColor White
Check ((Get-ExtensionReach @('storage', '<all_urls>')) -eq 'all' -and (Get-ExtensionReach @('tabs', 'storage')) -eq 'browsing' -and (Get-ExtensionReach @('storage', 'alarms')) -eq 'small') 'what it may do: every site, your browsing, or little'
Check ((Get-ExtensionReach @('https://*/*')) -eq 'all' -and (Get-ExtensionReach @()) -eq 'small') 'host patterns for every site count as every site'
$u = "$Sandbox/Users/Ana"
$chrome = "$u/AppData/Local/Google/Chrome/User Data/Default"
$ext1 = "$chrome/Extensions/aaaabbbbccccddddeeeeffffgggghhhh/1.2.0_0"; $ext2 = "$chrome/Extensions/iiiijjjjkkkkllllmmmmnnnnoooopppp/3.0_0"; $theme = "$chrome/Extensions/qqqqrrrrssssttttuuuuvvvvwwwwxxxx/1_0"
New-Item -ItemType Directory -Force "$ext1/_locales/en", $ext2, $theme | Out-Null
Set-Content -LiteralPath "$ext1/manifest.json" -Value '{ "name": "__MSG_appName__", "default_locale": "en", "version": "1.2.0", "permissions": ["storage"], "content_scripts": [ { "matches": ["<all_urls>"], "js": ["a.js"] } ] }'
Set-Content -LiteralPath "$ext1/_locales/en/messages.json" -Value '{ "appName": { "message": "Coupon Finder" } }'
Set-Content -LiteralPath "$ext2/manifest.json" -Value '{ "name": "Dark Reader Lite", "version": "3.0", "permissions": ["storage"] }'
Set-Content -LiteralPath "$theme/manifest.json" -Value '{ "name": "Ocean theme", "version": "1", "theme": { "colors": { "frame": [0, 0, 0] } } }'
$comp = "$chrome/Extensions/yyyyzzzzaaaabbbbccccddddeeeeffff/1.0_0"; New-Item -ItemType Directory -Force $comp | Out-Null
Set-Content -LiteralPath "$comp/manifest.json" -Value '{ "name": "Browser part", "version": "1.0", "permissions": ["<all_urls>"] }'
Set-Content -LiteralPath "$chrome/Secure Preferences" -Value '{ "extensions": { "settings": { "iiiijjjjkkkkllllmmmmnnnnoooopppp": { "state": 0, "location": 1 }, "aaaabbbbccccddddeeeeffffgggghhhh": { "state": 1, "location": 4 }, "yyyyzzzzaaaabbbbccccddddeeeeffff": { "location": 5 } } } }'
$ff = "$u/AppData/Roaming/Mozilla/Firefox/Profiles/abcd.default-release"
New-Item -ItemType Directory -Force $ff | Out-Null
Set-Content -LiteralPath "$ff/extensions.json" -Value '{ "addons": [ { "type": "extension", "location": "app-profile", "active": true, "signedState": 2, "defaultLocale": { "name": "uBlock Origin" }, "userPermissions": { "permissions": ["storage"], "origins": ["<all_urls>"] } }, { "type": "extension", "location": "app-system-defaults", "active": true, "defaultLocale": { "name": "Firefox Screenshots" } }, { "type": "theme", "location": "app-profile", "active": true, "defaultLocale": { "name": "Dark" } } ] }'
$script:Profiles = @($u)
$list = @(Get-BrowserExtensions)
$names = @($list | ForEach-Object { "$($_.Browser):$($_.Name)" })
Check ($list.Count -eq 3) "Chrome and Firefox extensions found; themes, parts of the browser and Firefox's own add-ons left out ($($names -join ', '))"
$cf = @($list | Where-Object { $_.Name -eq 'Coupon Finder' })[0]
Check ($cf -and $cf.Reach -eq 'all' -and $cf.On -and -not $cf.Store) 'name read from its translations; it can read every site, and does not come from the store'
$dr = @($list | Where-Object { $_.Name -eq 'Dark Reader Lite' })[0]
Check ($dr -and -not $dr.On -and $dr.Reach -eq 'small') 'switched off in Chrome: shown as off'
$ub = @($list | Where-Object { $_.Browser -eq 'Firefox' })[0]
Check ($ub.Name -eq 'uBlock Origin' -and $ub.Reach -eq 'all' -and $ub.On -and $ub.Store) 'Firefox: name, state, what it may do, signed by Mozilla'
$before = @(Get-ChildItem -LiteralPath $u -Recurse -File).Count
Show-BrowserExtensions | Out-Null
Check ($before -eq @(Get-ChildItem -LiteralPath $u -Recurse -File).Count) 'only shown: nothing is changed'

Write-Host "`n===== HEALTH REPORT AS A PDF (19) =====" -ForegroundColor White
$env:USERNAME = 'ana.secret'; $env:COMPUTERNAME = 'DESKTOP-SECRET1'
function Get-CimInstance {
    param([string]$ClassName, $Namespace, $Filter, $ErrorAction)
    $cls = "$ClassName$($args -join '')"
    if ($cls -match 'ComputerSystem') { return [pscustomobject]@{ Manufacturer = 'LENOVO'; Model = '20XW'; TotalPhysicalMemory = 16GB; Name = 'DESKTOP-SECRET1'; UserName = 'DESKTOP-SECRET1\ana.secret' } }
    if ($cls -match 'OperatingSystem') { return [pscustomobject]@{ LastBootUpTime = (Get-Date).AddDays(-3); CSName = 'DESKTOP-SECRET1'; RegisteredUser = 'ana.secret' } }
    if ($cls -match 'Processor') { return [pscustomobject]@{ Name = 'Intel(R) Core(TM) i7-1165G7' } }
    return $null
}
function Get-OsText { 'Windows 11 Pro 24H2' }
function Get-HealthItems { @((New-HealthItem (N 'Disk space') 'Warn' 'C: 20 GB free of 500 GB (4 %)' 'F'), (New-HealthItem (N 'Security') 'Good' 'Microsoft Defender on')) }
function Get-DiskFacts { @([pscustomobject]@{ Name = 'Samsung SSD 980 1TB'; Health = 'Healthy'; Wear = 3; Temp = 41 }) }
function Get-EventsSafe { param($Filter, $MaxEvents) $script:LastEventError = $null; if ($Filter.Id -eq 41) { return @(1, 2) } return @() }
$html = New-HealthReportHtml
Check ($html -match '<h1>PC health report</h1>' -and $html -match 'LENOVO 20XW' -and $html -match 'Samsung SSD 980 1TB' -and $html -match 'wear 3 %') 'the report: this PC, at a glance, drives, problems'
Check ($html -notmatch 'ana\.secret' -and $html -notmatch 'DESKTOP-SECRET1') 'no user name, no PC name in it'
Check ($html -match 'Unexpected shutdowns</th><td>2<') 'problems of the last 30 days counted'
$script:Lang = 'fr'; $fr = [System.Net.WebUtility]::HtmlDecode((New-HealthReportHtml)); $script:Lang = 'en'
Check ($fr -match 'Rapport de santé du PC' -and $fr -match 'Arrêts inattendus') 'in French when YSO is in French'
$evil = New-HealthItem (N 'Disk space') 'Bad' '<script>alert(1)</script>'
function Get-HealthItems { @($evil) }
Check ((New-HealthReportHtml) -notmatch '<script>') 'text is escaped: nothing in it can run as a script'
function Get-EdgePath { '' }
$desk = "$Sandbox/Desktop"; New-Item -ItemType Directory -Force $desk | Out-Null
function Get-DesktopFolder { $desk }
$script:LogDir = "$Sandbox/logs"; New-Item -ItemType Directory -Force $script:LogDir | Out-Null
Save-HealthReportPdf | Out-Null
$saved = @(Get-ChildItem -LiteralPath $script:LogDir, $desk -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'PC health report*' })
Check ($saved.Count -eq 1 -and $saved[0].Extension -eq '.html') 'without Edge: saved as a web page instead, to print to PDF'

Write-Host "`n===== DEEPER CLEANING (3, 7, 9, 29) =====" -ForegroundColor White
$script:Profiles = @("$Sandbox/Users/Ana")
New-Item -ItemType Directory -Force "$Sandbox/Users/Ana/.cache/huggingface/hub/models--x" | Out-Null
Check (@(Get-HuggingFaceCaches).Count -eq 1) 'Hugging Face models found'
$script:Calls = @()
function Confirm-Action { param([string]$Question, [bool]$Default) $script:Calls += , @('confirm', $Question); return $false }
New-File "$Sandbox/Users/Ana/.cache/huggingface/hub/models--x/model.bin" (New-Object byte[] 1MB)
Clear-HuggingFaceModels | Out-Null
Check ($script:Calls.Count -eq 0 -and (Test-Path "$Sandbox/Users/Ana/.cache/huggingface/hub/models--x/model.bin")) 'under 100 MB: not even asked'
$fs = [IO.File]::Open("$Sandbox/Users/Ana/.cache/huggingface/hub/models--x/model.bin", 'Open'); $fs.SetLength(150MB); $fs.Dispose()
Clear-HuggingFaceModels | Out-Null
Check ($script:Calls.Count -eq 1 -and (Test-Path "$Sandbox/Users/Ana/.cache/huggingface/hub/models--x/model.bin")) 'asked first (No by default), and kept when the answer is no'
$env:SystemDrive = $Sandbox
New-Item -ItemType Directory -Force "$Sandbox/`$WINDOWS.~BT/Sources", "$Sandbox/`$GetCurrent", "$Sandbox/ESD" | Out-Null
$lo = @(Get-UpgradeLeftovers)
Check ($lo.Count -eq 2 -and -not @($lo | Where-Object { $_ -match 'ESD' }).Count) "upgrade folders found, C:\ESD is not one of them ($($lo.Count))"
function Confirm-Action { param([string]$Question, [bool]$Default) return $true }
function Invoke-CleanMgr { $true }
Remove-UpgradeLeftovers $true | Out-Null
Check ((Test-Path -LiteralPath "$Sandbox/`$WINDOWS.~BT") -and (Test-Path -LiteralPath "$Sandbox/`$GetCurrent")) 'kept while going back to the previous Windows is still possible'
Remove-UpgradeLeftovers $false | Out-Null
Check (-not (Test-Path -LiteralPath "$Sandbox/`$WINDOWS.~BT") -and -not (Test-Path -LiteralPath "$Sandbox/`$GetCurrent") -and (Test-Path -LiteralPath "$Sandbox/ESD")) 'removed after that; C:\ESD stays (Reset this PC can need it)'
$env:SystemDrive = 'C:'

Write-Host ''
if ($script:fail -eq 0) { Write-Host 'RESULT: ALL CHECKS PASSED' -ForegroundColor Green } else { Write-Host "RESULT: $($script:fail) CHECK(S) FAILED" -ForegroundColor Red; exit 1 }
