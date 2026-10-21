#!/usr/bin/env bash
# Schakelt de actieve NixOS-configuratie om tussen KDE, Hyprland en SwayFX.
#
# Wat het doet:
#   1. Valideert de gekozen configuration.nix.<variant> met `nix-instantiate --parse`.
#   2. Kopieert 'm (met sudo) naar /etc/nixos/configuration.nix.
#   3. Zet voor Hyprland/SwayFX de bijbehorende Rofi-/Sway-dotfiles klaar
#      in ~/.config (hyprland-snippet.conf wordt NIET automatisch in een
#      bestaand hyprland.conf geplakt, enkel klaargezet om handmatig samen
#      te voegen).
#   4. Werkt de repo-kopie van configuration.nix bij naar dezelfde variant.
#   5. Draait `sudo nixos-rebuild boot` (bouwt de nieuwe generatie en zet
#      'm als standaard boot-entry; de lopende sessie blijft ongewijzigd
#      tot de volgende herstart).
#
# Gebruik: ./switch-desktop.sh {kde|hyprland|swayfx} [-y|--yes]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"
ASSUME_YES=false
for arg in "$@"; do
  [[ "$arg" == "-y" || "$arg" == "--yes" ]] && ASSUME_YES=true
done

usage() {
  echo "Gebruik: $0 {kde|hyprland|swayfx} [-y|--yes]" >&2
  exit 1
}

case "$TARGET" in
  kde)      SRC_CONFIG="$REPO_DIR/configuration.nix.kde" ;;
  hyprland) SRC_CONFIG="$REPO_DIR/configuration.nix.hyprland" ;;
  swayfx)   SRC_CONFIG="$REPO_DIR/configuration.nix.swayfx" ;;
  *)        usage ;;
esac

if [[ ! -f "$SRC_CONFIG" ]]; then
  echo "Fout: $SRC_CONFIG bestaat niet." >&2
  exit 1
fi

echo "==> Syntax van $SRC_CONFIG controleren"
nix-instantiate --parse "$SRC_CONFIG" > /dev/null

if ! $ASSUME_YES; then
  read -r -p "Omschakelen naar '$TARGET', /etc/nixos/configuration.nix overschrijven en 'nixos-rebuild boot' draaien? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Geannuleerd."; exit 1; }
fi

echo "==> Configuratie '$TARGET' naar /etc/nixos/configuration.nix kopiëren"
sudo cp "$SRC_CONFIG" /etc/nixos/configuration.nix
# hardware-configuration.nix is hardware-specifiek en wordt bewust niet
# overschreven; de versie die al in /etc/nixos staat blijft leidend.

case "$TARGET" in
  hyprland)
    mkdir -p ~/.config/rofi ~/.config/hypr
    cp "$REPO_DIR/config.rasi" ~/.config/rofi/config.rasi
    cp "$REPO_DIR/hyprland-snippet.conf" ~/.config/hypr/hyprland-snippet.conf
    echo "==> Rofi-config geïnstalleerd in ~/.config/rofi/config.rasi"
    echo "==> Let op: ~/.config/hypr/hyprland-snippet.conf staat klaar, maar is"
    echo "    een AANVULLING. Voeg de relevante regels zelf samen met je"
    echo "    bestaande ~/.config/hypr/hyprland.conf (zie de comments erin)."
    ;;
  swayfx)
    mkdir -p ~/.config/rofi ~/.config/sway
    cp "$REPO_DIR/config.rasi" ~/.config/rofi/config.rasi
    cp "$REPO_DIR/sway-config" ~/.config/sway/config
    echo "==> Rofi-config geïnstalleerd in ~/.config/rofi/config.rasi"
    echo "==> Sway-config geïnstalleerd in ~/.config/sway/config"
    ;;
esac

echo "==> Repository-kopie van configuration.nix bijwerken naar '$TARGET'"
cp "$SRC_CONFIG" "$REPO_DIR/configuration.nix"

echo "==> sudo nixos-rebuild boot"
sudo nixos-rebuild boot

cat <<EOF

Klaar. De '$TARGET'-configuratie is gebouwd en ingesteld als standaard
boot-entry. De huidige sessie blijft ongewijzigd tot de volgende herstart:

    sudo reboot
EOF
