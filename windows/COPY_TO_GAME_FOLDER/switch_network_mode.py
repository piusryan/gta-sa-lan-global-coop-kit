import re
import shutil
import socket
import subprocess
import sys
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

ROOT = Path(__file__).resolve().parent
CONFIG = ROOT / "coop" / "server.ini"
BACKUP = ROOT / "coop" / "server.ini.bak"
GAME = ROOT / "gta_sa.exe"


def read_config():
    if not CONFIG.exists():
        raise FileNotFoundError("Config not found: " + str(CONFIG))
    return CONFIG.read_text(encoding="utf-8")


def get_setting(text, key):
    match = re.search(r"(?m)^[ \t]*" + re.escape(key) + r"[ \t]*=[ \t]*(.*?)[ \t]*(\r?)$", text)
    return match.group(1) if match else ""


def set_setting(text, key, value):
    pattern = re.compile(r"(?m)^([ \t]*" + re.escape(key) + r"[ \t]*=[ \t]*).*?(\r?)$")
    if pattern.search(text):
        return pattern.sub(lambda m: m.group(1) + value + m.group(2), text)
    return text.rstrip("\r\n") + "\r\n" + key + " = " + value + "\r\n"


def lan_ip():
    sock = None
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.connect(("192.0.2.1", 80))
        ip = sock.getsockname()[0]
        if ip and not ip.startswith(("127.", "169.254.")):
            return ip
    except OSError:
        pass
    finally:
        if sock is not None:
            sock.close()
    try:
        for ip in socket.gethostbyname_ex(socket.gethostname())[2]:
            if not ip.startswith(("127.", "169.254.")):
                return ip
    except OSError:
        pass
    return "not detected"


app = tk.Tk()
app.title("GTA SA Co-op - Network Mode Switcher")
app.geometry("660x640")
app.resizable(False, False)
app.configure(bg="#f5f5f8")

style = ttk.Style()
style.configure("TButton", padding=6)
style.configure("TCheckbutton", background="#f5f5f8")

mode = tk.IntVar(value=0)
name = tk.StringVar()
port = tk.StringVar(value="7788")
players = tk.StringVar(value="2")
password = tk.StringVar()
turn = tk.StringVar()
show_pass = tk.BooleanVar(value=False)


def make_label(parent, text, x, y, w, h=20):
    label = tk.Label(parent, text=text, anchor="w", bg="#f5f5f8", font=("Segoe UI", 9))
    label.place(x=x, y=y, width=w, height=h)
    return label


title = tk.Label(app, text="GTA SA Story Co-op", anchor="w", bg="#f5f5f8", font=("Segoe UI", 15, "bold"))
title.place(x=22, y=14, width=360, height=28)
make_label(app, "Pick a mode, check the details, then click Apply. Simple.", 22, 45, 450)

badge = tk.Label(app, text="MODE: LAN", bg="#def0ff", font=("Segoe UI", 9, "bold"), relief="solid", borderwidth=1)
badge.place(x=480, y=19, width=150, height=26)

frame_mode = tk.LabelFrame(app, text="1. Choose how to play", bg="#f5f5f8", font=("Segoe UI", 9, "bold"))
frame_mode.place(x=20, y=78, width=600, height=112)

tk.Radiobutton(frame_mode, text="LAN only  -  both PCs on the same Wi-Fi / router", variable=mode, value=0,
               anchor="w", bg="#f5f5f8", font=("Segoe UI", 10), command=lambda: update_info()).place(
               x=18, y=25, width=560, height=28)
tk.Radiobutton(frame_mode, text="GLOBAL / Online  -  play with friends over the internet", variable=mode, value=1,
               anchor="w", bg="#f5f5f8", font=("Segoe UI", 10, "bold"), command=lambda: update_info()).place(
               x=18, y=66, width=560, height=28)

frame_details = tk.LabelFrame(app, text="2. Server details", bg="#f5f5f8", font=("Segoe UI", 9, "bold"))
frame_details.place(x=20, y=200, width=600, height=160)

make_label(frame_details, "Name:", 16, 28, 70)
entry_name = tk.Entry(frame_details, textvariable=name)
entry_name.place(x=90, y=24, width=490, height=24)

make_label(frame_details, "Port:", 16, 66, 70)
entry_port = tk.Entry(frame_details, textvariable=port, width=10)
entry_port.place(x=90, y=62, width=90, height=24)

make_label(frame_details, "Max players:", 205, 66, 85)
combo_players = ttk.Combobox(frame_details, textvariable=players, values=["2", "3", "4"], state="readonly", width=8)
combo_players.place(x=295, y=62, width=90, height=24)

make_label(frame_details, "Password:", 16, 102, 70)
entry_password = tk.Entry(frame_details, textvariable=password, show="*")
entry_password.place(x=90, y=98, width=360, height=24)

tk.Checkbutton(frame_details, text="Show", variable=show_pass, bg="#f5f5f8",
               command=lambda: entry_password.configure(show="" if show_pass.get() else "*")).place(
               x=460, y=99, width=100, height=20)

