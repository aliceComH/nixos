#!/usr/bin/env python3
"""Central de Updates — um botão por grupo do sistema (irmã da claudia.py).

Cada cartão mostra os inputs do flake que o grupo atualiza, em que data estão
travados, e a lista de pacotes do grupo (nome + versão instalada). O botão abre
um terminal com tools/updates/update-group.sh, que atualiza, constrói, mostra o
diff de versões e só aplica depois de você confirmar.

Rodar: python /etc/nixos/tools/updates/updates.py
"""
import json
import os
import subprocess
from datetime import datetime

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk, Pango  # noqa: E402

FLAKE = "/etc/nixos"
LOCK = os.path.join(FLAKE, "flake.lock")
PACKAGES_JSON = "/etc/update-groups.json"  # gerado por modules/nixos/update-groups.nix
SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "update-group.sh")

# Espelha o `case` de update-group.sh (fonte da verdade do grupo -> inputs).
# "sections" são as chaves de /etc/update-groups.json exibidas no cartão.
GROUPS = [
    {
        "id": "hyprland",
        "title": "Hyprland",
        "color": "#8BE9FD",
        "inputs": ["nixpkgs-hyprland"],
        "sections": [("Pacotes", "hyprland")],
        "note": "Travado por rev em flake.nix. Atualizar troca a rev e pede confirmação extra: "
                "wiki, código-fonte local e regras são da versão travada.",
    },
    {
        "id": "osu",
        "title": "osu!",
        "color": "#FF79C6",
        "inputs": ["nixpkgs-osu"],
        "sections": [("Pacotes", "osu")],
        "note": "Só o osu-lazer. O wrapper de áudio (quantum 32) não muda.",
    },
    {
        "id": "sistema",
        "title": "Sistema (drivers + ferramentas)",
        "color": "#50FA7B",
        "inputs": ["nixpkgs", "home-manager"],
        "sections": [("Drivers", "drivers"), ("Ferramentas", "ferramentas")],
        "note": "Kernel, Mesa, firmware, PipeWire, systemd e todo o userland base saem do mesmo "
                "nixpkgs, por isso atualizam juntos. Kernel e drivers novos pedem reboot.",
    },
    {
        "id": "programas",
        "title": "Programas",
        "color": "#BD93F9",
        "inputs": ["nixpkgs-apps", "antigravity-nix", "claude-desktop", "bedrock-on-linux"],
        "sections": [("Pacotes", "programas")],
        "note": "Também roda `flatpak update --user` (Spotify, DataGrip, ProtonPlus, qBittorrent).",
    },
]


def read_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def lock_info(lock, name):
    """Texto 'input  rev  data' para um input de primeiro nível do flake."""
    try:
        node = lock["nodes"]["root"]["inputs"][name]
        locked = lock["nodes"][node]["locked"]
        date = datetime.fromtimestamp(locked["lastModified"]).strftime("%d/%m/%Y")
        return f"{name}  {locked.get('rev', '?')[:8]}  ({date})"
    except (KeyError, TypeError):
        return f"{name}  (não encontrado no flake.lock)"


class Card(Gtk.Frame):
    def __init__(self, group, on_update):
        super().__init__()
        self.group = group
        self.set_shadow_type(Gtk.ShadowType.IN)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_border_width(12)
        self.add(box)

        title = Gtk.Label(xalign=0)
        title.set_markup(
            f"<span foreground='{group['color']}' size='large'><b>"
            f"{GLib.markup_escape_text(group['title'])}</b></span>"
        )
        box.pack_start(title, False, False, 0)

        note = Gtk.Label(label=group["note"], xalign=0)
        note.set_line_wrap(True)
        note.set_max_width_chars(48)
        note.get_style_context().add_class("dim-label")
        box.pack_start(note, False, False, 0)

        self.buffer = Gtk.TextBuffer()
        self.buffer.create_tag("head", weight=Pango.Weight.BOLD, foreground=group["color"])
        self.buffer.create_tag("dim", foreground="#9AA0B4")
        view = Gtk.TextView(buffer=self.buffer)
        view.set_editable(False)
        view.set_cursor_visible(False)
        view.set_monospace(True)
        view.set_left_margin(8)
        view.set_right_margin(8)
        view.set_top_margin(6)
        view.set_bottom_margin(6)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(190)
        scroll.set_shadow_type(Gtk.ShadowType.IN)
        scroll.add(view)
        box.pack_start(scroll, True, True, 0)

        button = Gtk.Button(label=f"Atualizar {group['title']}")
        button.connect("clicked", lambda _b: on_update(group))
        box.pack_start(button, False, False, 0)

    def refresh(self, lock, packages):
        buf = self.buffer
        buf.set_text("")

        def put(text, tag=None):
            end = buf.get_end_iter()
            if tag:
                buf.insert_with_tags_by_name(end, text, tag)
            else:
                buf.insert(end, text)

        put("Inputs que serão atualizados\n", "head")
        for name in self.group["inputs"]:
            put(f"  {lock_info(lock, name)}\n")

        for label, key in self.group["sections"]:
            put(f"\n{label}\n", "head")
            if packages is None:
                put("  lista disponível depois do próximo rebuild\n", "dim")
                continue
            items = packages.get(key, [])
            width = max((len(p["name"]) for p in items), default=0)
            for p in items:
                put(f"  {p['name']:<{width}}  ")
                put(f"{p.get('version') or '—'}\n", "dim")
            if not items:
                put("  (vazio)\n", "dim")


class UpdatesApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Central de Updates")
        Gtk.Settings.get_default().set_property("gtk-application-prefer-dark-theme", True)
        self.set_default_size(980, 760)
        self.set_border_width(15)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.add(root)

        header = Gtk.Label(xalign=0)
        header.set_markup(
            "<b>Central de Updates</b>  "
            "<span size='small' foreground='#9AA0B4'>cada botão atualiza só o seu grupo, "
            "mostra o diff e pede confirmação antes de aplicar</span>"
        )
        root.pack_start(header, False, False, 0)

        grid = Gtk.Grid(column_spacing=12, row_spacing=12)
        grid.set_column_homogeneous(True)
        grid.set_row_homogeneous(True)
        root.pack_start(grid, True, True, 0)

        self.cards = []
        for i, group in enumerate(GROUPS):
            card = Card(group, self.run_update)
            grid.attach(card, i % 2, i // 2, 1, 1)
            self.cards.append(card)

        self.status = Gtk.Label(xalign=0)
        self.status.get_style_context().add_class("dim-label")
        root.pack_start(self.status, False, False, 0)

        self.signature = None
        self.refresh()
        GLib.timeout_add_seconds(3, self.refresh)

    def refresh(self):
        """Relê flake.lock e a lista de pacotes quando algum dos dois muda."""
        signature = tuple(
            os.stat(p).st_mtime_ns if os.path.exists(p) else 0 for p in (LOCK, PACKAGES_JSON)
        )
        if signature != self.signature:
            self.signature = signature
            lock = read_json(LOCK) or {}
            packages = read_json(PACKAGES_JSON)
            for card in self.cards:
                card.refresh(lock, packages)
        return True

    def run_update(self, group):
        try:
            subprocess.Popen(
                ["kitty", "--title", f"Update: {group['title']}", "bash", SCRIPT, group["id"]]
            )
            self.status.set_text(f"Terminal aberto para: {group['title']}")
        except OSError as err:
            self.status.set_text(f"Não consegui abrir o kitty: {err}")


if __name__ == "__main__":
    app = UpdatesApp()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()
