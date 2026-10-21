# NixOS Configuratie voor Asus Laptop

Deze repository bevat de NixOS configuratiebestanden voor een Asus laptop (hostname `asus-nixos`) met zowel **Hyprland (Wayland)** als **KDE Plasma** desktop omgevingen.

## Configuratiebestanden

Er zijn drie volwaardige, onderling gesynchroniseerde configuraties voor dezelfde laptop (zelfde hostname, gebruiker, netwerk, printers, pakketten, SolidCraft, enz.), die elk hun eigen desktop-omgeving opzetten:

- `configuration.nix` - **Actieve configuratie** (op dit moment een kopie van de KDE-variant, zie hieronder). Dit bestand wordt naar `/etc/nixos/configuration.nix` gekopieerd en gebruikt door `nixos-rebuild switch`.
- `configuration.nix.kde` - KDE Plasma 6 variant (identiek aan de huidige `configuration.nix`)
- `configuration.nix.hyprland` - Hyprland (Wayland) variant, met Waybar, Rofi en bijbehorende Wayland-tools
- `configuration.nix.swayfx` - SwayFX variant (Sway-fork met blur/shadows/rounded corners), met Kitty, Rofi, Waybar, Mako, Dolphin
- `hardware-configuration.nix` - Hardware specifieke instellingen (gedeeld door alle drie de varianten)
- `hyprland-snippet.conf` - Extra Hyprland configuratie (aanvulling, geen vervanging, op `~/.config/hypr/hyprland.conf`)
- `config.rasi` - Rofi configuratie voor startmenu (Hyprland en SwayFX)
- `sway-config` - Sway configuratie (volledige `~/.config/sway/config`)
- `switch-desktop.sh` - Script om tussen de drie varianten te wisselen (zie "Gebruik" hieronder)

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
Momentueel actief (`configuration.nix`, identiek aan `configuration.nix.kde`).

### Hyprland (Wayland)
Volwaardige configuratie in `configuration.nix.hyprland`, nog niet actief.

### SwayFX
Volwaardige configuratie in `configuration.nix.swayfx`, nog niet actief (experimenteel).

## Gebruik

1. **Systeem bijwerken:**
   ```bash
   sudo nix-channel --update
   sudo nixos-rebuild switch --upgrade
   ```

2. **Configuratie wijzigen:**
   - Bewerk het gewenste configuratiebestand in deze repository
   - Kopieer het naar `/etc/nixos/configuration.nix`
   - Voer uit: `sudo nixos-rebuild switch`

