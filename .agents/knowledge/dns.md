<!--
Template para novos knowledge docs. Copie este arquivo para
.agents/knowledge/<nome-do-subsistema>.md e preencha as seções.
Não delete este comentário nos docs gerados a partir daqui.
-->

# DNS local (Unbound + bloqueio de anúncios)

## O que é

Unbound em `127.0.0.1:53` como resolvedor desta máquina: cache, validação DNSSEC,
encaminhamento por DNS-over-TLS (Quad9 e Cloudflare) e bloqueio de anúncios,
trackers e malware por `local-zone ... redirect` + `local-data` A `0.0.0.0` / AAAA `::`
(antes era `always_nxdomain`; trocado para evitar sites com layout/JS quebrado por NXDOMAIN).

## Por que existe

Privacidade (DoT), latência (cache local com serve-expired) e bloqueio no nível
do DNS, que vale para todos os apps sem extensão de navegador. Escuta só em
localhost: NÃO atende outros aparelhos da rede.

## Arquivos envolvidos

- `modules/nixos/local-dns.nix` — serviço, tuning de cache/threads, forwarders, socket do `unbound-control`, timer semanal `unbound-blocklist-update`, regra de sudo do killswitch.
- `config/hypr/hyprland/scripts/update-blocklist.sh` — baixa as listas (HaGeZi Pro++, HaGeZi TIF medium, nativas winoffice/tiktok, StevenBlack), deduplica, valida com `unbound-checkconf` e instala.
- `config/hypr/hyprland/scripts/adblock-killswitch.sh` — liga/desliga o bloqueio copiando o master para o arquivo ativo.
- `config/hypr/hyprland/scripts/dns-killswitch.sh` — desliga o módulo inteiro (comenta o import e faz rebuild).
- `config/unbound/allowlist.txt` — domínios liberados (viram `always_transparent`).
- `/var/lib/unbound/adblock_master.conf` (lista completa) e `/var/lib/unbound/adblock.conf` (a que o unbound inclui; vazia = bloqueio desligado). Fora do git.

## Depende de / Relacionado a

- Sem links para outros docs por enquanto.

## Pontos de atenção

- As listas ficam em `/var/lib/unbound` porque o `ProtectSystem=strict` do serviço só deixa o stateDir gravável.
- `systemctl reload unbound` (SIGHUP) relê a lista mas ZERA o cache; as primeiras consultas depois de um update são cache miss.
- ~540 mil zonas custam ~260 MiB de RAM e alguns segundos de carga. A TIF completa (1,4 milhão) foi evitada de propósito; a `tif.medium` é o meio-termo.
- `serve-expired-client-timeout = 0` é o que faz o expirado ser servido na hora. O padrão do unbound 1.26 é 1800 ms (espera o upstream antes de servir o expirado).
- A cauda dos cache miss (100–500 ms) é o upstream resolvendo + handshake TLS; não é ajustável daqui sem abrir mão do DoT.
- Site quebrou? Testar com o killswitch em `off`; se resolver, pôr o domínio em `allowlist.txt` e rodar o update.
- O script só aceita linhas com cara de domínio (regex), então uma lista comprometida não injeta diretivas no config.
- `networking.dhcpcd.enable = false` e `networkmanager.dns = "none"` fixam o resolv.conf em 127.0.0.1; se o unbound cair, a máquina fica sem DNS.
