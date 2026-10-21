# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

let
  # SolidCraft: parametrische CAD-software, niet beschikbaar in nixpkgs.
  # Gepakt als AppImage uit de officiële GitHub release (v0.18.2).
  # https://solidcraft.io/download/
  solidcraftVersion = "0.18.2";
  solidcraftSrc = pkgs.fetchurl {
    url = "https://github.com/tangency-labs/solidcraft/releases/download/v${solidcraftVersion}/solidcraft-${solidcraftVersion}-linux-x86_64.AppImage";
    sha256 = "a227c1e632b407c13141fa0fd72e81ec9dab6fb63231a40d3cbcf636ba758e51";
  };
  solidcraft = pkgs.appimageTools.wrapType2 {
    pname = "solidcraft";
    version = solidcraftVersion;
    src = solidcraftSrc;
    extraPkgs = pkgs: with pkgs; [ ];
  };
  # De AppImage bevat zelf een .desktop-bestand en icoon, maar wrapType2
  # installeert die niet automatisch. Hier pakken we ze alsnog uit en zetten
  # ze op hun standaardplek, zodat SolidCraft in het startmenu verschijnt.
  solidcraftExtracted = pkgs.appimageTools.extractType2 {
    pname = "solidcraft";
    version = solidcraftVersion;
    src = solidcraftSrc;
  };
  solidcraftDesktopItem = pkgs.runCommand "solidcraft-desktop-item" { } ''
    install -Dm444 ${solidcraftExtracted}/ai.storyteller.solidcraft.desktop \
      $out/share/applications/ai.storyteller.solidcraft.desktop
    install -Dm444 ${solidcraftExtracted}/ai.storyteller.solidcraft.png \
      $out/share/icons/hicolor/256x256/apps/ai.storyteller.solidcraft.png
  '';
in
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
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "nl";
    variant = "us";
  };

  # Configure console keymap
  console.keyMap = "nl";

  # Enable CUPS to print documents.
  # Network printers (such as the Epson) are discovered via Avahi/mDNS, which is
  # enabled further down in this file (services.avahi).
  services.printing = {
    enable = true;
    # Epson drivers, used as a fallback when the printer does not support
    # driverless IPP Everywhere printing:
    #   epson-escpr2 = newer Epson inkjets (XP-, ET-, WF-series)
    #   epson-escpr  = older Epson inkjets
    drivers = [ pkgs.epson-escpr2 pkgs.epson-escpr ];
  };

  # Optional: declarative printer definition. Uncomment and fill in the IP address
  # of the Epson (preferably a fixed address / DHCP reservation in the router).
  # model = "everywhere" uses driverless IPP; replace it with a driver PPD name
  # if the printer needs one of the drivers above.
  # hardware.printers = {
  #   ensurePrinters = [
  #     {
  #       name = "Epson";
  #       deviceUri = "ipp://192.168.1.50/ipp/print";  # Replace with the printer's IP
  #       model = "everywhere";
  #     }
  #   ];
  #   ensureDefaultPrinter = "Epson";
  # };

  # Optional: scanning support for Epson multifunction printers.
  # sane-airscan provides driverless network scanning (eSCL/AirScan).
  # hardware.sane = {
  #   enable = true;
  #   extraBackends = [ pkgs.sane-airscan ];
  # };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."rvdveldt" = {
    isNormalUser = true;
    description = "Richard van der Veldt";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;  # Default login shell
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Enable zsh system-wide (required before it can be used as a login shell)
  programs.zsh = {
    enable = true;
    # Configure OhMyZSH
    ohMyZsh = {
      enable = true;
      # Setup Theme
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
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    gparted  # Partition Editor
    git      # Version control
    openssh  # Provides ssh-keygen (there is no separate ssh-keygen package)
    btop     # Interactive resource monitor
    fastfetch  # Fast system information tool (neofetch replacement)
    tree     # Recursive directory listing
    fzf      # Fuzzy finder for files and shell history
    curl     # Transfer data from/to a URL
    wget     # Download files over HTTP(S)/FTP
    rsync    # Efficient file synchronization/transfer
    unzip    # Extract .zip archives
    fd       # Fast, user-friendly alternative to find
    ripgrep  # Fast recursive grep (provides the `rg` command)
    bat      # cat with syntax highlighting and git integration
    eza      # Modern ls replacement (colors, git status, tree view)
    ncdu     # Interactive disk usage analyzer
    python3  # Python interpreter (use venvs or nix-shell for project-specific libraries)
    libreoffice-qt6-fresh  # Office suite (Qt6 build, matches the KDE Plasma desktop)
    vscode   # Visual Studio Code editor (unfree, allowed via nixpkgs.config.allowUnfree)
    mistral-vibe  # Mistral Vibe CLI, command-line coding assistant (provides the `vibe` command)
    claude-code  # Claude Code CLI by Anthropic, terminal coding assistant (provides the `claude` command; unfree, allowed via nixpkgs.config.allowUnfree)
    unixodbc  # ODBC driver manager (provides isql / odbcinst for testing connections)
    mariadb.client  # MariaDB/MySQL command-line client (provides the `mariadb` and `mysql` commands)
    solidcraft  # Parametric CAD software (packaged above from the upstream AppImage release)
    solidcraftDesktopItem  # .desktop entry + icon for SolidCraft, extracted from the AppImage above
    #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #   wget
    zsh       # Use ZSH as default, i.s.o. BASH
  ];

  # ODBC driver registration. The generic environment.unixODBCDrivers option points to
  # lib/libmaodbc.so, but in this package the library lives in lib/mariadb/, so the
  # driver is registered by hand. The MariaDB driver also works for MySQL servers.
  environment.etc."odbcinst.ini".text =
    let
      # The driver cannot find its own libmariadb.so.3 (same directory), so add that
      # directory to the RPATH of libmaodbc.so. This rebuilds the package locally.
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # System-wide Environment settings and variables
  environment.sessionVariables = {
    LS_COLORS = "*.pdf=93";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # NixOS Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Samba server: shares ~/shared with other machines on the network.
  # After the first rebuild, set a Samba password once (it is separate
  # from the login password):  sudo smbpasswd -a rvdveldt
  services.samba = {
    enable = true;
    openFirewall = true;  # Opens the required SMB ports in the firewall
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixos-vm";
        "netbios name" = "nixos";
        "security" = "user";
        "map to guest" = "never";  # No anonymous access
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

  # Client-side network discovery for Dolphin (network:/ and smb://):
  # Avahi (mDNS/Bonjour) lets the Synology show up by name and resolves *.local hostnames.
  services.avahi = {
    enable = true;
    nssmdns4 = true;      # Resolve .local names via mDNS
    openFirewall = true;  # Opens UDP 5353 for mDNS
  };

  # WS-Discovery replies come in on UDP 3702; KDE uses this to find SMB servers
  networking.firewall.allowedUDPPorts = [ 3702 ];

  # Make sure the shared directory exists, owned by the user
  systemd.tmpfiles.rules = [
    "d /home/rvdveldt/shared 0755 rvdveldt users -"
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
