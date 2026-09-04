# kenny's user-level (home-manager) config.
# System-level stuff (niri/steam/portals/AMD tuning) lives in configuration.nix.
{ config, pkgs, lib, inputs, ... }:

let
  # ---- PWAs ----
  # A PWA here is just `helium --app=<url>`. On niri (prefer-no-csd) that's
  # a frameless window -- no tab strip, no Chromium title bar, no window
  # buttons -- so a web app sits on the workspace like a native one.
  #
  # Chromium derives the Wayland app_id from the URL itself (host + path,
  # each run of non-alphanumerics -> "_", wrapped chrome-<...>-Default) and
  # *ignores* --class, so `wmClass` below has to be that exact derived
  # string. It's what the dock matches the running window against to show
  # `<name>`'s icon and group it under the pinned launcher.
  #
  # `installedId` is set when the same PWA was also "Install"ed from
  # helium's menu: that writes its own chrome-<hash>-Default.desktop which
  # launches with `--app-id=` and keeps Chromium's title bar. We overwrite
  # that file (force below -- helium owns the original) with the frameless
  # `--app=` version so both launchers behave the same.
  #
  # Add one: an entry here, a matching bind in niri/config.kdl, and a 512px
  # PNG at assets/pwa-icons/<name>.png.
  pwas = {
    basecamp = {
      name = "Basecamp";
      genericName = "Project management";
      # a logged-in helium profile redirects app.basecamp.com to its
      # account, so no account id is baked in here
      url = "https://app.basecamp.com";
      wmClass = "chrome-app.basecamp.com__-Default";
      installedId = "nbcopffeanpomgfeccnbakllkmjlknkn";
    };
    google-messages = {
      name = "Messages";
      genericName = "SMS / RCS";
      url = "https://messages.google.com/web";
      wmClass = "chrome-messages.google.com__web-Default";
      installedId = "hpfldicfbfomlpcikngkocigghgafkph";
    };
  };

  # Icon= is an absolute path to the bundled PNG rather than a theme name:
  # the launcher / dock resolve it without depending on an icon-theme cache
  # existing for ~/.local/share/icons.
  mkPwaDesktop = key: p: ''
    [Desktop Entry]
    Type=Application
    Name=${p.name}
    ${lib.optionalString (p ? genericName) "GenericName=${p.genericName}"}
    Exec=helium --app=${p.url}
    StartupWMClass=${p.wmClass}
    Icon=${./assets/pwa-icons/${key}.png}
    Terminal=false
    Categories=Network;
  '';

  # <name>.desktop (the one niri binds spawn) + the overridden
  # chrome-<installedId>-Default.desktop, all pointing at mkPwaDesktop
  pwaDesktopFiles =
    (lib.mapAttrs' (key: p:
      lib.nameValuePair "applications/${key}.desktop" {
        text = mkPwaDesktop key p;
      }) pwas)
    // (lib.mapAttrs' (key: p:
      lib.nameValuePair
        "applications/chrome-${p.installedId}-Default.desktop" {
          force = true;
          text = mkPwaDesktop key p;
        })
      (lib.filterAttrs (_: p: p.installedId != null) pwas));

  # each PWA's icon installed under every hicolor size the launcher looks in
  pwaIconFiles = lib.mapAttrs' (key: _:
    lib.nameValuePair "icons/hicolor/512x512/apps/${key}.png" {
      source = ./assets/pwa-icons/${key}.png;
    }) pwas;

  # ---- LiMusic ----
  # Third-party YouTube Music desktop client (no official one exists):
  # https://simohypers.github.io/limusic/ -- not in nixpkgs, so fetch the
  # upstream AppImage straight into the store (pinned by hash, so this is
  # reproducible -- no manual download needed on another machine). Run
  # through `appimage-run` explicitly rather than relying on the
  # `programs.appimage.binfmt` kernel registration (configuration.nix) so
  # this still works even if binfmt isn't set up yet.
  limusicAppImage = pkgs.fetchurl {
    url = "https://github.com/SimoHypers/limusic/releases/download/v0.6.9/limusic_0.6.9_amd64.AppImage";
    sha256 = "sha256-rwboptDDiR5EuHwY72vyeV0u2pavwjQNAN2iQKtFWBY=";
    executable = true;
  };

  # ---- nvim ----
  # synthwave84.nvim isn't in nixpkgs; build it straight from GitHub. It
  # brings its own lualine theme + an optional neon "glow" on some token
  # groups (configured in programs.neovim.initLua below).
  synthwave84-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "synthwave84-nvim";
    version = "0-unstable-2023-02-14";
    src = pkgs.fetchFromGitHub {
      owner = "LunarVim";
      repo = "synthwave84.nvim";
      rev = "eac1f349713e2f470d8ee857913a42135bcc1a7f";
      sha256 = "sha256-hbHxTk2R7nul1zbUVJwqwTGba8uyep8c2/+APrpjs54=";
    };
  };
