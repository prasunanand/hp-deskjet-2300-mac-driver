# HP DeskJet 2300 series driver for macOS

A macOS printer driver for the HP DeskJet 2300 series (2320 / 2330 / 2332, USB `03f0:3654`),
built from HP's open-source [HPLIP](https://developers.hp.com/hp-linux-imaging-and-printing) `hpcups` filter.

HP ships no macOS driver for this printer, and it has no AirPrint-over-USB interface, so macOS
falls back to "Generic PCL Laser Printer". The printer silently drops those jobs. HPLIP supports it
on Linux via `hpcups` (printer language `pcl3gui2`, no binary plugin), so this repo builds that
filter natively for macOS.

Tested on macOS 26.6 (Apple Silicon) with a DeskJet 2332 over USB.

## Build and install

Requires the Xcode Command Line Tools.

```sh
cd driver
make deps            # downloads HPLIP 3.26.4 + IJG libjpeg 9f into ../src, builds static libjpeg
make                 # builds driver/build/hpcups
sudo ./install.sh    # installs filter + PPD, adds the USB printer as HP_DeskJet_2332
lpoptions -d HP_DeskJet_2332   # make it your default (macOS keeps this per user)
lp test/hello.pdf    # print a test page
```

For an Intel Mac, build with `make ARCH=x86_64`.

## What gets installed

| Path | Purpose |
| --- | --- |
| `/Library/Printers/HPDeskJet2300/hpcups` | CUPS raster → PCL3GUI filter |
| `/Library/Printers/PPDs/Contents/Resources/HP-DeskJet-2300-hpcups.ppd` | PPD (HP's, pointed at the filter above; A4 default) |
| CUPS queue `HP_DeskJet_2332` | `usb://HP/DeskJet%202300%20series?serial=…` |

The driver also shows up in System Settings → Printers & Scanners as
"HP DeskJet 2300 series, hpcups 3.26.4 (local build)".

To uninstall:

```sh
sudo lpadmin -x HP_DeskJet_2332
sudo rm -rf /Library/Printers/HPDeskJet2300 /Library/Printers/PPDs/Contents/Resources/HP-DeskJet-2300-hpcups.ppd
```

## How the macOS build differs from HPLIP

The [Makefile](driver/Makefile) compiles only `prnt/hpcups` and `common/utils.c`, not HPLIP's
autotools build. It copies the sources into `build/src` with these changes:

- **Header clash.** `common/utils.h` is renamed to `cutils.h`, because macOS filesystems are case-insensitive and
  `#include "utils.h"` would otherwise resolve to hpcups' own `Utils.h`.
- **Missing header.** `<malloc.h>` becomes `<stdlib.h>`, because macOS has no `malloc.h`.
- **No image processor.** It builds with `-DDISABLE_IMAGEPROCESSOR`. HP's `libImageProcessor` is a closed x86 Linux
  `.so` that's only used for the `ljzjstream` language, not `pcl3gui2`.
- **No D-Bus.** It builds without `HAVE_DBUS`, so there are no desktop status notifications.

libjpeg is linked statically, so the filter depends only on system libraries (`libcups`,
`libcupsimage`, `libz`, `libc++`). That matters because CUPS runs filters in a sandbox.

## Limitations

- Printing only: no scanning, ink levels, or alignment/cleaning utilities.
- `lpadmin` warns that PPD-based printer drivers are deprecated. They still work in CUPS 2.x, but a
  future macOS that ships CUPS 3 may drop support.

## License

The filter and PPD come from HPLIP (GPL-2.0 / BSD / MIT, see HPLIP's `COPYING`). This repo only adds
build glue.
