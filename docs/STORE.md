# YSO on the Microsoft Store

Everything YSO needs to be published on the Microsoft Store is in this repository. What is left needs your Partner Center account, so it is done by hand once.

Publishing on the Store is free for individual developers. The Store signs and hosts the package, installs it without a SmartScreen warning, and updates it for everyone.

## What is ready

| Part | Where |
|---|---|
| The package manifest (identity, icons, capabilities) | `packaging/AppxManifest.xml` |
| `YSO.exe`, a small launcher that starts `YSO.ps1` with Windows PowerShell 5.1, without a console window, as administrator | `packaging/launcher/` |
| The build: icons drawn from the YSO mark, the launcher compiled, `YSO.msix` packed | `packaging/build-msix.ps1` |
| A test: the package signed with a test certificate, installed, checked, removed | `packaging/test-msix.ps1` |
| Both run on every push, on Windows (job "Microsoft Store package") | `.github/workflows/tests.yml` |

Installed from the Store, YSO knows it (its files are in `WindowsApps`): it does not look for new versions on GitHub, does not offer to update itself, and does not install a copy of itself. The Store does all of that.

## What you do once

1. **Create the account.** Go to [Partner Center](https://partner.microsoft.com/dashboard/registration) and sign up as an individual developer. It is free; Microsoft checks your identity, which can take a few days.
2. **Reserve the name.** In Apps and games, choose New product, then MSIX or PWA app, and reserve "YSO - Your System Optimizer" (or another name if it is taken).
3. **Copy the identity.** In the app, open Product management, then Product identity. Copy three values:
   - Package/Identity/Name (for example `12345Example.YSO`)
   - Package/Identity/Publisher (it starts with `CN=`)
   - Package/Properties/PublisherDisplayName
4. **Give them to GitHub.** In the repository, open Settings, Secrets and variables, Actions, tab Variables, and create:
   - `STORE_IDENTITY` = the Name
   - `STORE_PUBLISHER` = the Publisher
   - `STORE_PUBLISHER_NAME` = the PublisherDisplayName

   These are not secrets: anyone who installs the app can read them.
5. **Get the package.** Run the Tests workflow (Actions, Tests, Run workflow). When it is done, download the artifact `YSO-msix` from the run: it holds `YSO.msix`, built with your identity.
6. **Submit.** Create a submission in Partner Center and upload `YSO.msix` in Packages. Fill in the Store listing (description, screenshots from `docs/screenshots`, privacy policy URL) and the age rating.

## The capabilities, and what to write about them

The package uses three restricted capabilities. Partner Center asks why; these answers are true and short:

- **runFullTrust**: "YSO is a desktop app (Windows PowerShell and WPF)."
- **allowElevation**: "YSO is a maintenance tool: it cleans system folders (Windows Update cache, crash dumps, temporary files of all users), creates restore points, runs DISM and SFC, and changes system settings the user chooses. Each of these needs administrator rights. YSO asks once, with the normal UAC prompt."
- **unvirtualizedResources**: "YSO changes real Windows settings the user picks (startup programs, privacy settings, power plan, DNS) and cleans real files. With virtualization, these changes would go to a private copy and have no effect."

If certification refuses `allowElevation`, the other way is to keep the Store page pointing to the installer on GitHub: that needs no package at all.

## Each new version

Change `$script:Version` in `YSO.ps1` as usual. The package has the same version as YSO, with a 0 at the end (YSO 1.0.1 is package `1.0.1.0`), as the Store asks. The Store takes a package only if its version is higher than the last one: to send a correction, give YSO a new version number (1.0.2), not a corrected build of the same version. Download `YSO-msix` from the run of that commit and upload it in a new submission.

## Good to know

- The package needs Windows 10 version 1903 or later (YSO itself runs on 1607 or later).
- It is built for x64. Windows 11 on ARM runs it too.
- Scheduled tasks (weekly cleanup, automatic updates, the icon next to the clock) use a copy of YSO in `C:\Program Files\YSO`, as when YSO starts from its file: the folder of a Store app changes with each version.
