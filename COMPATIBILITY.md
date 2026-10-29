# Compatibility

Reports of this toolkit on real TVs. **Nothing has been confirmed yet.** Add
yours via a pull request (see [CONTRIBUTING.md](CONTRIBUTING.md)).

Status values: `works` (all scripts ran, TV fine afterwards), `partial` (some
steps failed, say which), `broke` (something stopped working, say what and how
you recovered).

| Vendor | Model | Android / Google TV version | Status | Notes (what was removed, what failed) |
|---|---|---|---|---|
| Panasonic | 4KTV-JUP (Jupiter_EU, MediaTek, 1.7 GB RAM) | Android 11, fw 3.501 | works (modest gain) | Removed demomode, partnersetup, onetimeinitializer; no breakage across reboots. Removing the screensaver (`backdrop`) made the TV sleep ~10 min into audio playback; restored, fixed. Background-restricted 9 streaming apps: ~270 MB RAM freed, apps still launch. Free RAM 58 → 132 MB after boot. Animation scale resets on reboot. Details: [docs/PANASONIC-4KTV-JUP.md](docs/PANASONIC-4KTV-JUP.md). |
