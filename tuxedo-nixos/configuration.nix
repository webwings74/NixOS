# NixOS configuration for "tuxedo-nixos"
# Dual-boot setup: NixOS replaces the former TuxedoOS/Ubuntu partition,
# the existing Windows installation and the existing EFI System Partition (ESP) are kept.
# Software and services are shared with the MacBook/VM configuration (mbp-configuration.nix);
# hardware-specific parts (bootloader, kernel, Parallels, Apple keyboard) are NOT copied.

{ config, lib, pkgs, ... }:

let
  # SolidCraft: parametric CAD software, not available in nixpkgs.
  # Packaged as an AppImage from the official GitHub release (v0.19.0).
  # This is the linux-x86_64 build, matching this desktop PC (Intel CPU).
  # https://solidcraft.io/download/
  solidcraftVersion = "0.19.0";
  solidcraftSrc = pkgs.fetchurl {
    url = "https://github.com/tangency-labs/solidcraft/releases/download/v${solidcraftVersion}/solidcraft-${solidcraftVersion}-linux-x86_64.AppImage";
    sha256 = "0fdd9fd2418d5171beec59039189ef14901271acead5227c1539608718252de1";
  };
  solidcraft = pkgs.appimageTools.wrapType2 {
    pname = "solidcraft";
    version = solidcraftVersion;
    src = solidcraftSrc;
    extraPkgs = pkgs: with pkgs; [ ];
  };
  # The AppImage contains its own .desktop file and icon, but wrapType2 does not
  # install them. Extract them here and put them in the standard locations so
  # SolidCraft shows up in the application menu.
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

  # ---------------------------------------------------------------------------
  # Boot loader
  # ---------------------------------------------------------------------------

  # Do not use systemd-boot; use GRUB so Windows can be detected and chain-loaded.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  # Re-use the existing ESP (do NOT format it, Windows boots from it as well).
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    # "nodev" = EFI install: no GRUB is written to a disk MBR, only to the ESP.
    device = "nodev";
    # Detect Windows (and other OSes) and add them to the GRUB menu.
    useOSProber = true;
    # Keep the number of old generations in the menu limited.
    configurationLimit = 20;
  };

  # Use the default (LTS) kernel. The newest kernel (linuxPackages_latest) is too new
  # for the NVIDIA driver and made the nvidia-open module fail to build.
  boot.kernelPackages = pkgs.linuxPackages;

  # ---------------------------------------------------------------------------
  # Desktop: KDE Plasma 6 on Wayland
  # ---------------------------------------------------------------------------
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ---------------------------------------------------------------------------
  # NVIDIA RTX 4070 Super
  # ---------------------------------------------------------------------------
  # The NVIDIA userspace driver is unfree, so unfree packages must be allowed.
  # (Also needed for vscode, claude-code, etc. below.)
  nixpkgs.config.allowUnfree = true;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;              # Open kernel modules (supported on RTX 40 series)
    modesetting.enable = true;
  };

  # ---------------------------------------------------------------------------
  # TUXEDO hardware control
  # ---------------------------------------------------------------------------
  # tuxedo-rs is the Rust reimplementation of TUXEDO Control Center (the original
  # Electron app is not packaged in nixpkgs). Enables the tuxedo-drivers kernel
  # module + tailord daemon, plus tailor-gui as the TCC GUI alternative.
  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  # ---------------------------------------------------------------------------
  # System
  # ---------------------------------------------------------------------------
  networking.hostName = "tuxedo-nixos";

  # Network connections via NetworkManager (defined ONCE only; a duplicate
  # definition was the cause of the nixos-install error).
  networking.networkmanager.enable = true;

  # Keep hardware clock in local time, same as Windows.
  time.hardwareClockInLocalTime = true;
  time.timeZone = "Europe/Amsterdam";

  # Locale and keyboard.
  # Dutch system language; also generate the English locale as fallback.
  i18n.defaultLocale = "nl_NL.UTF-8";
  i18n.supportedLocales = [ "nl_NL.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];

  # Dutch formats for dates, numbers, currency, paper size, etc.
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

  # Keyboard layout (the MacBook uses the "mac-iso" variant; not needed here).
  services.xserver.xkb.layout = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with PipeWire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ---------------------------------------------------------------------------
  # Users, shell and programs
  # ---------------------------------------------------------------------------
  # Set the password after install with: nixos-enter --root /mnt -c 'passwd rvdveldt'
  users.users.rvdveldt = {
    isNormalUser = true;
    description = "Richard van der Veldt";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;  # Default login shell
    packages = with pkgs; [
      kdePackages.kate  # KDE text editor
    ];
  };

  programs.firefox.enable = true;

  # Enable zsh system-wide (required before it can be used as a login shell).
  programs.zsh = {
    enable = true;
    # Configure Oh My Zsh.
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "sudo" "docker" ];
    };
  };

  # nix-ld: lets prebuilt, dynamically linked Linux binaries run on NixOS.
  # Needed for the Claude Code VS Code extension, which ships a generic native binary.
  programs.nix-ld.enable = true;

  # System-wide packages.
  environment.systemPackages = with pkgs; [
    vim          # Text editor
    git          # Version control
    efibootmgr   # Inspect and edit the UEFI boot entries and boot order
    openssh      # Provides ssh-keygen (there is no separate ssh-keygen package)
    btop         # Interactive resource monitor
    fastfetch    # Fast system information tool (neofetch replacement)
    tree         # Recursive directory listing
    fzf          # Fuzzy finder for files and shell history
    curl         # Transfer data from/to a URL
    wget         # Download files over HTTP(S)/FTP
    rsync        # Efficient file synchronization/transfer
    unzip        # Extract .zip archives
    fd           # Fast, user-friendly alternative to find
    ripgrep      # Fast recursive grep (provides the `rg` command)
    bat          # cat with syntax highlighting and git integration
    eza          # Modern ls replacement (colors, git status, tree view)
    ncdu         # Interactive disk usage analyzer
    python3      # Python interpreter (use venvs or nix-shell for project-specific libraries)
    libreoffice-qt6-fresh  # Office suite (Qt6 build, matches the KDE Plasma desktop)
    vscode       # Visual Studio Code editor (unfree, allowed above)
    mistral-vibe # Mistral Vibe CLI, command-line coding assistant (provides the `vibe` command)
    claude-code  # Claude Code CLI by Anthropic (provides the `claude` command; unfree)
    unixodbc     # ODBC driver manager (provides isql / odbcinst for testing connections)
    mariadb.client  # MariaDB/MySQL command-line client (provides `mariadb` and `mysql`)
    solidcraft   # Parametric CAD software (packaged above from the upstream AppImage release)
    solidcraftDesktopItem  # .desktop entry + icon for SolidCraft, extracted from the AppImage
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

  # System-wide environment variables.
  environment.sessionVariables = {
    LS_COLORS = "*.pdf=93";  # Show PDF files in bright yellow in `ls` output
  };

  # ---------------------------------------------------------------------------
  # Nix
  # ---------------------------------------------------------------------------
  # Enable flakes and the new `nix` command.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ---------------------------------------------------------------------------
  # Network services: Samba, Windows/KDE network discovery
  # ---------------------------------------------------------------------------
  # Samba server: shares ~/shared with other machines on the network.
  # After the first rebuild, set a Samba password once (it is separate
  # from the login password):  sudo smbpasswd -a rvdveldt
  services.samba = {
    enable = true;
    openFirewall = true;  # Opens the required SMB ports in the firewall
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "tuxedo-nixos";
        "netbios name" = "tuxedo-nixos";
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

  # Make the share discoverable from Windows (WS-Discovery).
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

  # WS-Discovery replies come in on UDP 3702; KDE uses this to find SMB servers.
  networking.firewall.allowedUDPPorts = [ 3702 ];

  # TEMPORARY: uitgezet om te testen of de firewall de Raise3D-printer-discovery
  # in ideaMaker blokkeert. Zet dit na de test weer terug naar true (of verwijder
  # de regel, want enabled is de NixOS-default).
  networking.firewall.enable = false;

  # Make sure the shared directory exists, owned by the user.
  systemd.tmpfiles.rules = [
    "d /home/rvdveldt/shared 0755 rvdveldt users -"
  ];

  # Do not change this value after the initial install.
  system.stateVersion = "26.05";
}