make_label(frame_details, "Empty password = no password. For Global mode a password is strongly recommended.", 16, 132, 560)

frame_adv = tk.LabelFrame(app, text="3. Advanced - only if a friend cannot connect", bg="#f5f5f8", font=("Segoe UI", 9, "bold"))
frame_adv.place(x=20, y=370, width=600, height=86)

make_label(frame_adv, "TURN relay:", 16, 28, 80)
entry_turn = tk.Entry(frame_adv, textvariable=turn)
entry_turn.place(x=100, y=24, width=480, height=24)

hint = tk.Label(frame_adv, text="metered:<app>:<api-key>   or   turn:<host>:<port>:<user>:<password>   (leave empty normally)",
                anchor="w", bg="#f5f5f8", fg="#6e6e78", font=("Segoe UI", 8))
hint.place(x=100, y=52, width=480, height=20)

info = tk.Label(app, text="", anchor="nw", justify="left", bg="#e8f4ff", relief="solid", borderwidth=1,
                font=("Segoe UI", 9), wraplength=570)
info.place(x=20, y=466, width=600, height=70)

ttk.Button(app, text="Apply & Save", command=lambda: apply_config(False)).place(x=22, y=548, width=150, height=36)
ttk.Button(app, text="Apply & Launch GTA", command=lambda: apply_config(True)).place(x=182, y=548, width=170, height=36)
ttk.Button(app, text="Open config", command=lambda: open_config()).place(x=362, y=548, width=120, height=36)
ttk.Button(app, text="Close", command=app.destroy).place(x=492, y=548, width=128, height=36)

make_label(app, "Your LAN IP: " + lan_ip(), 22, 596, 600)


def update_info():
    if mode.get() == 1:
        info.configure(text="GLOBAL MODE\nThe mod detects your public IP and forwards UDP 7788 automatically. Give friends the invite code shown in F9 (or your public IP). Close and restart GTA after applying.", bg="#fff2d9")
        badge.configure(text="MODE: GLOBAL", bg="#ffe0a8")
    else:
        info.configure(text="LAN MODE\nBoth PCs must be on the same router. Friends connect with your LAN IP (shown at the bottom) and port 7788. Nothing else to set up.", bg="#e8f4ff")
        badge.configure(text="MODE: LAN", bg="#def0ff")


def apply_config(launch):
    current_mode = "1" if mode.get() == 1 else "0"
    server_name = name.get().strip()
    server_port = port.get().strip()
    max_players = players.get().strip() or "2"
    server_password = password.get()
    relay = turn.get().strip()

    if not server_name:
        messagebox.showwarning("Missing name", "Please enter a server name.", parent=app)
        return
    if not server_port.isdigit() or not 1 <= int(server_port) <= 65535:
        messagebox.showwarning("Bad port", "Port must be a number from 1 to 65535.", parent=app)
        return
    if current_mode == "1" and not server_password:
        answer = messagebox.askyesno("No password", "Global mode with no password means anyone who finds the server can join. Continue anyway?", parent=app)
        if not answer:
            return

    try:
        text = read_config()
        shutil.copyfile(CONFIG, BACKUP)
        for key, value in (("name", server_name), ("port", server_port), ("max_players", max_players),
                           ("password", server_password), ("internet", current_mode), ("turn", relay)):
            text = set_setting(text, key, value)
        with open(CONFIG, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
    except Exception as exc:
        messagebox.showerror("Could not save", str(exc), parent=app)
        return

    update_info()
    if launch:
        if not GAME.exists():
            messagebox.showerror("Missing game", "gta_sa.exe was not found in this folder.", parent=app)
            return
        if sys.platform == "win32":
            subprocess.Popen([str(GAME)], cwd=str(ROOT))
        else:
            messagebox.showinfo("Launch manually", "On Linux, start GTA San Andreas through Wine, then press F9 in the game.", parent=app)
    else:
        messagebox.showinfo("Done", "Saved. Close GTA completely and start it again, then press F9 in the game to host or join.", parent=app)


def open_config():
    try:
        if sys.platform == "win32":
            subprocess.Popen(["notepad.exe", str(CONFIG)])
        else:
            subprocess.Popen(["xdg-open", str(CONFIG)])
    except OSError as exc:
        messagebox.showerror("Could not open", str(exc), parent=app)


try:
    initial = read_config()
    mode.set(1 if get_setting(initial, "internet").strip() == "1" else 0)
    loaded_name = get_setting(initial, "name").strip()
    if loaded_name:
        name.set(loaded_name)
    loaded_port = get_setting(initial, "port").strip()
    if loaded_port:
        port.set(loaded_port)
    loaded_players = get_setting(initial, "max_players").strip()
    if loaded_players in ("2", "3", "4"):
        players.set(loaded_players)
    password.set(get_setting(initial, "password"))
    turn.set(get_setting(initial, "turn").strip())
except Exception as exc:
    messagebox.showerror("Config problem", str(exc), parent=app)

update_info()
app.mainloop()
