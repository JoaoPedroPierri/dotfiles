# O login gráfico é feito pelo SDDM (sessão Hyprland), não por startx.
# Se preferires arrancar o Hyprland a partir do tty1 sem display manager:
#   1) sudo systemctl disable sddm
#   2) descomenta as linhas abaixo
#
# if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
#   exec Hyprland
# fi
