#!/usr/bin/env bash

# Script archlinux install (versão atualizada)
# Original: João Pedro Pierri (@joaoppierri)
# Corre no live ISO, como root:  bash arch-install.sh
# Requer arch-chroot.sh na mesma pasta.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
msg(){ printf '\n\e[1;36m[!] %s\e[0m\n' "$*"; }
ask(){ local v; read -rp "$2 [$3]: " v; printf -v "$1" '%s' "${v:-$3}"; }

[[ $EUID -eq 0 ]] || { echo "Execute como root."; exit 1; }
[[ -f $SCRIPT_DIR/arch-chroot.sh ]] || { echo "arch-chroot.sh tem de estar na mesma pasta."; exit 1; }

# UEFI ou BIOS (deteção automática)
[[ -d /sys/firmware/efi ]] && UEFI=1 || UEFI=0

check_network(){
  ping -c1 -W3 archlinux.org &>/dev/null && return 0
  msg "Sem internet. A ligar por Wi-Fi (iwd)..."
  iwctl device list
  local dev ssid
  read -rp "Dispositivo Wi-Fi (ex: wlan0): " dev
  iwctl station "$dev" scan; sleep 3
  iwctl station "$dev" get-networks
  read -rp "Nome da rede: " ssid
  iwctl station "$dev" connect "$ssid"      # pede a palavra-passe
  sleep 5
  ping -c1 -W5 archlinux.org &>/dev/null || { echo "Continua sem ligação."; exit 1; }
}

questions(){
  msg "Configuração (ENTER aceita o valor por omissão)"
  ask HOST_NAME "Hostname" "archlinux"
  ask USERNAME  "Utilizador (minúsculas, sem espaços)" "user"
  ask TIMEZONE  "Fuso horário" "Europe/Lisbon"
  ask LOCALE    "Locale (pt_PT, pt_BR, en_US...)" "pt_PT"
  KEYMAP=pt-latin1   # teclado português (Portugal)
  printf '\nKernel:\n [1] linux (padrão, mais compatível)\n [2] linux-zen (desempenho)\n [3] linux-lts (estabilidade)\n'
  local k; ask k "Escolha" "1"
  case $k in 2) KERNEL=linux-zen;; 3) KERNEL=linux-lts;; *) KERNEL=linux;; esac
}

choose_disk(){
  msg "Discos disponíveis"
  lsblk -dpno NAME,SIZE,MODEL -e 7,11 | grep -v zram || true
  read -rp "Disco de destino (ex: /dev/sda, /dev/nvme0n1): " DISK
  [[ -b $DISK ]] || { echo "Disco inválido."; exit 1; }
  echo "TODOS OS DADOS EM $DISK SERÃO APAGADOS!"
  read -rp "Escreva o caminho do disco para confirmar: " c
  [[ $c == "$DISK" ]] || { echo "Cancelado."; exit 1; }
  # nvme0n1 / mmcblk0 usam sufixo "p" nas partições
  [[ $DISK == *[0-9] ]] && P="${DISK}p" || P="$DISK"
}

partition_disk(){
  msg "A particionar $DISK ($([[ $UEFI == 1 ]] && echo UEFI || echo BIOS))"
  swapoff -a || true
  umount -R /mnt 2>/dev/null || true
  wipefs -af "$DISK"
  sgdisk -Z "$DISK"
  if [[ $UEFI == 1 ]]; then
    sgdisk -n1:0:+1G -t1:ef00 -c1:ESP -n2:0:0 -t2:8300 -c2:root "$DISK"
  else
    sgdisk -n1:0:+1M -t1:ef02 -c1:BIOSBOOT -n2:0:0 -t2:8300 -c2:root "$DISK"
  fi
  partprobe "$DISK"; udevadm settle
}

format_mount(){
  msg "A formatar e montar"
  mkfs.ext4 -F -q "${P}2"
  mount "${P}2" /mnt
  if [[ $UEFI == 1 ]]; then
    mkfs.fat -F32 "${P}1"
    mount --mkdir "${P}1" /mnt/boot
  fi
}

fast_mirrors(){
  msg "A otimizar downloads e espelhos"
  timedatectl set-ntp true
  sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
  systemctl stop reflector.service 2>/dev/null || true
  reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist \
    || msg "reflector falhou, a manter os espelhos atuais"
}

install_base(){
  msg "A instalar o sistema base"
  local ucode=""
  case "$(grep -m1 vendor_id /proc/cpuinfo)" in
    *GenuineIntel*) ucode=intel-ucode;;
    *AuthenticAMD*) ucode=amd-ucode;;
  esac
  local pkgs=(base "$KERNEL" "${KERNEL}-headers" linux-firmware base-devel sudo
              neovim wget git zsh networkmanager grub zram-generator
              # GPU AMD (Mesa + Vulkan RADV)
              mesa vulkan-radeon
              # Hyprland + essenciais Wayland
              hyprland hyprlock hypridle swaybg hyprpolkitagent
              xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
              kitty wofi waybar dunst thunar sddm
              qt5-wayland qt6-wayland polkit
              grim slurp wl-clipboard brightnessctl network-manager-applet
              pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol
              noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd)
  [[ -n $ucode ]] && pkgs+=("$ucode")
  [[ $UEFI == 1 ]] && pkgs+=(efibootmgr)
  pacstrap -K /mnt "${pkgs[@]}"
  genfstab -U /mnt >> /mnt/etc/fstab
}

run_chroot(){
  msg "A configurar o sistema (chroot)"
  {
    printf 'DISK=%q\nUEFI=%q\nHOST_NAME=%q\nUSERNAME=%q\n' "$DISK" "$UEFI" "$HOST_NAME" "$USERNAME"
    printf 'TIMEZONE=%q\nLOCALE=%q\nKEYMAP=%q\n' "$TIMEZONE" "$LOCALE" "$KEYMAP"
  } > /mnt/root/install.env
  install -m755 "$SCRIPT_DIR/arch-chroot.sh" /mnt/root/arch-chroot.sh
  arch-chroot /mnt /root/arch-chroot.sh
  rm -f /mnt/root/arch-chroot.sh /mnt/root/install.env
}

finish(){
  umount -R /mnt
  msg "Instalação concluída! Remova o pendrive e reinicie."
  read -rp "Reiniciar agora? [S/n]: " r
  [[ ${r,,} == n ]] || reboot
}

check_network
questions
choose_disk
partition_disk
format_mount
fast_mirrors
install_base
run_chroot
finish
