========================================================================
 GTA SAN ANDREAS - LAN / GLOBAL STORY CO-OP SERVER KIT
 Arch Linux edition - made from a working setup
========================================================================

This folder contains every script, config and note that was used to build
a GTA San Andreas story co-op server that runs on Linux (Arch + Wine),
plus a clean generator so another person can build their OWN LAN server
or their OWN Global/Online server from scratch.

The 5.9 GB game itself is NOT copied here. You need your own legal copy
of GTA San Andreas 1.0 US (Windows) on every PC. Mod files used by this
setup are included in mod/ so a fresh install can be reproduced.

------------------------------------------------------------------------
0. WHAT IS IN THIS KIT
------------------------------------------------------------------------

scripts/
  setup-linux.sh             First-time Linux setup: chmod +x *.sh and
                             create the local .wine-prefix.
  start-story-coop.sh        Launches gta_sa.exe with the correct Wine
                             prefix (never launch the .exe directly).
  Switch-Network-Mode.sh     Native Linux LAN / Global switcher with a
                             terminal menu. Also has quick flags.
  Switch-Network-Mode.desktop  Desktop launcher for the switcher.
  Switch-Network-Mode.bat    Original Windows launcher (reference).
  Switch-Network-Mode.ps1    Original Windows GUI script (reference).
  create-coop-server.sh      NEW: builds a fresh, clean coop/server.ini
                             for LAN or Global with one command.
  install.bat                SA:COOP ASI-loader installer (Windows).

config/
  server.ini.lan.template    Clean LAN preset  (internet = 0).
  server.ini.global.template Clean Global preset (internet = 1).
  coop.ini.template          Clean client/UI config: no nickname and no
                             password from the original setup.

mod/SA-COOP-v0.3.4/          SA:COOP v0.3.4 files used to install the mod
                             (coop.asi, ASI loader, coop-server.exe, notes).
                             Everyone must use v0.3.4 (protocol 63).

docs/                        The original notes from the working setup:
                             LINUX-START.txt (Arch/Wine guide),
                             LAN-STORY-COOP-INSTRUCTIONS.md (game guide),
                             Readme.txt, Leia-me.txt, Инструкция.txt.

------------------------------------------------------------------------
1. REQUIREMENTS - EVERY PC (HOST AND GUEST)
------------------------------------------------------------------------

* Arch Linux with the multilib repo enabled. Edit /etc/pacman.conf:

      [multilib]
      Include = /etc/pacman.d/mirrorlist

  then:

      sudo pacman -Syu
      sudo pacman -S wine wine-gecko wine-mono lib32-libldap \
        lib32-gnutls lib32-alsa-lib lib32-openal lib32-libpulse \
        lib32-mesa lib32-libx11 lib32-libxrandr

  Optional but recommended for old-game audio:

      sudo pacman -S fluidsynth lib32-fluidsynth

  Log out/in after the first 32-bit driver install if Wine complains
  about missing 32-bit OpenGL.

* GTA San Andreas 1.0 US (Windows). Other versions are not supported
  by SA:COOP. Put the game in its FINAL folder location BEFORE setup,
  because the Wine prefix stores absolute paths inside itself.

* SA:COOP v0.3.4. The game folder in this kit's origin already has it
  installed. For a fresh PC, copy the files from mod/SA-COOP-v0.3.4/
  into the game folder (next to gta_sa.exe) and run install.bat once
  if the ASI loader is missing. On Linux you can just copy an already
  working game folder to the second PC.

* LAN game: both PCs on the same router, VPN off.
  Global game: internet on host, UPnP enabled OR UDP 7788 forwarded
  in the router, VPN/CGNAT issues may need a TURN relay.

------------------------------------------------------------------------
2. BUILD YOUR OWN LAN SERVER (same router, 2 PCs)
------------------------------------------------------------------------

