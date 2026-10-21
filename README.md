# auto-restart-streamdeck-macos

Restarts the Elgato Stream Deck app on macOS when it loses the deck after the Mac wakes from sleep.

## The problem

On wake, the Stream Deck app sometimes asks the deck for its firmware version before the deck has finished powering up. The read fails, the app drops the device, and it never tries again. The keys stay dead until you replug the deck or restart the app. The app's log shows it:

```
DeviceManager  device attached @(1)[4057/128/DL33L2A30108]
DeviceComm     [DL33L2A30108]: Preheat  Read FW version: FAILED
DeviceManager  device purged @(1)[4057/128/DL33L2A30108]
```

It's more common when the deck sits behind a USB hub or dock, where it can take longer to power up.

## What this does

A launch agent watches `~/Library/Logs/ElgatoStreamDeck/StreamDeck.log`. When `Read FW version: FAILED` appears, it waits 5 seconds and restarts the app in the background.

- It only acts on that failure. On a normal wake it does nothing.
- A restarted app can hit the same failure, so it retries. It stops after 3 restarts in 10 minutes, so a deck that keeps failing can't put the app in a restart loop.
- It stops the app by its exact process name and PID, with a 10 second grace period before forcing it.

## Install

```sh
./install.sh
```

The script is copied to `~/Library/Application Support/auto-restart-streamdeck/`, and a launch agent is added at `~/Library/LaunchAgents/com.cmer.auto-restart-streamdeck.plist`. It starts at login and launchd restarts it if it exits.

Activity is logged to `~/Library/Logs/auto-restart-streamdeck.log`.

## Restart the app by hand

```sh
~/Library/Application\ Support/auto-restart-streamdeck/auto-restart-streamdeck.sh restart
```

## Uninstall

```sh
./uninstall.sh
```

## Settings

Environment variables, mostly for testing:

| Variable | Default | Meaning |
| --- | --- | --- |
| `STREAMDECK_LOG` | `~/Library/Logs/ElgatoStreamDeck/StreamDeck.log` | Log file to watch |
| `SETTLE_SECONDS` | `5` | Wait between the failure and the restart |
| `MAX_RESTARTS` | `3` | Restarts allowed per window |
| `WINDOW_SECONDS` | `600` | Length of that window |
| `DRY_RUN` | `0` | `1` logs the restart instead of doing it |
