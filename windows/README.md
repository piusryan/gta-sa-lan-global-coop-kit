# LAN + Global Co-op Kit

One archive for GTA San Andreas story co-op with a simple mode switcher.

## What this is

- **SA:COOP v0.3.4** - two to four players play the same story (missions, cutscenes, cars, police, weather).
- **Mode switcher** - a small GUI with two big buttons: **LAN only** or **GLOBAL / Online**.
  - Windows: `Switch-Network-Mode.bat` (double-click, no install needed).
  - Linux/Arch: `bash run-switcher.sh` (needs `sudo pacman -S python tk`).
  - The Python version also works on Windows.
- **Gameplay guide** - `LAN-STORY-COOP-INSTRUCTIONS.md`.

Requires a legally owned **GTA San Andreas 1.0 US**. This kit does **not** include the game or its files.

## Install

1. Install GTA San Andreas 1.0 US.
2. Open `COPY_TO_GAME_FOLDER` and copy **everything inside it** into your GTA folder (next to `gta_sa.exe`).
3. Run `install.bat` there (Windows) to install the ASI loader. Skip on an existing modded install.
4. Run the switcher, choose LAN or GLOBAL, click **Apply & Save**.
5. Start `gta_sa.exe`, press **F9** in the main menu, host or join.

The switcher saves `coop/server.ini.bak` before every change.

## LAN vs Global

| | LAN | Global |
|---|---|---|
| Who can join | Same router / Wi-Fi | Anyone with the invite code or public IP |
| Connect with | Host's LAN IP + port 7788 | Invite code `XXXX-XXXX-XXXX` or public IP + 7788 |
| Router setup | None | UPnP (automatic), or forward UDP 7788 manually |
| Recommended | fine without password | set a password |

If the host has CGNAT or a friend cannot connect, set a TURN relay in the switcher:
`metered:<app>:<api-key>` or `turn:<host>:<port>:<user>:<password>`.

## Notes for sharing

- Share the whole ZIP, keep `NOTICE.txt` and the license files in `coop/licenses/`.
- Do not add `gta_sa.exe`, `gta3.img`, or the original game DLLs.
- Everyone must use the same mod version (v0.3.4, protocol 63).
- Optional extras (HUD.asi, modloader, widescreen fixes) are not bundled; add them separately if wanted.
