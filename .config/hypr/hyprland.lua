-- ~/.config/hypr/hyprland.lua  (Hyprland >= 0.55, config em Lua)
-- User: JoaoPedroPierri | Telegram @joaoppierri
-- Portado da antiga config do i3 (ver legacy-i3/.config/i3/config)
-- Wiki: https://wiki.hypr.land/Configuring/Start/

local home = os.getenv("HOME")
local mod = "SUPER" -- tecla Windows

--------------------------------------------------------------------
-- PROGRAMAS
--------------------------------------------------------------------
local terminal = "kitty"
local menu = "wofi --show drun"
local browser = "google-chrome-stable"

--------------------------------------------------------------------
-- CORES (pywal, com fallback caso o cache ainda não exista)
--------------------------------------------------------------------
local function wal_color(n, fallback)
  local f = io.open(home .. "/.cache/wal/colors", "r")
  if not f then
    return fallback
  end
  local i = 0
  local found = nil
  for line in f:lines() do
    if i == n then
      found = line
      break
    end
    i = i + 1
  end
  f:close()
  if found and found:match("^#%x%x%x%x%x%x$") then
    return (found:gsub("#", ""))
  end
  return fallback
end

local accent = wal_color(2, "90a57d") -- i3wm.color2
local dim = wal_color(0, "141414")    -- i3wm.color0

--------------------------------------------------------------------
-- MONITORES
-- Por omissão: qualquer monitor, resolução preferida.
-- Exemplo (como no antigo .screenlayout):
--   hl.monitor({ output = "eDP-1", disabled = true })
--   hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
-- Descobrir nomes: hyprctl monitors
--------------------------------------------------------------------
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

--------------------------------------------------------------------
-- VARIÁVEIS DE AMBIENTE (GPU AMD + Wayland)
--------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

--------------------------------------------------------------------
-- INICIAR COM O HYPRLAND
--------------------------------------------------------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("wallpaper")                                -- swaybg + pywal
  hl.exec_cmd("waybar")                                   -- barras
  hl.exec_cmd("dunst")                                    -- notificações
  hl.exec_cmd("nm-applet --indicator")                    -- rede
  hl.exec_cmd("systemctl --user start hyprpolkitagent")   -- polkit
  hl.exec_cmd("hypridle")                                 -- bloquear/suspender
end)

--------------------------------------------------------------------
-- APARÊNCIA (gaps inner 4, borda 1px, como no i3)
--------------------------------------------------------------------
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 0,
    border_size = 1,
    layout = "dwindle",
    allow_tearing = false,
    resize_on_border = false,
    col = {
      active_border = "rgba(" .. accent .. "ff)",
      inactive_border = "rgba(" .. accent .. "55)",
    },
  },
  decoration = {
    rounding = 0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    focus_on_activate = true,
  },
})

--------------------------------------------------------------------
-- TECLADO PORTUGUÊS (Portugal)
--------------------------------------------------------------------
hl.config({
  input = {
    kb_layout = "pt",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = { natural_scroll = false },
  },
})

-- Opções menos críticas, isoladas: se uma chave mudar numa versão
-- futura, só esta linha falha e o resto da config continua a carregar.
pcall(hl.config, { input = { numlock_by_default = true } })
pcall(hl.config, { cursor = { no_warps = true } })

--------------------------------------------------------------------
-- ATALHOS
--------------------------------------------------------------------

-- Terminal / menu / fechar
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + Q", hl.dsp.window.close())

-- Bloquear (hyprlock com fortune) e sair
hl.bind(mod .. " + X", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("powermenu"))

-- Data e calendário
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("notify-send -u low \"$(date '+%d/%m/%Y     %H:%M')\" \"$(cal)\""))

-- Luz noturna (antigo redshift)
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("nightlight"))

