# TVoptimization

Scripts to make an Android TV / Google TV faster and less ad- and
telemetry-heavy, driven from a Linux machine over ADB (Android Debug Bridge).

Built with a Panasonic TV in mind, but it uses only standard Android tools, so
it should work on most Android TV / Google TV sets (Sony, Philips, TCL, Hisense,
Xiaomi, Nvidia Shield, ...). **It is untested on real hardware so far**; see
[COMPATIBILITY.md](COMPATIBILITY.md) and please add your results.

**What it does:** removes unwanted preinstalled apps, tunes a few settings,
clears caches. **What it never does:** root the TV, flash firmware, or touch
the system image. Everything is reversible (see [Undoing changes](#undoing-changes)).

> **Use at your own risk.** Removing the wrong package can break the launcher
> or TV inputs. The scripts default to dry-run and protect known-critical
> packages, but you are responsible for what you put in `packages.txt`.
> Vendor profiles marked UNVERIFIED are guesses.

## 1. Prepare the TV

1. **Settings → Device Preferences → About**, tap **Build** 7 times to enable Developer options.
2. **Settings → Device Preferences → Developer options**: turn on **USB debugging**
   and **Network/ADB debugging** (wording varies by vendor and Android version).
3. Note the TV's IP (**Settings → Network**). Ideally give it a fixed IP / DHCP reservation in your router.

## 2. Prepare the computer

Install ADB:

| Distro | Command |
|---|---|
| Arch | `sudo pacman -S android-tools` |
| Debian/Ubuntu | `sudo apt install adb` |

Connect, then **accept the "Allow debugging?" prompt on the TV**:

```bash
adb connect 192.168.1.50:5555      # use your TV's IP
adb devices                        # should list it as "device", not "unauthorized"
export TV_ADDR=192.168.1.50:5555   # lets the scripts connect automatically
```

## 3. Run the scripts in order

| Script | Changes the TV? | Purpose |
|---|---|---|
| `00_detect.sh` | No | Writes model, Android version, RAM, storage and package lists to `reports/<time>/`. |
| `01_backup.sh` | No | Saves package and settings state to `backup/<time>/` for rollback. **Run before anything that changes things.** |
| `02_debloat.sh` | Only with `--apply` | Removes/disables packages listed in `packages.txt`. |
| `03_tweaks.sh` | Only with `--apply` | Faster animations, ad opt-out, Private DNS, less background scanning. |
| `04_cleanup.sh` | Cache only | Trims app caches and shows free space. |
| `05_background.sh` | Only with `--apply` | Stops apps listed in `background.txt` from running in the background, freeing RAM without uninstalling them. `--reset` undoes it. |
| `99_restore.sh` | Yes (undo) | Restores packages/settings from the newest backup. |

Typical session:

```bash
./00_detect.sh                      # look around
./01_backup.sh                      # safety net
cp packages.example.txt packages.txt
$EDITOR packages.txt                # uncomment ONLY packages you understand
./02_debloat.sh                     # dry run: shows what would happen
./02_debloat.sh --apply             # do it (small batches, reboot, test)
./03_tweaks.sh --apply
./04_cleanup.sh
```

## Vendor profiles (protected packages)

Each TV brand ships its tuner, HDMI/input framework and launcher under
different package names, and removing them breaks the TV. `profiles/` holds
lists of **protected package prefixes** that `02_debloat.sh` will never touch:

- `profiles/generic.conf` applies to every TV (Android framework, Play services, launcher).
- `profiles/<manufacturer>.conf` is added automatically, chosen from
  `ro.product.manufacturer`. Override with `PROFILE=sony ./02_debloat.sh`.
- No profile for your brand? You get a warning and only the generic list.
  Check your `00_detect.sh` report for the tuner/input packages and add a
  profile (copy `profiles/TEMPLATE.conf.example`), then send a PR.

Shipped profiles: `panasonic` and `sony`, both **unverified**.

## How removal works

`pm uninstall -k --user 0 <pkg>` removes the app **for the current user only**.
The APK stays in the read-only system partition, so it is not really gone: a
factory reset or `cmd package install-existing` brings it back. If the TV
refuses, the script falls back to `pm disable-user`, which hides and stops the app.

## What the tweaks do

| Setting | Effect | Default |
|---|---|---|
| `window/transition/animator_duration_scale = 0.5` | UI animations take half as long, so it feels snappier | 1.0 |
| `limit_ad_tracking = 1` | Opts out of personalised advertising | 0 |
| `private_dns_mode/specifier` | Encrypted DNS; the default `dns.adguard-dns.com` also blocks many ad/tracker domains. Override with `DNS_HOST=...`, or `DNS_HOST=""` to skip. | off |
| `wifi_scan_always_enabled`, `ble_scan_always_enabled = 0` | Stops background radio scans | varies |

**Private DNS sends every domain name the TV looks up to the provider you choose**
(AdGuard by default). That is a third party seeing which services your TV
contacts. Pick one you trust, run your own, or skip it with `DNS_HOST=""`. If that
DNS server is unreachable the TV can lose internet; undo with
`adb shell settings put global private_dns_mode off`.

Private DNS needs Android 9 or newer. Some TVs reset animation settings at
boot, so re-run `03_tweaks.sh --apply` if they revert. Streaming tips (not scriptable): use
Ethernet or 5 GHz Wi-Fi, and keep the TV on a fixed IP.

## Verifying it worked

- Free RAM / storage: compare `reports/` from before and after (`./00_detect.sh` again).
- Private DNS: `adb shell settings get global private_dns_mode` should print `hostname`.
- Connectivity: `adb shell ping -c 5 8.8.8.8`.
- Check that live TV, HDMI inputs and your streaming apps still work after each batch.

## Undoing changes

```bash
./99_restore.sh                          # newest backup
./99_restore.sh backup/20261021-120000   # a specific one
```

Restore only brings back packages that were installed **when the backup was
taken**, so apps you had already removed earlier stay removed. Backups made by
an older version lack `packages_installed.txt` and are refused with an
explanation; re-run `01_backup.sh` before changing anything.
`99_restore.sh` does not undo `05_background.sh`; run `./05_background.sh --reset`.

Last resort: factory reset restores every removed system app.

## Safety notes

- Everything that changes the TV is a dry run until you pass `--apply`.
- Package names, `DNS_HOST` and profile names are validated before use: `adb shell`
  re-parses its arguments on the TV, so an unchecked name like `foo; ...` would
  run as a command there. Lines that fail validation are skipped with a warning.
- Still, **read any `packages.txt` or profile you get from someone else** before running it.
- The scripts only talk to the TV over ADB. They send nothing anywhere else.

## Real-world example

[docs/PANASONIC-4KTV-JUP.md](docs/PANASONIC-4KTV-JUP.md) walks through a full run
on a 1.7 GB Panasonic TV: what was changed, measured results, and the surprises
(including a settings shortcut that opened the factory reset page).

> **Don't open Android settings screens with `am start -a android.settings.*`
> on a TV you don't know.** On the Panasonic above, the privacy intent landed on
> the factory reset page. Navigate the menus by hand instead.

## Troubleshooting

- **`no authorized device`**: accept the prompt on the TV; or Developer options → *Revoke USB debugging authorizations* and reconnect.
- **`connection refused`**: Network debugging is off, or the IP changed.
- **`pm uninstall` fails with `DELETE_FAILED_DEVICE_POLICY_MANAGER`**: the app is protected; the script tries disabling it instead.
- **Home screen empty after a change**: run `./99_restore.sh` and reboot.

## Files

```
lib.sh                 shared helpers, profile loading
profiles/              protected-package lists (generic + per vendor)
00_detect.sh           read-only inspection
01_backup.sh           snapshot for rollback
02_debloat.sh          remove/disable packages (dry-run default)
03_tweaks.sh           settings tweaks (dry-run default)
04_cleanup.sh          cache trim
05_background.sh       stop chosen apps running in the background (frees RAM)
99_restore.sh          undo (packages and settings; use 05_background.sh --reset for background limits)
packages.example.txt   template for your own packages.txt
background.example.txt template for your own background.txt
docs/                  case studies from real TVs
COMPATIBILITY.md       which TVs it has been tried on
CONTRIBUTING.md        how to report a TV or add a profile
reports/ backup/       generated output (git-ignored)
```

## License

MIT, see [LICENSE](LICENSE).
