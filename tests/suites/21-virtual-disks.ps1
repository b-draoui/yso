param([string]$ScriptPath, [string]$Sandbox)
# Virtual disks (29): finding the disks of VirtualBox, WSL and Docker Desktop, refusing a machine
# that is saved, running or has snapshots, and compacting only after the last warning.
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
Import-Settings

Write-Host "`n===== WHAT VIRTUALBOX KNOWS =====" -ForegroundColor White
$vb = "$Sandbox/vbox"; New-Item -ItemType Directory -Force "$vb/Off", "$vb/Saved", "$vb/Snap/Snapshots" | Out-Null
$ns = 'xmlns="http://www.virtualbox.org/"'
Set-Content -LiteralPath "$vb/VirtualBox.xml" -Value @"
<?xml version="1.0"?>
<VirtualBox $ns version="1.19-windows"><Global><MachineRegistry>
  <MachineEntry uuid="{1}" src="$vb/Off/Off.vbox"/>
  <MachineEntry uuid="{2}" src="$vb/Saved/Saved.vbox"/>
  <MachineEntry uuid="{3}" src="$vb/Snap/Snap.vbox"/>
  <MachineEntry uuid="{4}" src="$vb/Gone/Gone.vbox"/>
</MachineRegistry></Global></VirtualBox>
"@
Set-Content -LiteralPath "$vb/Off/Off.vbox" -Value "<VirtualBox $ns><Machine uuid='{1}' name='Ubuntu 26.04' OSType='Ubuntu_64'><MediaRegistry><HardDisks><HardDisk uuid='{a}' location='Off.vdi' format='VDI' type='Normal'/><HardDisk uuid='{b}' location='old.vmdk' format='VMDK'/></HardDisks></MediaRegistry></Machine></VirtualBox>"
Set-Content -LiteralPath "$vb/Saved/Saved.vbox" -Value "<VirtualBox $ns><Machine uuid='{2}' name='Server' OSType='Ubuntu_64' stateFile='Snapshots/x.sav'><MediaRegistry><HardDisks><HardDisk uuid='{c}' location='Saved.vdi' format='VDI'/></HardDisks></MediaRegistry></Machine></VirtualBox>"
Set-Content -LiteralPath "$vb/Snap/Snap.vbox" -Value "<VirtualBox $ns><Machine uuid='{3}' name='Win' OSType='Windows11_64' currentSnapshot='{s}'><MediaRegistry><HardDisks><HardDisk uuid='{d}' location='Snap.vdi' format='VDI'><HardDisk uuid='{e}' location='Snapshots/{e}.vdi' format='VDI'/></HardDisk></HardDisks></MediaRegistry><Snapshot uuid='{s}' name='before'/></Machine></VirtualBox>"
$ms = @(Get-VBoxMachines -VBoxHome $vb)
$off = @($ms | Where-Object { $_.Name -eq 'Ubuntu 26.04' })[0]
$sav = @($ms | Where-Object { $_.Name -eq 'Server' })[0]
$snap = @($ms | Where-Object { $_.Name -eq 'Win' })[0]
Check ($ms.Count -eq 3) "every machine of VirtualBox.xml whose file exists is read ($($ms.Count))"
Check ($off -and @($off.Disks).Count -eq 1 -and (Split-Path -Leaf $off.Disks[0]) -eq 'Off.vdi' -and [System.IO.Path]::IsPathRooted($off.Disks[0]) -and -not $off.Saved -and -not $off.Snapshots) 'a machine that is off: its .vdi, found next to its .vbox (other formats are left alone)'
Check ($sav -and $sav.Saved) 'a machine in saved state is recognised'
Check ($snap -and $snap.Snapshots -and @($snap.Disks).Count -eq 1 -and $snap.Disks[0] -match 'Snapshots') 'a machine with snapshots is recognised (only the disk it writes to is listed)'

