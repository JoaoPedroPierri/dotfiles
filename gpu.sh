#!/usr/bin/env bash
# GPU AMD + Wine/jogos (Vulkan RADV). Requer o multilib ativo em /etc/pacman.conf
# (o install/arch-chroot.sh já o ativa).
set -euo pipefail

sudo pacman -S --needed --noconfirm \
  mesa lib32-mesa \
  vulkan-radeon lib32-vulkan-radeon \
  vulkan-icd-loader lib32-vulkan-icd-loader \
  vulkan-tools mesa-utils \
  wine-staging winetricks wine-mono wine-gecko \
  gamemode lib32-gamemode

echo
echo "Teste: vulkaninfo --summary | head   e   glxinfo -B | head"
