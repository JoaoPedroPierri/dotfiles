# Setup antigo: i3 + polybar + rofi (X11)

Guardado para referência. O setup atual é Hyprland (ver README principal).
O `i3-install` já não é mantido: usa pacotes X11 (maim, xclip, redshift, nitrogen, i3lock...).
 Voltar para o Setup Antigo (`legacy-i3`)
Caso pretendas utilizar o i3 (X11) lado a lado ou substituir o Hyprland:
Instala os pacotes base do Xorg e do i3:
```bash
   sudo pacman -S --needed xorg-server xorg-xinit i3-wm i3status i3lock dmenu feh picom rofi xclip
   ```
Copia os ficheiros de configuração de `legacy-i3/` para a tua pasta pessoal (`~/.config/` e `~/`).
Termina a sessão atual (`SUPER + M`) e seleciona i3 no menu de sessões do SDDM antes de iniciar sessão.
