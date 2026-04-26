#!/usr/bin/env bash
set -u

# Lança Discord Canary (Flatpak).
flatpak run com.discordapp.DiscordCanary &

sleep 0.2

# Lança Steam.
steam &

sleep 0.2

# Lança Spotify (Flatpak).
flatpak run com.spotify.Client &

wait
