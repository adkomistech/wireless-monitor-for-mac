#!/bin/zsh
# Installs the toggle script and builds a clickable app for it:
# ~/Applications/Wireless Monitor.app (find it with Spotlight).
# Usage: ./make-app.sh ["App Name"]   (letters, digits and spaces only)
# Re-running it overwrites the installed script, so edit settings in
# wireless-monitor.sh here, then run it again.
set -e

NAME="${1:-Wireless Monitor}"
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HOME/.config/sunshine/wireless-monitor.sh"
APP="$HOME/Applications/$NAME.app"

mkdir -p "$HOME/.config/sunshine" "$HOME/Applications"
cp "$DIR/wireless-monitor.sh" "$SCRIPT"
chmod +x "$SCRIPT"

TMP="$(mktemp -d)"
cat > "$TMP/toggle.applescript" <<EOF
set r to do shell script quoted form of "$SCRIPT"
if r is "on" then
	display notification "Open Moonlight on the other computer and pick this Mac" with title "$NAME is on"
else if r is "off" then
	display notification "Virtual screen disconnected" with title "$NAME is off"
else
	display notification r with title "$NAME: something is wrong"
end if
EOF
osacompile -o "$APP" "$TMP/toggle.applescript"
rm -rf "$TMP"

echo "Installed: $APP"