Write-Host "`n===== THE SIZE OF A VDI =====" -ForegroundColor White
$vdi = "$vb/Off/Off.vdi"
$h = New-Object byte[] 4096
[BitConverter]::GetBytes([uint32]0xBEDA107FL).CopyTo($h, 0x40)
[BitConverter]::GetBytes([uint16]1).CopyTo($h, 0x44); [BitConverter]::GetBytes([uint16]1).CopyTo($h, 0x46)
[BitConverter]::GetBytes([uint64]50GB).CopyTo($h, 0x170)
[BitConverter]::GetBytes([uint32]1MB).CopyTo($h, 0x178)
[BitConverter]::GetBytes([uint32]51200).CopyTo($h, 0x180)
[BitConverter]::GetBytes([uint32]300).CopyTo($h, 0x184)
[System.IO.File]::WriteAllBytes($vdi, $h)
$r = Read-VdiHeader $vdi
Check ($r -and $r.Capacity -eq 50GB -and $r.Allocated -eq 300MB) 'its full size (what the machine sees) is read from its header'
Set-Content -LiteralPath "$Sandbox/not.vdi" -Value ('x' * 500)
Check ($null -eq (Read-VdiHeader "$Sandbox/not.vdi")) 'a file that is not a VDI gives nothing'

Write-Host "`n===== WSL AND DOCKER =====" -ForegroundColor White
$w = @(ConvertFrom-LxssEntries @(
    [pscustomobject]@{ DistributionName = 'Ubuntu'; BasePath = '\\?\C:\Users\me\AppData\Local\wsl\{50d0}'; Version = 2 },
    [pscustomobject]@{ DistributionName = 'Old'; BasePath = 'C:\old'; Version = 1 },
    [pscustomobject]@{ DistributionName = 'docker-desktop'; BasePath = 'C:\Users\me\AppData\Local\Docker\wsl\main'; Version = 2; VhdFileName = 'ext4.vhdx' }))
Check ($w.Count -eq 2 -and $w[0].Path -eq [System.IO.Path]::Combine('C:\Users\me\AppData\Local\wsl\{50d0}', 'ext4.vhdx') -and $w[0].Kind -eq 'WSL' -and $w[1].Kind -eq 'Docker') 'WSL 2 distributions and their ext4.vhdx (WSL 1 has no disk; docker-desktop is Docker)'

Write-Host "`n===== WHEN A DISK IS LEFT ALONE =====" -ForegroundColor White
function Get-VBoxManagePath { return 'C:\VBoxManage.exe' }
$script:InUse = $false
function Test-FileInUse([string]$Path) { return $script:InUse }
$none = [pscustomobject]@{ VBoxOpen = $false; VBoxVms = $false; Docker = $false; WslRunning = $false }
$d = { param($m) [pscustomobject]@{ Kind = 'VirtualBox'; Name = $m.Name; Path = 'x.vdi'; Machine = $m } }
Check ((Get-VDiskProblem (& $d $off) $none) -eq '') 'a machine that is off and closed can be compacted'
Check ((Get-VDiskProblem (& $d $sav) $none) -match 'saved state') 'saved state: refused, with what to do'
Check ((Get-VDiskProblem (& $d $snap) $none) -match 'snapshots') 'snapshots: left alone'
$script:InUse = $true
Check ((Get-VDiskProblem (& $d $off) $none) -match 'running') 'a disk in use (the machine runs): refused'
$script:InUse = $false
Check ((Get-VDiskProblem (& $d $off) ([pscustomobject]@{ VBoxOpen = $true; Docker = $false })) -match 'close VirtualBox') 'VirtualBox open: close it first'
$wd = [pscustomobject]@{ Kind = 'WSL'; Name = 'Ubuntu'; Path = 'x.vhdx'; Machine = $null }
Check ((Get-VDiskProblem $wd ([pscustomobject]@{ VBoxOpen = $false; Docker = $true })) -match 'Docker') 'Docker Desktop open: quit it first (it would start WSL again)'
Check ((Get-VDiskProblem $wd $none) -eq '') 'WSL running is no reason: YSO stops it just before'
$sc = Get-VhdxCompactScript 'C:\Users\me\wsl\ext4.vhdx'
Check ($sc -match 'select vdisk file="C:\\Users\\me\\wsl\\ext4\.vhdx"' -and $sc -match 'attach vdisk readonly' -and $sc -match 'compact vdisk' -and $sc -match 'detach vdisk') 'a .vhdx is compacted read-only with diskpart (works on every edition of Windows)'

