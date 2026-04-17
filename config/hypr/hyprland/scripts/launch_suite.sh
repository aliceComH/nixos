#!/bin/bash
# Lança o Discord
flatpak run dev.vencord.Vesktop & 

sleep 0.2

# Lança a Steam
steam & 

sleep 0.2

# Lança o Spotify
flatpak run com.spotify.Client &
