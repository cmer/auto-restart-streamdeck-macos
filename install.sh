#!/bin/bash
# Installs the watcher as a launch agent that starts at login and stays running.
set -euo pipefail

LABEL="com.cmer.auto-restart-streamdeck"
REPO_URL="https://raw.githubusercontent.com/cmer/auto-restart-streamdeck-macos/main"
# Copied out of the repo so moving or deleting the clone does not break the agent.
INSTALL_DIR="$HOME/Library/Application Support/auto-restart-streamdeck"
SCRIPT="$INSTALL_DIR/auto-restart-streamdeck.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/auto-restart-streamdeck.log"
DOMAIN="gui/$(id -u)"

mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# Piped from curl there is no clone to copy from, so the watcher is downloaded instead.
SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SOURCE" ] && [ -f "$(dirname "$SOURCE")/auto-restart-streamdeck.sh" ]; then
	install -m 755 "$(dirname "$SOURCE")/auto-restart-streamdeck.sh" "$SCRIPT"
else
	TMP=$(mktemp)
	trap 'rm -f "$TMP"' EXIT
	curl -fsSL "$REPO_URL/auto-restart-streamdeck.sh" -o "$TMP"
	install -m 755 "$TMP" "$SCRIPT"
fi

# printf rather than a heredoc: Homebrew's bash 5.3 hangs on heredocs over 512 bytes,
# and curl | bash runs whichever bash is first on PATH.
printf '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>%s</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>%s</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>ThrottleInterval</key>
	<integer>30</integer>
	<key>ProcessType</key>
	<string>Background</string>
	<key>StandardOutPath</key>
	<string>%s</string>
	<key>StandardErrorPath</key>
	<string>%s</string>
</dict>
</plist>\n' \
	"$LABEL" "$SCRIPT" "$LOG" "$LOG" > "$PLIST"

# Reinstalling replaces a running copy instead of failing on it.
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$PLIST"

echo "Installed $LABEL"
echo "Log: $LOG"
