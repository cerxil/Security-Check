Write-Host "=== System Security Check ===`n"

$baseBoard = Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product
$vendor = $baseBoard.Manufacturer
$model  = $baseBoard.Product
Write-Host "Detected Motherboard: $vendor $model"

# --- BIOS / UEFI Information ---
$bios = Get-CimInstance Win32_BIOS
Write-Host "`nBIOS Vendor : $($bios.Manufacturer)"
Write-Host "BIOS Version: $($bios.SMBIOSBIOSVersion)"

if ($bios.ReleaseDate -is [string]) {
    $date = [datetime]::ParseExact($bios.ReleaseDate.Substring(0,8),'yyyyMMdd',$null)
} else {
    $date = $bios.ReleaseDate
}
Write-Host "BIOS Date   : $date`n"

# --- Boot Mode ---
try {
    $firmwareType = (Get-ComputerInfo).BiosFirmwareType
    Write-Host "Boot Mode   : $firmwareType"
} catch {
    Write-Host "Boot Mode   : Unknown" -ForegroundColor Yellow
}

# --- Secure Boot ---
function Get-SecureBootStatus {
    try {
        $sb = Confirm-SecureBootUEFI -ErrorAction Stop
        if ($sb) { return "Enabled" } else { return "Disabled" }
    } catch {
        # Registry fallback
        $reg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State" -ErrorAction SilentlyContinue
        if ($reg) {
            if ($reg.UEFISecureBootEnabled -eq 1) { return "Enabled" }
            else { return "Disabled" }
        } else {
            return "Unavailable"
        }
    }
}

$secureBootStatus = Get-SecureBootStatus
switch ($secureBootStatus) {
    "Enabled"      { Write-Host "Secure Boot : Enabled" -ForegroundColor Green }
    "Disabled"     { Write-Host "Secure Boot : Disabled" -ForegroundColor Red }
    default        { Write-Host "Secure Boot : Unavailable" -ForegroundColor Yellow }
}

# --- TPM ---
function Get-TPMStatus {
    try {
        $tpm = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction Stop
        if ($tpm.IsEnabled_InitialValue) { return "Enabled" }
        elseif ($tpm.IsActivated_InitialValue) { return "Present but disabled" }
        else { return "Present but inactive" }
    } catch {
        try {
            $tpm2 = Get-Tpm -ErrorAction Stop
            if ($tpm2.TpmPresent -and $tpm2.TpmReady) { return "Enabled" }
            elseif ($tpm2.TpmPresent) { return "Present but not ready" }
            else { return "Not found" }
        } catch {
            return "Unavailable"
        }
    }
}

$tpmStatus = Get-TPMStatus
switch ($tpmStatus) {
    "Enabled"      { Write-Host "TPM         : Enabled" -ForegroundColor Green }
    "Present but disabled" { Write-Host "TPM         : Present but disabled" -ForegroundColor Yellow }
    "Present but inactive" { Write-Host "TPM         : Present but inactive" -ForegroundColor Yellow }
    "Not found"    { Write-Host "TPM         : Not found" -ForegroundColor Red }
    default        { Write-Host "TPM         : Unavailable" -ForegroundColor Yellow }
}

Write-Host ""

# --- Virtualization & VBS ---
$vmSupport = Get-CimInstance Win32_Processor | Select-Object -ExpandProperty VirtualizationFirmwareEnabled -ErrorAction SilentlyContinue
if ($vmSupport -eq $true) {
    Write-Host "CPU Virtualization (VT-x/AMD-V): Enabled" -ForegroundColor Green
} else {
    Write-Host "CPU Virtualization (VT-x/AMD-V): Disabled or Unsupported" -ForegroundColor Red
}

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
$enableVBS = (Get-ItemProperty -Path $regPath -Name EnableVirtualizationBasedSecurity -ErrorAction SilentlyContinue).EnableVirtualizationBasedSecurity
$hvci = (Get-ItemProperty -Path "$regPath\Scenarios\HypervisorEnforcedCodeIntegrity" -Name Enabled -ErrorAction SilentlyContinue).Enabled

if ($enableVBS -eq 1) { Write-Host "Virtualization-Based Security (VBS): Enabled" -ForegroundColor Green }
else { Write-Host "Virtualization-Based Security (VBS): Disabled" -ForegroundColor Yellow }

if ($hvci -eq 1) { Write-Host "Memory Integrity (HVCI): Enabled" -ForegroundColor Green }
else { Write-Host "Memory Integrity (HVCI): Disabled" -ForegroundColor Yellow }

# --- Windows Security Services ---
$services = @(
    @{Name="WinDefend"; Label="Microsoft Defender Antivirus Service"},
    @{Name="wscsvc"; Label="Security Center"},
    @{Name="lsass"; Label="Local Security Authority Subsystem (LSASS)"}
)

foreach ($svc in $services) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service.Status -eq "Running") {
        Write-Host "$($svc.Label): Running" -ForegroundColor Green
    } else {
        Write-Host "$($svc.Label): Not Running" -ForegroundColor Red
    }
}

# --- Summary ---
Write-Host "`n=== Summary ==="
$issues = @()
if ($firmwareType -ne "UEFI") { $issues += "System not in UEFI mode" }
if ($secureBootStatus -ne "Enabled") { $issues += "Secure Boot not enabled" }
if ($tpmStatus -ne "Enabled") { $issues += "TPM not active or missing" }

if ($issues.Count -eq 0) {
    Write-Host "System is fully compliant with most anti-cheat and kernel protection requirements." -ForegroundColor Green
} else {
    Write-Host "Potential Issues Detected:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
}

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)
