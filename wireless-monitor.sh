#!/bin/zsh
# Wireless monitor toggle: BetterDisplay virtual screen + Sunshine.
# On:  connects the virtual screen and starts Sunshine streaming it.
# Off: stops Sunshine and disconnects the virtual screen.
# Prints "on" or "off" so the menu-bar app can show a notification.

# --- settings -------------------------------------------------------------
SCREEN="Wireless Monitor"                     # virtual screen name in BetterDisplay
CONF="$HOME/.config/sunshine/sunshine.conf"   # Sunshine config file
# --------------------------------------------------------------------------

CLI=/opt/homebrew/bin/betterdisplaycli
SUNSHINE=/opt/homebrew/opt/sunshine/bin/sunshine

if pgrep -f "$SUNSHINE" >/dev/null; then
  pkill -f "$SUNSHINE"
  "$CLI" set --name="$SCREEN" --connected=off >/dev/null 2>&1
  echo "off"
  exit 0
fi

if [ ! -f "$CONF" ]; then
  echo "no config: $CONF"
  exit 1
fi

pgrep -x BetterDisplay >/dev/null || { open -a BetterDisplay; sleep 5; }
"$CLI" set --name="$SCREEN" --connected=on >/dev/null 2>&1
sleep 3

# the virtual screen's display ID can change after reconnecting,
# so point Sunshine at the current one every time
ID=$("$CLI" get --identifiers 2>/dev/null | SCREEN="$SCREEN" /usr/bin/python3 -c '
import json, os, sys
raw = "[" + sys.stdin.read() + "]"
for d in json.loads(raw):
    if d.get("name") == os.environ["SCREEN"]:
        print(d["displayID"])
        break' 2>/dev/null)
if [ -z "$ID" ]; then
  "$CLI" set --name="$SCREEN" --connected=off >/dev/null 2>&1
  echo "no screen named \"$SCREEN\" in BetterDisplay"
  exit 1
fi
/usr/bin/sed -i '' "s/^output_name = .*/output_name = $ID/" "$CONF"

nohup "$SUNSHINE" "$CONF" >/dev/null 2>&1 &
echo "on"
