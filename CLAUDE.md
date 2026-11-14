# Configuração do Linux da Alice

## Seu papel

Você é a assistente de configuração desta máquina. O repositório é a configuração
inteira do sistema: NixOS + Home Manager + Hyprland, versionada em git.
Responda sempre em português do Brasil.

## Fatos da máquina

- **Host:** `alice-nixos`
- **Usuária:** `alice`
- **Flake:** `/etc/nixos`
- **Hyprland:** travado na versão `0.55.4` (config em Lua, em `config/hypr/`)

## Regras de operação

- **Rebuild:** o comando é `sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos`.
  Nunca rode sem a Alice pedir; informe o comando e deixe ela decidir.
- **Commits:** só commite quando a Alice pedir.
- **Knowledge:** antes de mexer em qualquer subsistema, consulte
  `.agents/knowledge/_index.md` e leia o doc relacionado, se existir.
- **`.agents/`:** é a fonte única das regras e do knowledge. Não apague nem mova;
  edite as regras lá, não aqui.

## Regras importadas

@.agents/rules/hyprland-guidelines.md
@.agents/rules/pipewire-quantum.md
@.agents/rules/knowledge-docs.md

## Automações

- Skills deste projeto ficam em `.claude/skills/`.
- Ao criar uma automação nova, decida se ela é genérica (`~/.claude/`) ou deste
  projeto (`/etc/nixos/.claude/`). Se os dois servirem, pergunte à Alice
  explicando a vantagem de cada um.

## Hardware

- **Processador:** Intel Core i5-14600K.
- **Placa-mãe:** Asus TUF Gaming B660M-PLUS D4, Intel LGA 1700, mATX, DDR4.
- **SSD:** Kingston Fury Renegade 1TB, M.2 2280, PCIe 4.0 x4, NVMe (SFYRS/1000G).
- **RAM:** 2 kits Corsair Vengeance RGB RS 32GB (2x16GB), 3600MHz, DDR4, CL18
  (CMG32GX4M2D3600C18).
- **GPU:** XFX Radeon RX 9070 Swift Triple Fan OC, 16GB (RX-97SWFT3B7).
- **Monitor:** ASUS ROG Strix OLED 27" XG27ACDMS, QHD, 280Hz, QD-OLED, HDR10.
  É `DP-3` nas configurações do Hyprland.
- **TV:** Samsung 43" Neo QLED QN43QN90BAGXZD, 4K, 144Hz.
  É `HDMI-A-1` nas configurações do Hyprland.
- **Soundbar:** Samsung HW-B650F, 3.1 canais com subwoofer, conectada via fibra óptica.
- **Fone principal:** HyperX Cloud Core (HX-HSCC-2-BK/WW), USB e P3.
- **Fone sem fio:** HyperX Cloud III Wireless (77Z45AA). É usado a partir de um
  loopback do HyperX Cloud Core.
- **Microfone:** HyperX QuadCast S, USB (519P0AA).
- **Teclado:** Wooting 80HE, layout 80%, 8000Hz.
- **Mouse:** Corsair Scimitar Elite, 17 botões, cabeado (CH-9304211-NA).
- **Mesa digitalizadora:** Wacom Intuos Pro Gen 2 PTK470, pequena, sempre conectada via cabo.
