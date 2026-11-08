# YSO 1.1 screenshots

Every screen of YSO, in English and [in French](#français). The pictures are drawn by the automated tests on Windows Server 2025 each time the code changes, so they always show the current version. Lists that need real apps, machines or past changes (the update list, the virtual disks, the apps to uninstall, the list of changes) are filled with sample data, and the space finder scans a small folder.

[Back to the README](../README.md)

## Home
The health of the PC at a glance. Each card has the button that helps.

![Home: Analyze and Clean everything at the top, then the health of the PC as cards: disk space, disk health, Windows Update, security, startup programs, cleaning, app updates](screenshots/home.png)

## Clean
Each part on its own line, with what it frees. Analyze first: it deletes nothing.

![The Clean page while it analyzes: each part with its description and a tick box, and the progress at the bottom](screenshots/clean-analyzing.png)

![The Clean page after Analyze: the space each part frees and the total for what is ticked](screenshots/clean.png)

![The details of Analyze: what each step found, then a table of categories, files and sizes with the total](screenshots/details.png)

Before cleaning everything, YSO says what it will do.

![The Clean everything question: what will be cleaned, the restore point, the Recycle Bin kept, and how long it takes](screenshots/clean-confirm.png)

## Updates
Apps (winget) and drivers (Windows Update) in one list, one tick box each. The recommended ones are ticked first.

![The update list: apps with their versions and notes like new major version, drivers with recommended or optional, and the buttons to install the ticked ones or nothing](screenshots/updates.png)

## Space finder
Pick a drive or a folder, then click a folder to open it.

![The space finder: each drive with the space used, and a button to choose a folder](screenshots/space-finder-drives.png)

![The space finder in a folder: each subfolder as a row with its size, a bar and its share, and buttons for back, biggest files, show in Explorer and done](screenshots/space-finder.png)

## Virtual disks
Gives back the space that VirtualBox machines, WSL and Docker Desktop no longer use. A machine that is running, saved or has snapshots is left alone, with the reason.

![The virtual disks page: each disk with its kind, its size and whether it can be compacted now, what to do inside a VirtualBox machine first, and the choices](screenshots/virtual-disks.png)

## Privacy & ads
Tick what you do not want, then Apply. A sentence under each line says what changes.

![Privacy & ads: each feature with a tick box and a sentence that says what changes, then Apply, Tick the recommended ones and Cancel](screenshots/privacy.png)

## Uninstall apps
Each app with its size and when it was last used. YSO runs the app's own uninstaller, then shows what it left behind.

![Uninstall apps: each app with its publisher, size and when it was last used, and buttons to sort the list](screenshots/uninstall.png)

![What an app left behind: its folders with their size and its registry key, ticked, with Remove the ticked ones and Keep everything](screenshots/leftovers.png)

## Undo YSO changes
Every setting YSO changes is written down first. Click one to put it back as it was.

![Undo YSO changes: each change with its date, the tool that made it and what changed; an undone one is marked](screenshots/undo.png)

## Startup programs
Click a program to switch it on or off.

![Startup programs: each program with an On label, its publisher and who it starts for, and a button for the Windows startup settings](screenshots/startup.png)

## Restore points

![Restore points on a PC where System Restore is not available: a warning and a Continue button](screenshots/restore-points.png)

## Cleanup history

![Cleanup history before the first cleanup: a sentence saying that cleanups will show up here](screenshots/history.png)

## Settings

![Settings: the current values, then each setting as a choice: language, weekly auto-clean, age limits, folders to never touch, settings file, reset, new versions](screenshots/settings.png)

## All tools
Every tool with an icon and one sentence that says what it does.

![All tools: the tools in groups, each with an icon and one sentence](screenshots/tools.png)

---

## Français

Tous les écrans de YSO en français. Les images sont faites par les tests automatiques sur Windows Server 2025 à chaque changement du code. Les listes qui demandent de vraies applis, de vraies machines ou des modifications passées (mises à jour, disques virtuels, applications à désinstaller, liste des modifications) contiennent des exemples.

**Accueil** : l'état du PC, et pour chaque carte le bouton qui aide.

![Accueil : Analyse et Tout nettoyer en haut, puis l'état du PC en cartes](screenshots/fr/home.png)

**Nettoyer** : chaque partie sur sa ligne, avec ce qu'elle libère. L'analyse ne supprime rien.

![La page Nettoyer pendant l'analyse](screenshots/fr/clean-analyzing.png)

![La page Nettoyer après l'analyse : l'espace libéré par chaque partie et le total](screenshots/fr/clean.png)

![Le détail de l'analyse : ce que chaque étape a trouvé, puis un tableau des catégories, fichiers et tailles](screenshots/fr/details.png)

![La question avant de tout nettoyer : ce qui sera nettoyé, le point de restauration, la durée](screenshots/fr/clean-confirm.png)

**Mises à jour** : applis et pilotes dans une seule liste, une case à cocher pour chacune.

![La liste des mises à jour avec les cases à cocher](screenshots/fr/updates.png)

**Explorateur d'espace** : choisir un disque ou un dossier, puis cliquer sur un dossier pour l'ouvrir.

![L'explorateur d'espace : les disques et le bouton pour choisir un dossier](screenshots/fr/space-finder-drives.png)

![L'explorateur d'espace dans un dossier : chaque sous-dossier avec sa taille et une barre](screenshots/fr/space-finder.png)

**Disques virtuels** : récupère l'espace que les machines VirtualBox, WSL et Docker Desktop n'utilisent plus.

![La page des disques virtuels : chaque disque, sa taille et s'il peut être compacté maintenant](screenshots/fr/virtual-disks.png)

**Vie privée et publicités** : cocher ce que vous ne voulez pas, puis Appliquer. Une phrase sous chaque ligne dit ce qui change.

![Vie privée et publicités : chaque fonction avec une case à cocher et une phrase](screenshots/fr/privacy.png)

**Désinstaller des applications** : chaque application avec sa taille et sa dernière utilisation, puis ce qu'elle a laissé.

![Désinstaller des applications : la liste avec éditeur, taille et dernière utilisation](screenshots/fr/uninstall.png)

![Ce qu'une application a laissé : ses dossiers et sa clé du registre, cochés](screenshots/fr/leftovers.png)

**Annuler les modifications de YSO** : chaque réglage modifié par YSO est noté ; un clic le remet comme avant.

![Annuler les modifications de YSO : chaque modification avec sa date, l'outil et ce qui a changé](screenshots/fr/undo.png)

**Programmes au démarrage** : cliquer sur un programme pour l'activer ou le désactiver.

![Programmes au démarrage avec les étiquettes Activé](screenshots/fr/startup.png)

**Points de restauration, historique, paramètres, tous les outils**

![Points de restauration](screenshots/fr/restore-points.png)

![Historique des nettoyages](screenshots/fr/history.png)

![Paramètres](screenshots/fr/settings.png)

![Tous les outils, chacun avec une icône et une phrase](screenshots/fr/tools.png)
