# Kernel: padrão é o zen `v7.2.2-zen1`.
#
# O `linuxPackages_zen` do nixpkgs ainda está em 7.1.10; o tag oficial
# `v7.2.2-zen1` já existe no zen-kernel (e o Arch já empacota 7.2.2.zen1),
# por isso compilamos esse src via override. `ZEN_INTERACTIVE` voltou a
# existir neste tag — o que falhou no `master` WIP (commit 2709dd5) já
# não se aplica.
#
# Fallback no boot: specialisation `mainline-72` = `linuxPackages_latest`
# (mainline 7.2.2, o que estava como padrão antes desta mudança).
#
# `lowLatencyIrqTuning`: otimizações de interrupção que replicam o que foi
# testado em `kernel-7-rt-oriented.nix` (commit 6ab4fb1a, "kernel 7 + low
# latency governor"), como parâmetros de boot — funcionam em qualquer
# kernel, mainline ou zen:
#
#   • threadirqs      → processa hard-IRQs em threads de kernel dedicadas
#                        em vez do contexto de interrupção, reduzindo a
#                        latência que uma IRQ longa impõe a outras tarefas
#                        (ajuda tanto em áudio/input como na NIC).
#   • nohz=on         → modo tickless: CPUs ociosas não recebem interrupções
#                        de timer periódicas, reduzindo overhead geral de IRQ.
#   • rcu_nocbs=all   → descarrega callbacks de RCU do contexto de
#                        interrupção/softirq para threads dedicadas em
#                        todas as CPUs.
#
# (As otimizações de rede — BBR, CAKE, buffers, EEE off — já vivem em
# `network-tuning.nix` e continuam sempre ativas, independente disto.)
{
  lib,
  pkgs,
  config,
  ...
}:

let
  linuxPackages_zen72 = pkgs.linuxPackagesFor (
    pkgs.linuxKernel.kernels.linux_zen.override {
      argsOverride = rec {
        version = "7.2.2";
        modDirVersion = "${version}-zen1";
        src = pkgs.fetchFromGitHub {
          owner = "zen-kernel";
          repo = "zen-kernel";
          rev = "v${version}-zen1";
          hash = "sha256-KDPxfU+md/ii13KfwSz6IocPFma8Xe0T3xXlsIEj0GM=";
        };
      };
    }
  );
in
{
  options.local.kernelLowLatencyIrqTuning.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Ativa threadirqs/nohz=on/rcu_nocbs=all no kernel. Desativado
      automaticamente na specialisation de rollback `no-irq-tuning`.
    '';
  };

  config = {
    boot.kernelPackages = lib.mkDefault linuxPackages_zen72;

    boot.kernelParams = lib.mkIf config.local.kernelLowLatencyIrqTuning.enable [
      "threadirqs"
      "nohz=on"
      "rcu_nocbs=all"
    ];

    # Rollback 1: mesmo zen 7.2.2, mas sem os parâmetros de baixa latência.
    specialisation.no-irq-tuning.configuration = {
      local.kernelLowLatencyIrqTuning.enable = lib.mkForce false;
    };

    # Rollback 2: mainline 7.2.2 (o que tínhamos como padrão), pré-compilado
    # pelo nixpkgs, se o zen 7.2.2 se comportar pior (drivers, HDMI FRL, etc.).
    specialisation.mainline-72.configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    };
  };
}