-- Aplicações
hl.bind(mod .. " + SHIFT + Y", hl.dsp.exec_cmd("kitty -e yt -t"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("mpv --player-operation-mode=pseudo-gui"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("tidal-hifi"))
hl.bind(mod .. " + F1", hl.dsp.exec_cmd("qbittorrent"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + T", hl.dsp.exec_cmd(home .. "/.local/bin/telegram"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("libreoffice"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("code-oss"))

-- Scratchpad (workspace especial)
hl.bind(mod .. " + O", hl.dsp.window.move({ workspace = "special:scratchpad" }))
hl.bind(mod .. " + L", hl.dsp.workspace.toggle_special("scratchpad"))

-- Foco com as setas
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Mover janela
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Layout
hl.bind(mod .. " + semicolon", hl.dsp.layout("togglesplit")) -- split toggle
hl.bind(mod .. " + E", hl.dsp.layout("togglesplit"))         -- layout toggle split
hl.bind(mod .. " + W", hl.dsp.group.toggle())                -- "tabbed": grupo de janelas
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + C", hl.dsp.window.center())

-- Screenshots (grim + slurp, ver bin/shot)
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("shot -s -r")) -- guardar ecrã inteiro
hl.bind("Print", hl.dsp.exec_cmd("shot -c -r"))           -- copiar ecrã inteiro
hl.bind(mod .. " + C", hl.dsp.exec_cmd("shot -c -a"))     -- copiar área selecionada

-- Workspaces 1..10
for i = 1, 10 do
  local key = i % 10 -- 10 -> tecla 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Rato: mover/redimensionar com SUPER + botões
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Modo resize (SUPER+R) - isolado em pcall por ser a parte mais recente da API
pcall(function()
  hl.define_submap("resize", function()
    hl.bind("left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
    hl.bind("right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
    hl.bind("Return", hl.dsp.submap("default"))
    hl.bind("Escape", hl.dsp.submap("default"))
  end)
  hl.bind(mod .. " + R", hl.dsp.submap("resize"))
end)

-- Áudio, brilho e media
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

--------------------------------------------------------------------
-- REGRAS DE JANELAS (as mesmas apps/workspaces do i3)
-- Descobrir a classe de uma janela: hyprctl clients
--------------------------------------------------------------------

-- Ignorar pedidos de maximizar e corrigir drags no XWayland (config oficial)
hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- Apps com workspace fixa
hl.window_rule({ name = "ws1-browser", match = { class = "^(google-chrome|google-chrome-stable|Google-chrome)$" }, workspace = "1" })
hl.window_rule({ name = "ws2-terminal", match = { class = "^kitty$" }, workspace = "2", float = true, center = true })
hl.window_rule({ name = "ws3-telegram", match = { class = "^(org.telegram.desktop|Telegram.*|telegram.*)$" }, workspace = "3", float = true, center = true })
hl.window_rule({ name = "ws4-tidal", match = { class = "^tidal-hifi$" }, workspace = "4" })
hl.window_rule({ name = "ws5-libreoffice", match = { class = "^(libreoffice.*|soffice.*)$" }, workspace = "5", float = true, center = true })
hl.window_rule({ name = "ws6-mpv", match = { class = "^mpv$" }, workspace = "6", float = true, center = true })
hl.window_rule({ name = "ws7-qbittorrent", match = { class = "^(org.qbittorrent.qBittorrent|qBittorrent)$" }, workspace = "7", float = true })
hl.window_rule({ name = "ws8-code", match = { class = "^(code-oss|Code - OSS|code)$" }, workspace = "8", float = true, center = true })

-- Janelas que flutuam
hl.window_rule({ name = "float-viewnior", match = { class = "^(viewnior|Viewnior)$" }, float = true })
hl.window_rule({ name = "float-gucharmap", match = { class = "^(gucharmap|Gucharmap)$" }, float = true })
hl.window_rule({ name = "float-bluetooth", match = { class = "^(.blueman-manager-wrapped|blueman-manager)$" }, float = true })
hl.window_rule({ name = "float-pycharm", match = { class = "^(pycharm.*|jetbrains-pycharm.*)$" }, float = true, center = true })
hl.window_rule({ name = "float-galculator", match = { class = "^(galculator|Galculator)$" }, float = true, center = true })
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol)$" }, float = true, center = true })
hl.window_rule({ name = "float-discord", match = { class = "^(discord|vesktop)$" }, float = true, center = true })
hl.window_rule({ name = "float-lutris", match = { class = "^(net.lutris.Lutris|lutris)$" }, float = true, center = true })
hl.window_rule({ name = "float-nm-connection-editor", match = { class = "^nm-connection-editor$" }, float = true, center = true })
