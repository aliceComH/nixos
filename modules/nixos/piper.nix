# Piper + libratbag: rebind de botões do Logitech G502 Hero.
# ratbagd (D-Bus) + Piper (GUI).
#
# O G502 HERO devolve o perfil activo 1-based (HID++ 0x8100). O libratbag
# 0.18 guarda esse número como 0-based, então cada probe do ratbagd
# (USB unplug/plug ou restart do serviço) apontava um slot à frente e
# enable o próximo — o Piper mostrava um perfil novo default.
# Ver libratbag#1606 / #1323 / PR #1799 (Quirk=INDEX_OFFSET). O 0.18 não
# tem esse quirk; o overlay abaixo aplica o backport.
{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      libratbag = prev.libratbag.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../../patches/libratbag-g502-index-offset.patch
        ];
      });
    })
  ];

  services.ratbagd.enable = true;

  environment.systemPackages = [ pkgs.piper ];
}
