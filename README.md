# HP DeskJet 2300 series driver for macOS

A macOS printer driver for the HP DeskJet 2300 series (2320 / 2330 / 2332, USB `03f0:3654`),
built from HP's open-source [HPLIP](https://developers.hp.com/hp-linux-imaging-and-printing) `hpcups` filter.

HP ships no macOS driver for this printer, and it has no AirPrint-over-USB interface, so macOS
falls back to "Generic PCL Laser Printer". The printer silently drops those jobs. HPLIP supports it
on Linux via `hpcups` (printer language `pcl3gui2`, no binary plugin), so this repo builds that
filter natively for macOS.

> Not affiliated with or endorsed by HP Inc. "HP" and "DeskJet" are trademarks of HP Inc.,
> used here only to identify the printers this works with.

Tested on macOS 26.6 (Apple Silicon) with a DeskJet 2332 over USB.

## Build and install

Requires the Xcode Command Line Tools.

```sh
git clone https://github.com/prasunanand/hp-deskjet-2300-mac-driver.git
cd hp-deskjet-2300-mac-driver
make deps            # downloads HPLIP 3.26.4 + IJG libjpeg 9f into src/, builds static libjpeg
make                 # builds build/hpcups and build/HP-DeskJet-2300-hpcups.ppd
sudo ./install.sh    # installs filter + PPD, adds the USB printer as HP_DeskJet_2332
lpoptions -d HP_DeskJet_2332   # make it your default (macOS keeps this per user)
lp test/hello.pdf    # print a test page
```

For an Intel Mac, build with `make ARCH=x86_64`. For Letter paper as the default, use `make PAPER=Letter`.

## What gets installed

| Path | Purpose |
| --- | --- |
| `/Library/Printers/HPDeskJet2300/hpcups` | CUPS raster → PCL3GUI filter |
| `/Library/Printers/PPDs/Contents/Resources/HP-DeskJet-2300-hpcups.ppd` | PPD generated from HPLIP's, pointed at the filter above |
| CUPS queue `HP_DeskJet_2332` | `usb://HP/DeskJet%202300%20series?serial=…` |

The driver also shows up in System Settings → Printers & Scanners as
"HP DeskJet 2300 series, hpcups 3.26.4 (local build)".

To uninstall:

```sh
sudo lpadmin -x HP_DeskJet_2332
sudo rm -rf /Library/Printers/HPDeskJet2300 /Library/Printers/PPDs/Contents/Resources/HP-DeskJet-2300-hpcups.ppd
```

## How the macOS build differs from HPLIP

The [Makefile](Makefile) compiles only `prnt/hpcups` and `common/utils.c`, not HPLIP's
autotools build. It copies the sources into `build/src` with these changes:

- **Header clash.** `common/utils.h` is renamed to `cutils.h`, because macOS filesystems are case-insensitive and
  `#include "utils.h"` would otherwise resolve to hpcups' own `Utils.h`.
- **Missing header.** `<malloc.h>` becomes `<stdlib.h>`, because macOS has no `malloc.h`.
- **No image processor.** It builds with `-DDISABLE_IMAGEPROCESSOR`. HP's `libImageProcessor` is a closed x86 Linux
  `.so` that's only used for the `ljzjstream` language, not `pcl3gui2`.
- **No D-Bus.** It builds without `HAVE_DBUS`, so there are no desktop status notifications.

libjpeg is linked statically, so the filter depends only on system libraries (`libcups`,
`libcupsimage`, `libz`, `libc++`). That matters because CUPS runs filters in a sandbox.

The PPD is HPLIP's `ppd/hpcups/hp-deskjet_2300_series.ppd` with four changes: `*cupsFilter` gets the
filter's absolute install path, the `*NickName` and `*PCFileName` are changed so it doesn't clash with an
official HP PPD, and the default paper size is set to `PAPER`.

## Limitations

- Printing only: no scanning, ink levels, or alignment/cleaning utilities.
- `lpadmin` warns that PPD-based printer drivers are deprecated. They still work in CUPS 2.x, but a
  future macOS that ships CUPS 3 may drop support.

## License

[GPL-2.0](LICENSE). The repo contains only build files; the driver source code and the PPD are downloaded from HPLIP
at build time. Those files keep their own license headers: GPL-2.0 or HP's BSD-style license,
copyright HP Development Company, L.P. Because parts of `hpcups` are GPL-2.0, any `hpcups` binary
built from this repo is GPL-2.0 as well.
