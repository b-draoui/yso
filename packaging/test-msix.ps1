<#
.SYNOPSIS
    Installs the package made by build-msix.ps1 on this PC, checks it, and removes it again.

.DESCRIPTION
    For automated testing (GitHub's Windows runners). The package is signed with a certificate
    made for this test only, trusted on this PC only. The Store signs the real one.
#>
$ErrorActionPreference = 'Stop'
$out = Join-Path $PSScriptRoot 'out'
[xml]$m = Get-Content -LiteralPath (Join-Path $out 'package\AppxManifest.xml') -Raw
$publisher = $m.Package.Identity.Publisher
$name = $m.Package.Identity.Name
$signtool = @(Get-ChildItem -Path "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Parent.Name -match '^\d+(\.\d+){3}$' } | Sort-Object { [version]$_.Directory.Parent.Name } -Descending)[0].FullName

$cert = New-SelfSignedCertificate -Type Custom -Subject $publisher -KeyUsage DigitalSignature -FriendlyName 'YSO test package' `
    -CertStoreLocation 'Cert:\CurrentUser\My' -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
$test = Join-Path $out 'YSO-test-signed.msix'
Copy-Item -LiteralPath (Join-Path $out 'YSO.msix') -Destination $test -Force
& $signtool sign /fd SHA256 /sha1 $cert.Thumbprint /s My $test
if ($LASTEXITCODE -ne 0) { throw "signtool failed (exit code $LASTEXITCODE)." }
$cer = Join-Path $out 'test.cer'
Export-Certificate -Cert $cert -FilePath $cer | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null

try {
    Add-AppxPackage -Path $test
    $pkg = Get-AppxPackage -Name $name
    if (-not $pkg) { throw 'The package is not installed.' }
    Write-Host "Installed: $($pkg.PackageFullName)"
    Write-Host "Folder:    $($pkg.InstallLocation)"
    foreach ($f in 'YSO.exe', 'YSO.ps1', 'AppxManifest.xml', 'Assets\Square44x44Logo.png') {
        if (-not (Test-Path -LiteralPath (Join-Path $pkg.InstallLocation $f))) { throw "Missing in the package: $f" }
    }
    # YSO knows it runs from the Store package (no self-update, no install of its own there)
    $ps1 = Join-Path $pkg.InstallLocation 'YSO.ps1'
    $probe = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". '$ps1' -Engine; if (`$script:IsPackaged) { 'packaged' } else { 'not packaged' }"
    $said = "$(@($probe)[-1])".Trim()
    Write-Host "YSO in the package says: $said"
    if ($said -ne 'packaged') { throw 'YSO did not see that it runs from the Store package.' }
    Write-Host 'Store package: OK'
} finally {
    Get-AppxPackage -Name $name | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath 'Cert:\LocalMachine\TrustedPeople' | Where-Object { $_.Thumbprint -eq $cert.Thumbprint } | Remove-Item -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $cert.PSPath -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $test, $cer -Force -ErrorAction SilentlyContinue
}