Write-Host "`n===== THE LAST WARNING, THEN COMPACTING =====" -ForegroundColor White
New-Item -ItemType Directory -Force "$Sandbox/disks" | Out-Null
function New-Disk([string]$Kind, [string]$Name, [long]$Size) {
    $p = "$Sandbox/disks/$Name.$(if ($Kind -eq 'VirtualBox') { 'vdi' } else { 'vhdx' })"
    $fs = [System.IO.File]::Create($p); $fs.SetLength($Size); $fs.Dispose()
    return [pscustomobject]@{ Kind = $Kind; Name = $Name; Path = $p; Size = $Size; Machine = $(if ($Kind -eq 'VirtualBox') { $off } else { $null }); Capacity = 0; Ready = $true; Why = '' }
}
$script:Answers = New-Object System.Collections.Queue
function Read-Choice { param([string]$Prompt, [object[]]$Buttons, [string]$Hint, [switch]$KeepCase) return [string]$script:Answers.Dequeue() }
function Confirm-Action { param([string]$Question, [bool]$Default) $script:Asked = $Question; return [bool]$script:Answers.Dequeue() }
function Clear-Host { }
$script:Done = @()
function Invoke-VdiCompact([string]$Path) { $script:Done += "vdi $Path"; $fs = [System.IO.File]::Open($Path, 'Open'); $fs.SetLength(4MB); $fs.Dispose(); return 0 }
function Invoke-VhdxCompact([string]$Path) { $script:Done += "vhdx $Path"; $fs = [System.IO.File]::Open($Path, 'Open'); $fs.SetLength(2MB); $fs.Dispose(); return 0 }
$script:WslStopped = $false
function Stop-Wsl([object[]]$Disks) { $script:WslStopped = $true; return $true }
function Get-VBoxMachines { return @($off) }
$script:List = @()
function Get-VirtualDisks { return $script:List }

$script:List = @((New-Disk 'VirtualBox' 'Ubuntu VM' 10MB), (New-Disk 'WSL' 'Ubuntu' 8MB))
$script:Answers.Enqueue('A'); $script:Answers.Enqueue($false)
$script:Results.Clear()
Invoke-VDiskCompact 6>$null
Check ($script:Asked -eq 'Compact now?' -and $script:Done.Count -eq 0 -and -not $script:WslStopped) 'answering No to the last warning: nothing is touched, WSL is not stopped'
$script:Answers.Enqueue('A'); $script:Answers.Enqueue($true)
Invoke-VDiskCompact 6>$null
$res = @($script:Results | Where-Object { $_.Category -eq 'Virtual disks' })
Check ($script:WslStopped -and $script:Done.Count -eq 2 -and $res.Count -eq 1 -and $res[0].Bytes -eq (6MB + 6MB) -and $res[0].Files -eq 2) "Yes: WSL is stopped first, both disks are compacted and the space freed is counted ($(@($script:Done).Count) done)"
$script:Done = @(); $script:Results.Clear(); $script:InUse = $true
$script:List = @((New-Disk 'VirtualBox' 'Started meanwhile' 10MB))
$script:Answers.Enqueue('1'); $script:Answers.Enqueue($true)
Invoke-VDiskCompact 6>$null
Check ($script:Done.Count -eq 0 -and $script:Results.Count -eq 0) 'checked again right before: a machine started meanwhile is not compacted'
$script:InUse = $false
$script:List = @((New-Disk 'VirtualBox' 'Saved one' 10MB))
$script:List[0].Ready = $false; $script:List[0].Why = 'in saved state: start it, then shut it down from inside'
$script:Answers.Enqueue('0')
$out = (Invoke-VDiskCompact 6>&1 | Out-String)
Check ($script:Done.Count -eq 0 -and $out -match 'saved state' -and $out -match 'No disk can be compacted') 'nothing ready: the reason is shown next to the disk, nothing is asked or done'
$script:DryRun = $true
$script:List = @((New-Disk 'WSL' 'Ubuntu' 8MB))
Invoke-VDiskCompact 6>$null
Check ($script:Done.Count -eq 0 -and $script:Answers.Count -eq 0) 'Analyze-only mode: the list, and nothing else'
$script:DryRun = $false

Write-Host ("`nRESULT: {0}" -f $(if ($script:fail) { "$($script:fail) FAILURE(S)" } else { 'ALL CHECKS PASSED' })) -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
