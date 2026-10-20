# NixOS Configuratie voor Asus Laptop

Deze repository bevat de NixOS configuratiebestanden voor een Asus laptop met zowel **Hyprland (Wayland)** als **KDE Plasma** desktop omgevingen.

## Configuratiebestanden

- `configuration.nix` - Hoofdconfiguratie (momentueel geconfigureerd voor KDE Plasma)
- `configuration.kde.nix` - KDE Plasma specifieke configuratie
- `configuration.nix.swayfx` - SwayFX Window Manager configuratie (experimenteel)
- `configuration.nix.kde-backup` - Backup van eerdere KDE configuratie
- `hardware-configuration.nix` - Hardware specifieke instellingen
- `hyprland-snippet.conf` - Extra Hyprland configuratie
- `config.rasi` - Rofi configuratie voor startmenu
- `sway-config` - Sway configuratie

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
- Samba server is geconfigureerd voor bestandsdelen
- Avahi (mDNS) is ingeschakeld voor netwerkontdekking

## Pakketten

Belangrijke geïnstalleerde pakketten:
- `gparted` - Partitie editor
- `git` - Versiebeheer
- `openssh` - SSH client/server
- `btop` - Systeemmonitor
- `fastfetch` - Systeeminformatie
- `python3` - Python interpreter
- `libreoffice-qt6-fresh` - Kantooruite
- `vscode` - Code editor
- `mistral-vibe` - Mistral Vibe CLI
- `zsh` - Shell met OhMyZsh

## ODBC Configuratie

MariaDB/ODBC driver is geconfigureerd voor database connecties. Test met:
```bash
isql -v MariaDB test
```

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
- **Nix Flakes**: Ingeschakeld voor experimentele functies

## Probleemoplossing

Bij problemen met de configuratie:
1. Controleer de logbestanden in `/var/log/`
2. Gebruik `nixos-option` om opties te doorzoeken
3. Raadpleeg de [NixOS handleiding](https://nixos.org/manual/)

---

*Laatst bijgewerkt: 2026-10-20*
