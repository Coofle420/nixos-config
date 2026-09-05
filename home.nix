{ config, pkgs, lib, inputs, ... }:

let
  pwas = {
    basecamp = {
      name = "Basecamp";
      genericName = "Project management";
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

  pwaIconFiles = lib.mapAttrs' (key: _:
    lib.nameValuePair "icons/hicolor/512x512/apps/${key}.png" {
      source = ./assets/pwa-icons/${key}.png;
    }) pwas;

  limusicAppImage = pkgs.fetchurl {
    url = "https://github.com/SimoHypers/limusic/releases/download/v0.6.9/limusic_0.6.9_amd64.AppImage";
    sha256 = "sha256-rwboptDDiR5EuHwY72vyeV0u2pavwjQNAN2iQKtFWBY=";
    executable = true;
  };

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
  home.stateVersion = "26.05";

  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  home.packages = with pkgs; [
    protonplus
    mangohud
    dolphin-emu

    xwayland-satellite

    discord
    zoom-us
    gnome-disk-utility
    obs-studio

    playerctl

    zsh-completions
    fzf
  ];

  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      shell = {
        font_family = "JetBrainsMono Nerd Font";
        launch_apps_as_systemd_services = true;
        corner_radius_scale = 1.2;
        panel.transparency_mode = "solid";
      };

      shell.shadow.alpha = 0.5;

      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "Synthwave";
      };

      theme.templates.enable_builtin_templates = false;

      wallpaper = {
        enabled = true;
        default.path = "${./assets/synthwave-grid.png}";
      };

      bar.default = {
        position          = "top";
        thickness         = 36;
        background_opacity = 0.0;
        shadow            = true;
        border_width      = 0.0;
        margin_edge       = 6;
        margin_ends       = 8;
        padding           = 8;
        widget_spacing    = 22;
        font_weight       = 600;

        capsule           = true;
        capsule_thickness = 0.82;
        capsule_fill      = "surface";
        capsule_opacity   = 0.9;
        capsule_padding   = 8.0;

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

      widget.nixos_menu = {
        type = "custom_button";
        custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        tooltip = "Applications";
        scale = 1.5;
        actions.left = "exec noctalia msg panel-toggle launcher";
      };

      dock = {
        enabled = true;
        background_opacity = 0.0;
        item_spacing = 3;
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

      widget.clock = {
        format      = "{:%a %d %b   %H:%M}";
        color       = "secondary";
        font_weight = 700;
      };

      widget.network    = { show_label = false; };
      widget.volume     = { show_label = false; };
      widget.bluetooth  = { show_label = false; };

      widget.audio_visualizer = {
        width   = 60;
        bands   = 18;
        color_1 = "primary";
        color_2 = "secondary";
      };

      widget.workspaces = {
        style         = "regular";
        focused_color = "primary";
        occupied_color = "secondary";
      };

      plugins = {
        enabled = [
        ];
        auto_update = "all";
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

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.92";
      confirm_os_window_close = 0;

      cursor_trail = 1;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 1;
    };
    extraConfig = ''
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
          type = 1;
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

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;

    shellAliases = {
      nixcd        = "cd /etc/nixos";
      nixbuild     = "cd /etc/nixos && sudo nixos-rebuild build --flake .#eeepy";
      nixswitch    = "cd /etc/nixos && sudo nixos-rebuild switch --flake .#eeepy";
      nixupdate    = "cd /etc/nixos && nix flake update";
      nixrollback  = "sudo nixos-rebuild switch --rollback";
      nixgc        = "sudo nix-collect-garbage --delete-older-than 14d";
    };

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
      }
    ];

    initContent = ''
      bindkey '^H'      backward-kill-word
      bindkey '^[[3;5~' kill-word

      command -v fastfetch >/dev/null && fastfetch
    '';
  };

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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

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

  gtk = {
    enable = true;
    gtk2.force = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

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

      row.activatable:selected {
        box-shadow: inset 3px 0 0 0 @accent_bg_color;
      }
    '';

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
    iconTheme = {
      name = "Tela-pink-dark";
      package = pkgs.tela-icon-theme;
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
  xdg.configFile."gtk-3.0/gtk.css".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;

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
  xdg.configFile."mimeapps.list".force = true;
  home.file."${config.xdg.configHome}/starship.toml".force = true;

  xdg.dataFile = pwaDesktopFiles // pwaIconFiles // {
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

    "dolphin-emu/Styles/synthwave.qss".source = ./assets/dolphin-emu/synthwave.qss;
  };

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
