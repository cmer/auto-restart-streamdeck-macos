#!/bin/bash
# Restarts the Stream Deck app when it loses the deck on wake from sleep.
#
# On wake, the app sometimes asks the deck for its firmware version before the deck is
# ready. The read fails, the app drops the device and never retries, so the keys stay
# dead until the app restarts or the cable is replugged. This script watches the app's
# log for that failure and restarts the app.
#
# Usage:
#   auto-restart-streamdeck.sh           watch the log (what the launch agent runs)
#   auto-restart-streamdeck.sh restart   restart the app once, right now

set -u

LOG_FILE="${STREAMDECK_LOG:-$HOME/Library/Logs/ElgatoStreamDeck/StreamDeck.log}"
APP_NAME="Elgato Stream Deck"
PROCESS_NAME="Stream Deck"
PATTERN="Read FW version: FAILED"
# Gives the deck time to finish powering up before the app looks at it again.
SETTLE_SECONDS="${SETTLE_SECONDS:-5}"
# A deck that fails every time would otherwise restart the app in a loop.
COOLDOWN_SECONDS="${COOLDOWN_SECONDS:-120}"
DRY_RUN="${DRY_RUN:-0}"

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

restart_app() {
	if [ "$DRY_RUN" = 1 ]; then
		log "dry run: would restart $APP_NAME"
		return
	fi

	# Exact process name and a single PID, never a pattern match.
	local pid
	pid=$(pgrep -x "$PROCESS_NAME" | head -n 1)
	if [ -n "$pid" ]; then
		log "stopping $PROCESS_NAME (pid $pid)"
		kill -TERM "$pid"
		for _ in 1 2 3 4 5 6 7 8 9 10; do
			kill -0 "$pid" 2>/dev/null || break
			sleep 1
		done
		if kill -0 "$pid" 2>/dev/null; then
			log "pid $pid ignored SIGTERM, sending SIGKILL"
			kill -KILL "$pid"
		fi
	fi

	# --runinbk starts it in the menu bar without opening its window.
	open -a "$APP_NAME" --args --runinbk
	log "started $APP_NAME"
}

watch_log() {
	local last_restart=0 now
	log "watching $LOG_FILE"

	# -F follows the file across the app's log rotation; -n 0 skips old failures.
	tail -n 0 -F "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
		case "$line" in
			*"$PATTERN"*) ;;
			*) continue ;;
		esac

		now=$(date +%s)
		if [ $((now - last_restart)) -lt "$COOLDOWN_SECONDS" ]; then
			log "device failed again within ${COOLDOWN_SECONDS}s of a restart, leaving it alone"
			continue
		fi

		log "Stream Deck app dropped the device, restarting in ${SETTLE_SECONDS}s"
		sleep "$SETTLE_SECONDS"
		last_restart=$(date +%s)
		restart_app
	done
}

case "${1:-watch}" in
	watch) watch_log ;;
	restart) restart_app ;;
	*)
		echo "usage: $0 [watch|restart]" >&2
		exit 64
		;;
esac
