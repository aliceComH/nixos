# Minecraft Java em LAN (Open to LAN) — portas liberadas SÓ para a rede local.
#   UDP 4445  : anúncio multicast do "Open to LAN" (224.0.2.60), para ver mundos
#               de quem está na rede.
#   TCP 25565 : porta fixa para hospedar (digitar 25565 no campo de porta do Open to LAN).
# Restrito à sub-rede da casa por regra de origem (-s), não por allowed*Ports, que
# abririam para qualquer origem. Ver .agents/knowledge/minecraft-java.md.
{ ... }:

let
  lan = "192.168.0.0/24";
  rules = [
    "-p udp --dport 4445 -s ${lan}"
    "-p tcp --dport 25565 -s ${lan}"
  ];
in
{
  networking.firewall.extraCommands = builtins.concatStringsSep "\n"
    (map (r: "iptables -A nixos-fw ${r} -j nixos-fw-accept") rules);

  networking.firewall.extraStopCommands = builtins.concatStringsSep "\n"
    (map (r: "iptables -D nixos-fw ${r} -j nixos-fw-accept 2>/dev/null || true") rules);
}
