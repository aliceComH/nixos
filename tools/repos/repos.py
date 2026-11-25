#!/usr/bin/env python3
"""Mapa de Pastas — onde a Alice e o Claude mexem, e o estado git de cada uma
(irmã da Central de Updates, tools/updates/updates.py).

Cada cartão mostra caminho, descrição, se é repositório git e, se for: remote
(origin), branch, mudanças não commitadas e ahead/behind em relação ao upstream.
Ahead/behind usa o que já está em cache local; nada vai à rede a não ser pelo
botão "Atualizar remoto" (git fetch).

A lista de pastas fica em tools/repos/pastas.toml.

Rodar:  python /etc/nixos/tools/repos/repos.py            (interface)
        python /etc/nixos/tools/repos/repos.py --print    (mapa no terminal)
        python /etc/nixos/tools/repos/repos.py --json     (mapa em JSON)
        acrescente --fetch para rodar git fetch antes de ler
"""
import json
import os
import subprocess
import sys
import threading
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(HERE, "pastas.toml")
GIT_ENV = {
    **os.environ,
    "GIT_OPTIONAL_LOCKS": "0",     # leitura não disputa o index.lock com outro git
    "GIT_TERMINAL_PROMPT": "0",    # fetch nunca trava pedindo senha
    "LC_ALL": "C",
}


# ── Coleta (sem GTK, usada também pelo --print/--json) ──────────────────────

def load_folders():
    with open(CONFIG, "rb") as f:
        return tomllib.load(f).get("pasta", [])


def git(path, *args, timeout=10):
    r = subprocess.run(
        ["git", "-C", path, *args],
        capture_output=True, text=True, env=GIT_ENV, timeout=timeout,
    )
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def inspect(folder):
    """Dicionário com o estado de uma pasta da config."""
    path = os.path.expanduser(folder["caminho"])
    info = {
        "nome": folder.get("nome", folder["caminho"]),
        "caminho": path,
        "descricao": folder.get("descricao", ""),
        "cor": folder.get("cor", "#8BE9FD"),
        "existe": os.path.isdir(path),
        "git": False,
    }
    if not info["existe"]:
        return info

    try:
        code, top, _ = git(path, "rev-parse", "--show-toplevel")
    except (OSError, subprocess.TimeoutExpired) as err:
        info["erro"] = str(err)
        return info
    # Só conta como repo se a própria pasta for a raiz (não um subdiretório de outro repo).
    if code != 0 or os.path.realpath(top) != os.path.realpath(path):
        if code == 0:
            info["dentro_de"] = top
        return info

    info["git"] = True
    _, status, _ = git(path, "status", "--porcelain=v2", "--branch")
    branch, upstream, ahead, behind, changes = None, None, None, None, 0
    for line in status.splitlines():
        if line.startswith("# branch.head "):
            branch = line.split(" ", 2)[2]
        elif line.startswith("# branch.upstream "):
            upstream = line.split(" ", 2)[2]
        elif line.startswith("# branch.ab "):
            a, b = line.split(" ")[2:4]
            ahead, behind = int(a), -int(b)
        elif line and not line.startswith("#"):
            changes += 1
    code, remote, _ = git(path, "remote", "get-url", "origin")
    _, last, _ = git(path, "log", "-1", "--format=%h %cd  %s", "--date=format:%d/%m/%Y")
    info.update(
        remote=remote if code == 0 else None,
        branch=branch,
        upstream=upstream,
        ahead=ahead,
        behind=behind,
        mudancas=changes,
        ultimo_commit=last or None,
    )
    return info


def fetch(info):
    """git fetch do origin; devolve mensagem de erro ou None."""
    if not info.get("git") or not info.get("remote"):
        return None
    try:
        code, _, err = git(info["caminho"], "fetch", "--quiet", "origin", timeout=60)
    except subprocess.TimeoutExpired:
        return "fetch: tempo esgotado"
    return None if code == 0 else f"fetch: {err.splitlines()[-1] if err else code}"


