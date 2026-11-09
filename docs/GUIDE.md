# YSO guide

What each tool does, what it changes, and how to undo it. The same guide is in YSO: Help, in the window, or G in the console menu.

**[Version française](GUIDE.fr.md)**

## Contents

- [Getting started](#getting-started)
  - [How YSO works](#how-yso-works)
  - [What YSO never touches](#what-yso-never-touches)
  - [The Clean page](#the-clean-page)
- [Clean](#clean)
  - [1. Temporary files](#1-temporary-files)
  - [2. Browser caches](#2-browser-caches)
  - [3. System junk (reports, dumps, old logs)](#3-system-junk-reports-dumps-old-logs)
  - [4. Windows Update cache](#4-windows-update-cache)
  - [5. Recycle Bin](#5-recycle-bin)
  - [6. GPU shader caches](#6-gpu-shader-caches)
  - [7. Developer & app caches](#7-developer--app-caches)
  - [8. Deep clean (Disk Cleanup)](#8-deep-clean-disk-cleanup)
  - [9. Old Windows version (Windows.old)](#9-old-windows-version-windowsold)
  - [10. Hibernation file](#10-hibernation-file)
- [Network](#network)
  - [11. Network check (speed, DNS, Wi-Fi)](#11-network-check-speed-dns-wi-fi)
  - [12. Change DNS servers](#12-change-dns-servers)
  - [13. Flush DNS cache](#13-flush-dns-cache)
  - [14. Full network reset](#14-full-network-reset)
- [Optimize](#optimize)
  - [15. Optimize drives (TRIM / defrag)](#15-optimize-drives-trim--defrag)
  - [16. Power plan](#16-power-plan)
  - [17. Startup programs](#17-startup-programs)
  - [18. Boot time analyzer](#18-boot-time-analyzer)
- [Apps & privacy](#apps--privacy)
  - [30. Privacy & ads (Windows, Edge, Copilot)](#30-privacy--ads-windows-edge-copilot)
  - [31. Uninstall apps (and their leftovers)](#31-uninstall-apps-and-their-leftovers)
  - [32. Undo YSO changes](#32-undo-yso-changes)
- [Diagnose & repair](#diagnose--repair)
  - [19. System health report](#19-system-health-report)
  - [20. Crashes & errors](#20-crashes--errors)
  - [21. Security check & Defender scan](#21-security-check--defender-scan)
  - [22. What runs automatically? (audit)](#22-what-runs-automatically-audit)
  - [23. Driver problems](#23-driver-problems)
  - [24. Check drives for errors](#24-check-drives-for-errors)
  - [25. Memory test](#25-memory-test)
  - [26. Repair Windows files (DISM + SFC)](#26-repair-windows-files-dism--sfc)
- [Space & updates](#space--updates)
  - [27. Space finder (what fills my disk?)](#27-space-finder-what-fills-my-disk)
  - [28. Updates: apps & drivers](#28-updates-apps--drivers)
  - [29. Virtual disks (compact VMs, WSL, Docker)](#29-virtual-disks-compact-vms-wsl-docker)
- [One-click](#one-click)
  - [A. Analyze (deletes nothing)](#a-analyze-deletes-nothing)
  - [F. Full maintenance](#f-full-maintenance)
  - [R. Restore points](#r-restore-points)
  - [S. Weekly auto-clean](#s-weekly-auto-clean)
  - [H. Cleanup history](#h-cleanup-history)
  - [T. Self-test (check everything)](#t-self-test-check-everything)
  - [P. Report a problem](#p-report-a-problem)
  - [O. Settings / Langue](#o-settings--langue)
  - [L. Logs folder](#l-logs-folder)
- [YSO itself](#yso-itself)
  - [Icon next to the clock](#icon-next-to-the-clock)
  - [New versions of YSO](#new-versions-of-yso)
  - [Uninstall YSO](#uninstall-yso)

## Getting started

### How YSO works

YSO looks after Windows: it frees space, checks the health of the PC, installs updates and fixes common problems. The home page shows the state of the PC in green, orange or red, and each card has the button that helps. Every tool says what it does while it works, asks its questions with buttons, and can be stopped.

**What changes.** YSO needs administrator rights (one Windows prompt), because it cleans system folders and changes Windows settings. It asks before it changes anything, except the cleanups you start yourself.

**To undo it.** Settings YSO changes can be put back with Undo YSO changes (32). The files it deletes are temporary files and caches: Windows and your apps make them again when they need them.

**Step by step:**

1. Click Analyze: YSO measures what can be freed, and deletes nothing.
2. On the Clean page, untick what you want to keep, then click Clean selected.
3. Once a month, run Full maintenance, or switch on Weekly auto-clean.

### What YSO never touches

YSO never deletes your passwords, cookies, browsing history, bookmarks, site data, messages, Downloads, Documents, browser extensions or game files. Files in use are skipped, recent temporary files are kept (24 hours by default), folder links are never followed, and system folders are refused.

**What changes.** What cannot be undone is always asked separately: emptying the Recycle Bin, old driver versions, Windows.old, old restore points, a network reset. Full maintenance and driver updates create a restore point first.

**To undo it.** In Settings (O) you can list folders YSO must never touch. Started with -DryRun, YSO is in analyze-only mode: it shows everything and changes nothing. Each session is written to C:\ProgramData\YSO\Logs.

### The Clean page

The Clean page lists every part YSO can clean, with a sentence on what it is. Analyze shows how much each part frees. Tick what you want, then click Clean selected.

**What changes.** The ticked parts are cleaned one after the other, with a progress bar and what each one freed. The Recycle Bin and old driver versions are cleaned only if you tick them.

**To undo it.** Deleted temporary files and caches do not go to the Recycle Bin: Windows and your apps make them again when they need them.

## Clean

### 1. Temporary files

Deletes the temporary files of every user of the PC and of Windows. Apps leave them behind after installs, updates and crashes.

**What changes.** Only files older than 24 hours (you can change it in Settings), and never a file that is in use.

**To undo it.** Not needed: apps make new temporary files when they need them.

### 2. Browser caches

Deletes the copies of web pages, images and scripts that Chrome, Edge, Brave, Vivaldi, Opera and Firefox keep, in every profile. Pages load from the internet again the first time.

**What changes.** Passwords, cookies, history, bookmarks, open tabs and extensions are not touched. If a browser is open, YSO offers to close it for a complete clean; its tabs come back when you open it again.

**To undo it.** Not needed: the browser fills its cache again as you browse.

### 3. System junk (reports, dumps, old logs)

Deletes error reports, crash dumps (also those in the temporary folders of Windows services, sometimes several GB), logs older than 14 days and the thumbnail cache.

**What changes.** Recent logs and dumps are kept, so a recent crash can still be looked at. The Prefetch folder is never touched: emptying it would make Windows slower.

**To undo it.** Not needed. Thumbnails are made again when you open a folder.

### 4. Windows Update cache

Deletes update files Windows has already installed, and the Delivery Optimization cache (updates shared with other PCs).

**What changes.** If updates are waiting for a restart, or Windows Update is busy, the cache is kept: restart, then run it again.

**To undo it.** Not needed: Windows downloads again what it still needs.

### 5. Recycle Bin

Empties the Recycle Bin of every drive.

**What changes.** YSO always asks first, and shows how much it holds.

**To undo it.** Cannot be undone: files emptied from the Recycle Bin are gone.

### 6. GPU shader caches

Deletes the compiled shaders that NVIDIA, AMD, Intel and DirectX keep. Most useful after a driver update, or when a game shows graphics glitches.

**What changes.** Games make them again on their next launch, so the first load may stutter briefly.

**To undo it.** Not needed: they come back by themselves.

### 7. Developer & app caches

Deletes the caches and old logs of npm, pip, VS Code, Discord, Teams, Spotify, Steam and every app built on Chromium.

**What changes.** Projects, installed packages, settings, logins and game files are not touched. For VS Code, the saved data of projects not opened for 60 days goes too (it comes back if you open them again).

**To undo it.** Not needed: apps rebuild their caches.

### 8. Deep clean (Disk Cleanup)

Runs Windows Disk Cleanup with every safe option, then cleans the component store (old versions of Windows files kept after updates). Frees a lot, and takes 10 to 30 minutes.

**What changes.** Downloads, the Recycle Bin and Windows.old are never included. Old driver versions are removed only if you say yes. Part of the cleanup finishes at the next restart.

**To undo it.** Afterwards, updates installed before it can no longer be uninstalled, and removed driver versions cannot come back.

### 9. Old Windows version (Windows.old)

Windows.old holds the previous version of Windows after a big update, so you can go back to it for 10 days. It often takes 15 to 30 GB.

**What changes.** YSO shows its size and whether going back is still possible, then asks.

**To undo it.** Cannot be undone: once it is removed, you can no longer go back to the previous version of Windows.

### 10. Hibernation file

hiberfil.sys can take several GB. Windows uses it for Hibernate and Fast Startup. Reduced keeps Fast Startup and halves it, Off removes it, Full is the Windows default.

**What changes.** On a laptop, Hibernate saves your work when the battery runs out: keep Reduced or Full there.

**To undo it.** Undo YSO changes (32) puts the previous setting back, or choose Full here.

## Network

### 11. Network check (speed, DNS, Wi-Fi)

Measures the link to your router, the time it takes to reach the internet, the speed of several DNS servers and the Wi-Fi signal, and says where a problem comes from.

**What changes.** Nothing is changed.

**To undo it.** Nothing to undo.

### 12. Change DNS servers

DNS turns site names into addresses. Your provider's DNS can be slow; Cloudflare, Google or Quad9 are often faster, and some block dangerous sites. Network check (11) shows which one is fastest for you.

**What changes.** YSO saves your current DNS settings first, then sets the new ones on every connected adapter.

**To undo it.** Option 4 on the same screen puts your previous settings back, and so does Undo YSO changes (32).

### 13. Flush DNS cache

Empties the list of site addresses Windows remembers. Helps when a site moved, or will not load after a change of DNS or of network.

**What changes.** Nothing else changes: sites are looked up again.

**To undo it.** Nothing to undo.

### 14. Full network reset

Resets Winsock and the TCP/IP settings of Windows. A last resort when the internet does not work and nothing else helped.

**What changes.** It erases IP and DNS settings typed by hand, can disturb VPN or proxy software until it is set up again, and needs a restart. Your network settings are saved to a file in the logs folder first.

**To undo it.** Cannot be undone automatically: the saved file lists your previous settings, so you can type them again.

## Optimize

### 15. Optimize drives (TRIM / defrag)

Asks Windows to optimize each drive: TRIM for SSDs (it tells the drive which blocks are free) and defragmentation for hard drives.

**What changes.** The same as Windows' own Optimize Drives tool. Safe for SSDs: Windows never defragments them.

**To undo it.** Nothing to undo.

### 16. Power plan

Chooses between Ultimate Performance, High Performance and Balanced. Performance plans keep the processor ready, for a slightly faster PC.

**What changes.** On a laptop they mean more heat, more fan noise and less battery: Balanced is better there.

**To undo it.** Undo YSO changes (32), or choose Balanced here.

### 17. Startup programs

Lists the programs that start with Windows, with their publisher and how much they slow down startup. Click one to switch it on or off.

**What changes.** It works like Task Manager: the program stays installed and only stops starting by itself. Microsoft Store apps manage their own startup, in Windows Settings.

**To undo it.** Click it again, or use Undo YSO changes (32).

### 18. Boot time analyzer

Reads how long the last startups took, from Windows' own records, and which apps, drivers and services slowed them down.

**What changes.** Nothing is changed. Only full startups are measured: Restart, or Shut down when Fast Startup is off.

**To undo it.** Nothing to undo.

## Apps & privacy

### 30. Privacy & ads (Windows, Edge, Copilot)

Switches off, with tick boxes: ads and suggestions in Windows, tips on the lock screen, web results (Bing) in the Start menu search, ad tracking, diagnostic data and activity history, Copilot, Recall and Click to Do, the AI features of Edge, Notepad and Paint, and ads in Edge.

**What changes.** These are the settings Windows and Edge offer for it. Some are policies: Windows or Edge then shows "managed by your organization", which is normal. Some changes show after you sign out. Defender, Windows Update and the Store are never touched.

**To undo it.** Untick a line and Apply to get the Windows default back, or use Undo YSO changes (32) for the exact previous state.

**Step by step:**

1. Tick what you do not want, or click Tick the recommended ones.
2. Click Apply, read the list of changes, and confirm.
3. Sign out and back in, or let YSO restart File Explorer when it offers to.

### 31. Uninstall apps (and their leftovers)

Lists your desktop apps with their size and when they were last used. YSO starts the app's own uninstaller, then looks for what it left behind: folders and registry keys named like it.

**What changes.** YSO never offers the folder of another installed app, a system folder, or a name another app also uses. Folders of 1 GB or more start unticked: a folder can hold your own data, like game saves or a mail profile. Runtimes and drivers get a warning.

**To undo it.** The app can be installed again. Removed folders go to the Recycle Bin and registry keys are saved to a file first: Undo YSO changes (32) puts them back.

**Step by step:**

1. Find the app: sort by size or by last use, or type part of its name.
2. Click it, read what YSO shows about it, and confirm.
3. Follow the window of its uninstaller to the end.
4. Among the leftovers, untick what you want to keep, then click Remove the ticked ones.

### 32. Undo YSO changes

Every setting YSO changes is written down first, with what it was before: startup programs, power plan, hibernation file, DNS, privacy settings and app leftovers. This list shows them, newest first.

**What changes.** Click one to see what it changed, then confirm: it is back exactly as it was. Cleaned files are not in this list: they are caches that come back by themselves.

**To undo it.** An undone change is marked as such. The last 300 changes are kept.

## Diagnose & repair

### 19. System health report

Everything about the PC in one report: Windows and hardware, disk space and wear, battery capacity, Windows Update, recent crashes, security and drivers. For each problem, an arrow shows the tool that helps.

**What changes.** Nothing is changed. It can make Windows' detailed battery report, which opens in your browser.

**To undo it.** Nothing to undo.

### 20. Crashes & errors

Shows the recent blue screens, app crashes and serious errors from Windows' logs, and what caused them when Windows knows.

**What changes.** Nothing is changed. A few errors are normal on every PC: look for the ones that repeat, or happen when you have a problem.

**To undo it.** Nothing to undo.

### 21. Security check & Defender scan

Checks the antivirus, the firewall and Windows Update. With Microsoft Defender, it can update the virus definitions and run a quick scan (5 to 15 minutes).

**What changes.** Only Defender's own update and scan: no setting is changed.

**To undo it.** Nothing to undo.

### 22. What runs automatically? (audit)

Lists the scheduled tasks and services that do not come from Microsoft, and whether their program is signed. Takes 10 to 60 seconds.

**What changes.** Nothing is changed. Not signed does not mean malware. To remove something, uninstall the program it belongs to.

**To undo it.** Nothing to undo.

### 23. Driver problems

Lists the devices with a missing or broken driver, then helps: Device Manager, optional driver updates in Windows Update, or a new scan of the hardware.

**What changes.** Nothing is changed unless you choose one of these actions.

**To undo it.** Nothing to undo.

### 24. Check drives for errors

Scans each drive for file-system errors, while you keep working.

**What changes.** If errors are found, YSO asks before repairing: other drives are repaired at once, the Windows drive at the next restart, before Windows loads.

**To undo it.** A repair cannot be undone, but it only fixes the records of the file system.

### 25. Memory test

Starts Windows Memory Diagnostic, which checks the RAM for faults, a common cause of blue screens and random crashes. It runs after a restart, before Windows loads, and takes 10 to 30 minutes.

**What changes.** Save your work first. The result shows as a notification when Windows starts again, and here next time.

**To undo it.** Nothing to undo.

### 26. Repair Windows files (DISM + SFC)

Runs DISM, which repairs Windows' store of system files (it needs internet), then SFC, which repairs the system files from that store. Takes 15 to 45 minutes.

**What changes.** Only Windows' own files are repaired, with Windows' own tools.

**To undo it.** Nothing to undo: the repaired files are the original ones.

## Space & updates

### 27. Space finder (what fills my disk?)

Shows which folders fill a drive, biggest first. Click a folder to open it, Back to go up, Biggest files to see the largest files, Show in Explorer to open it there.

**What changes.** Nothing is changed or deleted: it only shows. Delete what you do not need yourself, in File Explorer.

**To undo it.** Nothing to undo.

### 28. Updates: apps & drivers

Finds app updates (with winget) and driver updates (with Windows Update), and shows them in one list where you tick what to install. YSO can also check on a schedule and tell you, or install safe updates by itself.

**What changes.** A restore point is made before drivers are installed. In automatic mode, big new versions (7.x to 8.x), optional drivers and the apps you exclude are left for you. Only apps in the winget catalog are checked.

**To undo it.** An app can be uninstalled, then its previous version installed from its website. A driver can be rolled back in Device Manager, or with the restore point.

**Step by step:**

1. Click Check for updates now.
2. Tick what to install, then click Install the ticked updates.
3. If you want, choose Notify me or Automatic, and when it runs.

### 29. Virtual disks (compact VMs, WSL, Docker)

The disk of a virtual machine is one big file on your PC (.vdi for VirtualBox, .vhdx for WSL and Docker Desktop). It grows when the machine writes, but never shrinks, even when you delete files inside it. Compacting removes the empty space from the file: the file gets smaller, and nothing inside the machine changes.

**What changes.** YSO refuses a machine that is running, in saved state or with snapshots, and wants VirtualBox and Docker Desktop closed. The file is rewritten in place: a power cut or a crash during compaction can damage it.

**To undo it.** Compacting cannot be undone, and does not need to be. Copy a disk you cannot lose before, so you can put it back if something goes wrong.

**Step by step:**

1. VirtualBox: compacting only removes empty blocks, and deleted files are not empty until the free space is filled with zeros. Inside the machine, run sdelete -z C: (Windows) or the dd command YSO shows (Linux), then shut the machine down from inside.
2. WSL and Docker: nothing to do inside. YSO frees the unused blocks and stops WSL by itself.
3. Copy the disk file of the machine somewhere else, an external drive for example: that is your backup.
4. Keep the PC plugged in. Open Virtual disks, check that the disk says it can be compacted, and confirm.
5. Start the machine to check that it works. Then you can delete the copy.

## One-click

### A. Analyze (deletes nothing)

Measures how much each part of the cleaning would free. Deletes nothing.

**What changes.** Nothing is changed. Deep clean (8) usually frees more on top of it, but cannot be measured in advance.

**To undo it.** Nothing to undo.

### F. Full maintenance

Everything at once: a restore point, then temporary files, browser caches, offline copies of sites, system junk, developer and app caches, GPU caches, the Windows Update cache, DNS, deep clean, and drive optimization. The Recycle Bin and updates only if you choose them.

**What changes.** All the questions are asked at the start, then you can walk away. If Windows is waiting for a restart, restart first: some parts can only be cleaned after it.

**To undo it.** The restore point (R) takes Windows and its settings back to before; your documents are not touched by it.

### R. Restore points

A restore point takes Windows, its settings and your programs back to an earlier state. Your documents are not touched. Here you see yours, create one, keep only the newest, or open System Protection.

**What changes.** Deleting old restore points is asked separately, and cannot be undone.

**To undo it.** To go back to a restore point: System Protection, then System Restore.

### S. Weekly auto-clean

Cleans by itself every Sunday at 3:00 (or at the next startup if the PC was off), silently, and only when plugged in. You choose what it cleans in Settings.

**What changes.** It never closes your apps and never empties the Recycle Bin. It runs as a scheduled task, from C:\Program Files\YSO.

**To undo it.** Turn it off here, at any time.

### H. Cleanup history

Shows what each cleanup freed, with its date, its parts and its total.

**What changes.** Nothing is changed.

**To undo it.** Nothing to undo.

### T. Self-test (check everything)

Checks that each part of YSO works on this PC, one line per check. A BROKEN line says what does not work, and why.

**What changes.** Nothing is changed.

**To undo it.** Nothing to undo.

### P. Report a problem

Makes one zip file on your Desktop with the self-test, the error log and recent logs, to send to the developer (a GitHub issue, an email...).

**What changes.** User names, the PC name, private IP addresses and the Wi-Fi name are removed from it. Nothing is sent by itself: open it and check it before you send it.

**To undo it.** Delete the zip when you no longer need it.

### O. Settings / Langue

Language, how old temporary files and logs must be before YSO deletes them, what weekly auto-clean cleans, folders YSO must never touch, new versions of YSO, and the icon next to the clock.

**What changes.** Saved in C:\ProgramData\YSO\settings.json. Reset to defaults puts everything back as after installing.

**To undo it.** Change it back here, or use Reset to defaults.

### L. Logs folder

Opens the folder where YSO writes what it did in each session, and its errors.

**What changes.** Nothing is changed.

**To undo it.** Nothing to undo.

## YSO itself

### Icon next to the clock

Optional, in Settings (option 9). Every 6 hours it checks free space, the drives and the battery, and tells you when something needs you, at most once a week for each thing. It also tells you what the weekly cleanup freed. Right-click it to open YSO or to check now.

**What changes.** It starts with Windows (a scheduled task) and only reads. Uninstalling YSO removes it.

**To undo it.** Right-click it, then Remove this icon, or use option 9 in Settings.

### New versions of YSO

When a new version is published, an Update button appears in YSO. It downloads the new version from GitHub, checks its SHA-256 checksum and that PowerShell can read it, then replaces YSO. Your settings and history stay.

**What changes.** YSO asks GitHub at most once an hour, when its window opens; you can turn it off in Settings. Installed from the Microsoft Store, YSO is updated by the Store instead.

**To undo it.** To go back to an earlier version, download it from the Releases page of YSO on GitHub.

### Uninstall YSO

Settings > Apps > Installed apps > YSO > Uninstall. YSO asks whether to keep its history and settings.

**What changes.** Its weekly cleanup, automatic updates and the icon next to the clock stop too.

**To undo it.** Install it again with the same line as the first time.
