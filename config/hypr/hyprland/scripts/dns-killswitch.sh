#!/usr/bin/env bash
# dns-killswitch.sh - Ativa ou desativa o módulo de DNS Local no NixOS
# Utilidade para debug da rede

CONFIG_FILE="/etc/nixos/hosts/alice-nixos/configuration.nix"

# Verifica se a linha está ativa (sem comentário)
if grep -q "^[[:space:]]*../../modules/nixos/local-dns.nix" "$CONFIG_FILE"; then
    echo "[ Killswitch ] Desativando DNS Local (Unbound)..."
    sudo sed -i 's|^[[:space:]]*../../modules/nixos/local-dns.nix|    # ../../modules/nixos/local-dns.nix|' "$CONFIG_FILE"
    echo "[ NixOS ] Reconstruindo o sistema..."
    sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos
    echo "[ Rede ] Reiniciando NetworkManager para restaurar o DHCP..."
    sudo systemctl restart NetworkManager
    echo "[ Sucesso ] DNS Local desativado! O DHCP do roteador assumiu."

# Verifica se a linha está comentada
elif grep -q "^[[:space:]]*#[[:space:]]*../../modules/nixos/local-dns.nix" "$CONFIG_FILE"; then
    echo "[ Killswitch ] Ativando DNS Local (Unbound)..."
    sudo sed -i 's|^[[:space:]]*#[[:space:]]*../../modules/nixos/local-dns.nix|    ../../modules/nixos/local-dns.nix|' "$CONFIG_FILE"
    echo "[ NixOS ] Reconstruindo o sistema..."
    sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos
    echo "[ Sucesso ] DNS Local ativado!"

else
    echo "[ Erro ] Não foi possível encontrar a linha do local-dns.nix no $CONFIG_FILE"
fi
