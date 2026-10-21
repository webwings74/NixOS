# NixOS Configuratie voor Asus Laptop

Deze repository bevat de NixOS configuratiebestanden voor een Asus laptop (hostname `asus-nixos`) met zowel **Hyprland (Wayland)** als **KDE Plasma** desktop omgevingen.

## Configuratiebestanden

- `configuration.nix` - Hoofdconfiguratie (momentueel geconfigureerd voor KDE Plasma 6)
- `configuration.kde.nix` - KDE Plasma specifieke configuratie
- `configuration.nix.swayfx` - SwayFX Window Manager configuratie (experimenteel)
- `configuration.nix.kde-backup` - Backup van eerdere KDE configuratie
- `hardware-configuration.nix` - Hardware specifieke instellingen
- `hyprland-snippet.conf` - Extra Hyprland configuratie
- `config.rasi` - Rofi configuratie voor startmenu
- `sway-config` - Sway configuratie

## Systeeminstellingen

- **Hostname:** `asus-nixos`
- **Bootloader:** systemd-boot (EFI)
- **Kernel:** Linux 7.2 (`pkgs.linuxKernel.packages.linux_7_2`) in plaats van de NixOS-standaardkernel. Kernelmodules (zoals `prl-tools` voor Parallels) worden voor dezelfde versie gebouwd.
- **Tijdzone:** `Europe/Amsterdam`
- **Taal en regio:** `nl_NL.UTF-8` (inclusief alle `LC_*` instellingen)
- **Toetsenbord:** layout `nl`, variant `us`; console keymap `nl`
- **Display manager:** SDDM met KDE Plasma 6
- **Geluid:** PipeWire (met ALSA, 32-bit ALSA en PulseAudio-ondersteuning)
- **Browser:** Firefox
- **Unfree pakketten:** toegestaan (`nixpkgs.config.allowUnfree = true`)
- **nix-ld:** ingeschakeld, zodat vooraf gebouwde dynamisch gelinkte Linux-binaries draaien. Nodig voor de Claude Code VS Code extensie.

## LS_COLORS Instellingen

Systeembrede omgevingsvariabelen voor kleurcodering van bestanden in de terminal:

```nix
environment.sessionVariables = {
  LS_COLORS = "*.pdf=93";
};
```

Deze instelling zorgt ervoor dat PDF-bestanden in de terminal worden weergegeven met **kleur 93** (geel) voor betere zichtbaarheid.

### Beschikbare LS_COLORS opties

Je kunt meerdere bestandsxtensies en kleuren toevoegen. Voorbeelden:

```nix
environment.sessionVariables = {
  LS_COLORS = "
    *.pdf=93:
    *.zip=31:
    *.tar=31:
    *.gz=31:
    *.jpg=33:
    *.png=33:
  ";
};
```

Kleurcodes:
- `30` - Zwart
- `31` - Rood
- `32` - Groen
- `33` - Geel
- `34` - Blauw
- `35` - Magenta
- `36` - Cyaan
- `37` - Wit
- `90` - Lichtgrijs
- `91` - Lichtrood
- `92` - Lichtgroen
- `93` - Lichtgeel
- `94` - Lichtblauw
- `95` - Lichtmagenta
- `96` - Lichtcyaan
- `97` - Lichtwit

## Desktop Omgevingen

### KDE Plasma
Momentueel actief. Gebruik:
```bash
sudo nixos-rebuild switch --build-host localhost
```

### Hyprland (Wayland)
Toekomstige configuratie. De basisconfiguratie is aanwezig in `configuration.nix` commentaar.

### SwayFX
Experimentele configuratie beschikbaar in `configuration.nix.swayfx`.

## Gebruik

1. **Systeem bijwerken:**
   ```bash
   sudo nix-channel --update
   sudo nixos-rebuild switch --upgrade
   ```

2. **Configuratie wijzigen:**
   - Bewerk het gewenste configuratiebestand
   - Voer uit: `sudo nixos-rebuild switch`

3. **Specifieke configuratie activeren:**
   ```bash
   sudo nixos-rebuild switch -I nixos-config=/path/naar/configuration.nix
   ```

## Netwerk

