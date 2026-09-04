# System-level configuration.
#
# Split of responsibility in this repo:
#   configuration.nix  -> things that need root / affect every user (this file)
#   home.nix            -> kenny's user-level config (niri, kitty, noctalia, apps)
# See flake.nix for how the two are wired together.
{ config, lib, pkgs, inputs, ... }:

let
  # ---- Helium "rice" bits ----
  # A Chromium theme is just an unpacked extension whose manifest carries a
  # `theme` block; Helium loads it via --load-extension (see programs.helium
  # below) and makes it the active theme. Synthwave palette, same colours as
  # the bar / kitty / starship.
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

  # Self-contained synthwave start page (assets/helium-newtab.html). Served
  # as a file:// URL by the RestoreOnStartup / HomepageLocation policies, so
  # every window opens on it and the home button returns to it.
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

  # ---- Boot ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CachyOS kernel: BORE scheduler + gaming-oriented patches, via the
  # Chaotic-Nyx overlay (see flake.nix). Fully reversible: pick the
  # previous generation at the systemd-boot menu if anything regresses.
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Load amdgpu in initramfs: fixes low-res boot screen, shaves a little boot time.
  hardware.amdgpu.initrd.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "eeepy";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  # ---- Desktop sessions ----
  # KDE Plasma stays installed as a safety-net session: if niri or noctalia
  # ever fail to start, you can still log in graphically and fix things.
  # Pick "niri" instead of "Plasma (X11)"/"Plasma (Wayland)" at the SDDM
  # login screen to use the new setup.
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # niri itself: this ALSO wires up xdg-desktop-portal-gnome (required for
  # niri's screencasting/remote-desktop support), gnome-keyring (secrets
  # portal) and nautilus as the file-chooser portal backend.
  # https://github.com/niri-wm/niri/wiki/Important-Software
  programs.niri.enable = true;

  # Both plasma6 and niri modules set a default login session; make niri
  # win so it's what SDDM pre-selects, while Plasma stays one click away
  # in the session dropdown as the fallback.
  services.displayManager.defaultSession = lib.mkForce "niri";

  # Access/Notification portal roles in niri's association are mapped to
  # "gtk" (see the niri NixOS module source); make sure that backend is
  # actually installed alongside the gnome one niri adds automatically.
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

  # ---- Gaming ----
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # Wine/Proton and many native games need the 32-bit GL/Vulkan stack.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # AMD GPU: unlock overclock/undervolt controls (used via CoreCtrl below).
  # Default ppfeaturemask (0xfffd7fff) is the conservative one recommended
  # by the module docs -- less likely to cause display flicker than
  # 0xffffffff. https://docs.kernel.org -> amdgpu ppfeaturemask
  hardware.amdgpu.overdrive.enable = true;
  programs.corectrl.enable = true;

  powerManagement.cpuFreqGovernor = "performance";
  zramSwap.enable = true;

  services.flatpak.enable = true;

  # AppImages don't run on NixOS out of the box (no /lib64/ld-linux.so.2,
  # no standard FHS layout for their bundled loader to find). This registers
  # them with the kernel's binfmt_misc so double-clicking (or `./foo.AppImage`
  # after `chmod +x`) just runs them through appimage-run's FHS sandbox --
  # no manual `appimage-run foo.AppImage` needed.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # noctalia: recommendedServices turns on NetworkManager (already on above),
  # Bluetooth, UPower and power-profiles-daemon for the shell's quick-settings.
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # ---- Virtualisation (QEMU/KVM + virt-manager) ----
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;                 # emulated TPM (Windows 11 guests)
      # UEFI/OVMF firmware ships with qemu itself on this nixpkgs -- no
      # separate `ovmf` submodule to enable anymore.
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;   # USB passthrough in SPICE
  boot.kernelModules = [ "kvm-intel" ];               # nested VT-x (12700KF)
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  users.users."kenny" = {
    isNormalUser = true;
    description = "kenny";
    extraGroups = [ "networkmanager" "wheel" "corectrl" "libvirtd" "kvm" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      kdePackages.kate
      virt-viewer          # lightweight SPICE/VNC guest console
      spice-gtk            # SPICE client bits virt-manager leans on
      virtio-win           # virtio driver ISO for Windows guests
      swtpm
    ];
  };

  # System-level zsh: adds it to /etc/shells (required before it can be a
  # login shell), sets up completion caching and /share/zsh profile linking.
  # The interactive rice (starship prompt, plugins, zoxide) is home-manager's
  # -- see programs.zsh / programs.starship / programs.zoxide in home.nix.
  programs.zsh.enable = true;

  programs.firefox.enable = true;

  # Helium browser (via helium-flake, see flake.nix). Riced:
  #  - synthwave theme extension (heliumSynthwaveTheme, --load-extension)
  #  - synthwave start page on every window + the home button (policies)
  #  - Wayland-native rendering under niri + AMD hardware video decode
  #  - forced dark UI, tidy/private policy set
  # `--disable-features=DisableLoadExtensionCommandLineSwitch` is required on
  # current Chromium for --load-extension to be honoured at all.
  programs.helium = {
    enable = true;
    flags = [
      "--ozone-platform-hint=auto"
      # VAAPI decode + dark web UI; FluentOverlayScrollbar = the thin
      # auto-hiding scrollbar (less chrome, sits better with the theme).
      "--enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL,WebUIDarkMode,FluentScrollbar,FluentOverlayScrollbar"
      "--disable-features=DisableLoadExtensionCommandLineSwitch"
      "--force-dark-mode"
      "--load-extension=${heliumSynthwaveTheme}"
    ];
    policies = {
      # synthwave start page: open it on launch, and on the home button
      RestoreOnStartup = 4;                       # 4 = open a specific set of pages
      RestoreOnStartupURLs = [ heliumStartUrl ];
      HomepageLocation = heliumStartUrl;
      HomepageIsNewTabPage = false;
      ShowHomeButton = true;

      # clean first run
      PromotionalTabsEnabled = false;
      DefaultBrowserSettingEnabled = false;
      MetricsReportingEnabled = false;
      # privacy
      BrowserSignin = 0;
      SyncDisabled = true;
      SearchSuggestEnabled = false;
      # layout
      BookmarkBarEnabled = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ---- Fonts ----
  # JetBrains Mono Nerd Font everywhere -- the mono desktop look. It's the
  # default for serif/sans/mono, so GTK/Qt app UI, SDDM, and anything that
  # asks fontconfig for a generic family gets it. Noto is only the fallback
  # for glyphs JetBrains Mono lacks (accents edge cases, symbols, emoji), so
  # nothing renders as tofu.
  #   - "JetBrainsMono Nerd Font"      -> the slightly-loose UI variant
  #   - "JetBrainsMono Nerd Font Mono" -> strict fixed-width, for terminals
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
    vim            # tiny root-shell fallback editor; kenny's nvim is in home.nix
    wget
    claude-code
    git
    gh
  ];

  system.stateVersion = "26.05";
}
