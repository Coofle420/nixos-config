{ config, lib, pkgs, inputs, ... }:

let
  synthwave = import ./synthwave-palette.nix;

  heliumSynthwaveTheme =
    pkgs.writeTextFile {
      name = "helium-synthwave-theme";
      destination = "/manifest.json";
      text = builtins.toJSON {
        manifest_version = 3;
        version = "1.0";
        name = "Synthwave";
        theme.colors = {
          frame = [ 26 16 37 ];
          frame_inactive = [ 20 12 28 ];
          frame_incognito = [ 13 6 20 ];
          toolbar = [ 36 23 54 ];
          toolbar_text = [ 244 234 255 ];
          tab_text = [ 255 255 255 ];
          tab_background_text = [ 185 143 220 ];
          background_tab = [ 26 16 37 ];
          bookmark_text = [ 217 199 255 ];
          toolbar_button_icon = [ 5 217 232 ];
          omnibox_background = [ 26 16 37 ];
          omnibox_text = [ 244 234 255 ];
          ntp_background = [ 26 16 37 ];
          ntp_text = [ 244 234 255 ];
          ntp_header = [ 107 73 132 ];
          ntp_link = [ 5 217 232 ];
          button_background = [ 36 23 54 ];
        };
      };
    };

  heliumStartPage = pkgs.runCommand "helium-startpage" { } ''
    mkdir -p $out
    cp ${./assets/helium-newtab.html} $out/newtab.html
  '';
  heliumStartUrl = "file://${heliumStartPage}/newtab.html";
in

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  hardware.amdgpu.initrd.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "eeepy";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.niri.enable = true;
  services.displayManager.defaultSession = lib.mkForce "niri";
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu.overdrive.enable = true;
  programs.corectrl.enable = true;

  powerManagement.cpuFreqGovernor = "performance";
  zramSwap.enable = true;

  services.flatpak.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  stylix = {
    enable = true;
    polarity = "dark";
    image = ./assets/synthwave-grid.png;
    base16Scheme = synthwave;

    cursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };

    opacity.terminal = 0.92;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      serif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 12;
        applications = 10;
        desktop = 10;
        popups = 10;
      };
    };
  };

  programs.qylock = {
    enable = true;
    theme = "last-of-us";
  };

  services.displayManager.sddm.settings.General.GreeterEnvironment =
    let
      qt6Pkgs = [ pkgs.kdePackages.qtdeclarative pkgs.kdePackages.qt5compat
                  pkgs.kdePackages.qtmultimedia pkgs.kdePackages.qtsvg ];
      qmlPath    = lib.concatMapStringsSep ":" (p: "${p}/lib/qt-6/qml") qt6Pkgs;
      pluginPath = lib.concatMapStringsSep ":" (p: "${p}/lib/qt-6/plugins") qt6Pkgs;
    in lib.concatStringsSep "," [
      "QML2_IMPORT_PATH=${qmlPath}"
      "QML_IMPORT_PATH=${qmlPath}"
      "QT_PLUGIN_PATH=${pluginPath}"
    ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  users.users."kenny" = {
    isNormalUser = true;
    description = "kenny";
    extraGroups = [ "networkmanager" "wheel" "corectrl" "libvirtd" "kvm" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      kdePackages.kate
      virt-viewer
      spice-gtk
      virtio-win
      swtpm
    ];
  };

  programs.zsh.enable = true;

  programs.firefox.enable = true;

  programs.helium = {
    enable = true;
    flags = [
      "--ozone-platform-hint=auto"
      "--enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL,WebUIDarkMode,FluentScrollbar,FluentOverlayScrollbar"
      "--disable-features=DisableLoadExtensionCommandLineSwitch"
      "--force-dark-mode"
      "--load-extension=${heliumSynthwaveTheme}"
    ];
    policies = {
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [ heliumStartUrl ];
      HomepageLocation = heliumStartUrl;
      HomepageIsNewTabPage = false;
      ShowHomeButton = true;

      PromotionalTabsEnabled = false;
      DefaultBrowserSettingEnabled = false;
      MetricsReportingEnabled = false;
      BrowserSignin = 0;
      SyncDisabled = true;
      SearchSuggestEnabled = false;
      BookmarkBarEnabled = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font Mono" "Noto Sans Mono" ];
      sansSerif = [ "JetBrainsMono Nerd Font" "Noto Sans" ];
      serif     = [ "JetBrainsMono Nerd Font" "Noto Serif" ];
      emoji     = [ "Noto Color Emoji" ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    claude-code
    git
    gh
  ];

  system.stateVersion = "26.05";
}