HOST PC - the one that has the story save:

  1. Copy your GTA SA folder to the final place, for example:

         cd ~
         cp -a "/path/to/GTA SA" "gta-sa-coop"
         cd "gta-sa-coop"

  2. Copy the Linux scripts into the game folder:

         cp /path/to/LAN-GLOBAL-COOP-KIT/scripts/*.sh .
         cp /path/to/LAN-GLOBAL-COOP-KIT/scripts/*.desktop .

     Keep the .desktop file next to the scripts: it finds the game
     folder from its own location. If you want a shortcut on your
     Desktop instead, copy the .desktop there and change its Exec line
     to: Exec=bash -c 'cd "/absolute/path/to/gta-sa-coop" && ./Switch-Network-Mode.sh'

  3. If coop/coop.ini does not exist yet, create it from the template:

         mkdir -p coop
         cp /path/to/LAN-GLOBAL-COOP-KIT/config/coop.ini.template coop/coop.ini

     If it already exists, keep it: it stores your nickname and F9 settings.

  4. Run the first-time setup once:

         bash setup-linux.sh

  5. Create your LAN server config:

         ./create-coop-server.sh . --lan --name "My LAN Co-op" --port 7788 --players 2

     Or run it with no options for interactive questions:

         ./create-coop-server.sh . --lan

     It writes coop/server.ini and keeps a backup at coop/server.ini.bak.

  6. Open UDP 7788 on the host firewall:

         sudo ufw allow 7788/udp

     or with firewalld:

         sudo firewall-cmd --add-port=7788/udp --permanent
         sudo firewall-cmd --reload

  7. Start the game:

         ./start-story-coop.sh

  8. Press F9 in the main menu (click EN if the window is Russian).
     Enter your nickname, open "Host a game", choose a save slot or
     "New game", set players to 2, click "Start the server".
     Write down the invite code XXXX-XXXX-XXXX if one is shown.

  9. Find the host LAN IP:

         ip -4 -o addr show scope global
     Example: 192.168.1.23. You can also run:
         ./Switch-Network-Mode.sh --status

  10. Leave the game running.

GUEST PC:

  1. Install/copy the same game + SA:COOP v0.3.4, copy scripts/*.sh into
     that game folder and run "bash setup-linux.sh" once.
  2. Start with "./start-story-coop.sh".
  3. F9 -> "Join a game" -> host = the host's LAN IP (192.168.1.23 in
     the example) or the invite code -> port 7788 -> password (whatever
     you set, empty if you left it empty) -> Connect.
  4. Do NOT use 127.0.0.1 unless both players are on the same PC.

------------------------------------------------------------------------
3. BUILD YOUR OWN GLOBAL / ONLINE SERVER (friends over the internet)
------------------------------------------------------------------------

HOST PC:

  1. Do steps 1-4 of section 2 on the host.

  2. Create a Global config WITH a password (strongly recommended):

         ./create-coop-server.sh . --global --name "My Online Co-op" \
              --port 7788 --players 2 --password "choose-a-secret"

     This sets internet = 1 in coop/server.ini. A password is required
     by the generator unless you explicitly pass --no-password, because
     anyone who finds the server could otherwise join.

  3. Router: enable UPnP. SA:COOP detects the public IP and tries to
     forward UDP 7788 automatically. If UPnP is disabled or blocked by
     your ISP, forward UDP 7788 manually to the host's LAN IP in your
     router admin page (e.g. 192.168.1.23 -> port 7788 UDP).

  4. Firewall on the host: sudo ufw allow 7788/udp
     (or the firewalld commands from section 2).

  5. Start "./start-story-coop.sh", press F9, open "Host a game",
     start the server, and give friends the invite code shown in F9
     (or your public IP from e.g. whatismyipaddress.com).

  6. If a friend still cannot connect (symmetric NAT, CGNAT, mobile
     hotspot), use a TURN relay. Either add it when generating:

         ./create-coop-server.sh . --global --name "My Online Co-op" \
              --password "secret" --turn "metered:<app>:<api-key>"

     or paste it later with the mode switcher (section 4). Accepted
     formats:

         metered:<application-name>:<api-key>
         turn:<host>:<port>:<user>:<password>

     A free account at metered.ca works. Never share the API key.

GUEST PC:

  Press F9 -> "Join a game" -> enter the invite code or the host's
  public IP -> port 7788 -> the password -> Connect. Guest needs the
  same game version and SA:COOP v0.3.4.

------------------------------------------------------------------------
4. SWITCH MODES LATER (or fix settings without regenerating)
------------------------------------------------------------------------

  ./Switch-Network-Mode.sh                 interactive menu
  ./Switch-Network-Mode.sh --status        show mode, settings, LAN IP
  ./Switch-Network-Mode.sh --lan           quick switch, no questions
  ./Switch-Network-Mode.sh --global        quick switch, no questions
  ./Switch-Network-Mode.sh --global --launch   switch + start the game

  The menu lets you edit name, port, max players, password and TURN
  relay, choose LAN or Global, and either just save or also launch GTA.
  It always backs up coop/server.ini to coop/server.ini.bak and keeps
  the CRLF line endings the game expects.

  On Windows the original Switch-Network-Mode.bat (which calls
  Switch-Network-Mode.ps1) does the same thing through a GUI.

  IMPORTANT: close GTA completely and start it again after changing
  any server setting, then press F9 to host or join.

------------------------------------------------------------------------
5. server.ini KEY REFERENCE
------------------------------------------------------------------------

  name          server name shown to friends
  port          UDP port, default 7788 (host and guest must match)
  password      empty = no password. Fine for private LAN, bad for Global
  max_players   2, 3 or 4
  internet      0 = LAN only; 1 = Global (UPnP + invite code in F9)
  turn          optional TURN relay for difficult NAT
  host          fixed host nickname; empty = first player to join hosts
  friendly_fire 0/1 - can players hurt each other
  partner_teleport 0/1 - allow /tp and /tphere
  shared_life   0/1 - partner death fails host's story mission

------------------------------------------------------------------------
6. HOW STORY CO-OP WORKS (quick reminder)
------------------------------------------------------------------------

  The HOST starts story missions. A mission begins when both players
  stand in the marker. Press Y in the marker to force-start and bring
  the partner over. Partners see the same cutscenes, markers, enemies
  and rewards. Money/skills/look are separate; story progress follows
  the host's save.

  Keys: F9 co-op window, T chat (Enter send, Esc close), B voice
  (hold), G sit in nearest car, Y/N yes/no, F2 player list, F4 skins,
  U animations, F7 toggle mod UI. Commands: /help /players /tp
  /tphere /kick <nick>.

------------------------------------------------------------------------
7. TROUBLESHOOTING
------------------------------------------------------------------------

  "Server does not answer" on the guest:
    - Host game must be running and the server started in F9.
    - Use the host's real LAN IP, not 127.0.0.1.
    - Allow UDP 7788 on the host (ufw/firewalld) and make sure the
      network is Private, not Public.
    - Turn off VPNs on both PCs.

  Global guest cannot connect:
    - Check UPnP or manual UDP 7788 forward on the host router.
    - ISP may use CGNAT (host has 10.x / 100.64.x / 172.16-31.x
      WAN IP): use a TURN relay or a different network.
    - Confirm the password and the invite code are current.

  No F9 window / mod not loaded:
    - Launch with ./start-story-coop.sh (direct gta_sa.exe).
    - coop.asi and the coop/ folder must sit next to gta_sa.exe.
    - coop/coop.log should begin with "SA:COOP 0.3.4 (protocol 63) loaded".

  "Wine: no 32-bit support":
    - Enable multilib and install the lib32-* packages from section 1.

  Different versions cannot connect:
    - Everyone must use SA:COOP v0.3.4, protocol 63.

  Antivirus removed coop.asi or coop-server.exe:
    - Add the game folder to exclusions, restore files from mod/ here.

  Logs to inspect: coop/coop.log, coop/coop.old.log,
  coop/server-data/server.log.

  If the game runs but graphics look wrong, add "export WINEDEBUG=-all"
  before the launch command or set windowed mode in coop/coop.ini.

------------------------------------------------------------------------
8. SAFETY / HOUSEKEEPING
------------------------------------------------------------------------

  * Do not share your server password, TURN credentials or API key.
  * Do not delete .wine-prefix after the first launch; it contains the
    Wine installation and stored paths.
  * The mode switcher and generator keep .bak files: copy them back if
    a new config breaks the connection.
  * The guest only needs the client side; the host runs the server in
    the game via F9. There is no separate Windows service required for
    story co-op.
  * Do not run install.bat on an already installed game; run it only
    on a fresh game folder when the ASI loader is missing.

========================================================================
 Quick path: copy scripts/ -> game folder, bash setup-linux.sh,
 ./create-coop-server.sh . --lan (or --global with --password), 
 ./start-story-coop.sh, press F9, Host a game -> Start the server.
========================================================================
