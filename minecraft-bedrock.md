# Minecraft Bedrock (licença Microsoft Store) no NixOS + Hyprland

Caminho **Wine**, para quem **só** tem o pacote PC *Java & Bedrock* da Microsoft.

Não usamos mcpelauncher (isso é o APK Android / Google Play). O cliente que a Microsoft te vendeu é o **Windows GDK**. `wine` cru na app da Store **não corre** (Xbox/GDK). O que instalamos é o [BedrockOnLinux](https://github.com/Wyze3306/BedrockOnLinux): prefix Wine gerido + motor **WineGDK / GDK-Proton**, jogo descarregado **dos servidores da Microsoft com a tua conta**.

Instável no sentido de “projecto comunitário, updates do Minecraft podem partir uma versão” — não no sentido de ser pirataria. **Não há ficheiros do jogo no Nix.** Sem a compra Microsoft, o download recusa.

---

## O que está no repo

| Ficheiro | Função |
|---|---|
| [`flake.nix`](flake.nix) | Input `bedrock-on-linux` |
| [`modules/nixos/minecraft-bedrock.nix`](modules/nixos/minecraft-bedrock.nix) | Pacote no PATH (`bedrock-on-linux`) |
| [`modules/home/flatpak-user.nix`](modules/home/flatpak-user.nix) | Remove o Flatpak antigo `io.mrarm.mcpelauncher` |
| [`config/hypr/hyprland/windowrules/workspace-5-gaming.lua`](config/hypr/hyprland/windowrules/workspace-5-gaming.lua) | Workspace 5 |

```bash
sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos
bedrock-on-linux
```

---

## 1. Módulo NixOS (referência)

`modules/nixos/minecraft-bedrock.nix`:

```nix
{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

Input em `flake.nix`:

```nix
bedrock-on-linux = {
  url = "github:Wyze3306/BedrockOnLinux";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Actualizar só isto (não toca no Hyprland):

```bash
nix flake update bedrock-on-linux
sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos
```

Equivalente sem flake (teste):

```bash
nix run github:Wyze3306/BedrockOnLinux
```

---

## 2. Porque não é `wine Minecraft.exe`

O Bedrock de PC deixou de ser UWP clássico e passou a **GDK** (Xbox identity, WinAppSDK, pacote da Store ainda encriptado). O Wine normal não:

- inicia sessão Xbox / XUser;
- desencripta o executável `KEEP_ENCRYPTED_ON_DISK`;
- fala com o CDN da Store com a tua licença.

O BedrockOnLinux empacota um **GDK-Proton** (fork WineGDK) e o [Xodus](https://github.com/xodus-gaming/xodus) para o download oficial. Por baixo **é Wine**. O wrapper no Nix é `steam-run` (FHS), o mesmo padrão de muitos jogos Windows no NixOS.

---

## 3. Autenticação Microsoft / Xbox Live

Há **dois** logins Microsoft, **a mesma conta** (a que comprou Java & Bedrock).

1. **Store (download)** — o launcher abre um webview (`xodus-cli`) em `login.live.com`. É a sessão da Microsoft Store: pede a licença do título e faz stream do pacote do CDN Xbox. Sem isto não há jogo no disco.
2. **Xbox (online)** — identidade no motor WineGDK (XGame, XUser, XSAPI). Friends, convites, servidores públicos, Realms, Marketplace. O launcher avisa no **PLAY** se esta sessão faltar (offline = só SP/LAN).

Fluxo:

1. `bedrock-on-linux`
2. **Sign in** → página de código/dispositivo Microsoft (ou webview). Usa a conta da compra PC.
3. 2FA se estiver ligada.
4. O launcher oferece o **segundo** sign-in a seguir (online). Aceita.
5. Escolhe versão (Minecraft, não Preview, salvo quereres) → **PLAY**.
6. A primeira vez descarrega o jogo (~2.5 GB) + motor GDK-Proton. Depois reutiliza `~/.local/share/bedrock-on-linux/`.

Tokens ficam na pasta de dados do launcher, injectados no prefix Wine **parado** antes de cada arranque. Nada passa por relay de terceiros.

Se o webview de login ficar em “Please wait” (WebKit no NixOS/Hyprland): fecha a janela pelo menu da conta e tenta outra vez. O projecto já mitiga AT-SPI/WebKit a crashar. Último recurso: `bedrock-on-linux doctor`.

Amigos: Friends / Realms / IP de servidor Bedrock, como no Windows. Presence Xbox é heartbeat do launcher enquanto o jogo corre.

---

## 4. Hyprland

XWayland já está ligado (`programs.hyprland.xwayland`). A GUI do launcher é **X11/XWayland**. O jogo também, por omissão.

```lua
hl.window_rule({
    match = { class = "^(bedrock-on-linux)$" },
    workspace = "5 silent",
    no_shadow = true,
})
hl.window_rule({
    match = { class = "^(Minecraft\\.Windows\\.exe)$" },
    workspace = "5 silent",
    immediate = true,
    no_blur = true,
    no_shadow = true,
})
```

Classes reais (ajusta se não pegar):

```bash
hyprctl clients | rg -A8 -i 'bedrock|minecraft|wine'
```

O wrapper Nix define `MESA_VK_WSI_PRESENT_MODE=immediate` (present async no RADV/XWayland). Sem isto o compositor empilha vsync em cima do jogo e o FPS parece 60 mesmo com o limiter do Bedrock em Unlimited. Tearing no Hyprland **só** funciona com a janela **fullscreen** + `immediate` — a regra do jogo força fullscreen.

Wayland nativo no jogo (experimental; testa se o XWayland ainda capar):

```bash
BOL_INPUT=wayland bedrock-on-linux
```

GPU AMD + Vulkan 1.3: a RX 9070 chega (DGC / DXR OK no `doctor`). **Não** ligues o Legacy compatibility renderer — isso troca D3D12 inteiro por WineD3D e piora. **Não** uses `PROTON_USE_WINED3D=1`.

Não definimos `WINEPREFIX` à mão: o launcher gere o prefix. Não uses o `wine` do sistema para “abrir o mesmo prefix”.

---

## 5. Performance (RX 9070 + Intel + WineGDK)

O `bedrock-on-linux doctor` já aponta as causas. Neste sistema (2026-09): **ntsync OK**, **Vulkan/DXR OK**, avisos = **render distance 50** + **vsync ligado em janela**.

O engasgo de chunks **não** é a GPU a falhar. No Wine 11 o sync rápido é `/dev/ntsync` (já built-in no zen 7.2). Sem ntsync, os workers do Bedrock serializam no wineserver e o mundo parece single-thread. Com ntsync, o bottleneck conhecido é outro: o Bedrock **monta o anel de chunks na main thread**, o custo cresce com o **quadrado** da distância. 50 chunks (800 blocos em `gfx_viewdistance`) deixa a GPU ociosa e o frame a esperar. Isto é o mesmo padrão dos reports AMD (RX 7600 / 9060 XT / 7800 XT) no [issue #63](https://github.com/Wyze3306/BedrockOnLinux/issues/63), depois fechado como duplicado do ntsync — no teu caso o ntsync já está bem, sobra a distância + vsync.

### No jogo (Video), por ordem

1. **VSync = Off.** Unlimited com vsync *on* **não** desbloqueia FPS. No prefix: `gfx_vsync:1` e `gfx_max_framerate:0` — exactamente este combo. Liga **Fullscreen** no Bedrock também (`gfx_fullscreen`).
2. **Render distance 16–24.** 32 já começa a doer na main thread; 50 é o aviso do doctor. Simulation distance baixa (4–8) se o mundo “engasgar” ao andar.
3. **Max FPS** = cap no refresh do DP-3 (**240 ou 280**), **não** Unlimited. Unlimited no Wine piora hitch de chunks (o autor do BOL sugere isto). O compositor deixa de ter fila dupla.
4. **Anti-aliasing / MSAA = Off** (no ficheiro: `gfx_msaa:0`). MSAA 2+ no vkd3d é caro e stuttery.
5. **Visuals:** Classic ou Fancy. **Vibrant Visuals** e RTX/BetterRTX no WineGDK em RDNA4 ainda são piores que no Windows ([#153](https://github.com/Wyze3306/BedrockOnLinux/issues/153)). Upscaling (`gfx_upscaling`) podes deixar.
6. Primeira hora num bioma novo: hitch de **shader compile**. Depois o cache do vkd3d fica em `~/.local/share/bedrock-on-linux/` — não apagues isso.

Ficheiro (jogo **fechado**):

`~/.local/share/bedrock-on-linux/compatdata/pfx/drive_c/users/steamuser/AppData/Roaming/Minecraft Bedrock/Users/<id>/games/com.mojang/minecraftpe/options.txt`

### Se ainda parecer 60 fps

- Confirma que a janela do **jogo** (não o launcher) está fullscreen no **DP-3 @ 280**, não no HDMI 4K.
- `hyprctl clients` → `fullscreen: 1` e class `Minecraft.Windows.exe`.
- HUD: no launcher, env custom `MANGOHUD=1` (ou `DXVK_HUD=fps` — o render é D3D12, MangoHud é mais fiável).
- Teste avulso: `MESA_VK_WSI_PRESENT_MODE=mailbox` (sem tearing, ainda uncapped). Se mailbox voltar a 60, o tecto é o compositor, não o jogo.
- `BOL_INPUT=wayland` só se o XWayland continuar a capar depois do fullscreen.
- Não spoofes GPU Intel (`DXVK_CONFIG=dxgi.customVendorId=…`) neste hardware — isso era workaround de gente em vkd3d antigo / WineD3D.

Controller: o doctor pede o user no grupo `input` se usares comando.

---

## Primeiro arranque

```bash
bedrock-on-linux
```

1. Sign in (Store) com a conta Microsoft da compra.
2. Sign in (Xbox / online) — a mesma conta.
3. PLAY e espera o download.
4. Se falhar: `bedrock-on-linux doctor` e `bedrock-on-linux repair` (reconstroi o prefix, **não** apaga mundos).

Logs: **Settings** no launcher, ou `~/.local/share/bedrock-on-linux/logs/`.

---

## Referências

- [BedrockOnLinux](https://github.com/Wyze3306/BedrockOnLinux) (Nix: `nix run github:Wyze3306/BedrockOnLinux`)
- [Xodus](https://github.com/xodus-gaming/xodus) — download da Store com a tua licença