def collect(do_fetch=False):
    infos = []
    for folder in load_folders():
        info = inspect(folder)
        if do_fetch and info.get("remote"):
            err = fetch(info)
            info = inspect(folder)  # relê ahead/behind com as refs novas
            if err:
                info["erro"] = err
        infos.append(info)
    return infos


def sync_text(info):
    if not info.get("upstream"):
        return "sem upstream"
    a, b = info["ahead"], info["behind"]
    if a == 0 and b == 0:
        return f"em dia com {info['upstream']}"
    parts = []
    if a:
        parts.append(f"{a} à frente")
    if b:
        parts.append(f"{b} atrás")
    return f"{', '.join(parts)} de {info['upstream']}"


def rows(info):
    """Linhas (rótulo, valor, destaque) mostradas no cartão e no --print."""
    if not info["existe"]:
        return [("Estado", "não existe ainda", "warn")]
    if not info["git"]:
        extra = f" (fica dentro do repo {info['dentro_de']})" if info.get("dentro_de") else ""
        out = [("Git", "não é repositório git" + extra, "warn")]
    else:
        changes = info["mudancas"]
        out = [
            ("Git", "repositório", "ok"),
            ("Remote", info["remote"] or "sem origin", None if info["remote"] else "warn"),
            ("Branch", info["branch"] or "?", None),
            ("Mudanças", "nenhuma" if changes == 0 else f"{changes} não commitada(s)",
             "ok" if changes == 0 else "warn"),
            ("Sincronia", sync_text(info),
             "ok" if info.get("upstream") and not (info["ahead"] or info["behind"]) else "warn"),
            ("Último", info["ultimo_commit"] or "sem commits", "dim"),
        ]
    if info.get("erro"):
        out.append(("Erro", info["erro"], "err"))
    return out


def print_map(infos):
    for info in infos:
        print(f"■ {info['nome']}  —  {info['caminho']}")
        print(f"  {info['descricao']}")
        for label, value, _ in rows(info):
            print(f"  {label:<10} {value}")
        print()


# ── Interface GTK3 ──────────────────────────────────────────────────────────

COLORS = {"ok": "#50FA7B", "warn": "#FFB86C", "err": "#FF5555", "dim": "#9AA0B4"}


