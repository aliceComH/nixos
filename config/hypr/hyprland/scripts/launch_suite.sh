#!/usr/bin/env bash
set -u

# Lança Vesktop (Flatpak, Flathub).
vesktop --enable-features=WebRTCPipeWireCapturer &

sleep 0.2

# Lança Steam.
steam &

sleep 0.2

# Lança Spotify (Flatpak).
flatpak run com.spotify.Client &

wait