3. **Overschakelen naar een andere desktop-omgeving:**
   ```bash
   ./switch-desktop.sh {kde|hyprland|swayfx}
   ```
   Dit script (`switch-desktop.sh`):
   - controleert de syntax van de gekozen `configuration.nix.<variant>`;
   - kopieert 'm naar `/etc/nixos/configuration.nix` (met `sudo`);
   - zet voor Hyprland/SwayFX de bijbehorende Rofi-config (`config.rasi`) klaar in `~/.config/rofi/config.rasi`, en voor SwayFX ook `sway-config` in `~/.config/sway/config`. De Hyprland-snippet (`hyprland-snippet.conf`) wordt **niet** automatisch in een bestaande `~/.config/hypr/hyprland.conf` geplakt (dat zou 'm kunnen overschrijven) - hij wordt alleen klaargezet in `~/.config/hypr/hyprland-snippet.conf` om handmatig samen te voegen;
   - werkt de repo-kopie van `configuration.nix` bij naar de gekozen variant;
   - draait `sudo nixos-rebuild boot` (bouwt de nieuwe generatie en zet 'm als standaard boot-entry, zonder de lopende sessie te raken).

   Voeg `-y`/`--yes` toe om de bevestigingsvraag over te slaan. Herstart daarna (`sudo reboot`) om de nieuwe omgeving te activeren.

   Handmatig kan ook nog steeds:
   ```bash
   sudo cp ~/Projecten/NixOS/asus-laptop/configuration.nix.hyprland /etc/nixos/configuration.nix
   sudo nixos-rebuild switch
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

De onderstaande pakketten staan in alle drie de varianten (`configuration.nix` / `.kde`, `.hyprland`, `.swayfx`). Elke variant voegt daarnaast zijn eigen desktop-specifieke tooling toe (bv. Waybar/Rofi voor Hyprland en SwayFX, Dolphin/Mako/pavucontrol voor SwayFX) - zie het `environment.systemPackages`-blok in het betreffende bestand.

Belangrijke geïnstalleerde pakketten:
- `gparted` - Partitie editor
- `git` - Versiebeheer
- `openssh` - SSH client/server (levert `ssh-keygen`)
- `btop` - Systeemmonitor
- `fastfetch` - Systeeminformatie
- `tree` - Recursieve directory listing
- `fzf` - Fuzzy finder voor bestanden en shell-historie
- `curl` - Data op- en downloaden via URL's
- `wget` - Bestanden downloaden via HTTP(S)/FTP
- `rsync` - Efficiënt bestanden synchroniseren/overzetten
- `unzip` - .zip-archieven uitpakken
- `fd` - Snellere, gebruiksvriendelijkere `find`
- `ripgrep` - Snelle recursieve grep (commando `rg`)
- `bat` - `cat` met syntax highlighting en git-integratie
- `eza` - Moderne `ls`-vervanging (kleuren, git status, boomweergave)
- `ncdu` - Interactieve disk usage analyzer
- `python3` - Python interpreter (gebruik venvs of nix-shell voor projectspecifieke bibliotheken)
- `libreoffice-qt6-fresh` - Kantoorsuite (Qt6, past bij KDE Plasma)
- `vscode` - Code editor
- `mistral-vibe` - Mistral Vibe CLI (commando `vibe`)
- `claude-code` - Claude Code CLI van Anthropic (commando `claude`)
- `unixodbc` - ODBC driver manager (`isql` / `odbcinst`)
- `mariadb.client` - MariaDB/MySQL command-line client (`mariadb` en `mysql`)
- `kdePackages.kate` - Teksteditor (alleen voor gebruiker `rvdveldt`)
- `zsh` - Shell met OhMyZsh
- `solidcraft` - Parametrische CAD-software (v0.12.0), niet in nixpkgs, zelf gepakt uit de officiële Linux x64 AppImage via `pkgs.appimageTools.wrapType2` (zie `let`-blok bovenin `configuration.nix`). Start met `solidcraft`, of via het startmenu/Krunner (icoon en `.desktop`-entry komen van `solidcraftDesktopItem`, uitgepakt uit dezelfde AppImage).

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

### 2026-10-21 (nog later)
- `curl`, `wget`, `rsync`, `unzip`, `fd`, `ripgrep`, `bat`, `eza` en `ncdu` toegevoegd aan
  `environment.systemPackages` in alle drie de varianten (`configuration.nix`,
  `configuration.nix.kde`, `configuration.nix.hyprland`, `configuration.nix.swayfx`).

### 2026-10-21 (later)
- `tree` en `fzf` toegevoegd aan `environment.systemPackages` in alle drie de varianten
  (`configuration.nix`, `configuration.nix.kde`, `configuration.nix.hyprland`,
  `configuration.nix.swayfx`).

### 2026-10-21
- `claude-code` toegevoegd aan `environment.systemPackages` (commando `claude`).
- README bijgewerkt met systeeminstellingen, printen, ZSH, ODBC-details en het gebruik van Claude Code.
- `solidcraft` toegevoegd: parametrische CAD-software, gepakt als AppImage (v0.12.0) via `pkgs.appimageTools.wrapType2` omdat het niet in nixpkgs/Flathub staat.
- `solidcraftDesktopItem` toegevoegd: `.desktop`-entry en icoon voor SolidCraft, uitgepakt uit dezelfde AppImage zodat het ook in het startmenu verschijnt.
- `configuration.nix` gekopieerd naar `configuration.nix.kde` (expliciete KDE-variant naast de actieve configuratie).
- `configuration.nix.hyprland` en `configuration.nix.swayfx` gesynchroniseerd met `configuration.nix`: SolidCraft-packaging (inclusief desktop-item), `claude-code`, de Epson-printerdrivers (`epson-escpr2`/`epson-escpr`) en de `LS_COLORS`-instelling waren daar nog niet in opgenomen.
- Verouderde bestandsverwijzing in de koptekst van `configuration.nix.swayfx` hersteld (verwees nog naar de oude bestandsnamen `configuration.nix`/`configuration.kde.nix` voor Hyprland/KDE).
- README-secties "Configuratiebestanden", "Desktop Omgevingen", "Gebruik" en "Pakketten" bijgewerkt: verwijzingen naar het niet meer bestaande `configuration.kde.nix`/`configuration.nix.kde-backup` verwijderd, `configuration.nix.hyprland` toegevoegd, en uitgelegd hoe je tussen de drie varianten wisselt.
- `switch-desktop.sh` toegevoegd: kopieert de gekozen variant naar `/etc/nixos/configuration.nix`, zet de bijbehorende Rofi-/Sway-dotfiles klaar in `~/.config`, werkt de repo-kopie van `configuration.nix` bij, en draait `sudo nixos-rebuild boot`.

---

*Laatst bijgewerkt: 2026-10-21*
