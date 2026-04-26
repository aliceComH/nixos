{ lib, pkgs, ... }:

let
  mkKernelOverride = lib.mkOverride 90;
  rtOrientedKernel = pkgs.linux_7_0.override {
    argsOverride = {
      structuredExtraConfig = with lib.kernel; {
        # Aggressive low-latency profile (RT-oriented, not PREEMPT_RT patchset).
        PREEMPT = mkKernelOverride yes;
        PREEMPT_LAZY = mkKernelOverride no;

        HZ = freeform "1000";
        HZ_1000 = yes;

        # Helps keep interrupt handling preemptible when supported.
        IRQ_FORCED_THREADING = yes;
      };
    };
  };
in
{
  boot.kernelPackages = lib.mkDefault (pkgs.linuxPackagesFor rtOrientedKernel);

  boot.kernelParams = [
    "threadirqs"
    "preempt=full"
    "nohz=on"
    "rcu_nocbs=all"
    # Extra aggressive profile: lowers overhead at the expense of security hardening.
    "mitigations=off"
  ];

  # Keeps a known-good fallback entry available in the boot menu.
  specialisation.zen-fallback.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
  };
}
