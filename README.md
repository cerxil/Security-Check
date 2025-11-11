# Security Check

Quickly view your system’s security configuration — including UEFI mode, Secure Boot, TPM, virtualization, and key Windows security services.

![Output](https://raw.githubusercontent.com/cerxil/Security-Check/refs/heads/main/Security-Check-Image.png)

---

## How It Works

1. The script automatically gathers detailed hardware and firmware security information.
2. It checks for Secure Boot, TPM, and UEFI mode status.
3. It detects CPU virtualization, VBS, and Memory Integrity configuration.
4. It verifies that key Windows security services (Defender, Security Center, LSASS) are running.
5. Results are displayed in an easy-to-read color-coded summary.

---

## What It Checks

* Motherboard and BIOS information
* Boot mode (UEFI or Legacy)
* Secure Boot status
* TPM (Trusted Platform Module) presence and activation
* CPU virtualization (VT-x / AMD-V)
* Virtualization-Based Security (VBS) and Memory Integrity (HVCI)
* Core Windows security services (Defender, Security Center, LSASS)

---

## How to Run

You have two options:

### 1. Download and Run Manually (Offline)

1. Download [`Security-Check.ps1`](https://github.com/cerxil/Security-Check/blob/main/Security-Check.ps1) from this repository.
2. Right-click the file and select **Run with PowerShell**, or run it manually from PowerShell.
   *(Administrator privileges are optional but recommended.)*

### 2. One-Time Execution via PowerShell

Run the script directly from GitHub:

```powershell
irm https://raw.githubusercontent.com/cerxil/Security-Check/refs/heads/main/Security-Check.ps1 | iex
```

> Note: You may need to allow script execution:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## Troubleshooting

* Run PowerShell **as Administrator** if permission errors occur.
* Some checks may display “Unavailable” on virtual machines or unsupported systems.
* The script is **read-only** and does not modify any system settings.

---

If something doesn’t work as expected, feel free to [open an issue](https://github.com/cerxil/Security-Check/issues).
