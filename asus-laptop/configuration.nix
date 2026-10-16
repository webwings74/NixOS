# NixOS configuration: Hyprland (Wayland) setup.
# The KDE Plasma version of this file is kept as configuration.kde.nix.
# Help: configuration.nix(5), https://search.nixos.org/options, `nixos-help`.

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Boot Linux kernel 7.2 instead of the NixOS default kernel.
  # Kernel modules (such as prl-tools for Parallels) are built for this same version.
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_7_2;

  networking.hostName = "asus-nixos";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "nl_NL.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # ===== HYPRLAND =====

  # Hyprland itself is pure Wayland. The X server is only enabled so SDDM can
  # run its greeter on X11, which is far more reliable than the Wayland greeter
  # (the Wayland greeter pulls in kwin and often ends in a blinking cursor).
  services.xserver.enable = true;

  # Keymap for the X11 greeter (Hyprland has its own keymap, set in hyprland.conf).
  services.xserver.xkb = {
    layout = "nl";
    variant = "us";
  };

  # Console keymap
  console.keyMap = "nl";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # Run X11 apps inside Hyprland
  };

  # SDDM display manager with an X11 greeter; Hyprland appears as a session.
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "hyprland";

  # Do NOT set WAYLAND_DISPLAY, XDG_SESSION_TYPE or XDG_CURRENT_DESKTOP here:
  # the compositor sets those itself, and overriding them breaks the session.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Electron apps (VS Code, ...) use Wayland natively
  };

  # Authentication agent and touchpad support
  security.polkit.enable = true;
  services.libinput.enable = true;

  # ====================

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."rvdveldt" = {
    isNormalUser = true;
    description = "Richard van der Veldt";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    shell = pkgs.zsh;  # Default login shell
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Enable zsh system-wide (required before it can be used as a login shell)
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "sudo" "docker" ];
    };
  };

  # nix-ld: lets prebuilt, dynamically linked Linux binaries run on NixOS.
  # Needed for the Claude Code VS Code extension, which ships a generic native binary.
  programs.nix-ld.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    gparted  # Partition Editor
    git      # Version control
    openssh  # Provides ssh-keygen
    btop     # Interactive resource monitor
    fastfetch  # Fast system information tool
    python3  # Python interpreter
    libreoffice-qt6-fresh  # Office suite
    vscode   # Visual Studio Code (unfree)
    mistral-vibe  # Mistral Vibe CLI
    unixodbc  # ODBC driver manager
    mariadb.client  # MariaDB/MySQL client
    zsh       # ZSH shell

    # Hyprland desktop tooling
    kitty     # Terminal (default in Hyprland's generated config)
    alacritty # Alternative terminal
    wofi      # Launcher (default in Hyprland's generated config)
    rofi      # Alternative launcher
    waybar    # Status bar
    mako      # Notification daemon
    hyprpolkitagent  # Polkit authentication agent for Hyprland
    wl-clipboard  # Wayland clipboard utilities (wl-copy / wl-paste)
    grim      # Screenshot utility for Wayland
    slurp     # Region selection for screenshots
    swaylock  # Screen locker
    swayidle  # Idle management
    kdePackages.dolphin  # File manager (default in Hyprland's generated config)
    networkmanagerapplet # Network tray icon (nm-applet)
    pavucontrol  # Volume control
  ];

  # ODBC driver registration
  environment.etc."odbcinst.ini".text =
    let
      mariadbOdbc = pkgs.unixodbcDrivers.mariadb.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.patchelf ];
        postFixup = (old.postFixup or "") + ''
          patchelf --add-rpath $out/lib/mariadb $out/lib/mariadb/libmaodbc.so
        '';
      });
    in ''
      [MariaDB]
      Description = MariaDB/MySQL ODBC driver
      Driver = ${mariadbOdbc}/lib/mariadb/libmaodbc.so
    '';

  # Samba server: shares ~/shared with other machines on the network.
  # After the first rebuild, set a Samba password once:  sudo smbpasswd -a rvdveldt
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixos-vm";
        "netbios name" = "nixos";
        "security" = "user";
        "map to guest" = "never";
      };
      shared = {
        "path" = "/home/rvdveldt/shared";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "rvdveldt";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  # Make the share discoverable from Windows (WS-Discovery)
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Network discovery (Synology by name, *.local hostnames)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  networking.firewall.allowedUDPPorts = [ 3702 ];

  # Make sure the shared directory exists, owned by the user
  systemd.tmpfiles.rules = [
    "d /home/rvdveldt/shared 0755 rvdveldt users -"
  ];

  # NixOS Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Do NOT change this after the initial install.
  system.stateVersion = "26.05";

}
