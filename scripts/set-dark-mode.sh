#!/bin/bash

# 1. Force GTK to use Dark Mode
# "prefer-dark" handles LibAdwaita/GTK4 apps
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# "Adwaita-dark" handles legacy GTK3 apps
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# 2. Define Environment Variables for Qt and Wayland
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME="gtk3"    # Force Qt to use the GTK theme
export GTK_THEME="Adwaita-dark"
export MOZ_ENABLE_WAYLAND=1           # Firefox/Thunderbird Wayland support

# 3. Inject these variables into the user session 
# This ensures apps launched via Fuzzel/Terminal inherit them
dbus-update-activation-environment --systemd \
    QT_QPA_PLATFORM \
    QT_QPA_PLATFORMTHEME \
    GTK_THEME \
    MOZ_ENABLE_WAYLAND \
    XDG_CURRENT_DESKTOP=niri
