# Tuning de stack de rede: BBR + fila CAKE, buffers, Fast Open, backlog.
# O perfil TuneD continua a ser o throughput-performance (cpu-performance.nix) —
# esse perfil só ajusta net.core.somaxconn, por isso estes sysctls não conflitam
# de forma problemática.
{ pkgs, ... }:
let
  eeeOff = pkgs.writeShellScript "ethernet-eee-off" ''
    set -euo pipefail
    for p in /sys/class/net/*; do
      name="''${p##*/}"
      # ignora lo, br-, docker, virbr, wl*, etc.
      case "$name" in
        lo | wl* | br* | veth* | virbr* | docker* | waydroid*) continue ;;
      esac
      if [ -d "$p/device" ]; then
        ${pkgs.ethtool}/bin/ethtool --set-eee "$name" off 2>/dev/null || true
      fi
    done
  '';
in
{
  boot.kernelModules = [
    "tcp_bbr"
    "sch_cake"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_low_latency" = 1;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.core.netdev_max_backlog" = 5000;
  };

  # EEE (Energy-Efficient Ethernet) pode adicionar latência ao "acordar" a ligação;
  # corre depois de existirem interfaces, antes do alvo de utilizador completo.
  systemd.services.ethernet-eee-off = {
    description = "Desativa EEE (Energy-Efficient Ethernet) em interfaces com fio";
    after = [ "sys-subsystem-net-devices.device" "network.target" ];
    before = [ "default.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${eeeOff}";
    };
  };
}
