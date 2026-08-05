# screen-sharing (portais/PipeWire)

## O que é

O caminho de screen share/webcam no Wayland+Hyprland: apps (Vesktop, OBS,
navegadores) pedem captura via `xdg-desktop-portal`/`xdg-desktop-portal-hyprland`,
que entregam o stream via PipeWire.

## Por que existe (o bug real por trás de "às vezes não funciona")

`xdg-desktop-portal` e `xdg-desktop-portal-hyprland` ficam rodando por dias
sem reiniciar sozinhos, mas seguram uma conexão de socket aberta com o
`pipewire.service`. Toda vez que o PipeWire reinicia — `nixos-rebuild
switch` que toque a config de áudio, `systemctl --user restart pipewire`
manual, ou um crash — essa conexão morre e **não se reconecta sozinha**.

Evidência (`journalctl --user -u xdg-desktop-portal`):

```
Caught PipeWire error: connection error
Failed to close session implementation: O tempo limite foi alcançado
```

Esse padrão se repete desde pelo menos 28/07, sempre em janelas de tempo
que coincidem com restart do `pipewire.service` no journal. Resultado:
screen share falha silenciosamente (sem popup, sem erro visível no app) até
um reboot completo — que por acaso reinicia tudo junto e mascara a causa
real.

## Arquivos envolvidos

- `modules/nixos/hyprland-system.nix` — declara `xdg.portal` (backends
  `hyprland`+`gtk`) e, agora, o fix: `systemd.user.services."xdg-desktop-portal"`
  e `."xdg-desktop-portal-hyprland"` com `unitConfig.PartOf = [
  "pipewire.service" "wireplumber.service" ]`. `PartOf` propaga stop/restart
  do alvo para quem declara — reiniciar pipewire/wireplumber agora força os
  portais a reiniciar junto e reconectar no socket novo.
- `config/xdg-desktop-portal/hyprland-portals.conf` — preferências de backend
  por interface (`ScreenCast`/`Screenshot` = hyprland, `FileChooser` = gtk).
- `modules/nixos/voice-normalizer.nix` / `modules/nixos/services.nix` — toda
  vez que esses arquivos mudam e você roda `nixos-rebuild switch`, o
  `pipewire.service` reinicia e, sem o fix acima, quebrava o screen share.

## Depende de / Relacionado a

- **Forte:** PipeWire/WirePlumber (`modules/nixos/services.nix`) — o portal
  não existe sem eles; o bug em si é sobre a relação de ciclo de vida entre
  os dois.

## Pontos de atenção

- Alívio imediato sem rebuild, se o screen share já estiver quebrado agora:
  `systemctl --user restart xdg-desktop-portal xdg-desktop-portal-hyprland`
  (não precisa reiniciar a máquina).
- Descartado como causa: `bitdepth 10` nos monitores (causa comum reportada
  no GitHub do `xdg-desktop-portal-hyprland` para o Vesktop) — não está
  configurado em `general.lua` (`hl.monitor` sem `bitdepth`), então não é
  fator aqui.
- Se o problema voltar mesmo com o fix aplicado, o próximo suspeito é
  `xdg-desktop-portal-hyprland` crashando sozinho (SEGV) em vez de perder a
  conexão — nesse caso o log mostra `core-dump`/`SEGV` em vez de
  `connection error`, e o fix é outro (versão do pacote, `qt6-wayland`).
