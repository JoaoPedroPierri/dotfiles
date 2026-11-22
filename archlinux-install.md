Arch Linux Install - Eu uso esse guia para meu próprio uso, não me responsabilizo por problemas.
Setup atual: Hyprland (Wayland), GPU AMD, teclado português (Portugal), GRUB (UEFI ou BIOS), ext4 e zram.
O setup antigo (i3 + X11) está em `legacy-i3/`.
---
Instalação automática (recomendado)
1. Teclado e internet (no live ISO)
```
loadkeys pt-latin1
```
Wi-Fi (se não tiveres cabo; o script também pergunta se faltar internet):
```
iwctl
device list
station wlan0 connect <nomedarede>
```
2. Obter e correr o instalador
```
pacman -Sy git
git clone https://github.com/JoaoPedroPierri/dotfiles
cd dotfiles/install
bash arch-install.sh
```
O `arch-install.sh` faz tudo sozinho depois de umas perguntas iniciais (hostname, utilizador, fuso, locale, kernel e disco):
deteta UEFI/BIOS e parte o disco (apaga o disco todo, pede confirmação);
escolhe os espelhos mais rápidos (`reflector`) e descarrega em paralelo;
instala base + kernel à escolha (`linux`, `linux-zen` ou `linux-lts`) + microcode Intel/AMD;
instala Mesa + Vulkan RADV (AMD) e o Hyprland com Waybar, Wofi, Dunst, Kitty, SDDM e PipeWire;
configura locale, teclado `pt-latin1`, hostname, utilizador, sudo (grupo `wheel`), zram, GRUB e serviços.
No fim pede para reiniciar. Remove o pendrive.
3. Depois do primeiro arranque
Faz login no SDDM com a sessão Hyprland. Abre o terminal (`SUPER + Enter`) e corre:
```
sudo nmtui                        # Wi-Fi, se necessário
git clone https://github.com/JoaoPedroPierri/dotfiles ~/.joao-repo/dotfiles
~/.joao-repo/dotfiles/hyprland-install
```
O `hyprland-install` instala os restantes programas (pacman + AUR), copia as configs com backup (`.bak-<data>`), gera as cores do pywal e define o wallpaper.
---
Instalação manual (resumo dos passos)
```
loadkeys pt-latin1
cfdisk /dev/sdX                                   # EFI 1G + root
mkfs.fat -F32 /dev/sdX1 && mkfs.ext4 /dev/sdX2
mount /dev/sdX2 /mnt && mount --mkdir /dev/sdX1 /mnt/boot

reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base linux linux-firmware amd-ucode base-devel sudo neovim git zsh \
  networkmanager grub efibootmgr zram-generator mesa vulkan-radeon hyprland sddm kitty waybar wofi
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```
Dentro do chroot (o essencial):
```
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime && hwclock --systohc
sed -i 's/^#pt_PT.UTF-8 UTF-8/pt_PT.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
echo LANG=pt_PT.UTF-8 > /etc/locale.conf
echo KEYMAP=pt-latin1 > /etc/vconsole.conf
echo meuhost > /etc/hostname
passwd
useradd -m -G wheel -s /bin/zsh meuuser && passwd meuuser
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel && chmod 440 /etc/sudoers.d/10-wheel
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux --recheck
grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager sddm
```
---
Notas
Hyprland 0.55+ usa configuração em Lua (`~/.config/hypr/hyprland.lua`). O formato antigo `hyprland.conf` está descontinuado. Se o teu Hyprland for mais antigo que a 0.55, usa o Hyprland da versão do teu sistema ou atualiza (`sudo pacman -Syu`). O `hypridle.conf` e o `hyprlock.conf` mantêm o formato antigo.
Se o teclado ficar diferente já no Hyprland, confirma em `~/.config/hypr/hyprland.lua` a linha `kb_layout = "pt"`.
Se usares teclado brasileiro, troca `pt-latin1` → `br-abnt2` e `kb_layout = "pt"` → `kb_layout = "br"`, e o locale para `pt_BR`.
Wine/jogos: `~/.joao-repo/dotfiles/gpu.sh`.
---
Comandos e atalhos para utilizar
Estes são os comandos e atalhos principais configurados para controlar o ambiente no Hyprland:
Atalho	Ação
`SUPER + Enter`	terminal
`SUPER + D`	lançador
`SUPER + Q`	fechar janela
`SUPER + E`	ficheiros
`SUPER + L`	bloquear
`SUPER + 1..5`	mudar de área de trabalho
`Print`	captura de ecrã
> **Nota:** O `SUPER + M` sai do Hyprland.
FINALIZADO
