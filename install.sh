#!/bin/sh
# Install the locally built hpcups filter + PPD and add the USB DeskJet 2300 series printer.
# Usage: sudo ./install.sh
set -eu

cd "$(dirname "$0")"
FILTER_DIR=/Library/Printers/HPDeskJet2300
PPD_SRC=build/HP-DeskJet-2300-hpcups.ppd
PPD_DST=/Library/Printers/PPDs/Contents/Resources/HP-DeskJet-2300-hpcups.ppd
QUEUE=HP_DeskJet_2332

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi
[ -x build/hpcups ] && [ -f "$PPD_SRC" ] || { echo "build output missing; run make first" >&2; exit 1; }

URI=$(lpinfo -v | awk '/usb:\/\/HP\/DeskJet%202300/ {print $2; exit}')
[ -n "$URI" ] || { echo "DeskJet 2300 series not found on USB; is it plugged in and on?" >&2; exit 1; }

# CUPS only runs filters owned by root and not group/world writable
install -d -o root -g wheel -m 755 "$FILTER_DIR"
install -o root -g wheel -m 755 build/hpcups "$FILTER_DIR/hpcups"
install -o root -g wheel -m 644 "$PPD_SRC" "$PPD_DST"

lpadmin -x "$QUEUE" 2>/dev/null || true
lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD_DST" \
        -D "HP DeskJet 2332" -L "USB" -o printer-is-shared=false
lpadmin -d "$QUEUE"

echo "Installed. Queue: $QUEUE  Device: $URI"
lpstat -p "$QUEUE"
