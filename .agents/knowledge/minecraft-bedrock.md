<!--
Knowledge doc do subsistema Minecraft Bedrock (BedrockOnLinux / WineGDK).
-->

# Minecraft Bedrock (BedrockOnLinux)

## O que é

Cliente Windows GDK da Microsoft Store a correr via BedrockOnLinux
(WineGDK / GDK-Proton + Xodus). Licença PC Java & Bedrock; não é
mcpelauncher/APK.

## Por que existe

`wine` cru não arranca o pacote Store (Xbox/GDK, executável encriptado).
O flake puxa o launcher; o prefix vive em
`~/.local/share/bedrock-on-linux/`. Performance no Hyprland é limitada
por XWayland+vsync e pela main thread do Bedrock (render distance), não
pela RX 9070.

## Arquivos envolvidos

- `flake.nix` — input `bedrock-on-linux` (`follows` nixpkgs).
- `modules/nixos/minecraft-bedrock.nix` — pacote no PATH, wrapped com
  `MESA_VK_WSI_PRESENT_MODE=immediate` (`--set-default`) para o RADV não
  usar FIFO no XWayland (teto aparente a 60 fps).
- `config/hypr/hyprland/windowrules/workspace-5-gaming.lua` — class
  `Minecraft.Windows.exe`: workspace 5, `fullscreen`, `immediate`,
  sem blur/shadow. Tearing no Hyprland 0.55 **só** em fullscreen.
- `modules/home/flatpak-user.nix` — desinstala `io.mrarm.mcpelauncher`.
- `minecraft-bedrock.md` — guia humano (login, doctor, settings in-game).

Kernel zen já tem `CONFIG_NTSYNC=y` e `/dev/ntsync`; o `doctor` reporta
`fast sync: OK`. Não é preciso módulo extra.

## Depende de / Relacionado a

- **Fraco:** [screen-sharing](screen-sharing.md) — mesmo compositor
  Hyprland; sem dependência de portais.
- **Fraco:** GPU AMD (`modules/nixos/amd-gpu.nix`) — RADV; DGC/DXR OK
  na 9070 segundo o doctor.

## Pontos de atenção

- Hyprland **pinado**; não bump para “melhorar” o Wine.
- Não ligar Legacy renderer / `PROTON_USE_WINED3D` — troca D3D12 por
  WineD3D.
- `BOL_INPUT=wayland` é experimental; default é XWayland.
- `gfx_viewdistance` 800 = 50 chunks; doctor avisa a partir de ~32.
- `bwrap` recusa cwd `/etc/nixos`; lançar a partir de `$HOME`.
- Correr `bedrock-on-linux doctor` depois de queixas de FPS/chunks
  antes de mexer no prefix (`repair` não apaga mundos).
