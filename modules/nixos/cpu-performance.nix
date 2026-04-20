# Máxima performance de CPU — pensado para o Intel Core i5-14600K sem
# restrições de energia nem de temperatura.
#
# O que isto faz:
#   • governor = performance  →  intel_pstate nunca escala para baixo
#   • EPP = performance        →  dica de hardware para frequência máxima
#   • min_perf_pct = 100       →  proibido reduzir a frequência de base
#   • turbo boost habilitado   →  deixa o CPU subir até o boost máximo
#   • C-states limitados a C1  →  elimina latência de wakeup (mais calor
#                                  em idle; aceitável com um bom cooler)
#   • mitigations=off          →  desativa Spectre/Meltdown/etc.
#                                  ATENÇÃO: reduz isolamento entre processos.
#                                  Seguro em máquina de uso pessoal que não
#                                  executa código não-confiável em paralelo.
{ ... }:

{
  # Governor via NixOS (aplicado antes do tuned subir, sem conflito porque
  # o perfil throughput-performance define o mesmo valor).
  powerManagement.cpuFreqGovernor = "performance";

  # Tuned: fixa o perfil throughput-performance em qualquer situação.
  # A regra vazia em recommend é sempre verdadeira e é avaliada primeiro.
  services.tuned.recommend = {
    throughput-performance = { };
  };

  # O tuned lê /etc/tuned/active_profile no arranque para saber qual perfil
  # carregar — se este ficheiro tiver "balanced" do arranque anterior, ignora
  # o recommend.conf. Sobrescrevemos o ficheiro para garantir consistência.
  environment.etc."tuned/active_profile".text = "throughput-performance\n";

  boot.kernelParams = [
    # Limita C-states a C1 — CPU acorda instantaneamente do idle.
    "processor.max_cstate=1"
    "intel_idle.max_cstate=1"

    # Desativa mitigações de vulnerabilidades de CPU (Spectre, Meltdown,
    # MDS, etc.) para recuperar os ciclos que elas consomem.
    "mitigations=off"
  ];
}
