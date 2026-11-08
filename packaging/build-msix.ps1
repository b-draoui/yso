<#
.SYNOPSIS
    Builds YSO.msix, the Microsoft Store package of YSO (see docs/STORE.md).

.DESCRIPTION
    Needs Windows with the Windows SDK (makeappx.exe) and the .NET Framework 4 compiler (csc.exe),
    as on GitHub's Windows runners. The package identity comes from Partner Center (repository
    variables STORE_IDENTITY, STORE_PUBLISHER, STORE_PUBLISHER_NAME); without them a test
    identity is used, good for a test install only.

    The package holds YSO.ps1 as it is, YSO.exe (a small launcher, packaging/launcher) and the
    YSO mark drawn by YSO itself. Version: the version of YSO with a 0 at the end (1.0.1 -> 1.0.1.0),
    as the Store asks (the last number is the Store's).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File packaging\build-msix.ps1
#>
param(
    [string]$OutDir = (Join-Path $PSScriptRoot 'out'),
    [string]$Identity = $env:STORE_IDENTITY,
    [string]$Publisher = $env:STORE_PUBLISHER,
    [string]$PublisherName = $env:STORE_PUBLISHER_NAME
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$yso = Join-Path $repo 'YSO.ps1'
if (-not $Identity) { $Identity = 'YSO.Test' }
if (-not $Publisher) { $Publisher = 'CN=YSO Test' }
if (-not $PublisherName) { $PublisherName = 'YSO' }
$m = [regex]::Match((Get-Content -LiteralPath $yso -Raw), "\`$script:Version\s*=\s*'(\d+)\.(\d+)(?:\.(\d+))?'")
if (-not $m.Success) { throw 'The version of YSO was not found in YSO.ps1.' }
$patch = $(if ($m.Groups[3].Success) { $m.Groups[3].Value } else { '0' })
$version = '{0}.{1}.{2}.0' -f $m.Groups[1].Value, $m.Groups[2].Value, $patch

$stage = Join-Path $OutDir 'package'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
$assets = Join-Path $stage 'Assets'
New-Item -ItemType Directory -Path $assets -Force | Out-Null
Copy-Item -LiteralPath $yso -Destination $stage

# The images: the YSO mark, drawn by YSO's own New-YsoLogo, on transparent tiles
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$ast = [System.Management.Automation.Language.Parser]::ParseFile($yso, [ref]$null, [ref]$null)
foreach ($name in 'New-YsoLogo', 'Save-YsoIcon') {
    $fn = $ast.Find({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -eq $name }, $true)
    . ([scriptblock]::Create($fn.Extent.Text))
}
function Save-Png($Bitmap, [string]$Path) {
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($Bitmap))
    $fs = [System.IO.File]::Create($Path)
    try { $enc.Save($fs) } finally { $fs.Close() }
}
function New-Tile([int]$Width, [int]$Height, [double]$Scale) {
    $s = [int]([math]::Min($Width, $Height) * $Scale)
    $v = New-Object System.Windows.Media.DrawingVisual
    $dc = $v.RenderOpen()
    $dc.DrawImage((New-YsoLogo $s), (New-Object System.Windows.Rect ([double](($Width - $s) / 2)), ([double](($Height - $s) / 2)), ([double]$s), ([double]$s)))
    $dc.Close()
    $bmp = New-Object System.Windows.Media.Imaging.RenderTargetBitmap $Width, $Height, 96, 96, ([System.Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($v)
    return $bmp
}
Save-Png (New-Tile 44 44 1.0) (Join-Path $assets 'Square44x44Logo.png')
Save-Png (New-Tile 50 50 1.0) (Join-Path $assets 'StoreLogo.png')
Save-Png (New-Tile 150 150 0.66) (Join-Path $assets 'Square150x150Logo.png')
Save-Png (New-Tile 310 150 0.66) (Join-Path $assets 'Wide310x150Logo.png')
$ico = Join-Path $OutDir 'YSO.ico'
Save-YsoIcon $ico

# The launcher (YSO.exe)
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
$src = Join-Path $PSScriptRoot 'launcher'
& $csc /nologo /target:winexe /platform:anycpu /optimize+ /reference:System.Windows.Forms.dll "/win32manifest:$src\app.manifest" "/win32icon:$ico" "/out:$stage\YSO.exe" "$src\YSOLauncher.cs"
if ($LASTEXITCODE -ne 0) { throw "The launcher did not compile (csc exit code $LASTEXITCODE)." }

# The manifest, with the identity from Partner Center
$esc = { param($t) [System.Security.SecurityElement]::Escape($t) }
$xml = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Raw
$xml = $xml.Replace('__IDENTITY__', (& $esc $Identity)).Replace('__PUBLISHER_NAME__', (& $esc $PublisherName))
$xml = $xml.Replace('__PUBLISHER__', (& $esc $Publisher)).Replace('__VERSION__', $version)
[System.IO.File]::WriteAllText((Join-Path $stage 'AppxManifest.xml'), $xml, (New-Object System.Text.UTF8Encoding $false))

# The package
$kits = @(Get-ChildItem -Path "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\makeappx.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Parent.Name -match '^\d+(\.\d+){3}$' } | Sort-Object { [version]$_.Directory.Parent.Name } -Descending)
if ($kits.Count -eq 0) { throw 'makeappx.exe was not found: install the Windows SDK.' }
$msix = Join-Path $OutDir 'YSO.msix'
& $kits[0].FullName pack /o /d $stage /p $msix
if ($LASTEXITCODE -ne 0) { throw "makeappx failed (exit code $LASTEXITCODE)." }
Write-Host "YSO.msix $version ($Identity, $Publisher): $msix"
