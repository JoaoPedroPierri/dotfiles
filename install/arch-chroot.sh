#!/usr/bin/env bash

# Script archlinux chroot (versão atualizada)
# Original: João Pedro Pierri (@joaoppierri)
# Chamado automaticamente pelo arch-install.sh (não é preciso correr à mão).

set -euo pipefail
source /root/install.env

msg(){ printf '\n\e[1;36m[!] %s\e[0m\n' "$*"; }

timezone_config(){
  ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  hwclock --systohc
}

language_system(){
  sed -i -e 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' \
         -e "s/^#\(${LOCALE}\.UTF-8 UTF-8\)/\1/" /etc/locale.gen
  locale-gen
  echo "LANG=${LOCALE}.UTF-8" > /etc/locale.conf
  echo "KEYMAP=${KEYMAP}"     > /etc/vconsole.conf
}

hostname_config(){
  echo "$HOST_NAME" > /etc/hostname
  cat > /etc/hosts <<EOF
127.0.0.1  localhost
::1        localhost
127.0.1.1  ${HOST_NAME}.localdomain ${HOST_NAME}
EOF
}

pacman_config(){
  sed -i -e 's/^#Color/Color/' \
         -e 's/^#VerbosePkgLists/VerbosePkgLists/' \
         -e 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
  grep -q '^ILoveCandy' /etc/pacman.conf || sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
  # multilib (Steam, Wine, etc.)
  sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  pacman -Sy --noconfirm
}

zram_config(){
  cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF
}

gpu_amd_config(){
  # libs 32 bits (Steam/Wine) - multilib já ativado em pacman_config
  pacman -S --noconfirm --needed lib32-mesa lib32-vulkan-radeon
}

keyboard_x11_config(){
  # layout PT para o SDDM/XWayland
  mkdir -p /etc/X11/xorg.conf.d
  cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "pt"
EndSection
EOF
}

hyprland_config(){
  # Config mínima (Lua, Hyprland >= 0.55). O hyprland-install substitui-a
  # pela config completa deste repositório.
  local cfg="/home/$USERNAME/.config/hypr"
  mkdir -p "$cfg"
  cat > "$cfg/hyprland.lua" <<'LUAEOF'
-- Config inicial Hyprland (teclado PT, GPU AMD)
local mod = "SUPER"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("XCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("dunst")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

hl.config({
  general = { gaps_in = 4, gaps_out = 8, border_size = 2, layout = "dwindle" },
  input = { kb_layout = "pt", follow_mouse = 1 },
  misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
})

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
LUAEOF
  chown -R "$USERNAME:$(id -gn "$USERNAME")" "/home/$USERNAME/.config"
}

initramfs_rebuild(){
  mkinitcpio -P   # aplica o KEYMAP do vconsole.conf
}

users_config(){
  msg "Palavra-passe do root"
  until passwd root; do :; done
  useradd -m -G wheel -s /bin/zsh "$USERNAME"
  msg "Palavra-passe de $USERNAME"
  until passwd "$USERNAME"; do :; done
  echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
  chmod 440 /etc/sudoers.d/10-wheel
}

grub_install(){
  if [[ $UEFI == 1 ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux --recheck
    # entrada de fallback para firmwares problemáticos
    grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck
  else
    grub-install --target=i386-pc --recheck "$DISK"
  fi
  grub-mkconfig -o /boot/grub/grub.cfg
}

services_enable(){
  systemctl enable NetworkManager fstrim.timer systemd-timesyncd sddm
}

timezone_config
language_system
hostname_config
pacman_config
zram_config
gpu_amd_config
keyboard_x11_config
initramfs_rebuild
users_config
hyprland_config
grub_install
services_enable
