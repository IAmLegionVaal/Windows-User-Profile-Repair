# Windows User Profile Repair

> **Testing note:** This was tested by me to be working. User experience may vary.

Included: `Repair-WindowsUserProfile.ps1`

```powershell
.\Repair-WindowsUserProfile.ps1
.\Repair-WindowsUserProfile.ps1 -Sid 'S-1-5-21-...' 
.\Repair-WindowsUserProfile.ps1 -Sid 'S-1-5-21-...' -RepairState
```

The default mode reports profile registration and status. `-RepairState` creates a registry backup and resets the selected profile’s State and RefCount values. It refuses automatic repair when duplicate normal and `.bak` keys exist.

Logs: `C:\ProgramData\WindowsUserProfileRepair\Logs`

Exit codes: `0` success, `1` fatal error. A restart is required after repair.

Profile registry changes carry risk. Verify the SID and maintain a backup before use.

MIT License.
