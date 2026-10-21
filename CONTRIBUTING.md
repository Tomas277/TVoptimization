# Contributing

The most useful contribution is **a report from a real TV**. The scripts are
generic, but package names differ per vendor, and only people with the
hardware can verify them.

## Report your TV (add a row to COMPATIBILITY.md)

1. Run `./00_detect.sh` and `./01_backup.sh`.
2. Apply what you like, test live TV, HDMI inputs and your apps.
3. Open a PR adding one row to [COMPATIBILITY.md](COMPATIBILITY.md): vendor,
   model, Android version, status, and what you removed or what broke.

**Do not paste your `reports/` or `backup/` folders.** They contain your
device fingerprint and installed apps. Share only the package names that matter.

## Add or improve a vendor profile

Profiles live in `profiles/<manufacturer>.conf` and list package **prefixes**
that must never be removed (tuner, input framework, launcher, remote service).
Start from `profiles/TEMPLATE.conf.example`. State the model and Android
version you verified on, or mark the file `UNVERIFIED`.

The file name is the output of `adb shell getprop ro.product.manufacturer`,
lower-cased, letters and digits only.

## Code changes

- Keep scripts in plain bash, safe by default (dry-run unless `--apply`).
- Anything read from a file or environment variable and passed to `adb shell`
  must be validated first (see `valid_pkg` / `valid_host` in `lib.sh`), because the
  TV's shell parses it again.
- Anything that changes the TV must be undoable by `99_restore.sh`.
- Comment the "why", not just the "what". People read these before running them.
- Run `shellcheck *.sh` before opening a PR; CI does the same.
