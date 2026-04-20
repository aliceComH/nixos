#!/usr/bin/env bash
set -u

# Lança Vesktop (nativo via nixpkgs).
vesktop &

sleep 0.2

# Lança Steam.
steam &

sleep 0.2

# Lança Spotify (Flatpak).
flatpak run com.spotify.Client &

wait
