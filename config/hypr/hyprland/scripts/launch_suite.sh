#!/usr/bin/env bash
set -u

# Lança Vesktop (Flatpak, Flathub).
flatpak run dev.vencord.Vesktop &

sleep 0.2

# Lança Steam.
steam &

sleep 0.2

# Lança Spotify (Flatpak).
flatpak run com.spotify.Client &

wait