in

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.username = "kenny";
  home.homeDirectory = "/home/kenny";
  # Matches the NixOS system.stateVersion -- do not change on upgrades,
  # see the comment in configuration.nix.
  home.stateVersion = "26.05";

  home.sessionVariables = {
    # Noctalia wraps Terminal=true .desktop entries in $TERMINAL.
    TERMINAL = "kitty";
  };

  home.packages = with pkgs; [
    # JetBrains Mono Nerd Font (used by kitty, Noctalia, and as the system
    # default UI font) is installed system-wide via `fonts.packages` in
    # configuration.nix, so it's not repeated here.

    # Gaming
    protonplus
    mangohud
    dolphin-emu           # GameCube / Wii emulator (synthwave user style below)

    # X11-under-niri support for Steam/Discord windows; niri >=25.08
    # auto-spawns this on demand as long as it's on PATH, no config.kdl
    # changes needed. https://github.com/niri-wm/niri/wiki/Xwayland
    xwayland-satellite

    # Communication / misc
    discord
    zoom-us
    gnome-disk-utility   # "Disks" -- partition / SMART / mount GUI
    obs-studio           # screen recording / streaming (PipeWire capture)

    # Used by niri's media-key binds in config.kdl
    playerctl

    # Shell: extra completion definitions (zsh), and fzf which zoxide's
    # `cdi` interactive picker shells out to.
    zsh-completions
    fzf
  ];
  # fastfetch: installed + configured via programs.fastfetch below (synthwave
  # theme), so it's not in home.packages.

  # ---- niri ----
  # niri doesn't have a home-manager options module in this flake graph;
  # config.kdl is plain KDL, so we just drop the file in place directly.
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  # ---- Noctalia ----
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    # nixpkgs on the nixos-26.05 channel doesn't carry a `noctalia` package
    # yet (only nixpkgs-unstable does), so pull the binary straight from
    # the noctalia flake input itself rather than relying on the module's
    # `pkgs.noctalia` default (which would silently resolve to null/no
    # package on this channel).
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      shell = {
        # noctalia 5.x calls this `font_family` (the old `font` key is ignored
        # with an "unknown setting" warning).
        font_family = "JetBrainsMono Nerd Font";
        launch_apps_as_systemd_services = true;
        # Bump global rounding a touch so panels/cards match the rounder bar.
        corner_radius_scale = 1.2;
        # Solid panels -- blur is disabled compositor-side (see the noctalia
        # layer-rule in niri/config.kdl), so "glass" would just look see-through.
        panel.transparency_mode = "solid";
      };

      # Slightly softer global shadow.
      shell.shadow.alpha = 0.5;

      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "Synthwave";
      };

      # Don't let noctalia manage other apps' themes. home-manager owns the
      # dotfiles here (kitty, niri, starship, gtk/qt), and noctalia's
      # template hooks either silently fail against the read-only Nix
      # symlinks or fight home-manager over files like ~/.config/starship.toml.
      # The palette is static ("Synthwave") anyway, so there's nothing to
      # keep live. (Trade-off: GTK/Qt apps lose the synthwave accent tint and
      # fall back to Adwaita-dark.)
      theme.templates.enable_builtin_templates = false;

      wallpaper = {
        enabled = true;
        default.path = "${./assets/synthwave-grid.png}";
      };

      # ---- Bar: "islands" layout ----
      # The bar surface itself is invisible (background_opacity = 0); each
      # widget cluster instead rides in its own solid, fully-rounded pill
      # ("island") floating over the wallpaper. Related widgets are bundled
      # into capsule_groups so a group is one indivisible lane slot -- see
      # https://docs.noctalia.dev/noctalia/bar/ ("Capsule groups").
      # reserve_space still defaults on, so windows keep clear of the strip.
      #
      # Named "default" on purpose: noctalia's runtime settings file
      # (~/.local/state/noctalia/settings.toml, written at first run) already
      # carries an empty `[bar.default]` stub. The two tables merge, so using
      # any other name would leave that stub as a second, unstyled bar
      # stacked on top of this one.
      bar.default = {
        position          = "top";
        thickness         = 36;
        background_opacity = 0.0;    # no bar plate -- just the islands
        shadow            = true;
        border_width      = 0.0;
        margin_edge       = 6;       # float the islands off the screen edge
        margin_ends       = 8;
        padding           = 8;
        widget_spacing    = 22;      # gap between the centred islands
        font_weight       = 600;

        # Default island styling. Solid near-black pill, automatic (full) pill
        # radius, no border -- clean and modern. Groups inherit this unless
        # they override a field.
        capsule           = true;    # loose widgets get their own island too
        capsule_thickness = 0.82;    # island height as a fraction of the bar
        capsule_fill      = "surface";
        capsule_opacity   = 0.9;
        capsule_padding   = 8.0;
        # capsule_radius omitted on purpose -> automatic pill radius

        # Everything rides in the `center` lane so the islands cluster in the
        # middle instead of being flung to the screen edges (noctalia has no
        # real compact/auto-width bar mode -- empty start/end is the trick).
        # The bar surface is invisible anyway, so it reads as one floating
        # centred strip. clock sits mid-list to stay roughly screen-centre.
        start  = [ ];
        center = [ "nixos_menu" "workspaces" "group:tools" "clock" "audio_visualizer" "group:status" ];
        end    = [ ];

        capsule_group = [
          { id = "tools";  members = [ "launcher" "settings" "screenshot" "caffeine" "nightlight" ];
            widget_spacing = 4; }
          { id = "status"; members = [ "tray" "notifications" "network" "bluetooth" "volume" "power_profile" "control-center" "session" ];
            widget_spacing = 4; }
        ];
      };

      # nix-snowflake button at the far-left of the bar -- opens the app
      # launcher. custom_button's `glyph` field only takes Tabler/alias
      # names, not arbitrary Nerd Font codepoints, so use `custom_image`
      # pointing at the official snowflake SVG from nixos-icons.
      widget.nixos_menu = {
        type = "custom_button";
        custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        tooltip = "Applications";
        scale = 1.5;   # per-widget content scale (0.2-2.5) -- bigger snowflake
        actions.left = "exec noctalia msg panel-toggle launcher";
      };

      # ---- Dock ----
      # Bottom pinned launchers. Migrated here from Noctalia's runtime
      # settings.toml so it's part of the flake. `nixos` is
      # applications/nixos.desktop (the nix-snowflake launcher button);
      # `basecamp` / `google-messages` are the frameless PWA entries (see
      # the `pwas` set at the top of this file).
      dock = {
        enabled = true;
        background_opacity = 0.0;
        item_spacing = 3;   # default (6) reads as too spaced-out; tight row of icons
        # Keep this in sync with whatever you pin via the Settings UI --
        # ~/.local/state/noctalia/settings.toml overrides this on every launch.
        pinned = [
          "nixos"
          "helium"
          "org.kde.dolphin"
          "discord"
          "basecamp"
          "google-messages"
          "com.obsproject.Studio"
          "steam"
          "limusic"
          "kitty"
          "org.kde.discover"
        ];
      };

      # Center island: date + time on one line, cyan to pick up the synthwave
      # secondary accent.
      widget.clock = {
        format      = "{:%a %d %b   %H:%M}";
        color       = "secondary";
        font_weight = 700;
      };

      # Icon-only status island -- drop the text labels so it stays compact.
      widget.network    = { show_label = false; };
      widget.volume     = { show_label = false; };
      widget.bluetooth  = { show_label = false; };

      # Synthwave-gradient spectrum bars.
      widget.audio_visualizer = {
        width   = 60;
        bands   = 18;
        color_1 = "primary";
        color_2 = "secondary";
      };

      # Workspace pills: pink active pill to match niri's focus ring.
      widget.workspaces = {
        style         = "regular";
        focused_color = "primary";
        occupied_color = "secondary";
      };

      # Plugins. Both built-in git sources stay enabled (Noctalia caches +
      # auto-updates them). To actually turn a plugin on, add its
      # fully-qualified id to `enabled` here -- list what's available with
      #   noctalia msg plugins list
      # A plugin's bar widget then appears as a widget type you can drop into
      # a lane / capsule_group above (type = "<author>/<plugin>:<entry>").
      plugins = {
        enabled = [
          # "noctalia/screen_recorder"
        ];
        auto_update = "all";   # all | official | none
        source = [
          { name = "official";  kind = "git"; enabled = true;
            location = "https://github.com/noctalia-dev/official-plugins"; }
          { name = "community"; kind = "git"; enabled = true;
            location = "https://github.com/noctalia-dev/community-plugins"; }
        ];
      };
    };

    customPalettes.Synthwave = {
      dark = {
        mPrimary = "#ff2e88";
        mOnPrimary = "#1a1025";
        mSecondary = "#05d9e8";
        mOnSecondary = "#1a1025";
        mTertiary = "#b967ff";
        mOnTertiary = "#1a1025";
        mError = "#ff3860";
        mOnError = "#1a1025";
        mSurface = "#1a1025";
        mOnSurface = "#f4eaff";
        mSurfaceVariant = "#241736";
        mOnSurfaceVariant = "#d9c7ff";
        mOutline = "#6b4984";
        mShadow = "#0d0614";
        mHover = "#2e1d47";
        mOnHover = "#ffffff";
        terminal = {
          background = "#1a1025";
          foreground = "#f4eaff";
          cursor = "#ff2e88";
          cursorText = "#1a1025";
          selectionBg = "#3d2a5c";
          selectionFg = "#f4eaff";
          normal = {
            black = "#241736";
            red = "#ff2e88";
            green = "#05d9e8";
            yellow = "#f9c80e";
            blue = "#2de2e6";
            magenta = "#b967ff";
            cyan = "#05d9e8";
            white = "#f4eaff";
          };
          bright = {
            black = "#6b4984";
            red = "#ff6ec7";
            green = "#72f1b8";
            yellow = "#ffe66d";
            blue = "#6bf1ff";
            magenta = "#d9a7ff";
            cyan = "#7afcff";
            white = "#ffffff";
          };
        };
      };
    };
  };

  # ---- kitty ----
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.92";
      confirm_os_window_close = 0;

      # Animated cursor: it streaks to its new spot as you type and
      # backspace instead of teleporting. (kitty >= 0.36)
      cursor_trail = 1;                     # ms the cursor must be still before the trail catches up
      cursor_trail_decay = "0.1 0.4";       # fade-in / fade-out seconds
      cursor_trail_start_threshold = 1;     # animate even on single-cell moves (typing)
    };
    extraConfig = ''
      # Dark synthwave theme, matches the Noctalia "Synthwave" custom palette
      # in programs.noctalia.customPalettes above -- keep these in sync.
      background            #1a1025
      foreground            #f4eaff
      cursor                #ff2e88
      cursor_text_color     #1a1025
      selection_background  #3d2a5c
      selection_foreground  #f4eaff

      url_color #05d9e8

      color0  #241736
      color8  #6b4984

      color1  #ff2e88
      color9  #ff6ec7

      color2  #05d9e8
      color10 #72f1b8

      color3  #f9c80e
      color11 #ffe66d

      color4  #2de2e6
      color12 #6bf1ff

      color5  #b967ff
      color13 #d9a7ff

      color6  #05d9e8
      color14 #7afcff

      color7  #f4eaff
      color15 #ffffff
    '';
  };

  # ---- fastfetch ----
  # Synthwave theme to match the Noctalia "Synthwave" palette / kitty colors:
  #   pink   #ff2e88  -> "38;2;255;46;136"   (title, "system" section, logo)
  #   cyan   #05d9e8  -> "38;2;5;217;232"    ("desktop" section)
  #   purple #b967ff  -> "38;2;185;103;255"  ("hardware" section, separator)
  # Layout: FastCat "TheLead" style -- no box, instead colored "━━ section ━━"
  # header bars grouping the modules, a " ✦ " separator, one accent colour
  # per group. Lean module set (no Host/BIOS/Board/Font/Cursor/Media/etc).
  # Section headers are `custom` modules; fastfetch expands {#R;G;B}...{#}
  # inline colour codes in a format string (Nix strings can't hold a raw ESC,
  # so this is how the colour gets in). Keys are hand-padded so the ✦ aligns.
  # Logo: bunny ASCII art (assets/fastfetch-logo.txt), `file` type so the
  # leading `$1` in it picks up logo.color."1" (pink).
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "file";
        source = ./assets/fastfetch-logo.txt;
        padding = { top = 1; left = 2; right = 3; };
        color = {
          "1" = "38;2;255;46;136";
        };
      };

      display = {
        separator = " ✦ ";
        color = {
          title = "38;2;255;46;136";
          separator = "38;2;185;103;255";
          output = "38;2;217;199;255";
        };
        percent = {
          type = 1; # number only -- ram/swap/disk keep their lines, no bar graphic
        };
      };

      modules = [
        "break"
        { type = "title"; format = "{user-name}@{host-name}"; }
        "break"

        { type = "custom";   format = "{#38;2;255;46;136}━━━━━  system  ━━━━━{#}"; }
        { type = "os";       key = "󱄅 distro "; keyColor = "38;2;255;46;136"; }
        { type = "kernel";   key = " kernel "; keyColor = "38;2;255;46;136"; }
        { type = "uptime";   key = "󰔠 uptime "; keyColor = "38;2;255;46;136"; }
        # (no `packages` module: counting the nix store cost ~40ms of the
        # ~65ms total on every interactive shell -- dropped for speed.)
        "break"

        { type = "custom";   format = "{#38;2;5;217;232}━━━━  desktop  ━━━━{#}"; }
        { type = "wm";       key = "󱂬 wm     "; keyColor = "38;2;5;217;232"; }
        { type = "shell";    key = "󰞷 shell  "; keyColor = "38;2;5;217;232"; }
        { type = "terminal"; key = " term   "; keyColor = "38;2;5;217;232"; }
        "break"

        { type = "custom";   format = "{#38;2;185;103;255}━━━  hardware  ━━━{#}"; }
        { type = "cpu";      key = "󰻠 cpu    "; keyColor = "38;2;185;103;255"; format = "{1} ({3})"; }
        { type = "gpu";      key = "󰢮 gpu    "; keyColor = "38;2;185;103;255"; format = "{2}"; }
        { type = "memory";   key = "󰍛 ram    "; keyColor = "38;2;185;103;255"; }
        { type = "swap";     key = "󰓡 swap   "; keyColor = "38;2;185;103;255"; }
        { type = "disk";     key = "󰋊 disk   "; keyColor = "38;2;185;103;255"; folders = "/"; }
        "break"

        { type = "colors"; paddingLeft = 1; symbol = "circle"; }
        "break"
      ];
    };
  };

  # ---- zsh ----
  # kenny's login shell is set to zsh in configuration.nix
  # (programs.zsh.enable + users.users.kenny.shell); this block is the actual
  # interactive config. Deliberately lean -- prompt is starship, plus the
  # three "core" plugins. History/completion come from home-manager's own
  # sensible zsh defaults.
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;   # fish-style greyed-out inline suggestion
    enableCompletion = true;

    # Shortcuts for the /etc/nixos edit -> build -> switch loop (see the
    # `nix` skill / this file's own top-of-file comments for what each step
    # does). Deliberately keeps `nixbuild` and `nixswitch` separate rather
    # than one command that does both -- build first, look at the result,
    # THEN switch is the whole point of the two-step dance.
    shellAliases = {
      nixcd        = "cd /etc/nixos";
      nixbuild     = "cd /etc/nixos && sudo nixos-rebuild build --flake .#eeepy";
      nixswitch    = "cd /etc/nixos && sudo nixos-rebuild switch --flake .#eeepy";
      nixupdate    = "cd /etc/nixos && nix flake update";           # bumps flake.lock; nixbuild/nixswitch after
      nixrollback  = "sudo nixos-rebuild switch --rollback";
      nixgc        = "sudo nix-collect-garbage --delete-older-than 14d";  # reclaim disk from old generations
    };

    plugins = [
      {
        # Command-line syntax coloring as you type (the faster F-Sy-H fork,
        # not the older zsh-syntax-highlighting).
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
      }
    ];
    # The big _extra_ completion collection. The `_*` files land on the
    # system fpath via programs.zsh.enable's /share/zsh linking, so this just
    # needs to be installed.
    # (added to home.packages below)

    initContent = ''
      # Ctrl+Backspace deletes the whole previous word (kitty sends ^H for it);
      # Ctrl+Delete does the same forwards. Ctrl+U still wipes the whole line.
      bindkey '^H'      backward-kill-word
      bindkey '^[[3;5~' kill-word

      # fastfetch greets every new interactive shell (you asked for this).
      command -v fastfetch >/dev/null && fastfetch
    '';
  };

  # ---- starship prompt (synthwave) ----
  # Two-line prompt; pink path, cyan git, purple symbols, red prompt char on
  # a non-zero exit. Colors are the same Synthwave palette as the bar/kitty.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      palette = "synthwave";

      palettes.synthwave = {
        pink = "#ff2e88";
        cyan = "#05d9e8";
        purple = "#b967ff";
        yellow = "#f9c80e";
        red = "#ff3860";
      };

      character = {
        success_symbol = "[❯](bold cyan)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold purple)";
      };

      directory = {
        style = "bold pink";
        truncation_length = 3;
        truncate_to_repo = true;
        read_only = " ";
      };

      git_branch = {
        symbol = " ";
        style = "cyan";
      };
      git_status.style = "purple";
      git_state.style = "purple";

      cmd_duration = {
        min_time = 500;
        style = "yellow";
        format = "[ $duration]($style) ";
      };

      nix_shell = {
        symbol = " ";
        style = "purple";
        format = "[$symbol$name]($style) ";
      };
    };
  };

  # ---- zoxide ----
  # Stock commands: `z foo` jumps to the frecent dir matching "foo", `zi`
  # opens the fzf picker. Plain `cd` stays the shell builtin. (Dropped the
  # earlier `--cmd cd` override -- it removed the `z`/`zi` names people
  # expect, which read as "zoxide isn't working".) zoxide only knows dirs
  # you've visited *since* it started learning, so a fresh db feels empty
  # for a day or two.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ---- neovim (synthwave) ----
  # Lean but complete: synthwave84 colourscheme with its neon glow on a few
  # token groups, treesitter highlighting for the languages this repo + day
  # job touch, a matching lualine statusline, gitsigns and indent guides.
  # This owns `nvim` for kenny; configuration.nix keeps only tiny `vim` as
  # the root-shell fallback.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: with p; [
        nix lua bash python markdown markdown_inline json yaml toml
        c rust javascript typescript tsx html css kdl vim vimdoc regex diff
      ]))
      lualine-nvim
      nvim-web-devicons
      gitsigns-nvim
      indent-blankline-nvim
      synthwave84-nvim
    ];
    initLua = ''
      vim.g.mapleader = " "

      local o = vim.opt
      o.number = true
      o.relativenumber = true
      o.termguicolors = true
      o.cursorline = true
      o.signcolumn = "yes"
      o.scrolloff = 6
      o.expandtab = true
      o.shiftwidth = 2
      o.tabstop = 2
      o.smartindent = true
      o.ignorecase = true
      o.smartcase = true
      o.undofile = true
      o.wrap = false
      o.splitright = true
      o.splitbelow = true
      o.mouse = "a"
      o.clipboard = "unnamedplus"

      require("synthwave84").setup({
        glow = {
          error_msg = true,
          type = true,
          string = true,
          function_names = true,
          keyword = true,
          operator = false,
        },
      })
      vim.cmd.colorscheme("synthwave84")

      -- treesitter grammars come from nix (nvim-treesitter.withPlugins);
      -- just switch on tree-sitter highlighting per buffer. Done via an
      -- autocmd so it works regardless of which nvim-treesitter branch
      -- nixpkgs is on (the `main` rewrite dropped the old configs module).
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args) pcall(vim.treesitter.start, args.buf) end,
      })

      require("gitsigns").setup()
      require("ibl").setup({ scope = { enabled = false } })

      require("lualine").setup({
        options = {
          theme = "synthwave84",
          globalstatus = true,
          section_separators = "",
          component_separators = "|",
        },
      })
    '';
  };

  # ---- GTK / Qt dark theme (so Nautilus, GTK/Qt file dialogs etc. match) ----
  # KDE Plasma (kept as the fallback session) already writes its own
  # ~/.gtkrc-2.0 and gtk-3.0/4.0 settings.ini before home-manager ever runs,
  # and home-manager refuses to clobber files it doesn't already own. Force
  # it here since we want Nix's dark theme to win. Note: if you log into
  # Plasma and it rewrites these itself, they'll disagree until the next
  # `home-manager switch` puts the dark theme back.
  gtk = {
    enable = true;
    gtk2.force = true;
    # GTK app UI font. fontconfig's sans-serif default (configuration.nix)
    # already resolves to JetBrains Mono, but GTK wants an explicit family +
    # size in its settings.ini.
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    # ---- Synthwave recolour for GTK/libadwaita ----
    # Adwaita-dark is the base; these @define-color overrides repaint it in
    # the same palette as Noctalia "Synthwave" / kitty / fastfetch, so
    # libadwaita dialogs (the xdg-desktop-portal-gnome screencast /
    # "Share Screen" picker, file chooser, Nautilus, GNOME Disks...) match
    # instead of showing stock grey + blue accent. Palette:
    #   bg #1a1025  surface #241736  hover #2e1d47  view #150c1f
    #   fg #f4eaff  pink #ff2e88  pink-lt #ff77b6  cyan #05d9e8  purple #b967ff
    gtk4.extraCss = ''
      @define-color accent_color             #ff77b6;
      @define-color accent_bg_color          #ff2e88;
      @define-color accent_fg_color          #1a1025;

      @define-color destructive_color        #ff6b9d;
      @define-color destructive_bg_color     #ff2e6b;
      @define-color destructive_fg_color     #1a1025;

      @define-color success_color            #05d9e8;
      @define-color success_bg_color         #05d9e8;
      @define-color success_fg_color         #1a1025;

      @define-color warning_color            #ffc857;
      @define-color warning_bg_color         #ffc857;
      @define-color warning_fg_color         #1a1025;

      @define-color error_color              #ff6b9d;
      @define-color error_bg_color           #ff2e6b;
      @define-color error_fg_color           #1a1025;

      @define-color window_bg_color          #1a1025;
      @define-color window_fg_color          #f4eaff;
      @define-color view_bg_color            #150c1f;
      @define-color view_fg_color            #f4eaff;
      @define-color headerbar_bg_color       #241736;
      @define-color headerbar_fg_color       #f4eaff;
      @define-color headerbar_border_color   #f4eaff;
      @define-color headerbar_backdrop_color #1a1025;
      @define-color headerbar_shade_color    rgba(13, 6, 20, 0.55);
      @define-color popover_bg_color         #241736;
      @define-color popover_fg_color         #f4eaff;
      @define-color dialog_bg_color          #241736;
      @define-color dialog_fg_color          #f4eaff;
      @define-color card_bg_color            rgba(244, 234, 255, 0.05);
      @define-color card_fg_color            #f4eaff;
      @define-color card_shade_color         rgba(13, 6, 20, 0.55);
      @define-color sidebar_bg_color         #150c1f;
      @define-color sidebar_fg_color         #f4eaff;
      @define-color sidebar_backdrop_color   #1a1025;
      @define-color sidebar_border_color     rgba(244, 234, 255, 0.10);
      @define-color thumbnail_bg_color       #241736;
      @define-color thumbnail_fg_color       #f4eaff;
      @define-color shade_color              rgba(13, 6, 20, 0.55);
      @define-color scrollbar_outline_color  rgba(13, 6, 20, 0.60);
      @define-color borders                  rgba(244, 234, 255, 0.12);

      /* a touch more than the stock accent tint on the selected source row */
      row.activatable:selected {
        box-shadow: inset 3px 0 0 0 @accent_bg_color;
      }
    '';

    # GTK3 holdouts (some file dialogs, older apps). Adwaita-gtk3 hardcodes
    # more than gtk4 so this is best-effort -- selection + accent take.
    gtk3.extraCss = ''
      @define-color accent_color            #ff77b6;
      @define-color accent_bg_color         #ff2e88;
      @define-color accent_fg_color         #1a1025;
      @define-color theme_selected_bg_color #ff2e88;
      @define-color theme_selected_fg_color #1a1025;
      @define-color theme_bg_color          #1a1025;
      @define-color theme_base_color        #150c1f;
      @define-color theme_fg_color          #f4eaff;
      @define-color theme_text_color        #f4eaff;
      @define-color insensitive_bg_color    #241736;
      @define-color window_bg_color         #1a1025;
      @define-color view_bg_color           #150c1f;
      @define-color headerbar_bg_color      #241736;
      @define-color borders                 rgba(244, 234, 255, 0.12);
    '';
    # Tela (vinceliuice) -- pink/dark variant to sit with the synthwave
    # accent. Swap "pink" for purple / dracula / nord / grey etc. to retaste;
    # the package ships every colour.
    iconTheme = {
      name = "Tela-pink-dark";
      package = pkgs.tela-icon-theme;
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  # gtk3/gtk4 modules don't expose a `force` option like gtk2 does; force
  # the underlying managed files directly instead (see comment above).
  # gtk.css is here too: Plasma writes its own `@import 'colors.css';` stub
  # (leftover Breeze `*_breeze` colour names that libadwaita ignores anyway),
  # and home-manager won't clobber it without this. Our extraCss replaces it
  # outright, leaving Plasma's orphaned colors.css unimported / inert.
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
  xdg.configFile."gtk-3.0/gtk.css".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  # Helium is the default browser (revert by pointing these back at
  # firefox.desktop, or `xdg-settings set default-web-browser firefox.desktop`).
  # The claude-cli handler is carried over from the pre-existing
  # ~/.config/mimeapps.list that this now replaces.
  xdg.mimeApps = {
    enable = true;
    associations.added."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    defaultApplications = {
      "text/html" = "helium.desktop";
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
      "x-scheme-handler/about" = "helium.desktop";
      "x-scheme-handler/unknown" = "helium.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
  # Both pre-existed as plain files (mimeapps.list from the base install,
  # starship.toml written by noctalia's now-disabled starship template).
  xdg.configFile."mimeapps.list".force = true;
  home.file."${config.xdg.configHome}/starship.toml".force = true;

  # ---- PWAs ----
  # helium --app windows, defined in the `pwas` set at the top of this file
  # (see the comment there). niri binds: Mod+Shift+B -> Basecamp.
  xdg.dataFile = pwaDesktopFiles // pwaIconFiles // {
    # nix-snowflake button for the Noctalia dock: opens the app launcher.
    # (The bar gets the same logo as a `custom_button` widget -- see the
    # noctalia settings block.)
    "applications/nixos.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Applications
      Icon=${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg
      Exec=noctalia msg panel-toggle launcher
      Terminal=false
      Categories=System;
    '';

    "applications/limusic.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=LiMusic
      GenericName=YouTube Music client
      Comment=Third-party desktop client for YouTube Music
      Exec=${pkgs.appimage-run}/bin/appimage-run ${limusicAppImage}
      Icon=${./assets/appimages/limusic.png}
      StartupWMClass=limusic-app
      Terminal=false
      Categories=AudioVideo;Audio;Music;
    '';

    # Dolphin emulator synthwave user style. Dolphin looks for user styles in
    # <data>/dolphin-emu/Styles/ (D_USER_IDX, ~/.local/share on XDG); the
    # activation script below points Qt.ini at this file by name.
    "dolphin-emu/Styles/synthwave.qss".source = ./assets/dolphin-emu/synthwave.qss;
  };

  # Turn the Dolphin synthwave look on. Both ini files are mutable (Dolphin
  # writes window state, game-list columns, controller config, ... to them),
  # so they can't be read-only Nix symlinks -- instead merge the handful of
  # keys in on every switch:
  #   Qt.ini [userstyle]     -> the synthwave.qss above (styletype 3 = User,
  #                             see Source/Core/DolphinQt/Settings.h)
  #   Dolphin.ini [Interface]-> "Clean Pink" icon theme, dark titlebar
  home.activation.dolphinUserStyle =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      _cfg="${config.xdg.configHome}/dolphin-emu"
      _crudini=${pkgs.crudini}/bin/crudini
      run mkdir -p "$_cfg"
      run $_crudini --set "$_cfg/Qt.ini"      userstyle enabled   true
      run $_crudini --set "$_cfg/Qt.ini"      userstyle styletype 3
      run $_crudini --set "$_cfg/Qt.ini"      userstyle name       synthwave.qss
      run $_crudini --set "$_cfg/Dolphin.ini" Interface ThemeName  "Clean Pink"
    '';

  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