def run_gui():
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import GLib, Gtk

    esc = GLib.markup_escape_text

    class Card(Gtk.Frame):
        def __init__(self):
            super().__init__()
            self.set_shadow_type(Gtk.ShadowType.IN)
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            box.set_border_width(12)
            self.add(box)

            self.title = Gtk.Label(xalign=0)
            self.path = Gtk.Label(xalign=0, selectable=True)
            self.desc = Gtk.Label(xalign=0)
            self.desc.set_line_wrap(True)
            self.desc.set_max_width_chars(48)
            self.desc.get_style_context().add_class("dim-label")
            for w in (self.title, self.path, self.desc):
                box.pack_start(w, False, False, 0)

            self.grid = Gtk.Grid(column_spacing=14, row_spacing=4)
            self.grid.set_margin_top(4)
            box.pack_start(self.grid, True, True, 0)

            self.open_btn = Gtk.Button(label="Abrir no Thunar")
            self.open_btn.connect("clicked", self.open_folder)
            box.pack_end(self.open_btn, False, False, 0)
            self.info = None

        def show(self, info):
            self.info = info
            self.title.set_markup(
                f"<span foreground='{info['cor']}' size='large'><b>{esc(info['nome'])}</b></span>"
            )
            self.path.set_markup(f"<tt>{esc(info['caminho'])}</tt>")
            self.desc.set_text(info["descricao"])
            for child in self.grid.get_children():
                self.grid.remove(child)
            for i, (label, value, tone) in enumerate(rows(info)):
                key = Gtk.Label(xalign=0)
                key.set_markup(f"<b>{esc(label)}</b>")
                val = Gtk.Label(xalign=0, selectable=True)
                val.set_line_wrap(True)
                val.set_max_width_chars(46)
                text = f"<tt>{esc(value)}</tt>" if label in ("Remote", "Branch") else esc(value)
                if tone:
                    text = f"<span foreground='{COLORS[tone]}'>{text}</span>"
                val.set_markup(text)
                self.grid.attach(key, 0, i, 1, 1)
                self.grid.attach(val, 1, i, 1, 1)
            self.grid.show_all()
            self.open_btn.set_sensitive(info["existe"])

        def open_folder(self, _b):
            try:
                subprocess.Popen(["thunar", self.info["caminho"]])
            except OSError:
                pass

    class ReposApp(Gtk.Window):
        def __init__(self):
            super().__init__(title="Mapa de Pastas")
            Gtk.Settings.get_default().set_property("gtk-application-prefer-dark-theme", True)
            self.set_default_size(1000, 760)
            self.set_border_width(15)

            root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
            self.add(root)

            top = Gtk.Box(spacing=8)
            header = Gtk.Label(xalign=0)
            header.set_markup(
                "<b>Mapa de Pastas</b>  "
                "<span size='small' foreground='#9AA0B4'>onde a Alice e o Claude mexem; "
                "lista em tools/repos/pastas.toml</span>"
            )
            top.pack_start(header, True, True, 0)
            self.fetch_btn = Gtk.Button(label="Atualizar remoto")
            self.fetch_btn.set_tooltip_text("git fetch em cada repositório com origin")
            self.fetch_btn.connect("clicked", lambda _b: self.reload(do_fetch=True))
            reload_btn = Gtk.Button(label="Recarregar")
            reload_btn.connect("clicked", lambda _b: self.reload())
            top.pack_end(self.fetch_btn, False, False, 0)
            top.pack_end(reload_btn, False, False, 0)
            root.pack_start(top, False, False, 0)

            self.grid = Gtk.Grid(column_spacing=12, row_spacing=12)
            self.grid.set_column_homogeneous(True)
            scroll = Gtk.ScrolledWindow()
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scroll.add(self.grid)
            root.pack_start(scroll, True, True, 0)

            self.status = Gtk.Label(xalign=0)
            self.status.get_style_context().add_class("dim-label")
            root.pack_start(self.status, False, False, 0)

            self.cards = []
            self.busy = False
            self.reload()

        def reload(self, do_fetch=False):
            if self.busy:
                return
            self.busy = True
            self.fetch_btn.set_sensitive(False)
            self.status.set_text("Rodando git fetch…" if do_fetch else "Lendo pastas…")

            def work():
                try:
                    result = collect(do_fetch)
                except (OSError, ValueError) as err:  # config inválida, etc.
                    result = err
                GLib.idle_add(self.done, result, do_fetch)

            threading.Thread(target=work, daemon=True).start()

        def done(self, result, fetched):
            self.busy = False
            self.fetch_btn.set_sensitive(True)
            if isinstance(result, Exception):
                self.status.set_text(f"Erro lendo {CONFIG}: {result}")
                return False
            while len(self.cards) < len(result):
                card = Card()
                i = len(self.cards)
                self.grid.attach(card, i % 2, i // 2, 1, 1)
                self.cards.append(card)
            while len(self.cards) > len(result):
                self.grid.remove(self.cards.pop())
            for card, info in zip(self.cards, result):
                card.show(info)
            self.grid.show_all()
            from datetime import datetime
            when = datetime.now().strftime("%H:%M:%S")
            self.status.set_text(
                f"{'Remoto atualizado' if fetched else 'Lido'} às {when} — {len(result)} pasta(s)"
            )
            return False

    app = ReposApp()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()


if __name__ == "__main__":
    args = set(sys.argv[1:])
    if "--json" in args:
        print(json.dumps(collect("--fetch" in args), ensure_ascii=False, indent=2))
    elif "--print" in args:
        print_map(collect("--fetch" in args))
    else:
        run_gui()
