# Wireless Monitor for Mac

Use the monitor on someone else's desk as a wireless second screen for your Mac,
even when the monitor has no AirPlay, no Wi‑Fi and only HDMI.

The trick: the monitor is already plugged into another computer that's always on.
Your Mac creates a virtual screen, streams it over the network, and that computer
shows it full screen. Click one button on the Mac, one in the app on the other
computer, and you have a second screen. Unplug nothing.

```
 Your Mac                                          Other computer (Windows / Linux / Mac)
┌───────────────────────────────┐                  ┌───────────────────────────────┐
│ BetterDisplay                 │                  │ Moonlight                     │
│   virtual screen 1920×1080    │   Wi‑Fi / LAN    │   shows the stream full       │
│ Sunshine                      │ ───────────────▶ │   screen on its monitor       │
│   streams that screen         │ (or Tailscale)   │                               │
└───────────────────────────────┘                  └──────────────┬────────────────┘
                                                                  │ HDMI
                                                           ┌──────▼──────┐
                                                           │   monitor   │
                                                           └─────────────┘
```

## Why

My husband's monitor sits on his desk, wired to his Windows laptop, cables neatly
tied. When I work at his desk, I'd like it as a second screen for my MacBook.
The monitor only has HDMI (taken) and VGA. No AirPlay, no wireless anything.

The usual answer is "buy a monitor with AirPlay". This setup gets the same
experience with free software and the hardware already on the desk.

All of it was set up by an AI agent ([Claude Code](https://claude.com/claude-code)):
one instance on my Mac, another one on the Windows laptop. They passed tasks to each
other through a shared Google Drive folder. I clicked "Allow" twice and typed a 4‑digit PIN.

## What you need

- A Mac with Apple Silicon, [Homebrew](https://brew.sh) and the Xcode Command Line Tools
  (`xcode-select --install`; the toggle script uses their `python3`)
- Another computer that's on and wired to the monitor. Any OS that runs
  [Moonlight](https://moonlight-stream.org)
- Both on the same network. If streaming fails on home Wi‑Fi, use
  [Tailscale](https://tailscale.com) (free), see Gotchas

Software, all free:

- [BetterDisplay](https://github.com/waydabber/BetterDisplay) — creates the virtual screen on the Mac
- [Sunshine](https://github.com/LizardByte/Sunshine) — streams it (it's made for game streaming, so latency is low)
- [Moonlight](https://github.com/moonlight-stream/moonlight-qt) — receives it on the other computer

## Setup on the Mac

1. Install BetterDisplay and Sunshine:

   ```bash
   brew install --cask betterdisplay
   brew install lizardbyte/homebrew/sunshine
   ```

2. Open BetterDisplay once, then create a virtual screen that matches the monitor:

   ```bash
   betterdisplaycli create --type=VirtualScreen --virtualScreenName="Wireless Monitor" \
     --aspectWidth=16 --aspectHeight=9 --useResolutionList=on --resolutionList=1920x1080 \
     --virtualScreenHiDPI=off
   ```

3. Copy the Sunshine config and set a login for its web panel:

   ```bash
   mkdir -p ~/.config/sunshine
   cp -n sunshine.conf.example ~/.config/sunshine/sunshine.conf
   /opt/homebrew/opt/sunshine/bin/sunshine ~/.config/sunshine/sunshine.conf --creds <user> <password>
   ```

   The password stays in your shell history. Run `history -c` afterwards if that bothers you.

4. Build the toggle app:

   ```bash
   ./make-app.sh
   ```

   This puts `Wireless Monitor.app` into `~/Applications`. Start it with Spotlight
   (⌘ + Space → "Wireless Monitor"). First click turns the screen on, second click turns it off.
   While it's off, Sunshine isn't running; only BetterDisplay stays in the menu bar.

   Named your virtual screen differently? Change `SCREEN` at the top of
   `wireless-monitor.sh` and run `./make-app.sh` again.

5. Click it once. macOS asks for **Screen Recording** permission, sometimes only when
   the first stream starts: System Settings → Privacy & Security → Screen & System Audio
   Recording. The app shows up there as **applet**. Turn it on, then click the toggle
   twice (off and on) so Sunshine restarts with the permission.

## Setup on the other computer

1. Install [Moonlight](https://moonlight-stream.org).
2. With the toggle on, Moonlight usually finds the Mac on its own. If not, press **+**
   and type the Mac's IP address.
3. Click the Mac. Moonlight shows a 4‑digit PIN. On the Mac, open the Sunshine panel at
   https://localhost:47990 → **PIN**, and enter it. The browser warns about the
   certificate: Sunshine uses a self-signed one, it's safe to continue.
4. In Moonlight settings:
   - **Display mode → Borderless windowed**, so the cursor can leave the stream window;
   - **Input → Optimize mouse for remote desktop instead of games**, so the stream
     doesn't grab the cursor;
   - 1080p, 60 FPS.
5. Move the Moonlight window to the monitor you want to take over, then click
   the Mac → **Desktop**.

## Every day

- **Start:** Mac → Wireless Monitor. Other computer → Moonlight → your Mac → Desktop.
- **Stop:** Ctrl + Alt + Shift + Q in Moonlight, then Wireless Monitor on the Mac again.

If the cursor goes to the wrong side, drag the screen in System Settings → Displays → Arrange.

## Gotchas we hit

| Symptom | Why | Fix |
| --- | --- | --- |
| Sunshine log: `No screen capture permission` | macOS gives Screen Recording to the app that started Sunshine. Started from a terminal or another tool, it has no permission | Always start it with the toggle app |
| PIN isn't accepted through the Sunshine API | Newer Sunshine wants the `pairing_id` from `GET /api/pin` along with the PIN | Use the web panel, or send both |
| Moonlight connects, then `Initial Ping Timeout` | UDP from the Mac got lost on the home Wi‑Fi | Run both machines on Tailscale and set `bind_address` to the Mac's Tailscale IP |
| Moonlight shows the Mac as offline | It only knows the old LAN address | Add the host by hand with the Tailscale IP |
| Your music plays from the other monitor | Sunshine streams audio by default | `stream_audio = disabled` |
| The other person's mouse moves your Mac's cursor | Sunshine accepts input from the client by default | `keyboard`, `mouse`, `controller = disabled` |
| …and now their mouse is stuck inside the stream window | Moonlight captures the cursor for games | Ctrl + Alt + Shift + Z to release it; the two Moonlight settings above to stop it |
| Stream opens on the wrong monitor | Moonlight opens where its window is | Move the window first (Windows: Win + Shift + ←/→) |

## Limits

- The other computer must be on and logged in, and its monitor is yours while streaming.
- A bit of latency and compression. Fine for text, code and browsing; not for colour work.

## License

MIT
