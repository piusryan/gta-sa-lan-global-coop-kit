# GTA San Andreas — Story Co-op on LAN (2 PCs)

This setup lets **two devices on the same LAN play the whole GTA San Andreas story together** (same missions, cutscenes, cars, police, weather, shared save on the host).

> The `Server` folder (open.mp) and `LAN Client` folder (SA-MP) are a **separate deathmatch/gungame setup**. They do **not** run story mode. For story co-op, use `gta_sa.exe` directly as described below.

## What is already installed on this PC

- Game version: **GTA San Andreas 1.0 US** (required by the mod).
- **SA:COOP v0.3.4** installed in the game folder:
  - `coop.asi`, `install.bat`, `coop\` folder
  - ASI loader installed as `vorbisFile.dll`; the original game file was saved as `vorbisHooked.dll`
- Config files (created on first launch):
  - `coop\server.ini` — port `7788`, 2 players, LAN-only (`internet = 0`), name `GTA SA Story Co-op (LAN)`
  - `coop\coop.ini` — English UI (`language = en`)
- Windows Firewall rules added: allow `coop\coop-server.exe` and allow **UDP 7788** (Private/Domain networks).
- Update source kept for reference: `SA-COOP-v0.3.4-UPDATE\` (see `UPDATE-WINDOWS.txt` inside it).

Verify after launch: `coop\coop.log` must begin with `SA:COOP 0.3.4 (protocol 63) loaded`.

---

## 1. Set up the second PC

1. Install GTA San Andreas **1.0 US** there (same game version).
2. The Linux PC is already on **0.3.4**. For a new second PC, copy the 0.3.4 files from this folder: `coop.asi`, `install.bat`, `vorbisFile.dll` and the `coop\` folder.
3. Place them **inside the game folder**, next to `gta_sa.exe`, so you get:
   - `coop.asi`
   - `install.bat`
   - `coop\` folder
4. Run `install.bat` only on a fresh install. Do **not** run it for an update.
5. **Both PCs must use v0.3.4.** Different versions cannot connect to each other.

---

## 2. Start the host (the PC with the story save)

1. Double-click **`gta_sa.exe`** in the game folder.
   - Do **not** use `samp.exe`, `LAN Client\Join-LAN.bat`, or open.mp for story co-op.
2. The SA:COOP window opens in the main menu. If it is in Russian, click **EN** at the top, or press **F9** to open it again.
3. Type your nickname.
4. Open the **Host a game** tab:
   - Choose a save slot, or choose **New game** to start from the beginning.
   - Set players to **2**.
   - Optional: Friendly fire / Shared life checkboxes.
   - Click **Start the server**.
5. Write down the code shown (`XXXX-XXXX-XXXX`) **and/or** find your LAN IP with `ipconfig` (IPv4 Address, for example `192.168.1.2` or `192.168.0.250`).
6. Leave the game running.

---

## 3. Join from the second PC

1. Double-click **`gta_sa.exe`**.
2. Press **F9** (or use the window that opens in the main menu).
3. Open the **Join a game** tab.
4. Enter:
   - Host: the host PC's LAN IP (for example `192.168.1.2`) — or paste the invite code.
   - Port: `7788`
   - Password: leave empty (no password by default)
5. Click **Connect**. The host's world loads on your side.

Both PCs must be on the same router/LAN. A VPN will usually break the connection.

---

## 4. How to play the story together

- The **host** starts story missions. A mission begins when both players are standing in the mission marker.
- If someone is far away, the host can press **Y** in the marker to start immediately and bring the partner over.
- Partners see the same texts, blips, markers, cutscenes and rewards. Enemies attack everyone.
- Money, skills, clothes, weapons and look are separate for each player. Story progress/save follows the host.
- When the host saves the game, the guest's progress is saved too.

### Main keys

| Key | Action |
|---|---|
| `F9` | SA:COOP window (host/join, settings, language) |
| `T` | Chat (`Enter` send, `Esc` close) |
| `B` | Voice chat (hold) |
| `G` | Sit in the nearest car as passenger |
| `Y` / `N` | Yes / No (invites, teleports, start mission) |
| `F2` | Player list, give money/weapons |
| `F4` | Skins |
| `U` | Animations |
| `F7` | Hide/show the mod interface |
| `Enter` / `Esc` | Offer / agree / refuse to skip a cutscene |

Chat commands: `/help`, `/players`, `/tp`, `/tphere`, `/kick <nickname>` (host).

---

## 5. Troubleshooting

- **"The server does not answer"** on the guest:
  - Make sure the host game is running and the server was started in F9.
  - Use the host's **LAN IP**, not `127.0.0.1` (that only works on the same PC).
  - On the host PC, allow the app through Windows Firewall:
    - `coop\coop-server.exe`
    - UDP port `7788`
    - Network type must be **Private** or **Domain** (Wi-Fi here is already Private).
  - Turn off VPNs on both PCs.
- **Antivirus deleted `coop.asi` or `coop-server.exe`**: add the game folder to antivirus exclusions, then copy the files from `SA-COOP-v0.3.4-UPDATE\` again.
- **Mod does not start / no F9 window**: make sure you launched `gta_sa.exe` directly. SA:COOP switches itself off when SA-MP/open.mp starts the game.
- **Different versions**: everyone must use v0.3.4 (protocol 63). Older versions cannot connect.
- Logs to check: `coop\coop.log`, `coop\coop.old.log`, `coop\server-data\server.log`.

---

## 6. Quick reference

| Thing | Value |
|---|---|
| Story co-op mod | SA:COOP v0.3.4 |
| Game version | GTA SA 1.0 US |
| Host port | UDP 7788 |
| Max players | 2 |
| Host window key | F9 |
| Start game for story | `gta_sa.exe` |
| Separate deathmatch server (not story) | `Server\Start-LAN-Server.bat` → UDP 7777 |