- NetworkManager is ingeschakeld voor netwerkbeheer
- Samba server is geconfigureerd voor bestandsdelen (share `shared` = `/home/rvdveldt/shared`, alleen gebruiker `rvdveldt`, geen gastentoegang)
- Na de eerste rebuild eenmalig een Samba-wachtwoord instellen: `sudo smbpasswd -a rvdveldt`
- Avahi (mDNS) is ingeschakeld voor netwerkontdekking (o.a. de Synology in Dolphin)
- Samba-wsdd (WS-Discovery) maakt de share vindbaar vanaf Windows

## Printen en scannen

- CUPS is ingeschakeld; netwerkprinters (zoals de Epson) worden gevonden via Avahi/mDNS.
- Epson drivers als terugvaloptie wanneer de printer geen driverless IPP Everywhere ondersteunt:
  - `epson-escpr2` - nieuwere Epson inkjets (XP-, ET-, WF-serie)
  - `epson-escpr` - oudere Epson inkjets
- Een declaratieve printerdefinitie (`hardware.printers`) en scannerondersteuning (`hardware.sane` met `sane-airscan`) staan als uitgecommentarieerde opties klaar in `configuration.nix`.

## Pakketten

Belangrijke geïnstalleerde pakketten:
- `gparted` - Partitie editor
- `git` - Versiebeheer
- `openssh` - SSH client/server (levert `ssh-keygen`)
- `btop` - Systeemmonitor
- `fastfetch` - Systeeminformatie
- `python3` - Python interpreter (gebruik venvs of nix-shell voor projectspecifieke bibliotheken)
- `libreoffice-qt6-fresh` - Kantoorsuite (Qt6, past bij KDE Plasma)
- `vscode` - Code editor
- `mistral-vibe` - Mistral Vibe CLI (commando `vibe`)
- `claude-code` - Claude Code CLI van Anthropic (commando `claude`)
- `unixodbc` - ODBC driver manager (`isql` / `odbcinst`)
- `mariadb.client` - MariaDB/MySQL command-line client (`mariadb` en `mysql`)
- `kdePackages.kate` - Teksteditor (alleen voor gebruiker `rvdveldt`)
- `zsh` - Shell met OhMyZsh

### Claude Code gebruiken

Na een rebuild start je Claude Code vanuit een projectmap:

```bash
cd ~/mijn-project
claude
```

Bij de eerste start log je in met je Claude-account (of een Anthropic API-sleutel). Het pakket komt uit nixpkgs en kan achterlopen op de nieuwste release.

## ZSH

- zsh is de standaard login shell van `rvdveldt`
- OhMyZsh is ingeschakeld met thema `agnoster` en de plugins `git`, `sudo` en `docker`

## ODBC Configuratie

MariaDB/ODBC driver is geconfigureerd voor database connecties. Test met:
```bash
isql -v MariaDB test
```

De driver wordt met de hand geregistreerd in `/etc/odbcinst.ini`, omdat de bibliotheek in `lib/mariadb/` staat. Met `patchelf` wordt die map aan de RPATH van `libmaodbc.so` toegevoegd, zodat `libmariadb.so.3` gevonden wordt. Dit bouwt het pakket lokaal opnieuw. De MariaDB-driver werkt ook voor MySQL-servers.

## Firewall

Open poorten:
- UDP 3702 - WS-Discovery (voor KDE SMB ontdekking)
- UDP 5353 - mDNS (Avahi)
- Samba poorten (TCP 139, 445)

## Gebruiker

Gebruiker: `rvdveldt`
- Groepen: networkmanager, wheel
- Shell: zsh
- Home directory: `/home/rvdveldt`

## Extra's

- **Rofi**: Startmenu met iconen (config.rasi)
- **LS_COLORS**: PDF bestanden getoond in geel (kleur 93)
- **Nix Flakes**: Ingeschakeld voor experimentele functies (`nix-command` en `flakes`)

## Probleemoplossing

Bij problemen met de configuratie:
1. Controleer de logbestanden in `/var/log/`
2. Gebruik `nixos-option` om opties te doorzoeken
3. Raadpleeg de [NixOS handleiding](https://nixos.org/manual/)

## Wijzigingslog

### 2026-10-21
- `claude-code` toegevoegd aan `environment.systemPackages` (commando `claude`).
- README bijgewerkt met systeeminstellingen, printen, ZSH, ODBC-details en het gebruik van Claude Code.

---

*Laatst bijgewerkt: 2026-10-21*
