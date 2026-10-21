#!/bin/bash
# Stops the watcher and removes everything install.sh put in place, except its log.
set -euo pipefail

LABEL="com.cmer.auto-restart-streamdeck"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Library/Application Support/auto-restart-streamdeck"

echo "Uninstalled $LABEL"
echo "Log left at $HOME/Library/Logs/auto-restart-streamdeck.log"
