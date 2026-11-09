# Guide de YSO

Ce que fait chaque outil, ce qu'il change, et comment l'annuler. Le même guide est dans YSO : Aide, dans la fenêtre, ou G dans le menu console.

**[English version](GUIDE.md)**

## Sommaire

- [Pour commencer](#pour-commencer)
  - [Comment marche YSO](#comment-marche-yso)
  - [Ce que YSO ne touche jamais](#ce-que-yso-ne-touche-jamais)
  - [La page Nettoyer](#la-page-nettoyer)
- [Nettoyer](#nettoyer)
  - [1. Fichiers temporaires](#1-fichiers-temporaires)
  - [2. Caches des navigateurs](#2-caches-des-navigateurs)
  - [3. Fichiers inutiles (rapports, vidages, journaux)](#3-fichiers-inutiles-rapports-vidages-journaux)
  - [4. Cache de Windows Update](#4-cache-de-windows-update)
  - [5. Corbeille](#5-corbeille)
  - [6. Caches de shaders GPU](#6-caches-de-shaders-gpu)
  - [7. Caches développeur et applis](#7-caches-développeur-et-applis)
  - [8. Nettoyage approfondi (Nettoyage de disque)](#8-nettoyage-approfondi-nettoyage-de-disque)
  - [9. Ancienne version de Windows (Windows.old)](#9-ancienne-version-de-windows-windowsold)
  - [10. Fichier de veille prolongée](#10-fichier-de-veille-prolongée)
- [Réseau](#réseau)
  - [11. Test réseau (vitesse, DNS, Wi-Fi)](#11-test-réseau-vitesse-dns-wi-fi)
  - [12. Changer de serveurs DNS](#12-changer-de-serveurs-dns)
  - [13. Vider le cache DNS](#13-vider-le-cache-dns)
  - [14. Réinitialisation réseau complète](#14-réinitialisation-réseau-complète)
- [Optimiser](#optimiser)
  - [15. Optimiser les disques (TRIM / défrag.)](#15-optimiser-les-disques-trim--défrag)
  - [16. Mode d'alimentation](#16-mode-dalimentation)
  - [17. Programmes au démarrage](#17-programmes-au-démarrage)
  - [18. Analyse du temps de démarrage](#18-analyse-du-temps-de-démarrage)
- [Applications et vie privée](#applications-et-vie-privée)
  - [30. Vie privée, publicités (Windows, Edge, Copilot)](#30-vie-privée-publicités-windows-edge-copilot)
  - [31. Désinstaller des applications (et leurs restes)](#31-désinstaller-des-applications-et-leurs-restes)
  - [32. Annuler les modifications de YSO](#32-annuler-les-modifications-de-yso)
- [Diagnostic et réparation](#diagnostic-et-réparation)
  - [19. Rapport de santé du système](#19-rapport-de-santé-du-système)
  - [20. Plantages et erreurs](#20-plantages-et-erreurs)
  - [21. Sécurité et analyse Defender](#21-sécurité-et-analyse-defender)
  - [22. Qu'est-ce qui se lance tout seul ? (audit)](#22-quest-ce-qui-se-lance-tout-seul--audit)
  - [23. Problèmes de pilotes](#23-problèmes-de-pilotes)
  - [24. Vérifier les disques](#24-vérifier-les-disques)
  - [25. Test de mémoire](#25-test-de-mémoire)
  - [26. Réparer les fichiers Windows (DISM + SFC)](#26-réparer-les-fichiers-windows-dism--sfc)
- [Espace & mises à jour](#espace--mises-à-jour)
  - [27. Explorateur d'espace (qui remplit le disque ?)](#27-explorateur-despace-qui-remplit-le-disque-)
  - [28. Mises à jour : applis & pilotes](#28-mises-à-jour--applis--pilotes)
  - [29. Disques virtuels (compacter VM, WSL, Docker)](#29-disques-virtuels-compacter-vm-wsl-docker)
- [En un clic](#en-un-clic)
  - [A. Analyser (ne supprime rien)](#a-analyser-ne-supprime-rien)
  - [F. Entretien complet](#f-entretien-complet)
  - [R. Points de restauration](#r-points-de-restauration)
  - [S. Nettoyage auto](#s-nettoyage-auto)
  - [H. Historique des nettoyages](#h-historique-des-nettoyages)
  - [T. Autotest (tout vérifier)](#t-autotest-tout-vérifier)
  - [P. Signaler un problème](#p-signaler-un-problème)
  - [O. Paramètres / Language](#o-paramètres--language)
  - [L. Dossier des journaux](#l-dossier-des-journaux)
- [YSO lui-même](#yso-lui-même)
  - [Icône à côté de l'horloge](#icône-à-côté-de-lhorloge)
  - [Nouvelles versions de YSO](#nouvelles-versions-de-yso)
  - [Désinstaller YSO](#désinstaller-yso)

## Pour commencer

### Comment marche YSO

YSO entretient Windows : il libère de l'espace, vérifie la santé du PC, installe les mises à jour et règle les problèmes courants. La page d'accueil montre l'état du PC en vert, orange ou rouge, et chaque carte a le bouton qui aide. Chaque outil dit ce qu'il fait pendant qu'il travaille, pose ses questions avec des boutons, et peut être arrêté.

**Ce qui change.** YSO a besoin des droits d'administrateur (une seule demande de Windows), parce qu'il nettoie des dossiers du système et modifie des réglages de Windows. Il demande avant de changer quoi que ce soit, sauf pour les nettoyages que vous lancez vous-même.

**Pour annuler.** Les réglages modifiés par YSO peuvent être remis avec Annuler les modifications de YSO (32). Les fichiers qu'il supprime sont des fichiers temporaires et des caches : Windows et vos applications les recréent quand ils en ont besoin.

**Étape par étape:**

1. Cliquez sur Analyse : YSO mesure ce qui peut être libéré, sans rien supprimer.
2. Sur la page Nettoyer, décochez ce que vous voulez garder, puis cliquez sur Nettoyer la sélection.
3. Une fois par mois, lancez l'Entretien complet, ou activez le Nettoyage auto.

### Ce que YSO ne touche jamais

YSO ne supprime jamais vos mots de passe, cookies, historique, favoris, données de sites, messages, Téléchargements, Documents, extensions de navigateur ni fichiers de jeux. Les fichiers utilisés sont ignorés, les fichiers temporaires récents sont gardés (24 heures par défaut), les liens de dossiers ne sont jamais suivis, et les dossiers du système sont refusés.

**Ce qui change.** Ce qui ne peut pas être annulé est toujours demandé à part : vider la Corbeille, les anciennes versions de pilotes, Windows.old, les anciens points de restauration, la réinitialisation du réseau. L'Entretien complet et les mises à jour de pilotes créent d'abord un point de restauration.

**Pour annuler.** Dans les Paramètres (O), vous pouvez donner des dossiers que YSO ne doit jamais toucher. Lancé avec -DryRun, YSO est en mode analyse seule : il montre tout et ne change rien. Chaque session est notée dans C:\ProgramData\YSO\Logs.

### La page Nettoyer

La page Nettoyer liste chaque partie que YSO peut nettoyer, avec une phrase qui dit ce que c'est. Analyse montre combien chaque partie libère. Cochez ce que vous voulez, puis cliquez sur Nettoyer la sélection.

**Ce qui change.** Les parties cochées sont nettoyées l'une après l'autre, avec une barre de progression et ce que chacune a libéré. La Corbeille et les anciennes versions de pilotes ne sont nettoyées que si vous les cochez.

**Pour annuler.** Les fichiers temporaires et les caches supprimés ne vont pas dans la Corbeille : Windows et vos applications les recréent quand ils en ont besoin.

## Nettoyer

### 1. Fichiers temporaires

Supprime les fichiers temporaires de chaque utilisateur du PC et de Windows. Les applications les laissent derrière elles après une installation, une mise à jour ou un plantage.

**Ce qui change.** Seulement les fichiers de plus de 24 heures (modifiable dans les Paramètres), et jamais un fichier en cours d'utilisation.

**Pour annuler.** Inutile : les applications créent de nouveaux fichiers temporaires quand elles en ont besoin.

### 2. Caches des navigateurs

Supprime les copies de pages web, d'images et de scripts que gardent Chrome, Edge, Brave, Vivaldi, Opera et Firefox, dans chaque profil. Les pages se rechargent depuis internet la première fois.

**Ce qui change.** Les mots de passe, cookies, historique, favoris, onglets ouverts et extensions ne sont pas touchés. Si un navigateur est ouvert, YSO propose de le fermer pour un nettoyage complet ; ses onglets reviennent quand vous le rouvrez.

**Pour annuler.** Inutile : le navigateur remplit de nouveau son cache pendant que vous naviguez.

### 3. Fichiers inutiles (rapports, vidages, journaux)

Supprime les rapports d'erreurs, les fichiers de vidage après plantage (aussi ceux des dossiers temporaires des services de Windows, parfois plusieurs Go), les journaux de plus de 14 jours et le cache des miniatures.

**Ce qui change.** Les journaux et vidages récents sont gardés, pour qu'un plantage récent puisse encore être étudié. Le dossier Prefetch n'est jamais touché : le vider rendrait Windows plus lent.

**Pour annuler.** Inutile. Les miniatures sont recréées quand vous ouvrez un dossier.

### 4. Cache de Windows Update

Supprime les fichiers de mises à jour que Windows a déjà installées, et le cache de l'Optimisation de la distribution (mises à jour partagées avec d'autres PC).

**Ce qui change.** Si des mises à jour attendent un redémarrage, ou si Windows Update travaille, le cache est gardé : redémarrez, puis relancez-le.

**Pour annuler.** Inutile : Windows retélécharge ce dont il a encore besoin.

### 5. Corbeille

Vide la Corbeille de chaque disque.

**Ce qui change.** YSO demande toujours avant, et montre combien elle contient.

**Pour annuler.** Impossible à annuler : les fichiers vidés de la Corbeille sont perdus.

### 6. Caches de shaders GPU

Supprime les shaders compilés que gardent NVIDIA, AMD, Intel et DirectX. Surtout utile après une mise à jour de pilote, ou quand un jeu a des problèmes d'affichage.

**Ce qui change.** Les jeux les recréent au lancement suivant : le premier chargement peut saccader un peu.

**Pour annuler.** Inutile : ils reviennent tout seuls.

### 7. Caches développeur et applis

Supprime les caches et les vieux journaux de npm, pip, VS Code, Discord, Teams, Spotify, Steam et de toutes les applications basées sur Chromium.

**Ce qui change.** Les projets, paquets installés, réglages, connexions et fichiers de jeux ne sont pas touchés. Pour VS Code, les données des projets pas ouverts depuis 60 jours partent aussi (elles reviennent si vous les rouvrez).

**Pour annuler.** Inutile : les applications reconstruisent leurs caches.

### 8. Nettoyage approfondi (Nettoyage de disque)

Lance le Nettoyage de disque de Windows avec toutes les options sûres, puis nettoie le magasin de composants (anciennes versions de fichiers de Windows gardées après les mises à jour). Libère beaucoup, et prend 10 à 30 minutes.

**Ce qui change.** Les Téléchargements, la Corbeille et Windows.old ne sont jamais inclus. Les anciennes versions de pilotes ne sont retirées que si vous dites oui. Une partie du nettoyage se termine au redémarrage suivant.

**Pour annuler.** Après, les mises à jour installées avant ne peuvent plus être désinstallées, et les versions de pilotes retirées ne peuvent pas revenir.

### 9. Ancienne version de Windows (Windows.old)

Windows.old contient la version précédente de Windows après une grosse mise à jour, pour pouvoir y revenir pendant 10 jours. Il prend souvent 15 à 30 Go.

**Ce qui change.** YSO montre sa taille et si le retour en arrière est encore possible, puis demande.

**Pour annuler.** Impossible à annuler : une fois retiré, vous ne pouvez plus revenir à la version précédente de Windows.

### 10. Fichier de veille prolongée

hiberfil.sys peut prendre plusieurs Go. Windows s'en sert pour la mise en veille prolongée et le démarrage rapide. Réduit garde le démarrage rapide et le divise par deux, Désactivé le supprime, Complet est le réglage de Windows.

**Ce qui change.** Sur un portable, la veille prolongée sauve votre travail quand la batterie se vide : gardez Réduit ou Complet.

**Pour annuler.** Annuler les modifications de YSO (32) remet le réglage d'avant, ou choisissez Complet ici.

## Réseau

### 11. Test réseau (vitesse, DNS, Wi-Fi)

Mesure la liaison avec votre box, le temps pour atteindre internet, la vitesse de plusieurs serveurs DNS et le signal Wi-Fi, et dit d'où vient un problème.

**Ce qui change.** Rien n'est modifié.

**Pour annuler.** Rien à annuler.

### 12. Changer de serveurs DNS

Le DNS traduit le nom des sites en adresses. Celui de votre fournisseur peut être lent ; Cloudflare, Google ou Quad9 sont souvent plus rapides, et certains bloquent les sites dangereux. Le Test réseau (11) montre lequel est le plus rapide chez vous.

**Ce qui change.** YSO enregistre d'abord vos réglages DNS actuels, puis met les nouveaux sur chaque carte réseau connectée.

**Pour annuler.** L'option 4 du même écran remet vos réglages d'avant, tout comme Annuler les modifications de YSO (32).

### 13. Vider le cache DNS

Vide la liste des adresses de sites que Windows retient. Aide quand un site a changé d'adresse, ou ne s'ouvre plus après un changement de DNS ou de réseau.

**Ce qui change.** Rien d'autre ne change : les sites sont recherchés à nouveau.

**Pour annuler.** Rien à annuler.

### 14. Réinitialisation réseau complète

Réinitialise Winsock et les réglages TCP/IP de Windows. En dernier recours, quand internet ne marche pas et que rien d'autre n'a aidé.

**Ce qui change.** Elle efface les réglages IP et DNS saisis à la main, peut perturber les VPN ou les proxys jusqu'à leur reconfiguration, et demande un redémarrage. Vos réglages réseau sont d'abord enregistrés dans un fichier du dossier des journaux.

**Pour annuler.** Impossible à annuler automatiquement : le fichier enregistré liste vos réglages d'avant, pour que vous puissiez les ressaisir.

## Optimiser

### 15. Optimiser les disques (TRIM / défrag.)

Demande à Windows d'optimiser chaque disque : TRIM pour les SSD (il indique au disque les blocs libres) et défragmentation pour les disques durs.

**Ce qui change.** Comme l'outil Optimiser les lecteurs de Windows. Sans danger pour les SSD : Windows ne les défragmente jamais.

**Pour annuler.** Rien à annuler.

### 16. Mode d'alimentation

Choisit entre Performances optimales, Performances élevées et Utilisation normale. Les modes performance gardent le processeur prêt, pour un PC un peu plus rapide.

**Ce qui change.** Sur un portable, cela veut dire plus de chaleur, plus de bruit de ventilateur et moins de batterie : Utilisation normale y est préférable.

**Pour annuler.** Annuler les modifications de YSO (32), ou choisissez Utilisation normale ici.

### 17. Programmes au démarrage

Liste les programmes qui démarrent avec Windows, avec leur éditeur et combien ils ralentissent le démarrage. Cliquez sur l'un d'eux pour l'activer ou le désactiver.

**Ce qui change.** Cela marche comme le Gestionnaire des tâches : le programme reste installé et arrête seulement de démarrer tout seul. Les applications du Microsoft Store gèrent leur démarrage dans les Paramètres de Windows.

**Pour annuler.** Cliquez de nouveau dessus, ou utilisez Annuler les modifications de YSO (32).

### 18. Analyse du temps de démarrage

Lit la durée des derniers démarrages dans les relevés de Windows, et quelles applications, pilotes et services les ont ralentis.

**Ce qui change.** Rien n'est modifié. Seuls les démarrages complets sont mesurés : Redémarrer, ou Arrêter quand le démarrage rapide est désactivé.

**Pour annuler.** Rien à annuler.

## Applications et vie privée

### 30. Vie privée, publicités (Windows, Edge, Copilot)

Désactive, avec des cases à cocher : les publicités et suggestions de Windows, les conseils de l'écran de verrouillage, les résultats web (Bing) dans la recherche du menu Démarrer, le suivi publicitaire, les données de diagnostic et l'historique des activités, Copilot, Recall et Click to Do, les fonctions IA d'Edge, du Bloc-notes et de Paint, et les publicités d'Edge.

**Ce qui change.** Ce sont les réglages que Windows et Edge prévoient pour cela. Certains sont des stratégies : Windows ou Edge affiche alors « géré par votre organisation », c'est normal. Certains changements apparaissent après une déconnexion. Defender, Windows Update et le Store ne sont jamais touchés.

**Pour annuler.** Décochez une ligne puis Appliquer pour revenir au réglage de Windows, ou utilisez Annuler les modifications de YSO (32) pour l'état exact d'avant.

**Étape par étape:**

1. Cochez ce que vous ne voulez pas, ou cliquez sur Cocher les recommandés.
2. Cliquez sur Appliquer, lisez la liste des changements, et confirmez.
3. Déconnectez-vous puis reconnectez-vous, ou laissez YSO redémarrer l'Explorateur quand il le propose.

### 31. Désinstaller des applications (et leurs restes)

Liste vos applications de bureau avec leur taille et leur dernière utilisation. YSO lance le programme de désinstallation de l'application, puis cherche ce qu'elle a laissé : les dossiers et clés du registre qui portent son nom.

**Ce qui change.** YSO ne propose jamais le dossier d'une autre application installée, un dossier du système, ni un nom qu'une autre application utilise aussi. Les dossiers de 1 Go ou plus sont décochés au départ : un dossier peut contenir vos propres données, comme des sauvegardes de jeu ou un profil de messagerie. Les runtimes et les pilotes ont un avertissement.

**Pour annuler.** L'application peut être réinstallée. Les dossiers retirés vont dans la Corbeille et les clés du registre sont d'abord enregistrées dans un fichier : Annuler les modifications de YSO (32) les remet.

**Étape par étape:**

1. Trouvez l'application : triez par taille ou par dernière utilisation, ou tapez une partie de son nom.
2. Cliquez dessus, lisez ce que YSO en montre, et confirmez.
3. Suivez la fenêtre de sa désinstallation jusqu'au bout.
4. Parmi les restes, décochez ce que vous voulez garder, puis cliquez sur Supprimer ce qui est coché.

### 32. Annuler les modifications de YSO

Chaque réglage modifié par YSO est d'abord noté, avec ce qu'il était avant : programmes au démarrage, mode d'alimentation, fichier de veille prolongée, DNS, réglages de vie privée et restes d'applications. Cette liste les montre, du plus récent au plus ancien.

**Ce qui change.** Cliquez sur l'un d'eux pour voir ce qu'il a changé, puis confirmez : tout revient exactement comme avant. Les fichiers nettoyés ne sont pas dans cette liste : ce sont des caches qui reviennent tout seuls.

**Pour annuler.** Une modification annulée est marquée comme telle. Les 300 dernières modifications sont gardées.

## Diagnostic et réparation

### 19. Rapport de santé du système

Tout le PC dans un seul rapport : Windows et matériel, espace et usure des disques, capacité de la batterie, Windows Update, plantages récents, sécurité et pilotes. Pour chaque problème, une flèche montre l'outil qui aide.

**Ce qui change.** Rien n'est modifié. Il peut créer le rapport détaillé de batterie de Windows, qui s'ouvre dans votre navigateur.

**Pour annuler.** Rien à annuler.

### 20. Plantages et erreurs

Montre les écrans bleus, plantages d'applications et erreurs graves récents des journaux de Windows, et leur cause quand Windows la connaît.

**Ce qui change.** Rien n'est modifié. Quelques erreurs sont normales sur tout PC : cherchez celles qui se répètent, ou qui arrivent quand vous avez un problème.

**Pour annuler.** Rien à annuler.

### 21. Sécurité et analyse Defender

Vérifie l'antivirus, le pare-feu et Windows Update. Avec Microsoft Defender, il peut mettre à jour les définitions de virus et lancer une analyse rapide (5 à 15 minutes).

**Ce qui change.** Seulement la mise à jour et l'analyse de Defender : aucun réglage n'est modifié.

**Pour annuler.** Rien à annuler.

### 22. Qu'est-ce qui se lance tout seul ? (audit)

Liste les tâches planifiées et les services qui ne viennent pas de Microsoft, et si leur programme est signé. Prend 10 à 60 secondes.

**Ce qui change.** Rien n'est modifié. Non signé ne veut pas dire malveillant. Pour retirer quelque chose, désinstallez le programme auquel il appartient.

**Pour annuler.** Rien à annuler.

### 23. Problèmes de pilotes

Liste les appareils dont le pilote manque ou ne marche pas, puis aide : Gestionnaire de périphériques, mises à jour facultatives de pilotes dans Windows Update, ou nouvelle recherche du matériel.

**Ce qui change.** Rien n'est modifié, sauf si vous choisissez l'une de ces actions.

**Pour annuler.** Rien à annuler.

### 24. Vérifier les disques

Recherche les erreurs du système de fichiers sur chaque disque, pendant que vous continuez à travailler.

**Ce qui change.** Si des erreurs sont trouvées, YSO demande avant de réparer : les autres disques sont réparés tout de suite, celui de Windows au prochain redémarrage, avant le chargement de Windows.

**Pour annuler.** Une réparation ne peut pas être annulée, mais elle corrige seulement les registres du système de fichiers.

### 25. Test de mémoire

Lance le Diagnostic de mémoire Windows, qui vérifie la RAM, une cause fréquente d'écrans bleus et de plantages au hasard. Il tourne après un redémarrage, avant le chargement de Windows, et prend 10 à 30 minutes.

**Ce qui change.** Enregistrez votre travail avant. Le résultat s'affiche dans une notification au redémarrage de Windows, et ici la fois suivante.

**Pour annuler.** Rien à annuler.

### 26. Réparer les fichiers Windows (DISM + SFC)

Lance DISM, qui répare la réserve de fichiers système de Windows (il faut internet), puis SFC, qui répare les fichiers système à partir de cette réserve. Prend 15 à 45 minutes.

**Ce qui change.** Seuls les fichiers de Windows sont réparés, avec les outils de Windows.

**Pour annuler.** Rien à annuler : les fichiers réparés sont ceux d'origine.

## Espace & mises à jour

### 27. Explorateur d'espace (qui remplit le disque ?)

Montre quels dossiers remplissent un disque, du plus gros au plus petit. Cliquez sur un dossier pour l'ouvrir, Retour pour remonter, Plus gros fichiers pour voir les plus gros fichiers, Voir dans l'Explorateur pour l'ouvrir là.

**Ce qui change.** Rien n'est modifié ni supprimé : il montre seulement. Supprimez vous-même ce dont vous n'avez pas besoin, dans l'Explorateur.

**Pour annuler.** Rien à annuler.

### 28. Mises à jour : applis & pilotes

Trouve les mises à jour d'applications (avec winget) et de pilotes (avec Windows Update), et les montre dans une seule liste où vous cochez ce qu'il faut installer. YSO peut aussi vérifier selon un horaire et vous prévenir, ou installer seul les mises à jour sûres.

**Ce qui change.** Un point de restauration est créé avant l'installation de pilotes. En mode automatique, les grosses nouvelles versions (7.x vers 8.x), les pilotes facultatifs et les applications que vous excluez vous sont laissés. Seules les applications du catalogue winget sont vérifiées.

**Pour annuler.** Une application peut être désinstallée, puis sa version d'avant réinstallée depuis son site. Un pilote peut être restauré dans le Gestionnaire de périphériques, ou avec le point de restauration.

**Étape par étape:**

1. Cliquez sur Chercher les mises à jour maintenant.
2. Cochez ce qu'il faut installer, puis cliquez sur Installer les mises à jour cochées.
3. Si vous voulez, choisissez Me prévenir ou Automatique, et quand ça tourne.

### 29. Disques virtuels (compacter VM, WSL, Docker)

Le disque d'une machine virtuelle est un seul gros fichier sur votre PC (.vdi pour VirtualBox, .vhdx pour WSL et Docker Desktop). Il grossit quand la machine écrit, mais ne rétrécit jamais, même quand vous supprimez des fichiers dedans. Compacter retire l'espace vide du fichier : il devient plus petit, et rien ne change dans la machine.

**Ce qui change.** YSO refuse une machine allumée, en état sauvegardé ou avec des snapshots, et demande que VirtualBox et Docker Desktop soient fermés. Le fichier est réécrit sur place : une coupure de courant ou un plantage pendant le compactage peut l'abîmer.

**Pour annuler.** Le compactage ne s'annule pas, et n'en a pas besoin. Copiez avant un disque que vous ne voulez pas perdre, pour pouvoir le remettre si quelque chose tourne mal.

**Étape par étape:**

1. VirtualBox : le compactage ne retire que les blocs vides, et les fichiers supprimés ne sont pas vides tant que l'espace libre n'est pas rempli de zéros. Dans la machine, lancez sdelete -z C: (Windows) ou la commande dd que YSO affiche (Linux), puis éteignez la machine depuis l'intérieur.
2. WSL et Docker : rien à faire à l'intérieur. YSO libère les blocs inutilisés et arrête WSL lui-même.
3. Copiez le fichier disque de la machine ailleurs, sur un disque externe par exemple : c'est votre sauvegarde.
4. Gardez le PC branché. Ouvrez Disques virtuels, vérifiez que le disque peut être compacté, et confirmez.
5. Démarrez la machine pour vérifier qu'elle marche. Ensuite, vous pouvez supprimer la copie.

## En un clic

### A. Analyser (ne supprime rien)

Mesure combien chaque partie du nettoyage libérerait. Ne supprime rien.

**Ce qui change.** Rien n'est modifié. Le Nettoyage approfondi (8) libère souvent plus en plus, mais ne peut pas être mesuré à l'avance.

**Pour annuler.** Rien à annuler.

### F. Entretien complet

Tout d'un coup : un point de restauration, puis fichiers temporaires, caches des navigateurs, copies hors ligne des sites, fichiers inutiles du système, caches de développement et d'applications, caches GPU, cache de Windows Update, DNS, nettoyage approfondi et optimisation des disques. La Corbeille et les mises à jour seulement si vous les choisissez.

**Ce qui change.** Toutes les questions sont posées au début, ensuite vous pouvez vous éloigner. Si Windows attend un redémarrage, redémarrez d'abord : certaines parties ne peuvent être nettoyées qu'après.

**Pour annuler.** Le point de restauration (R) ramène Windows et ses réglages à l'état d'avant ; vos documents n'y sont pas touchés.

### R. Points de restauration

Un point de restauration ramène Windows, ses réglages et vos programmes à un état antérieur. Vos documents ne sont pas touchés. Ici, vous voyez les vôtres, en créez un, gardez seulement le plus récent, ou ouvrez la Protection du système.

**Ce qui change.** Supprimer les anciens points de restauration est demandé à part, et ne peut pas être annulé.

**Pour annuler.** Pour revenir à un point de restauration : Protection du système, puis Restauration du système.

### S. Nettoyage auto

Nettoie tout seul chaque dimanche à 3 h (ou au démarrage suivant si le PC était éteint), sans rien afficher, et seulement sur secteur. Vous choisissez ce qu'il nettoie dans les Paramètres.

**Ce qui change.** Il ne ferme jamais vos applications et ne vide jamais la Corbeille. Il tourne comme tâche planifiée, depuis C:\Program Files\YSO.

**Pour annuler.** Désactivez-le ici, à tout moment.

### H. Historique des nettoyages

Montre ce que chaque nettoyage a libéré, avec sa date, ses parties et son total.

**Ce qui change.** Rien n'est modifié.

**Pour annuler.** Rien à annuler.

### T. Autotest (tout vérifier)

Vérifie que chaque partie de YSO marche sur ce PC, une ligne par vérification. Une ligne ERREUR dit ce qui ne marche pas, et pourquoi.

**Ce qui change.** Rien n'est modifié.

**Pour annuler.** Rien à annuler.

### P. Signaler un problème

Crée un fichier zip sur votre Bureau avec l'autotest, le journal d'erreurs et les journaux récents, à envoyer au développeur (ticket GitHub, e-mail...).

**Ce qui change.** Les noms d'utilisateurs, le nom du PC, les adresses IP privées et le nom du Wi-Fi en sont retirés. Rien n'est envoyé tout seul : ouvrez-le et vérifiez-le avant de l'envoyer.

**Pour annuler.** Supprimez le zip quand vous n'en avez plus besoin.

### O. Paramètres / Language

Langue, âge minimum des fichiers temporaires et des journaux avant que YSO les supprime, ce que nettoie le nettoyage hebdomadaire, dossiers que YSO ne doit jamais toucher, nouvelles versions de YSO, et l'icône à côté de l'horloge.

**Ce qui change.** Enregistré dans C:\ProgramData\YSO\settings.json. Rétablir les valeurs par défaut remet tout comme après l'installation.

**Pour annuler.** Remettez-le ici, ou utilisez Rétablir les valeurs par défaut.

### L. Dossier des journaux

Ouvre le dossier où YSO note ce qu'il a fait à chaque session, et ses erreurs.

**Ce qui change.** Rien n'est modifié.

**Pour annuler.** Rien à annuler.

## YSO lui-même

### Icône à côté de l'horloge

Facultative, dans les Paramètres (option 9). Toutes les 6 heures, elle vérifie l'espace libre, les disques et la batterie, et vous prévient quand quelque chose demande votre attention, au plus une fois par semaine pour chaque chose. Elle dit aussi ce que le nettoyage hebdomadaire a libéré. Clic droit dessus pour ouvrir YSO ou vérifier maintenant.

**Ce qui change.** Elle démarre avec Windows (une tâche planifiée) et ne fait que lire. Désinstaller YSO la retire.

**Pour annuler.** Clic droit dessus, puis Retirer cette icône, ou utilisez l'option 9 des Paramètres.

### Nouvelles versions de YSO

Quand une nouvelle version est publiée, un bouton de mise à jour apparaît dans YSO. Il télécharge la nouvelle version depuis GitHub, vérifie sa somme SHA-256 et que PowerShell peut la lire, puis remplace YSO. Vos réglages et votre historique restent.

**Ce qui change.** YSO interroge GitHub au plus une fois par heure, à l'ouverture de sa fenêtre ; vous pouvez le désactiver dans les Paramètres. Installé depuis le Microsoft Store, YSO est mis à jour par le Store.

**Pour annuler.** Pour revenir à une version précédente, téléchargez-la sur la page Releases de YSO sur GitHub.

### Désinstaller YSO

Paramètres > Applications > Applications installées > YSO > Désinstaller. YSO demande s'il faut garder son historique et ses réglages.

**Ce qui change.** Son nettoyage hebdomadaire, ses mises à jour automatiques et l'icône à côté de l'horloge s'arrêtent aussi.

**Pour annuler.** Réinstallez-le avec la même ligne que la première fois.
