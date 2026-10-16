# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

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

  networking.hostName = "asus-nixos"; # Define your hostname.

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

  # ===== HYPRLAND WAYLAND CONFIGURATION =====
  # Disable X11 for pure Wayland experience with Hyprland
  services.xserver.enable = false;

  # Enable Hyprland - a dynamic tiling Wayland compositor
  programs.hyprland = {
    enable = true;
  };

  # Enable SDDM display manager for session selection
  services.displayManager.sddm = {
    enable = true;
    # displayServer = "wayland";
    wayland.enable = true;
  };

  # Configure console keymap
  console.keyMap = "nl";

  # Wayland session environment variables
  environment.sessionVariables = {
    WAYLAND_DISPLAY = "wayland-1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
  };

  # Enable touchpad support for Wayland
  services.libinput.enable = true;

  # ==========================================

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
    extraGroups = [ "networkmanager" "wheel" "video" "seat" ]; # Added video and seat for Wayland
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
    # Hyprland-specific packages
    waybar    # Status bar
    rofi       # Application launcher
    wl-clipboard  # Wayland clipboard utilities
    grim       # Screenshot utility for Wayland
    slurp      # Region selection for screenshots
    swaylock   # Screen locker
    swayidle   # Idle management
    alacritty  # Terminal emulator (Wayland native)
    firefox   # Browser
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

  # Samba server
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

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  networking.firewall.allowedUDPPorts = [ 3702 ];

  systemd.tmpfiles.rules = [
    "d /home/rvdveldt/shared 0755 rvdveldt users -"
  ];

  # NixOS Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";

}
