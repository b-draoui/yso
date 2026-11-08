#!/bin/sh
# Copies the window pictures drawn by CI (branch ci-pictures) into docs/screenshots, English and French.
# Usage: tests/tools/update-screenshots.sh [os]   (default windows-2025)
set -e
os="${1:-windows-2025}"
git fetch -q origin ci-pictures
for lang in en fr; do
  dest=docs/screenshots; [ "$lang" = fr ] && dest=docs/screenshots/fr
  mkdir -p "$dest"
  while read -r src name; do
    git show "origin/ci-pictures:$os/$lang/$src.png" > "$dest/$name.png"
  done <<'MAP'
1-home home
2-tools tools
3-clean-analyzing clean-analyzing
4-clean-analyzed clean
5-analysis-details details
6-history history
7-question restore-points
8-dialog clean-confirm
9-update-choice updates
10-space-drives space-finder-drives
11-space-finder space-finder
13-startup startup
14-settings settings
15-virtual-disks virtual-disks
16-privacy privacy
17-uninstall uninstall
18-leftovers leftovers
19-undo undo
MAP
done
git log -1 --format='pictures from %s' origin/ci-pictures
