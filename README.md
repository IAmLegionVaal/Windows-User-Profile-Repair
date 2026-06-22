# Windows User Profile Repair

> **Testing note:** This was tested by me to be working. User experience may vary.

## One-click use

1. Sign in to the affected Windows account.
2. Download and extract the repository.
3. Double-click `Run-OneClick.bat` and approve the administrator prompt.
4. The launcher preserves the signed-in user SID across elevation, backs up the profile registry area, applies the guarded state repair and verifies the values. There is no menu.
5. Restart Windows before testing the profile and review logs in `C:\ProgramData\WindowsUserProfileRepair\Logs`.

Included: `Repair-WindowsUserProfile.ps1`

## PowerShell usage

```powershell
.\Repair-WindowsUserProfile.ps1
.\Repair-WindowsUserProfile.ps1 -Sid 'S-1-5-21-...'
.\Repair-WindowsUserProfile.ps1 -Sid 'S-1-5-21-...' -RepairState
.\Repair-WindowsUserProfile.ps1 -Sid 'S-1-5-21-...' -RepairState -WhatIf
```

The default mode reports profile registration and status. `-RepairState` requires administrator rights, creates a registry backup, resets the selected profile’s `State` and `RefCount` values, and verifies both values afterward. It refuses automatic repair when duplicate normal and `.bak` keys exist.

Exit codes: `0` success, `1` fatal error, `2` repair verification warnings.

Profile registry changes carry risk. Verify the SID and maintain a backup before use.

MIT License.
