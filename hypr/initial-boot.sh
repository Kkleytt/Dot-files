# Настройки стилей системы
kvantum_theme="catppuccin-mocha-blue"
color_scheme="prefer-dark"
gtk_theme="Flat-Remix-GTK-Blue-Dark"
icon_theme="Flat-Remix-Blue-Dark"
cursor_theme="Bibata-Modern-Ice"
status_file="$HOME/.config/hypr/.initial_boot_done"

if [ ! -f "$HOME/.config/hypr/.initial_startup_done" ]; then
    # Применение стилей и тем для GTK (темы, цвета, курсоры и тд)
    gsettings set org.gnome.desktop.interface color-scheme $color_scheme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme $icon_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &

    # Применение стилей и тем для NixOS (темы, цвета, курсоры и тд)
    if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
        gsettings set org.gnome.desktop.interface color-scheme "'$color_scheme'" > /dev/null 2>&1 &
        dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" > /dev/null 2>&1 &
        dconf write /org/gnome/desktop/interface/icon-theme "'$icon_theme'" > /dev/null 2>&1 &
        dconf write /org/gnome/desktop/interface/cursor-theme "'$cursor_theme'" > /dev/null 2>&1 &
        dconf write /org/gnome/desktop/interface/cursor-size "24" > /dev/null 2>&1 &
    fi
        
    # Установка стилей Kvantum
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &

    # Установка флага о завершении инициализации системы
    touch "$status_file"
    exit
fi